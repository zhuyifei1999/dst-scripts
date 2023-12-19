local SourceModifierList = require("util/sourcemodifierlist")

local function OnOceanIce(inst, on_ocean_ice)
	local self = inst.components.slipperyfeet
	if on_ocean_ice then
		if not self.onicetile then
			self.onicetile = true
			if self._updating["checkice"] then
				self:StopUpdating_Internal("checkice")
			else
				inst.components.slipperyfeet:StartSlipperySource("ocean_ice")
			end
		end
	elseif self.onicetile then
		self.onicetile = false
		self:StartUpdating_Internal("checkice")
	end
end

local function OnInit(inst)
	local self = inst.components.slipperyfeet
	self.inittask = nil
	inst:ListenForEvent("on_OCEAN_ICE_tile", OnOceanIce)
	if TheWorld.Map:IsOceanIceAtPoint(inst.Transform:GetWorldPosition()) then
		OnOceanIce(inst, true)
	end
end

local SlipperyFeet = Class(function(self, inst)
	self.inst = inst
	self._sources = SourceModifierList(inst, false, SourceModifierList.boolean)
	self._updating = {}
	self.onicetile = false
	self.started = false
	self.threshold = TUNING.WILSON_RUN_SPEED * 4
	self.decay_accel = TUNING.WILSON_RUN_SPEED * 2
	self.decay_spd = 0
	self.slippiness = 0

	self.inittask = inst:DoTaskInTime(0, OnInit) --Delayed so we're in position
end)

function SlipperyFeet:OnLoad()
	if self.inittask then
		self.inittask:Cancel()
		OnInit(self.inst)
	end
end

function SlipperyFeet:OnRemoveFromEntity()
	if self.inittask then
		self.inittask:Cancel()
		self.inittask = nil
	else
		self.inst:RemoveEventCallback("on_OCEAN_ICE_tile", OnOceanIce)
	end
	self:Stop_Internal()
end

function SlipperyFeet:StartSlipperySource(src, key)
	self._sources:SetModifier(src, true, key)
	self:Start_Internal()
end

function SlipperyFeet:StopSlipperySource(src, key)
	self._sources:RemoveModifier(src, key)
	if not self._sources:Get() then
		self:Stop_Internal()
	end
end

local function OnNewState(inst)
	inst.components.slipperyfeet:SetAccumulating_Internal(inst.sg:HasStateTag("running") and not inst.sg:HasStateTag("noslip"))
end

function SlipperyFeet:Start_Internal()
	if not self.started then
		self.started = true
		self.inst:ListenForEvent("newstate", OnNewState)
		OnNewState(self.inst)
	end
end

function SlipperyFeet:Stop_Internal()
	if self.started then
		self.started = false
		self.inst:RemoveEventCallback("newstate", OnNewState)
		self:SetAccumulating_Internal(false)
	end
end

function SlipperyFeet:SetAccumulating_Internal(accumulating)
	if accumulating then
		if not self._updating["accumulate"] then
			self.decay_spd = 0
			self:StartUpdating_Internal("accumulate")
		end
	elseif self._updating["accumulate"] then
		self.decay_spd = 0
		self:StopUpdating_Internal("accumulate")
	end
end

function SlipperyFeet:SetCurrent(val)
	self.slippiness = val
	if val > 0 then
		self:StartUpdating_Internal("decay")
		if val >= self.threshold then
			self.inst:PushEvent("feetslipped")
		end
	else
		self.decay_spd = 0
		self:StopUpdating_Internal("decay")
	end
end

function SlipperyFeet:DoDelta(delta)
	if delta > 0 then
		self.decay_spd = 0
		self:SetCurrent(self.slippiness + delta)
	else
		self:SetCurrent(math.max(0, self.slippiness + delta))
	end
end

function SlipperyFeet:CalcAccumulatingSpeed()
	local speed = self.inst.Physics:GetMotorSpeed()
	return speed * speed / TUNING.WILSON_RUN_SPEED --curved
end

function SlipperyFeet:StartUpdating_Internal(reason)
	local wasupdating = next(self._updating) ~= nil
	self._updating[reason] = true
	if not wasupdating then
		self.inst:StartUpdatingComponent(self)
	end
end

function SlipperyFeet:StopUpdating_Internal(reason)
	self._updating[reason] = nil
	if next(self._updating) == nil then
		self.inst:StopUpdatingComponent(self)
	end
end

function SlipperyFeet:DoDecay(dt)
	local speed = self.decay_spd
	self.decay_spd = self.decay_spd + self.decay_accel * dt
	speed = (speed + self.decay_spd) / 2 --avg
	self:DoDelta(-speed * dt)
end

function SlipperyFeet:OnUpdate(dt)
	if self._updating["checkice"] then
		--if we're on ocean tile but also visual ground, then assume it's ice overhang
		local x, y, z = self.inst.Transform:GetWorldPosition()
		if not (TheWorld.Map:IsOceanTileAtPoint(x, y, z) and TheWorld.Map:IsVisualGroundAtPoint(x, y, z)) then
			self:StopUpdating_Internal("checkice")
			self:StopSlipperySource("ocean_ice")
		end
	end

	if self._updating["accumulate"] then
		self:DoDelta(self:CalcAccumulatingSpeed() * dt * (0.7 + 0.3 * math.random()))
	elseif self.slippiness > 0 then
		self:DoDecay(dt)
	end
end

function SlipperyFeet:LongUpdate(dt)
	--don't check ice

	if self._updating["accumulate"] then
		--only accumulate one frame since we're not rly moving more
		self:DoDelta(self:CalcAccumulatingSpeed() * FRAMES)
	elseif self.slippiness > 0 then
		self:DoDecay(dt)
	end
end

function SlipperyFeet:GetDebugString()
	return string.format("%.1f/%.1f \(%+.1f/s\)", self.slippiness, self.threshold, self._updating["accumulate"] and self:CalcAccumulatingSpeed() or -self.decay_spd)
end

return SlipperyFeet
