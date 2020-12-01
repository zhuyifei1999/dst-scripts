local assets =
{
    Asset("ANIM", "anim/healing_cream.zip"),
	Asset("SCRIPT", "scripts/prefabs/fertilizer_nutrient_defs.lua"),
}

local prefabs =
{
    "flies",
    "poopcloud",
	"compostwrapheal_buff",
}

local FERTILIZER_DEFS = require("prefabs/fertilizer_nutrient_defs").FERTILIZER_DEFS

local function OnBurn(inst)
    DefaultBurnFn(inst)
    if inst.flies ~= nil then
        inst.flies:Remove()
        inst.flies = nil
    elseif inst.inittask ~= nil then
        inst.inittask:Cancel()
        inst.inittask = nil
    end
end

local function FuelTaken(inst, taker)
    local fx = taker.components.burnable ~= nil and taker.components.burnable.fxchildren[1] or nil
    local x, y, z
    if fx ~= nil and fx:IsValid() then
        x, y, z = fx.Transform:GetWorldPosition()
    else
        x, y, z = taker.Transform:GetWorldPosition()
    end
    SpawnPrefab("poopcloud").Transform:SetPosition(x, y + 1, z)
end

local function OnDropped(inst)
    if inst.flies == nil then
        inst.flies = inst:SpawnChild("flies")
        if inst.inittask ~= nil then
            inst.inittask:Cancel()
            inst.inittask = nil
        end
    end
end

local function OnPickup(inst)
    if inst.flies ~= nil then
        inst.flies:Remove()
        inst.flies = nil
    elseif inst.inittask ~= nil then
        inst.inittask:Cancel()
        inst.inittask = nil
    end
end

local function OnInit(inst)
    inst.inittask = nil
    inst.flies = inst:SpawnChild("flies")
end

local function GetFertilizerKey(inst)
    return inst.prefab
end

local function fertilizerresearchfn(inst)
    return inst:GetFertilizerKey()
end

local function on_heal(inst, target)
	if target.components.debuffable ~= nil and target.components.health ~= nil and not target.components.health:IsDead() then
		target.components.debuffable:AddDebuff("compostwrapheal_buff", "compostwrapheal_buff")
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("healing_cream")
    inst.AnimState:SetBuild("healing_cream")
    inst.AnimState:PlayAnimation("idle")

    --heal_fertilize (from fertilizer component) added to pristine state for optimization
    inst:AddTag("heal_fertilize")

    inst:AddTag("slowfertilize") -- for player self fertilize healing action

    MakeInventoryFloatable(inst)

    inst.GetFertilizerKey = GetFertilizerKey

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    inst.components.inventoryitem:SetOnPickupFn(OnPickup)
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPickup)
    
    inst:AddComponent("fertilizerresearchable")
    inst.components.fertilizerresearchable:SetResearchFn(fertilizerresearchfn)

    inst:AddComponent("fertilizer")
    inst.components.fertilizer:SetHealingAmount(TUNING.HEALING_MEDLARGE)
    inst.components.fertilizer.fertilizervalue = TUNING.COMPOSTWRAP_FERTILIZE
    inst.components.fertilizer.soil_cycles = TUNING.COMPOSTWRAP_SOILCYCLES
    inst.components.fertilizer.withered_cycles = TUNING.COMPOSTWRAP_WITHEREDCYCLES
    inst.components.fertilizer:SetNutrients(FERTILIZER_DEFS.compostwrap.nutrients)
    inst.components.fertilizer.onhealfn = on_heal

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL
    inst.components.fuel:SetOnTakenFn(FuelTaken)

    inst:AddComponent("smotherer")

    MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    inst.components.burnable:SetOnIgniteFn(OnBurn)
    MakeSmallPropagator(inst)

    MakeHauntableLaunchAndIgnite(inst)

    --V2C: delay spawning flies, since it's most likely being crafted into our pockets
    inst.inittask = inst:DoTaskInTime(0, OnInit)

    return inst
end

local function OnTick(inst, target)
    if target.components.health ~= nil
        and not target.components.health:IsDead()
		and target.components.sanity ~= nil
        and not target:HasTag("playerghost") then
        target.components.health:DoDelta(TUNING.COMPOSTWRAP_HOT_HEALTH_DELTA, nil, "tillweedsalve")
    else
        inst.components.debuff:Stop()
    end
end

local function OnAttached(inst, target)
    inst.entity:SetParent(target.entity)
    inst.Transform:SetPosition(0, 0, 0) --in case of loading
    inst.task = inst:DoPeriodicTask(TUNING.COMPOSTWRAP_HOT_TICK_RATE, OnTick, nil, target)
    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)
end

local function OnTimerDone(inst, data)
    if data.name == "regenover" then
        inst.components.debuff:Stop()
    end
end

local function OnExtended(inst, target)
    inst.components.timer:StopTimer("regenover")
    inst.components.timer:StartTimer("regenover", TUNING.COMPOSTWRAP_HOT_DURATION)
    inst.task:Cancel()
    inst.task = inst:DoPeriodicTask(TUNING.COMPOSTWRAP_HOT_TICK_RATE, OnTick, nil, target)
end

local function buff_fn()
    local inst = CreateEntity()

    if not TheWorld.ismastersim then
        --Not meant for client!
        inst:DoTaskInTime(0, inst.Remove)

        return inst
    end

    inst.entity:AddTransform()

    --[[Non-networked entity]]
    --inst.entity:SetCanSleep(false)
    inst.entity:Hide()
    inst.persists = false

    inst:AddTag("CLASSIFIED")

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(inst.Remove)
    inst.components.debuff:SetExtendedFn(OnExtended)
    inst.components.debuff.keepondespawn = true

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("regenover", TUNING.COMPOSTWRAP_HOT_DURATION)
    inst:ListenForEvent("timerdone", OnTimerDone)

    return inst
end

return Prefab("compostwrap", fn, assets),
	Prefab("compostwrapheal_buff", buff_fn, assets)
