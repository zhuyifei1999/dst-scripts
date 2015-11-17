local assets =
{
    Asset("ANIM", "anim/rock_light.zip"),
}

local prefabs =
{
    "nightmarelightfx",
}

local MAX_LIGHT_ON_FRAME = 15
local MAX_LIGHT_OFF_FRAME = 30

local function OnUpdateLight(inst, dframes)
    local frame = inst._lightframe:value() + dframes
    if frame >= inst._lightmaxframe then
        inst._lightframe:set_local(inst._lightmaxframe)
        inst._lighttask:Cancel()
        inst._lighttask = nil
    else
        inst._lightframe:set_local(frame)
    end

    local k = frame / inst._lightmaxframe
    inst.Light:SetRadius(inst._lightradius1:value() * k + inst._lightradius0:value() * (1 - k))

    if TheWorld.ismastersim then
        inst.Light:Enable(inst._lightradius1:value() > 0 or frame < inst._lightmaxframe)
    end
end

local function OnLightDirty(inst)
    if inst._lighttask == nil then
        inst._lighttask = inst:DoPeriodicTask(FRAMES, OnUpdateLight, nil, 1)
    end
    inst._lightmaxframe = inst._lightradius1:value() > 0 and MAX_LIGHT_ON_FRAME or MAX_LIGHT_OFF_FRAME
    OnUpdateLight(inst, 0)
end

local function fade_to(inst, rad, instant)
    if inst._lightradius1:value() ~= rad then
        local k = inst._lightframe:value() / inst._lightmaxframe
        local radius = inst._lightradius1:value() * k + inst._lightradius0:value() * (1 - k)
        local minradius0 = math.min(inst._lightradius0:value(), inst._lightradius1:value())
        local maxradius0 = math.max(inst._lightradius0:value(), inst._lightradius1:value())
        if radius > rad then
            inst._lightradius0:set(radius > minradius0 and maxradius0 or minradius0)
        else
            inst._lightradius0:set(radius < maxradius0 and minradius0 or maxradius0)
        end
        local maxframe = rad > 0 and MAX_LIGHT_ON_FRAME or MAX_LIGHT_OFF_FRAME
        inst._lightradius1:set(rad)
        inst._lightframe:set(instant and maxframe or math.max(0, math.floor((radius - inst._lightradius0:value()) / (rad - inst._lightradius0:value()) * maxframe + .5)))
        OnLightDirty(inst)
    end
end

local function ReturnChildren(inst)
    for k,child in pairs(inst.components.childspawner.childrenoutside) do
        if child.components.combat then
            child.components.combat:SetTarget(nil)
        end

        if child.components.lootdropper then
            child.components.lootdropper:SetLoot({})
            child.components.lootdropper:SetChanceLootTable(nil)
        end

        if child.components.health then
            child.components.health:Kill()
        end
    end
end

local function spawnfx(inst)
    if not inst.fx then
        inst.fx = SpawnPrefab("nightmarelightfx")
        local pt = inst:GetPosition()
        inst.fx.Transform:SetPosition(pt.x, -0.1, pt.z)
    end
end

