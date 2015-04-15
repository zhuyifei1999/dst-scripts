local assets =
{
	Asset("ANIM", "anim/swap_bedroll_furry.zip"),
}

--We don't watch "stopnight" because that would not work in a clock
--without night phase
local function wakeuptest(inst, phase)
    if phase ~= "night" then
        inst.components.sleepingbag:DoWakeUp()
    end
end

local function onwake(inst, sleeper, nostatechange)
    if inst.sleeptask ~= nil then
        inst.sleeptask:Cancel()
        inst.sleeptask = nil
    end

    inst:StopWatchingWorldState("phase", wakeuptest)

    if not nostatechange then
        sleeper.sg:GoToState("wakeup")
    end

    if inst.components.finiteuses ~= nil and inst.components.finiteuses:GetUses() <= 0 then
        inst:Remove()
    end
end

local function onsleeptick(inst, sleeper)
    if sleeper.components.hunger ~= nil then
        -- Check SGwilson, state "bedroll", if you change this value
        sleeper.components.hunger:DoDelta(TUNING.SLEEP_HUNGER_PER_TICK, true, true)
    end

    if sleeper.components.sanity ~= nil and sleeper.components.sanity:GetPercentWithPenalty() < 1 then
        sleeper.components.sanity:DoDelta(TUNING.SLEEP_SANITY_PER_TICK, true) 
    end

    if sleeper.components.health ~= nil and (not sleeper.components.hunger or sleeper.components.hunger:GetPercent() > 0) then
        sleeper.components.health:DoDelta(TUNING.SLEEP_HEALTH_PER_TICK, true, "bedroll", true) 
    end

    if sleeper.components.temperature ~= nil and sleeper.components.temperature.current < TUNING.SLEEP_TARGET_TEMP_BEDROLL_FURRY then
        sleeper.components.temperature:SetTemperature(sleeper.components.temperature:GetCurrent() + TUNING.SLEEP_TEMP_PER_TICK)
    end

    if sleeper.components.hunger ~= nil and sleeper.components.hunger.current <= 0 then
        inst.components.sleepingbag:DoWakeUp()
    end
end

local function onsleep(inst, sleeper)
    -- check if we're in an invalid period (i.e. daytime). if so: wakeup
    inst:WatchWorldState("phase", wakeuptest)

    if inst.sleeptask ~= nil then
        inst.sleeptask:Cancel()
    end
    inst.sleeptask = inst:DoPeriodicTask(TUNING.SLEEP_TICK_PERIOD, onsleeptick, nil, sleeper)
end

local function onuse(inst)
	inst.AnimState:OverrideSymbol("swap_bedroll", "swap_bedroll_furry", "bedroll_furry")
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("swap_bedroll_furry")
    inst.AnimState:SetBuild("swap_bedroll_furry")
    inst.AnimState:PlayAnimation("idle")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetConsumption(ACTIONS.SLEEPIN, 1)
    inst.components.finiteuses:SetMaxUses(3)
    inst.components.finiteuses:SetUses(3)

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

	MakeSmallBurnable(inst, TUNING.LONG_BURNABLE)
    MakeSmallPropagator(inst)
    inst:AddComponent("sleepingbag")
	inst.components.sleepingbag.onsleep = onsleep
    inst.components.sleepingbag.onwake = onwake

    inst.onuse = onuse

    MakeHauntableLaunchAndIgnite(inst)

    return inst
end

return Prefab("common/inventory/bedroll_furry", fn, assets)