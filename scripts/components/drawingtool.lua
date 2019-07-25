function FindEntityToDraw(target, tool)
    if target ~= nil then
        local x, y, z = target.Transform:GetWorldPosition()
        for i, v in ipairs(TheSim:FindEntities(x, y, z, 1.5, { "_inventoryitem" }, { "INLIMBO" })) do
            if v ~= target and v ~= tool and v.entity:IsVisible() and v.replica.inventoryitem:CanBePickedUp() then
                return v
            end
        end
    end
end

local DrawingTool = Class(function(self, inst)
    self.inst = inst

    self.ondrawfn = nil
end)

function DrawingTool:SetOnDrawFn(fn)
    self.ondrawfn = fn
end

function DrawingTool:GetImageToDraw(target)
    local ent = FindEntityToDraw(target, self.inst)
    if ent == nil then
        return
    end
    return ent.drawimageoverride or
        (#(ent.components.inventoryitem.imagename or "") > 0 and ent.components.inventoryitem.imagename) or
        ent.prefab or
        nil,
        ent,
        ent.drawatlasoverride or
        (#(ent.components.inventoryitem.atlasname or "") > 0 and ent.components.inventoryitem.atlasname) or
        nil
end

function DrawingTool:Draw(target, image, src, atlas)
    if target ~= nil and target.components.drawable ~= nil then
        target.components.drawable:OnDrawn(image, src, atlas)
        if self.ondrawfn ~= nil then
            self.ondrawfn(self.inst, target, image, src, atlas)
        end
    end
end

return DrawingTool