local states =
{
    calm = function(inst, instant)

        inst.SoundEmitter:KillSound("warnLP")
        inst.SoundEmitter:KillSound("nightmareLP")

        fade_to(inst, 0, instant)
        if not instant then
            inst.AnimState:PushAnimation("close_2")
            inst.AnimState:PushAnimation("idle_closed")

            inst.fx.AnimState:PushAnimation("close_2")
            inst.fx.AnimState:PushAnimation("idle_closed")
            inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_close")
        else
            inst.AnimState:PlayAnimation("idle_closed")
            inst.fx.AnimState:PlayAnimation("idle_closed")
        end

        if inst.components.childspawner then
            inst.components.childspawner:StopSpawning()
            inst.components.childspawner:StartRegen()
            ReturnChildren(inst)
        end
    end,

    warn = function(inst, instant)
        fade_to(inst, 3, instant)

        inst.AnimState:PlayAnimation("open_1")
        inst.fx.AnimState:PlayAnimation("open_1")
        inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_open_warning")
        inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_warning_LP", "warnLP")
    end,

    wild = function(inst, instant)
        inst.SoundEmitter:KillSound("warnLP")
        inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_open_LP", "nightmareLP")

        fade_to(inst, 6, instant)
        if not instant then
            inst.AnimState:PlayAnimation("open_2")
            inst.AnimState:PushAnimation("idle_open")

            inst.fx.AnimState:PlayAnimation("open_2")
            inst.fx.AnimState:PushAnimation("idle_open")
            inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_open")
        else
            inst.AnimState:PlayAnimation("idle_open")

            inst.fx.AnimState:PlayAnimation("idle_open")
        end

        if inst.components.childspawner then
            inst.components.childspawner:StartSpawning()
            inst.components.childspawner:StopRegen()
        end
    end,


    dawn = function(inst, instant)
        inst.SoundEmitter:KillSound("nightmareLP")
        fade_to(inst, 3, instant)
        inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_close")
        inst.SoundEmitter:KillSound("nightmareLP")
        inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_open_LP", "nightmareLP")

        inst.AnimState:PlayAnimation("close_1")
        inst.fx.AnimState:PlayAnimation("close_1")

        inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_open")

        if inst.components.childspawner then
            inst.components.childspawner:StartSpawning()
            inst.components.childspawner:StopRegen()
        end
    end
}

local function getsanityaura(inst)
    if TheWorld.state.isnightmarewild then
        return -TUNING.SANITY_MED
    elseif TheWorld.state.isnightmarewarn or TheWorld.state.isnightmaredawn then
        return -TUNING.SANITY_SMALL
    else
        return 0
    end
end

local function changestate(inst, phase, instant)
    spawnfx(inst)
    local statefn = states[phase]

    if statefn then
        if instant then
            statefn(inst, true)
        else
            inst:DoTaskInTime(math.random() * 2, statefn)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("nightmarelight.png")

    inst.AnimState:SetBuild("rock_light")
    inst.AnimState:SetBank("rock_light")
    inst.AnimState:PlayAnimation("idle_closed",false)

    inst.Light:SetRadius(0)
    inst.Light:SetIntensity(.9)
    inst.Light:SetFalloff(.9)
    inst.Light:SetColour(1, 1, 1)
    inst.Light:Enable(false)
    inst.Light:EnableClientModulation(true)

    inst._lightframe = net_smallbyte(inst.GUID, "nightmarelight._lightframe", "lightdirty")
    inst._lightradius0 = net_tinybyte(inst.GUID, "nightmarelight._lightradius0", "lightdirty")
    inst._lightradius1 = net_tinybyte(inst.GUID, "nightmarelight._lightradius1", "lightdirty")
    inst._lightmaxframe = MAX_LIGHT_OFF_FRAME
    inst._lightframe:set(inst._lightmaxframe)
    inst._lighttask = nil

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("lightdirty", OnLightDirty)

        return inst
    end

    MakeObstaclePhysics(inst, 1)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = getsanityaura

    inst:AddComponent("childspawner")
    inst.components.childspawner:SetRegenPeriod(5)
    inst.components.childspawner:SetSpawnPeriod(30)
    inst.components.childspawner:SetMaxChildren(math.random(1,2))
    inst.components.childspawner.childname = "crawlingnightmare"
    inst.components.childspawner:SetRareChild("nightmarebeak", 0.35)

    inst:AddComponent("inspectable")

    inst.fade_to = fade_to

    inst:WatchWorldState("nightmarephase", changestate)
    inst:DoTaskInTime(0, function()
        changestate(inst, TheWorld.state.nightmarephase, true)
    end)

    return inst
end

return Prefab("nightmarelight", fn, assets, prefabs)
