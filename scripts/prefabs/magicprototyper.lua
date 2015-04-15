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

local function spawnrabbits(inst)
	if math.random() <= 0.1 then
		local rabbit = SpawnPrefab("rabbit")
		rabbit.Transform:SetPosition(inst.Transform:GetWorldPosition())
	end
end

local function doonact(inst, soundprefix, onact)
    if onact ~= nil then
        onact(inst)
    end
    --inst.SoundEmitter:KillSound("sound")
    inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_ding")
end

local function onbuiltsound(inst, soundprefix)
    inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_place")
    inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_idle_LP","idlesound")
end

local function createmachine(level, name, soundprefix, sounddelay, techtree, mergeanims, onact)
	
	local function onturnon(inst)
		if mergeanims then
			inst.AnimState:PlayAnimation("proximity_pre")
			inst.AnimState:PushAnimation("proximity_loop", true)
		else
			inst.AnimState:PlayAnimation("proximity_loop", true)
		end
		inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_idle_LP","idlesound")
	end

	local function onturnoff(inst)
		if mergeanims then
			inst.AnimState:PushAnimation("proximity_pst")
		    inst.AnimState:PushAnimation("idle", true)
		else
		    inst.AnimState:PlayAnimation("idle", true)
		end
		inst.SoundEmitter:KillSound("idlesound")
	end

    local function onactivate(inst)
        inst.AnimState:PlayAnimation("use")
        inst.AnimState:PushAnimation("idle")
        inst.AnimState:PushAnimation("proximity_loop", true)
        inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_run","sound")
        inst:DoTaskInTime(1.5, doonact, soundprefix, onact)
    end

    local function onbuilt(inst)
        inst.components.prototyper.on = true
        inst.AnimState:PlayAnimation("place")
        inst.AnimState:PushAnimation("idle")
        inst.AnimState:PushAnimation("proximity_loop", true)
        inst:DoTaskInTime(sounddelay, onbuiltsound, soundprefix)
    end

	local assets = 
	{
		Asset("ANIM", "anim/"..name..".zip"),
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
return createmachine(3, "researchlab3", "lvl3", 0.15, TUNING.PROTOTYPER_TREES.SHADOWMANIPULATOR, true),
createmachine(4, "researchlab4", "lvl4", 0, TUNING.PROTOTYPER_TREES.PRESTIHATITATOR, false, spawnrabbits),
MakePlacer("common/researchlab3_placer", "researchlab3", "researchlab3", "idle"),
MakePlacer("common/researchlab4_placer", "researchlab4", "researchlab4", "idle")