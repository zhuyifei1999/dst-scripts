local containers = require("containers")

local Container = Class(function(self, inst)
    self.inst = inst

    self._cannotbeopened = net_bool(inst.GUID, "container._cannotbeopened")
    self._isopen = false
    self._numslots = 0
    self.acceptsstacks = true
    self.issidewidget = false
    self.type = nil
    self.widget = nil
    self.itemtestfn = nil
    self.opentask = nil

    if TheWorld.ismastersim then
        self.classified = SpawnPrefab("container_classified")
        self.classified.entity:SetParent(inst.entity)

        --Server intercepts messages and forwards to clients via classified net vars
        inst:ListenForEvent("itemget", function(inst, data) self.classified:SetSlotItem(data.slot, data.item, data.src_pos) end)
        inst:ListenForEvent("itemlose", function(inst, data) self.classified:SetSlotItem(data.slot) end)
    else
        containers.widgetsetup(self)

        if self.classified == nil and inst.container_classified ~= nil then
            self.classified = inst.container_classified
            inst.container_classified.OnRemoveEntity = nil
            inst.container_classified = nil
            self:AttachClassified(self.classified)
        end
    end
end)

--------------------------------------------------------------------------

function Container:OnRemoveFromEntity()
    if self.classified ~= nil then
        if TheWorld.ismastersim then
            self.classified:Remove()
            self.classified = nil
        else
            self.classified._parent = nil
            self.inst:RemoveEventCallback("onremove", self.ondetachclassified, self.classified)
            self:DetachClassified()
        end
    end
end

Container.OnRemoveEntity = Container.OnRemoveFromEntity

--------------------------------------------------------------------------
--Client triggers open/close based on receiving access to classified data
--------------------------------------------------------------------------

local function OpenContainer(inst, self)
    self.opentask = nil
    self:Open(ThePlayer)
end

function Container:AttachClassified(classified)
    self.classified = classified

    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)

    classified:InitializeSlots(self:GetNumSlots())

    self.opentask = self.inst:DoTaskInTime(0, OpenContainer, self)
end

function Container:DetachClassified()
    self.classified = nil
    self.ondetachclassified = nil
    self:Close()
end

--------------------------------------------------------------------------
--Server initialization requires param since prefab property is not set yet
--------------------------------------------------------------------------

function Container:WidgetSetup(prefab, data)
    containers.widgetsetup(self, prefab, data)
    if self.classified ~= nil then
        self.classified:InitializeSlots(self:GetNumSlots())
    end
end

--------------------------------------------------------------------------
--Common interface
--------------------------------------------------------------------------

function Container:GetWidget()
    return self.widget
end

function Container:SetNumSlots(numslots)
    self._numslots = numslots
end

function Container:GetNumSlots()
    return self._numslots
end

function Container:SetCanBeOpened(canbeopened)
    self._cannotbeopened:set(not canbeopened)
end

function Container:CanBeOpened()
    return not self._cannotbeopened:value()
end

function Container:CanTakeItemInSlot(item, slot)
    return item ~= nil and
        item.replica.inventoryitem ~= nil and
        item.replica.inventoryitem:CanGoInContainer() and
        (self.itemtestfn == nil or self:itemtestfn(item, slot))
end

function Container:AcceptsStacks()
    return self.acceptsstacks
end

function Container:IsSideWidget()
    return self.issidewidget
end

function Container:SetOpener(opener)
    self.classified.Network:SetClassifiedTarget(opener or self.inst)
    if self.inst.components.container ~= nil then
        for k, v in pairs(self.inst.components.container.slots) do
            v.replica.inventoryitem:SetOwner(self.inst)
        end
    else
        --Should only reach here during container construction
        assert(opener == nil)
    end
end

function Container:IsOpenedBy(guy)
    if self.inst.components.container ~= nil then
        return self.inst.components.container:IsOpenedBy(guy)
    else
        return self._isopen and self.classified ~= nil and guy ~= nil and guy == ThePlayer
    end
end

function Container:IsHolding(item, checkcontainer)
    if self.inst.components.container ~= nil then
        return self.inst.components.container:IsHolding(item, checkcontainer)
    else
        return self.classified ~= nil and self.classified:IsHolding(item, checkcontainer)
    end
end

function Container:GetItemInSlot(slot)
    if self.inst.components.container ~= nil then
        return self.inst.components.container:GetItemInSlot(slot)
    else
        return self.classified ~= nil and self.classified:GetItemInSlot(slot) or nil
    end
end

function Container:GetItems()
    if self.inst.components.container ~= nil then
        return self.inst.components.container.slots
    else
        return self.classified ~= nil and self.classified:GetItems() or {}
    end
end

