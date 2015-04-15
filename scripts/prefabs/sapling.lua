local assets =
{
	Asset("ANIM", "anim/sapling.zip"),
	Asset("SOUND", "sound/common.fsb"),
}

local prefabs =
{
    "twigs",
    "dug_sapling",
}    

local function ontransplantfn(inst)
	inst.components.pickable:MakeEmpty()
end

local function dig_up(inst, chopper)
	if inst.components.pickable and inst.components.pickable:CanBePicked() then
		inst.components.lootdropper:SpawnLootPrefab("twigs")
	end
	inst:Remove()
	local bush = inst.components.lootdropper:SpawnLootPrefab("dug_sapling")
end

local function onpickedfn(inst)
	inst.AnimState:PlayAnimation("rustle") 
	inst.AnimState:PushAnimation("picked", false) 
end

local function onregenfn(inst)
	inst.AnimState:PlayAnimation("grow") 
	inst.AnimState:PushAnimation("sway", true)
end

local function makeemptyfn(inst)
	inst.AnimState:PlayAnimation("empty")
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("sapling.png")

    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:SetBank("sapling")
    inst.AnimState:SetBuild("sapling")
    inst.AnimState:PlayAnimation("sway", true)

    inst:AddTag("renewable")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()
    
    inst.AnimState:SetTime(math.random() * 2)

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/harvest_sticks"
    
    inst.components.pickable:SetUp("twigs", TUNING.SAPLING_REGROW_TIME)
	inst.components.pickable.onregenfn = onregenfn
	inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.makeemptyfn = makeemptyfn
	inst.components.pickable.ontransplantfn = ontransplantfn

    inst:AddComponent("inspectable")

	inst:AddComponent("lootdropper")
	inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(dig_up)
    inst.components.workable:SetWorkLeft(1)

    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)
	MakeNoGrowInWinter(inst)    
	MakeHauntableIgnite(inst)
    ---------------------   
    
    return inst
end

return Prefab("forest/objects/sapling", fn, assets, prefabs)