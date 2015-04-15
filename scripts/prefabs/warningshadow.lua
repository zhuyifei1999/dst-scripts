local assets =
{
	Asset("ANIM", "anim/warning_shadow.zip"),
}

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("warning_shadow")
    inst.AnimState:SetBuild("warning_shadow")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetFinalOffset(-1)

    inst:AddTag("FX")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst.persists = false

    return inst
end

return Prefab("common/fx/warningshadow", fn, assets)