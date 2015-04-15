local Humanity = Class(function(self, inst)
    self.inst = inst

    if TheWorld.ismastersim then
        self.classified = inst.player_classified
    elseif self.classified == nil and inst.player_classified ~= nil then
        self:AttachClassified(inst.player_classified)
    end
end)

--------------------------------------------------------------------------

function Humanity:OnRemoveFromEntity()
    if self.classified ~= nil then
        if TheWorld.ismastersim then
            self.classified = nil
        else
            self.inst:RemoveEventCallback("onremove", self.ondetachclassified, self.classified)
            self:DetachClassified()
        end
    end
end

Humanity.OnRemoveEntity = Humanity.OnRemoveFromEntity

function Humanity:AttachClassified(classified)
    self.classified = classified
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)
end

function Humanity:DetachClassified()
    self.classified = nil
    self.ondetachclassified = nil
end

--------------------------------------------------------------------------

function Humanity:SetCurrent(current)
    if self.classified ~= nil then
        self.classified:SetValue("currenthumanity", current)
    end
end

function Humanity:SetMax(max)
    if self.classified ~= nil then
        self.classified:SetValue("maxhumanity", max)
    end
end

function Humanity:Max()
    if self.inst.components.humanity ~= nil then
        return self.inst.components.humanity.max
    elseif self.classified ~= nil then
        return self.classified.maxhumanity:value()
    else
        return 100
    end
end

function Humanity:GetPercent()
    if self.inst.components.humanity ~= nil then
        return self.inst.components.humanity:GetPercent()
    elseif self.classified ~= nil then
        return self.classified.currenthumanity:value() / self.classified.maxhumanity:value()
    else
        return 1
    end
end

function Humanity:SetHealthPenalty(healthpenalty)
    if self.classified ~= nil then
        self.classified:SetValue("humanityhealthpenalty", healthpenalty)
    end
end

function Humanity:SetHealthPenaltyMax(healthpenaltymax)
    if self.classified ~= nil then
        self.classified:SetValue("humanityhealthpenaltymax", healthpenaltymax)
    end
end

function Humanity:HealthPenaltyMax()
    if self.inst.components.humanity ~= nil then
        return self.inst.components.humanity.health_penalty_max
    elseif self.classified ~= nil then
        return self.classified.humanityhealthpenaltymax:value()
    else
        return 0
    end
end

function Humanity:GetHealthPenaltyPercent()
    if self.inst.components.humanity ~= nil then
        return self.inst.components.humanity:GetHealthPenaltyPercent()
    elseif self.classified ~= nil then
        return self.classified.humanityhealthpenalty:value() / self.classified.humanityhealthpenaltymax:value()
    else
        return 0
    end
end

function Humanity:SetIsPaused(ispaused)
    if self.classified ~= nil then
        self.classified.ishumanitypaused:set(ispaused)
    end
end

function Humanity:IsPaused()
    if self.inst.components.humanity ~= nil then
        return self.inst.components.humanity:IsPaused()
    elseif self.classified ~= nil then
        return self.classified.ishumanitypaused:value()
    else
        return false
    end
end

function Humanity:IsDeteriorating()
    if self.inst.components.humanity ~= nil then
        return self.inst.components.humanity:IsDeteriorating()
    elseif self.classified ~= nil then
        return self.classified.currenthumanity:value() <= 0 and
            self.classified.humanityhealthpenalty:value() < self.classified.humanityhealthpenaltymax:value()
    else
        return false
    end            
end

return Humanity