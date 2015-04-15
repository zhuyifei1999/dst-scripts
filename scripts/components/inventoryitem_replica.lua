local DEFAULT_ATLAS = "images/inventoryimages.xml"

local InventoryItem = Class(function(self, inst)
    self.inst = inst

    self._cannotbepickedup = net_bool(inst.GUID, "inventoryitem._cannotbepickedup")

    if TheWorld.ismastersim then
        self.classified = SpawnPrefab("inventoryitem_classified")
        self.classified.entity:SetParent(inst.entity)

        inst:ListenForEvent("percentusedchange", function(inst, data) self.classified:SerializePercentUsed(data.percent) end)
        inst:ListenForEvent("perishchange", function(inst, data) self.classified:SerializePerish(data.percent) end)

        if inst.components.deployable ~= nil then
            self:SetDeployMode(inst.components.deployable.mode)
            self:SetDeploySpacing(inst.components.deployable.spacing)
            self:SetUseGridPlacer(inst.components.deployable.usegridplacer)
        end

        if inst.components.weapon ~= nil then
            self:SetAttackRange(inst.components.weapon.attackrange or 0)
        end

        if inst.components.equippable ~= nil then
            self:SetWalkSpeedMult(inst.components.equippable.walkspeedmult or 1)
        end
    elseif self.classified == nil and inst.inventoryitem_classified ~= nil then
        self:AttachClassified(inst.inventoryitem_classified)
        inst.inventoryitem_classified.OnRemoveEntity = nil
        inst.inventoryitem_classified = nil
    end
end)

--------------------------------------------------------------------------

function InventoryItem:OnRemoveFromEntity()
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

InventoryItem.OnRemoveEntity = InventoryItem.OnRemoveFromEntity

function InventoryItem:AttachClassified(classified)
    self.classified = classified
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)
end

function InventoryItem:DetachClassified()
    self.classified = nil
    self.ondetachclassified = nil
end

--------------------------------------------------------------------------

function InventoryItem:SetCanBePickedUp(canbepickedup)
    self._cannotbepickedup:set(not canbepickedup)
end

function InventoryItem:CanBePickedUp()
    return not self._cannotbepickedup:value()
end

function InventoryItem:SetCanGoInContainer(cangoincontainer)
    self.classified.cangoincontainer:set(cangoincontainer)
end

function InventoryItem:CanGoInContainer()
    return self.classified ~= nil and self.classified.cangoincontainer:value()
end

function InventoryItem:SetImage(imagename)
    self.classified.image:set(imagename ~= nil and (imagename..".tex") or 0)
end

function InventoryItem:GetImage()
    return self.classified ~= nil and
        self.classified.image:value() ~= 0 and
        self.classified.image:value() or
        (self.inst.prefab..".tex")
end

function InventoryItem:SetAtlas(atlasname)
    self.classified.atlas:set(atlasname ~= nil and atlasname ~= DEFAULT_ATLAS and resolvefilepath(atlasname) or 0)
end

function InventoryItem:GetAtlas()
    return self.classified ~= nil and
        self.classified.atlas:value() ~= 0 and
        self.classified.atlas:value() or
        DEFAULT_ATLAS
end

function InventoryItem:SetOwner(owner)
    owner = owner ~= nil and owner.components.container ~= nil and owner.components.container.opener or owner
    assert(owner == nil or
        not owner:HasTag("player") or
        self.inst.components.weapon == nil or
        self.inst.components.weapon.variedmodefn == nil,
        "Players cannot access varied mode weapons")
    if self.inst.Network ~= nil then
        self.inst.Network:SetClassifiedTarget(owner)
    end
    self.classified.Network:SetClassifiedTarget(owner or self.inst)
end

function InventoryItem:IsHeld()
    if self.inst.components.inventoryitem ~= nil then
        return self.inst.components.inventoryitem:IsHeld()
    else
        return self.classified ~= nil
    end
end

function InventoryItem:IsHeldBy(guy)
    if self.inst.components.inventoryitem ~= nil then
        return self.inst.components.inventoryitem:IsHeldBy(guy)
    else
        return self.classified ~= nil and guy ~= nil and guy == ThePlayer and
            guy.replica.inventory:IsHolding(self.inst)
    end
end

function InventoryItem:IsGrandOwner(guy)
    if self.inst.components.inventoryitem ~= nil then
        return self.inst.components.inventoryitem:GetGrandOwner() == guy
    else
        return self.classified ~= nil and guy ~= nil and guy == ThePlayer and
            guy.replica.inventory:IsHolding(self.inst, true)
    end
end

function InventoryItem:SetPickupPos(pos)
    if pos ~= nil then
        self.classified.src_pos.isvalid:set(true)
        self.classified.src_pos.x:set(pos.x)
        self.classified.src_pos.z:set(pos.z)
    else
        self.classified.src_pos.isvalid:set(false)
    end
