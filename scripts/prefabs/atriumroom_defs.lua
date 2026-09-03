local defs = {
    internal = {},
    layouts = {},
}

local TILE_SCALE = TILE_SCALE
local IMPASSABLE = WORLD_TILES.IMPASSABLE

--------------------------------------------------------------------------

--[[
A short template for layouts.
defs.layouts.roomnamehere = {
    ApplyFloorTiles = function(inst, virtualroomset)
        virtualroomset:SetFloorTileInBatch(dtx, dty, IMPASSABLE)
    end,
    CreateRoomEntities = function(inst, virtualroomset)
        local x, _, z = virtualroomset:GetOrigin()
        -- Spawn entities.
    end,
}
]]

--------------------------------------------------------------------------

local function SetAllImpassable(virtualroomset)
    for y = -10, 10 do
        for x = -10, 10 do
            virtualroomset:SetFloorTileInBatch(x, y, IMPASSABLE)
        end
    end
end

defs.layouts.boss1 = {
    ApplyFloorTiles = function(inst, virtualroomset)
        SetAllImpassable(virtualroomset)

        for y = -3, 3 do
            for x = -3, 3 do
                virtualroomset:SetFloorTileInBatch(x, y, WORLD_TILES.BRICK_GLOW)
            end
        end
        -- virtualroomset:SetFloorTileInBatch(2, 0, IMPASSABLE)
        -- virtualroomset:SetFloorTileInBatch(3, 0, IMPASSABLE)
    end,
    CreateRoomEntities = function(inst, virtualroomset)
        local x, _, z = virtualroomset:GetOrigin()

        local trial = SpawnPrefab("charlie_boss_trial")
        trial.Transform:SetPosition(x, 0, z)
        trial:InitializeLayout(virtualroomset)
    end,
}

--------------------------------------------------------------------------

-- local fencepos2 = {
--     {-2 * TILE_SCALE, -1 * TILE_SCALE},
--     {-2 * TILE_SCALE, 0 * TILE_SCALE},
--     {-2 * TILE_SCALE, 1 * TILE_SCALE},
--     {-2 * TILE_SCALE, 2 * TILE_SCALE},
--     {-2 * TILE_SCALE, 3 * TILE_SCALE},
--     {0 * TILE_SCALE, -3 * TILE_SCALE},
--     {1 * TILE_SCALE, -3 * TILE_SCALE},
--     {2 * TILE_SCALE, -3 * TILE_SCALE},
-- }

-- defs.layouts.boss2 = {
--     ApplyFloorTiles = function(inst, virtualroomset)
--         SetAllImpassable(virtualroomset)

--         for y = -3, 3 do
--             for x = -3, 3 do
--                 virtualroomset:SetFloorTileInBatch(x, y, WORLD_TILES.BRICK_GLOW)
--             end
--         end
--     end,
--     CreateRoomEntities = function(inst, virtualroomset)
--         local x, _, z = virtualroomset:GetOrigin()


--         for _, pos in ipairs(fencepos1) do
--             local fence = SpawnPrefab("atrium_fence")
--             fence.Transform:SetPosition(x + pos[1], 0, z + pos[2])
--         end

--         for _, pos in ipairs(fencepos2) do
--             local fence = SpawnPrefab("atrium_fence")
--             fence.Transform:SetPosition(x + pos[1], 0, z + pos[2])
--         end
--     end,
-- }

local CURRENT_VERSION = 1
defs.InitializeLayout = function(virtualroomset)
    virtualroomset:SetVersion(CURRENT_VERSION) -- Mandatory call for InitializeLayout to have proper versioning control for this file.

    --------------------------------------------------------------------------
    -- NOTES(JBK): Adjusting the virtual room declarations will need a new CURRENT_VERSION number above.
    virtualroomset:DeclareVirtualRoom("boss1")
    -- virtualroomset:DeclareVirtualRoom("boss2")
    --------------------------------------------------------------------------
end

defs.DeleteLayout = function(virtualroomset)
end

return defs
