local function onpercent(self)
    if self.inst.components.combat ~= nil then
        self.inst.components.combat.panic_thresh = self.inst.components.combat.panic_thresh
    end
end

local function onmaxhealth(self, maxhealth)
    self.inst.replica.health:SetMax(maxhealth)
    self.inst.replica.health:SetIsFull((self.currenthealth or maxhealth) >= maxhealth)
    onpercent(self)
end

local function oncurrenthealth(self, currenthealth)
    self.inst.replica.health:SetCurrent(currenthealth)
    self.inst.replica.health:SetIsDead(currenthealth <= 0)
    self.inst.replica.health:SetIsFull(currenthealth >= self.maxhealth)
    onpercent(self)
end

local function ontakingfiredamage(self, takingfiredamage)
    self.inst.replica.health:SetIsTakingFireDamage(takingfiredamage)
end

local function onpenalty(self, penalty)
    self.inst.replica.health:SetPenalty(penalty)
end

local function oncanmurder(self, canmurder)
    self.inst.replica.health:SetCanMurder(canmurder)
end

local function oncanheal(self, canheal)
    self.inst.replica.health:SetCanHeal(canheal)
end

local Health = Class(function(self, inst)
    self.inst = inst
    self.maxhealth = 100
    self.minhealth = 0
    self.currenthealth = self.maxhealth
    self.invincible = false

    self.vulnerabletoheatdamage = true
    self.takingfiredamage = false
    self.takingfiredamagetime = 0
    self.fire_damage_scale = 1
    self.fire_timestart = 1
    self.firedamageinlastsecond = 0
    self.firedamagecaptimer = 0
    self.nofadeout = false
    self.penalty = 0
    self.absorb = 0
    self.playerabsorb = 0
    self.destroytime = nil

    self.canmurder = true
    self.canheal = true
end,
nil,
{
    maxhealth = onmaxhealth,
    currenthealth = oncurrenthealth,
    takingfiredamage = ontakingfiredamage,
    penalty = onpenalty,
    canmurder = oncanmurder,
    canheal = oncanheal,
})

function Health:OnRemoveFromEntity()
    self:StopRegen()
    onpercent(self)
end

function Health:RecalculatePenalty()
    --deprecated, keeping the function around so mods don't crash
end

function Health:SetInvincible(val)
    self.invincible = val
    self.inst:PushEvent("invincibletoggle", { invincible = val })
end

function Health:ForceUpdateHUD()
    self:DoDelta(0, false, nil, true, nil, true)
end

function Health:OnSave()
    return
    {
        health = self.currenthealth,
        penalty = self.penalty > 0 and self.penalty or nil,
    }
end

function Health:OnLoad(data)
    local haspenalty = data.penalty ~= nil and data.penalty > 0 and data.penalty < 1
    if haspenalty then
        self:SetPenalty(data.penalty)
    end

    if data.invincible ~= nil then 
        self.invincible = data.invincible
    end
    if data.health ~= nil then
        self:SetVal(data.health, "file_load")
        self:ForceUpdateHUD()
    elseif data.percent ~= nil then
        -- used for setpieces!
        -- SetPercent already calls ForceUpdateHUD
        self:SetPercent(data.percent, true, "file_load")
    elseif haspenalty then
        self:ForceUpdateHUD()
    end
end

local FIRE_TIMEOUT = .5

function Health:DoFireDamage(amount, doer, instant)
    if not self.invincible and self.fire_damage_scale > 0 then
        if not self.takingfiredamage then
            self.takingfiredamage = true
            self.takingfiredamagestarttime = GetTime()
            self.inst:StartUpdatingComponent(self)
            self.inst:PushEvent("startfiredamage")
            ProfileStatsAdd("onfire")
        end

        local time = GetTime()
        self.lastfiredamagetime = time

        if (instant or time - self.takingfiredamagestarttime > self.fire_timestart) and amount > 0 then

            --We're going to take damage at this point, so make sure it's now over the cap/second
            if self.firedamagecaptimer <= time then
                self.firedamageinlastsecond = 0
                self.firedamagecaptimer = time + 1
            end

            if self.firedamageinlastsecond + amount > TUNING.MAX_FIRE_DAMAGE_PER_SECOND then
                amount = TUNING.MAX_FIRE_DAMAGE_PER_SECOND - self.firedamageinlastsecond
            end

            self:DoDelta(-amount*self.fire_damage_scale, false, "fire")
            self.inst:PushEvent("firedamage")       

            self.firedamageinlastsecond = self.firedamageinlastsecond + amount
        end
    end
end

function Health:OnUpdate(dt)
    local time = GetTime()

    if time - self.lastfiredamagetime > FIRE_TIMEOUT then
        self.takingfiredamage = false
        self.inst:StopUpdatingComponent(self)
        self.inst:PushEvent("stopfiredamage")
        ProfileStatsAdd("fireout")
    end
end

local function DoRegen(inst, self)
    --print(string.format("Health:DoRegen ^%.2g/%.2fs", self.regen.amount, self.regen.period))
    if not self:IsDead() then
        self:DoDelta(self.regen.amount, true, "regen")
    --else
        --print("    can't regen from dead!")
    end
end

