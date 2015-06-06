local MaxHealer = Class(function(self, inst)
    self.inst = inst
    self.maxhealth = TUNING.MAX_HEALING_NORMAL
end)

--NOTE: This is set as a factor of num revives! not an HP amount
function MaxHealer:SetHealthAmount(health)
    self.maxhealth = health
end

function MaxHealer:Heal(target) 
    if target.components.health ~= nil then
        target.components.health.numrevives = math.max(0, target.components.health.numrevives - self.maxhealth) --borked for meat eff max health losses
        target.components.health:RecalculatePenalty(true)
        --print(target.components.health.penalty)
        if self.inst.components.stackable ~= nil and self.inst.components.stackable:IsStack() then
            self.inst.components.stackable:Get():Remove()
        else
            self.inst:Remove()
        end
        return true
    end
end

return MaxHealer
