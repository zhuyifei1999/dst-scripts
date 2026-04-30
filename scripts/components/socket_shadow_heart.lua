local Socket_Shadow_Heart = Class(function(self, inst)
    self.inst = inst

    if not self.inst.isplayer then
        if self.inst.prefab == "wx78_backupbody" then
            self.spawner = SpawnPrefab("wx78_heartveinspawner")
            self.spawner:ListenForEvent("onremove", function()
                self.spawner = nil
            end)
            self.spawner.entity:SetParent(self.inst.entity)
        end
    end
end)

function Socket_Shadow_Heart:OnRemoveFromEntity()
    if self.spawner then
        self.spawner:Remove()
    end
end

return Socket_Shadow_Heart
