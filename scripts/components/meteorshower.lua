local easing = require("easing")

local showerlevels =
{
	level1={
		showertime = function() return math.random(TUNING.METEOR_SHOWER_LVL1_DURATIONVAR_MIN, TUNING.METEOR_SHOWER_LVL1_DURATIONVAR_MAX) + TUNING.METEOR_SHOWER_LVL1_DURATION_BASE end, --how long the shower lasts
		meteorspersecond = function() return math.random(TUNING.METEOR_SHOWER_LVL1_METEORSPERSEC_MIN, TUNING.METEOR_SHOWER_LVL1_METEORSPERSEC_MAX) end,									--how many meteors falls every second
		maxmediummeteors = function() return math.random(TUNING.METEOR_SHOWER_LVL1_MEDMETEORS_MIN, TUNING.METEOR_SHOWER_LVL1_MEDMETEORS_MAX) end,										--maximum shatter meteors that can be spawned
		maxlargemeteors = function() return math.random(TUNING.METEOR_SHOWER_LVL1_LRGMETEORS_MIN, TUNING.METEOR_SHOWER_LVL1_LRGMETEORS_MAX) end,										--maximum boulders that can be spawned
		nextshower = function() return TUNING.METEOR_SHOWER_LVL1_BASETIME + (math.random() * TUNING.METEOR_SHOWER_LVL1_VARTIME) end,													--how long until the next shower
		waitforplayertimeout = function() return TUNING.TOTAL_DAY_TIME * 1 end, 																										--how long do we wait for a player to arrive
	},

	level2={
		showertime = function() return math.random(TUNING.METEOR_SHOWER_LVL2_DURATIONVAR_MIN, TUNING.METEOR_SHOWER_LVL2_DURATIONVAR_MAX) + TUNING.METEOR_SHOWER_LVL2_DURATION_BASE end, 
		meteorspersecond = function() return math.random(TUNING.METEOR_SHOWER_LVL2_METEORSPERSEC_MIN, TUNING.METEOR_SHOWER_LVL2_METEORSPERSEC_MAX) end,									
		maxmediummeteors = function() return math.random(TUNING.METEOR_SHOWER_LVL2_MEDMETEORS_MIN, TUNING.METEOR_SHOWER_LVL2_MEDMETEORS_MAX) end,										
		maxlargemeteors = function() return math.random(TUNING.METEOR_SHOWER_LVL2_LRGMETEORS_MIN, TUNING.METEOR_SHOWER_LVL2_LRGMETEORS_MAX) end,										
		nextshower = function() return TUNING.METEOR_SHOWER_LVL2_BASETIME + (math.random() * TUNING.METEOR_SHOWER_LVL2_VARTIME) end,													
		waitforplayertimeout = function() return TUNING.TOTAL_DAY_TIME * 2 end,
	},

	level3={
		showertime = function() return math.random(TUNING.METEOR_SHOWER_LVL3_DURATIONVAR_MIN, TUNING.METEOR_SHOWER_LVL3_DURATIONVAR_MAX) + TUNING.METEOR_SHOWER_LVL3_DURATION_BASE end, 
		meteorspersecond = function() return math.random(TUNING.METEOR_SHOWER_LVL3_METEORSPERSEC_MIN, TUNING.METEOR_SHOWER_LVL3_METEORSPERSEC_MAX) end,									
		maxmediummeteors = function() return math.random(TUNING.METEOR_SHOWER_LVL3_MEDMETEORS_MIN, TUNING.METEOR_SHOWER_LVL3_MEDMETEORS_MAX) end,										
		maxlargemeteors = function() return math.random(TUNING.METEOR_SHOWER_LVL3_LRGMETEORS_MIN, TUNING.METEOR_SHOWER_LVL3_LRGMETEORS_MAX) end,										
		nextshower = function() return TUNING.METEOR_SHOWER_LVL3_BASETIME + (math.random() * TUNING.METEOR_SHOWER_LVL3_VARTIME) end,													
		waitforplayertimeout = function() return TUNING.TOTAL_DAY_TIME * 3 end,
	},
}

