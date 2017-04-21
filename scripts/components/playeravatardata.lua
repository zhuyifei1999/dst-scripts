local EquipSlot = require("equipslotutil")

local PlayerAvatarData = Class(function(self, inst)
    self.inst = inst

    if inst:HasTag("player") then
        self.isplayer = inst:HasTag("player")
    else
        self.strings =
        {
            name = net_string(inst.GUID, "playeravatardata.name"),
            prefab = net_string(inst.GUID, "playeravatardata.prefab"),
        }

        self.skins =
        {
            --Skin strings are translated to nil when empty
            base_skin = net_string(inst.GUID, "playeravatardata.base_skin"),
            body_skin = net_string(inst.GUID, "playeravatardata.body_skin"),
            hand_skin = net_string(inst.GUID, "playeravatardata.hand_skin"),
            legs_skin = net_string(inst.GUID, "playeravatardata.legs_skin"),
            feet_skin = net_string(inst.GUID, "playeravatardata.feet_skin"),
        }

        self.numbers =
        {
            playerage = net_ushortint(inst.GUID, "playeravatardata.playerage"),
        }

        self.equip = {}
        for i = 1, EquipSlot.Count() do
            table.insert(self.equip, net_string(inst.GUID, "playeravatardata.equip["..tostring(i).."]"))
        end

        --self.unsupported_equips = nil
    end
end)

--Always return a new table because this data is used in place
--of TheNet:GetClientTable, where the return value is modified
--most of the time by the screens using it.
function PlayerAvatarData:GetData()
    if self.isplayer then
        return TheNet:GetClientTableForUser(self.inst.userid)
    elseif self.strings.name:value() == "" then
        return
    end

    local data = { equip = {} }
    for k, v in pairs(self.strings) do
        data[k] = v:value()
    end
    for k, v in pairs(self.skins) do
        --Skin strings are translated to nil when empty
        data[k] = v:value() ~= "" and v:value() or nil
    end
    for k, v in pairs(self.numbers) do
        data[k] = v:value()
    end
    for i, v in ipairs(self.equip) do
        table.insert(data.equip, v:value())
    end
    return data
end

function PlayerAvatarData:SetData(client_obj)
    if self.isplayer then
        return
    end

    for k, v in pairs(self.strings) do
        v:set(client_obj ~= nil and client_obj[k] or "")
    end
    for k, v in pairs(self.skins) do
        v:set(client_obj ~= nil and client_obj[k] or "")
    end
    for k, v in pairs(self.numbers) do
        v:set(client_obj ~= nil and client_obj[k] or 0)
    end
    for i, v in ipairs(self.equip) do
        v:set(client_obj ~= nil and client_obj.equip ~= nil and client_obj.equip[i] or "")
    end
end

function PlayerAvatarData:OnSave()
    if self.isplayer then
        return
    end

    local data = self:GetData()
    if data ~= nil and data.equip ~= nil then
        --translate equipslot id to name
        --names never change, but ids change if slots are added/removed
        local temp = {}
        if self.unsupported_equips ~= nil then
            for k, v in pairs(self.unsupported_equips) do
                temp[k] = v
            end
        end
        for i, v in ipairs(data.equip) do
            temp[EquipSlot.FromID(i)] = v
        end
        data.equip = temp
    end
    return data
end

function PlayerAvatarData:OnLoad(data)
    if self.isplayer then
        return
    elseif data.equip ~= nil then
        --translate equipslot name back to id
        local temp = {}
        for k, v in pairs(data.equip) do
            local eslotid = EquipSlot.ToID(k)
            if eslotid ~= nil then
                temp[eslotid] = v
            elseif self.unsupported_equips == nil then
                self.unsupported_equips = { [k] = v }
            else
                self.unsupported_equips[k] = v
            end
        end
        data.equip = temp
    end
    self:SetData(data)
end

return PlayerAvatarData
