local assets =
{
    Asset("ANIM", "anim/oar.zip"),
    Asset("ANIM", "anim/swap_oar.zip"),
}

local prefabs =
{
    
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_oar", "swap_oar")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function onpocket(inst, owner)

end

local function onattack(weapon, attacker, target)

end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst:AddTag("allow_action_on_impassable")

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("oar")
    inst.AnimState:SetBuild("oar")
    inst.AnimState:PlayAnimation("idle")

    inst.MiniMapEntity:SetIcon("boat_net.png")

    MakeInventoryFloatable(inst, "large", nil, {0.68, 0.5, 0.68})

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst:AddComponent("oar")
    inst:AddComponent("inspectable")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnPocket(onpocket)
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("burnable")
    inst.components.burnable.canlight = false
    inst.components.burnable.fxprefab = nil

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.OAR_USES)
    inst.components.finiteuses:SetUses(TUNING.OAR_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetConsumption(ACTIONS.ROW, 1)


    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("oar", fn, assets, prefabs)
