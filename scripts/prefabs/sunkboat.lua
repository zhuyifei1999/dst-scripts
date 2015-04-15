local assets =
{
	Asset("ANIM", "anim/boat_sunk.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("boat_sunk")
    inst.AnimState:SetBuild("boat_sunk")

    --MakeSnowCoveredPristine(inst)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst:AddComponent("inspectable")
    --MakeSnowCovered(inst)
    return inst
end

return Prefab("forest/objects/sunkboat", fn, assets)