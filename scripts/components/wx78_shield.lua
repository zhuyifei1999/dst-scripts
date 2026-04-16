local SourceModifierList = require("util/sourcemodifierlist")

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

local function on_canshieldcharge(self, val)
    if self.inst.wx78_classified then
        self.inst.wx78_classified.canshieldcharge:set(val)
        self.inst:PushEvent("wx_canshieldcharge", val)
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
    self.canshieldcharge = false
    self.chargegenerationsources = SourceModifierList(inst, 0, SourceModifierList.additive)

	-- Internal vars
	self.effect_cooldown = 5
    self.updating = false

    -- Recommended to explicitly add tag to prefab pristine state
    inst:AddTag("wx78_shield")
end,
nil,
{
	penetrationthreshold = on_penetrationthreshold,
    currentshield = on_currentshield,
    maxshield = on_maxshield,
    canshieldcharge = on_canshieldcharge,
})

function Wx78_Shield:ChargeSourceChanged_Internal()
    if self.chargegenerationsources:Get() ~= 0 then
        if not self.updating then
            self.updating = true
            self:UpdateCanShieldCharge()
            self.inst:StartUpdatingComponent(self)
        end
    else
        if self.updating then
            self.updating = false
            self:UpdateCanShieldCharge()
            self.inst:StopUpdatingComponent(self)
        end
    end
end

function Wx78_Shield:AddChargeSource(source, amount, reason)
    self.chargegenerationsources:SetModifier(source, amount, reason)
    self:ChargeSourceChanged_Internal()
end

function Wx78_Shield:RemoveChargeSource(source, reason)
    self.chargegenerationsources:RemoveModifier(source, reason)
    self:ChargeSourceChanged_Internal()
end

function Wx78_Shield:SetMax(amount)
    assert(amount > 0, "Max wx78_shield must be bigger than 0.")
	self.maxshield = amount
	self:DoDelta(0)
end

function Wx78_Shield:SetCurrent(amount)
	local old = self.currentshield

	self.currentshield = math.clamp(amount, 0, self.maxshield)

	local oldpercent = old / self.maxshield
	local newpercent = self.currentshield / self.maxshield
    self.inst:PushEvent("wxshielddelta", {
        oldpercent = oldpercent,
        newpercent = newpercent,
        maxshield = self.maxshield,
		penetrationthreshold = self.penetrationthreshold,
    })

	-- fx
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

function Wx78_Shield:SetPercent(p)
    self:SetCurrent(p * self:GetMax())
end

function Wx78_Shield:Impenetrable()
	return self.currentshield >= self:GetPenetrationThreshold()
end

function Wx78_Shield:DoDelta(delta)
    self:SetCurrent(self.currentshield + delta)
end


local COMBAT_TIMEOUT = 6
local function IsInCombat(inst)
    local combat = inst.components.combat
    if not combat then
        return false
    end

    local lastattacker = combat.lastattacker
    if lastattacker and lastattacker:IsValid() and (lastattacker.components.health == nil or not lastattacker.components.health:IsDead()) then
        if lastattacker.components.combat and lastattacker.components.combat.target == inst then
            return true
        end
    end

    local t = GetTime()
    return (math.max(combat.laststartattacktime or 0, combat.lastdoattacktime or 0) + COMBAT_TIMEOUT > t)
            or (combat:GetLastAttackedTime() + COMBAT_TIMEOUT > t)
end
local function IsHurt(inst)
    return inst.components.health and inst.components.health:IsHurt() or false
end

function Wx78_Shield:UpdateCanShieldCharge()
    self.canshieldcharge = self.updating and self.currentshield < self.maxshield and not IsInCombat(self.inst) and not IsHurt(self.inst)
end

function Wx78_Shield:GetCanShieldCharge()
    return self.canshieldcharge
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
    self:UpdateCanShieldCharge()
    if self:GetCanShieldCharge() then
        self:DoDelta(self.chargegenerationsources:Get() * dt)
    end
    if self.effect_cooldown > 0 then
        self.effect_cooldown = self.effect_cooldown - dt
        if self.effect_cooldown <= 0 and self.currentshield > 0 then
            SpawnShieldEffect(self.inst, self.currentshield < self:GetPenetrationThreshold() and "wx78_shield_half" or "wx78_shield_full")
            self.effect_cooldown = EFFECT_TIME + math.random() * EFFECT_TIME_VAR
        end
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