end

function InventoryItem:GetPickupPos()
    if self.classified ~= nil then
        local src_pos = self.classified.src_pos
        return src_pos.isvalid:value() and Vector3(src_pos.x:value(), 0, src_pos.z:value()) or nil
    end
end

function InventoryItem:SerializeUsage()
    local percentusedcomponent =
        self.inst.components.armor or
        self.inst.components.finiteuses or
        self.inst.components.fueled

    self.classified:SerializePercentUsed(percentusedcomponent ~= nil and percentusedcomponent:GetPercent() or nil)
    self.classified:SerializePerish(self.inst.components.perishable ~= nil and self.inst.components.perishable:GetPercent() or nil)
end

function InventoryItem:DeserializeUsage()
    if self.classified ~= nil then
        self.classified:DeserializePercentUsed()
        self.classified:DeserializePerish()
    end
end

function InventoryItem:SetDeployMode(deploymode)
    self.classified.deploymode:set(deploymode)
end

function InventoryItem:IsDeployable()
    if self.inst.components.deployable ~= nil then
        return true
    elseif self.classified ~= nil then
        return self.classified.deploymode:value() ~= DEPLOYMODE.NONE
    else
        return false
    end
end

function InventoryItem:SetDeploySpacing(deployspacing)
    self.classified.deployspacing:set(deployspacing)
end

function InventoryItem:DeploySpacingSq()
    if self.inst.components.deployable ~= nil then
        return self.inst.components.deployable:DeploySpacingSq()
    elseif self.classified ~= nil then
        return DEPLOYSPACING_SQ[self.classified.deployspacing:value()]
    else
        return DEPLOYSPACING_SQ[DEPLOYSPACING.DEFAULT]
    end
end

function InventoryItem:CanDeploy(pt, mouseover)
    if self.inst.components.deployable ~= nil then
        return self.inst.components.deployable:CanDeploy(pt, mouseover)
    elseif self.classified == nil then
        return false
    elseif self.classified.deploymode:value() == DEPLOYMODE.ANYWHERE then
        return TheWorld.Map:IsPassableAtPoint(pt:Get())
    elseif self.classified.deploymode:value() == DEPLOYMODE.TURF then
        return TheWorld.Map:CanPlaceTurfAtPoint(pt:Get())
    elseif self.classified.deploymode:value() == DEPLOYMODE.PLANT then
        return TheWorld.Map:CanDeployPlantAtPoint(pt, self.inst)
    elseif self.classified.deploymode:value() == DEPLOYMODE.WALL then
        return TheWorld.Map:CanDeployWallAtPoint(pt, self.inst)
    elseif self.classified.deploymode:value() == DEPLOYMODE.DEFAULT then
        return TheWorld.Map:CanDeployAtPoint(pt, self.inst, mouseover)
    end
end

function InventoryItem:SetUseGridPlacer(usegridplacer)
    self.classified.usegridplacer:set(usegridplacer)
end

function InventoryItem:GetDeployPlacerName()
    if self.inst.components.deployable ~= nil then
        if self.inst.components.deployable.usegridplacer then
            return "gridplacer"
        end
    elseif self.classified ~= nil and self.classified.usegridplacer:value() then
        return "gridplacer"
    end
    return (self.inst.prefab or "").."_placer"
end

function InventoryItem:SetAttackRange(attackrange)
    self.classified.attackrange:set(attackrange or 0)
end

function InventoryItem:AttackRange()
    if self.inst.components.weapon ~= nil then
        return self.inst.components.weapon.variedmodefn ~= nil and
            (self.inst.components.weapon.variedmodefn(self.inst).attackrange or 0) or
            self.inst.components.weapon.attackrange or 0
    elseif self.classified ~= nil then
        return math.max(0, self.classified.attackrange:value())
    else
        return 0
    end
end

function InventoryItem:IsWeapon()
    return self.inst.components.weapon ~= nil or
        (self.classified ~= nil and
        self.classified.attackrange:value() >= 0)
end

function InventoryItem:SetWalkSpeedMult(walkspeedmult)
    local x = math.floor((walkspeedmult or 1) * 100)
    assert(x >= 0 and x <= 255, "Walk speed multiplier out of range: "..tostring(walkspeedmult))
    assert(walkspeedmult == nil or math.abs(walkspeedmult * 100 - x) < .01 , "Walk speed multiplier can only have up to .01 precision: "..tostring(walkspeedmult))
    self.classified.walkspeedmult:set(x)
end

function InventoryItem:GetWalkSpeedMult()
    if self.inst.components.equippable ~= nil then
        return self.inst.components.equippable:GetWalkSpeedMult()
    elseif self.classified ~= nil then
        return self.classified.walkspeedmult:value() / 100
    else
        return 1
    end
end

return InventoryItem