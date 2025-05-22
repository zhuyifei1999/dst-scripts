local prefabs = {
    "wagpunk_cagewall_fx",
}
local function AddPlane(triangles, x0, y0, z0, x1, y1, z1)
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
local function BuildWagpunkArenaMesh()
    local triangles = {}
    local index_total = #WAGPUNK_ARENA_COLLISION_DATA
    local v0 = WAGPUNK_ARENA_COLLISION_DATA[index_total]
    local index = 1
    for index = 1, index_total do
        local v1 = WAGPUNK_ARENA_COLLISION_DATA[index]
        local x0, z0 = v0[1], v0[2]
        local x1, z1 = v1[1], v1[2]
        AddPlane(triangles, x0, 0, z0, x1, 4, z1)

        v0 = v1
    end
    return triangles
end

local function InitFX(inst)
    local index_total = #WAGPUNK_ARENA_COLLISION_DATA
    local v0 = WAGPUNK_ARENA_COLLISION_DATA[index_total]
    local index = 1
    for index = 1, index_total do
        local v1 = WAGPUNK_ARENA_COLLISION_DATA[index]
        local x0, z0 = v0[1], v0[2]
        local x1, z1 = v1[1], v1[2]
        local dz, dx = z1 - z0, x1 - x0
        local angle = math.atan2(-dz, dx)
        local dsq = dx * dx + dz * dz
        local fx = SpawnPrefab("wagpunk_cagewall_fx")
        fx.entity:SetParent(inst.entity)
        fx.Transform:SetPosition((x0 + x1) / 2, 0, (z0 + z1) / 2)
        fx:SetBeam(math.sqrt(dsq), angle * RADIANS)
        fx.persists = false

        v0 = v1
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst.entity:AddPhysics()
    inst.Physics:SetMass(0)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:SetCollisionMask(
        COLLISION.ITEMS,
        COLLISION.CHARACTERS,
        COLLISION.GIANTS
    )
    inst.Physics:SetTriangleMesh(BuildWagpunkArenaMesh())

    inst:AddTag("NOBLOCK")
    inst:AddTag("ignorewalkableplatforms")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end
    inst.persists = false

    inst:DoTaskInTime(25 * FRAMES, InitFX)

    return inst
end

return Prefab("wagpunk_arena_collision", fn, nil, prefabs)