function Container:IsFull()
    if self.inst.components.container ~= nil then
        return self.inst.components.container:IsFull()
    else
        return self.classified ~= nil and self.classified:IsFull()
    end
end

function Container:Has(prefab, amount)
    if self.inst.components.container ~= nil then
        return self.inst.components.container:Has(prefab, amount)
    elseif self.classified ~= nil then
        return self.classified:Has(prefab, amount)
    else
        return amount <= 0, 0
    end
end

function Container:Open(doer)
    if self.inst.components.container ~= nil then
        if self.opentask ~= nil then
            self.opentask:Cancel()
            self.opentask = nil
        end
        self.inst.components.container:Open(doer)
    elseif self.classified ~= nil and
        self.opentask == nil and
        doer ~= nil and
        doer == ThePlayer then
        if doer.HUD == nil then
            self._isopen = false
        elseif not self._isopen then
            doer.HUD:OpenContainer(self.inst, self:IsSideWidget())
            if self:IsSideWidget() then
                TheFocalPoint.SoundEmitter:PlaySound("dontstarve/wilson/backpack_open", "open")
            end
            self._isopen = true
        end
    end
end

function Container:Close()
    if self.opentask ~= nil then
        self.opentask:Cancel()
        self.opentask = nil
    end
    if self.inst.components.container ~= nil then
        self.inst.components.container:Close()
    elseif self._isopen then
        if ThePlayer ~= nil and ThePlayer.HUD ~= nil then
            ThePlayer.HUD:CloseContainer(self.inst, self:IsSideWidget())
            if self:IsSideWidget() then
                TheFocalPoint.SoundEmitter:PlaySound("dontstarve/wilson/backpack_close", "open")
            end
        end
        self._isopen = false
    end
end

function Container:IsBusy()
    return self.inst.components.container == nil and (self.classified == nil or self.classified:IsBusy())
end

--------------------------------------------------------------------------
--InvSlot click action handlers
--------------------------------------------------------------------------

function Container:PutOneOfActiveItemInSlot(slot)
    if self.inst.components.container ~= nil then
        self.inst.components.container:PutOneOfActiveItemInSlot(slot)
    elseif self.classified ~= nil then
        self.classified:PutOneOfActiveItemInSlot(slot)
    end
end

function Container:PutAllOfActiveItemInSlot(slot)
    if self.inst.components.container ~= nil then
        self.inst.components.container:PutAllOfActiveItemInSlot(slot)
    elseif self.classified ~= nil then
        self.classified:PutAllOfActiveItemInSlot(slot)
    end
end

function Container:TakeActiveItemFromHalfOfSlot(slot)
    if self.inst.components.container ~= nil then
        self.inst.components.container:TakeActiveItemFromHalfOfSlot(slot)
    elseif self.classified ~= nil then
        self.classified:TakeActiveItemFromHalfOfSlot(slot)
    end
end

function Container:TakeActiveItemFromAllOfSlot(slot)
    if self.inst.components.container ~= nil then
        self.inst.components.container:TakeActiveItemFromAllOfSlot(slot)
    elseif self.classified ~= nil then
        self.classified:TakeActiveItemFromAllOfSlot(slot)
    end
end

function Container:AddOneOfActiveItemToSlot(slot)
    if self.inst.components.container ~= nil then
        self.inst.components.container:AddOneOfActiveItemToSlot(slot)
    elseif self.classified ~= nil then
        self.classified:AddOneOfActiveItemToSlot(slot)
    end
end

function Container:AddAllOfActiveItemToSlot(slot)
    if self.inst.components.container ~= nil then
        self.inst.components.container:AddAllOfActiveItemToSlot(slot)
    elseif self.classified ~= nil then
        self.classified:AddAllOfActiveItemToSlot(slot)
    end
end

function Container:SwapActiveItemWithSlot(slot)
    if self.inst.components.container ~= nil then
        self.inst.components.container:SwapActiveItemWithSlot(slot)
    elseif self.classified ~= nil then
        self.classified:SwapActiveItemWithSlot(slot)
    end
end

function Container:MoveItemFromAllOfSlot(slot, container)
    if self.inst.components.container ~= nil then
        self.inst.components.container:MoveItemFromAllOfSlot(slot, container)
    elseif self.classified ~= nil then
        self.classified:MoveItemFromAllOfSlot(slot, container)
    end
end

function Container:MoveItemFromHalfOfSlot(slot, container)
    if self.inst.components.container ~= nil then
        self.inst.components.container:MoveItemFromHalfOfSlot(slot, container)
    elseif self.classified ~= nil then
        self.classified:MoveItemFromHalfOfSlot(slot, container)
    end
end

--------------------------------------------------------------------------

return Container