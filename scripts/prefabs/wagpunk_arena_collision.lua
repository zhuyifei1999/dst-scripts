local prefabs = {
    "wagpunk_cagewall_fx",
    "wagpunk_arena_collision_oneway",
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
local function ApplyOffset(value, offset)
    if value < 0 then
        value = value - offset
    elseif value > 0 then
        value = value + offset
    end
    return value
end
local function BuildWagpunkArenaMesh(offset)
    local triangles = {}
    local index_total = #WAGPUNK_ARENA_COLLISION_DATA
    local v0 = WAGPUNK_ARENA_COLLISION_DATA[index_total]
    local index = 1
    for index = 1, index_total do
        local v1 = WAGPUNK_ARENA_COLLISION_DATA[index]
        local x0, z0 = v0[1], v0[2]
        local x1, z1 = v1[1], v1[2]
        if offset then
            x0 = ApplyOffset(x0, offset)
            z0 = ApplyOffset(z0, offset)
            x1 = ApplyOffset(x1, offset)
            z1 = ApplyOffset(z1, offset)
        end
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

    --inst:DoTaskInTime(25 * FRAMES, InitFX)

    return inst
end

-----------------------------------------------------

local function TryToResolveGoodSpot(ent, map, ax, az, oneway_size)
    local x, y, z = ent.Transform:GetWorldPosition()
    local dx, dz = x - ax, z - az
    local dist = math.sqrt(dx * dx + dz * dz)
    if dist > 0 then
        dx = dx / dist
        dz = dz / dist
        local perfectdisttoinside = ent:GetPhysicsRadius(0) * 2 + oneway_size + 0.1 -- Small pad to make it not touch the other physics wall on teleporting.
        local testx, testz, disttoinside
        for distbonus = 0, 4, 2 do
            disttoinside = perfectdisttoinside + distbonus
            -- First test the NESW directions.
            testx, testz = x, z + disttoinside
            if map:IsPointInWagPunkArena(testx, 0, testz) then
                return testx, testz
            end
            testx, testz = x + disttoinside, z
            if map:IsPointInWagPunkArena(testx, 0, testz) then
                return testx, testz
            end
            testx, testz = x, z - disttoinside
            if map:IsPointInWagPunkArena(testx, 0, testz) then
                return testx, testz
            end
            testx, testz = x - disttoinside, z
            if map:IsPointInWagPunkArena(testx, 0, testz) then
                return testx, testz
            end
            -- Now the diagonals starting with NE.
            testx, testz = x + disttoinside, z + disttoinside
            if map:IsPointInWagPunkArena(testx, 0, testz) then
                return testx, testz
            end
            testx, testz = x + disttoinside, z - disttoinside
            if map:IsPointInWagPunkArena(testx, 0, testz) then
                return testx, testz
            end
            testx, testz = x - disttoinside, z - disttoinside
            if map:IsPointInWagPunkArena(testx, 0, testz) then
                return testx, testz
            end
            testx, testz = x - disttoinside, z + disttoinside
            if map:IsPointInWagPunkArena(testx, 0, testz) then
                return testx, testz
            end
        end
    end
    return nil, nil
end
local function GetIn(ent, oneway_size)
    ent.oncollide_onewaytask = nil
    local map = TheWorld.Map
    local ax, az = map:GetWagPunkArenaCenterXZ()
    if ax then
        local x, z = TryToResolveGoodSpot(ent, map, ax, az, oneway_size)
        if x then
            if ent.Physics then
                ent.Physics:Teleport(x, 0, z)
            else
                ent.Transform:SetPosition(x, 0, z)
            end
        else -- We failed to find a good spot eject at arena center.
            if ent.Physics then
                ent.Physics:Teleport(ax, 0, az)
            else
                ent.Transform:SetPosition(ax, 0, az)
            end
        end
        if ent.sg and ent.sg:HasStateTag("boathopping") then
            -- NOTES(JBK): Pushing an event here is out of order for timing with boathopping so we will handle the event directly as it has higher priority for this state.
            ent.sg:HandleEvent("cancelhop")
        end
    end
end

local function OnCollide_oneway(inst, other)
    if inst:IsValid() and other:IsValid() then
        if not other.oncollide_onewaytask then -- Get off of physics thread.
            other.oncollide_onewaytask = other:DoTaskInTime(0, GetIn, inst.oneway_size)
        end
    end
end

local function fn_oneway()
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
    inst.oneway_size = 0.4 -- A size of 0.5 can result in a corner that touches the normal tile boundary so keep it below that.
    inst.Physics:SetTriangleMesh(BuildWagpunkArenaMesh(inst.oneway_size))

    inst:AddTag("NOBLOCK")
    inst:AddTag("ignorewalkableplatforms")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end
    inst.persists = false

    inst.Physics:SetCollisionCallback(OnCollide_oneway)

    return inst
end

return Prefab("wagpunk_arena_collision", fn, nil, prefabs),
    Prefab("wagpunk_arena_collision_oneway", fn_oneway)