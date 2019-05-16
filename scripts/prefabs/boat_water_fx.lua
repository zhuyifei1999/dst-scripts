local assets =
{
    Asset("ANIM", "anim/boat_water_fx.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("NOBLOCK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("boat_water_fx")
    inst.AnimState:SetBuild("boat_water_fx")
    inst.AnimState:PlayAnimation("idle_loop")
    inst.AnimState:SetSortOrder(ANIM_SORT_ORDER.OCEAN_WAVES)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)    
    inst.AnimState:SetLayer(LAYER_BACKGROUND)     

    inst:ListenForEvent("animover", inst.Remove)

    return inst
end

return Prefab("boat_water_fx", fn, assets)
