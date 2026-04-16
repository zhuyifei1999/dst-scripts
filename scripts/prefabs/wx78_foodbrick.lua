local assets =
{
    Asset("ANIM", "anim/wx78_foodbrick.zip"),
    Asset("INV_IMAGE", "wx78_foodbrick_wet"),
}

local FERTILIZER_DEFS = require("prefabs/fertilizer_nutrient_defs").FERTILIZER_DEFS

local function MakeWet(inst)
    if not TheNet:IsDedicated() then
        inst:PushEvent("show_spoilage")
    end
    inst.pickupsound = "squidgy"
    inst.components.inventoryitem:ChangeImageName("wx78_foodbrick_wet")
    inst.components.perishable:StartPerishing()

    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.hungervalue = TUNING.CALORIES_MEDSMALL
    inst.components.edible.sanityvalue = 0
    inst.components.edible.foodtype = FOODTYPE.GENERIC

    if not inst.components.fertilizer then
        inst:AddComponent("fertilizer")
        inst.components.fertilizer.fertilizervalue = TUNING.WX78_FOODBRICK_FERTILIZE
        inst.components.fertilizer.soil_cycles = TUNING.WX78_FOODBRICK_SOILCYCLES
        inst.components.fertilizer.withered_cycles = TUNING.WX78_FOODBRICK_WITHEREDCYCLES
        inst.components.fertilizer:SetNutrients(FERTILIZER_DEFS.wx78_foodbrick.nutrients)

        inst:AddTag("tile_deploy")
        MakeDeployableFertilizer(inst)
    end
end

local function MakeDry(inst)
    if not TheNet:IsDedicated() then
        inst:PushEvent("hide_spoilage")
    end
    inst.pickupsound = "vegetation_firm"
    inst.components.inventoryitem:ChangeImageName(nil)
    inst.components.perishable:StopPerishing()

    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.hungervalue = TUNING.CALORIES_TINY
    inst.components.edible.sanityvalue = 0
    inst.components.edible.foodtype = FOODTYPE.RAW

    inst:RemoveComponent("fertilizer")
    inst:RemoveComponent("deployable")
    inst:RemoveTag("tile_deploy")
end

local function OnMoistureDeltaCallback(inst)--, oldmoisture, newmoisture)
    if inst.components.inventoryitem:IsWet() then
        if not inst._waswet then
            -- inst.AnimState:PlayAnimation("moisten")
            inst.AnimState:PushAnimation("idle_wet")
            inst._waswet = true
        end

        MakeWet(inst)
    else
        if inst._waswet then
            -- inst.AnimState:PlayAnimation("moisten")
            inst.AnimState:PushAnimation("idle_dry")
            inst._waswet = false
        end

        MakeDry(inst)
    end
end

local function GetStatus(inst)
    return inst.components.inventoryitem:IsWet() and "WET"
        or nil
end

local function CLIENT_OnWetnessChanged(inst, iswet)
    inst.pickupsound = iswet and "squidgy" or "vegetation_firm"
    if not TheNet:IsDedicated() then
        inst:PushEvent(iswet and "show_spoilage" or "hide_spoilage")
    end
end

local function COMMON_CanStackWithFn(inst, item)
    return inst.replica.inventoryitem:IsWet() == item.replica.inventoryitem:IsWet()
end

local function COMMON_ItemTileRefresh(inst)
    if not TheNet:IsDedicated() then
        inst:PushEvent(inst.replica.inventoryitem:IsWet() and "show_spoilage" or "hide_spoilage")
    end
end

local function COMMON_GetFertilizerKey(inst)
    return inst.prefab
end

local function fertilizerresearchfn(inst)
    return inst:GetFertilizerKey()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("wx78_foodbrick")
    inst.AnimState:SetBuild("wx78_foodbrick")
    inst.AnimState:PlayAnimation("idle_dry")

    inst.pickupsound = "vegetation_firm" -- 'squidgy' when wet

    inst:AddTag("fertilizerresearchable")

    MakeInventoryFloatable(inst, "small", 0.07, 1.2)
    MakeDeployableFertilizerPristine(inst)

    inst.stackable_CanStackWithFn = COMMON_CanStackWithFn
    inst.itemtile_Refresh = COMMON_ItemTileRefresh
    inst.wet_prefix = STRINGS.WET_PREFIX.WX78_FOODBRICK
    inst.GetFertilizerKey = COMMON_GetFertilizerKey

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("wetnesschange", CLIENT_OnWetnessChanged)
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitemmoisture:SetOnMoistureDeltaCallback(OnMoistureDeltaCallback)
    inst._waswet = false

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("tradable")

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_LARGE_FUEL

    inst:AddComponent("edible")
    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.hungervalue = 0
    inst.components.edible.sanityvalue = 0
    inst.components.edible.foodtype = FOODTYPE.RAW

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_ONE_DAY)
    inst.components.perishable:SetOnPerishFn(inst.Remove) -- If we don't set a perish replacement, it doesn't remove itself, so explicitly set this.

    inst:AddComponent("fertilizerresearchable")
    inst.components.fertilizerresearchable:SetResearchFn(fertilizerresearchfn)

    MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunchAndIgnite(inst)

    return inst
end

return Prefab("wx78_foodbrick", fn, assets)