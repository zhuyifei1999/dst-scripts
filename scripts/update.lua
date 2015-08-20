local function SpawnEndMeteors(maxmeteors)
	maxmeteors = maxmeteors or 7
	local nummeteor = math.random(1,maxmeteors)
	for i,v in ipairs(AllPlayers) do
		for k = 1, nummeteor do
			if v and v:IsValid() then
				v:DoTaskInTime(((1 * math.random()) + .33) * k * .5, function() 
			        local pt = v:GetPosition()
			        local theta = math.random() * 2 * PI
					local radius = 0
					if v:HasTag("playerghost") then --spread the meteors more once the player is a ghost
						radius = math.random(k+1, 10+(k*2))
					else
						radius = math.random(k-1, 5+(k*2))
					end
			        local offset = FindWalkableOffset(pt, theta, radius, 12, true)
			        if offset then
			        	pt = pt + offset
			        end
			        local meteor = SpawnPrefab("shadowmeteor")
			        meteor.Transform:SetPosition(pt:Get())
		        end)
		    end
	    end
	end
end


local function SpawnEndHounds()
	local numhounds = math.random(1,3)
	for i,v in ipairs(AllPlayers) do
		for k = 1, numhounds do
			TheWorld.components.hounded:ForceReleaseHound(v)
		end
	end
end

--this is an update that always runs on wall time (not sim time)
function WallUpdate(dt)
	if AUTOSPAWN_MASTER_SLAVE then 
		SpawnSecondInstance()
	end

	--TheSim:ProfilerPush("LuaWallUpdate")

	TheSim:ProfilerPush("RPC queue")
    HandleRPCQueue()
	TheSim:ProfilerPop()	

	if TheFocalPoint ~= nil then
		TheSim:SetActiveAreaCenterpoint(TheFocalPoint.Transform:GetWorldPosition())
    else
        TheSim:SetActiveAreaCenterpoint(0, 0, 0)
	end

	TheSim:ProfilerPush("updating wall components")
    for k,v in pairs(WallUpdatingEnts) do
        if v.wallupdatecomponents then
            for cmp in pairs(v.wallupdatecomponents) do
                if cmp.OnWallUpdate then
                    cmp:OnWallUpdate( dt )
                end
            end
        end
    end
    
	for k,v in pairs(NewWallUpdatingEnts) do
		WallUpdatingEnts[k] = v
		NewWallUpdatingEnts[k] = nil
    end
    
	TheSim:ProfilerPop()

	TheSim:ProfilerPush("mixer")
    TheMixer:Update(dt)
	TheSim:ProfilerPop()	

	if not IsSimPaused() then
		TheSim:ProfilerPush("camera")
		TheCamera:Update(dt)
		TheSim:ProfilerPop()	
	end
    
	CheckForUpsellTimeout(dt)

	TheSim:ProfilerPush("input")
	if not SimTearingDown then
	    TheInput:OnUpdate()
	end
	TheSim:ProfilerPop()	

	TheSim:ProfilerPush("fe")
	TheFrontEnd:Update(dt)
	TheSim:ProfilerPop()	
	
	--TheSim:ProfilerPop()

	-- Server termination script
	-- Only runs if the SERVER_TERMINATION_TIMER constant has been overriden (which we do with the pax demo)
	if SERVER_TERMINATION_TIMER > 0 and TheNet:GetIsServer() then
		local original_time = SERVER_TERMINATION_TIMER
		SERVER_TERMINATION_TIMER = SERVER_TERMINATION_TIMER - dt

		if SERVER_TERMINATION_TIMER <= 60 and original_time % 5 <= 0.02 and SERVER_TERMINATION_TIMER > 0 then
			SpawnEndHounds()
		end
		if SERVER_TERMINATION_TIMER <= 30 and original_time % 2 <= 0.02 and SERVER_TERMINATION_TIMER > 0 then
			SpawnEndMeteors()
		end

		if SERVER_TERMINATION_TIMER <= 0 then
			TheSim:Quit()
		elseif SERVER_TERMINATION_TIMER <= 30 and original_time > 30 then
			TheNet:Announce( "The sky is falling!", nil )
		elseif SERVER_TERMINATION_TIMER <= 60 and original_time > 60 then
			TheNet:Announce( "Let slip the dogs of war!", nil )
		elseif SERVER_TERMINATION_TIMER <= 120 and original_time > 120 then
			TheNet:Announce( "End times are almost here.", nil )
		elseif SERVER_TERMINATION_TIMER <= 180 and original_time > 180 then
			TheNet:Announce( "End times are coming.", nil )
		end
	end
