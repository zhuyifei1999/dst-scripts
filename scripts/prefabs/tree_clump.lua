local assets =
{
	Asset("ANIM", "anim/tree_clump.zip"),
}

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1.25)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:SetBank("tree_clump")
    inst.AnimState:SetBuild("tree_clump")
    inst.AnimState:PlayAnimation("anim", false)

    inst:AddComponent("inspectable")

    return inst
end

return Prefab("common/objects/treeclump", fn, assets)