local assets =
{
    Asset("ANIM", "anim/boat_mast.zip"),
    Asset("INV_IMAGE", "mast_item"),
    Asset("ANIM", "anim/seafarer_mast.zip"),
}

local prefabs =
{
	"boat_mast_sink_fx",
	"collapse_small",
}

local function on_hammered(inst, hammerer)
    inst.components.lootdropper:DropLoot()

    local collapse_fx = SpawnPrefab("collapse_small")
    collapse_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    collapse_fx:SetMaterial("wood")

    inst:Remove()
end

local function onburnt(inst)
	inst:AddTag("burnt")

	local mast = inst.components.mast
	if mast.boat ~= nil then
		mast.boat.components.boatphysics:RemoveMast(mast)
	end

	inst:RemoveComponent("mast")
end

local function onsave(inst, data)
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
		data.burnt = true
	end
end

local function onload(inst, data)
	if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
		inst:PushEvent("onburnt")
    end
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
    inst:AddTag("mast")

    inst.AnimState:SetBank("mast_01")
    inst.AnimState:SetBuild("boat_mast")
    inst.AnimState:PlayAnimation("closed")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakeLargeBurnable(inst, nil, nil, true)
	inst:ListenForEvent("onburnt", onburnt)
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

	inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

local function ondeploy(inst, pt, deployer)
    local mast = SpawnPrefab("mast")
    if mast ~= nil then
        mast.Physics:SetCollides(false)
        mast.Physics:Teleport(pt.x, 0, pt.z)
        mast.Physics:SetCollides(true)
        mast.SoundEmitter:PlaySound("turnoftides/common/together/boat/mast/place")
        mast.AnimState:PlayAnimation("place")
        mast.AnimState:PushAnimation("closed", false)

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
    inst.components.deployable:SetDeployMode(DEPLOYMODE.MAST) 
    inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.LESS)   

    MakeLargeBurnable(inst)
    MakeLargePropagator(inst)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")    

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("mast", fn, assets, prefabs),
       Prefab("mast_item", item_fn, assets),
       MakePlacer("mast_item_placer", "mast_01", "boat_mast", "closed")
