local function on_penetrationthreshold(self, threshold, old_threshold)
	if self.inst.wx78_classified ~= nil then
		self.inst.wx78_classified:SetValue("shieldpenetrationthreshold", threshold)
	end
end

local function on_currentshield(self, current, old_current)
	if self.inst.wx78_classified ~= nil then
		self.inst.wx78_classified:SetValue("currentshield", current)
	end
end

local function on_maxshield(self, max, old_max)
	if self.inst.wx78_classified ~= nil then
		self.inst.wx78_classified:SetValue("maxshield", max)
	end
end

local function SpawnShieldEffect(inst, effectname)
	SpawnPrefab(effectname).entity:SetParent(inst.entity)
end

local Wx78_Shield = Class(function(self, inst)
    self.inst = inst

	self.penetrationthreshold = 15
	self.currentshield = 0
	self.maxshield = 100

	-- Internal vars
	self.effect_cooldown = 5

    -- Recommended to explicitly add tag to prefab pristine state
    inst:AddTag("wx78_shield")
end,
nil,
{
	penetrationthreshold = on_penetrationthreshold,
    currentshield = on_currentshield,
    maxshield = on_maxshield,
})

function Wx78_Shield:SetMax(amount)
	self.maxshield = amount
	self:DoDelta(0)
end

function Wx78_Shield:SetCurrent(amount)
	local old = self.currentshield

	self.currentshield = math.clamp(amount, 0, self.maxshield)

	if old ~= self.currentshield and self.currentshield == 0 then
		self.last_shield_break_time = GetTime()
	end

	local oldpercent = old / self.maxshield
	local newpercent = self.currentshield / self.maxshield
    self.inst:PushEvent("wxshielddelta", {
        oldpercent = oldpercent,
        newpercent = newpercent,
        delta = self.currentshield-old,
		penetrationthreshold = self.penetrationthreshold,
    })

	-- fx
	if self.currentshield > 0 then
		self.inst:StartUpdatingComponent(self)
	else
		self.inst:StopUpdatingComponent(self)
	end
	if old ~= self.currentshield then
		if self.currentshield >= self.penetrationthreshold then
			if old <= 0 then
				SpawnShieldEffect(self.inst, "wx78_shield_full")
			elseif old <= self.penetrationthreshold then
				SpawnShieldEffect(self.inst, "wx78_shield_half_to_full")
			end
		elseif self.currentshield < self.penetrationthreshold then
			local was_over_threshold = old >= self.penetrationthreshold
			if self.currentshield == 0 and was_over_threshold then
				SpawnShieldEffect(self.inst, "wx78_shield_full_to_empty")
			elseif self.currentshield > 0 and was_over_threshold then
				SpawnShieldEffect(self.inst, "wx78_shield_full_to_half")
			elseif self.currentshield == 0 and not was_over_threshold then
				SpawnShieldEffect(self.inst, "wx78_shield_half_to_empty")
			elseif self.currentshield > 0 and old <= 0 then
				SpawnShieldEffect(self.inst, "wx78_shield_half")
			end
		end
	end
end

function Wx78_Shield:GetMax()
	return self.maxshield
end

function Wx78_Shield:GetCurrent()
	return self.currentshield
end

function Wx78_Shield:GetPenetrationThreshold()
	return self.penetrationthreshold
end

function Wx78_Shield:GetPercent()
	return self.currentshield / self.maxshield
end

function Wx78_Shield:TimeSinceLastShieldBreak()
    return self.last_shield_break_time ~= nil and GetTime() - self.last_shield_break_time or nil
end

function Wx78_Shield:SetPercent(p)
    self:SetCurrent(p * self:GetMax())
end

function Wx78_Shield:Impenetrable()
	return self.currentshield >= self:GetPenetrationThreshold()
end

function Wx78_Shield:DoDelta(delta)
    self:SetCurrent(self.currentshield + delta)
end

function Wx78_Shield:OnTakeDamage(amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    if ignore_absorb or amount >= 0 or overtime or afflicter == nil then
        return amount
    end

	-- If we're at the impenetrable threshold. Take the shield damage and return 0 for health damage.
	if self:Impenetrable() then
		self:DoDelta(amount)
		return 0
	end

	-- Otherwise we are not impenetrable.
	local current = self.currentshield
	self:DoDelta(amount)
	return amount + current
end

local EFFECT_TIME = 10
local EFFECT_TIME_VAR = 8
function Wx78_Shield:OnUpdate(dt)
	self.effect_cooldown = self.effect_cooldown - dt
	if self.effect_cooldown <= 0 then
		SpawnShieldEffect(self.inst, self.currentshield < self:GetPenetrationThreshold() and "wx78_shield_half" or "wx78_shield_full")
		self.effect_cooldown = EFFECT_TIME + math.random() * EFFECT_TIME_VAR
	end
end

function Wx78_Shield:OnSave()
	local current = self:GetCurrent()
    return current ~= 0 and { current = self:GetCurrent() } or nil
end

function Wx78_Shield:OnLoad(data)
	if data.current ~= nil then
		self:SetCurrent(data.current)
	end
end

function Wx78_Shield:GetDebugString()
    return string.format("%2.2f / %2.2f", self:GetCurrent(), self:GetMax())
end

return Wx78_Shield