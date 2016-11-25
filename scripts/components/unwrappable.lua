local function oncanbeunwrapped(self, canbeunwrapped)
    if canbeunwrapped then
        self.inst:AddTag("unwrappable")
    else
        self.inst:RemoveTag("unwrappable")
    end
end

local Unwrappable = Class(function(self, inst)
    self.inst = inst
    self.itemdata = nil
    self.canbeunwrapped = true
    self.onwrappedfn = nil
    self.onunwrappedfn = nil

    --V2C: Recommended to explicitly add tags to prefab pristine state
    --On construciton, "unwrappable" tag is added by default
end,
nil,
{
    canbeunwrapped = oncanbeunwrapped,
})

function Unwrappable:SetOnWrappedFn(fn)
    self.onwrappedfn = fn
end

function Unwrappable:SetOnUnwrappedFn(fn)
    self.onunwrappedfn = fn
end

function Unwrappable:WrapItems(items)
    if #items > 0 then
        self.itemdata = {}
        for i, v in ipairs(items) do
            local data = v:GetSaveRecord()
            table.insert(self.itemdata, data)
        end
        if self.onwrappedfn ~= nil then
            self.onwrappedfn(self.inst, #self.itemdata)
        end
    end
end

function Unwrappable:Unwrap(doer)
    local pos = self.inst:GetPosition()
    pos.y = 0
    if self.itemdata ~= nil then
        if doer ~= nil and
            self.inst.components.inventoryitem ~= nil and
            self.inst.components.inventoryitem:GetGrandOwner() == doer then
            local x, y, z = doer.Transform:GetWorldPosition()
            local rot = -doer.Transform:GetRotation() * DEGREES
            pos.x = x + math.cos(rot)
            pos.z = z + math.sin(rot)
        end
        for i, v in ipairs(self.itemdata) do
            local item = SpawnSaveRecord(v)
            if item ~= nil then
                if item.components.inventoryitem ~= nil then
                    item.components.inventoryitem:DoDropPhysics(pos.x, pos.y, pos.z, true, .5)
                elseif item.Physics ~= nil then
                    item.Physics:Teleport(pos:Get())
                else
                    item.Transform:SetPosition(pos:Get())
                end
            end
        end
        self.itemdata = nil
    end
    if self.onunwrappedfn ~= nil then
        self.onunwrappedfn(self.inst, pos)
    end
end

function Unwrappable:OnSave()
    if self.itemdata ~= nil then
        return { items = self.itemdata }
    end
end

function Unwrappable:OnLoad(data)
    if data.items ~= nil and #data.items > 0 then
        self.itemdata = data.items
        if self.onwrappedfn ~= nil then
            self.onwrappedfn(self.inst, #self.itemdata)
        end
    end
end

return Unwrappable
