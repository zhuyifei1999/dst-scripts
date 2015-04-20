
local Fillable = Class(function(self, inst)
    self.inst = inst

    self.filledprefab = nil
end)

function Fillable:Fill()
    if self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner then
        local ownerinv = self.inst.components.inventoryitem.owner.components.inventory

        local item = self.inst.components.inventoryitem:RemoveFromOwner(false)

        local replacement = SpawnPrefab(self.filledprefab)
        ownerinv:GiveItem(replacement)

        item:Remove()
    end
end

return Fillable
