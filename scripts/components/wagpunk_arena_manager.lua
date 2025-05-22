local TILE_SCALE = TILE_SCALE

local MONKEYISLAND_CENTER_X = 3 * TILE_SCALE
local MONKEYISLAND_CENTER_Z = 0 * TILE_SCALE

local PEARLSETPIECE_CENTER_X = 2 * TILE_SCALE + MONKEYISLAND_CENTER_X
local PEARLSETPIECE_CENTER_Z = -4 * TILE_SCALE + MONKEYISLAND_CENTER_Z

-- NOTES(JBK): This is heavily reliant on monkeyisland_01 static layout for position and hermitcrab_01 for entities.
local PEARLSETPIECE_MONKEYISLAND = { -- x, z, rot
    ["hermitcrab_marker"] = { -- 1
        {MONKEYISLAND_CENTER_X, MONKEYISLAND_CENTER_Z, 0}, -- Place at island center this is an achievement marker for island center point.
    },
    ["hermitcrab_lure_marker"] = { -- 1
        {PEARLSETPIECE_CENTER_X - 5 * TILE_SCALE, PEARLSETPIECE_CENTER_Z + 1 * TILE_SCALE, 0}, -- Place where lureplant bulbs are created.
    },
    ["hermitcrab_marker_fishing"] = { -- 16 in coastal tiles knight's move away max from land
        {PEARLSETPIECE_CENTER_X + 2 * TILE_SCALE, PEARLSETPIECE_CENTER_Z - 3 * TILE_SCALE, 0},
        {PEARLSETPIECE_CENTER_X + 3 * TILE_SCALE, PEARLSETPIECE_CENTER_Z - 2 * TILE_SCALE, 0},
        {PEARLSETPIECE_CENTER_X + 4 * TILE_SCALE, PEARLSETPIECE_CENTER_Z - 1 * TILE_SCALE, 0},
        {PEARLSETPIECE_CENTER_X + 5 * TILE_SCALE, PEARLSETPIECE_CENTER_Z, 0},
        {PEARLSETPIECE_CENTER_X + 5 * TILE_SCALE, PEARLSETPIECE_CENTER_Z + 1 * TILE_SCALE, 0},
        {PEARLSETPIECE_CENTER_X + 5 * TILE_SCALE, PEARLSETPIECE_CENTER_Z + 2 * TILE_SCALE, 0},
        {PEARLSETPIECE_CENTER_X + 5 * TILE_SCALE, PEARLSETPIECE_CENTER_Z + 3 * TILE_SCALE, 0},
        {PEARLSETPIECE_CENTER_X + 5 * TILE_SCALE, PEARLSETPIECE_CENTER_Z + 4 * TILE_SCALE, 0},
        {PEARLSETPIECE_CENTER_X - 6 * TILE_SCALE, PEARLSETPIECE_CENTER_Z - 3 * TILE_SCALE, 0},
        {PEARLSETPIECE_CENTER_X - 7 * TILE_SCALE, PEARLSETPIECE_CENTER_Z - 2 * TILE_SCALE, 0},
        {PEARLSETPIECE_CENTER_X - 8 * TILE_SCALE, PEARLSETPIECE_CENTER_Z - 1 * TILE_SCALE, 0},
        {PEARLSETPIECE_CENTER_X - 9 * TILE_SCALE, PEARLSETPIECE_CENTER_Z, 0},
        {PEARLSETPIECE_CENTER_X - 9 * TILE_SCALE, PEARLSETPIECE_CENTER_Z + 1 * TILE_SCALE, 0},
        {PEARLSETPIECE_CENTER_X - 9 * TILE_SCALE, PEARLSETPIECE_CENTER_Z + 2 * TILE_SCALE, 0},
        {PEARLSETPIECE_CENTER_X - 9 * TILE_SCALE, PEARLSETPIECE_CENTER_Z + 3 * TILE_SCALE, 0},
        {PEARLSETPIECE_CENTER_X - 9 * TILE_SCALE, PEARLSETPIECE_CENTER_Z + 4 * TILE_SCALE, 0},
    },
    ["hermithouse"] = { -- 1
        {PEARLSETPIECE_CENTER_X, PEARLSETPIECE_CENTER_Z, 0}, -- Center of arena is on a tile corner.
    },
    ["hermithouse_construction1"] = { -- 1
        {PEARLSETPIECE_CENTER_X, PEARLSETPIECE_CENTER_Z, 0}, -- Center of arena is on a tile corner.
    },
    ["hermithouse_construction2"] = { -- 1
        {PEARLSETPIECE_CENTER_X, PEARLSETPIECE_CENTER_Z, 0}, -- Center of arena is on a tile corner.
    },
    ["hermithouse_construction3"] = { -- 1
        {PEARLSETPIECE_CENTER_X, PEARLSETPIECE_CENTER_Z, 0}, -- Center of arena is on a tile corner.
    },
    ["hermitcrab"] = { -- 1 or 0
        {PEARLSETPIECE_CENTER_X + 2.5, PEARLSETPIECE_CENTER_Z, 0},
    },
    ["meatrack_hermit"] = { -- 6
        {PEARLSETPIECE_CENTER_X + 4.4, PEARLSETPIECE_CENTER_Z + 7.3, 0},
        {PEARLSETPIECE_CENTER_X + 7.6, PEARLSETPIECE_CENTER_Z + 4.1, 0},
        {PEARLSETPIECE_CENTER_X + 8.4, PEARLSETPIECE_CENTER_Z + 0.3, 0},
        {PEARLSETPIECE_CENTER_X + 9.3, PEARLSETPIECE_CENTER_Z + 7.7, 0},
        {PEARLSETPIECE_CENTER_X + 11.9, PEARLSETPIECE_CENTER_Z + 2.6, 0},
        {PEARLSETPIECE_CENTER_X + 13.1, PEARLSETPIECE_CENTER_Z + 6.8, 0},
    },
    ["beebox_hermit"] = { -- 1
        {PEARLSETPIECE_CENTER_X - 4 * TILE_SCALE - 2.3, PEARLSETPIECE_CENTER_Z + 2.3, 0},
    },
}

-- NOTES(JBK): This is heavily reliant on hermitcrab_01 static layout.
local TILESPOTS = { -- x, z, rot
    {-10,  -1, 0  },
    {-10,  -2, 270},
    {-10,  -3, 180},
    {-10,  -4, 270},
    {-10,  -5, 180},
    {-10,  -6, 270},
    {-10,  -7, 90 },
    {-10,  -8, 180},
    {-10,  -9, 90 },
    {-10, -10, 180},
    { -9,   0, 0  },
    { -9,  -6, 180},
    { -9,  -7, 270},
    { -9,  -8, 180},
    { -9, -11, 90 },
    { -8,   1, 0  },
    { -8,   0, 270},
    { -8, -12, 90 },
    { -7,   1, 270},
    { -6,   1, 90 },
    { -3,  -3, 270},
    { -3,  -4, 0  },
    { -3,  -5, 180},
    { -3, -12, 270},
    { -2,  -2, 0  },
    { -2,  -3, 180},
    { -2,  -4, 270},
    { -2,  -5, 90 },
    { -2,  -6, 180},
    { -2, -11, 0  },
    { -2, -12, 180},
    { -1,  -2, 270},
    { -1,  -3, 90 },
    { -1,  -4, 0  },
    { -1,  -5, 180},
    { -1,  -6, 270},
    { -1,  -7, 90 },
    { -1,  -8, 180},
    { -1,  -9, 0  },
    { -1, -10,  90},
    { -1, -11, 270},
    { -1, -12, 90 },
    {  0,  -2, 0  },
    {  0,  -3, 90 },
    {  0,  -4, 180},
    {  0,  -5, 90 },
    {  0,  -6, 270},
    {  0,  -7, 180},
    {  0,  -8, 0  },
    {  0,  -9, 180},
    {  0, -10, 0  },
    {  0, -11, 90 },
    {  0, -12, 270},
    {  1,   1, 0  },
    {  1,  -3, 270},
    {  1,  -4, 90 },
    {  1,  -5,   0},
    {  1,  -6, 180},
    {  1,  -7, 0  },
    {  1,  -8, 180},
    {  1,  -9, 270},
    {  1, -10, 0  },
    {  1, -11, 180},
    {  1, -12, 90 },
    {  2,  -5, 180},
    {  2,  -6, 270},
    {  2,  -7, 180},
    {  2,  -8, 270},
    {  2,  -9, 0  },
    {  2, -10, 90 },
    {  2, -11, 0  },
    {  3,  -6, 90 },
    {  3,  -7, 270},
    {  3,  -8, 180},
    {  3,  -9, 270},
    {  3, -10, 0  },
}

local STATES = {
    SPARKARK = 0, -- Waiting for Wagstaff to have given a Spark Ark.
    PEARLMAP = 1, -- Waiting for Pearl to get a map to leave the island.
    PEARLMOVE = 2, -- Waiting for Pearl to finish moving.
    TURF = 3, -- Waiting for the player to place the floor.
    CONSTRUCT = 4, -- Waiting for the player to place arena parts.
    LEVER = 5, -- Waiting for the lever switch.
    BOSS = 6, -- Waiting for boss defeat.
    BOSSCOOLDOWN = 7, -- Boss defeated and will not return until it is over.
}

