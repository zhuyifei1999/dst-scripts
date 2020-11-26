local assets =
{
    Asset("ANIM", "anim/quagmire_hoe.zip"),
}

local prefabs =
{
    "farm_soil",
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "quagmire_hoe", "swap_quagmire_hoe")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("quagmire_hoe")
    inst.AnimState:SetBuild("quagmire_hoe")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.FARM_HOE_USES)
    inst.components.finiteuses:SetUses(TUNING.FARM_HOE_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetConsumption(ACTIONS.TILL, 1)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.FARM_HOE_DAMAGE)

    inst:AddInherentAction(ACTIONS.TILL)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("farmtiller")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("farm_hoe", fn, assets, prefabs)
