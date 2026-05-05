local function DoRefreshMimicPauseStates(item, self, forceadd)
    item:PushEvent("itemmimic_refreshpausestates", {owner = self.inst, forceadd = forceadd})
end

local Socket_Shadow_Mimicry = Class(function(self, inst)
    self.inst = inst

    self.RefreshMimicPauseStates = function(forceadd)
        local container = self.inst.components.inventory or self.inst.components.container
        if container then
            container:ForEachItem(DoRefreshMimicPauseStates, self, forceadd)
        end
        container = self.inst.wx78_backupbody_inventory and self.inst.wx78_backupbody_inventory.components.inventory or nil
        if container then
            container:ForEachItem(DoRefreshMimicPauseStates, self, forceadd)
        end
    end

    if self.inst.prefab == "wx78_backupbody" then
        self.spawner = SpawnPrefab("wx78_mimicspawner")
        self.spawner:ListenForEvent("onremove", function()
            self.spawner = nil
        end)
        self.spawner.entity:SetParent(self.inst.entity)
    end

    self.RefreshMimicPauseStates(true)
end)

function Socket_Shadow_Mimicry:OnRemoveFromEntity()
    if self.spawner then
        self.spawner:Remove()
    end

    self.RefreshMimicPauseStates()
end

return Socket_Shadow_Mimicry
