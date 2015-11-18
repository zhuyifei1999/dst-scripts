local easing = require("easing")

local DeciduousTreeUpdater = Class(function(self, inst)

    self.inst = inst

    self.monster = false
    self.monster_target = nil
    self.last_monster_target = nil
    self.last_attack_time = 0
    self.root = nil

    self.fx = false

end)

function DeciduousTreeUpdater:StopAll()
	self.inst:StopUpdatingComponent(self)
end

function DeciduousTreeUpdater:StartFX(freq)
	-- if self.fx == false then
	-- 	self.fx = true
	-- 	self.fxTime = freq
	-- 	self.fxFreq = freq
	-- 	self.inst:StartUpdatingComponent(self)
	-- end
end

function DeciduousTreeUpdater:StopFX()
	-- self.fx = false
	-- if self.monster == false then self:StopAll() end
end

function DeciduousTreeUpdater:StartMonster(starttime)
	if self.monster == false then
		self.monster = true
		self.time_to_passive_drake = 1
		self.num_passive_drakes = 0
		self.inst.monster_start_time = starttime or GetTime()
		self.inst.monster_duration = GetRandomWithVariance(TUNING.DECID_MONSTER_DURATION, .33*TUNING.DECID_MONSTER_DURATION)
    	self.monsterFreq = .5 + math.random()
    	self.monsterTime = self.monsterFreq
    	self.inst:AddTag("monster")
    	self.spawneddrakes = false
		self.inst:DoTaskInTime(19*FRAMES, function(inst) 
			if inst.components.deciduoustreeupdater then
				inst:StartUpdatingComponent(inst.components.deciduoustreeupdater)
			end
		end)
	end
end

function DeciduousTreeUpdater:StopMonster()
	self.monster = false
	self.monster_target = nil
	self.last_monster_target = nil
	self.inst:RemoveTag("monster")
	if self.drakespawntask then
		self.drakespawntask:Cancel()
		self.drakespawntask = nil
	end
	if self.fx == false then self:StopAll() end
end

-- function DeciduousTreeUpdater:GetDebugString()

-- end

local prefabs =
{
	"green_leaves",
    "red_leaves",    
    "orange_leaves",
    "yellow_leaves",
    "deciduous_root",
    "birchnutdrake",
}

local builds = 
{
	normal = { --Green
		leavesbuild="tree_leaf_green_build",
        fx="green_leaves",
        chopfx="green_leaves_chop",
    },
    barren = {
        leavesbuild=nil,
        fx=nil,
        chopfx=nil,
    },
    red = {
        leavesbuild="tree_leaf_red_build",
        fx="red_leaves",
        chopfx="red_leaves_chop",
    },
    orange = {
        leavesbuild="tree_leaf_orange_build",
        fx="orange_leaves",
        chopfx="orange_leaves_chop",
    },
    yellow = {
        leavesbuild="tree_leaf_yellow_build",
        fx="yellow_leaves",
        chopfx="yellow_leaves_chop",
    },
    poison = {
        leavesbuild="tree_leaf_poison_build",
        fx=nil,
        chopfx=nil,
    },
}

local function GetBuild(inst)
	local build = builds[inst.build]
	if build == nil then
		return builds["normal"]
	end
	return build
end

