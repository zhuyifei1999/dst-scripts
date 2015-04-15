local assets =
{
	Asset("ANIM", "anim/meat.zip"),
	Asset("ANIM", "anim/meat_monster.zip"),
	Asset("ANIM", "anim/meat_small.zip"),
    Asset("ANIM", "anim/meat_human.zip"),
	Asset("ANIM", "anim/drumstick.zip"),
	Asset("ANIM", "anim/meat_rack_food.zip"),
    Asset("ANIM", "anim/batwing.zip"),
    Asset("ANIM", "anim/plant_meat.zip"),
}

local prefabs =
{
    "cookedmeat",
    "meat_dried",
    "spoiled_food",
}

local smallprefabs =
{
    "cookedsmallmeat",
    "smallmeat_dried",
    "spoiled_food",
}

local monsterprefabs =
{
    "cookedmonstermeat",
    "monstermeat_dried",
    "spoiled_food",
}

local humanprefabs =
{
    "humanmeat_cooked",
    "humanmeat_dried",
    "spoiled_food",
}

local drumstickprefabs =
{
    "drumstick_cooked",
    "spoiled_food",
}

local batwingprefabs =
{
    "batwing_cooked",
    "meat_dried",
    "spoiled_food",
}

local plantmeatprefabs =
{
    "plantmeat_cooked",
    "spoiled_food",
}

local function AddMonsterMeatChange(inst, prefab)
    if not prefab or not inst then return end
    AddHauntableCustomReaction(inst, function(inst, haunter)
        if math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
            local fx = SpawnPrefab("small_puff")
            if fx then fx.Transform:SetPosition(inst.Transform:GetWorldPosition()) end
            local new = SpawnPrefab(prefab)
            if new then
                new.Transform:SetPosition(inst.Transform:GetWorldPosition())
                if new.components.perishable and inst.components.perishable then
                    new.components.perishable:SetPercent(inst.components.perishable:GetPercent())
                end
                new:PushEvent("spawnedfromhaunt", {haunter=haunter, oldPrefab=inst})
            end
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
            inst:DoTaskInTime(0, function(inst) inst:Remove() end)
            return true
        end
        return false
    end, false, true, false)
end

local function common(bank, build, anim, tag)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation(anim)

    inst:AddTag("meat")
    if tag ~= nil then
        inst:AddTag(tag)
    end

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst:AddComponent("edible")
    inst.components.edible.ismeat = true    
    inst.components.edible.foodtype = FOODTYPE.MEAT

    inst:AddComponent("bait")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst:AddComponent("stackable")

    inst:AddComponent("tradable")
    inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.MEAT

	inst:AddComponent("perishable")
	inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
	inst.components.perishable:StartPerishing()
	inst.components.perishable.onperishreplacement = "spoiled_food"

    MakeHauntableLaunchAndPerish(inst)
    inst:ListenForEvent("spawnedfromhaunt", function(inst, data)
        Launch(inst, data.haunter, TUNING.LAUNCH_SPEED_SMALL)
    end)

    return inst
end

local function humanmeat()
    local inst = common("meat_human", "meat_human", "raw")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.ismeat = true    
    inst.components.edible.foodtype = FOODTYPE.MEAT
    inst.components.edible.healthvalue = -TUNING.HEALING_MED
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = -TUNING.SANITY_LARGE
    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)

    inst.components.tradable.goldvalue = 0

    inst:AddComponent("selfstacker")

    inst:AddComponent("cookable")
    inst.components.cookable.product = "humanmeat_cooked"
    inst:AddComponent("dryable")
    inst.components.dryable:SetProduct("humanmeat_dried")
    inst.components.dryable:SetDryTime(TUNING.DRY_FAST)
    return inst
end


local function humanmeat_cooked()
    local inst = common("meat_human", "meat_human", "cooked")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.tradable.goldvalue = 0

    inst.components.edible.healthvalue = -TUNING.HEALING_SMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_MEDSMALL
    inst.components.edible.sanityvalue = -TUNING.SANITY_LARGE

    inst.components.perishable:SetPerishTime(TUNING.PERISH_SLOW)

    return inst
end

local function humanmeat_dried()
    local inst = common("meat_rack_food", "meat_rack_food", "idle_dried_human")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.healthvalue = -TUNING.HEALING_SMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = -TUNING.SANITY_MED

    inst.components.perishable:SetPerishTime(TUNING.PERISH_PRESERVED)

    return inst
end
    
local function monster()
	local inst = common("monstermeat", "meat_monster", "idle")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.ismeat = true    
    inst.components.edible.foodtype = FOODTYPE.MEAT
    inst.components.edible.healthvalue = -TUNING.HEALING_MED
    inst.components.edible.hungervalue = TUNING.CALORIES_MEDSMALL
    inst.components.edible.sanityvalue = -TUNING.SANITY_MED
    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)

	inst.components.tradable.goldvalue = 0

    inst:AddComponent("selfstacker")

    inst:AddComponent("cookable")
    inst.components.cookable.product = "cookedmonstermeat"
    inst:AddComponent("dryable")
    inst.components.dryable:SetProduct("monstermeat_dried")
    inst.components.dryable:SetDryTime(TUNING.DRY_FAST)
    return inst
end


local function cookedmonster()
	local inst = common("monstermeat", "meat_monster", "cooked")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.tradable.goldvalue = 0

    inst.components.edible.healthvalue = -TUNING.HEALING_SMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_MEDSMALL
    inst.components.edible.sanityvalue = -TUNING.SANITY_SMALL

    inst.components.perishable:SetPerishTime(TUNING.PERISH_SLOW)

    return inst
end

