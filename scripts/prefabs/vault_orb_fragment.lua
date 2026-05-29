local assets = {
	Asset("ANIM", "anim/vault_orb_fragment.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("vault_orb_fragment")
    inst.AnimState:SetBuild("vault_orb_fragment")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "small", 0.05, { 0.8, 0.75, 0.8 })

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

return Prefab("vault_orb_fragment", fn, assets)