function DeciduousTreeUpdater:OnUpdate(dt)
	
	if not self.inst then 
		self:StopAll()
		return
	end

	if self.monster and self.inst.monster_start_time and ((GetTime() - self.inst.monster_start_time) > self.inst.monster_duration) then
		self.monster = false
    	if self.inst.monster_start_task ~= nil then
            self.inst.monster_start_task:Cancel()
            self.inst.monster_start_task = nil
        end
        if self.inst.monster and
            not (self.inst.components.burnable ~= nil and
                self.inst.components.burnable:IsBurning()) and
            not self.inst:HasTag("stump") and
            not self.inst:HasTag("burnt") then
            if not self.inst.monster_stop_task or self.inst.monster_stop_task == nil then
	            self.inst.monster_stop_task = self.inst:DoTaskInTime(math.random(0,2), function(inst) 
	                inst:StopMonster() 
	                inst.monster_stop_task = nil
	            end)
	        end
        end
        return
    end

	if self.monster == true then
		-- We want to spawn drakes at some interval
    	if self.time_to_passive_drake <= 0 then
    		if self.num_passive_drakes == 0 then
    			self.num_passive_drakes = TUNING.PASSIVE_DRAKE_SPAWN_NUM_NORMAL
    			if math.random() < .33 then self.num_passive_drakes = TUNING.PASSIVE_DRAKE_SPAWN_NUM_LARGE end
    			self.passive_drakes_spawned = 0
    		elseif self.passive_drakes_spawned < self.num_passive_drakes then
        		local passdrake = SpawnPrefab("birchnutdrake")
    			local passdrakeangle = math.random(360)
    			local passoffset = FindWalkableOffset(self.inst:GetPosition(), passdrakeangle*DEGREES, math.random(2,TUNING.DECID_MONSTER_TARGET_DIST*1.5), 30, false, false)
    			local xp,yp,zp = self.inst.Transform:GetWorldPosition()
    			passdrake.Transform:SetPosition(xp + passoffset.x, yp + passoffset.y, zp + passoffset.z)
    			passdrake.range = TUNING.DECID_MONSTER_TARGET_DIST * 4
    			passdrake:DoTaskInTime(0, function(passdrake)
    				if passdrake.components.combat then
    					local targ = FindEntity(passdrake, TUNING.DECID_MONSTER_TARGET_DIST * 4, function(guy)
				            return passdrake.components.combat and passdrake.components.combat:CanTarget(guy) and 
				            	not guy:HasTag("flying") and (not guy.sg or (guy.sg and not guy.sg:HasStateTag("flying"))) and
				            	not guy:HasTag("birchnutdrake") and not guy:HasTag("wall")
				        end)
        				passdrake.components.combat:SuggestTarget(targ)
    				end
    			end)
    			self.passive_drakes_spawned = self.passive_drakes_spawned + 1
    		else
    			self.num_passive_drakes = 0
    			self.time_to_passive_drake = GetRandomWithVariance(TUNING.PASSIVE_DRAKE_SPAWN_INTERVAL,TUNING.PASSIVE_DRAKE_SPAWN_INTERVAL_VARIANCE)
    		end
    	else
    		self.time_to_passive_drake = self.time_to_passive_drake - dt
    	end

		-- We only want to do the thinking for roots and proximity-drakes so often
		if self.monsterTime > 0 then
			self.monsterTime = self.monsterTime - dt
		else
	        self.monster_target = nil
	        local targdist = TUNING.DECID_MONSTER_TARGET_DIST
	        -- Look for nearby targets (anything not flying, a wall or a drake)
	        self.monster_target = FindEntity(self.inst, targdist * 1.5, function(guy)
	            return self.inst.components.combat and self.inst.components.combat:CanTarget(guy) and 
	            	not guy:HasTag("flying") and (not guy.sg or (guy.sg and not guy.sg:HasStateTag("flying"))) and
	            	not guy:HasTag("birchnutdrake") and not guy:HasTag("wall")
	        end)

	        if self.monster_target ~= nil and self.last_monster_target ~= nil and (GetTime() - self.last_attack_time) > TUNING.DECID_MONSTER_ATTACK_PERIOD then
	        	-- Spawn a root spike and give it a target
	            self.last_attack_time = GetTime()
            	self.root = SpawnPrefab("deciduous_root")
	            local rootpos = self.monster_target:GetPosition()
	            local angle = self.inst:GetAngleToPoint(rootpos)*DEGREES
	            if distsq(self.inst:GetPosition(), self.monster_target:GetPosition()) > (targdist*targdist) then
	                rootpos = self.inst:GetPosition() + Vector3(math.cos(angle) * targdist, 0, -math.sin(angle) * targdist)
	            end

	            local offset = Vector3(math.cos(angle) * 1.75, 0, -math.sin(angle) * 1.75)
	            local x,y,z = self.inst.Transform:GetWorldPosition()
	            self.root.Transform:SetPosition(x + offset.x, y + offset.y, z + offset.z)

	            self.root:PushEvent("givetarget", {target=self.monster_target, targetpos=rootpos, targetangle=angle, owner=self.inst})

	            -- If we haven't spawned drakes yet and the player is close enough, spawn drakes
	            if not self.spawneddrakes and distsq(self.inst:GetPosition(), self.monster_target:GetPosition()) <= ((targdist*.5)*(targdist*.5)) then
	            	self.spawneddrakes = true
	            	self.time_to_passive_drake = GetRandomWithVariance(TUNING.PASSIVE_DRAKE_SPAWN_INTERVAL,TUNING.PASSIVE_DRAKE_SPAWN_INTERVAL_VARIANCE)
	            	self.numdrakes = math.random(TUNING.MIN_TREE_DRAKES, TUNING.MAX_TREE_DRAKES)
	            	self.sectorsize = 360 / self.numdrakes
	            	self.drakespawntask = self.inst:DoPeriodicTask(6*FRAMES, function(inst)
	            		local dtu = inst.components.deciduoustreeupdater
	            		if dtu and dtu.numdrakes <= 0 and dtu.drakespawntask then
	            			dtu.drakespawntask:Cancel()
	            			dtu.drakespawntask = nil
	            		elseif dtu then
	            			local drake = SpawnPrefab("birchnutdrake")
	            			local minang = (dtu.sectorsize * (dtu.numdrakes - 1)) >= 0 and (dtu.sectorsize * (dtu.numdrakes - 1)) or 0
                			local maxang = (dtu.sectorsize * dtu.numdrakes) <= 360 and (dtu.sectorsize * dtu.numdrakes) or 360
			                local drakeangle = math.random(minang, maxang)
	            			local offset = FindWalkableOffset(inst:GetPosition(), drakeangle*DEGREES, math.random(2,TUNING.DECID_MONSTER_TARGET_DIST), 30, false, false)
	            			local x,y,z = inst.Transform:GetWorldPosition()
	            			drake.Transform:SetPosition(x + offset.x, y + offset.y, z + offset.z)
	            			drake.target = dtu.monster_target and dtu.monster_target or dtu.last_monster_target
	            			drake:DoTaskInTime(0, function(drake)
	            				if drake.components.combat then
		            				drake.components.combat:SuggestTarget(drake.target or FindClosestPlayerToInst(drake, 30, true))
	            				end
	            			end)
	            			dtu.numdrakes = dtu.numdrakes - 1
	            		end
	            	end)
	            end
	        end

	        if self.monster_target ~= nil and self.last_monster_target == nil and not self.inst.sg:HasStateTag("burning") then
	            self.inst:PushEvent("sway", {monster=true, monsterpost=nil})
	        elseif self.monster_target == nil and self.last_monster_target ~= nil and not self.inst.sg:HasStateTag("burning") then
	        	self.inst:PushEvent("sway", {monster=nil, monsterpost=true})
	        end
	        self.last_monster_target = self.monster_target
	        self.monsterTime = self.monsterFreq
	    end
	end
