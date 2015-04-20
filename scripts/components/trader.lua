local function onenabled(self, enabled)
    if enabled then
        self.inst:AddTag("trader")
    else
        self.inst:RemoveTag("trader")
    end
end

local Trader = Class(function(self, inst)
    self.inst = inst
    self.enabled = true
    self.deleteitemonaccept = true
end,
nil,
{
    enabled = onenabled,
})

function Trader:OnRemoveFromEntity()
    self.inst:RemoveTag("trader")
end

function Trader:IsTryingToTradeWithMe(inst)
    local act = inst:GetBufferedAction()
    return act ~= nil
        and act.target == self.inst
        and (act.action == ACTIONS.GIVETOPLAYER or
            act.action == ACTIONS.GIVEALLTOPLAYER or
            act.action == ACTIONS.GIVE)
end

function Trader:Enable( fn )
    self.enabled = true
end

function Trader:Disable( fn )
    self.enabled = false
end

function Trader:SetAcceptTest( fn )
    self.test = fn
end

function Trader:CanAccept( item, giver )
    return self.enabled and (not self.test or self.test(self.inst, item, giver))
end

function Trader:AcceptGift( giver, item, count )
    if not self.enabled then
        return false
    end

    if self:CanAccept(item, giver) then
        count = count or 1

        if item.components.stackable ~= nil and item.components.stackable.stacksize > count then
            item = item.components.stackable:Get(count)
        else
            item.components.inventoryitem:RemoveFromOwner(true)
        end

        if self.inst.components.inventory ~= nil then
            item.prevslot = nil
            item.prevcontainer = nil
            self.inst.components.inventory:GiveItem(item, nil, giver ~= nil and giver:GetPosition() or nil)
        elseif self.deleteitemonaccept then
            item:Remove()
        end

        if self.onaccept ~= nil then
            self.onaccept(self.inst, giver, item)
        end

        self.inst:PushEvent("trade", {giver = giver, item = item})

        return true
    end

    if self.onrefuse ~= nil then
        self.onrefuse(self.inst, giver, item)
    end
end

return Trader