local ARENA_CENTER_X = -3.5 * TILE_SCALE
local ARENA_CENTER_Z = -5.5 * TILE_SCALE

local WAGSTAFF_CENTER_X = -3 * TILE_SCALE + ARENA_CENTER_X
local WAGSTAFF_CENTER_Z = -5.5 * TILE_SCALE + ARENA_CENTER_Z

local ARENA_ENTITIES = {
    ["wagpunk_floor_marker"] = { -- Only one.
        {ARENA_CENTER_X, ARENA_CENTER_Z, 0}, -- Center of arena is on a tile corner.
    },
    ["wagpunk_lever"] = { -- Only one.
        {ARENA_CENTER_X, -1.5 * TILE_SCALE + ARENA_CENTER_Z, 0},
    },
    ["wagpunk_workstation"] = { -- Only one.
        {WAGSTAFF_CENTER_X, WAGSTAFF_CENTER_Z, 0},
    },
    ["junk_pile"] = {
        {-1.5 * TILE_SCALE + WAGSTAFF_CENTER_X, 1.0 * TILE_SCALE + WAGSTAFF_CENTER_Z, 0},
        {-1.0 * TILE_SCALE + WAGSTAFF_CENTER_X, -0.5 * TILE_SCALE + WAGSTAFF_CENTER_Z, 0},
        {1.5 * TILE_SCALE + WAGSTAFF_CENTER_X, -0.75 * TILE_SCALE + WAGSTAFF_CENTER_Z, 0},
        {1.25 * TILE_SCALE + WAGSTAFF_CENTER_X, 1.0 * TILE_SCALE + WAGSTAFF_CENTER_Z, 0},
    },
    ["fence_junk"] = {
        {-7.5 + WAGSTAFF_CENTER_X, 7.5 + WAGSTAFF_CENTER_Z, 270},
        {-6.5 + WAGSTAFF_CENTER_X, 7.5 + WAGSTAFF_CENTER_Z, 270},
        {-5.5 + WAGSTAFF_CENTER_X, 7.5 + WAGSTAFF_CENTER_Z, 270},
        {-4.5 + WAGSTAFF_CENTER_X, 7.5 + WAGSTAFF_CENTER_Z, 270},
        {-3.5 + WAGSTAFF_CENTER_X, 7.5 + WAGSTAFF_CENTER_Z, 270},
        {-2.5 + WAGSTAFF_CENTER_X, 7.5 + WAGSTAFF_CENTER_Z, 270},
        {-1.5 + WAGSTAFF_CENTER_X, 6.5 + WAGSTAFF_CENTER_Z, 270},
        {-0.5 + WAGSTAFF_CENTER_X, 6.5 + WAGSTAFF_CENTER_Z, 270},
        {0.5 + WAGSTAFF_CENTER_X, 6.5 + WAGSTAFF_CENTER_Z, 270},
        {1.5 + WAGSTAFF_CENTER_X, 6.5 + WAGSTAFF_CENTER_Z, 270},
        {2.5 + WAGSTAFF_CENTER_X, 6.5 + WAGSTAFF_CENTER_Z, 270},
        {3.5 + WAGSTAFF_CENTER_X, 6.5 + WAGSTAFF_CENTER_Z, 270},
        {4.5 + WAGSTAFF_CENTER_X, 6.5 + WAGSTAFF_CENTER_Z, 270},
        {5.5 + WAGSTAFF_CENTER_X, 6.5 + WAGSTAFF_CENTER_Z, 270},
        {6.5 + WAGSTAFF_CENTER_X, 5.5 + WAGSTAFF_CENTER_Z, 315},
        {7.5 + WAGSTAFF_CENTER_X, 4.5 + WAGSTAFF_CENTER_Z, 0},
        {7.5 + WAGSTAFF_CENTER_X, 3.5 + WAGSTAFF_CENTER_Z, 0},
        {7.5 + WAGSTAFF_CENTER_X, 2.5 + WAGSTAFF_CENTER_Z, 0},
        {7.5 + WAGSTAFF_CENTER_X, 1.5 + WAGSTAFF_CENTER_Z, 0},
        {7.5 + WAGSTAFF_CENTER_X, 0.5 + WAGSTAFF_CENTER_Z, 0},
    },
    ["wagpunk_floor_placerindicator"] = {},
    ["wagdrone_spot_marker"] = { -- 6.
        {-3.0 * TILE_SCALE + ARENA_CENTER_X, -1.0 * TILE_SCALE + ARENA_CENTER_Z, 0},
        {-2.5 * TILE_SCALE + ARENA_CENTER_X, 2.0 * TILE_SCALE + ARENA_CENTER_Z, 0},
        {-1.0 * TILE_SCALE + ARENA_CENTER_X, -2.0 * TILE_SCALE + ARENA_CENTER_Z, 0},
        {1.0 * TILE_SCALE + ARENA_CENTER_X, 2.5 * TILE_SCALE + ARENA_CENTER_Z, 0},
        {1.5 * TILE_SCALE + ARENA_CENTER_X, -1.5 * TILE_SCALE + ARENA_CENTER_Z, 0},
        {3.0 * TILE_SCALE + ARENA_CENTER_X, 0.5 * TILE_SCALE + ARENA_CENTER_Z, 0},
    },
    ["wagboss_robot"] = { -- Only one.
        {ARENA_CENTER_X, ARENA_CENTER_Z, 0},
    },
}
for i, v in ipairs(TILESPOTS) do
    ARENA_ENTITIES["wagpunk_floor_placerindicator"][i] = {v[1] * TILE_SCALE, v[2] * TILE_SCALE, v[3]}
end

