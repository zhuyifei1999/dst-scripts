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

local function onhit(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation(inst.components.prototyper.on and "proximity_loop" or "idle", true)
    end
end

local function doonact(inst, soundprefix)
    if inst._activecount > 1 then
        inst._activecount = inst._activecount - 1
    else
        inst._activecount = 0
        inst.SoundEmitter:KillSound("sound")
    end
    inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_ding")
end

local function onturnoff(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PushAnimation("idle", true)
        inst.SoundEmitter:KillSound("idlesound")
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

local function createmachine(level, name, soundprefix, techtree)
    local assets =
    {
        Asset("ANIM", "anim/"..name..".zip"),
    }

    local prefabs =
    {
        "collapse_small",
    }

    local function onturnon(inst)
        if not inst:HasTag("burnt") then 
            inst.AnimState:PlayAnimation("proximity_loop", true)
            if not inst.SoundEmitter:PlayingSound("idlesound") then
                inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_idle_LP", "idlesound")
            end
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
            inst:DoTaskInTime(1.5, doonact, soundprefix)
        end
    end

    local function onbuilt(inst)
        inst.components.prototyper.on = true
        inst.AnimState:PlayAnimation("place")
        inst.AnimState:PushAnimation("idle")
        inst.AnimState:PushAnimation("proximity_loop", true)
        inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_place")
        inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_idle_LP", "idlesound")              
    end

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
return createmachine(1, "researchlab", "lvl1", TUNING.PROTOTYPER_TREES.SCIENCEMACHINE),
    createmachine(2, "researchlab2", "lvl2", TUNING.PROTOTYPER_TREES.ALCHEMYMACHINE),
    MakePlacer("common/researchlab_placer", "researchlab", "researchlab", "idle" ),
    MakePlacer("common/researchlab2_placer", "researchlab2", "researchlab2", "idle")
