local assets =
{
    Asset("ANIM", "anim/bundle.zip"),
}

local assets_bundled =
{
    Asset("ANIM", "anim/bundle.zip"),
    Asset("INV_IMAGE", "bundle_small"),
    Asset("INV_IMAGE", "bundle_medium"),
    Asset("INV_IMAGE", "bundle_large"),
}

local prefabs =
{
    "bundle",
    "bundle_container",
}

local prefabs_bundled =
{
    "ash",
    "bundle_unwrap",
    "waxpaper",
}

local function OnStartBundling(inst)--, doer)
    inst.components.stackable:Get():Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("bundle")
    inst.AnimState:SetBuild("bundle")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("bundlemaker")
    inst.components.bundlemaker:SetBundlingPrefabs("bundle_container", "bundle")
    inst.components.bundlemaker:SetOnStartBundlingFn(OnStartBundling)

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    inst.components.propagator.flashpoint = 10 + math.random() * 5
    MakeHauntableLaunchAndIgnite(inst)

    return inst
end

local function container_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("bundle")

    --V2C: blank string for controller action prompt
    inst.name = " "

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("bundle_container")

    inst.persists = false

    return inst
end

local function OnWrapped(inst, num)
    local sizename =
        (num > 3 and "large") or
        (num > 1 and "medium") or
        "small"

    inst.AnimState:PlayAnimation("idle_"..sizename)
    inst.components.inventoryitem:ChangeImageName("bundle_"..sizename)
end

local function OnUnwrapped(inst, pos)
    if inst.burnt then
        SpawnPrefab("ash").Transform:SetPosition(pos:Get())
    else
        SpawnPrefab("waxpaper").Transform:SetPosition(pos:Get())
        SpawnPrefab("bundle_unwrap").Transform:SetPosition(pos:Get())
    end
    inst:Remove()
end

local function onburnt(inst)
    inst.burnt = true
    inst.components.unwrappable:Unwrap()
end

local function onignite(inst)
    inst.components.unwrappable.canbeunwrapped = false
end

local function onextinguish(inst)
    inst.components.unwrappable.canbeunwrapped = true
end

local function bundle_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("bundle")
    inst.AnimState:SetBuild("bundle")
    inst.AnimState:PlayAnimation("idle_large")

    inst:AddTag("bundle")

    --unwrappable (from unwrappable component) added to pristine state for optimization
    inst:AddTag("unwrappable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:ChangeImageName("bundle_large")

    inst:AddComponent("unwrappable")
    inst.components.unwrappable:SetOnWrappedFn(OnWrapped)
    inst.components.unwrappable:SetOnUnwrappedFn(OnUnwrapped)

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    inst.components.propagator.flashpoint = 10 + math.random() * 5
    inst.components.burnable:SetOnBurntFn(onburnt)
    inst.components.burnable:SetOnIgniteFn(onignite)
    inst.components.burnable:SetOnExtinguishFn(onextinguish)

    MakeHauntableLaunchAndIgnite(inst)

    return inst
end

return Prefab("bundle", bundle_fn, assets_bundled, prefabs_bundled),
    Prefab("bundlewrap", fn, assets, prefabs),
    Prefab("bundle_container", container_fn)
