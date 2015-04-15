require "prefabutil"

local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
	inst:Remove()
end

local function DoCheckRain(inst)
    inst.AnimState:SetPercent("meter", TheWorld.state.pop)
end

local function StartCheckRain(inst)
    if inst.task == nil then
        inst.task = inst:DoPeriodicTask(1, DoCheckRain, 0)
    end
end

local function onhit(inst, worker)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
	inst.AnimState:PlayAnimation("hit")
	--the global animover handler will restart the check task
end

local assets =
{
	Asset("ANIM", "anim/rain_meter.zip"),
}

local function onbuilt(inst)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
	inst.AnimState:PlayAnimation("place")
	--the global animover handler will restart the check task
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .4)

    inst.MiniMapEntity:SetIcon("rainometer.png")

    inst.AnimState:SetBank("rain_meter")
    inst.AnimState:SetBuild("rain_meter")
    inst.AnimState:SetPercent("meter", 0)

    MakeSnowCoveredPristine(inst)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

	inst:AddComponent("inspectable")
	
	inst:AddComponent("lootdropper")
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)		
	MakeSnowCovered(inst)

	inst:ListenForEvent("onbuilt", onbuilt)
	inst:ListenForEvent("animover", StartCheckRain)

	StartCheckRain(inst)

	MakeHauntableWork(inst)

	return inst
end

return Prefab("common/objects/rainometer", fn, assets),
	   MakePlacer("common/rainometer_placer", "rain_meter", "rain_meter", "idle")