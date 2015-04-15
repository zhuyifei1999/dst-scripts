require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/tent.zip"),
}

local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_big").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
	inst:Remove()
end

local function onhit(inst, worker)
	inst.AnimState:PlayAnimation("hit")
	inst.AnimState:PushAnimation("idle", true)
	if inst.sleeper ~= nil then
		inst.components.sleepingbag:DoWakeUp()
	end
end

local function onfinishedsound(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/tent_dis_twirl")
end

local function onfinished(inst)
	inst.AnimState:PlayAnimation("destroy")
	inst:ListenForEvent("animover", inst.Remove)
	inst.SoundEmitter:PlaySound("dontstarve/common/tent_dis_pre")
	inst.persists = false
	inst:DoTaskInTime(16 * FRAMES, onfinishedsound)
end

local function onbuilt(inst)
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("idle", true)
end

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

    inst.AnimState:PushAnimation("idle", true)

    inst.components.finiteuses:Use()
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
        sleeper.components.health:DoDelta(TUNING.SLEEP_HEALTH_PER_TICK * 2, true, "tent", true)
    end

    if sleeper.components.temperature ~= nil and sleeper.components.temperature.current < TUNING.SLEEP_TARGET_TEMP_TENT then
        sleeper.components.temperature:SetTemperature(sleeper.components.temperature:GetCurrent() + TUNING.SLEEP_TEMP_PER_TICK) 
    end

    if sleeper.components.hunger ~= nil and sleeper.components.hunger.current <= 0 then
        inst.components.sleepingbag:DoWakeUp()
    end
end

local function onsleep(inst, sleeper)
	-- check if we're in an invalid period (i.e. daytime). if so: wakeup
    inst:WatchWorldState("phase", wakeuptest)

    -- "occupied" anim
    inst.AnimState:PlayAnimation("sleep_loop", true)

    if inst.sleeptask ~= nil then
        inst.sleeptask:Cancel()
    end
    inst.sleeptask = inst:DoPeriodicTask(TUNING.SLEEP_TICK_PERIOD, onsleeptick, nil, sleeper)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst:AddTag("tent")    
    inst:AddTag("structure")
    inst.AnimState:SetBank("tent")
    inst.AnimState:SetBuild("tent")
    inst.AnimState:PlayAnimation("idle", true)
    
    inst.MiniMapEntity:SetIcon("tent.png")

    inst:AddTag("nosleepanim")

    MakeSnowCoveredPristine(inst)
    
    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    --[[inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = 2
    inst.components.fuel.startsize = "medium"
    --]]
    
    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.TENT_USES)
    inst.components.finiteuses:SetUses(TUNING.TENT_USES)
    inst.components.finiteuses:SetOnFinished(onfinished)

	inst:AddComponent("sleepingbag")
	inst.components.sleepingbag.onsleep = onsleep
    inst.components.sleepingbag.onwake = onwake

	MakeSnowCovered(inst)
	inst:ListenForEvent("onbuilt", onbuilt)

	MakeHauntableWork(inst)

    return inst
end

return Prefab("common/objects/tent", fn, assets),
		MakePlacer("common/tent_placer", "tent", "tent", "idle")