local Health = Class(function(self, inst)
    self.inst = inst

    self._isdead = net_bool(inst.GUID, "health._isdead")
    self._isnotfull = net_bool(inst.GUID, "health._isnotfull")
    self._cannotheal = net_bool(inst.GUID, "health._cannotheal")
    self._cannotmurder = net_bool(inst.GUID, "health._cannotmurder")

    if TheWorld.ismastersim then
        self.classified = inst.player_classified
    elseif self.classified == nil and inst.player_classified ~= nil then
        self:AttachClassified(inst.player_classified)
    end
end)

--------------------------------------------------------------------------

function Health:OnRemoveFromEntity()
    if self.classified ~= nil then
        if TheWorld.ismastersim then
            self.classified = nil
        else
            self.inst:RemoveEventCallback("onremove", self.ondetachclassified, self.classified)
            self:DetachClassified()
        end
    end
end

Health.OnRemoveEntity = Health.OnRemoveFromEntity

function Health:AttachClassified(classified)
    self.classified = classified
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)
end

function Health:DetachClassified()
    self.classified = nil
    self.ondetachclassified = nil
end

--------------------------------------------------------------------------

function Health:SetCurrent(current)
    if self.classified ~= nil then
        self.classified:SetValue("currenthealth", current)
    end
end

function Health:SetMax(max)
    if self.classified ~= nil then
        self.classified:SetValue("maxhealth", max)
    end
end

function Health:SetPenalty(penalty)
    if self.classified ~= nil then
        self.classified:SetValue("healthpenalty", penalty * TUNING.EFFIGY_HEALTH_PENALTY)
    end
end

function Health:Max()
    if self.inst.components.health ~= nil then
        return self.inst.components.health.maxhealth
    elseif self.classified ~= nil then
        return self.classified.maxhealth:value()
    else
        return 100
    end
end

function Health:GetPercent()
    if self.inst.components.health ~= nil then
        return self.inst.components.health:GetPercent()
    elseif self.classified ~= nil then
        return self.classified.currenthealth:value() / self.classified.maxhealth:value()
    else
        return 1
    end
end

function Health:GetPenaltyPercent()
    if self.inst.components.health ~= nil then
        return self.inst.components.health:GetPenaltyPercent()
    elseif self.classified ~= nil then
        return math.min(self.classified.healthpenalty:value(), self.classified.maxhealth:value() - 1) / self.classified.maxhealth:value()
    else
        return 0
    end
end

function Health:IsHurt()
    if self.inst.components.health ~= nil then
        return self.inst.components.health:IsHurt()
    elseif self.classified ~= nil then
        return self.classified.currenthealth:value() < math.max(1, self.classified.maxhealth:value() - self.classified.healthpenalty:value())
    else
        return false
    end
end

function Health:SetIsFull(isfull)
    self._isnotfull:set(not isfull)
end

function Health:IsFull()
    return not self._isnotfull:value()
end

function Health:SetIsDead(isdead)
    self._isdead:set(isdead)
end

function Health:IsDead()
    return self._isdead:value()
end

function Health:SetIsTakingFireDamage(istakingfiredamage)
    if self.classified ~= nil then
        self.classified.istakingfiredamage:set(istakingfiredamage)
    end
end

function Health:IsTakingFireDamage()
    if self.inst.components.health ~= nil then
        return self.inst.components.health.takingfiredamage
    else
        return self.classified ~= nil and self.classified.istakingfiredamage:value()
    end
end

function Health:SetCanHeal(canheal)
    self._cannotheal:set(not canheal)
end

function Health:CanHeal()
    return not self._cannotheal:value()
end

function Health:SetCanMurder(canmurder)
    self._cannotmurder:set(not canmurder)
end

function Health:CanMurder()
    return not self._cannotmurder:value()
end

return Health
