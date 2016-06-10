local EQUIPSLOT_NAMES = {}
for k, v in pairs(EQUIPSLOTS) do
    table.insert(EQUIPSLOT_NAMES, v)
end
local EQUIPSLOT_IDS = table.invert(EQUIPSLOT_NAMES)

local function EquipSlotToID(eslot)
    return EQUIPSLOT_IDS[eslot]
end

local function EquipSlotFromID(eslotid)
    return EQUIPSLOT_NAMES[eslotid]
end

local function GetCount()
    return #EQUIPSLOT_NAMES
end

return
{
    ToID = EquipSlotToID,
    FromID = EquipSlotFromID,
    Count = GetCount,
}
