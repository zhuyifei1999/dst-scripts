local assets =
{
    Asset("ANIM", "anim/gridplacer.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("gridplacer")
    inst.AnimState:SetBuild("gridplacer")
    inst.AnimState:PlayAnimation("anim", true)
    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

    inst:AddComponent("placer")
    inst.components.placer.snap_to_tile = true
    inst.components.placer.oncanbuild = inst.Show
    inst.components.placer.oncannotbuild = inst.Hide

    return inst
end

return Prefab("common/gridplacer", fn, assets)
