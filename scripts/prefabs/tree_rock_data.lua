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

    -- [[Biomes]] --

    -- Forest
    ["FOREST_AREA"] = {
        ["rocks"]               = 15,
        ["goldnugget"]          = 10,
        ["flint"]               = 10,
        ["nitre"]               = 10,
    },

    ["SAVANNA_AREA"] = {
        ["rocks"]               = 10,
        ["poop"]                = 20,
    },

    ["DECIDUOUS_AREA"] = {
        ["rocks"]               = 10,
        ["flint"]               = 5,
        ["goldnugget"]          = 3,
        ["poop"]                = 5,
    },

    ["MARSH_AREA"] = {
        ["rocks"]               = 10,
        ["flint"]               = 5,
        --["tentaclespots"]         = 5,
    },

    ["GRASS_AREA"] = {
        ["rocks"]               = 10,
        ["flint"]               = 5,

    },

    ["ROCKY_AREA"] = {
        ["rocks"]               = 20,
        ["flint"]               = 15,
        ["goldnugget"]          = 10,
    },

    ["DESERT_AREA"] = {
        ["rocks"]               = 10,
        --["boneshards"]            = 10
    },

    ["MOON_AREA"] = {
        ["rocks"]               = 5,
        ["flint"]               = 5,
        ["moonglass"]           = 10,
        ["moonrocknugget"]      = 5,
        --["rock_avocado_fruit_sprout"] = 0.5,
        --["rock_avocado_fruit"] = 1,
    },

    -- Caves
    ["MUD_AREA"] = {
        ["rocks"]               = 20,
        ["fossil_piece"]        = 0.5,
        ["poop"]                = 5,
    },

    ["CAVERN_AREA"] = {
        ["rocks"]               = 50,
        ["fossil_piece"]        = 5,
        ["guano"]               = 3,
        ["thulecite_pieces"]    = 5,
        --["silk"]              = 5,
        --["boneshard"]         = 5,
    },

    ["GUANO_AREA"] = {
        ["rocks"]               = 10,
        ["flint"]               = 10,
        ["goldnugget"]          = 5,
        ["guano"]               = 75,
    },

    ["RUINS_AREA"] = {
        ["rocks"]               = 5,
        ["flint"]               = 3,
        ["thulecite_pieces"]    = 10,
        ["redgem"]              = 0.75,
        ["bluegem"]             = 0.75,
        ["purplegem"]           = 0.5,
        ["yellowgem"]           = 0.2,
        ["orangegem"]           = 0.2,
        ["greengem"]            = 0.2,
    },

    ["VENT_AREA"] = { --Aka the default, kinda
        ["rocks"]               = 15,
        ["flint"]               = 8,
        ["goldnugget"]          = 2,
        ["redgem"]              = 0.5,
        ["bluegem"]             = 0.5,
        ["purplegem"]           = 0.2,
        ["yellowgem"]           = 0.02,
        ["orangegem"]           = 0.02,
        ["greengem"]            = 0.02,
    },

    ["VENT_AREA_SHADOW_RIFT"] = {
        ["rocks"]               = 10,
        ["flint"]               = 10,
        ["goldnugget"]          = 40,
        --["dreadstone"]        = 5,
        ["redgem"]              = 10,
        ["bluegem"]             = 10,
        ["purplegem"]           = 8,
        ["yellowgem"]           = 7,
        ["orangegem"]           = 7,
        ["greengem"]            = 7,
    },

    ["MUSHROOM_AREA"] = {
        ["rocks"]               = 10,
        ["flint"]               = 5,
        ["goldnugget"]          = 1,
        --["red_mushroom"]      = 5,
        --["blue_mushroom"]     = 5,
        --["green_mushroom"]    = 5,
    },

    ["SINKHOLE_AREA"] = {
        ["rocks"]               = 12,
        ["flint"]               = 5,
        ["goldnugget"]          = 3,
        ["nitre"]               = 5,
        ["guano"]               = 5,
    }
}

