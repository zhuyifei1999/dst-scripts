local assets =
{
	Asset("ANIM", "anim/koalephant_trunk.zip"),
}

local prefabs =
{
    "trunk_cooked",
    "spoiled_food",
}

local function create_common(anim)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("trunk")
    inst.AnimState:SetBuild("koalephant_trunk")
    inst.AnimState:PlayAnimation(anim)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("tradable")

    inst:AddComponent("edible")
    inst.components.edible.ismeat = true
    inst.components.edible.foodtype = FOODTYPE.MEAT

    inst:AddComponent("perishable")
    inst.components.perishable.onperishreplacement = "spoiled_food"

    MakeHauntableLaunchAndPerish(inst)

    return inst
end

local function create_summer()
    local inst = create_common("idle_summer")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.MEAT

    inst.components.edible.healthvalue = TUNING.HEALING_MEDLARGE
    inst.components.edible.hungervalue = TUNING.CALORIES_LARGE

    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.perishable:StartPerishing()

    inst:AddComponent("cookable")
    inst.components.cookable.product = "trunk_cooked"

    return inst
end

local function create_winter()
    local inst = create_common("idle_winter")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.MEAT

    inst.components.edible.healthvalue = TUNING.HEALING_MEDLARGE
    inst.components.edible.hungervalue = TUNING.CALORIES_LARGE

    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.perishable:StartPerishing()

    inst:AddComponent("cookable")
    inst.components.cookable.product = "trunk_cooked"

    return inst
end

local function create_cooked()
    local inst = create_common("cooked")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.MEAT

    inst.components.edible.healthvalue = TUNING.HEALING_LARGE
    inst.components.edible.hungervalue = TUNING.CALORIES_HUGE

    inst.components.perishable:SetPerishTime(TUNING.PERISH_SLOW)
    inst.components.perishable:StartPerishing()

    return inst
end

return Prefab("common/inventory/trunk_summer", create_summer, assets, prefabs),
        Prefab("common/inventory/trunk_winter", create_winter, assets, prefabs),
        Prefab("common/inventory/trunk_cooked", create_cooked, assets)