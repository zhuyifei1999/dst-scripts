local assets =
{
    Asset("ANIM", "anim/boat_wheel.zip"),
}

local item_assets =
{
    Asset("ANIM", "anim/seafarer_wheel.zip"),
    Asset("INV_IMAGE", "steeringwheel_item")
}

local prefabs =
{
    "collapse_small",
}

local item_prefabs =
{
    "steeringwheel",
}

local function on_hammered(inst, hammerer)
    inst.components.lootdropper:DropLoot()

    local collapse_fx = SpawnPrefab("collapse_small")
    collapse_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    collapse_fx:SetMaterial("wood")

    if inst.components.steeringwheel ~= nil and inst.components.steeringwheel.sailor ~= nil then
        inst.components.steeringwheel:StopSteering(inst.components.steeringwheel.sailor)
    end

    inst:Remove()
end

local function onignite(inst)
	if inst.components.steeringwheel.sailor ~= nil then
		inst.components.steeringwheel:StopSteering(inst.components.steeringwheel.sailor)
		inst.components.steeringwheel.sailor.components.steeringwheeluser:SetSteeringWheel(nil)

		inst.components.steeringwheel.sailor:PushEvent("stop_steering_boat")
	end

	inst:RemoveComponent("steeringwheel")
end

local function onextinguish(inst)
	if not inst:HasTag("burnt") then
		inst:AddComponent("steeringwheel")
	end
end

local function onburnt(inst)
	inst:AddTag("burnt")
	if inst.components.steeringwheel ~= nil then
		inst:RemoveComponent("steeringwheel")
	end
end

local function onsave(inst, data)
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
		data.burnt = true
	end
end

local function onload(inst, data)
	if data ~= nil and data.burnt == true then
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
    --MakeObstaclePhysics(inst, .2)

    --inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("boat_wheel")
    inst.AnimState:SetBuild("boat_wheel")
    inst.AnimState:PlayAnimation("idle")    

    inst:AddTag("structure")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakeSmallBurnable(inst, nil, nil, true)
	inst.components.burnable:SetOnIgniteFn(onignite)
	inst.components.burnable:SetOnExtinguishFn(onextinguish)
	inst:ListenForEvent("onburnt", onburnt)
    MakeSmallPropagator(inst)

    -- The loot that this drops is generated from the uncraftable recipe; see recipes.lua for the items.
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnFinishCallback(on_hammered)

    inst:AddComponent("hauntable")
    inst:AddComponent("inspectable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:AddComponent("steeringwheel")

	inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

local function ondeploy(inst, pt, deployer)
    local wheel = SpawnPrefab("steeringwheel")
    if wheel ~= nil then
        wheel.Transform:SetPosition(pt:Get())
        wheel.SoundEmitter:PlaySound("turnoftides/common/together/boat/steering_wheel/place")
        wheel.AnimState:PlayAnimation("place")
        wheel.AnimState:PushAnimation("idle")

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

    inst.AnimState:SetBank("seafarer_wheel")
    inst.AnimState:SetBuild("seafarer_wheel")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", nil, 0.77)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "steeringwheel"

    inst:AddComponent("inventoryitem")

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("steeringwheel", fn, assets, prefabs),
       Prefab("steeringwheel_item", item_fn, item_assets, item_prefabs),
       MakePlacer("steeringwheel_item_placer", "boat_wheel", "boat_wheel", "idle")
