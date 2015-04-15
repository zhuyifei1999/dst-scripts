local assets =
{
	Asset("ANIM", "anim/cook_pot_food.zip"),
}

local function OnGetHealth(inst, eater)
	local damage = eater and eater.components.health.maxhealth or TUNING.WILSON_HEALTH * 4
	return -damage
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

    inst.AnimState:SetBuild("cook_pot_food")
    inst.AnimState:SetBank("food")
    inst.AnimState:PlayAnimation("bonestew", false)

    inst:AddTag("meat")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

	inst:AddComponent("edible")
	inst.components.edible.ismeat = true
	inst.components.edible.foodtype = FOODTYPE.MEAT
    inst.components.edible.healthvalue = -TUNING.HEALING_SUPERHUGE --Dummy value used for "badfood" check
	inst.components.edible:SetGetHealthFn(OnGetHealth)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem:ChangeImageName("bonestew")

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("common/inventory/deadlyfeast", fn, assets)