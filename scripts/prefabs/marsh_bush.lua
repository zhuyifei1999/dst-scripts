local assets =
{
	Asset("ANIM", "anim/marsh_bush.zip"),
}

local prefabs =
{
    "twigs",
    "dug_marsh_bush",
}

local function ontransplantfn(inst)
	inst.components.pickable:MakeEmpty()
end

local function dig_up(inst, chopper)
	if inst.components.pickable and inst.components.pickable:CanBePicked() then
		inst.components.lootdropper:SpawnLootPrefab("twigs")
	end
	inst:Remove()
	inst.components.lootdropper:SpawnLootPrefab("dug_marsh_bush")
end

local function onpickedfn(inst, picker)
	inst.AnimState:PlayAnimation("picking")
	inst.AnimState:PushAnimation("picked", false)
	if picker.components.combat then
        picker.components.combat:GetAttacked(inst, TUNING.MARSHBUSH_DAMAGE)
        picker:PushEvent("thorns")
	end
end

local function onregenfn(inst)
	inst.AnimState:PlayAnimation("grow")
	inst.AnimState:PushAnimation("idle", true)
end

local function makeemptyfn(inst)
	inst.AnimState:PlayAnimation("idle_dead")
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("marsh_bush")
    inst.AnimState:SetBank("marsh_bush")
    inst.AnimState:PlayAnimation("idle", true)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst.AnimState:SetTime(math.random()*2)

    local color = 0.5 + math.random() * 0.5
    inst.AnimState:SetMultColour(color, color, color, 1)

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/harvest_sticks"
    
    inst.components.pickable:SetUp("twigs", TUNING.MARSHBUSH_REGROW_TIME)
	inst.components.pickable.onregenfn = onregenfn
	inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.makeemptyfn = makeemptyfn
	inst.components.pickable.ontransplantfn = ontransplantfn

	inst:AddComponent("lootdropper")
	inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(dig_up)
    inst.components.workable:SetWorkLeft(1)
    
    inst:AddComponent("inspectable")
    
    MakeLargeBurnable(inst)
    MakeLargePropagator(inst)
    MakeHauntableIgnite(inst)

    return inst
end

return Prefab("marsh/objects/marsh_bush", fn, assets, prefabs)