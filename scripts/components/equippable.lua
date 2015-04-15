local function onequipslot(self, equipslot)
    self.inst.replica.equippable:SetEquipSlot(equipslot)
end

--Update inventoryitem_replica constructor if any more properties are added

local function onwalkspeedmult(self, walkspeedmult)
    if self.inst.replica.inventoryitem ~= nil then
        self.inst.replica.inventoryitem:SetWalkSpeedMult(walkspeedmult)
    end
end

local Equippable = Class(function(self, inst)
    self.inst = inst

    self.isequipped = false
    self.equipslot = EQUIPSLOTS.HANDS
    self.onequipfn = nil
    self.onunequipfn = nil
    self.onpocketfn = nil
    self.equipstack = false
    self.walkspeedmult = nil
end,
nil,
{
    equipslot = onequipslot,
    walkspeedmult = onwalkspeedmult,
})

function Equippable:OnRemoveFromEntity()
    if self.inst.replica.inventoryitem ~= nil then
        self.inst.replica.inventoryitem:SetWalkSpeedMult(1)
    end
end

function Equippable:SetOnEquip(fn)
    self.onequipfn = fn
end

function Equippable:SetOnPocket(fn)
    self.onpocketfn = fn
end

function Equippable:SetOnUnequip(fn)
    self.onunequipfn = fn
end

function Equippable:IsEquipped()
    return self.isequipped
end

function Equippable:Equip(owner, slot)
    self.isequipped = true
    
    if self.onequipfn then
        self.onequipfn(self.inst, owner)
    end
    self.inst:PushEvent("equipped", {owner=owner, slot=slot})

end

function Equippable:ToPocket(owner)
    if self.onpocketfn then
        self.onpocketfn(self.inst, owner)
    end

end

function Equippable:Unequip(owner, slot)
    self.isequipped = false
    
    if self.onunequipfn then
        self.onunequipfn(self.inst, owner)
    end
    
    self.inst:PushEvent("unequipped", {owner=owner, slot=slot})
end

function Equippable:GetWalkSpeedMult()
	return self.walkspeedmult or 1.0
end

return Equippable