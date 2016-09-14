local prefabs =
{
    "collapse_small",
}

local assets =
{
    Asset("ANIM", "anim/stagehand.zip"),
    Asset("SOUND", "sound/sfx.fsb"),
}

local function onhammered(inst)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst, worker, workleft)
    if not inst:HasTag("burnt") and workleft > 0 then
        inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stagehand/hit")
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle")
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .6)

    inst:AddTag("structure")

    inst.AnimState:SetBank("stagehand")
    inst.AnimState:SetBuild("stagehand")
    inst.AnimState:PlayAnimation("idle")

	MakeSnowCoveredPristine(inst)
     
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakeSmallBurnable(inst, nil, nil, true)
    MakeSmallPropagator(inst)
	MakeHauntableWork(inst)
	MakeSnowCovered(inst)

	inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")

    return inst
end


return Prefab("endtable", fn, assets, prefabs),
       MakePlacer("endtable_placer", "stagehand", "stagehand", "idle")

