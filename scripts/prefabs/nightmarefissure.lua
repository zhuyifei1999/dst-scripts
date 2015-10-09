local assets =
{
    Asset("ANIM", "anim/nightmare_crack_ruins.zip"),
    Asset("ANIM", "anim/nightmare_crack_upper.zip"),
}

local prefabs =
{
    "nightmarebeak",
    "crawlingnightmare",
    "nightmarefissurefx",
    "upper_nightmarefissurefx"
}

local upperLightColour = {239/255, 194/255, 194/255}
local lowerLightColour = {1,1,1}

local function returnchildren(inst)
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

local function spawnchildren(inst)
    if inst.components.childspawner then
        inst.components.childspawner:StartSpawning()
        inst.components.childspawner:StopRegen()
    end
end

local function killchildren(inst)
    if inst.components.childspawner then
        inst.components.childspawner:StopSpawning()
        inst.components.childspawner:StartRegen()
        returnchildren(inst)
    end
end

local function dofx(inst)
    local fx = SpawnPrefab("statue_transition")
    if fx ~= nil then
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx.Transform:SetScale(1, 1.5, 1)
    end
end

local function turnoff(inst, light)
    if light then
        light:Enable(false)
    end
end

local function spawnfx(inst)
    if inst.fx == nil then
        inst.fx = SpawnPrefab(inst.fxprefab)
        local x, y, z = inst.Transform:GetWorldPosition()
        inst.fx.Transform:SetPosition(x, -0.1, z)
    end
end

local states =
{
    calm = function(inst, instant)
        inst.SoundEmitter:KillSound("loop")

        RemovePhysicsColliders(inst)

        inst.Light:Enable(true)
        inst.components.lighttweener:StartTween(nil, 0, nil, nil, nil, (instant and 0) or .33, turnoff)
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


        killchildren(inst)
    end,

    warn = function(inst, instant)

        ChangeToObstaclePhysics(inst)
        inst.Light:Enable(true)
        inst.components.lighttweener:StartTween(nil, 2, nil, nil, nil, (instant and 0) or  0.5)
        inst.AnimState:PlayAnimation("open_1")
        inst.fx.AnimState:PlayAnimation("open_1")
        inst.SoundEmitter:KillSound("loop")
        inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_fissure_open_warning")
        inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_fissure_open_LP", "loop")
    end,

    wild = function(inst, instant)

        ChangeToObstaclePhysics(inst)
        inst.Light:Enable(true)
        inst.components.lighttweener:StartTween(nil, 5, nil, nil, nil, (instant and 0) or 0.5)
        inst.SoundEmitter:KillSound("loop")
        inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_fissure_open")
        inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_fissure_open_LP", "loop")


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

        spawnchildren(inst)
    end,

    dawn = function(inst, instant)
        ChangeToObstaclePhysics(inst)
        inst.Light:Enable(true)
        inst.components.lighttweener:StartTween(nil, 2, nil, nil, nil, (instant and 0) or 0.5)
        inst.SoundEmitter:KillSound("loop")
        inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_fissure_open")
        inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_fissure_open_LP", "loop")

        inst.AnimState:PlayAnimation("close_1")
        inst.fx.AnimState:PlayAnimation("close_1")

        inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_open")

        spawnchildren(inst)
    end
}


local function OnPhaseChanged(inst, phase, instant)
    local statefn = states[phase]

    if statefn then
        spawnfx(inst)
        if instant then
            statefn(inst, true)
        else
            inst:DoTaskInTime(math.random() * 2, statefn)
        end
    end
end

local function getsanityaura(inst)
    if TheWorld.state.isnightmarewarn or TheWorld.state.isnightmaredawn then
        return -TUNING.SANITY_SMALL
    elseif TheWorld.state.isnightmarewild then
        return -TUNING.SANITY_MED
    end

    return 0
end

local function commonfn(type, lightcolour, fxprefab)

    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1.0)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBuild(type)
    inst.AnimState:SetBank(type)
    inst.AnimState:PlayAnimation("idle_closed")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent( "childspawner" )
    inst.components.childspawner:SetRegenPeriod(5)
    inst.components.childspawner:SetSpawnPeriod(30)
    inst.components.childspawner:SetMaxChildren(1)
    inst.components.childspawner.childname = "crawlingnightmare"
    inst.components.childspawner:SetRareChild("nightmarebeak", 0.35)

    inst:AddComponent("lighttweener")
    inst.components.lighttweener:StartTween(inst.Light, 1, .9, 0.9, lightcolour, 0, turnoff)

    inst.fxprefab = fxprefab

    inst:WatchWorldState("nightmarephase", OnPhaseChanged)
    inst:DoTaskInTime(0, function()
        OnPhaseChanged(inst, TheWorld.state.nightmarephase, true)
    end)

    return inst
end


local function upper()
    return commonfn("nightmare_crack_upper", upperLightColour, "upper_nightmarefissurefx")
end

local function lower()
    return commonfn("nightmare_crack_ruins", lowerLightColour, "nightmarefissurefx")
end


return Prefab("fissure", upper, assets, prefabs),
       Prefab("fissure_lower", lower, assets, prefabs)