local function driedmonster()
	local inst = common("meat_rack_food", "meat_rack_food", "idle_dried_monster")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.healthvalue = -TUNING.HEALING_SMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_MEDSMALL
    inst.components.edible.sanityvalue = -TUNING.SANITY_TINY

    inst.components.perishable:SetPerishTime(TUNING.PERISH_PRESERVED)

    return inst
end

local function cooked()
	local inst = common("meat", "meat", "cooked")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.healthvalue = TUNING.HEALING_SMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_MED
    inst.components.edible.sanityvalue = 0
	inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)

    AddMonsterMeatChange(inst, "cookedmonstermeat")

    return inst
end

local function driedmeat()
	local inst = common("meat_rack_food", "meat_rack_food", "idle_dried_large")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.healthvalue = TUNING.HEALING_MED
    inst.components.edible.hungervalue = TUNING.CALORIES_MED
    inst.components.edible.sanityvalue = TUNING.SANITY_MED
	inst.components.perishable:SetPerishTime(TUNING.PERISH_PRESERVED)

    AddMonsterMeatChange(inst, "monstermeat_dried")

    return inst
end



local function raw()
	local inst = common("meat", "meat", "raw")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.hungervalue = TUNING.CALORIES_MED
    inst.components.edible.sanityvalue = -TUNING.SANITY_SMALL

    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)

    inst:AddComponent("cookable")
    inst.components.cookable.product = "cookedmeat"
    inst:AddComponent("dryable")
    inst.components.dryable:SetProduct("meat_dried")
    inst.components.dryable:SetDryTime(TUNING.DRY_MED)

    AddMonsterMeatChange(inst, "monstermeat")

    return inst
end

local function smallmeat()
	local inst = common("meat_small", "meat_small", "raw")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.healthvalue = 0
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = -TUNING.SANITY_SMALL

    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)

    inst:AddComponent("cookable")
    inst.components.cookable.product = "cookedsmallmeat"
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
    inst:AddComponent("dryable")
    inst.components.dryable:SetProduct("smallmeat_dried")
    inst.components.dryable:SetDryTime(TUNING.DRY_FAST)

    return inst
end

local function cookedsmallmeat()
	local inst = common("meat_small", "meat_small", "cooked")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = 0

    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)

	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    return inst
end
   
local function driedsmallmeat()
	local inst = common("meat_rack_food", "meat_rack_food", "idle_dried_small")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.healthvalue = TUNING.HEALING_MEDSMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = TUNING.SANITY_SMALL

    inst.components.perishable:SetPerishTime(TUNING.PERISH_PRESERVED)

	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    return inst
end

local function drumstick()
	local inst = common("drumstick", "drumstick", "raw", "drumstick")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.healthvalue = 0
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = -TUNING.SANITY_SMALL

    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)

    inst:AddComponent("cookable")
    inst.components.cookable.product = "drumstick_cooked"
    inst:AddComponent("dryable")
    inst.components.dryable:SetProduct("smallmeat_dried")
    inst.components.dryable:SetDryTime(TUNING.DRY_FAST)
    return inst
end

local function drumstick_cooked()
	local inst = common("drumstick", "drumstick", "cooked", "drumstick")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)

    return inst
end

local function batwing()
    local inst = common("batwing", "batwing", "raw", "batwing")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.healthvalue = TUNING.HEALING_SMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = -TUNING.SANITY_SMALL

    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)

    inst:AddComponent("dryable")
    inst.components.dryable:SetProduct("smallmeat_dried")
    inst.components.dryable:SetDryTime(TUNING.DRY_MED)

    inst:AddComponent("cookable")
    inst.components.cookable.product = "batwing_cooked"

    return inst
end

local function batwing_cooked()
    local inst = common("batwing", "batwing", "cooked", "batwing")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.healthvalue = TUNING.HEALING_MEDSMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_MEDSMALL
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)

    return inst
end

local function plantmeat()
    local inst = common("plant_meat", "plant_meat", "raw")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.healthvalue = 0
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = -TUNING.SANITY_SMALL

    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)

    inst:AddComponent("cookable")
    inst.components.cookable.product = "plantmeat_cooked"

    return inst
end

local function plantmeat_cooked()
    local inst = common("plant_meat", "plant_meat", "cooked")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.hungervalue = TUNING.CALORIES_MEDSMALL
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)

    return inst
end

return Prefab("common/inventory/meat", raw, assets, prefabs),
        Prefab("common/inventory/cookedmeat", cooked, assets),
        Prefab("common/inventory/meat_dried", driedmeat, assets),
        Prefab("common/inventory/monstermeat", monster, assets, monsterprefabs),
        Prefab("common/inventory/cookedmonstermeat", cookedmonster, assets),
        Prefab("common/inventory/monstermeat_dried", driedmonster, assets),
        Prefab("common/inventory/smallmeat", smallmeat, assets, smallprefabs),
        Prefab("common/inventory/cookedsmallmeat", cookedsmallmeat, assets),
        Prefab("common/inventory/smallmeat_dried", driedsmallmeat, assets),
        Prefab("common/inventory/drumstick", drumstick, assets, drumstickprefabs),
        Prefab("common/inventory/drumstick_cooked", drumstick_cooked, assets),
        Prefab("common/inventory/batwing", batwing, assets, batwingprefabs),
        Prefab("common/inventory/batwing_cooked", batwing_cooked, assets),
        Prefab("common/inventory/plantmeat", plantmeat, assets, plantmeatprefabs),
        Prefab("common/inventory/plantmeat_cooked", plantmeat_cooked, assets),
        Prefab("common/inventory/humanmeat", humanmeat, assets, humanprefabs),
        Prefab("common/inventory/humanmeat_cooked", humanmeat_cooked, assets),
        Prefab("common/inventory/humanmeat_dried", humanmeat_dried, assets)
