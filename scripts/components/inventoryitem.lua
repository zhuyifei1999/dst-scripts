local function onatlasname(self, atlasname)
    self.inst.replica.inventoryitem:SetAtlas(atlasname)
end

local function onimagename(self, imagename)
    self.inst.replica.inventoryitem:SetImage(imagename)
end

local function onowner(self, owner)
    self.inst.replica.inventoryitem:SetOwner(owner)
end

local function oncanbepickedup(self, canbepickedup)
    self.inst.replica.inventoryitem:SetCanBePickedUp(canbepickedup)
end

local function oncangoincontainer(self, cangoincontainer)
    self.inst.replica.inventoryitem:SetCanGoInContainer(cangoincontainer)
end

local InventoryItem = Class(function(self, inst)
    self.inst = inst

    self.owner = nil
    self.canbepickedup = true
    self.canbepickedupalive = false --added for minion pickup behaviour, e.g. eyeplants
    self.onpickupfn = nil
    self.isnew = true
    self.nobounce = false
    self.cangoincontainer = true
    self.inst:ListenForEvent("stacksizechange", 
        function(inst, data)
            if self.owner then
                self.owner:PushEvent("stacksizechange", { item = self.inst, src_pos = data.src_pos, stacksize = data.stacksize, oldstacksize = data.oldstacksize })
            end
    end)
    self.keepondeath = false
    self.atlasname = nil
    self.imagename = nil
    self.onactiveitemfn = nil
    self.trappable = true

    if self.inst.components.waterproofer == nil then
        self:EnableMoisture(true)
    end
end,
nil,
{
    atlasname = onatlasname,
    imagename = onimagename,
    owner = onowner,
    canbepickedup = oncanbepickedup,
    cangoincontainer = oncangoincontainer,
})

function InventoryItem:OnRemoveFromEntity()
    self:EnableMoisture(false)
end

--Provided specifically for waterproofer component
function InventoryItem:EnableMoisture(enable)
    if enable == false then
        if self.inst.components.inventoryitemmoisture ~= nil then
            self.inst:RemoveComponent("inventoryitemmoisture")
        end
    elseif self.inst.components.inventoryitemmoisture == nil then
        self.inst:AddComponent("inventoryitemmoisture")
        self.inst.components.inventoryitemmoisture:AttachReplica(self.inst.replica.inventoryitem)
    end
end

function InventoryItem:GetMoisture()
    return self.inst.components.inventoryitemmoisture ~= nil and self.inst.components.inventoryitemmoisture.moisture or 0
end

function InventoryItem:IsWet()
    return self.inst.components.inventoryitemmoisture ~= nil and self.inst.components.inventoryitemmoisture.iswet
end

function InventoryItem:InheritMoisture(moisture, iswet)
    if self.inst.components.inventoryitemmoisture ~= nil then
        self.inst.components.inventoryitemmoisture:InheritMoisture(moisture, iswet)
    end
end

function InventoryItem:DiluteMoisture(item, count)
    if self.inst.components.inventoryitemmoisture ~= nil then
        self.inst.components.inventoryitemmoisture:DiluteMoisture(item, count)
    end
end

function InventoryItem:AddMoisture(delta)
    if self.inst.components.inventoryitemmoisture ~= nil then
        self.inst.components.inventoryitemmoisture:DoDelta(delta)
    end
end

function InventoryItem:SetOwner(owner)
    self.owner = owner
end

function InventoryItem:ClearOwner(owner)
    self.owner = nil
end

function InventoryItem:SetOnDroppedFn(fn)
    self.ondropfn = fn
end

function InventoryItem:SetOnActiveItemFn(fn)
    self.onactiveitemfn = fn 
end

function InventoryItem:SetOnPickupFn(fn)
    self.onpickupfn = fn
end

function InventoryItem:SetOnPutInInventoryFn(fn)
    self.onputininventoryfn = fn
end

function InventoryItem:GetSlotNum()
    if self.owner ~= nil then
        local ct = self.owner.components.container or self.owner.components.inventory
        return ct ~= nil and ct:GetItemSlot(self.inst) or nil
    end
end

function InventoryItem:GetContainer()
    if self.owner then
        return self.owner.components.container or self.owner.components.inventory
    end
end

function InventoryItem:HibernateLivingItem()
    if self.inst.components.brain then
        BrainManager:Hibernate(self.inst)
    end

    if self.inst.SoundEmitter then
        self.inst.SoundEmitter:KillAllSounds()
    end
end

function InventoryItem:WakeLivingItem()
    if self.inst.components.brain then
        BrainManager:Wake(self.inst)
    end
end

