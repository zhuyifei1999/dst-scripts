local assets =
{
    Asset("ANIM", "anim/reticule.zip"),
}

local function reticule()
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("reticule")
    inst.AnimState:SetBuild("reticule")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddComponent("colourtweener")
    inst.components.colourtweener:StartTween({ 0, 0, 0, 1 }, 0)

    return inst
end

return Prefab("reticule", reticule, assets)
