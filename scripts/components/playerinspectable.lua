local EQUIPSLOT_NAMES = {}
for k, v in pairs(EQUIPSLOTS) do
    table.insert(EQUIPSLOT_NAMES, v)
end
local EQUIPSLOT_IDS = table.invert(EQUIPSLOT_NAMES)
EQUIPSLOT_NAMES = nil

local function OnEquip(inst, data)
    inst.Network:SetPlayerEquip(EQUIPSLOT_IDS[data.eslot], data.item:GetSkinName() or data.item.prefab)
end

local function OnUnequip(inst, data)
    inst.Network:SetPlayerEquip(EQUIPSLOT_IDS[data.eslot], "")
end

local PlayerInspectable = Class(function(self, inst)
    self.inst = inst

    inst:ListenForEvent("equip", OnEquip)
    inst:ListenForEvent("unequip", OnUnequip)
end)

return PlayerInspectable
