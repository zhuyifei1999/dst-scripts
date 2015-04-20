local assets =
{
    Asset("ANIM", "anim/ice_splash.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("ice_splash")
    inst.AnimState:SetBuild("ice_splash")
    inst.AnimState:PlayAnimation("full")

    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return Prefab("common/fx/ice_splash", fn, assets)