local assets =
{
	Asset("ANIM", "anim/wagdrone_parts.zip"),
}

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("wagdrone_parts")
	inst.AnimState:SetBuild("wagdrone_parts")
	inst.AnimState:PlayAnimation("idle")

	inst.pickupsound = "metal"

	MakeInventoryFloatable(inst, "med", 0.5, { 0.75, 1.1, 0.75 })

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("wagdrone_parts", fn, assets)
