local assets =
{
	Asset("ANIM", "anim/honeycomb.zip"),
}

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBuild("honeycomb")
    inst.AnimState:SetBank("honeycomb")
    inst.AnimState:PlayAnimation("idle")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    --inst:AddComponent("edible")
    --inst.components.edible.healthvalue = TUNING.HONEYCOMB_HEALTH
    --inst.components.edible.hungervalue = TUNING.HONEYCOMB_HUNGER

    inst:AddComponent("tradable")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst:AddComponent("stackable")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("common/inventory/honeycomb", fn, assets)