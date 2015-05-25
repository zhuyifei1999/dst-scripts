local assets =
{
    Asset("ANIM", "anim/charcoal.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("charcoal")
    inst.AnimState:SetBuild("charcoal")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("molebait")
    MakeDragonflyBait(inst, 3)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.BURNT
    inst.components.edible.hungervalue = 20
    inst.components.edible.healthvalue = 20
        
    inst:AddComponent("tradable")

    inst:AddComponent("bait")

    MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    MakeSmallPropagator(inst)

    MakeHauntableLaunchAndIgnite(inst)

    ---------------------       

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    return inst
end

return Prefab("common/inventory/charcoal", fn, assets)