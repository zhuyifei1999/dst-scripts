require("map/level")

----------------------------------
-- Cave levels
----------------------------------


AddLevel(LEVELTYPE.SURVIVAL, {
	id="DST_CAVE",
	name=STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS[12],
	desc= STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC[12],
    location = "cave",
    --#TODOCAVES: disabled temporarily for main branch ~gjans
    hideinfrontend = BRANCH~="dev",

	overrides={
        {"task_set",        "cave_default"},
        {"start_location",  "caves"},

		--{"day", 			"onlynight"}, 
		{"waves", 			"off"},
        {"layout_mode",     "RestrictNodesByKey"},
        {"wormhole_prefab", "tentacle_pillar" },
	},
    background_node_range = {0,1},
    required_prefabs = {
        "multiplayer_portal",
    },
})
