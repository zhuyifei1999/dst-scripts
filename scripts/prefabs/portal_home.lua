local assets =
{
	Asset("ANIM", "anim/grass.zip"),
}

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:SetBank("grass")
    inst.AnimState:SetBuild("grass1")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetTime(math.random() * 2)

    return inst
end

return Prefab("portal_home", fn, assets)