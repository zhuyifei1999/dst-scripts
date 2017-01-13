local assets =
{
    Asset("ANIM", "anim/redlantern.zip"),
    Asset("ANIM", "anim/swap_redlantern.zip"),
    Asset("INV_IMAGE", "redlantern_lit"),
}

local prefabs =
{
    "redlanternlight",
    "redlanternbody",
}

local LIGHT_RADIUS = 2
local LIGHT_COLOUR = Vector3(200 / 255, 100 / 255, 100 / 255)
local LIGHT_INTENSITY = .8
local LIGHT_FALLOFF = .5

local function OnUpdateFlicker(inst, starttime)
    local time = starttime ~= nil and (GetTime() - starttime) * 15 or 0
    local flicker = (math.sin(time) + math.sin(time + 2) + math.sin(time + 0.7777)) * .5 -- range = [-1 , 1]
    flicker = (1 + flicker) * .5 -- range = 0:1
    inst.Light:SetRadius(LIGHT_RADIUS + .1 * flicker)
    flicker = flicker * 2 / 255
    inst.Light:SetColour(LIGHT_COLOUR.x + flicker, LIGHT_COLOUR.y + flicker, LIGHT_COLOUR.z + flicker)
end

local function turnon(inst)
    if not inst.components.fueled:IsEmpty() then
        if inst.components.fueled ~= nil then
            inst.components.fueled:StartConsuming()
        end

        local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil

        if inst._light == nil or not inst._light:IsValid() then
            inst._light = SpawnPrefab("redlanternlight")
        end
        inst._light.entity:SetParent((owner or inst).entity)

        inst.AnimState:Show("LIGHT")

        if inst._lantern ~= nil then
            inst._lantern.AnimState:Show("LIGHT")
        end

        if not (inst._lantern ~= nil and inst._lantern.entity:IsVisible()) and
            owner ~= nil and inst.components.equippable:IsEquipped() then
            owner.AnimState:Show("LANTERN_OVERLAY")
        end

        inst.components.inventoryitem:ChangeImageName("redlantern_lit")
    end
end

local function turnoff(inst)
    if inst.components.fueled ~= nil then
        inst.components.fueled:StopConsuming()
    end

    if inst._light ~= nil then
        if inst._light:IsValid() then
            inst._light:Remove()
        end
        inst._light = nil
    end

    inst.AnimState:Hide("LIGHT")

    if inst._lantern ~= nil then
        inst._lantern.AnimState:Hide("LIGHT")
    end

    if inst.components.equippable:IsEquipped() then
        inst.components.inventoryitem.owner.AnimState:Hide("LANTERN_OVERLAY")
    end

    inst.components.inventoryitem:ChangeImageName("redlantern")
end

local function OnRemove(inst)
    if inst._light ~= nil and inst._light:IsValid() then
        inst._light:Remove()
    end
end

local function ondropped(inst)
    turnoff(inst)
    turnon(inst)
end

local function onremove(inst)
    if inst._lantern ~= nil then
        inst._lantern:Remove()
        inst._lantern = nil
    end
end

local function ToggleOverrideSymbols(inst, owner)
    if owner.sg:HasStateTag("nodangle") or (owner.components.rider ~= nil and owner.components.rider:IsRiding()) then
        owner.AnimState:OverrideSymbol("swap_object", "swap_redlantern", "swap_redlantern")
        if not inst.components.fueled:IsEmpty() then
            owner.AnimState:Show("LANTERN_OVERLAY")
        end
        inst._lantern:Hide()
    else
        owner.AnimState:OverrideSymbol("swap_object", "swap_redlantern", "swap_redlantern_stick")
        owner.AnimState:Hide("LANTERN_OVERLAY")
        inst._lantern:Show()
    end
end

local function onequip(inst, owner)
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    owner.AnimState:OverrideSymbol("lantern_overlay", "swap_redlantern", "redlantern_overlay")

    inst._lantern = SpawnPrefab("redlanternbody")
    inst._lantern.entity:SetParent(owner.entity)
    inst._lantern.entity:AddFollower()
    inst._lantern.Follower:FollowSymbol(owner.GUID, "swap_object", 68, -126, 0)
    inst._lantern:ListenForEvent("onremove", onremove, inst)
    inst._lantern:ListenForEvent("newstate", function(owner, data)
        ToggleOverrideSymbols(inst, owner)
    end, owner)

    ToggleOverrideSymbols(inst, owner)

    if inst.components.fueled:IsEmpty() then
        inst._lantern.AnimState:Hide("LIGHT")
        owner.AnimState:Hide("LANTERN_OVERLAY")
    else
        if inst._lantern.entity:IsVisible() then
            owner.AnimState:Hide("LANTERN_OVERLAY")
        else
            owner.AnimState:Show("LANTERN_OVERLAY")
        end
        turnon(inst)
    end
end

local function onunequip(inst, owner)
    if inst._lantern ~= nil then
        if inst._lantern.entity:IsVisible() then
            owner.AnimState:OverrideSymbol("swap_object", "swap_redlantern", "swap_redlantern")
        end
        inst._lantern:Remove()
        inst._lantern = nil
    end

    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    owner.AnimState:ClearOverrideSymbol("lantern_overlay")
    owner.AnimState:Hide("LANTERN_OVERLAY")
end

local function nofuel(inst)
    local equippable = inst.components.equippable
    if equippable ~= nil and equippable:IsEquipped() then
        local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
        if owner ~= nil then
            local data =
            {
                prefab = inst.prefab,
                equipslot = equippable.equipslot,
            }
            turnoff(inst)
            owner:PushEvent("torchranout", data)
            return
        end
    end
    turnoff(inst)
end

local function lanternlightfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.Light:SetIntensity(LIGHT_INTENSITY)
    --inst.Light:SetColour(LIGHT_COLOUR.x, LIGHT_COLOUR.y, LIGHT_COLOUR.z)
    inst.Light:SetFalloff(LIGHT_FALLOFF)
    --inst.Light:SetRadius(LIGHT_RADIUS)
    inst.Light:EnableClientModulation(true)

    inst:DoPeriodicTask(.1, OnUpdateFlicker, nil, GetTime())
    OnUpdateFlicker(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("redlantern")
    inst.AnimState:SetBuild("redlantern")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst:AddTag("light")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:SetTime(math.random() * inst.AnimState:GetCurrentAnimationLength())

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(ondropped)
    inst.components.inventoryitem:SetOnPutInInventoryFn(turnoff)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("fueled")
    inst.components.fueled:InitializeFuelLevel(TUNING.REDLANTERN_LIGHTTIME)
    inst.components.fueled:SetDepletedFn(nofuel)
    inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL -- so people can toss depleted lanterns into a firepit

    MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)

    inst.OnRemoveEntity = OnRemove

    inst._light = nil
    turnon(inst)

    return inst
end

local function lanternbodyfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("redlantern")
    inst.AnimState:SetBuild("redlantern")
    inst.AnimState:PlayAnimation("idle_body_loop", true)

    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:SetTime(math.random() * inst.AnimState:GetCurrentAnimationLength())

    inst.persists = false

    return inst
end

return Prefab("redlantern", fn, assets, prefabs),
    Prefab("redlanternlight", lanternlightfn),
    Prefab("redlanternbody", lanternbodyfn)
