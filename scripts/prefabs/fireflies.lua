local assets =
{
    Asset("ANIM", "anim/fireflies.zip"),
}

local INTENSITY = .5

local function updatefade(inst, rate)
    inst._fadeval:set_local(math.clamp(inst._fadeval:value() + rate, 0, INTENSITY))

    --Client light modulation is enabled:
    inst.Light:SetIntensity(inst._fadeval:value())

    if rate == 0 or
        (rate < 0 and inst._fadeval:value() <= 0) or
        (rate > 0 and inst._fadeval:value() >= INTENSITY) then
        inst._fadetask:Cancel()
        inst._fadetask = nil
        if inst._fadeval:value() <= 0 and TheWorld.ismastersim then
            inst:AddTag("NOCLICK")
            inst.Light:Enable(false)
        end
    end
end

local function fadein(inst)
    local ismastersim = TheWorld.ismastersim
    if not ismastersim or inst._faderate:value() <= 0 then
        if ismastersim then
            inst:RemoveTag("NOCLICK")
            inst.Light:Enable(true)
            inst.AnimState:PlayAnimation("swarm_pre")
            inst.AnimState:PushAnimation("swarm_loop", true)
            local t = 3 + math.random() * 2
            local rate = INTENSITY * FRAMES / t
            inst._faderate:set(rate)
        end
        if inst._fadetask ~= nil then
            inst._fadetask:Cancel()
        end
        local rate = inst._faderate:value() * math.clamp(1 - inst._fadeval:value() / INTENSITY, 0, 1)
        inst._fadetask = inst:DoPeriodicTask(FRAMES, updatefade, nil, rate)
        if not ismastersim then
            updatefade(inst, rate)
        end
    end
end

local function fadeout(inst)
    local ismastersim = TheWorld.ismastersim
    if not ismastersim or inst._faderate:value() > 0 then
        if ismastersim then
            inst.AnimState:PlayAnimation("swarm_pst")
            local t = .75 + math.random()
            local rate = -INTENSITY * FRAMES / t
            inst._faderate:set(rate)
        end
        if inst._fadetask ~= nil then
            inst._fadetask:Cancel()
        end
        local rate = inst._faderate:value() * math.clamp(inst._fadeval:value() / INTENSITY, 0, 1)
        inst._fadetask = inst:DoPeriodicTask(FRAMES, updatefade, nil, rate)
        if not ismastersim then
            updatefade(inst, rate)
        end
    end
end

local function OnFadeRateDirty(inst)
    if inst._faderate:value() > 0 then
        fadein(inst)
    elseif inst._faderate:value() < 0 then
        fadeout(inst)
    elseif inst._fadetask ~= nil then
        inst._fadetask:Cancel()
        inst._fadetask = nil
        inst._fadeval:set_local(0)

        --Client light modulation is enabled:
        inst.Light:SetIntensity(0)
    end
end

local function updatelight(inst)
    if TheWorld.state.isnight and not inst.components.playerprox:IsPlayerClose() and inst.components.inventoryitem.owner == nil then
        fadein(inst)
    else
        fadeout(inst)
    end
end

local function ondropped(inst)
    inst.components.workable:SetWorkLeft(1)
    inst._fadeval:set(0)
    inst._faderate:set_local(0)
    fadein(inst)
    inst:DoTaskInTime(2 + math.random(), updatelight)
end

local function onpickup(inst)
    if inst._fadetask ~= nil then
        inst._fadetask:Cancel()
        inst._fadetask = nil
    end
    inst._fadeval:set_local(0)
    inst._faderate:set(0)
    inst.Light:SetIntensity(0)
    inst.Light:Enable(false)
end

local function onworked(inst, worker)
    if worker.components.inventory ~= nil then
        worker.components.inventory:GiveItem(inst, nil, inst:GetPosition())
    end
end

local function getstatus(inst)
    if inst.components.inventoryitem.owner ~= nil then
        return "HELD"
    end
end

local function OnIsNight(inst)
    inst:DoTaskInTime(2 + math.random(), updatelight)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddPhysics()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst:AddTag("NOBLOCK")
    inst:AddTag("NOCLICK")

    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(INTENSITY)
    inst.Light:SetRadius(1)
    inst.Light:SetColour(180/255, 195/255, 150/255)
    inst.Light:SetIntensity(0)
    inst.Light:Enable(false)
    inst.Light:EnableClientModulation(true)

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.AnimState:SetBank("fireflies")
    inst.AnimState:SetBuild("fireflies")
    inst.AnimState:SetRayTestOnBB(true)

    inst:AddTag("cattoyairborne")

    inst._fadeval = net_float(inst.GUID, "fireflies._fadeval")
    inst._faderate = net_float(inst.GUID, "fireflies._faderate", "onfaderatedirty")
    inst._fadetask = nil

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("onfaderatedirty", OnFadeRateDirty)

        return inst
    end

    inst:AddComponent("playerprox")

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.NET)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(onworked)

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
    inst.components.stackable.forcedropsingle = true

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(ondropped)
    inst.components.inventoryitem:SetOnPickupFn(onpickup)
    inst.components.inventoryitem.canbepickedup = false

    inst:AddComponent("tradable")

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL
    inst.components.fuel.fueltype = FUELTYPE.CAVE

    inst.components.playerprox:SetDist(3,5)
    inst.components.playerprox:SetOnPlayerNear(updatelight)
    inst.components.playerprox:SetOnPlayerFar(updatelight)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:WatchWorldState("isnight", OnIsNight)

    updatelight(inst)

    return inst
end

return Prefab("common/objects/fireflies", fn, assets)