local VINE_LOOT_DATA = {
    ["rocks"]       = {build = "tree_rock_normal", symbols = {"swap_rock1", "swap_rock2", "swap_rock3"}},
    ["redgem"]      = {build = "gems", symbols = {"swap_redgem"}},
    ["bluegem"]     = {build = "gems", symbols = {"swap_bluegem"}},
    ["purplegem"]   = {build = "gems", symbols = {"swap_purplegem"}},
    ["yellowgem"]   = {build = "gems", symbols = {"swap_yellowgem"}},
    ["orangegem"]   = {build = "gems", symbols = {"swap_orangegem"}},
    ["greengem"]    = {build = "gems", symbols = {"swap_greengem"}},

    ["flint"]               = {build = "tree_rock_normal", symbols = {"swap_flint"}},
    ["goldnugget"]          = {build = "tree_rock_normal", symbols = {"swap_goldnugget"}},
    ["nitre"]               = {build = "tree_rock_normal", symbols = {"swap_nitre"}},
    ["thulecite_pieces"]    = {build = "tree_rock_normal", symbols = {"swap_thulecitefragment"}},
    ["fossil_piece"]        = {build = "tree_rock_normal", symbols = {"swap_fossilfragment"}},
    ["moonglass"]           = {build = "tree_rock_normal", symbols = {"swap_moonglass"}},
    ["moonrocknugget"]      = {build = "tree_rock_normal", symbols = {"swap_moonrocknugget"}},
    ["guano"]               = {build = "tree_rock_normal", symbols = {"swap_guano"}},
    ["poop"]                = {build = "tree_rock_normal", symbols = {"swap_poop"}},

    --dreadstone?
    --scrap?
}

local EXTRA_LOOT_MODIFIERS = {
    ["WEB_CREEP"] = {
        ["silk"] = 5,
    },
}

