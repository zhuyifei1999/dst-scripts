local assets =
{
    Asset("ANIM", "anim/purple_gem.zip"),
    Asset("INV_IMAGE", "purplegem"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("purplegem")
    inst.AnimState:SetBuild("purple_gem")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("key")
    inst.components.key.keytype = LOCKTYPE.MAXWELL

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:ChangeImageName("purplegem")

    return inst
end

return Prefab("maxwellkey", fn, assets)