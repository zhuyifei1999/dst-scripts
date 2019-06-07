local easing = require("easing")

local Grogginess = Class(function(self, inst)
    self.inst = inst

    self.resistance = 1
    self.grog_amount = 0
    self.knockouttime = 0
    self.knockoutduration = 0
    self.wearofftime = 0
    self.wearoffduration = TUNING.GROGGINESS_WEAR_OFF_DURATION
    self.decayrate = TUNING.GROGGINESS_DECAY_RATE

    self:SetDefaultTests()
end)

function Grogginess:OnRemoveFromEntity()
    if self.inst:HasTag("groggy") then
        self.inst:RemoveTag("groggy")
        if self.onwearofffn ~= nil then
            self.onwearofffn(self.inst)
        end
    end
end

function DefaultKnockoutTest(inst)
    local self = inst.components.grogginess
    return self.grog_amount >= self.resistance
        and not (inst.components.health ~= nil and inst.components.health.takingfiredamage)
        and not (inst.components.burnable ~= nil and inst.components.burnable:IsBurning())
end

function DefaultComeToTest(inst)
    local self = inst.components.grogginess
    return self.knockouttime > self.knockoutduration and self.grog_amount < self.resistance
end

function DefaultWhileGroggy(inst)
    --assume grog_amount > 0
    local self = inst.components.grogginess
    local pct = self.grog_amount < self.resistance and self.grog_amount / self.resistance or 1
    local speed_mod = Remap(pct, 1, 0, TUNING.MIN_GROGGY_SPEED_MOD, TUNING.MAX_GROGGY_SPEED_MOD)
    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "grogginess", speed_mod)
end

function DefaultWhileWearingOff(inst)
    --assume wearofftime > 0
    local self = inst.components.grogginess
    local pct = self.wearofftime < TUNING.GROGGINESS_WEAR_OFF_DURATION and easing.inQuad(self.wearofftime / TUNING.GROGGINESS_WEAR_OFF_DURATION, 0, 1, 1) or 1
    local speed_mod = Remap(pct, 0, 1, TUNING.MAX_GROGGY_SPEED_MOD, 1)
    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "grogginess", speed_mod)
end

function DefaultOnWearOff(inst)
    inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "grogginess")
end

function Grogginess:SetDefaultTests()
    self.knockouttestfn = DefaultKnockoutTest
    self.cometotestfn = DefaultComeToTest
    self.whilegroggyfn = DefaultWhileGroggy
    self.whilewearingofffn = DefaultWhileWearingOff
    self.onwearofffn = DefaultOnWearOff
end

-----------------------------------------------------------------------------------------------------

function Grogginess:SetComeToTest(fn)
    self.cometotestfn = fn
end

function Grogginess:SetKnockOutTest(fn)
    self.knockouttestfn = fn
end

function Grogginess:SetResistance(resist)
    self.resistance = resist
end

function Grogginess:SetDecayRate(rate)
    self.decayrate = rate
end

function Grogginess:SetWearOffDuration(duration)
    self.wearoffduration = duration
end

function Grogginess:IsKnockedOut()
    return self.inst.sg ~= nil and self.inst.sg:HasStateTag("knockout")
end

function Grogginess:IsGroggy()
    return self.grog_amount > 0 and not self:IsKnockedOut()
end

function Grogginess:HasGrogginess()
    return self.grog_amount > 0
end

function Grogginess:GetDebugString()
    return string.format("%s, knockouttime=%2.2f Groggy: %d/%d",
            self:IsKnockedOut() and "KNOCKED OUT" or "AWAKE",
            self.knockouttime,
            self.grog_amount,
            self.resistance)
end

function Grogginess:AddGrogginess(grogginess, knockoutduration)
    if grogginess <= 0 then
        return
    end

    self.grog_amount = self.grog_amount + grogginess
    self.wearofftime = 0

    if not self.inst:HasTag("groggy") then
        self.inst:AddTag("groggy")
        self.inst:StartUpdatingComponent(self)
        self.knockouttime = 0
    end

    if self.knockouttestfn ~= nil and self.knockouttestfn(self.inst) then
        if not self:IsKnockedOut() then
            self.knockouttime = 0
        end
        self.knockoutduration = math.max(self.knockoutduration, knockoutduration or TUNING.MIN_KNOCKOUT_TIME)
        self:KnockOut()
    end
end

function Grogginess:ExtendKnockout(knockoutduration)
    if self:IsKnockedOut() then
        self.knockoutduration = knockoutduration
        self.knockouttime = 0
        self.grog_amount = math.max(self.grog_amount, self.resistance)
    end
end

function Grogginess:KnockOut()
    if self.inst.entity:IsVisible() and not (self.inst.components.health ~= nil and self.inst.components.health:IsDead()) then
        self.inst:PushEvent("knockedout")
    end
end

function Grogginess:ComeTo()
    if self:IsKnockedOut() and not (self.inst.components.health ~= nil and self.inst.components.health:IsDead()) then
        self.grog_amount = self.resistance
        self.inst:PushEvent("cometo")
    end
end

function Grogginess:OnUpdate(dt)
    self.grog_amount = math.max(0, self.grog_amount - self.decayrate)

    if self:IsKnockedOut() then
        self.knockouttime = self.knockouttime + dt
        if self.cometotestfn ~= nil and self.cometotestfn(self.inst) then
            self:ComeTo()
        end
    elseif self.grog_amount <= 0 then
        self.inst:RemoveTag("groggy")
        self.wearofftime = math.min(self.wearoffduration, self.wearofftime + dt)
        if self.wearofftime >= self.wearoffduration then
            self.inst:StopUpdatingComponent(self)
            self.knockouttime = 0
            self.knockoutduration = 0
            self.wearofftime = 0
            if self.onwearofffn ~= nil then
                self.onwearofffn(self.inst)
            end            
        elseif self.whilewearingofffn ~= nil then
            self.whilewearingofffn(self.inst)
        end
    elseif self.whilegroggyfn ~= nil then
        self.whilegroggyfn(self.inst)
    end
end

return Grogginess
