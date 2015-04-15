--------------------------------------------------------------------------
--[[ Hunter class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "Hunter should not exist on client")

local HUNT_UPDATE = 2

local MIN_TRACKS = 6
local MAX_TRACKS = 12

local TOOCLOSE_TO_HUNT_SQ = (TUNING.MIN_JOINED_HUNT_DISTANCE) * (TUNING.MIN_JOINED_HUNT_DISTANCE)

local _dirt_prefab = "dirtpile"
local _track_prefab = "animal_track"
local _beast_prefab_summer = "koalefant_summer"
local _beast_prefab_winter = "koalefant_winter"
local _alternate_beasts = {"warg", "spat"}

local trace = function() end

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst
    
-- Private
local _activeplayers = {}
local _activehunts = {}

local OnUpdateHunt

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function GetMaxHunts()
	return #_activeplayers
end

local function RemoveDirt(hunt)
	assert(hunt)
    trace("Hunter:RemoveDirt")
    if hunt.lastdirt then
        trace("   removing old dirt")
        hunt.lastdirt:Remove()
        hunt.lastdirt = nil
    else
        trace("   nothing to remove")
    end
end


local function StopHunt(hunt)
	assert(hunt)
    trace("Hunter:StopHunt")

    RemoveDirt(hunt)

    if hunt.hunttask then
        trace("   stopping")
        hunt.hunttask:Cancel()
        hunt.hunttask = nil
		
    else
        trace("   nothing to stop")
    end
end

local function BeginHunt(hunt)
	assert(hunt)
    trace("Hunter:BeginHunt")

    hunt.hunttask = self.inst:DoPeriodicTask(HUNT_UPDATE, function() OnUpdateHunt(hunt) end)
    if hunt.hunttask then
        trace("The Hunt Begins!")
    else
        trace("The Hunt ... failed to begin.")
    end

end

local function StopCooldown(hunt)
	assert(hunt)
    trace("Hunter:StopCooldown")
    if hunt.cooldowntask then
        trace("    stopping")
        hunt.cooldowntask:Cancel()
        hunt.cooldowntask = nil
        hunt.cooldowntime = nil
    else
        trace("    nothing to stop")
    end
end

local function OnCooldownEnd(hunt)
	assert(hunt)
    trace("Hunter:OnCooldownEnd")
    
    StopCooldown(hunt) -- clean up references
    StopHunt(hunt)

    BeginHunt(hunt)
end

local function RemoveHunt(hunt)
    StopHunt(hunt)
	for i,v in ipairs(_activehunts) do
		if v == hunt then
			table.remove(_activehunts, i)
			return
		end
	end
	assert(false)
end

local function StartCooldown(hunt, cooldown)
	assert(hunt)
    local cooldown = cooldown or math.random(TUNING.HUNT_COOLDOWN - TUNING.HUNT_COOLDOWNDEVIATION, TUNING.HUNT_COOLDOWN + TUNING.HUNT_COOLDOWNDEVIATION)
    trace("Hunter:StartCooldown", cooldown)

    StopHunt(hunt)
    StopCooldown(hunt)

	if #_activehunts > GetMaxHunts() then
		RemoveHunt(hunt)
		return
	end

    if cooldown and cooldown > 0 then
        trace("The Hunt begins in", cooldown)
		hunt.activeplayer = nil
        hunt.lastdirt = nil
        hunt.lastdirttime = nil

        hunt.cooldowntask = self.inst:DoTaskInTime(cooldown, function() OnCooldownEnd(hunt) end)
        hunt.cooldowntime = GetTime() + cooldown
    end
end


local function StartHunt()
    trace("Hunter:StartHunt")
	-- Given the way hunt is used, it should really be its own class now
	local newhunt = {
						lastdirt = nil,
						direction = nil,
						activeplayer = nil,
					}
	table.insert(_activehunts, newhunt)
	local startHunt = math.random(TUNING.HUNT_COOLDOWN - TUNING.HUNT_COOLDOWNDEVIATION, TUNING.HUNT_COOLDOWN + TUNING.HUNT_COOLDOWNDEVIATION)
    self.inst:DoTaskInTime(0, function(inst) StartCooldown(newhunt, startHunt) end)
	return newhunt
end

local function GetSpawnPoint(pt, radius, hunt)
    trace("Hunter:GetSpawnPoint", tostring(pt), radius)

    local angle = hunt.direction
    if angle then
        local offset = Vector3(radius * math.cos( angle ), 0, -radius * math.sin( angle ))
        local spawn_point = pt + offset
        trace(string.format("Hunter:GetSpawnPoint RESULT %s, %2.2f", tostring(spawn_point), angle/DEGREES))
        return spawn_point
    end

end

local function SpawnDirt(pt,hunt)
	assert(hunt)
    trace("Hunter:SpawnDirt")

    local spawn_pt = GetSpawnPoint(pt, TUNING.HUNT_SPAWN_DIST, hunt)
    if spawn_pt then
        local spawned = SpawnPrefab(_dirt_prefab)
        if spawned then
            spawned.Transform:SetPosition(spawn_pt:Get())
            hunt.lastdirt = spawned
            hunt.lastdirttime = GetTime()
            return true
        end
    end
    trace("Hunter:SpawnDirt FAILED")
    return false
end

local function GetRunAngle(pt, angle, radius)
    local offset, result_angle = FindWalkableOffset(pt, angle, radius, 14, true)
    if result_angle then
        return result_angle
    end
end


local function GetNextSpawnAngle(pt, direction, radius)
    trace("Hunter:GetNextSpawnAngle", tostring(pt), radius)

    local base_angle = direction or math.random() * 2 * PI
    local deviation = math.random(-TUNING.TRACK_ANGLE_DEVIATION, TUNING.TRACK_ANGLE_DEVIATION)*DEGREES

    local start_angle = base_angle + deviation
    trace(string.format("   original: %2.2f, deviation: %2.2f, starting angle: %2.2f", base_angle/DEGREES, deviation/DEGREES, start_angle/DEGREES))

    local angle = GetRunAngle(pt, start_angle, radius)
    trace(string.format("Hunter:GetSpawnPoint RESULT %s", tostring(angle and angle/DEGREES)))
    return angle
end

local function StartDirt(hunt,position)
	assert(hunt)

    trace("Hunter:StartDirt")

    RemoveDirt(hunt)

    local pt = position --Vector3(player.Transform:GetWorldPosition())

    hunt.numtrackstospawn = math.random(MIN_TRACKS, MAX_TRACKS)
    hunt.trackspawned = 0
    hunt.direction = GetNextSpawnAngle(pt, nil, TUNING.HUNT_SPAWN_DIST)
    if hunt.direction then
        trace(string.format("   first angle: %2.2f", hunt.direction/DEGREES))

        trace("    numtrackstospawn", hunt.numtrackstospawn)

        -- it's ok if this spawn fails, because we'll keep trying every HUNT_UPDATE
		local spawnRelativeTo =  pt
        if SpawnDirt(spawnRelativeTo, hunt) then
            trace("Suspicious dirt placed for player ")
        end
    else
        trace("Failed to find suitable dirt placement point")
    end
end

-- are we too close to the last dirtpile of a hunt?
local function IsNearHunt(player)
	for i,hunt in ipairs(_activehunts) do
		if hunt.lastdirt then
            local dirtpos = Point(hunt.lastdirt.Transform:GetWorldPosition())
            local playerpos = Point(player.Transform:GetWorldPosition())
            local dsq = distsq(dirtpos, playerpos)
			if dsq <= TOOCLOSE_TO_HUNT_SQ then
				return true
			end
		end
	end
	return false
end

-- something went unrecoverably wrong, try again after a breif pause
local function ResetHunt(hunt)
	assert(hunt)
    trace("Hunter:ResetHunt - The Hunt was a dismal failure, please stand by...")
	if hunt.activeplayer then
	    hunt.activeplayer:PushEvent("huntlosttrail")
	end

    StartCooldown(hunt, TUNING.HUNT_RESET_TIME)
end

-- Don't be tricked by the name. This is not called every frame
OnUpdateHunt = function(hunt)
	assert(hunt)

    trace("Hunter:OnUpdateHunt")

    if hunt.lastdirttime then
        if (GetTime() - hunt.lastdirttime) > (.75*TUNING.SEG_TIME) and hunt.huntedbeast == nil and hunt.trackspawned >= 1 then
        
            -- check if the player is currently active in any other hunts
          	local playerIsInOtherHunt = false
		    for i,v in ipairs(_activehunts) do
			    if v ~= hunt and v.activeplayer and hunt.activeplayer then
			        if v.activeplayer == hunt.activeplayer then
				        playerIsInOtherHunt = true
				    end
			    end
		    end
		    
		    -- if the player is still active in another hunt then end this one quietly
		    if playerIsInOtherHunt then
		        StartCooldown(hunt)
		    else
                ResetHunt(hunt, true) --Wash the tracks away but only if the player has seen at least 1 track
            end
            
            return
        end
    end

    if not hunt.lastdirt then
		-- pick a player that is available, meaning, not being the active participant in a hunt
		local huntingPlayers = {}	
		for i,v in ipairs(_activehunts) do
			if v.activeplayer then
				huntingPlayers[v.activeplayer] = true
			end
		end

		local eligiblePlayers = {}
		for i,v in ipairs(_activeplayers) do
			if not huntingPlayers[v] and not IsNearHunt(v) then
				table.insert(eligiblePlayers, v)
			end
		end
		if #eligiblePlayers == 0 then
			-- Maybe next time?
			return
		end
		local player = eligiblePlayers[math.random(1,#eligiblePlayers)]
		trace("Start hunt for player",player)
		local position = Vector3(player.Transform:GetWorldPosition())
        StartDirt(hunt,position)
    else
		-- if no player near enough, then give up this hunt and start a new one
        local x,y,z =hunt.lastdirt.Transform:GetWorldPosition()
		
		if not IsAnyPlayerInRange(x,y,z,TUNING.MAX_DIRT_DISTANCE) then
			-- try again rather soon
			StartCooldown(hunt, 0.1)
		end
    end

end

local function OnBeastDeath(hunt,spawned)
    trace("Hunter:OnBeastDeath")
	hunt.huntedbeast = nil
    StartCooldown(hunt)
end

local function GetAlternateBeastChance()
    local day = GetTime()/TUNING.TOTAL_DAY_TIME
    local chance = Lerp(TUNING.HUNT_ALTERNATE_BEAST_CHANCE_MIN, TUNING.HUNT_ALTERNATE_BEAST_CHANCE_MAX, day/100)
    chance = math.clamp(chance, TUNING.HUNT_ALTERNATE_BEAST_CHANCE_MIN, TUNING.HUNT_ALTERNATE_BEAST_CHANCE_MAX)
    return chance
end

local function SpawnHuntedBeast(hunt, pt)
	assert(hunt)
    trace("Hunter:SpawnHuntedBeast")
        
    local spawn_pt = GetSpawnPoint(pt, TUNING.HUNT_SPAWN_DIST, hunt)
    if spawn_pt then
        if math.random() > GetAlternateBeastChance() then
            if TheWorld.state.iswinter then
                hunt.huntedbeast = SpawnPrefab(_beast_prefab_winter)
            else
                hunt.huntedbeast = SpawnPrefab(_beast_prefab_summer)
            end
        else
            local beastPrefab = GetRandomItem(_alternate_beasts)
            hunt.huntedbeast = SpawnPrefab(beastPrefab)
        end

        if hunt.huntedbeast then
            trace("Kill the Beast!")
            hunt.huntedbeast.Physics:Teleport(spawn_pt:Get())
            self.inst:ListenForEvent("death", function(inst, data) OnBeastDeath(hunt, hunt.huntedbeast) end, hunt.huntedbeast)
            return true
        end
    end
    trace("Hunter:SpawnHuntedBeast FAILED")
    return false
end

local function SpawnTrack(spawn_pt, hunt)
    trace("Hunter:SpawnTrack")

    if spawn_pt then
        local next_angle = GetNextSpawnAngle(spawn_pt, hunt.direction, TUNING.HUNT_SPAWN_DIST)
        if next_angle then
            local spawned = SpawnPrefab(_track_prefab)
            if spawned then
                spawned.Transform:SetPosition(spawn_pt:Get())

                hunt.direction = next_angle

                trace(string.format("   next angle: %2.2f", hunt.direction/DEGREES))
                spawned.Transform:SetRotation(hunt.direction/DEGREES - 90)

                hunt.trackspawned = hunt.trackspawned + 1
                trace(string.format("   spawned %u/%u", hunt.trackspawned, hunt.numtrackstospawn))
                return true
            end
        end
    end
    trace("Hunter:SpawnTrack FAILED")
    return false
end



--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function KickOffHunt()
	-- schedule start of a new hunt
	if #_activehunts < GetMaxHunts() then
		StartHunt()
	end 
end

local function OnPlayerJoined(src, player)
	for i,v in ipairs(_activeplayers) do
		if v == player then
			return
		end
	end
	table.insert(_activeplayers, player)
	-- one hunt per player. 
	KickOffHunt()
end

local function OnPlayerLeft(src, player)
	for i,v in ipairs(_activeplayers) do
		if v == player then
			table.remove(_activeplayers, i)
			return
		end
	end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------


for i, v in ipairs(AllPlayers) do
	OnPlayerJoined(self, v)
end

inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

-- if anything fails during this step, it's basically unrecoverable, since we only have this one chance
-- to spawn whatever we need to spawn.  if that fails, we need to restart the whole process from the beginning
-- and hope we end up in a better place
function self:OnDirtInvestigated(pt, doer)
	assert(doer)

    trace("Hunter:OnDirtInvestigated (by "..tostring(doer)..")")

	local hunt = nil
	-- find the hunt this pile belongs to
	for i,v in ipairs(_activehunts) do
		local pos = v.lastdirt and v.lastdirt:GetPosition()
		if v.lastdirt and v.lastdirt:GetPosition() == pt then
			hunt = v
			break
		end
	end

	if not hunt then
		-- we should probably do something intelligent here.
		trace("yikes, no matching hunt found for investigated dirtpile")
		return
	end

	hunt.activeplayer = doer

    if hunt.numtrackstospawn and hunt.numtrackstospawn > 0 then
        if SpawnTrack(pt,hunt) then
            trace("    ", hunt.trackspawned, hunt.numtrackstospawn)
            if hunt.trackspawned < hunt.numtrackstospawn then
                if SpawnDirt(pt, hunt) then
                    trace("...good job, you found a track!")
                else
                    trace("SpawnDirt FAILED! RESETTING")
                    ResetHunt(hunt)
                end
            elseif hunt.trackspawned == hunt.numtrackstospawn then
                if SpawnHuntedBeast(hunt,pt) then
                    trace("...you found the last track, now find the beast!")
                    hunt.activeplayer:PushEvent("huntbeastnearby")
                    StopHunt(hunt)
                else
                    trace("SpawnHuntedBeast FAILED! RESETTING")
                    ResetHunt(hunt)
                end
            end
        else
            trace("SpawnTrack FAILED! RESETTING")
            ResetHunt(hunt)
        end
    end
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    local str = ""
    
	for i,playerdata in pairs(_activeplayers) do
	    str = str.." Cooldown: ".. (self.cooldowntime and string.format("%2.2f", math.max(1, self.cooldowntime - GetTime())) or "-")
    	if not self.lastdirt then
	        str = str.." No last dirt."
    	    str = str.." Distance: ".. (playerdata.distance and string.format("%2.2f", playerdata.distance) or "-")
        	str = str.."/"..tostring(TUNING.MIN_HUNT_DISTANCE)
	    else
    	    str = str.." Dirt"
        	str = str.." Distance: ".. (playerdata.distance and string.format("%2.2f", playerdata.distance) or "-")
	        str = str.."/"..tostring(TUNING.MAX_DIRT_DISTANCE)
    	end
	end
    return str
end

end)
