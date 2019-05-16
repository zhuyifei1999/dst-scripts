local BoatPatch = Class(function(self, inst)
    self.inst = inst

    inst:AddTag("boat_patch")
end)

function BoatPatch:OnRemoveFromEntity()
    self.inst:RemoveTag("boat_patch")
end

return BoatPatch
