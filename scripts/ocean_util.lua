
function IsOceanTile(tile)
	return tile >= GROUND.OCEAN_START and tile <= GROUND.OCEAN_END
end

function IsLandTile(tile)
	return tile < GROUND.UNDERGROUND and
        tile ~= GROUND.IMPASSABLE and
        tile ~= GROUND.INVALID
end

function IsSurroundedByWater(x, y, radius)
	for i = -radius, radius, 1 do
		if not IsOceanTile(WorldSim:GetTile(x - radius, y + i)) or not IsOceanTile(WorldSim:GetTile(x + radius, y + i)) then
			return false
		end
	end
	for i = -(radius - 1), radius - 1, 1 do
		if not IsOceanTile(WorldSim:GetTile(x + i, y - radius)) or not IsOceanTile(WorldSim:GetTile(x + i, y + radius)) then
			return false
		end
	end
	return true
end

local function isWaterOrInvalid(ground)
	return IsOceanTile(ground) or ground == GROUND.INVALID
end

function IsSurroundedByWaterOrInvalid(x, y, radius)
	for i = -radius, radius, 1 do
		if not isWaterOrInvalid(WorldSim:GetTile(x - radius, y + i)) or not isWaterOrInvalid(WorldSim:GetTile(x + radius, y + i)) then
			return false
		end
	end
	for i = -(radius - 1), radius - 1, 1 do
		if not isWaterOrInvalid(WorldSim:GetTile(x + i, y - radius)) or not isWaterOrInvalid(WorldSim:GetTile(x + i, y + radius)) then
			return false
		end
	end
	return true
end

function IsCloseToWater(x, y, radius)
	for i = -radius, radius, 1 do
		if IsOceanTile(WorldSim:GetTile(x - radius, y + i)) or IsOceanTile(WorldSim:GetTile(x + radius, y + i)) then
			return true
		end
	end
	for i = -(radius - 1), radius - 1, 1 do
		if IsOceanTile(WorldSim:GetTile(x + i, y - radius)) or IsOceanTile(WorldSim:GetTile(x + i, y + radius)) then
			return true
		end
	end
	return false
end

function IsCloseToLand(x, y, radius)
	for i = -radius, radius, 1 do
		if IsLandTile(WorldSim:GetTile(x - radius, y + i)) or IsLandTile(WorldSim:GetTile(x + radius, y + i)) then
			return true
		end
	end
	for i = -(radius - 1), radius - 1, 1 do
		if IsLandTile(WorldSim:GetTile(x + i, y - radius)) or IsLandTile(WorldSim:GetTile(x + i, y + radius)) then
			return true
		end
	end
	return false
end

function IsCloseToTileType(x, y, radius, tile)
	for i = -radius, radius, 1 do
		if WorldSim:GetTile(x - radius, y + i) == tile or WorldSim:GetTile(x + radius, y + i) == tile then
			return true
		end
	end
	for i = -(radius - 1), radius - 1, 1 do
		if WorldSim:GetTile(x + i, y - radius) == tile or WorldSim:GetTile(x + i, y + radius) == tile then
			return true
		end
	end
	return false
end

