require "map/room_functions"

---------------------------------------------
---------------------------------------------

--[[
random setpiece ideas boons and traps

bunch of vent rocks together with loot inside take loot boom vents trigger with spores or miasma or something

burned setpiece with a bunch of rock trees that had burned?

setpiece with several rock trees, each with 5 ruins gems that is a trap, not actually real
]]

-- withered ferns and light bulbs
-- miasma in general could also do this

local function RandomRockTreeState()
    if math.random() < TUNING.TREE_ROCK.BOULDER_GEN_CHANCE then
        local roll = math.random()
        if roll > 2/3 then
            return { boulder = true, workable = { workleft = TUNING.TREE_ROCK.MINE_MED} }
        elseif roll > 1/3 then
            return { boulder = true, workable = { workleft = TUNING.TREE_ROCK.MINE_LOW} }
        else
            return { boulder = true }
        end
    end
end

local function RandomVentRockState()
    local roll = math.random()
    if roll > 2/3 then
        return { workable = { workleft = TUNING.CAVE_VENTS.MINE_MED }, set_loot_table = "cave_vent_rock_med" }
    elseif roll > 1/3 then
        return { workable = { workleft = TUNING.CAVE_VENTS.MINE_LOW }, set_loot_table = "cave_vent_rock_low"}
    else
        return nil --full state
    end
end

AddRoom("BGVentsRoom", {
    colour={r=.8,g=1,b=.8,a=.50},
    value = WORLD_TILES.VENT, --WORLD_TILES.ARCHIVE
    type = NODE_TYPE.Background,
    random_node_exit_weight = 0,
    contents =  {
        distributepercent = .1,
        distributeprefabs =
        {
            cave_vent_rock  = 0.1,
            tree_rock1      = 0.035,
            tree_rock2      = 0.035,
            --cave_fern_withered = 0.2,
            --flower_cave_withered = 0.1,
        },
        prefabdata = {
            cave_vent_rock = RandomVentRockState,
            tree_rock1 = RandomRockTreeState,
            tree_rock2 = RandomRockTreeState,
        },
    }
})

AddRoom("VentsRoom", {
    colour={r=.8,g=1,b=.8,a=.50},
    value = WORLD_TILES.VENT,
    random_node_exit_weight = 0,
    --type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .1,
        distributeprefabs=
        {
            cave_vent_rock  = 0.5,
            tree_rock1      = 0.12,
            tree_rock2      = 0.12,
        },
        prefabdata = {
            cave_vent_rock = RandomVentRockState,
            tree_rock1 = RandomRockTreeState,
            tree_rock2 = RandomRockTreeState,
        },
    }
})

--#DELETEME
AddRoom("CentipedeNest", {
    colour={r=.8,g=1,b=.8,a=.50},
    value = WORLD_TILES.VENT,
    random_node_entrance_weight = 0,
    type = NODE_TYPE.Room,
    contents =  {
        countstaticlayouts =
        {
            ["CentipedeNest"] = 1,
        },
        distributepercent = .2,
        distributeprefabs =
        {
            cave_vent_rock  = 0.4,
            tree_rock1      = 0.02,
            tree_rock2      = 0.02,
        },
        prefabdata = {
            cave_vent_rock = RandomVentRockState,
            tree_rock1 = RandomRockTreeState,
            tree_rock2 = RandomRockTreeState,
        },
    }
})

AddRoom("RockTreeRoom", {
    colour={r=.8,g=1,b=.8,a=.50},
    value = WORLD_TILES.VENT,
    random_node_exit_weight = 0,
    type = NODE_TYPE.Room,
    contents =  {
        countprefabs = {
            tree_rock1      = function() return math.random(SIZE_VARIATION) end,
            tree_rock2      = function() return math.random(SIZE_VARIATION) end,
        },
        distributepercent = .1,
        distributeprefabs=
        {
            cave_vent_rock  = 0.1,
            tree_rock1      = 0.5,
            tree_rock2      = 0.5,
        },
        prefabdata = {
            cave_vent_rock = RandomVentRockState,
            tree_rock1 = RandomRockTreeState,
            tree_rock2 = RandomRockTreeState,
        },
    }
})

AddRoom("VentsRoom_exit", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = WORLD_TILES.VENT_NOISE,
	random_node_entrance_weight = 0,
    --type = NODE_TYPE.Room,
    tags = {"ExitPiece"},
    contents =  {
		distributepercent = 0.1,
        distributeprefabs =
        {
            cave_vent_rock = 0.1,
            tree_rock1 = 0.01,
            tree_rock2 = 0.01,
        },
        prefabdata = {
            cave_vent_rock = RandomVentRockState,
            tree_rock1 = RandomRockTreeState,
            tree_rock2 = RandomRockTreeState,
        },
    }
})

-- An experimental idea.

AddRoom("RuinsIsland", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = WORLD_TILES.TILES,
    SafeFromDisconnect = true,
    tags = {"ForceDisconnected", "RoadPoison", "not_mainland"},
    random_node_entrance_weight = 0,
    contents =  {
        countstaticlayouts =
        {
            --["GrottoPoolBig"] = 1,
            --["GrottoPoolSmall"] = 4,
            --["SacredBarracks"] = 1,
            --["Barracks"] = 1,
        },
        countprefabs =
        {
            mushgnome_spawner = 1,
        },
        distributepercent = 0.35,
        distributeprefabs =
        {
            mushtree_moon = 0.075,

            lightflier_flower = 0.02,

            cavelightmoon = 0.003,
            cavelightmoon_small = 0.003,
            cavelightmoon_tiny = 0.003,

            moonglass_stalactite1 = 0.007,
            moonglass_stalactite2 = 0.007,
            moonglass_stalactite3 = 0.007,
        },
    }
})

AddRoom("RuinsIsland_entrance", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = WORLD_TILES.VENT_NOISE,
    SafeFromDisconnect = true,
    tags = {"ForceDisconnected", "RoadPoison", "not_mainland"},
	random_node_exit_weight = 0,
    contents =  {
		distributepercent = 0.20,
        distributeprefabs =
        {
			-- mushroom only
			mushtree_tall =	0.30,
            flower_cave = 0.10,

			-- moon only
            mushtree_moon = 0.40,
            lightflier_flower = 0.01,

			-- anywhere
            cavelightmoon_small = 0.003,
            cavelightmoon_tiny = 0.003,
        },
    }
})