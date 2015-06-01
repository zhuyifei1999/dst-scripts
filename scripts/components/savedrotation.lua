local SavedRotation = Class(function(self, inst)
    self.inst = inst
end)

function SavedRotation:OnSave()
    return { rotation = self.inst.Transform:GetRotation() }
end

function SavedRotation:OnLoad(data)
    if data.rotation then
        self.inst.Transform:SetRotation(data.rotation)
    end
end

return SavedRotation
