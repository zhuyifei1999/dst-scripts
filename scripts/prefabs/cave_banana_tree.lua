local assets=
{
	Asset("ANIM", "anim/cave_banana_tree.zip"),
}


local prefabs =
{
    "cave_banana",
    "charcoal",
    "log",
    "twigs",
}

local function onregenfn(inst)
	inst.AnimState:PlayAnimation("grow")
	inst.AnimState:PushAnimation("idle_loop", true)
	inst.AnimState:Show("BANANA")
end

local function makefullfn(inst)
	inst.AnimState:PlayAnimation("idle_loop", true)
	inst.AnimState:Show("BANANA")
end


local function onpickedfn(inst)
	inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
	inst.AnimState:PlayAnimation("pick")
	inst.AnimState:PushAnimation("idle_loop")
	inst.AnimState:Hide("BANANA")
end

local function makeemptyfn(inst)
	inst.AnimState:PlayAnimation("idle_loop")
	inst.AnimState:Hide("BANANA")
end

local function setupstump(inst)
	local stump = SpawnPrefab("cave_banana_stump")
	local pos = inst:GetPosition()
	stump.Transform:SetPosition(pos:Get())
	inst:Remove()
end

local function tree_chopped(inst, worker)
	if not worker or (worker and not worker:HasTag("playerghost")) then
		inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
	end

	inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")

	inst.components.lootdropper:SpawnLootPrefab("log")
	inst.components.lootdropper:SpawnLootPrefab("twigs")
	inst.components.lootdropper:SpawnLootPrefab("twigs")
	inst.AnimState:Hide("BANANA")
	if inst.components.pickable and inst.components.pickable.canbepicked then
		inst.components.lootdropper:SpawnLootPrefab("cave_banana")
	end
	inst.components.pickable.caninteractwith = false
	inst.components.workable.workable = false
	inst.AnimState:PlayAnimation("fall")
	inst:ListenForEvent("animover", setupstump)
end

local function tree_chop(inst, worker)
	inst.AnimState:PlayAnimation("chop")
	inst.AnimState:PushAnimation("idle_loop", true)
	if not worker or (worker and not worker:HasTag("playerghost")) then
    	inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
    end
end

local function tree_startburn(inst)
    if inst.components.pickable then
    	inst.components.pickable.caninteractwith = false
    end
end

local function tree_burnt(inst)
	local burnt_tree = SpawnPrefab("cave_banana_burnt")
	local pos = inst:GetPosition()
	burnt_tree.no_banana = inst.components.pickable and not inst.components.pickable.canbepicked
	inst:Remove()
	burnt_tree.Transform:SetPosition(pos:Get())
	if burnt_tree.no_banana then
		burnt_tree.AnimState:Hide("BANANA")
	end
end

local function tree_fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    local sound = inst.entity:AddSoundEmitter()
	local minimap = inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst,.5)

	minimap:SetIcon( "cave_banana_tree.png" )

    anim:SetBank("cave_banana_tree")
    anim:SetBuild("cave_banana_tree")
    anim:PlayAnimation("idle_loop",true)
    anim:SetTime(math.random()*2)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
    	return inst
    end

	inst:AddComponent("pickable")
	inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"
	inst.components.pickable:SetUp("cave_banana", TUNING.CAVE_BANANA_GROW_TIME)
	inst.components.pickable.onregenfn = onregenfn
	inst.components.pickable.onpickedfn = onpickedfn
	inst.components.pickable.makeemptyfn = makeemptyfn
	inst.components.pickable.makefullfn = makefullfn


	inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.CHOP)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnFinishCallback(tree_chopped)
    inst.components.workable:SetOnWorkCallback(tree_chop)


	inst:AddComponent("lootdropper")
    inst:AddComponent("inspectable")

    ---------------------
    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)
	MakeNoGrowInWinter(inst)
    ---------------------

    inst.components.burnable:SetOnIgniteFn(tree_startburn)
	inst.components.burnable:SetOnBurntFn(tree_burnt)

    return inst
end

local function stump_burnt(inst)
	inst.components.lootdropper:SpawnLootPrefab("ash")
	inst:Remove()
end

local function stump_dug(inst)
	inst.components.lootdropper:SpawnLootPrefab("log")
	inst:Remove()
end

local function stump_fn()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    local sound = inst.entity:AddSoundEmitter()
    local minimap = inst.entity:AddMiniMapEntity()
	minimap:SetIcon( "cave_banana_tree.png" )
	inst.entity:AddNetwork()

    anim:SetBank("cave_banana_tree")
    anim:SetBuild("cave_banana_tree")
	inst.AnimState:PlayAnimation("idle_stump")

	inst:SetPrefabNameOverride("cave_banana_tree")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
    	return inst
    end

	inst:AddComponent("lootdropper")
    inst:AddComponent("inspectable")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnWorkCallback(stump_dug)

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
	inst.components.burnable:SetOnBurntFn(stump_burnt)

    return inst
end

local function burnt_chopped(inst)
	inst.components.workable.workable = false
	inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
	inst.AnimState:PlayAnimation("chop_burnt")
	inst.components.lootdropper:SpawnLootPrefab("charcoal")
	inst.persists = false
	inst:DoTaskInTime(50*FRAMES, inst.Remove)
end

local function burnt_onsave(inst, data)
	if inst.no_banana then
		data.no_banana = inst.no_banana
	end
end

local function burnt_onload(inst, data)
	if data and data.no_banana then
		inst.no_banana = data.no_banana
		inst.AnimState:Hide("BANANA")
	end
end

local function burnt_fn()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    local sound = inst.entity:AddSoundEmitter()
    local minimap = inst.entity:AddMiniMapEntity()
	minimap:SetIcon( "cave_banana_tree.png" )
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst,.5)

    anim:SetBank("cave_banana_tree")
    anim:SetBuild("cave_banana_tree")
	inst.AnimState:PlayAnimation("burnt")

	inst:SetPrefabNameOverride("cave_banana_tree")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
    	return inst
    end

    inst:AddComponent("inspectable")
	inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.CHOP)
	inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(burnt_chopped)

    MakeHauntableWorkAndIgnite(inst)

    inst.OnSave = burnt_onsave
    inst.OnLoad = burnt_onload

	return inst
end

return Prefab("cave_banana_tree", tree_fn, assets, prefabs),
Prefab("cave_banana_burnt", burnt_fn, assets, prefabs),
Prefab("cave_banana_stump", stump_fn, assets, prefabs)