local WaterProofer = Class(function(self, inst)
    self.inst = inst

    self.effectiveness = 1

    --V2C: Recommended to explicitly add tag to prefab pristine state
    inst:AddTag("waterproofer")
end)

function WaterProofer:OnRemoveFromEntity()
    self.inst:RemoveTag("waterproofer")
end

function WaterProofer:GetEffectiveness()
    return self.effectiveness
end

function WaterProofer:SetEffectiveness(val)
    self.effectiveness = val
end

return WaterProofer