require("map/level")

----------------------------------
-- Cave levels
----------------------------------


AddLevel(LEVELTYPE.SURVIVAL, {
        id="DST_CAVE",
        name=STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS[12],
        desc= STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC[12],
        location = "cave",
        hideinfrontend = false,

        overrides={
            {"task_set",        "cave_default"},
            {"start_location",  "caves"},

            --{"day",           "onlynight"},
            {"waves",           "off"},
            {"layout_mode",     "RestrictNodesByKey"},
            {"wormhole_prefab", "tentacle_pillar" },
        },
        background_node_range = {0,1},
        required_prefabs = {
            "multiplayer_portal",
        },
    })

AddLevel(LEVELTYPE.SURVIVAL, {
        id="DST_CAVE_PLUS",
        name=STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS[13],
        desc= STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC[13],
        location = "cave",
        hideinfrontend = false,
        
        overrides={
                {"task_set",        "cave_default"},
                {"start_location",  "caves"},

                {"boons",           "often"},
                {"cave_spiders",    "often"},
                {"berrybush",       "rare"},
                {"carrot",          "rare"},
                {"rabbits",         "rare"},
                {"flower_cave",     "rare"},
                {"wormlights",      "rare"},

                -- {"world_size",       "large"},   --large is now default, kept here for clarity   
                -- {"task_set",         "default"}, --don't need to specify default, kept here for clarity      

                {"waves",           "off"},
                {"layout_mode",     "RestrictNodesByKey"},
                {"wormhole_prefab", "tentacle_pillar" },
        },
        background_node_range = {0,1},
        required_prefabs = {
            "multiplayer_portal",
        },
    })
