local Equippable = Class(function(self, inst)
    self.inst = inst

    self._equipslot = net_tinybyte(inst.GUID, "equippable._equipslot")
end)

local EQUIPSLOT_NAMES = {}
for k, v in pairs(EQUIPSLOTS) do
    table.insert(EQUIPSLOT_NAMES, v)
end
local EQUIPSLOT_IDS = table.invert(EQUIPSLOT_NAMES)

function Equippable:SetEquipSlot(eslot)
    self._equipslot:set(EQUIPSLOT_IDS[eslot])
end

function Equippable:EquipSlot()
    return EQUIPSLOT_NAMES[self._equipslot:value()]
end

function Equippable:IsEquipped()
    if self.inst.components.equippable ~= nil then
        return self.inst.components.equippable:IsEquipped()
    else
        return self.inst.replica.inventoryitem ~= nil and
            self.inst.replica.inventoryitem:IsHeld() and
            ThePlayer.replica.inventory:GetEquippedItem(self:EquipSlot()) == self.inst
    end
end

return Equippable