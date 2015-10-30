local DURATION = .5

local DSP =
{
    mufflehat =
    {
        lowdsp =
        {
            ["set_music"] = 50,
            ["set_ambience"] = 50,
            ["set_sfx/set_ambience"] = 50,
            ["set_sfx/movement"] = 50,
            ["set_sfx/creature"] = 50,
            ["set_sfx/player"] = 50,
            ["set_sfx/voice"] = 50,
            ["set_sfx/sfx"] = 50,
        },
        duration = DURATION,
    },
}

local function OnEquipChanged(inst)
    local self = inst.components.playerhearing
    local inventory = inst.replica.inventory
    local dirty = false
    for k, v in pairs(DSP) do
        if self[k] == not inventory:EquipHasTag(k) then
            self[k] = not self[k]
            dirty = true
        end
    end
    if dirty then
        self:UpdateDSPTables()
    end
end

local function OnInit(inst, self)
    inst:ListenForEvent("equip", OnEquipChanged)
    inst:ListenForEvent("unequip", OnEquipChanged)
    OnEquipChanged(inst)
end

local PlayerHearing = Class(function(self, inst)
    self.inst = inst

    for k, v in pairs(DSP) do
        self[k] = false
    end
    self.dsptables = {}

    inst:DoTaskInTime(0, OnInit, self)
end)

function PlayerHearing:GetDSPTables()
    return self.dsptables
end

function PlayerHearing:UpdateDSPTables()
    for k, v in pairs(DSP) do
        if self[k] then
            if self.dsptables[k] == nil then
                self.dsptables[k] = v
                self.inst:PushEvent("pushdsp", v)
            end
        elseif self.dsptables[k] ~= nil then
            self.dsptables[k] = nil
            self.inst:PushEvent("popdsp", v)
        end
    end
end

return PlayerHearing