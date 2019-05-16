
local function set_ocean_angle(inst)
	inst.currentAngle = 45 * math.random(0, 7) + 22.5 --math.random(0, 359)
end

local Ocean = Class(function(self, inst)
	self.inst = inst
	self.currentAngle = 0
	self.currentSpeed = 1
	set_ocean_angle(self)
	--[[
	--self.inst:StartUpdatingComponent(self)
	self.inst:ListenForEvent("nighttime", function()
		if not GetSeasonManager():IsHurricaneStorm() then
			self.inst:DoTaskInTime(0.25 * math.random() * TUNING.SEG_TIME, function()
				self.currentSpeed = 0.0
				self.inst:DoTaskInTime(math.random(10, 15), function()
					self.currentSpeed = 1.0
					set_ocean_angle(self)
				end)
			end)
		end
	end)
	]]--
end)

function Ocean:OnUpdate( dt )
end

--[[
function Ocean:OnSave()
	return
	{
		currentAngle = self.currentAngle,
		currentSpeed = self.currentSpeed
	}
end

function Ocean:OnLoad(data)
	self.currentAngle = data.currentAngle or self.currentAngle
	self.currentSpeed = data.currentSpeed or self.currentSpeed
end
]]--


function Ocean:GetCurrentAngle()
	return self.currentAngle
end

function Ocean:GetCurrentSpeed()
	return self.currentSpeed
end

function Ocean:GetCurrentVec3()
	return self.currentSpeed * math.cos(self.currentAngle * DEGREES), 0, self.currentSpeed * math.sin(self.currentAngle * DEGREES)
	--return self.currentSpeed * math.sin(self.currentAngle * DEGREES), 0, self.currentSpeed * math.cos(self.currentAngle * DEGREES)
end

function Ocean:SpawnImpactWave(x, y, z, speed, count)
	--self.waves.SpawnImpactWave(self.waves, x, y, z, speed, count)
end

return Ocean