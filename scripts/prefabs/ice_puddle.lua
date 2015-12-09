local assets =
{
    Asset("ANIM", "anim/ice_puddle.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("ice_puddle")
    inst.AnimState:SetBuild("ice_puddle")
    inst.AnimState:PlayAnimation("full")
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return Prefab("common/fx/ice_puddle", fn, assets)