local MeteorShower = Class(function(self,inst)
	self.inst = inst
	self.timetospawn = 0
	self.spawntime = 0.5
	self.shower = false
	self.inst:StartUpdatingComponent(self)
	self.showerlevel = showerlevels[self:PickNextShowerLevel()]
	self.showertime = self.showerlevel.showertime()
	self.meteorspersecond = self.showerlevel.meteorspersecond()
	self.nextshower = self.showerlevel.nextshower()
	self.maxmediummeteors = self.showerlevel.maxmediummeteors()
	self.maxlargemeteors = self.showerlevel.maxlargemeteors()
	self.waitforplayertimeout = self.showerlevel.waitforplayertimeout()
	self.waittime = 0
end)


function MeteorShower:OnSave()
	if not self.noserial then
        if self.showerold then
            self.showerlevel = self.showerold
            self.showerold = nil
            self.showertime = self.showerlevel.showertime()
            self.meteorspersecond = self.showerlevel.meteorspersecond()
            self.nextshower = self.showerlevel.nextshower()
            self.maxmediummeteors = self.showerlevel.maxmediummeteors()
            self.maxlargemeteors = self.showerlevel.maxlargemeteors()
            self.waitforplayertimeout = self.showerlevel.waitforplayertimeout()
            self.waittime = self.waittime
        end
		return
		{
			showertime = self.showertime,
			meteorspersecond = self.meteorspersecond,
			nextshower = self.nextshower,
			maxlargemeteors = self.maxlargemeteors,
			maxmediummeteors = self.maxmediummeteors,
			waitforplayertimeout = self.waitforplayertimeout,
			waittime = self.waittime
		}
	end
	self.noserial = false
end

function MeteorShower:OnLoad(data)
	self.showertime = data.showertime or self.showerlevel.showertime()
	self.meteorspersecond = data.meteorspersecond or self.showerlevel.meteorspersecond()
	self.nextshower = data.nextshower or self.showerlevel.nextshower()
	self.maxlargemeteors = data.maxlargemeteors or self.showerlevel.maxlargemeteors()
	self.maxmediummeteors = data.maxmediummeteors or self.showerlevel.maxmediummeteors()
	self.waitforplayertimeout = data.waitforplayertimeout or self.showerlevel.waitforplayertimeout()
	self.waittime = data.waittime or 0
end

function MeteorShower:OnProgress()
	self.noserial = true
end

function MeteorShower:GetDebugString()
	if not self.shower then
		return string.format("Next shower in %2.2f. Waiting for player for %2.2f seconds (max of %2.2f). %2.2f meteors will fall every second. It will last for %2.2f seconds",
		self.nextshower, self.waittime, self.waitforplayertimeout, self.meteorspersecond, self.showertime)
	else
		return string.format("SHOWERING")
	end
end

function MeteorShower:SetNextShower()
	-- Use the cooldown from the previous shower if available, not the new one
	self.nextshower = self.prevshowerlevel and self.prevshowerlevel.nextshower() or self.showerlevel.nextshower()

	-- Set the rest of the data on the new shower level
	self.showertime = self.showerlevel.showertime()
	self.meteorspersecond = self.showerlevel.meteorspersecond()
	self.maxmediummeteors = self.showerlevel.maxmediummeteors()
	self.maxlargemeteors = self.showerlevel.maxlargemeteors()
	self.waitforplayertimeout = self.showerlevel.waitforplayertimeout()
	self.waittime = 0
end

function MeteorShower:GetTimeForNextMeteor()
	if self.offscreen then
		return 1/(self.meteorspersecond*TUNING.METEOR_SHOWER_OFFSCREEN_MOD)
	else
		return 1/self.meteorspersecond
	end
end

function MeteorShower:GetNextMeteorSize()
	local rand = math.random()
	local size = nil
	local mod = 1
	if self.offscreen then
		mod = TUNING.METEOR_SHOWER_OFFSCREEN_MOD
	end
	if rand <= TUNING.METEOR_LARGE_CHANCE*mod and self.numlargemeteors < self.maxlargemeteors*mod then
		size = "large"
		self.numlargemeteors = self.numlargemeteors + 1
	end

	if not size and rand <= TUNING.METEOR_MEDIUM_CHANCE*mod and self.nummediummeteors < self.maxmediummeteors*mod then
		size = "medium"
		self.nummediummeteors = self.nummediummeteors + 1
	end

	if not size then
		size = "small"
	end
	
	return size, mod
end

function MeteorShower:SetShowerLevel(level)
	self.prevshowerlevel = self.showerlevel
 	self.showerlevel = showerlevels[level]
    self.levelname = level
	self:SetNextShower()
