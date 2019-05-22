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

    if inst.components.steeringwheel.sailor ~= nil then
        inst.components.steeringwheel:StopSteering(inst.components.steeringwheel.sailor)
    end

    inst:Remove()
end

local function on_load_postpass(inst, new_entities, data)
    -- Check to see if we're placed on a boat.
    local wheelx, _, wheelz = inst.Transform:GetWorldPosition()
    local wheel_platform = TheWorld.Map:GetPlatformAtPoint(wheelx, wheelz)

    -- If we're placed on a boat, remove the ability to hammer or burn the steering wheel.
    if wheel_platform == nil or wheel_platform.components.hull == nil then
        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)

        -- The loot that this drops is generated from the uncraftable recipe; see recipes.lua for the items.
        inst:AddComponent("lootdropper")
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(3)
        inst.components.workable:SetOnFinishCallback(on_hammered)
    end
end

local function fn()

    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    --MakeObstaclePhysics(inst, .2)

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("boat_wheel")
    inst.AnimState:SetBuild("boat_wheel")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("hauntable")
    inst:AddComponent("inspectable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:AddComponent("steeringwheel")

    inst.OnLoadPostPass = on_load_postpass
    if not POPULATING then
        inst:DoTaskInTime(0, on_load_postpass)
    end

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