function InventoryItem:OnPutInInventory(owner)
--    print(string.format("InventoryItem:OnPutInInventory[%s]", self.inst.prefab))
--    print("   transform=", Point(self.inst.Transform:GetWorldPosition()))
    self.inst.components.inventoryitem:SetOwner(owner)
    owner:AddChild(self.inst)
    self.inst:RemoveFromScene()
    self.inst.Transform:SetPosition(0,0,0) -- transform is now local?
--    print("   updated transform=", Point(self.inst.Transform:GetWorldPosition()))
    self:HibernateLivingItem()
    if self.onputininventoryfn then
        self.onputininventoryfn(self.inst, owner)
    end
    self.inst:PushEvent("onputininventory", owner)
end

function InventoryItem:OnRemoved()
    if self.owner then
        self.owner:RemoveChild(self.inst)
    end
    self:ClearOwner()
    self.inst:ReturnToScene()
    self:WakeLivingItem()
end

function InventoryItem:OnDropped(randomdir)
    --print("InventoryItem:OnDropped", self.inst, randomdir)

    if not self.inst:IsValid() then
        return
    end

    --print("OWNER", self.owner, self.owner and Point(self.owner.Transform:GetWorldPosition()))

    local x, y, z
    if self.owner ~= nil then
        -- if we're owned, our own coords are junk at this point
        x, y, z = self.owner.Transform:GetWorldPosition()
    else
        x, y, z = self.inst.Transform:GetWorldPosition()
        --print("pos", x,y,z)
    end

    --print("REMOVED", self.inst)
    self:OnRemoved()

    -- now in world space, if we weren't already
    --print("setpos", x,y,z)
    self.inst.Transform:SetPosition(x, y, z)

    if self.inst.Physics ~= nil then
        if not self.nobounce then
            y = y + 1
            --print("setpos", x,y,z)
            self.inst.Physics:Teleport(x, y, z)
        end

        -- convert x, y, z to velocity
        if randomdir then
            local speed = 2 + math.random()
            local angle = math.random() * 2 * PI
            x = speed * math.cos(angle)
            y = self.nobounce and 0 or speed * 3
            z = -speed * math.sin(angle)
        else
            x = 0
            y = self.nobounce and 0 or 5
            z = 0
        end
        --print("vel", x, y, z)
        self.inst.Physics:SetVel(x, y, z)
    end

    if self.ondropfn ~= nil then
        self.ondropfn(self.inst)
    end
    self.inst:PushEvent("ondropped")

    if self.inst.components.propagator ~= nil then
        self.inst.components.propagator:Delay(5)
    end
end

-- If this function retrns true then it has destroyed itself and you shouldnt give it to the player
function InventoryItem:OnPickup(pickupguy)
-- not only the player can have inventory!   
   if self.isnew and self.inst.prefab and pickupguy:HasTag("player") then
        ProfileStatsAdd("collect_"..self.inst.prefab)
        self.isnew = false
    end

    if self.inst.components.burnable and self.inst.components.burnable:IsSmoldering() then
        self.inst.components.burnable:StopSmoldering()
        if pickupguy.components.health then
            pickupguy.components.health:DoFireDamage(TUNING.SMOTHER_DAMAGE, nil, true)
            pickupguy:PushEvent("burnt")
        end
    end

    self.inst.Transform:SetPosition(0,0,0)
    self.inst:PushEvent("onpickup", {owner = pickupguy})
    if self.onpickupfn and type(self.onpickupfn) == "function" then
        return self.onpickupfn(self.inst, pickupguy)
    end
end

function InventoryItem:IsHeld()
    return self.owner ~= nil
end

function InventoryItem:IsHeldBy(guy)
    return self.owner == guy
end

function InventoryItem:ChangeImageName(newname)
    self.imagename = newname
    self.inst:PushEvent("imagechange")
end

function InventoryItem:RemoveFromOwner(wholestack)
    if self.owner == nil then
        return
    elseif self.owner.components.inventory ~= nil then
        return self.owner.components.inventory:RemoveItem(self.inst, wholestack)
    elseif self.owner.components.container ~= nil then
        return self.owner.components.container:RemoveItem(self.inst, wholestack)
    end
end

function InventoryItem:OnRemoveEntity()
    self:RemoveFromOwner(true)
    TheWorld:PushEvent("forgetinventoryitem", self.inst)
end

function InventoryItem:GetGrandOwner()
    if self.owner then
        if self.owner.components.inventoryitem then
            return self.owner.components.inventoryitem:GetGrandOwner()
        else
            return self.owner
        end
    end
end

function InventoryItem:IsSheltered()
    return self:IsHeld() and 
    ((self.owner.components.container) or (self.owner.components.inventory and self.owner.components.inventory:IsWaterproof()))
end

return InventoryItem
