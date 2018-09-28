local MoonTrader = Class(function(self, inst)
    self.inst = inst
    self.canaccept = nil
    self.onaccept = nil

    --V2C: Recommended to explicitly add tag to prefab pristine state
    inst:AddTag("moontrader")
end)

function MoonTrader:SetCanAcceptFn(fn)
    self.canaccept = fn
end

function MoonTrader:SetOnAcceptFn(fn)
    self.onaccept = fn
end

function MoonTrader:AcceptOffering(giver, item)
    if self.canaccept ~= nil and not self.canaccept(self.inst, item, giver) then
        return false
    elseif item.components.stackable ~= nil and item.components.stackable:IsStack() then
        item = item.components.stackable:Get()
    else
        item.components.inventoryitem:RemoveFromOwner(true)
    end

    if self.onaccept ~= nil then
        self.onaccept(self.inst, giver, item)
    end

    item:Remove()

    return true
end

return MoonTrader
