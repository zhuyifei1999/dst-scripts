require "prefabutil"

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then 
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation(inst.components.prototyper.on and "proximity_loop" or "idle", true)
    end
end

local function spawnrabbits(inst)
    if not inst:HasTag("burnt") and math.random() <= 0.1 then
        SpawnPrefab("rabbit").Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function doonact(inst, soundprefix, onact)
    if onact ~= nil then
        onact(inst)
    end
    if inst._activecount > 1 then
        inst._activecount = inst._activecount - 1
    else
        inst._activecount = 0
        inst.SoundEmitter:KillSound("sound")
    end
    inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_ding")
end

local function onbuiltsound(inst, soundprefix)
    inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_place")
end

local function createmachine(level, name, soundprefix, sounddelay, techtree, mergeanims, onact)
    local function onturnon(inst)
        if not inst:HasTag("burnt") then 
            if mergeanims then
                inst.AnimState:PlayAnimation("proximity_pre")
                inst.AnimState:PushAnimation("proximity_loop", true)
            else
                inst.AnimState:PlayAnimation("proximity_loop", true)
            end
            if not inst.SoundEmitter:PlayingSound("idlesound") then
                inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_idle_LP", "idlesound")
            end
        end
    end

    local function onturnoff(inst)
        if not inst:HasTag("burnt") then 
            if mergeanims then
                inst.AnimState:PushAnimation("proximity_pst")
                inst.AnimState:PushAnimation("idle", true)
            else
                inst.AnimState:PlayAnimation("idle", true)
            end
            inst.SoundEmitter:KillSound("idlesound")
        end
    end

    local function onactivate(inst)
        if not inst:HasTag("burnt") then 
            inst.AnimState:PlayAnimation("use")
            inst.AnimState:PushAnimation("idle")
            inst.AnimState:PushAnimation("proximity_loop", true)
            if not inst.SoundEmitter:PlayingSound("sound") then
                inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_run", "sound")
            end
            inst._activecount = inst._activecount + 1
            inst:DoTaskInTime(1.5, doonact, soundprefix, onact)
        end
    end

    local function onbuilt(inst)
        inst.components.prototyper.on = true
        inst.AnimState:PlayAnimation("place")
        inst.AnimState:PushAnimation("idle")
        inst.AnimState:PushAnimation("proximity_loop", true)
        inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_idle_LP", "idlesound")
        inst:DoTaskInTime(sounddelay, onbuiltsound, soundprefix)
    end

    local assets =
    {
        Asset("ANIM", "anim/"..name..".zip"),
    }

    local prefabs =
    {
        "collapse_small",
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, .4)

        inst.MiniMapEntity:SetPriority(5)
        inst.MiniMapEntity:SetIcon(name..".png")

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("prototyper")
        inst:AddTag("structure")
        inst:AddTag("level"..level)

        MakeSnowCoveredPristine(inst)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst._activecount = 0

        inst:AddComponent("inspectable")
        inst:AddComponent("prototyper")
        inst.components.prototyper.onturnon = onturnon
        inst.components.prototyper.onturnoff = onturnoff
        inst.components.prototyper.trees = techtree
        inst.components.prototyper.onactivate = onactivate

        inst:ListenForEvent("onbuilt", onbuilt)

        inst:AddComponent("lootdropper")
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(4)
        inst.components.workable:SetOnFinishCallback(onhammered)
        inst.components.workable:SetOnWorkCallback(onhit)
        MakeSnowCovered(inst)

        MakeLargeBurnable(inst, nil, nil, true)
        MakeLargePropagator(inst)

        inst.OnSave = onsave
        inst.OnLoad = onload

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

        return inst
    end
    return Prefab("common/objects/"..name, fn, assets, prefabs)
end

--Using old prefab names
return createmachine(3, "researchlab3", "lvl3", 0.15, TUNING.PROTOTYPER_TREES.SHADOWMANIPULATOR, true),
    createmachine(4, "researchlab4", "lvl4", 0, TUNING.PROTOTYPER_TREES.PRESTIHATITATOR, false, spawnrabbits),
    MakePlacer("common/researchlab3_placer", "researchlab3", "researchlab3", "idle"),
    MakePlacer("common/researchlab4_placer", "researchlab4", "researchlab4", "idle")
