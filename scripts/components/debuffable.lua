local function onenable(self, enable)
    if enable then
        self.inst:AddTag("debuffable")
    else
        self.inst:RemoveTag("debuffable")
    end
end

local Debuffable = Class(function(self, inst)
    self.inst = inst
    self.enable = true
    self.followsymbol = ""
    self.followoffset = { 0, 0, 0 }
    self.debuffs = {}

    --V2C: Recommended to explicitly add tag to prefab pristine state
    --inst:AddTag("debuffable")
end,
nil,
{
    enable = onenable,
})

function Debuffable:IsEnabled()
    return self.enable
end

function Debuffable:Enable(enable)
    self.enable = enable
    if not enable then
        local toremove = {}
        for k, v in pairs(self.debuffs) do
            table.insert(toremove, k)
        end
        for i, v in ipairs(toremove) do
            self:RemoveDebuff(v)
        end
    end
end

function Debuffable:SetFollowSymbol(symbol, x, y, z)
    self.followsymbol = symbol
    self.followoffset.x = x
    self.followoffset.y = y
    self.followoffset.z = z
    for k, v in pairs(self.debuffs) do
        if v.components.debuff ~= nil then
            v.components.debuff:AttachTo(k, self.inst, symbol, self.followoffset)
        end
    end
end

function Debuffable:HasDebuff(name)
    return self.debuffs[name] ~= nil
end

function Debuffable:AddDebuff(name, prefab)
    if self.enable and self.debuffs[name] == nil then
        local ent = SpawnPrefab(prefab)
        if ent ~= nil then
            if ent.components.debuff ~= nil then
                self.debuffs[name] = ent
                ent.persists = false
                ent.components.debuff:AttachTo(name, self.inst, self.followsymbol, self.followoffset)
            else
                ent:Remove()
            end
        end
    end
end

function Debuffable:RemoveDebuff(name)
    local ent = self.debuffs[name]
    if ent ~= nil then
        self.debuffs[name] = nil
        if ent.components.debuff ~= nil then
            ent.components.debuff:OnDetach()
        else
            ent:Remove()
        end
    end
end

function Debuffable:OnSave()
    if next(self.debuffs) == nil then
        return
    end

    local data = {}
    for k, v in pairs(self.debuffs) do
        local saved--[[, refs]] = v:GetSaveRecord()
        data[k] = saved
    end
    return { debuffs = data }
end

function Debuffable:OnLoad(data)
    if data ~= nil and data.debuffs ~= nil then
        for k, v in pairs(data.debuffs) do
            if self.debuffs[k] == nil then
                local ent = SpawnSaveRecord(v)
                if ent ~= nil then
                    if ent.components.debuff ~= nil then
                        self.debuffs[k] = ent
                        ent.persists = false
                        ent.components.debuff:AttachTo(k, self.inst, self.followsymbol, self.followoffset)
                    else
                        ent:Remove()
                    end
                end
            end
        end
    end
end

return Debuffable
