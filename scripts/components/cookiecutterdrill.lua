local CookieCutterDrill = Class(function(self, inst)
    self.inst = inst

	self.drill_progress = 0
	self.drill_duration = 10

	self.leak_type = "med_leak"

	self.sound = "turnoftides/common/together/boat/damage"
	self.sound_intensity = 0.8
end)

-- No need to start drilling on wake as it is handled from the state graph
function CookieCutterDrill:OnEntitySleep()
	self.inst:StopUpdatingComponent(self)
end

function CookieCutterDrill:ResetDrillProgress()
	self.drill_progress = 0
end

function CookieCutterDrill:GetIsDoneDrilling()
	return self.drill_progress >= self.drill_duration
end

function CookieCutterDrill:StartDrilling()
	self.inst:StartUpdatingComponent(self)
end

function CookieCutterDrill:StopDrilling()
	self.inst:StopUpdatingComponent(self)
end

function CookieCutterDrill:FinishDrilling()
	self.inst:StopUpdatingComponent(self)

	self:ResetDrillProgress()

	local x, y, z = self.inst.Transform:GetWorldPosition()
	local boat = TheWorld.Map:GetPlatformAtPoint(x, z)

	if boat ~= nil then
		if self.inst.components.eater ~= nil then self.inst.components.eater.lasteattime = GetTime() end

		local leak = SpawnPrefab("boat_leak")
		leak.Transform:SetPosition(x, y, z)
		leak.components.boatleak.isdynamic = true
		leak.components.boatleak:SetBoat(boat)
		leak.components.boatleak:SetState(self.leak_type)

		table.insert(boat.components.hullhealth.leak_indicators_dynamic, leak)

		if boat.components.walkableplatform ~= nil then
	        for k,v in pairs(boat.components.walkableplatform:GetEntitiesOnPlatform()) do
	            if v:IsValid() then
	                v:PushEvent("on_standing_on_new_leak")
	            end
	        end
		end

		if self.sound ~= nil and boat.SoundEmitter ~= nil then
			boat.SoundEmitter:PlaySoundWithParams(self.sound, { intensity = self.sound_intensity or 1 })
		end
	end
end

function CookieCutterDrill:OnUpdate(dt)
	self.drill_progress = self.drill_progress + dt
end

return CookieCutterDrill