
local Vase = Class(function(self, inst)
    self.inst = inst
    self.deleteitemonaccept = true
end)

function Vase:OnRemoveFromEntity()
    self.inst:RemoveTag("vase")
end

function Vase:Decorate(giver, item)
	if item == nil then
		return false
	end
	
    if item.components.stackable ~= nil and item.components.stackable.stacksize > 0 then
        item = item.components.stackable:Get(1)
    else
        item.components.inventoryitem:RemoveFromOwner(true)
    end

    if self.deleteitemonaccept then
        item:Remove()
    end

    if self.ondecorate ~= nil then
        self.ondecorate(self.inst, giver, item)
    end

    return true
end

function Vase:GetDebugString()
    return ""
end

return Vase
