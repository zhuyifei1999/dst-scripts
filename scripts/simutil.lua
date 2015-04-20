local function getfiltersource(src)
   if not src then return "[?]" end
   if src:sub(1, 1) == "@" then
       src = src:sub(2)
   end
   return src
end

local function getformatinfo(info)
   if not info then return "**error**" end
   local source = getfiltersource(info.source)
   if info.currentline then
       source = source..":"..info.currentline
   end
   return ("@%s in %s"):format(source, info.name or "?")
end

function CalledFrom()
    local info = debug.getinfo(3)
    return getformatinfo(info)
end

function GetWorld()
    print("Warning: GetWorld() is deprecated. Please use TheWorld instead. ("..CalledFrom()..")")
    return TheWorld
end

function GetPlayer()
    print("Warning: GetPlayer() is deprecated. Please use ThePlayer instead. ("..CalledFrom()..")")
    return ThePlayer
end

function FindEntity(inst, radius, fn, musttags, canttags, mustoneoftags)
    if inst ~= nil and inst:IsValid() then
        local x, y, z = inst.Transform:GetWorldPosition()
        --print("FIND", inst, radius, musttags and #musttags or 0, canttags and #canttags or 0, mustoneoftags and #mustoneoftags or 0)
        local ents = TheSim:FindEntities(x, y, z, radius, musttags, canttags, mustoneoftags) -- or we could include a flag to the search?
        for i, v in ipairs(ents) do
            if v ~= inst and v.entity:IsVisible() and (fn == nil or fn(v, inst)) then
                return v
            end
        end
    end
end

function FindClosestPlayerInRangeSq(x, y, z, rangesq, isalive)
    local closestPlayer = nil
    for i, v in ipairs(AllPlayers) do
        if (isalive == nil or isalive ~= v:HasTag("playerghost")) and
            v.entity:IsVisible() then
            local distsq = v:GetDistanceSqToPoint(x, y, z)
            if distsq < rangesq then
                rangesq = distsq
                closestPlayer = v
            end
        end
    end
    return closestPlayer, closestPlayer ~= nil and rangesq or nil
end

function FindClosestPlayerInRange(x, y, z, range, isalive)
    return FindClosestPlayerInRangeSq(x, y, z, range * range, isalive)
end

function FindClosestPlayer(x, y, z, isalive)
    return FindClosestPlayerInRangeSq(x, y, z, math.huge, isalive)
end

function FindClosestPlayerToInst(inst, range, isalive)
    local x, y, z = inst.Transform:GetWorldPosition()
	return FindClosestPlayerInRange(x, y, z, range, isalive)
end


function FindPlayersInRangeSq(x, y, z, rangesq, isalive)
    local players = {}
    for i, v in ipairs(AllPlayers) do
        if (isalive == nil or isalive ~= v:HasTag("playerghost")) and
            v.entity:IsVisible() and
            v:GetDistanceSqToPoint(x, y, z) < rangesq then
            table.insert(players, v)
        end
    end
    return players
end

function FindPlayersInRange(x, y, z, range, isalive)
    return FindPlayersInRangeSq(x, y, z, range * range, isalive)
end

function IsAnyPlayerInRangeSq(x, y, z, rangesq, isalive)
    for i, v in ipairs(AllPlayers) do
        if (isalive == nil or isalive ~= v:HasTag("playerghost")) and
            v.entity:IsVisible() and
            v:GetDistanceSqToPoint(x, y, z) < rangesq then
            return true
        end
    end
    return false
end

function IsAnyPlayerInRange(x, y, z, range, isalive)
    return IsAnyPlayerInRangeSq(x, y, z, range * range, isalive)
end

-- Get a location where it`s safe to spawn an item so it won`t get lost in the ocean
function FindSafeSpawnLocation(x, y, z)
    local ent = x ~= nil and z ~= nil and FindClosestPlayer(x, y, z) or nil
    if ent ~= nil then
        return ent.Transform:GetWorldPosition()
    elseif TheWorld.components.playerspawner ~= nil then
        -- we still don't have an enity, find a spawnpoint. That must be in a safe location
        return TheWorld.components.playerspawner:GetAnySpawnPoint()
    else
        -- if everything failed, return origin  
        return 0, 0, 0
    end
end

function GetRandomInstWithTag(tag, inst, radius)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, radius, type(tag) == "string" and { tag } or tag)
    return #ents > 0 and ents[math.random(1, #ents)] or nil