local TASKS_TO_LOOT_KEY = {
    -- [[ Forest ]] --

    -- FOREST_AREA
    ["Forest hunters"]          = "FOREST_AREA",
    ["Befriend the pigs"]       = "FOREST_AREA",
    ["Magic meadow"]            = "FOREST_AREA",
    ["Hounded magic meadow"]    = "FOREST_AREA",
    ["For a nice walk"]         = "FOREST_AREA",

    -- SAVANNA_AREA
    ["Great Plains"]            = "SAVANNA_AREA",
    ["The hunters"]             = "SAVANNA_AREA",

    -- DECIDUOUS_AREA
    ["Speak to the king"]       = "DECIDUOUS_AREA",
    ["Mole Colony Deciduous"]   = "DECIDUOUS_AREA",

    -- MARSH_AREA
    ["Squeltch"]                = "MARSH_AREA",

    -- GRASS_AREA
    ["Beeeees!"]                = "GRASS_AREA",
    ["Killer bees!"]            = "GRASS_AREA",
    ["Make a Beehat"]           = "GRASS_AREA",
    ["Frogs and bugs"]          = "GRASS_AREA",
    ["MooseBreedingTask"]       = "GRASS_AREA",
    ["Make a pick"]             = "GRASS_AREA",

    -- ROCKY_AREA
    ["Dig that rock"]           = "ROCKY_AREA",
    ["Kill the spiders"]        = "ROCKY_AREA",
    ["Mole Colony Rocks"]       = "ROCKY_AREA",

    -- DESERT_AREA
    ["Lightning Bluff"]         = "DESERT_AREA",
    ["Badlands"]                = "DESERT_AREA",

    -- MOON_AREA
    ["MoonIsland_IslandShards"] = "MOON_AREA",
    ["MoonIsland_Beach"]        = "MOON_AREA",
    ["MoonIsland_Forest"]       = "MOON_AREA",
    ["MoonIsland_Baths"]        = "MOON_AREA",
    ["MoonIsland_Mine"]         = "MOON_AREA",

    -- [[ Caves ]] --

    -- MUD_AREA
    ["MudWorld"]                = "MUD_AREA",
    ["MudCave"]                 = "MUD_AREA",
    ["MudLights"]               = "MUD_AREA",
    ["MudPit"]                  = "MUD_AREA",
    ["ToadStoolTask1"]          = "MUD_AREA",
    ["ToadStoolTask3"]          = "MUD_AREA",

    -- GUANO_AREA
    ["BigBatCave"]              = "GUANO_AREA",
    ["RockyLand"]               = "GUANO_AREA",
    ["ToadStoolTask2"]          = "GUANO_AREA",
    ["BatCloister"]             = "GUANO_AREA",

    -- MUSHROOM_AREA
    ["RedForest"]               = "MUSHROOM_AREA",
    ["GreenForest"]             = "MUSHROOM_AREA",
    ["BlueForest"]              = "MUSHROOM_AREA",
    ["FungalNoiseForest"]       = "MUSHROOM_AREA",
    ["FungalNoiseMeadow"]       = "MUSHROOM_AREA",

    -- CAVERN_AREA
    ["SpillagmiteCaverns"]      = "CAVERN_AREA",

    -- MOON_AREA
    ["MoonCaveForest"]          = "MOON_AREA",
    ["ArchiveMaze"]             = "MOON_AREA",

    -- VENT_AREA
    ["CentipedeCaveTask"]       = "VENT_AREA",
    ["CentipedeCaveIslandTask"] = "VENT_AREA",

    -- RUINS_AREA
    ["LichenLand"]              = "RUINS_AREA",
    ["Residential"]             = "RUINS_AREA",
    ["Military"]                = "RUINS_AREA",
    ["Sacred"]                  = "RUINS_AREA",
    ["TheLabyrinth"]            = "RUINS_AREA",
    ["SacredAltar"]             = "RUINS_AREA",
    ["AtriumMaze"]              = "RUINS_AREA",

    ["MoreAltars"]              = "RUINS_AREA",
    ["CaveJungle"]              = "RUINS_AREA",
    ["SacredDanger"]            = "RUINS_AREA",
    ["MilitaryPits"]            = "RUINS_AREA",
    ["MuddySacred"]             = "RUINS_AREA",
    ["Residential2"]            = "RUINS_AREA",
    ["Residential3"]            = "RUINS_AREA",

    -- MARSH_AREA
    ["SwampySinkhole"]          = "MARSH_AREA",
    ["CaveSwamp"]               = "MARSH_AREA",

    -- SINKHOLE_AREA
    ["UndergroundForest"]       = "SINKHOLE_AREA",
    ["PleasantSinkhole"]        = "SINKHOLE_AREA",
    ["RabbitTown"]              = "SINKHOLE_AREA",
    ["RabbitCity"]              = "SINKHOLE_AREA",
    ["SpiderLand"]              = "SINKHOLE_AREA",
    ["RabbitSpiderWar"]         = "SINKHOLE_AREA",

}

for i = 1, 10 do
    -- SINKHOLE_AREA
    TASKS_TO_LOOT_KEY["CaveExitTask"..i] = "SINKHOLE_AREA"
end

local AREA_MODIFIER_FNS = {
    ["VENT_AREA"] = function()
        local riftspawner = TheWorld.components.riftspawner
        if riftspawner and riftspawner:IsShadowPortalActive() then
            return "VENT_AREA_SHADOW_RIFT"
        end
    end,
}

local function CheckModifyLootArea(area)
    if AREA_MODIFIER_FNS[area] then
        return AREA_MODIFIER_FNS[area]() or area
    end

    return area
end

return {
    WEIGHTED_VINE_LOOT = WEIGHTED_VINE_LOOT,
    VINE_LOOT_DATA = VINE_LOOT_DATA,
    TASKS_TO_LOOT_KEY = TASKS_TO_LOOT_KEY,
    EXTRA_LOOT_MODIFIERS = EXTRA_LOOT_MODIFIERS,
    AREA_MODIFIER_FNS = AREA_MODIFIER_FNS,

    CheckModifyLootArea = CheckModifyLootArea,
}