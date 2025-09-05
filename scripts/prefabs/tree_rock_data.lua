local WEIGHTED_VINE_LOOT = {
    DEFAULT = {
        ["rocks"] = 20,
        ["redgem"] = 0.5,
        ["bluegem"] = 0.5,
        ["purplegem"] = 0.2,
        ["yellowgem"] = 0.02,
        ["orangegem"] = 0.02,
        ["greengem"] = 0.02,
    },
    SHADOW_RIFT = { --TODO only if in the original biome
        ["rocks"] = 15,
        ["redgem"] = 2,
        ["bluegem"] = 2,
        ["purplegem"] = 1,
        ["yellowgem"] = 0.5,
        ["orangegem"] = 0.5,
        ["greengem"] = 0.5,
    },
    -- [[Biomes]] --

    -- Forest
    ["FOREST_AREA"] = {},
    ["SAVANNA_AREA"] = {},
    ["DECIDUOUS_AREA"] = {},
    ["MARSH_AREA"] = {},
    ["GRASS_AREA"] = {},
    ["ROCKY_AREA"] = {},
    ["DESERT_AREA"] = {},
    ["MOON_AREA"] = {},

    -- Caves
    ["GUANO_AREA"] = {},
}

local VINE_LOOT_DATA = {
    ["rocks"]       = {build = "tree_rock_normal", symbols = {"swap_rock1", "swap_rock2", "swap_rock3"}},
    ["redgem"]      = {build = "gems", symbols = {"swap_redgem"}},
    ["bluegem"]     = {build = "gems", symbols = {"swap_bluegem"}},
    ["purplegem"]   = {build = "gems", symbols = {"swap_purplegem"}},
    ["yellowgem"]   = {build = "gems", symbols = {"swap_yellowgem"}},
    ["orangegem"]   = {build = "gems", symbols = {"swap_orangegem"}},
    ["greengem"]    = {build = "gems", symbols = {"swap_greengem"}},
}

--Uses string finder
--TODO This may not be preferable this is a long of strings to sift through and string find.
local TASKS_TO_LOOT_KEY = {
    ["FOREST_AREA"] = {
        -- Forest
        "Forest hunters",
        "Befriend the pigs",
        "Magic meadow",
        "For a nice walk",
    },
    ["SAVANNA_AREA"] = {
        -- Forest
        "Great Plains",
        "The hunters",
    },
    ["DECIDUOUS_AREA"] = {
        -- Forest
        "Speak to the king",
        "Mole Colony Deciduous",
    },
    ["MARSH_AREA"] = {
        -- Forest
        "Squeltch",
    },
    ["GRASS_AREA"] = {
        -- Forest
        "Beeeees!",
        "Killer bees!",
        "Make a Beehat",
        "Frogs and bugs",
        "MooseBreedingTask",
        "Make a pick",
    },
    ["ROCKY_AREA"] = {
        -- Forest
        "Dig that rock",
        "Kill the spiders",
        "Mole Colony Rocks",
    },
    ["DESERT_AREA"] = {
        -- Forest
        "Lightning Bluff",
        "Badlands",
    },
    ["MOON_AREA"] = {
        -- Forest
        "MoonIsland_",
    },
}

return {
    WEIGHTED_VINE_LOOT = WEIGHTED_VINE_LOOT,
    VINE_LOOT_DATA = VINE_LOOT_DATA,
    TASKS_TO_LOOT_KEY = TASKS_TO_LOOT_KEY,
}