--------------------------------------------------------------------------
--[[ wagpunk_arena_manager class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

local _world = TheWorld
assert(_world.ismastersim, "Wagpunk Arena Manager should not exist on the client!")
local _map = _world.Map
local WAGSTAFF_FLOOR = WORLD_TILES.WAGSTAFF_FLOOR

self.inst = inst
self.TILESPOTS = TILESPOTS
self.WALLSPOTS = WAGPUNK_ARENA_COLLISION_DATA
self.ARENA_ENTITIES = ARENA_ENTITIES
self.PEARLSETPIECE_MONKEYISLAND = PEARLSETPIECE_MONKEYISLAND
self.STATES = STATES

self.pearlsentities = {}
self.arenaentities = {}
self.arenaprefabcounts = {}

local function CheckStateForChanges_Bridge(inst)
    self.checktask = nil
    if not self.appliedrotationtransformation then
        if not self.failed then
            -- Reschedule a check later to let this finish loading.
            self.checktask = self.inst:DoTaskInTime(0, CheckStateForChanges_Bridge)
        end
        return
    end
    self:CheckStateForChanges()
end
function self:QueueCheck()
    if not self.checktask then
        self.checktask = self.inst:DoTaskInTime(0, CheckStateForChanges_Bridge)
    end
end

function self:GetStateString()
    if self.state == nil then
        return "SPARKARK"
    end

    for statename, stateid in pairs(self.STATES) do
        if self.state == stateid then
            return statename
        end
    end

    return "SPARKARK"
end

function self:ApplyRotationTransformation_Pearl(data)
    -- NOTES(JBK): This mapping is from the layout of hermitcrab_01 where the angle between the hermitcrab_marker and beebox_hermit is known from setpiece placement.
    -- The static layout default angle is 56.973 degrees.
    local angle = self.storedangle_pearl
    if angle > 0 then
        if angle < 45 then
            --print("Flip diagonal bottomleft to topright")
            for _, v in ipairs(data) do
                v[1], v[2], v[3] = v[2], v[1], 270 - v[3]
            end
        elseif angle < 90 then
            --print("No rotation")
        elseif angle < 135 then
            --print("Flip X")
            for _, v in ipairs(data) do
                v[1], v[2], v[3] = -v[1], v[2], 180 - v[3]
            end
        else -- angle < 180
            --print("Rotate 90 left")
            for _, v in ipairs(data) do
                v[1], v[2], v[3] = -v[2], v[1], v[3] - 90
            end
        end
    else
        if angle > -45 then
            --print("Rotate 90 right")
            for _, v in ipairs(data) do
                v[1], v[2], v[3] = v[2], -v[1], v[3] + 90
            end
        elseif angle > -90 then
            --print("Flip Y")
            for _, v in ipairs(data) do
                v[1], v[2], v[3] = v[1], -v[2], -v[3]
            end
        elseif angle > -135 then
            --print("Rotate 180 or flip X + Y")
            for _, v in ipairs(data) do
                v[1], v[2], v[3] = -v[1], -v[2], 180 + v[3]
            end
        else -- angle > -180
            --print("Flip diagonal topleft to downright")
            for _, v in ipairs(data) do
                v[1], v[2], v[3] = -v[2], -v[1], 90 - v[3]
            end
        end
    end
end
function self:ApplyRotationTransformation_Monkey(data)
    -- NOTES(JBK): This mapping is from the layout of monkeyisland_01 where the angle between the monkeyqueen and monkeyisland_portal is known from setpiece placement.
    -- The static layout default angle is -132.31622 degrees.
    local angle = self.storedangle_monkey
    if angle > 0 then
        if angle < 45 then
            --print("Flip diagonal topleft to downright")
            for _, v in ipairs(data) do
                v[1], v[2], v[3] = -v[2], -v[1], 90 - v[3]
            end
        elseif angle < 90 then
            --print("Rotate 180 or flip X + Y")
            for _, v in ipairs(data) do
                v[1], v[2], v[3] = -v[1], -v[2], 180 + v[3]
            end
        elseif angle < 135 then
            --print("Flip Y")
            for _, v in ipairs(data) do
                v[1], v[2], v[3] = v[1], -v[2], -v[3]
            end
        else -- angle < 180
            --print("Rotate 90 right")
            for _, v in ipairs(data) do
                v[1], v[2], v[3] = v[2], -v[1], v[3] + 90
            end
        end
    else
        if angle > -45 then
            --print("Rotate 90 left")
            for _, v in ipairs(data) do
                v[1], v[2], v[3] = -v[2], v[1], v[3] - 90
            end
        elseif angle > -90 then
            --print("Flip X")
            for _, v in ipairs(data) do
                v[1], v[2], v[3] = -v[1], v[2], 180 - v[3]
            end
        elseif angle > -135 then
            --print("No rotation")
        else -- angle > -180
            --print("Flip diagonal bottomleft to topright")
            for _, v in ipairs(data) do
                v[1], v[2], v[3] = v[2], v[1], 270 - v[3]
            end
        end
    end
end

function self:ClearReferencesForRotationTransformation()
    if self.hermitcrab_marker then
        self.hermitcrab_marker:RemoveEventCallback("onremove", self.OnRemove_HermitCrabMarker)
        self.hermitcrab_marker = nil
    end
    if self.beebox_hermit then
        self.beebox_hermit:RemoveEventCallback("onremove", self.OnRemove_BeeBoxHermit)
        self.beebox_hermit = nil
    end
    if self.monkeyportal then
        self.monkeyportal:RemoveEventCallback("onremove", self.OnRemove_MonkeyPortal)
        self.monkeyportal = nil
    end
    if self.monkeyqueen then
        self.monkeyqueen:RemoveEventCallback("onremove", self.OnRemove_MonkeyQueen)
        self.monkeyqueen = nil
    end
end
function self:ApplyAllRotationTransformations()
    self.appliedrotationtransformation = true
    self:ApplyRotationTransformation_Pearl(self.TILESPOTS)
    self:ApplyRotationTransformation_Pearl(self.WALLSPOTS)
    for prefab, transformdata in pairs(self.ARENA_ENTITIES) do
        self:ApplyRotationTransformation_Pearl(transformdata)
    end
    for prefab, transformdata in pairs(self.PEARLSETPIECE_MONKEYISLAND) do
        self:ApplyRotationTransformation_Monkey(transformdata)
    end
    self:ClearReferencesForRotationTransformation()
end
function self:TryToApplyRotationTransformation()
    if self.failed then
        self:ClearReferencesForRotationTransformation()
        if BRANCH == "staging" then
            c_announce("This world has too many important entities for wagpunk_arena_manager please upload the world to the bug tracker.")
        end
        return false
    end
    if self.appliedrotationtransformation then
        return true
    end

    if self.storedangle_pearl and self.storedangle_monkey then
        self:ApplyAllRotationTransformations()
        return true
    end

    if not self.storedangle_pearl and (not self.hermitcrab_marker or not self.beebox_hermit) then
        print("ERROR: wagpunk_arena_manager expected to be able to calculate the set piece angle using hermitcrab_marker and beebox_hermit but found neither of these.")
        if BRANCH == "staging" then
            c_announce("This world is missing important entities for wagpunk_arena_manager please upload the world to the bug tracker.")
        end
        return false
    end

    if not self.storedangle_monkey and (not self.monkeyqueen or not self.monkeyportal) then
        print("ERROR: wagpunk_arena_manager expected to be able to calculate the set piece angle using monkeyqueen and monkeyportal but found neither of these.")
        if BRANCH == "staging" then
            c_announce("This world is missing important entities for wagpunk_arena_manager please upload the world to the bug tracker.")
        end
        return false
    end

    if not self.storedangle_pearl then
        local x1, y1, z1 = self.hermitcrab_marker.Transform:GetWorldPosition()
        local x2, y2, z2 = self.beebox_hermit.Transform:GetWorldPosition()
        local tx, ty, tz = TheWorld.Map:GetTileCenterPoint(x2, y2, z2) -- Must use beebox origin because its spawn is not on a tile boundary.
        self.storedx_pearl, self.storedz_pearl = tx, tz
        self.storedangle_pearl = math.atan2(z2 - z1, x2 - x1) * RADIANS
    end

    if not self.storedangle_monkey then
        local x1, y1, z1 = self.monkeyqueen.Transform:GetWorldPosition()
        local x2, y2, z2 = self.monkeyportal.Transform:GetWorldPosition() -- Is in a good spot away from tile boundaries.
        local tx, ty, tz = TheWorld.Map:GetTileCenterPoint(x2, y2, z2)
        self.storedx_monkey, self.storedz_monkey = tx, tz
        self.storedangle_monkey = math.atan2(z2 - z1, x2 - x1) * RADIANS
    end

    self:ApplyAllRotationTransformations()
    return true
end

self.OnRemove_CageWall = function(cagewall, data)
    self.cagewalls[cagewall] = nil
end
function self:TrackCageWall(cagewall)
    self.cagewalls[cagewall] = true
    cagewall:ListenForEvent("onremove", self.OnRemove_CageWall)
end
function self:SpawnCageWalls()
    if self.cagewalls then
        return
    end

    self.cagewalls = {}
    for _, v in ipairs(self.WALLSPOTS) do
        local x, z, rot = self.storedx_pearl + v[1], self.storedz_pearl + v[2], math.floor(v[3] / 90) * 90
        local cagewall = SpawnPrefab("wagpunk_cagewall")
        cagewall.Transform:SetPosition(x, 0, z)
        cagewall.Transform:SetRotation(rot)
        self:TrackCageWall(cagewall)
    end
end


self.OnRemove_Lever = function(lever, data)
    self.lever = nil
end
function self:TrackLever(lever)
    self.lever = lever
    lever:ListenForEvent("onremove", self.OnRemove_Lever)
end

self.OnRemove_Workstation = function(workstation, data)
    self.workstation = nil
end
function self:TrackWorkstation(workstation)
    self.workstation = workstation
    workstation:ListenForEvent("onremove", self.OnRemove_Workstation)
end

self.OnDeath_Wagboss = function(wagboss, data)
    self:BossCompleted()
end
self.OnRemove_Wagboss = function(wagboss, data)
    self.wagboss = nil
end
function self:TrackWagboss(wagboss)
    self.wagboss = wagboss
    wagboss:ListenForEvent("onremove", self.OnRemove_Wagboss)
    wagboss:ListenForEvent("death", self.OnDeath_Wagboss)
end

self.validspotfn_clearthisarea = function(x, z, r)
    ClearSpotForRequiredPrefabAtXZ(x, z, r)
    return true
end
self.validspotfn_junk_pile = function(x, z, r)
    return not _map:IsOceanAtPoint(x, 0, z, false) and TheSim:CountEntities(x, 0, z, r) == 0
end
self.validspotfn_fence_junk = function(x, z, r)
    return not _map:IsOceanAtPoint(x, 0, z, false) and TheSim:CountEntities(x, 0, z, r) == 0
end
self.postinitfn_fence_junk = function(ent)
    ent:SetOrientation(ent.Transform:GetRotation()) -- Fixup fence rotation animations.
end

function self:SpawnWagstaffSetPiece()
    local levers = self:TryToSpawnArenaEntities("wagpunk_lever", self.validspotfn_clearthisarea)
    if levers then
        self:TrackLever(levers[1])
    end
    local workstations = self:TryToSpawnArenaEntities("wagpunk_workstation", self.validspotfn_clearthisarea)
    if workstations then
        self:TrackWorkstation(workstations[1])
    end
    self:TryToSpawnArenaEntities("junk_pile", self.validspotfn_junk_pile)
    self:TryToSpawnArenaEntities("fence_junk", self.validspotfn_fence_junk, self.postinitfn_fence_junk) -- Always last.
end

self.OnRemove_ArenaEntity = function(ent, data)
    self.arenaentities[ent] = nil
    local count = self.arenaprefabcounts[ent.prefab] or 0
    count = count - 1
    if count <= 0 then
        self.arenaprefabcounts[ent.prefab] = nil
    else
        self.arenaprefabcounts[ent.prefab] = count
    end
end
function self:TrackArenaEntity(ent)
    self.arenaentities[ent] = true
    local count = self.arenaprefabcounts[ent.prefab] or 0
    count = count + 1
    self.arenaprefabcounts[ent.prefab] = count
    ent:ListenForEvent("onremove", self.OnRemove_ArenaEntity)
end

function self:HasArenaEntity(prefab)
    return self.arenaprefabcounts[prefab] ~= nil
end

function self:TryToSpawnArenaEntities(prefab, validspotfn, postinitfn)
    local ents
    if not self:HasArenaEntity(prefab) then
        for _, v in ipairs(self.ARENA_ENTITIES[prefab]) do
            local x, z, rot = self.storedx_pearl + v[1], self.storedz_pearl + v[2], v[3]
            local ent = SpawnPrefab(prefab)
            if validspotfn == nil or validspotfn(x, z, ent:GetPhysicsRadius(0)) then
                ent.Transform:SetPosition(x, 0, z)
                ent.Transform:SetRotation(rot)
                if postinitfn then
                    postinitfn(ent)
                end
                self:TrackArenaEntity(ent)
                if ents then
                    table.insert(ents, ent)
                else
                    ents = {ent}
                end
            else
                ent:Remove()
            end
        end
    end
    return ents
end

function self:RemoveArenaEntities(prefab)
    for ent, _ in pairs(self.arenaentities) do
        if ent.prefab == prefab then
            ent:Remove()
        end
    end
end

function self:GetArenaSocketingInstFor(inst, item)
    if (item.prefab == "gestalt_cage_filled1" or item.prefab == "gestalt_cage_filled2") then
        if self:HasArenaEntity("wagdrone_spot_marker") then
            local closestent
            local smallestdsq = math.huge
            for ent, _ in pairs(self.arenaentities) do
                if ent.prefab == "wagdrone_spot_marker" then
                    local dsq = inst:GetDistanceSqToInst(ent)
                    if dsq < smallestdsq then
                        smallestdsq = dsq
                        closestent = ent
                    end
                end
            end
            return closestent
        end
    elseif item.prefab == "gestalt_cage_filled3" then
        if self.wagboss and not self.wagboss:IsSocketed() then
            return self.wagboss
        end
    end

    return nil
end

function self:TeleportWagstaffToWorkstation()
    local x, y, z = self.workstation.Transform:GetWorldPosition()
    local theta = math.random() * TWOPI
    local radius = self.workstation:GetPhysicsRadius(0) + self.wagstaff:GetPhysicsRadius(0) + 0.5
    local x2, z2 = x + math.cos(theta) * radius, z + math.sin(theta) * radius
    self.wagstaff.Transform:SetPosition(x2, y, z2)
    self.wagstaff:ForceFacePoint(x, y, z)
end
local function WorkstationToggled_Bridge(workstation, state)
    self:WorkstationToggled(state)
end
function self:WorkstationToggled(on) -- Caller assumed to be from self.workstation only.
    if self.workstationtoggledtask then
        self.workstationtoggledtask:Cancel()
        self.workstationtoggledtask = nil
    end

    local wagboss_tracker = TheWorld.components.wagboss_tracker
    if wagboss_tracker and wagboss_tracker:IsWagbossDefeated() then
        return -- No need to do anything here.
    end

    if on then
        self.workstationtoggledtask = self.workstation:DoTaskInTime(0.1, WorkstationToggled_Bridge, on) -- Always reschedule to handle Wagstaff state changes when next to the station.
        local wagstaff
        if self.state == self.STATES.SPARKARK then
            -- A player has activated a workstation before the questline is good for it.
            -- Do nothing but still reschedule in case the questline does advance.
        elseif self.state == self.STATES.PEARLMAP then
            -- Wagstaff wants Pearl off of the Island.
            wagstaff = self:TryToSpawnWagstaff()
            if wagstaff then
                wagstaff.arena_state = self.state
                wagstaff.tiedtoworkstation = true
                self:TeleportWagstaffToWorkstation()
                wagstaff.components.npc_talker:Chatter("WAGSTAFF_WAGPUNK_ARENA_PEARLMAP")
            end
        elseif self.state == self.STATES.PEARLMOVE then
            -- Waiting for Pearl finish moving.
            wagstaff = self:TryToSpawnWagstaff()
            if wagstaff then
                wagstaff.arena_state = self.state
                wagstaff.tiedtoworkstation = true
                self:TeleportWagstaffToWorkstation()
            elseif self.wagstaff and not self.wagstaff.erodingout and self.wagstaff.arena_state ~= self.STATES.PEARLMOVE then
                self.wagstaff.arena_state = self.state
                self.wagstaff.components.npc_talker:resetqueue()
                self.wagstaff.components.talker:ShutUp()
            end
        elseif self.state == self.STATES.TURF then
            -- Wagstaff wants the turf to be placed down to build up a good spot.
            wagstaff = self:TryToSpawnWagstaff()
            if wagstaff then
                wagstaff.arena_state = self.state
                wagstaff.tiedtoworkstation = true
                self:TeleportWagstaffToWorkstation()
                wagstaff.components.npc_talker:Chatter("WAGSTAFF_WAGPUNK_ARENA_TURF")
            elseif self.wagstaff and not self.wagstaff.erodingout and self.wagstaff.arena_state ~= self.STATES.TURF then
                self.wagstaff.arena_state = self.state
                self.wagstaff.components.npc_talker:resetqueue()
                self.wagstaff.components.talker:ShutUp()
                self.wagstaff.components.npc_talker:Chatter("WAGSTAFF_WAGPUNK_ARENA_TURF")
            end
        elseif self.state == self.STATES.CONSTRUCT then
            -- Wagstaff wants robots to be placed at set locations in the arena.
            wagstaff = self:TryToSpawnWagstaff()
            if wagstaff then
                wagstaff.arena_state = self.state
                self:TeleportWagstaffToWorkstation()
                wagstaff.components.npc_talker:Chatter("WAGSTAFF_WAGPUNK_ARENA_CONSTRUCT")
            elseif self.wagstaff and not self.wagstaff.erodingout and self.wagstaff.arena_state ~= self.STATES.CONSTRUCT then
                self.wagstaff.tiedtoworkstation = nil
                self.wagstaff.arena_state = self.state
                self.wagstaff.components.npc_talker:resetqueue()
                self.wagstaff.components.talker:ShutUp()
                self.wagstaff.components.npc_talker:Chatter("WAGSTAFF_WAGPUNK_ARENA_CONSTRUCT")
            end
        elseif self.state == self.STATES.LEVER then
            -- Wagstaff wants the lever to be thrown.
            wagstaff = self:TryToSpawnWagstaff()
            if wagstaff then
                wagstaff.arena_state = self.state
                wagstaff.tiedtoworkstation = true
                self:TeleportWagstaffToWorkstation()
                wagstaff.components.npc_talker:Chatter("WAGSTAFF_WAGPUNK_ARENA_LEVER")
            elseif self.wagstaff and not self.wagstaff.erodingout and self.wagstaff.arena_state ~= self.STATES.LEVER then
                if self.workstation and not self.wagstaff:IsNear(self.workstation, 8) then
                    self:TeleportWagstaffToWorkstation()
                end
                self.wagstaff.tiedtoworkstation = true
                self.wagstaff.arena_state = self.state
                self.wagstaff.components.npc_talker:resetqueue()
                self.wagstaff.components.talker:ShutUp()
                self.wagstaff.components.npc_talker:Chatter("WAGSTAFF_WAGPUNK_ARENA_LEVER")
            end
        elseif self.state == self.STATES.BOSS then
            if self.wagstaff then
                self.wagstaff:DoFadeOutIn(0)
            end
        elseif self.state == self.STATES.BOSSCOOLDOWN then
            if self.wagstaff then
                self.wagstaff:DoFadeOutIn(0)
            end
        end
    else
        if self.wagstaff then
            if self.wagstaff.tiedtoworkstation then
                self.wagstaff:DoFadeOutIn(0)
            elseif self.wagstaff.arena_state ~= self.STATES.LEVER and self.state == self.STATES.LEVER then
                self.wagstaff:DoFadeOutIn(0)
            end
        end
    end

    if self.wagstaff and not self.wagstaff.tiedtoworkstation then
        if not self.wagstaff.avoid_erodeout then
            local distsq = self.wagstaff:GetDistanceSqToClosestPlayer(true)
            if distsq > 256 then -- (4 * TILE_SCALE) ^ 2
                self.wagstaff:DoFadeOutIn(0)
            end
        end
        if self.wagstaff and not self.wagstaff.erodingout and not self.workstationtoggledtask then
            self.workstationtoggledtask = self.workstation:DoTaskInTime(0.1, WorkstationToggled_Bridge, on)
        end
    end
end

self.OnRemove_Wagstaff = function(wagstaff, data)
    self.wagstaff = nil
end
function self:TrackWagstaff(wagstaff)
    self.wagstaff = wagstaff
    wagstaff:ListenForEvent("onremove", self.OnRemove_Wagstaff)
end
function self:TryToSpawnWagstaff()
    if self.wagstaff then
        return nil -- One already is around, reschedule.
    end

    local wagboss_tracker = TheWorld.components.wagboss_tracker
    if wagboss_tracker and wagboss_tracker:IsWagbossDefeated() then
        return nil -- Nope!
    end

    local wagstaff = SpawnPrefab("wagstaff_npc_wagpunk_arena")
    self:TrackWagstaff(wagstaff)
    wagstaff.sg:GoToState("idle", "idle_loop")
    return wagstaff
end

local TELEPORT_TIME_FX_SYNC = 12 * FRAMES
function self:OnFinishedTeleportPearlEntity(ent, deleted)
    if not deleted then
        ent:RemoveEventCallback("onremove", self.OnRemove_TeleportingPearlEntity)
        if ent.prefab == "hermitcrab" then
            ent.sg.mem.teleporting = nil
        end
        ent:PushEvent("teleported")
    end
    self.pearlmovingcount = self.pearlmovingcount - 1
    if self.pearlmovingcount <= 0 then
        self:PearlMoveCompleted()
    end
end
self.OnRemove_TeleportingPearlEntity = function(ent, data)
    self:OnFinishedTeleportPearlEntity(ent, true)
end
self.TeleportPearlEntityToMonkeyIsland_Arrive = function(ent)
    ent:ReturnToScene()
    self:OnFinishedTeleportPearlEntity(ent)
end
self.TeleportPearlEntityToMonkeyIsland_Appear = function(ent, x, z, rot, fxprefab, delay)
    if fxprefab and not ent:IsAsleep() then
        local fx = SpawnPrefab(fxprefab)
        fx.Transform:SetPosition(x, 0, z)
        ent:DoTaskInTime(TELEPORT_TIME_FX_SYNC, self.TeleportPearlEntityToMonkeyIsland_Arrive)
    else
        self.TeleportPearlEntityToMonkeyIsland_Arrive(ent)
    end
end
self.TeleportPearlEntityToMonkeyIsland_Teleport = function(ent, x, z, rot, fxprefab, delay)
    local radius = ent:GetPhysicsRadius(0)
    ent:RemoveFromScene()
    if fxprefab then -- We have visuals for everything that is mandatory to move.
        self.validspotfn_clearthisarea(x, z, radius)
    end
    ent.Transform:SetPosition(x, 0, z)
    ent.Transform:SetRotation(rot)
    if fxprefab and not ent:IsAsleep() then
        ent:DoTaskInTime(delay, self.TeleportPearlEntityToMonkeyIsland_Appear, x, z, rot, fxprefab, delay)
    else
        self.TeleportPearlEntityToMonkeyIsland_Arrive(ent)
    end
end
self.TeleportPearlEntityToMonkeyIsland_Disappear = function(ent, x, z, rot, fxprefab, delay)
    if fxprefab and not ent:IsAsleep() then
        local ex, ey, ez = ent.Transform:GetWorldPosition()
        local fx = SpawnPrefab(fxprefab)
        fx.Transform:SetPosition(ex, ey, ez)
        ent:DoTaskInTime(TELEPORT_TIME_FX_SYNC, self.TeleportPearlEntityToMonkeyIsland_Teleport, x, z, rot, fxprefab, delay)
    else
        self.TeleportPearlEntityToMonkeyIsland_Teleport(ent, x, z, rot, fxprefab, delay)
    end
end
function self:TeleportPearlEntityToMonkeyIsland(prefab, fxprefab)
    local index = 1
    for ent, _ in pairs(self.pearlsentities) do
        if ent.prefab == prefab then
            if ent.prefab == "hermitcrab" then
                ent.sg.mem.teleporting = true
                ent.sg:GoToState("dancebusy")
            end
            local v = self.PEARLSETPIECE_MONKEYISLAND[prefab][index]
            if v then
                self.pearlmovingcount = self.pearlmovingcount + 1
                ent:ListenForEvent("onremove", self.OnRemove_TeleportingPearlEntity)
                local x, z, rot = self.storedx_monkey + v[1], self.storedz_monkey + v[2], v[3]
                local delay = self.pearlmovingcount * 0.25 + math.random() * 0.25
                if fxprefab and not ent:IsAsleep() then
                    ent:DoTaskInTime(delay, self.TeleportPearlEntityToMonkeyIsland_Disappear, x, z, rot, fxprefab, delay)
                else
                    self.TeleportPearlEntityToMonkeyIsland_Teleport(ent, x, z, rot, fxprefab, delay)
                end
                index = index + 1
            elseif BRANCH == "staging" then
                c_announce("This world has too many hermitcrab entities for wagpunk_arena_manager default teleporting please upload the world to the bug tracker.")
            end
        end
    end
end
local function WaitForPearl_Bridge()
    self:WaitForPearl()
end
function self:WaitForPearl()
    if self.waitingforpearltask ~= nil then
        self.waitingforpearltask:Cancel()
        self.waitingforpearltask = nil
    end

    if self.hermitcrab and not self.hermitcrab:IsAsleep() and self.hermitcrab.components.npc_talker:haslines() then
        self.waitingforpearltask = self.inst:DoTaskInTime(0.1, WaitForPearl_Bridge)
        return
    end

    self:MovePearlToMonkeyIsland()
end
function self:MovePearlToMonkeyIsland()
    self.pearlmovingcount = 0
    self:TeleportPearlEntityToMonkeyIsland("hermithouse", "hermitcrab_fx_tall")
    self:TeleportPearlEntityToMonkeyIsland("hermithouse_construction1", "hermitcrab_fx_tall")
    self:TeleportPearlEntityToMonkeyIsland("hermithouse_construction2", "hermitcrab_fx_tall")
    self:TeleportPearlEntityToMonkeyIsland("hermithouse_construction3", "hermitcrab_fx_tall")
    self:TeleportPearlEntityToMonkeyIsland("beebox_hermit", "hermitcrab_fx_small")
    self:TeleportPearlEntityToMonkeyIsland("meatrack_hermit", "hermitcrab_fx_med")
    self:TeleportPearlEntityToMonkeyIsland("hermitcrab", "hermitcrab_fx_small")
    self:TeleportPearlEntityToMonkeyIsland("hermitcrab_marker")
    self:TeleportPearlEntityToMonkeyIsland("hermitcrab_lure_marker")
    self:TeleportPearlEntityToMonkeyIsland("hermitcrab_marker_fishing")
end

function self:CheckTurfCompletion()
    -- NOTES(JBK): Must check each time because mods might place the turf out of our area where a count would be optimal for this check.
    for _, v in ipairs(self.TILESPOTS) do
        local dtx, dtz = v[1], v[2]
        local x, z = self.storedx_pearl + dtx * TILE_SCALE, self.storedz_pearl + dtz * TILE_SCALE
        if _map:GetTileAtPoint(x, 0, z) ~= WAGSTAFF_FLOOR then
            return false
        end
    end

    self:TurfCompleted()
    return true
end

function self:CheckConstructCompleted()
    if self:HasArenaEntity("wagdrone_spot_marker") then
        return false
    end

    if self.wagboss and not self.wagboss:IsSocketed() then
        if self.inst.components.lunaralterguardianspawner then
            self.inst.components.lunaralterguardianspawner:TrySpawnLunarGuardian(self.wagstaff)
        end
        return false
    end

    self:ConstructCompleted()
    return true
end

function self:SetState(state)
    self.state = state
    self:UpdateNetvars()
end

function self:SparkArkCompleted()
    if not self.sparkark then
        self.sparkark = true
        self:QueueCheck()
    end
end
function self:IsPearlMapValid(giver, item) -- item has tag "mapscroll"
    if not giver or not item then
        return false
    end

    if not item.components.maprecorder then
        return false
    end

    if not self.storedx_monkey or not self.storedz_monkey then
        return false
    end

    local tx, ty = _map:GetTileCoordsAtPoint(self.storedx_monkey, 0, self.storedz_monkey)
    return item.components.maprecorder:IsTileSeeableInRecordedMap(giver, tx, ty)
end
function self:IsPearlMapValidToPearl(giver, item)
    if item.prefab ~= "mapscroll_tricker" then
        return false
    end
    return self:IsPearlMapValid(giver, item)
end
function self:IsPearlMapValidToWagstaff(giver, item)
    if item.prefab == "mapscroll_tricker" then
        return false
    end
    return self:IsPearlMapValid(giver, item)
end
function self:HasPearlAcceptedAGoodMap()
    return self.pearlmap
end
function self:ShouldPearlAcceptMaps()
    return self.state == self.STATES.PEARLMAP and not self:HasPearlAcceptedAGoodMap()
end
function self:ShouldWagstaffAcceptItem(inst, item, giver, count)
    inst.trader_chatterreason = nil
    if inst ~= self.wagstaff then
        return false
    end

    if inst.components.inventory:GetFirstItemInAnySlot() ~= nil then
        inst.trader_chatterreason = "WAGSTAFF_TOOMANYITEMS"
        return false
    end

    if self.state == self.STATES.PEARLMAP then
        if not item:HasTag("mapscroll") then
            inst.trader_chatterreason = "WAGSTAFF_GOT_NOT_MAPSCROLL"
            return false
        end

        if self:HasPearlAcceptedAGoodMap() then
            inst.trader_chatterreason = "WAGSTAFF_GOT_MAPSCROLL_NOLONGERNEEDED"
            return false
        end

        local success = self:IsPearlMapValidToWagstaff(giver, item)
        if not success then
            if item.prefab == "mapscroll_tricker" then
                inst.trader_chatterreason = "WAGSTAFF_MAPSCROLL_TRICKER"
            else
                inst.trader_chatterreason = "WAGSTAFF_GOT_MAPSCROLL_BAD"
            end
            return false
        end

        inst.trader_chatterreason = "WAGSTAFF_GOT_MAPSCROLL_GOOD"
        return true
    elseif self.state == self.STATES.CONSTRUCT then
        if item:HasTag("mapscroll") then
            inst.trader_chatterreason = "WAGSTAFF_GOT_MAPSCROLL_NOLONGERNEEDED"
            return false
        end

        if item:HasTag("gestalt_cage") then
            inst.trader_chatterreason = "WAGSTAFF_GOT_EMPTY_GESTALTCAGE"
            return false
        end

        if not item:HasTag("gestalt_cage_filled") then
            inst.trader_chatterreason = "WAGSTAFF_GOT_NOT_GESTALTCAGE"
            return false
        end


        if (item.prefab == "gestalt_cage_filled1" or item.prefab == "gestalt_cage_filled2") and not self:HasArenaEntity("wagdrone_spot_marker") then
            inst.trader_chatterreason = "WAGSTAFF_GOT_GESTALTCAGE_NOLONGERNEEDED"
            return false
        end
        if item.prefab == "gestalt_cage_filled3" and self.wagboss and self.wagboss:IsSocketed() then
            inst.trader_chatterreason = "WAGSTAFF_GOT_GESTALTCAGE_NOLONGERNEEDED"
            return false
        end

        inst.trader_chatterreason = "WAGSTAFF_GOT_GESTALTCAGE_GOOD"
        return true
    end

    return false
end
function self:PearlMapCompleted()
    if not self.pearlmap then
        self.pearlmap = true
        self:QueueCheck()
    end
end
function self:PearlMoveCompleted()
    if not self.pearlmove then
        self.pearlmove = true
        self:QueueCheck()
    end
end
function self:TurfCompleted()
    if not self.turfed then
        self.turfed = true
        self:QueueCheck()
    end
end
function self:ConstructCompleted()
    if not self.constructed then
        self.constructed = true
        self:QueueCheck()
    end
end
function self:LeverCompleted()
    if not self.levered then
        self.levered = true
        self:QueueCheck()
    end
end
local function BossCompleted_Bridge()
    self:BossCompleted()
end
function self:BossCompleted()
    if self.despawngraceperiodtask then
        self.despawngraceperiodtask:Cancel()
        self.despawngraceperiodtask = nil
    end
    if not self.bossed then
        self.bossed = true
        self:QueueCheck()
    end
end

local function BossCooldownFinished_Bridge()
    self:BossCooldownFinished()
end
function self:BossCooldownFinished()
    if self.bosscooldowntask ~= nil then
        self.bosscooldowntask:Cancel()
        self.bosscooldowntask = nil
    end
    self:SetState(self.STATES.CONSTRUCT)
    self:QueueCheck()
end

function self:CheckStateForChanges_Internal()
    if self.state == self.STATES.SPARKARK then
        if self.sparkark then
            self:SetState(self.STATES.PEARLMAP)
            return true
        end
        -- Wait for Spark Ark to be completed.
    elseif self.state == self.STATES.PEARLMAP then
        if self.pearlmap then
            self:SetState(self.STATES.PEARLMOVE)
            return true
        end
        self:SpawnWagstaffSetPiece()
    elseif self.state == self.STATES.PEARLMOVE then
        if self.pearlmove then
            self:SetState(self.STATES.TURF)
            return true
        end
        -- Pearl has been given a map to get off of the island and will move there over time.
        -- Wait for Pearl to finish moving.
        self:WaitForPearl()
    elseif self.state == self.STATES.TURF then
        if self.turfed then
            self:SetState(self.STATES.CONSTRUCT)
            return true
        end
        self:TryToSpawnArenaEntities("wagpunk_floor_marker") -- Self managed for setup.
        self:TryToSpawnArenaEntities("wagpunk_floor_placerindicator") -- Floor decal helpers to direct the player.
        if self.workstation then
            self.workstation.components.craftingstation:LearnItem("wagpunk_floor_kit", "wagpunk_floor_kit")
        end

        if self.wagstaff then
            self.wagstaff:RemoveComponent("trader")
        end
    elseif self.state == self.STATES.CONSTRUCT then
        if self.constructed then
            self:SetState(self.STATES.LEVER)
            return true
        end
        self:RemoveArenaEntities("wagpunk_floor_placerindicator") -- Just in case.
        local wagboss_tracker = TheWorld.components.wagboss_tracker
        if wagboss_tracker == nil or not wagboss_tracker:IsWagbossDefeated() then
            self:TryToSpawnArenaEntities("wagdrone_spot_marker", self.validspotfn_clearthisarea)
        end
        local wagboss_robots = self:TryToSpawnArenaEntities("wagboss_robot", self.validspotfn_clearthisarea)
        if wagboss_robots then
            self:TrackWagboss(wagboss_robots[1])
        end
        if self.wagstaff then
            self.wagstaff:AddTrader()
        end
        if self.workstation then
            self.workstation.components.craftingstation:LearnItem("gestalt_cage", "gestalt_cage")
        end
    elseif self.state == self.STATES.LEVER then
        if self.levered then
            self:SetState(self.STATES.BOSS)
            return true
        end
        self:RemoveArenaEntities("wagdrone_spot_marker") -- Just in case.
        self:SpawnCageWalls()
        if self.lever then
            self.lever:ExtendLever()
        end
        if self.wagstaff then
            self.wagstaff:RemoveComponent("trader")
        end
    elseif self.state == self.STATES.BOSS then
        if self.bossed then -- Loop back for repeating the fight.
            if self.wagboss == nil or IsEntityDead(self.wagboss) then
                -- Boss is dead go on cooldown and reset task flags back to construct.
                self.levered = nil
                self.bossed = nil
                self.constructed = nil
                self:SetState(self.STATES.BOSSCOOLDOWN)
                if self.bosscooldowntask ~= nil then
                    self.bosscooldowntask:Cancel()
                    self.bosscooldowntask = nil
                end
                self.bosscooldowntask = self.inst:DoTaskInTime(TUNING.WAGPUNK_ARENA_WAGBOSS_ROBOT_COOLDOWN_DEFEATED_TIME, BossCooldownFinished_Bridge)
            else
                -- The boss won make it go back to the center and reset the arena.
                self.levered = nil
                self.bossed = nil
                self:SetState(self.STATES.LEVER)
                self.wagboss:PushEvent("doreset")
            end

            if self.cagewalls then
                for cagewall, _ in pairs(self.cagewalls) do
                    cagewall:RetractWallWithJitter(0.4)
                end
            end
            if self.collision and self.collision:IsValid() then
                self.collision:Remove()
            end
            self.collision = nil
            local wagboss_tracker = TheWorld.components.wagboss_tracker
            if wagboss_tracker and wagboss_tracker:IsWagbossDefeated() then
                if self.workstation then
                    -- FIXME(JBK): WA: Kit.
                    --self.workstation.components.craftingstation:LearnItem("wagdrone_rolling_kit", "wagdrone_rolling_kit")
                end
            end
            self:UnlockPlayers()
            return true
        end
        -- Do nothing and wait for boss defeated.
        if self.cagewalls then
            for cagewall, _ in pairs(self.cagewalls) do
                cagewall:ExtendWallWithJitter(0.4)
            end
        end
        if not self.collision then
            self.collision = SpawnPrefab("wagpunk_arena_collision")
            self.collision.Transform:SetPosition(self.storedx_pearl, 0, self.storedz_pearl)
        end
        if self.lever then
            self.lever:RetractLever()
        end
        if self.wagboss then
            self.wagboss:PushEvent("activate")
        end
        self:LockPlayersIn()
    elseif self.state == self.STATES.BOSSCOOLDOWN then
        -- We wait.
    end
    return false
end

function self:DecrementAliveCount()
    local count = self.playersdata.alivecount - 1
    self.playersdata.alivecount = count
    if count <= 0 then
        if self.despawngraceperiodtask then
            self.despawngraceperiodtask:Cancel()
            self.despawngraceperiodtask = nil
        end
        if next(self.playersdata.disconnected) and not next(self.playersdata.players) then
            self.despawngraceperiodtask = self.inst:DoTaskInTime(TUNING.WAGPUNK_ARENA_WAGBOSS_ROBOT_DESPAWN_GRACE_TIME, BossCompleted_Bridge)
        else
            self:BossCompleted()
        end
    end
end
function self:IncrementAliveCount()
    local count = self.playersdata.alivecount + 1
    self.playersdata.alivecount = count
    if self.despawngraceperiodtask then
        self.despawngraceperiodtask:Cancel()
        self.despawngraceperiodtask = nil
    end
end

self.OnPlayerJoined = function(world, player)
    if self.playersdata.disconnected[player.userid] then
        self.playersdata.disconnected[player.userid] = nil
        self:TrackPlayer(player)
    end
end

self.OnPlayerRemove = function(player, data)
    self.playersdata.disconnected[player.userid] = true
    self:StopTrackingPlayer(player)
end
self.OnPlayerBecameGhost = function(player, data)
    if self.playersdata.players[player] ~= false then
        self.playersdata.players[player] = false
        self:DecrementAliveCount()
    end
end
self.OnPlayerRespawnedFromGhost = function(player, data)
    if self.playersdata.players[player] ~= true then
        self.playersdata.players[player] = true
        self:IncrementAliveCount()
    end
end
function self:StopTrackingPlayer(player)
    local isalive = self.playersdata.players[player]
    self.playersdata.players[player] = nil
    player:RemoveEventCallback("onremove", self.OnPlayerRemove)
    player:RemoveEventCallback("ms_becameghost", self.OnPlayerBecameGhost)
    player:RemoveEventCallback("ms_respawnedfromghost", self.OnPlayerRespawnedFromGhost)
    if isalive then
        self:DecrementAliveCount()
    end
end
function self:TrackPlayer(player)
    local isalive = not IsEntityDeadOrGhost(player)
    self.playersdata.players[player] = isalive
    player:ListenForEvent("onremove", self.OnPlayerRemove)
    player:ListenForEvent("ms_becameghost", self.OnPlayerBecameGhost)
    player:ListenForEvent("ms_respawnedfromghost", self.OnPlayerRespawnedFromGhost)
    if isalive then
        self:IncrementAliveCount()
    end
end

function self:LockPlayersIn()
    if not self.playersdata then
        self.playersdata = {
            players = {}, -- Player instances that are marked for the fight. Format: players[player] = isalive
            alivecount = 0,
            disconnected = {}, -- Player KUs who left when marked for the fight. Format: disconnected[ku] = true
        }
        for _, player in ipairs(AllPlayers) do
            local x, _, z = player.Transform:GetWorldPosition()
            local inarena = _map:IsPointInWagPunkArena(x, 0, z)
            if inarena then
                self:TrackPlayer(player)
            end
        end

        self.inst:ListenForEvent("ms_playerjoined", self.OnPlayerJoined)

        self.inst:StartUpdatingComponent(self)
    end
end
function self:UnlockPlayers()
    if self.playersdata then
        self.inst:StopUpdatingComponent(self)

        self.inst:RemoveEventCallback("ms_playerjoined", self.OnPlayerJoined)

        for player, _ in pairs(self.playersdata.players) do
            player:RemoveEventCallback("onremove", self.OnPlayerRemove)
            player:RemoveEventCallback("ms_becameghost", self.OnPlayerBecameGhost)
            player:RemoveEventCallback("ms_respawnedfromghost", self.OnPlayerRespawnedFromGhost)
        end
        self.playersdata = nil
    end
end

self.updateaccumulator = 0
self.UPDATE_TICK_TIME = 1
function self:OnUpdate(dt)
    self.updateaccumulator = self.updateaccumulator + dt
    if self.updateaccumulator > self.UPDATE_TICK_TIME then
        self.updateaccumulator = 0
        if self.playersdata then
            for _, player in ipairs(AllPlayers) do
                local x, _, z = player.Transform:GetWorldPosition()
                local inarena = _map:IsPointInWagPunkArena(x, 0, z)
                local shouldbeinarena = self.playersdata.players[player] ~= nil
                -- NOTES(JBK): Some things will cause the player to get into or out of the arena outside of our control like physics bunching.
                -- Intead of trying to find every case for that we will make the player dynamically count for the fight.
                -- FIXME(JBK): WA: Known issue list: Wanda revive, Winona revive, Winona teleport, Meat Effigy.
                if not inarena and shouldbeinarena then
                    self:StopTrackingPlayer(player)
                elseif inarena and not shouldbeinarena then
                    self:TrackPlayer(player)
                end
            end
        end
    end
end

function self:CheckStateForChanges() -- This can only be called if the transformation was applied so we have arena coordinates.
    while self:CheckStateForChanges_Internal() do
        -- Keep going.
    end
end

local function UpdateNetvars_Bridge()
    self:UpdateNetvars()
end
function self:UpdateNetvars()
    if self.updatenetvarstask ~= nil then -- Let this function repeat entry safe.
        self.updatenetvarstask:Cancel()
        self.updatenetvarstask = nil
    end
    local wagpunk_floor_helper = _world.net and _world.net.components.wagpunk_floor_helper
    if not wagpunk_floor_helper then
        self.updatenetvarstask = self.inst:DoTaskInTime(0, UpdateNetvars_Bridge) -- Reschedule.
        return
    end

    wagpunk_floor_helper.barrier_active:set(self.state == self.STATES.BOSS)
end
function self:OnInit()
    self:TryToApplyRotationTransformation()
    if not self.state then
        self:SetState(self.STATES.SPARKARK)
        self:QueueCheck()
    end
    self:UpdateNetvars()
end

function self:OnSave()
    local data, ents = {}, {}

    data.storedangle_pearl = self.storedangle_pearl
    data.storedx_pearl = self.storedx_pearl
    data.storedz_pearl = self.storedz_pearl

    data.storedangle_monkey = self.storedangle_monkey
    data.storedx_monkey = self.storedx_monkey
    data.storedz_monkey = self.storedz_monkey

    data.sparkark = self.sparkark
    data.pearlmap = self.pearlmap
    data.pearlmove = self.pearlmove
    data.turfed = self.turfed
    data.constructed = self.constructed
    data.levered = self.levered
    data.bossed = self.bossed

    if self.state ~= self.STATES.SPARKARK then
        data.state = self:GetStateString()
    end

    if self.cagewalls then
        data.cagewalls = {}
        for cagewall, _ in pairs(self.cagewalls) do
            table.insert(data.cagewalls, cagewall.GUID)
            table.insert(ents, cagewall.GUID)
        end
    end
    if self.lever then
        data.lever = self.lever.GUID
        table.insert(ents, self.lever.GUID)
    end
    if self.workstation then
        data.workstation = self.workstation.GUID
        table.insert(ents, self.workstation.GUID)
    end
    if self.wagboss then
        data.wagboss = self.wagboss.GUID
        table.insert(ents, self.wagboss.GUID)
    end
    if self.wagstaff then
        data.wagstaff = self.wagstaff.GUID
        table.insert(ents, self.wagstaff.GUID)
        data.w_tiedtoworkstation = self.wagstaff.tiedtoworkstation
    end
    if next(self.arenaentities) then
        data.arenaentities = {}
        for ent, _ in pairs(self.arenaentities) do
            table.insert(data.arenaentities, ent.GUID)
            table.insert(ents, ent.GUID)
        end
    end
    if self.playersdata then
        local disconnected = {}
        for playeruserid, _ in pairs(self.playersdata.disconnected) do
            table.insert(disconnected, playeruserid)
        end
        for player, _ in pairs(self.playersdata.players) do
            table.insert(disconnected, player.userid)
        end
        if disconnected[1] then
            data.disconnected = disconnected
        end
    end
    if self.bosscooldowntask then
        data.bosscooldownremaining = GetTaskRemaining(self.bosscooldowntask)
    end
    return data, ents
end

function self:OnLoad(data)
    if not data then
        return
    end

    self.storedangle_pearl = data.storedangle_pearl
    self.storedx_pearl = data.storedx_pearl
    self.storedz_pearl = data.storedz_pearl

    self.storedangle_monkey = data.storedangle_monkey
    self.storedx_monkey = data.storedx_monkey
    self.storedz_monkey = data.storedz_monkey

    self.sparkark = data.sparkark
    self.pearlmap = data.pearlmap
    self.pearlmove = data.pearlmove
    self.turfed = data.turfed
    self.constructed = data.constructed
    self.levered = data.levered
    self.bossed = data.bossed

    if data.disconnected then
        local disconnected = {}
        for _, playeruserid in ipairs(data.disconnected) do
            disconnected[playeruserid] = true
        end
        if next(disconnected) then
            self.playersdata = {
                players = {},
                alivecount = 0,
                disconnected = disconnected,
            }
            self.inst:ListenForEvent("ms_playerjoined", self.OnPlayerJoined)

            self.inst:StartUpdatingComponent(self)
        end
    end
    if data.bosscooldownremaining then
        self.bosscooldowntask = self.inst:DoTaskInTime(data.bosscooldownremaining, BossCooldownFinished_Bridge)
    end

    if data.state then
        self:SetState(self.STATES[data.state] or self.STATES.SPARKARK)
        self:QueueCheck()
    end
end

function self:LoadPostPass(newents, savedata)
    if savedata.cagewalls then
        self.cagewalls = {}
        for _, cagewallguid in ipairs(savedata.cagewalls) do
            if newents[cagewallguid] then
                local cagewall = newents[cagewallguid].entity
                self:TrackCageWall(cagewall)
            end
        end
    end
    if savedata.lever then
        if newents[savedata.lever] then
            local lever = newents[savedata.lever].entity
            self:TrackLever(lever)
        end
    end
    if savedata.workstation then
        if newents[savedata.workstation] then
            local workstation = newents[savedata.workstation].entity
            self:TrackWorkstation(workstation)
        end
    end
    if savedata.wagboss then
        if newents[savedata.wagboss] then
            local wagboss = newents[savedata.wagboss].entity
            self:TrackWagboss(wagboss)
        end
    end
    if savedata.wagstaff then
        if newents[savedata.wagstaff] then
            local wagstaff = newents[savedata.wagstaff].entity
            wagstaff.tiedtoworkstation = savedata.w_tiedtoworkstation
            self:TrackWagstaff(wagstaff)
        end
    end
    if savedata.arenaentities then
        for _, entguid in ipairs(savedata.arenaentities) do
            if newents[entguid] then
                local ent = newents[entguid].entity
                self:TrackArenaEntity(ent)
            end
        end
    end
end

self.OnRemove_HermitCrabMarker = function(ent, data)
    self.hermitcrab_marker = nil
end
function self:RegisterHermitCrabMarker(ent)
    if self.appliedrotationtransformation then
        return
    end
    if self.hermitcrab_marker then
        print("ERROR: wagpunk_arena_manager expected only one hermitcrab_marker in the world but encountered multiple most likely from mods.")
        self.failed = true
        return
    end

    self.hermitcrab_marker = ent
    ent:ListenForEvent("onremove", self.OnRemove_HermitCrabMarker)
end

self.OnRemove_BeeBoxHermit = function(ent, data)
    self.beebox_hermit = nil
end
function self:RegisterBeeBoxHermit(ent)
    if self.appliedrotationtransformation then
        return
    end
    if self.beebox_hermit then
        print("ERROR: wagpunk_arena_manager expected only one beebox_hermit in the world but encountered multiple most likely from mods.")
        self.failed = true
        return
    end

    self.beebox_hermit = ent
    ent:ListenForEvent("onremove", self.OnRemove_BeeBoxHermit)
end

self.OnRemove_PearlEntity = function(ent, data)
    self.pearlsentities[ent] = nil
end
function self:RegisterPearlEntity(ent)
    self.pearlsentities[ent] = true
    ent:ListenForEvent("onremove", self.OnRemove_PearlEntity)
end

self.OnRemove_HermitCrab = function(ent, data)
    self.hermitcrab = nil
end
function self:RegisterHermitCrab(ent)
    self.hermitcrab = ent
    ent:ListenForEvent("onremove", self.OnRemove_HermitCrab)
end


self.OnRemove_MonkeyPortal = function(ent, data)
    self.monkeyportal = nil
end
function self:RegisterMonkeyPortal(ent)
    if self.appliedrotationtransformation then
        return
    end
    if self.monkeyportal then
        print("ERROR: wagpunk_arena_manager expected only one monkeyportal in the world but encountered multiple most likely from mods.")
        self.failed = true
        return
    end

    self.monkeyportal = ent
    ent:ListenForEvent("onremove", self.OnRemove_MonkeyPortal)
end

self.OnRemove_MonkeyQueen = function(ent, data)
    self.monkeyqueen = nil
end
function self:RegisterMonkeyQueen(ent)
    if self.appliedrotationtransformation then
        return
    end
    if self.monkeyqueen then
        print("ERROR: wagpunk_arena_manager expected only one monkeyqueen in the world but encountered multiple most likely from mods.")
        self.failed = true
        return
    end

    self.monkeyqueen = ent
    ent:ListenForEvent("onremove", self.OnRemove_MonkeyQueen)
end


self.inst:ListenForEvent("ms_register_hermitcrab_marker", function(inst, ent) self:RegisterHermitCrabMarker(ent) end, _world)
self.inst:ListenForEvent("ms_register_beebox_hermit", function(inst, ent) self:RegisterBeeBoxHermit(ent) end, _world)
self.inst:ListenForEvent("ms_register_hermitcrab", function(inst, ent) self:RegisterHermitCrab(ent) end, _world)
self.inst:ListenForEvent("ms_register_pearl_entity", function(inst, ent) self:RegisterPearlEntity(ent) end, _world)

self.inst:ListenForEvent("ms_register_monkeyisland_portal", function(inst, ent) self:RegisterMonkeyPortal(ent) end, _world)
self.inst:ListenForEvent("ms_register_monkeyqueen", function(inst, ent) self:RegisterMonkeyQueen(ent) end, _world)

self.inst:ListenForEvent("ms_lunarriftmutationsmanager_taskcompleted", function(inst) self:SparkArkCompleted() end, _world)
self.inst:ListenForEvent("ms_wagpunk_floor_kit_deployed", function(inst) self:CheckTurfCompletion() end, _world)
self.inst:ListenForEvent("ms_wagpunk_constructrobot", function(inst) self:CheckConstructCompleted() end, _world)
self.inst:ListenForEvent("ms_wagpunk_lever_activated", function(inst) self:LeverCompleted() end, _world)

self.inst:DoTaskInTime(0, function() self:OnInit() end)


function self:DebugForcePearl()
    -- Pearl's Pearl is needed for CC questline and that means at least 10 tasks and her home has been upgraded.
    local doer = ThePlayer or TheWorld
    local hermithouse
    repeat
        hermithouse = nil
        for ent, _ in pairs(self.pearlsentities) do
            if ent.prefab == "hermithouse_construction1" or ent.prefab == "hermithouse_construction2" or ent.prefab == "hermithouse_construction3" then
                hermithouse = ent
                hermithouse.components.constructionsite:ForceCompletion(doer)
                break
            end
        end
    until hermithouse == nil
    if self.hermitcrab then
        self.hermitcrab.components.friendlevels:CompleteAllTasks(doer)
    end
end
function self:DebugForceTurf()
    for _, v in ipairs(self.TILESPOTS) do
        local dtx, dtz = v[1], v[2]
        local x, z = self.storedx_pearl + dtx * TILE_SCALE, self.storedz_pearl + dtz * TILE_SCALE

        local tile_x, tile_y = _map:GetTileCoordsAtPoint(x, 0, z)

        local current_tile = nil
        local undertile = TheWorld.components.undertile
        if undertile ~= nil then
            current_tile = _map:GetTile(tile_x, tile_y)
        end
    
        _map:SetTile(tile_x, tile_y, WAGSTAFF_FLOOR)
        -- Because of a terraforming callback in farming_manager.lua, the undertile gets cleared during SetTile.
        -- We can circumvent this for now by setting the undertile after SetTile.
        if undertile ~= nil and current_tile ~= nil then
            undertile:SetTileUnderneath(tile_x, tile_y, current_tile)
        end
    end
end
function self:DebugForceConstruct()
    if self.wagboss then
        self.wagboss:SocketCage()
    end
    if self:HasArenaEntity("wagdrone_spot_marker") then
        for ent, _ in pairs(self.arenaentities) do
            if ent.prefab == "wagdrone_spot_marker" then
                if math.random() < 0.5 then
                    ReplacePrefab(ent, "wagdrone_rolling")
                else
                    ReplacePrefab(ent, "wagdrone_flying")
                end
            end
        end
    end
end
function self:DebugSkipState()
    print("Completing state:", self:GetStateString())
    if self.state == self.STATES.SPARKARK then
        self:DebugForcePearl()
        self:SparkArkCompleted()
    elseif self.state == self.STATES.PEARLMAP then
        self:PearlMapCompleted()
    elseif self.state == self.STATES.PEARLMOVE then
        if self.pearlmovingcount == 0 then
            self:PearlMoveCompleted()
        else
            print("  Not so fast wait for Pearl to finish.")
        end
    elseif self.state == self.STATES.TURF then
        self:DebugForceTurf()
        self:TurfCompleted()
    elseif self.state == self.STATES.CONSTRUCT then
        self:DebugForceConstruct()
        self:ConstructCompleted()
    elseif self.state == self.STATES.LEVER then
        self:LeverCompleted()
    elseif self.state == self.STATES.BOSS then
        if self.wagboss then
            if self.wagboss.components.health then
                self.wagboss.components.health:Kill()
            else
                self.OnDeath_Wagboss(self.wagboss)
                self.wagboss:Remove()
            end
        else
            self:BossCompleted()
        end
    elseif self.state == self.STATES.BOSSCOOLDOWN then
        self:BossCooldownFinished()
    end
end
function self:DebugPrintFlags()
    print("sparkark:", self.sparkark)
    print("pearlmap:", self.pearlmap)
    print("pearlmove:", self.pearlmove)
    print("turfed:", self.turfed)
    print("constructed:", self.constructed)
    print("levered:", self.levered)
    print("bossed:", self.bossed)
end

end)