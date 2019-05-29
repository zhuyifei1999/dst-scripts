local assets =
{
    Asset("ANIM", "anim/boat_mast.zip"),
    Asset("INV_IMAGE", "mast_item"),
    Asset("ANIM", "anim/seafarer_mast.zip"),
}

local prefabs =
{

}

local function on_hammered(inst, hammerer)
    inst.components.lootdropper:DropLoot()

    local collapse_fx = SpawnPrefab("collapse_small")
    collapse_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    collapse_fx:SetMaterial("wood")

    inst:Remove()
end

local function fn()

    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    MakeObstaclePhysics(inst, .2)

    inst.Transform:SetEightFaced()

    inst:AddTag("NOBLOCK")
    inst:AddTag("structure")

    inst.AnimState:SetBank("mast_01")
    inst.AnimState:SetBuild("boat_mast")
    inst.AnimState:PlayAnimation("closed")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakeLargeBurnable(inst)
    MakeLargePropagator(inst)

    inst:AddComponent("hauntable")
    inst:AddComponent("inspectable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:AddComponent("mast")

    -- The loot that this drops is generated from the uncraftable recipe; see recipes.lua for the items.
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnFinishCallback(on_hammered)

    return inst
end

local function ondeploy(inst, pt, deployer)
    local mast = SpawnPrefab("mast")
    if mast ~= nil then
        mast.Physics:SetCollides(false)
        mast.Physics:Teleport(pt.x, 0, pt.z)
        mast.Physics:SetCollides(true)

        mast.AnimState:PlayAnimation("place")

        inst:Remove()
    end
end

local function item_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("boat_accessory")

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("seafarer_mast")
    inst.AnimState:SetBuild("seafarer_mast")
    inst.AnimState:PlayAnimation("IDLE")

    MakeInventoryFloatable(inst, "med", 0.25, 0.83)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy

    MakeLargeBurnable(inst)
    MakeLargePropagator(inst)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    --inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.NONE)

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("mast", fn, assets, prefabs),
       Prefab("mast_item", item_fn, assets),
       MakePlacer("mast_item_placer", "mast_01", "boat_mast", "closed")
