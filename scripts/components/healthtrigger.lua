local function OnHealthDelta(inst, data)
    inst.components.healthtrigger:OnHealthDelta(data)
end

local HealthTrigger = Class(function(self, inst)
    self.inst = inst

    self.triggers = {}

    self.inst:ListenForEvent("healthdelta", OnHealthDelta)
end)

function HealthTrigger:OnRemoveFromEntity()
    self.inst:RemoveEventCallback("healthdelta", OnHealthDelta)
end

function HealthTrigger:AddTrigger(amount, fn)
    self.triggers[amount] = fn
end

function HealthTrigger:OnHealthDelta(data)
    for k, v in pairs(self.triggers) do
        if (data.oldpercent > k and data.newpercent <= k) or
            (data.oldpercent < k and data.newpercent >= k) then
            v(self.inst)
        end
    end
end

return HealthTrigger