end

function PostUpdate(dt)
	--TheSim:ProfilerPush("LuaPostUpdate")
	EmitterManager:PostUpdate()
	--TheSim:ProfilerPop()
end


local StaticComponentLongUpdates = {}
function RegisterStaticComponentLongUpdate(classname, fn)
	StaticComponentLongUpdates[classname] = fn
end


local StaticComponentUpdates = {}
function RegisterStaticComponentUpdate(classname, fn)
	StaticComponentUpdates[classname] = fn
end


local last_tick_seen = -1
--This is where the magic happens
function Update( dt )
    HandleClassInstanceTracking()
	--TheSim:ProfilerPush("LuaUpdate")    
	CheckDemoTimeout()
    
    if PLATFORM == "NACL" then
        AccumulatedStatsHeartbeat(dt)
    end
	
    if not IsSimPaused() then
		local tick = TheSim:GetTick()
		if tick > last_tick_seen then
			TickRPCQueue()
			
			TheSim:ProfilerPush("scheduler")
			for i = last_tick_seen +1, tick do
				RunScheduler(i)
			end
			TheSim:ProfilerPop()
			
			if SimShuttingDown then
			    return 
			end
			
			TheSim:ProfilerPush("static components")
			for k,v in pairs(StaticComponentUpdates) do
				v(dt)
			end
			TheSim:ProfilerPop()
			
			TheSim:ProfilerPush("updating components")
			for k,v in pairs(UpdatingEnts) do
				--TheSim:ProfilerPush(v.prefab)
				if v.updatecomponents then
					for cmp in pairs(v.updatecomponents) do
						--TheSim:ProfilerPush(v:GetComponentName(cmp))
						if cmp.OnUpdate and not StopUpdatingComponents[cmp] then
							cmp:OnUpdate( dt )
						end
						--TheSim:ProfilerPop()
					end
				end
				--TheSim:ProfilerPop()
			end

			for k,v in pairs(NewUpdatingEnts) do
				UpdatingEnts[k] = v
			end
			NewUpdatingEnts = {}

			for k,v in pairs(StopUpdatingComponents) do
				v:StopUpdatingComponent_Deferred(k)
			end
			StopUpdatingComponents = {}

			TheSim:ProfilerPop()

			for i = last_tick_seen + 1, tick do
				TheSim:ProfilerPush("LuaSG")
				SGManager:Update(i)
				TheSim:ProfilerPop()
	            
				TheSim:ProfilerPush("LuaBrain")
				BrainManager:Update(i)
				TheSim:ProfilerPop()
			end
		else
			print ("Saw this before")
		end
		last_tick_seen = tick
	end

    --TheSim:ProfilerPop()        
end

--this is for advancing the sim long periods of time (to skip nights, come back from caves, etc)
function LongUpdate(dt, ignore_player)
	--print ("LONG UPDATE", dt, ignore_player)
	local function doupdate(dt)
		for k,v in pairs(StaticComponentLongUpdates) do
			v(dt)
		end

		for i,v in ipairs(AllPlayers) do
			if ignore_player then
				if v.components.beard then
					v.components.beard.pause = true
				end

				if v.components.beaverness then
					v.components.beaverness.ignoremoon = true
				end
			end
		end


		for k,v in pairs(Ents) do
			
			local should_ignore = false
			if ignore_player then
				
				if v.components.inventoryitem then
					local grand_owner = v.components.inventoryitem:GetGrandOwner()
					if grand_owner and grand_owner:HasTag("player") then
						should_ignore = true
					end
					if grand_owner and grand_owner.prefab == "chester" then
						local leader = grand_owner.components.follower.leader
						if leader and leader:HasTag("player") then
							should_ignore = true
						end
					end
				end
				
				if v.components.follower and v.components.follower.leader and v.components.follower.leader:HasTag("player") then
					should_ignore = true
				end

				if v:HasTag("player") then
					should_ignore = true
				end
			end
				
			if not should_ignore then
				v:LongUpdate(dt)	
			end
			
		end	

		for i,v in ipairs(AllPlayers) do
			if v.components.beard then
				v.components.beard.pause = nil
			end

			if v.components.beaverness then
				v.components.beaverness.ignoremoon = nil
			end
		end

	end

	doupdate(dt)

end