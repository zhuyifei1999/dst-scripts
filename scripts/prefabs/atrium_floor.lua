local assets =
{
    Asset("ANIM", "anim/atrium_floor.zip"),
}

local prefabs =
{
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    --[[Non-networked entity]]

    inst:AddTag("DECOR")
    inst:AddTag("NOCLICK")
    
    inst.persists = false

    inst.AnimState:SetBank("atrium_floor")
    inst.AnimState:SetBuild("atrium_floor")
    inst.AnimState:PlayAnimation("idle_active")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(2)

    return inst
end

return Prefab("atrium_floor", fn, assets, prefabs)
