local assets =
{
	Asset("ANIM", "anim/armor_sweatervest.zip"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "armor_sweatervest", "swap_body")
    inst.components.fueled:StartConsuming()
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    inst.components.fueled:StopConsuming()
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:SetBank("armor_sweatervest")
    inst.AnimState:SetBuild("armor_sweatervest")
    inst.AnimState:PlayAnimation("anim")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("dapperness")
    inst.components.dapperness.dapperness = TUNING.DAPPERNESS_MED
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY

    inst.components.equippable:SetOnEquip( onequip )
    inst.components.equippable:SetOnUnequip( onunequip )

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE
    inst.components.fueled:InitializeFuelLevel(TUNING.SWEATERVEST_PERISHTIME)
    inst.components.fueled:SetDepletedFn(inst.Remove)

	inst:AddComponent("insulator")
    inst.components.insulator.insulation = TUNING.INSULATION_SMALL

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("common/inventory/sweatervest", fn, assets)