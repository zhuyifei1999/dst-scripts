
local assets =
{
    Asset("ANIM", "anim/wintertree.zip"),
    Asset("ANIM", "anim/wintertree_build.zip"),
}

local prefabs = 
{
	"winter_tree",
    "collapse_small",
}

local function onhammered(inst)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onplanted(inst, data)
	local x, y, z = inst.Transform:GetWorldPosition()
    inst:Remove()
    local tree = SpawnPrefab("winter_tree")
    tree.Transform:SetPosition(x, y, z)
	tree.components.growable:StartGrowing()
end

local function onbuilt(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/salt_lick_craft") -- placeholder sound
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("idle", false)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()  
    inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, 0.5)

	inst.AnimState:SetBank("wintertree")
	inst.AnimState:SetBuild("wintertree_build")
	inst.AnimState:PlayAnimation("idle")

	MakeSnowCoveredPristine(inst)

	inst:AddTag("winter_treestand")
    inst:AddTag("structure")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(onhammered)

    ---------------------
    MakeMediumBurnable(inst, nil, nil, true)
    MakeMediumPropagator(inst)
	MakeHauntableWork(inst)
	MakeSnowCovered(inst)

    inst:ListenForEvent("onbuilt", onbuilt)
	inst:ListenForEvent("plantwintertreeseed", onplanted)

	return inst
end

return Prefab("winter_treestand", fn, assets, prefabs),
	MakePlacer("winter_treestand_placer", "wintertree", "wintertree_build", "idle")

