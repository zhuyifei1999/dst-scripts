local assets =
{
    Asset("ANIM", "anim/bandage_butterfly.zip"),
}

local function OnHealFn(inst, target, doer)
    if target.components.sanity ~= nil then
        target.components.sanity:DoDelta(TUNING.SANITY_SMALL)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("bandage_butterfly")
    inst.AnimState:SetBuild("bandage_butterfly")
    inst.AnimState:PlayAnimation("idle")

    inst.pickupsound = "vegetation_firm"

    MakeInventoryFloatable(inst, nil, .05, .9)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("healer")
    inst.components.healer:SetHealthAmount(TUNING.HEALING_MEDLARGE)
    inst.components.healer:SetOnHealFn(OnHealFn)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("bandage_butterflywings", fn, assets)