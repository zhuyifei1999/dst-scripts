local function OnRemoveEntity(inst)
    if inst._parent ~= nil then
        inst._parent.inventoryitem_classified = nil
    end
end

local function OnEntityReplicated(inst)
    inst._parent = inst.entity:GetParent()
    if inst._parent == nil then
        print("Unable to initialize classified data for inventory item")
    elseif inst._parent.replica.inventoryitem ~= nil then
        inst._parent.replica.inventoryitem:AttachClassified(inst)
    else
        inst._parent.inventoryitem_classified = inst
        inst.OnRemoveEntity = OnRemoveEntity
    end
end

local function OnImageDirty(inst)
    if inst._parent ~= nil then
        inst._parent:PushEvent("imagechange")
    end
end

local function SerializePercentUsed(inst, percent)
    if percent ~= nil then
        percent = math.floor(percent * 100 + .5)
        inst.percentused:set(percent <= 1 and 1 or (percent >= 100 and 100 or percent))
    else
        inst.percentused:set(255)
    end
end

local function DeserializePercentUsed(inst)
    if inst.percentused:value() ~= 255 and inst._parent ~= nil then
        inst._parent:PushEvent("percentusedchange", { percent = inst.percentused:value() / 100 })
    end
end

local function SerializePerish(inst, percent)
    if percent ~= nil then
        percent = math.floor(percent * 62 + .5)
        inst.perish:set(percent >= 62 and 62 or percent)
    else
        inst.perish:set(63)
    end
end

local function DeserializePerish(inst)
    if inst.perish:value() ~= 63 and inst._parent ~= nil then
        inst._parent:PushEvent("perishchange", { percent = inst.perish:value() / 62 })
    end
end

local function OnStackSizeDirty(parent)
    TheWorld:PushEvent("stackitemdirty", parent)
end

local function RegisterNetListeners(inst)
    inst:ListenForEvent("imagedirty", OnImageDirty)
    inst:ListenForEvent("percentuseddirty", DeserializePercentUsed)
    inst:ListenForEvent("perishdirty", DeserializePerish)
    inst:ListenForEvent("stacksizedirty", OnStackSizeDirty, inst._parent)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddNetwork()
    inst.entity:Hide()
    inst:AddTag("CLASSIFIED")

    inst.image = net_hash(inst.GUID, "inventoryitem.image", "imagedirty")
    inst.atlas = net_hash(inst.GUID, "inventoryitem.atlas", "imagedirty")
    inst.cangoincontainer = net_bool(inst.GUID, "inventoryitem.cangoincontainer")
    inst.src_pos =
    {
        isvalid = net_bool(inst.GUID, "inventoryitem.src_pos.isvalid"),
        x = net_float(inst.GUID, "inventoryitem.src_pos.x"),
        z = net_float(inst.GUID, "inventoryitem.src_pos.z"),
    }
    inst.percentused = net_byte(inst.GUID, "inventoryitem.percentused", "percentuseddirty")
    inst.perish = net_smallbyte(inst.GUID, "inventoryitem.perish", "perishdirty")
    inst.deploymode = net_tinybyte(inst.GUID, "deployable.mode")
    inst.deployspacing = net_tinybyte(inst.GUID, "deployable.spacing")
    inst.usegridplacer = net_bool(inst.GUID, "deployable.usegridplacer")
    inst.attackrange = net_float(inst.GUID, "weapon.attackrange")
    inst.walkspeedmult = net_byte(inst.GUID, "equippable.walkspeedmult")

    inst.image:set(0)
    inst.atlas:set(0)
    inst.cangoincontainer:set(true)
    inst.src_pos.isvalid:set(false)
    inst.percentused:set(255)
    inst.perish:set(63)
    inst.deploymode:set(DEPLOYMODE.NONE)
    inst.deployspacing:set(DEPLOYSPACING.DEFAULT)
    inst.usegridplacer:set(false)
    inst.attackrange:set(-1)
    inst.walkspeedmult:set(1)

    if not TheWorld.ismastersim then
        inst.DeserializePercentUsed = DeserializePercentUsed
        inst.DeserializePerish = DeserializePerish
        inst.OnEntityReplicated = OnEntityReplicated

        --Delay net listeners until after initial values are deserialized
        inst:DoTaskInTime(0, RegisterNetListeners)
        return inst
    end

    inst.entity:AddTransform() --So we can follow parent's sleep state
    inst.entity:SetPristine()

    inst.persists = false

    inst.SerializePercentUsed = SerializePercentUsed
    inst.SerializePerish = SerializePerish

    return inst
end

return Prefab("inventoryitem_classified", fn)