function SpawnWaves(inst, numWaves, totalAngle, waveSpeed, wavePrefab, initialOffset, idleTime, instantActive, random_angle)
	wavePrefab = wavePrefab or "rogue_wave"
	totalAngle = math.clamp(totalAngle, 1, 360)

    local pos = inst:GetPosition()
    local startAngle = (random_angle and math.random(-180, 180)) or inst.Transform:GetRotation()
    local anglePerWave = totalAngle/(numWaves - 1)

	if totalAngle == 360 then
		anglePerWave = totalAngle/numWaves
	end

    --[[
    local debug_offset = Vector3(2 * math.cos(startAngle*DEGREES), 0, -2 * math.sin(startAngle*DEGREES)):Normalize()
    inst.components.debugger:SetOrigin("debugy", pos.x, pos.z)
    local debugpos = pos + (debug_offset * 2)
    inst.components.debugger:SetTarget("debugy", debugpos.x, debugpos.z)
    inst.components.debugger:SetColour("debugy", 1, 0, 0, 1)
	--]]

    for i = 0, numWaves - 1 do
        local wave = SpawnPrefab(wavePrefab)

        local angle = (startAngle - (totalAngle/2)) + (i * anglePerWave)
        local rad = initialOffset or (inst.Physics and inst.Physics:GetRadius()) or 0.0
        local total_rad = rad + wave.Physics:GetRadius() + 0.1
        local offset = Vector3(math.cos(angle*DEGREES),0, -math.sin(angle*DEGREES)):Normalize()
        local wavepos = pos + (offset * total_rad)

        if inst:GetIsOnWater(wavepos:Get()) then
	        wave.Transform:SetPosition(wavepos:Get())

	        local speed = waveSpeed or 6
	        wave.Transform:SetRotation(angle)
	        wave.Physics:SetMotorVel(speed, 0, 0)
	        wave.idle_time = idleTime or 5

	        if instantActive then
	        	wave.sg:GoToState("idle")
	        end

	        if wave.soundtidal then
	        	wave.SoundEmitter:PlaySound("dontstarve_DLC002/common/rogue_waves/"..wave.soundtidal)
	        end
        else
        	wave:Remove()
        end
    end
end


function FindLandBetweenPoints(p0x, p0y, p1x, p1y)
	local map = TheWorld.Map
	local dummy
    p0x, dummy, p0y = map:GetTileCenterPoint(p0x, 0, p0y)
    p1x, dummy, p1y = map:GetTileCenterPoint(p1x, 0, p1y)

	local dx = math.abs(p1x - p0x)
	local dy = math.abs(p1y - p0y)

    local ix = p0x < p1x and TILE_SCALE or -TILE_SCALE
    local iy = p0y < p1y and TILE_SCALE or -TILE_SCALE

    local e = 0;
    for i = 0, dx+dy - 1 do
	    if IsLandTile(map:GetTileAtPoint(p0x, 0, p0y)) then
			break
		end

        local e1 = e + dy
        local e2 = e - dx
        if math.abs(e1) < math.abs(e2) then
            p0x = p0x + ix
            e = e1
		else 
            p0y = p0y + iy
            e = e2
        end
	end

	return p0x, 0, p0y
end

function FindRandomPointOnShoreFromOcean(x, y, z)
	local nodes = {}

    for i, node in ipairs(TheWorld.topology.nodes) do
		if node.type ~= NODE_TYPE.Blank and node.type ~= NODE_TYPE.Blocker and node.type ~= NODE_TYPE.SeparatedRoom then
			table.insert(nodes, {n = node, distsq = VecUtil_LengthSq(x - node.x, z - node.y)})
		end
	end
	table.sort(nodes, function(a, b) return a.distsq < b.distsq end)
	
	local closest = {}
	for i = 1, 4 do
		table.insert(closest, nodes[i])
	end
	shuffleArray(closest)

	local dest_x, dest_y, dest_z
	for _, c in ipairs(closest) do
		dest_x, dest_y, dest_z = FindLandBetweenPoints(x, z, c.n.x, c.n.y)
		if dest_x ~= nil then
			return dest_x, dest_y, dest_z
		end
	end

	if TheWorld.components.playerspawner ~= nil then
		return TheWorld.components.playerspawner:GetAnySpawnPoint()
	end

	return nil
end

function LandFlyingCreature(creature)
    creature:RemoveTag("flying")
    creature:PushEvent("on_landed")
    if creature.Physics ~= nil then
        creature.Physics:CollidesWith(COLLISION.LIMITS)
    end
end

function RaiseFlyingCreature(creature)
    creature:AddTag("flying")
    creature:PushEvent("on_no_longer_landed")
    if creature.Physics ~= nil then
        creature.Physics:ClearCollidesWith(COLLISION.LIMITS)
    end
end
