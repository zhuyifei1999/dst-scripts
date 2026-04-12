local Socket_Shadow_Mimicry = Class(function(self, inst)
    self.inst = inst

    if self.inst.prefab == "wx78_backupbody" then
        self.spawner = SpawnPrefab("wx78_mimicspawner")
        self.spawner:ListenForEvent("onremove", function()
            self.spawner = nil
        end)
        self.spawner.entity:SetParent(self.inst.entity)
    end
end)

function Socket_Shadow_Mimicry:OnRemoveFromEntity()
    if self.spawner then
        self.spawner:Remove()
    end
end

return Socket_Shadow_Mimicry
