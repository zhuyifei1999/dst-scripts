
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
