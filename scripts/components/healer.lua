local Healer = Class(function(self, inst)
    self.inst = inst
    self.health = TUNING.HEALING_SMALL
end)

function Healer:SetHealthAmount(health)
    self.health = health
end

function Healer:Heal(target)
    if target.components.health then
        target.components.health:DoDelta(self.health,false,self.inst.prefab)
        if self.inst.components.stackable and self.inst.components.stackable.stacksize > 1 then
            self.inst.components.stackable:Get():Remove()
        else
            self.inst:Remove()
        end
        return true
    end
end

return Healer