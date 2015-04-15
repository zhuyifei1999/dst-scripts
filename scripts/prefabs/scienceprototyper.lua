require "prefabutil"

local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
	inst:Remove()
end

local function onhit(inst, worker)
	inst.AnimState:PlayAnimation("hit")
	inst.AnimState:PushAnimation(inst.components.prototyper.on and "proximity_loop" or "idle", true)
end

local function doonact(inst, soundprefix)
    inst.SoundEmitter:KillSound("sound")
    inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_ding", "sound")
end

local function onturnoff(inst)
    inst.AnimState:PushAnimation("idle", true)
    inst.SoundEmitter:KillSound("idlesound")
end

local function createmachine(level, name, soundprefix, techtree)

    local assets =
    {
        Asset("ANIM", "anim/"..name..".zip"),
    }

	local function onturnon(inst)
		inst.AnimState:PlayAnimation("proximity_loop", true)
		inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_idle_LP", "idlesound")
	end

    local function onactivate(inst)
        inst.AnimState:PlayAnimation("use")
        inst.AnimState:PushAnimation("idle")
        inst.AnimState:PushAnimation("proximity_loop", true)
        inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_run","sound")
        inst:DoTaskInTime(1.5, doonact, soundprefix)
    end

    local function onbuilt(inst)
        inst.components.prototyper.on = true
        inst.AnimState:PlayAnimation("place")
        inst.AnimState:PushAnimation("idle")
        inst.AnimState:PushAnimation("proximity_loop", true)
        inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_place")
        inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_idle_LP","idlesound")              
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

        if not TheWorld.ismastersim then
            return inst
        end

        inst.entity:SetPristine()

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

		inst:AddComponent("hauntable")
		inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

		return inst
	end
	return Prefab("common/objects/"..name, fn, assets)
end
--Using old prefab names
return createmachine(1, "researchlab", "lvl1", TUNING.PROTOTYPER_TREES.SCIENCEMACHINE),
	createmachine(2, "researchlab2", "lvl2", TUNING.PROTOTYPER_TREES.ALCHEMYMACHINE),
	MakePlacer("common/researchlab_placer", "researchlab", "researchlab", "idle" ),
	MakePlacer("common/researchlab2_placer", "researchlab2", "researchlab2", "idle")