local assets =
{
    Asset("ANIM", "anim/twigs.zip"),
    Asset("SOUND", "sound/common.fsb"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("twigs")
    inst.AnimState:SetBuild("twigs")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("cattoy")
    MakeDragonflyBait(inst, 3)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -----------------
    inst:AddComponent("inventoryitem")
    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
    inst:AddComponent("tradable")

    -----------------
    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.WOOD
    inst.components.edible.woodiness = 5
    inst.components.edible.healthvalue = 0
    inst.components.edible.hungervalue = 0

    ---------------------
    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunchAndIgnite(inst)

    inst:AddComponent("inspectable")
    ----------------------

    inst:AddComponent("repairer")
    inst.components.repairer.repairmaterial = MATERIALS.WOOD
    inst.components.repairer.healthrepairvalue = TUNING.REPAIR_STICK_HEALTH

    return inst
end

return Prefab("twigs", fn, assets)
