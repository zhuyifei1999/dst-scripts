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

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    --MakeSnowCovered(inst)
    return inst
end

return Prefab("sunkboat", fn, assets)