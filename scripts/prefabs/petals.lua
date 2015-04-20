local assets =
{
    Asset("ANIM", "anim/flower_petals.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("petals")
    inst.AnimState:SetBuild("flower_petals")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("cattoy")
    MakeDragonflyBait(inst, 3)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("tradable")

    inst:AddComponent("inspectable")

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.TINY_FUEL

    MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
    MakeSmallPropagator(inst)

    inst:AddComponent("edible")
    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.hungervalue = 0
    inst.components.edible.foodtype = FOODTYPE.VEGGIE

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    MakeHauntableLaunchAndPerish(inst)
    AddHauntableCustomReaction(inst, function(inst, haunter)
        if math.random() <= TUNING.HAUNT_CHANCE_HALF then
            local fx = SpawnPrefab("small_puff")
            if fx then fx.Transform:SetPosition(inst.Transform:GetWorldPosition()) end
            local new = SpawnPrefab("petals_evil")
            if new then
                new.Transform:SetPosition(inst.Transform:GetWorldPosition())
                if new.components.perishable and inst.components.perishable then
                    new.components.perishable:SetPercent(inst.components.perishable:GetPercent())
                end
                new:PushEvent("spawnedfromhaunt", {haunter=haunter, oldPrefab=inst})
            end
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
            inst:DoTaskInTime(0, function(inst) inst:Remove() end)
            return true
        end
        return false
    end, false, true, false)

    return inst
end

return Prefab("common/inventory/petals", fn, assets)