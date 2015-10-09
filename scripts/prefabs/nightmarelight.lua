    local assets =
{
    Asset("ANIM", "anim/rock_light.zip"),
}

local prefabs =
{
    "nightmarelightfx",
}

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

local function turnoff(inst, light)
    if light ~= nil then
        light:Enable(false)
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

        inst.Light:Enable(true)

        inst.components.lighttweener:StartTween(nil, 0, nil, nil, nil, (instant and 0) or 1, turnoff)

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

        inst.Light:Enable(true)

        inst.components.lighttweener:StartTween(nil, 3, nil, nil, nil, (instant and 0) or  0.5)

        inst.AnimState:PlayAnimation("open_1")
        inst.fx.AnimState:PlayAnimation("open_1")
        inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_open_warning")
        inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_warning_LP", "warnLP")
    end,

    wild = function(inst, instant)

        inst.SoundEmitter:KillSound("warnLP")
        inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_open_LP", "nightmareLP")

        inst.Light:Enable(true)

        inst.components.lighttweener:StartTween(nil, 6, nil, nil, nil, (instant and 0) or 0.5)
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
        inst.Light:Enable(true)
        inst.components.lighttweener:StartTween(nil, 3, nil, nil, nil, (instant and 0) or 0.5)
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
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    inst.MiniMapEntity:SetIcon( "nightmarelight.png" )

    inst.AnimState:SetBuild("rock_light")
    inst.AnimState:SetBank("rock_light")
    inst.AnimState:PlayAnimation("idle_closed",false)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakeObstaclePhysics(inst, 1)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = getsanityaura

    inst:AddComponent( "childspawner" )
    inst.components.childspawner:SetRegenPeriod(5)
    inst.components.childspawner:SetSpawnPeriod(30)
    inst.components.childspawner:SetMaxChildren(math.random(1,2))
    inst.components.childspawner.childname = "crawlingnightmare"
    inst.components.childspawner:SetRareChild("nightmarebeak", 0.35)

    inst:AddComponent("inspectable")

    inst:AddComponent("lighttweener")
    inst.components.lighttweener:StartTween(inst.Light, 1, .9, 0.9, {255/255,255/255,255/255}, 0, turnoff)

    inst:WatchWorldState("nightmarephase", changestate)
    inst:DoTaskInTime(0, function()
        changestate(inst, TheWorld.state.nightmarephase, true)
    end)

    return inst
end

return Prefab( "nightmarelight", fn, assets, prefabs)

