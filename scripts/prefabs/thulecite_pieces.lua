local assets =
{
	Asset("ANIM", "anim/thulecite_pieces.zip"),
}

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("thulecite_pieces")
    inst.AnimState:SetBuild("thulecite_pieces")
    inst.AnimState:PlayAnimation("anim")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.ELEMENTAL
    inst.components.edible.hungervalue = 1

    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("repairer")
    inst.components.repairer.repairmaterial = MATERIALS.THULECITE
    inst.components.repairer.healthrepairvalue = TUNING.REPAIR_THULECITE_PIECES_HEALTH
    inst.components.repairer.workrepairvalue = TUNING.REPAIR_THULECITE_PIECES_WORK

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    MakeHauntableLaunchAndSmash(inst)
    
    return inst
end

return Prefab("common/inventory/thulecite_pieces", fn, assets)