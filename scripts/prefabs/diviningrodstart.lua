local assets =
{
	Asset("ANIM", "anim/diviningrod.zip"),
}

local prefabs =
{
    "diviningrod",
}

local function onpickedfn(inst, picker, loot)
    inst.persists = false
	inst.AnimState:PlayAnimation("idle_empty")
	inst:RemoveComponent("inspectable")
	inst:RemoveTag("diviningrod")
	RemovePhysicsColliders(inst)
	if loot and inst.disabled then
	    loot.disabled = true
	end
	inst:DoTaskInTime(3, ErodeAway)
end

local function OnSave(inst, data)
    data.disabled = inst.disabled
end

local function OnLoad(inst, data)
	if data then
	    inst.disabled = data.disabled
	end
end

local function fn(Sim)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .5)

    if not TheWorld.ismastersim then
        return
    end

	inst:AddTag("diviningrod")
	inst:AddTag("irreplaceable")

    inst.AnimState:SetBank("diviningrod")
    inst.AnimState:SetBuild("diviningrod")
    inst.AnimState:PlayAnimation("idle_full")

    inst:AddComponent("inspectable")

    inst:AddComponent("pickable")
    inst.components.pickable:SetUp("diviningrod", nil)
	inst.components.pickable.onpickedfn = onpickedfn

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

    return inst
end

return Prefab("diviningrodstart", fn, assets)
