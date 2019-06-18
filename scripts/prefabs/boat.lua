local assets =
{
    Asset("ANIM", "anim/boat_test.zip"),
}

local item_assets =
{
    Asset("ANIM", "anim/seafarer_boat.zip"),
    Asset("INV_IMAGE", "boat_item"),
}

local prefabs =
{
    "mast",
    "burnable_locator_medium",
    "steeringwheel",
    "rudder",
    "boatlip",
    "boat_water_fx",
    "boat_leak",
    "fx_boat_crackle",
    "boatfragment01",
    "boatfragment02",
    "boatfragment03",
    "boatfragment04",
    "boatfragment05",
    "fx_boat_pop",
    "boat_player_collision",
    "boat_item_collision",
    "walkingplank",
}

local item_prefabs =
{
    "boat",
}

local function OnRepaired(inst)    
    --inst.SoundEmitter:PlaySound("dontstarve/creatures/together/fossil/repair")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("boat.png")
    inst.entity:AddNetwork()

    inst:AddTag("ignorewalkableplatforms")

    local radius = 4
    local max_health = TUNING.BOAT.HEALTH

    local phys = inst.entity:AddPhysics()
    phys:SetMass(TUNING.BOAT.MASS)
    phys:SetFriction(0)
    phys:SetDamping(5)    
    phys:SetCollisionGroup(COLLISION.OBSTACLES)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.WORLD)    
    phys:CollidesWith(COLLISION.OBSTACLES)   
    phys:SetCylinder(radius, 0.1) 
    --Boats currently need to not go to sleep because
    --constraints will cause a crash if either the target object or the source object is removed from the physics world    
    phys:SetDontRemoveOnSleep(true)           

    inst.AnimState:SetBank("boat_01")
    inst.AnimState:SetBuild("boat_test")
    inst.AnimState:SetSortOrder(ANIM_SORT_ORDER.OCEAN_BOAT)
	inst.AnimState:SetFinalOffset(1)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)

    inst:AddComponent("walkableplatform")
    inst.components.walkableplatform.radius = radius

    inst:AddComponent("healthsyncer")
    inst.components.healthsyncer.max_health = max_health

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --inst:AddComponent("hauntable")
    --inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    --local mast = SpawnPrefab('mast')
    --mast.components.mast:SetBoat(inst)

    inst:AddComponent("hull")
    inst.components.hull:SetRadius(radius)
    inst.components.hull:SetBoatLip(SpawnPrefab('boatlip'))
    --inst.components.hull:SetRudder(SpawnPrefab('rudder'))
    --inst.components.hull:SetMast(mast)
	inst.components.hull:AttachEntityToBoat(SpawnPrefab("boat_player_collision"), 0, 0)

    local boat_item_collision = SpawnPrefab("boat_item_collision")
    boat_item_collision:AddTag("ignorewalkableplatforms")

    inst.components.hull:AttachEntityToBoat(boat_item_collision, 0, 0, true, false)

    local walking_plank = SpawnPrefab("walkingplank")
    local edge_offset = -0.05
    inst.components.hull:AttachEntityToBoat(walking_plank, 0, radius + edge_offset, false, true)
    inst.components.hull:SetPlank(walking_plank)

    inst:AddComponent("repairable")
    inst.components.repairable.repairmaterial = MATERIALS.WOOD
    inst.components.repairable.onrepaired = OnRepaired

    inst:AddComponent("hullhealth")
    inst:AddComponent("boatphysics")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(max_health)
    inst.components.health.nofadeout = true
	
	inst.activefires = 0

	local burnable_locator = SpawnPrefab('burnable_locator_medium')
	burnable_locator.boat = inst
	inst.components.hull:AttachEntityToBoat(burnable_locator, 0, 0, false, true)

	burnable_locator = SpawnPrefab('burnable_locator_medium')
	burnable_locator.boat = inst
	inst.components.hull:AttachEntityToBoat(burnable_locator, 2.5, 0, false, true)

	burnable_locator = SpawnPrefab('burnable_locator_medium')
	burnable_locator.boat = inst
	inst.components.hull:AttachEntityToBoat(burnable_locator, -2.5, 0, false, true)

	burnable_locator = SpawnPrefab('burnable_locator_medium')
	burnable_locator.boat = inst
	inst.components.hull:AttachEntityToBoat(burnable_locator, 0, 2.5, false, true)

	burnable_locator = SpawnPrefab('burnable_locator_medium')
	burnable_locator.boat = inst
	inst.components.hull:AttachEntityToBoat(burnable_locator, 0, -2.5, false, true)
	
    inst:SetStateGraph("SGboat")

    return inst