end

function GetClosestInstWithTag(tag, inst, radius)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, radius, type(tag) == "string" and { tag } or tag)
    return ents[1] ~= inst and ents[1] or ents[2]
end

function DeleteCloseEntsWithTag(tag, inst, radius)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, radius, type(tag) == "string" and { tag } or tag)
    for i, v in ipairs(ents) do
        v:Remove()
    end
end

function AnimateUIScale(item, total_time, start_scale, end_scale)
    item:StartThread(
    function()
        local scale = 1
        local time_left = total_time
        local start_time = GetTime()
        local end_time = start_time + total_time
        local transform = item.UITransform
        while true do
            local t = GetTime()
            
            local percent = (t - start_time) / total_time
            if percent > 1 then
                transform:SetScale(end_scale, end_scale, end_scale)
                return
            end
            local scale = (1 - percent)*start_scale + percent*end_scale
            transform:SetScale(scale, scale, scale)
            Yield()
        end
    end)
end

-- Use this function to fan out a search for a point that meets a condition.
-- If your condition is basically "walkable ground" use FindWalkableOffset instead.
-- test_fn takes a parameter "offset" which is check_angle*radius.
function FindValidPositionByFan(start_angle, radius, attempts, test_fn)
	local theta = start_angle -- radians
	
	attempts = attempts or 8

	local attempt_angle = (2*PI)/attempts
	local tmp_angles = {}
	for i=0,attempts-1 do
		local a = i*attempt_angle
		if a > PI then
			a = a-(2*PI)
		end
		table.insert(tmp_angles, a)
	end
	
	-- Make the angles fan out from the original point
	local angles = {}
	for i=1,math.ceil(attempts/2) do
		table.insert(angles, tmp_angles[i])
		local other_end = #tmp_angles - (i-1)
		if other_end > i then
			table.insert(angles, tmp_angles[other_end])
		end
	end

	
    --print("FindValidPositionByFan")

	for i, attempt in ipairs(angles) do
		local check_angle = theta + attempt
		if check_angle > 2*PI then check_angle = check_angle - 2*PI end

		local offset = Vector3(radius * math.cos( check_angle ), 0, -radius * math.sin( check_angle ))

        --print(string.format("    %2.2f", check_angle/DEGREES))

		if test_fn(offset) then
			local deflected = i > 1
            --print(string.format("    OK on try %u", i))
			return offset, check_angle, deflected
		end
	end
end

-- This function fans out a search from a starting position/direction and looks for a walkable
-- position, and returns the valid offset, valid angle and whether the original angle was obstructed.
function FindWalkableOffset(position, start_angle, radius, attempts, check_los, ignore_walls)
	--print("FindWalkableOffset:")

    if ignore_walls == nil then 
        ignore_walls = true 
    end

	local test = function(offset)
		local run_point = position+offset
		local ground = TheWorld
		local tile = ground.Map:GetTileAtPoint(run_point.x, run_point.y, run_point.z)
		if tile == GROUND.IMPASSABLE or tile >= GROUND.UNDERGROUND then
			--print("\tfailed, unwalkable ground.")
			return false
		end
		if check_los and not ground.Pathfinder:IsClear(position.x, position.y, position.z,
		                                                 run_point.x, run_point.y, run_point.z,
		                                                 {ignorewalls = ignore_walls, ignorecreep = true}) then
			--print("\tfailed, no clear path.")
			return false
		end
		--print("\tpassed.")
		return true

	end

	return FindValidPositionByFan(start_angle, radius, attempts, test)
end

function CanEntitySeePoint(inst, x, y, z)
    return TheSim:GetLightAtPoint(x, y, z) > TUNING.DARK_CUTOFF
        or (inst ~= nil and inst:HasTag("nightvision"))
    --NOTE: HasTag naturally checks IsValid already
end

function CanEntitySeeTarget(inst, target)
    if target == nil or not target:IsValid() then
        return false
    end
    local x, y, z = target.Transform:GetWorldPosition()
    return CanEntitySeePoint(inst, x, y, z)
end

function SpringCombatMod(amount)
    return TheWorld.state.isspring and amount * TUNING.SPRING_COMBAT_MOD or amount
end
