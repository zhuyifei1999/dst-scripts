local assets =
{
	Asset("ANIM", "anim/anim_test.zip"),
}

local function fn(Sim)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:SetBank("anim_test_bank")
    inst.AnimState:SetBuild("anim_test")
    inst.AnimState:PlayAnimation("anim0", true)

    return inst
end

return Prefab("anim_test", fn, assets)