end

function DeciduousTreeUpdater:SpawnIgniteWave()
	if self.monster then
    	self.ignitenumdrakes = math.random(TUNING.MIN_TREE_DRAKES, TUNING.MAX_TREE_DRAKES)
    	self.ignitesectorsize = 360 / self.ignitenumdrakes
    	self.ignitedrakespawntask = self.inst:DoPeriodicTask(6*FRAMES, function(inst)
    		local dtu = inst.components.deciduoustreeupdater
    		if dtu and dtu.ignitenumdrakes <= 0 and dtu.ignitedrakespawntask then
    			dtu.ignitedrakespawntask:Cancel()
    			dtu.ignitedrakespawntask = nil
    		elseif dtu then
    			local drake = SpawnPrefab("birchnutdrake")
    			local minang = (dtu.ignitesectorsize * (dtu.ignitenumdrakes - 1)) >= 0 and (dtu.ignitesectorsize * (dtu.ignitenumdrakes - 1)) or 0
    			local maxang = (dtu.ignitesectorsize * dtu.ignitenumdrakes) <= 360 and (dtu.ignitesectorsize * dtu.ignitenumdrakes) or 360
                local drakeangle = math.random(minang, maxang)
    			local offset = FindWalkableOffset(inst:GetPosition(), drakeangle*DEGREES, math.random(2,TUNING.DECID_MONSTER_TARGET_DIST), 30, false, false)
    			local x,y,z = inst.Transform:GetWorldPosition()
    			drake.Transform:SetPosition(x + offset.x, y + offset.y, z + offset.z)
    			drake.target = dtu.monster_target and dtu.monster_target or dtu.last_monster_target
    			drake:DoTaskInTime(0, function(drake)
    				if drake.components.combat then
						drake.components.combat:SuggestTarget(drake.target or FindClosestPlayerToInst(drake, 30, true))
    				end
    			end)
    			dtu.ignitenumdrakes = dtu.ignitenumdrakes - 1
    		end
    	end)
	end
end

return DeciduousTreeUpdater
