require "prefabutil"

local function DoCheckTemp(inst)
	local high_temp = 35
	local low_temp = 0
	local temp = math.min(math.max(low_temp, TheWorld.state.temperature), high_temp)
	local percent = (temp - low_temp) / (high_temp - low_temp)
	inst.AnimState:SetPercent("meter", 1 - percent)
end

local function StartCheckTemp(inst)
    if inst.task == nil then
        inst.task = inst:DoPeriodicTask(1, DoCheckTemp, 0)
    end
end

local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
	inst:Remove()
end

local function onhit(inst, worker)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
	inst.AnimState:PlayAnimation("hit")
	--the global animover handler will restart the check task
end

local function onbuilt(inst)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
	inst.AnimState:PlayAnimation("place")
	--the global animover handler will restart the check task
end

local assets = 
{
	Asset("ANIM", "anim/winter_meter.zip"),
}

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .4)

    inst.MiniMapEntity:SetIcon("winterometer.png")

    inst.AnimState:SetBank("winter_meter")
    inst.AnimState:SetBuild("winter_meter")
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
	inst:ListenForEvent("animover", StartCheckTemp)

    StartCheckTemp(inst)

    MakeHauntableWork(inst)

	return inst
end

return Prefab("common/objects/winterometer", fn, assets),
	   MakePlacer("common/winterometer_placer", "winter_meter", "winter_meter", "idle")