end

local function build_boat_collision_mesh(radius, height)
    local segment_count = 20
    local segment_span = math.pi * 2 / segment_count

    local triangles = {}
    local y0 = 0
    local y1 = height

    for segement_idx = 0, segment_count do

        local angle = segement_idx * segment_span
        local angle0 = angle - segment_span / 2
        local angle1 = angle + segment_span / 2

        local x0 = math.cos(angle0) * radius
        local z0 = math.sin(angle0) * radius

        local x1 = math.cos(angle1) * radius
        local z1 = math.sin(angle1) * radius
        
        table.insert(triangles, x0)
        table.insert(triangles, y0)
        table.insert(triangles, z0)

        table.insert(triangles, x0)
        table.insert(triangles, y1)
        table.insert(triangles, z0)

        table.insert(triangles, x1)
        table.insert(triangles, y0)
        table.insert(triangles, z1)

        table.insert(triangles, x1)
        table.insert(triangles, y0)
        table.insert(triangles, z1)

        table.insert(triangles, x0)
        table.insert(triangles, y1)
        table.insert(triangles, z0)

        table.insert(triangles, x1)
        table.insert(triangles, y1)
        table.insert(triangles, z1)
    end

	return triangles
end

local PLAYER_COLLISION_MESH = build_boat_collision_mesh(4.1, 3)
local ITEM_COLLISION_MESH = build_boat_collision_mesh(4.2, 3)

local function boat_player_collision_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
	inst.entity:AddNetwork()

    local phys = inst.entity:AddPhysics()
    phys:SetMass(0)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetCollisionGroup(COLLISION.LIMITS)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.CHARACTERS)
    phys:CollidesWith(COLLISION.WORLD)
    phys:SetTriangleMesh(PLAYER_COLLISION_MESH)    

    inst:AddTag("NOBLOCK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.persists = false

    return inst
end

local function boat_item_collision_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    local phys = inst.entity:AddPhysics()
    phys:SetMass(1)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetCollisionGroup(COLLISION.LIMITS)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.ITEMS)
    phys:CollidesWith(COLLISION.FLYERS)
    phys:CollidesWith(COLLISION.WORLD)
    phys:SetTriangleMesh(ITEM_COLLISION_MESH)  
    --Boats currently need to not go to sleep because
    --constraints will cause a crash if either the target object or the source object is removed from the physics world
    phys:SetDontRemoveOnSleep(true)        

    inst:AddTag("NOBLOCK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

local function ondeploy(inst, pt, deployer)
    local boat = SpawnPrefab("boat")
    if boat ~= nil then
        boat.Physics:SetCollides(false)
        boat.Physics:Teleport(pt.x, 0, pt.z)
        boat.Physics:SetCollides(true)

        boat.sg:GoToState("place")
		
		boat.components.hull:OnDeployed()

        inst:Remove()
    end
end

local function item_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("boatbuilder")

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("seafarer_boat")
    inst.AnimState:SetBuild("seafarer_boat")
    inst.AnimState:PlayAnimation("IDLE")

    MakeInventoryFloatable(inst, "med", 0.25, 0.83)

    --Deployable needs to be client side because of the custom deploy range
    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy
    inst.components.deployable:SetDeployMode(DEPLOYMODE.WATER)
    inst.components.deployable:SetDeployRange(10)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

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

return Prefab("boat", fn, assets, prefabs),
       Prefab("boat_player_collision", boat_player_collision_fn),
       Prefab("boat_item_collision", boat_item_collision_fn),
       Prefab("boat_item", item_fn, item_assets, item_prefabs),
       MakePlacer("boat_item_placer", "boat_01", "boat_test", "idle_full", true, false, false, nil, nil, nil, nil, 6)

