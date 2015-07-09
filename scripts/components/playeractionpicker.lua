local PlayerActionPicker = Class(function(self, inst)
    self.inst = inst
    self.map = TheWorld.Map
    self.containers = {}
    self.leftclickoverride = nil
    self.rightclickoverride = nil
end)

function PlayerActionPicker:RegisterContainer(container)
    if container ~= nil and self.containers[container] == nil then
        self.containers[container] = function()
            self:UnregisterContainer(container)
        end
        self.inst:ListenForEvent("onremove", self.containers[container], container)
    end
end

function PlayerActionPicker:UnregisterContainer(container)
    if container ~= nil and self.containers[container] ~= nil then
        self.inst:RemoveEventCallback("onremove", self.containers[container], container)
        self.containers[container] = nil
    end
end

local function OrderByPriority(l, r)
    return l.priority > r.priority
end

-- All the action picker functions that do the heavy lifting run their resulting table through the SortActionList function
-- so we can just do the ghost action selection here, rather than littering it throughout the component.
function PlayerActionPicker:SortActionList(actions, target, useitem)
    if #actions == 0 then
        return actions
    end

    table.sort(actions, OrderByPriority)

    local ret = {}

    for i, v in ipairs(actions) do
        if self.actionfilter ~= nil and not self.actionfilter(self.inst, v) then
            --filtered
        elseif target == nil then
            table.insert(ret, BufferedAction(self.inst, nil, v, useitem))
        elseif target:is_a(EntityScript) then
            table.insert(ret, BufferedAction(self.inst, target, v, useitem))
        elseif target:is_a(Vector3) then
            table.insert(ret, BufferedAction(self.inst, nil, v, useitem, target))
        end
    end

    return ret
end

function PlayerActionPicker:GetSceneActions(useitem, right)
    local actions = {}

    useitem:CollectActions("SCENE", self.inst, actions, right)

    if useitem ~= self.inst then
        if not right and useitem.inherentsceneaction ~= nil then
            table.insert(actions, useitem.inherentsceneaction)
        elseif right and useitem.inherentscenealtaction ~= nil then
            table.insert(actions, useitem.inherentscenealtaction)
        end
    end

    local sorted_acts = self:SortActionList(actions, useitem)

    if #sorted_acts == 0 and
        useitem ~= self.inst and
        (self.inst.CanExamine == nil or self.inst:CanExamine()) and
        useitem:HasTag("inspectable") and
        (self.inst.sg == nil or self.inst.sg:HasStateTag("moving") or self.inst.sg:HasStateTag("idle")) and
        (self.inst:HasTag("moving") or self.inst:HasTag("idle")) then
        sorted_acts = self:SortActionList({ ACTIONS.WALKTO }, useitem)
    end

    return sorted_acts
end


function PlayerActionPicker:GetUseItemActions(target, useitem, right)
    local actions = {}

    useitem:CollectActions("USEITEM", self.inst, target, actions, right)

    return self:SortActionList(actions, target, useitem)
end

function PlayerActionPicker:GetPointActions(pos, useitem, right)
    local actions = {}

    useitem:CollectActions("POINT", self.inst, pos, actions, right)

    local sorted_acts = self:SortActionList(actions, pos, useitem)

    if not self.inst.components.playercontroller:IsControlPressed(CONTROL_FORCE_STACK) then
        for i, v in ipairs(sorted_acts) do
            if v.action == ACTIONS.DROP then
                v.options.wholestack = true
                break
            end
        end
    end

    return sorted_acts
end

function PlayerActionPicker:GetEquippedItemActions(target, useitem, right)
    local actions = {}

    useitem:CollectActions("EQUIPPED", self.inst, target, actions, right)

    return self:SortActionList(actions, target, useitem)
end

function PlayerActionPicker:GetInventoryActions(useitem, right)
    local actions = {}

    useitem:CollectActions("INVENTORY", self.inst, actions, right)

    local sorted_acts = self:SortActionList(actions, nil, useitem)

    if not self.inst.components.playercontroller:IsControlPressed(CONTROL_FORCE_STACK) then
        for i, v in ipairs(sorted_acts) do
            if v.action == ACTIONS.DROP then
                v.options.wholestack = true
                break
            end
        end
    end
    
    return sorted_acts
end