end

function MeteorShower:StartShower(playerpresent)
	self.shower = true
	self.nummediummeteors = 0
	self.numlargemeteors = 0
	if playerpresent == false then
		self.offscreen = true
	else
		self.offscreen = false
	end
end

function MeteorShower:ForceShower(level)

	if self.shower then return false end  

    if level and showerlevels[level] then
 	    self.showerold = self.showerlevel
 	    self.showerlevel = showerlevels[level]
        self.showertime = self.showerlevel.showertime()
        self.meteorspersecond = self.showerlevel.meteorspersecond()
        self.nextshower = self.showerlevel.nextshower()
        self.maxmediummeteors = self.showerlevel.maxmediummeteors()
        self.maxlargemeteors = self.showerlevel.maxlargemeteors()
        self.waitforplayertimeout = self.showerlevel.waitforplayertimeout()
        self.waittime = 0
    end
	self.nextshower = 1

    return true
end

function MeteorShower:PickNextShowerLevel()
	local rand = math.random()
	if rand <= .33 then
		return "level1"
	elseif rand <= .67 then
		return "level2"
	else
		return "level3"
	end
end

function MeteorShower:EndShower()
    if self.showerold then
 	    self.showerlevel = self.showerold
 	    self.showerold = nil
        self.showertime = self.showerlevel.showertime()
        self.meteorspersecond = self.showerlevel.meteorspersecond()
        self.nextshower = self.showerlevel.nextshower()
        self.maxmediummeteors = self.showerlevel.maxmediummeteors()
        self.maxlargemeteors = self.showerlevel.maxlargemeteors()
        self.waitforplayertimeout = self.showerlevel.waitforplayertimeout()
        self.waittime = 0
    end

	self.shower = false

	local level = self:PickNextShowerLevel()
	self:SetShowerLevel(level)
end

function MeteorShower:GetSpawnPoint(rad)
	if not self.pos then
		self.pos = self.inst:GetPosition()
	end
    local theta = math.random() * 2 * PI
    -- Do some easing fanciness to make it less clustered around the spawner prefab
    local radius = easing.outSine(math.random(), math.random()*7, rad or TUNING.METEOR_SHOWER_SPAWN_RADIUS, 1)

    local fan_offset = FindValidPositionByFan(theta, radius, 30, 
    	function(offset)
    		local spawnpt = self.pos + offset
	        return TheWorld.Map:IsPassableAtPoint(spawnpt:Get())
    	end) 
    if fan_offset then
	    return self.pos + fan_offset
	end
end

function MeteorShower:SpawnMeteor(spawn_point)
    local met = SpawnPrefab("shadowmeteor")

    met.Transform:SetPosition(spawn_point.x, spawn_point.y, spawn_point.z)

    return met
end

function MeteorShower:OnUpdate( dt )

	-- If everything is zero'd out, just stop
	if self.showertime == 0 and self.meteorspersecond == 0 and self.maxmediummeteors == 0 and self.maxlargemeteors == 0 then
		self.inst:StopUpdatingComponent(self)
		return
	end

	if self.nextshower > 0 then
		self.nextshower = self.nextshower - dt
		if self.nextshower <= 0 then
			self.waittime = 0
		end
	elseif self.nextshower <= 0 and not self.shower then
		if not self.pos then
			self.pos = self.inst:GetPosition()
		end
		if IsAnyPlayerInRange(self.pos.x, self.pos.y, self.pos.z, TUNING.METEOR_SHOWER_SPAWN_RADIUS*1.2) then
			self:StartShower()
		else
			self.waittime = self.waittime + dt
			if self.waittime >= self.waitforplayertimeout then
				self:StartShower(false)
			end
		end
	end


	if self.shower then
		if self.showertime > 0 then
			self.showertime = self.showertime - dt

			if self.timetospawn > 0 then
				self.timetospawn = self.timetospawn - dt
			end

			if self.timetospawn <= 0 then				
				local spawn_point = self:GetSpawnPoint()								
				if spawn_point then
					local met = self:SpawnMeteor(spawn_point)	
					local size, mod = self:GetNextMeteorSize()
					met:SetSize(size, mod)

					if self.spawntime then
						self.timetospawn = self:GetTimeForNextMeteor()
					end
				end
			end
		else
			self:EndShower()
		end
	end    
end

return MeteorShower