function Health:StartRegen(amount, period, interruptcurrentregen)
    -- We don't always do this just for backwards compatibility sake. While unlikely, it's possible some modder was previously relying on
    -- the fact that StartRegen didn't stop the existing task. If they want to continue using that behavior, they now just need to add
    -- a "false" flag as the last parameter of their StartRegen call. Generally, we want to restart the task, though.
    if interruptcurrentregen == nil or interruptcurrentregen == true then
        self:StopRegen()
    end

    if self.regen == nil then
        self.regen = {}
    end
    self.regen.amount = amount
    self.regen.period = period

    if self.regen.task == nil then
        self.regen.task = self.inst:DoPeriodicTask(self.regen.period, DoRegen, nil, self)
    end
end

function Health:SetAbsorptionAmount(amount)
    self.absorb = amount
end

function Health:SetAbsorptionAmountFromPlayer(amount)
    self.playerabsorb = amount
end

function Health:StopRegen()
    --print("Health:StopRegen")
    if self.regen ~= nil then
        if self.regen.task ~= nil then
            --print("   stopping task")
            self.regen.task:Cancel()
            self.regen.task = nil
        end
        self.regen = nil
    end
end

function Health:SetPenalty(penalty)
    --Penalty should never be less than 0% or ever above 75%.
    self.penalty = math.clamp(penalty, 0, TUNING.MAXIMUM_HEALTH_PENALTY)
end

function Health:DeltaPenalty(delta)
    self:SetPenalty(self.penalty + delta)
    self:ForceUpdateHUD() --handles capping health at max with penalty
end

function Health:GetPenaltyPercent()
    return self.penalty
end

function Health:GetPercent()
    return self.currenthealth / self.maxhealth
end

function Health:IsInvincible()
    return self.invincible
end

function Health:GetDebugString()
    local s = string.format("%2.2f / %2.2f", self.currenthealth, self:GetMaxWithPenalty())
    if self.regen ~= nil then
        s = s..string.format(", regen %.2f every %.2fs", self.regen.amount, self.regen.period)
    end
    return s
end

function Health:SetCurrentHealth(amount)
    self.currenthealth = amount
end

function Health:SetMaxHealth(amount)
    self.maxhealth = amount
    self.currenthealth = amount
    self:ForceUpdateHUD() --handles capping health at max with penalty
end

function Health:SetMinHealth(amount)
    self.minhealth = amount
end

function Health:IsHurt()
    return self.currenthealth < self:GetMaxWithPenalty()
end

function Health:GetMaxWithPenalty()
    return self.maxhealth - self.maxhealth * self.penalty
end

function Health:Kill()
    if self.currenthealth > 0 then
        self:DoDelta(-self.currenthealth)
    end
end

function Health:IsDead()
    return self.currenthealth <= 0
end

local function destroy(inst)
    local time_to_erode = 1
    local tick_time = TheSim:GetTickTime()

    if inst.DynamicShadow ~= nil then
        inst.DynamicShadow:Enable(false)
    end

    inst:StartThread(function()
        local ticks = 0
        while ticks * tick_time < time_to_erode do
            local erode_amount = ticks * tick_time / time_to_erode
            inst.AnimState:SetErosionParams(erode_amount, 0.1, 1.0)
            ticks = ticks + 1
            Yield()
        end
        inst:Remove()
    end)
end

function Health:SetPercent(percent, overtime, cause)
    self:SetVal(self.maxhealth * percent, cause)
    self:DoDelta(0, overtime, cause, true, nil, true)
end

function Health:SetVal(val, cause, afflicter)
    local old_percent = self:GetPercent()

    if val > self:GetMaxWithPenalty() then
        val = self:GetMaxWithPenalty()
    end

    if self.minhealth ~= nil and val < self.minhealth then
        self.currenthealth = self.minhealth
        self.inst:PushEvent("minhealth", { cause = cause, afflicter = afflicter })
    elseif val < 0 then
        self.currenthealth = 0
    else
        self.currenthealth = val
    end

    local new_percent = self:GetPercent()

    if old_percent > 0 and new_percent <= 0 or self:GetMaxWithPenalty() <= 0 then
        self.inst:PushEvent("death", { cause = cause, afflicter = afflicter })

        TheWorld:PushEvent("entity_death", { inst = self.inst, cause = cause, afflicter = afflicter })

        if not self.nofadeout then
            self.inst:AddTag("NOCLICK")
            self.inst.persists = false
            self.inst:DoTaskInTime(self.destroytime or 2, destroy)
        end
    end
end

function Health:DoDelta(amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    if self.redirect ~= nil then
        self.redirect(self.inst, amount, overtime, cause)
        return
    end

    if not ignore_invincible and (self.invincible or self.inst.is_teleporting == true) then
        return
    end

    if amount < 0 and not ignore_absorb then
        amount = amount - amount * self.absorb
        if afflicter ~= nil and afflicter:HasTag("player") then
            amount = amount - amount * self.playerabsorb
        end
    end

    local old_percent = self:GetPercent()
    self:SetVal(self.currenthealth + amount, cause, afflicter)
    local new_percent = self:GetPercent()

    self.inst:PushEvent("healthdelta", { oldpercent = old_percent, newpercent = self:GetPercent(), overtime = overtime, cause = cause, afflicter = afflicter, amount = amount })

    if self.ondelta ~= nil then
        self.ondelta(self.inst, old_percent, self:GetPercent())
    end
end

return Health