function PlayerActionPicker:GetLeftClickActions(position, target)
    if self.leftclickoverride ~= nil then
        local actions, usedefault = self.leftclickoverride(self.inst, target, position)
        if not usedefault or (actions ~= nil and #actions > 0) then
            return actions or {}
        end
    end

    local actions = nil
    local useitem = self.inst.replica.inventory:GetActiveItem()
    local equipitem = self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    local ispassable = self.map:IsPassableAtPoint(position:Get())

    --if we're specifically using an item, see if we can use it on the target entity
    if useitem ~= nil then
        if useitem:IsValid() then
            if target == self.inst then
                actions = self:GetInventoryActions(useitem)
            elseif target ~= nil then
                actions = self:GetUseItemActions(target, useitem)
            elseif ispassable then
                actions = self:GetPointActions(position, useitem)
            end
        end
    elseif target ~= nil and target ~= self.inst then
        --if we're clicking on a scene entity, see if we can use our equipped object on it, or just use it
        if self.inst.components.playercontroller:IsControlPressed(CONTROL_FORCE_INSPECT) and
            target:HasTag("inspectable") and
            (self.inst.CanExamine == nil or self.inst:CanExamine()) and
            (self.inst.sg == nil or self.inst.sg:HasStateTag("moving") or self.inst.sg:HasStateTag("idle")) and
            (self.inst:HasTag("moving") or self.inst:HasTag("idle")) then
            actions = self:SortActionList({ ACTIONS.LOOKAT }, target, nil)
        elseif self.inst.components.playercontroller:IsControlPressed(CONTROL_FORCE_ATTACK) and target.replica.combat ~= nil and self.inst.replica.combat:CanTarget(target) then
            actions = self:SortActionList({ ACTIONS.ATTACK }, target, nil)
        elseif equipitem ~= nil and equipitem:IsValid() then
            actions = self:GetEquippedItemActions(target, equipitem)
        end

        if actions == nil or #actions == 0 then
            actions = self:GetSceneActions(target)
        end
    end

    if actions == nil and target == nil and equipitem ~= nil and equipitem:IsValid() and ispassable then
        --can we use our equipped item at the point?
        actions = self:GetPointActions(position, equipitem)
        --this is to make it so you don't auto-drop equipped items when you left click the ground. kinda ugly.
        if actions ~= nil then
            for i, v in ipairs(actions) do
                if v.action == ACTIONS.DROP then
                    table.remove(actions, i)
                    break
                end
            end
        end
    end

    return actions or {}
end

function PlayerActionPicker:GetRightClickActions(position, target)
    if self.rightclickoverride ~= nil then
        local actions, usedefault = self.rightclickoverride(self.inst, target, position)
        if not usedefault or (actions ~= nil and #actions > 0) then
            return actions or {}
        end
    end

    local actions = nil
    local useitem = self.inst.replica.inventory:GetActiveItem()
    local equipitem = self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    local ispassable = self.map:IsPassableAtPoint(position:Get())

    if target ~= nil and self.containers[target] then
        --check if we have container widget actions
        actions = self:GetSceneActions(target, true)
    elseif useitem ~= nil then
        --if we're specifically using an item, see if we can use it on the target entity
        if useitem:IsValid() then
            if target == self.inst then
                actions = self:GetInventoryActions(useitem, true)
            elseif target ~= nil then
                actions = self:GetUseItemActions(target, useitem, true)
            elseif ispassable then
                actions = self:GetPointActions(position, useitem, true)
            end
        end
    elseif target ~= nil then
        --if we're clicking on a scene entity, see if we can use our equipped object on it, or just use it
        if equipitem ~= nil and equipitem:IsValid() then
            actions = self:GetEquippedItemActions(target, equipitem, true)
        end

        if actions == nil or #actions == 0 then
            actions = self:GetSceneActions(target, true)
        end
    elseif equipitem ~= nil and equipitem:IsValid() and ispassable then
        actions = self:GetPointActions(position, equipitem, true)
    end

    return actions or {}
end

function PlayerActionPicker:DoGetMouseActions(position, target)
    if position == nil then
        if TheInput:GetHUDEntityUnderMouse() ~= nil then
            return
        elseif target == nil then
            target = TheInput:GetWorldEntityUnderMouse()
        end
        position = TheInput:GetWorldPosition()

        local cansee
        if target == nil then
            local x, y, z = position:Get()
            cansee = CanEntitySeePoint(self.inst, x, y, z)
        else
            cansee = target == self.inst or CanEntitySeeTarget(self.inst, target)
        end

        --Check for actions in the dark
        if not cansee then
            if self.inst:GetDistanceSqToPoint(position:Get()) < 16 then
                local lmbs = self:GetLeftClickActions(position)
                for i, v in ipairs(lmbs) do
                    if v.action == ACTIONS.DROP then
                        return v
                    end
                end
            end
            return
        end
    end

    local leftActions = self:GetLeftClickActions(position, target)
    local rightActions = self:GetRightClickActions(position, target)
    local lmb = leftActions and leftActions[1]
    local rmb = rightActions and rightActions[1]

    return lmb, rmb ~= nil and (lmb == nil or lmb.action ~= rmb.action) and rmb or nil
end

return PlayerActionPicker