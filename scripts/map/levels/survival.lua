require("map/level")


----------------------------------
-- Survival levels
----------------------------------

AddLevel(LEVELTYPE.SURVIVAL, { 
		id = "SURVIVAL_TOGETHER",
		name = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS[10],
		desc = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC[10],
        location = "forest",
		overrides = {
			-- {"start_location", 	"default"}, --don't need to specify default, kept here for clarity	
			-- {"season_start",	"default"}, --don't need to specify default, kept here for clarity	
			-- {"world_size",		"large"}, --large is now default, kept here for clarity	
			-- {"task_set", 		"default"},	 --don't need to specify default, kept here for clarity	
		},		
		numrandom_set_pieces = 5,
		random_set_pieces = 
		{
			"Chessy_1",
			"Chessy_2",
			"Chessy_3",
			"Chessy_4",
			"Chessy_5",
			"Chessy_6",
			"ChessSpot1",
			"ChessSpot2",
			"ChessSpot3",
			"Maxwell1",
			"Maxwell2",
			"Maxwell3",
			"Maxwell4",
			"Maxwell5",
			"Maxwell6",
			"Maxwell7",
			"Warzone_1",
			"Warzone_2",
			"Warzone_3",
		},
		ordered_story_setpieces = {
		},
		required_prefabs = {
            "multiplayer_portal",
		},
	})

AddLevel(LEVELTYPE.SURVIVAL, { 
		id = "SURVIVAL_TOGETHER_CLASSIC",
		name = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS[11],
		desc = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC[11],
        location = "forest",
		overrides = {
			-- {"start_location", 	"default"} ,--don't need to specify default, kept here for clarity	
			-- {"season_start",	"default"}, --don't need to specify default, kept here for clarity	
			{"task_set", 		"classic"},
			-- {"world_size",		"large"}, --large is now default, kept here for clarity	

            {"spring",			"noseason"},
            {"summer",			"noseason"},
            {"bearger",			"never"},
            {"goosemoose",		"never"},
            {"dragonfly",		"never"},
            {"deciduousmonster","never"},

            {"buzzard",			"never"},
            {"catcoon",			"never"},
            {"moles",			"never"},
            {"lightninggoat",	"never"},
            {"houndmound",		"never"},

            {"rock_ice",		"never"},
            {"cactus",			"never"},

            {"frograin",		"never"},
            {"wildfires",		"never"},
		},		
		numrandom_set_pieces = 5,
		random_set_pieces = 
		{
			"Chessy_1",
			"Chessy_2",
			"Chessy_3",
			"Chessy_4",
			"Chessy_5",
			"Chessy_6",
			"ChessSpot1",
			"ChessSpot2",
			"ChessSpot3",
			"Maxwell1",
			"Maxwell2",
			"Maxwell3",
			"Maxwell4",
			"Maxwell5",
			"Maxwell6",
			"Maxwell7",
			"Warzone_1",
			"Warzone_2",
			"Warzone_3",
		},
		ordered_story_setpieces = {
		},
		required_prefabs = {
            "multiplayer_portal",
		},
	})


if PLATFORM == "PS4" then   -- boons and spiders at default values rather than "often"
AddLevel(LEVELTYPE.SURVIVAL, {
		id="SURVIVAL_DEFAULT_PLUS",
		name=STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS[2],
		desc= STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC[2],
        location = "forest",
		overrides={				
				{"start_location", 	"plus"},
				{"berrybush", 		"rare"},
				{"carrot", 			"rare"},
				{"rabbits", 		"rare"},
				-- {"world_size",		"large"}, --large is now default, kept here for clarity	
				-- {"task_set", 		"default"},			--don't need to specify default, kept here for clarity		
		},
		numrandom_set_pieces = 5,
		random_set_pieces = 
		{
			"Chessy_1",
			"Chessy_2",
			"Chessy_3",
			"Chessy_4",
			"Chessy_5",
			"Chessy_6",
			"ChessSpot1",
			"ChessSpot2",
			"ChessSpot3",
			"Maxwell1",
			"Maxwell2",
			"Maxwell3",
			"Maxwell4",
			"Maxwell5",
			"Maxwell6",
			"Maxwell7",
			"Warzone_1",
			"Warzone_2",
			"Warzone_3",
		},

		ordered_story_setpieces = {
			"TeleportatoRingLayout",
			"TeleportatoBoxLayout",
			"TeleportatoCrankLayout",
			"TeleportatoPotatoLayout",
			"AdventurePortalLayout",
			"TeleportatoBaseLayout",
		},
		required_prefabs = {
			"teleportato_ring",  "teleportato_box",  "teleportato_crank", "teleportato_potato", "teleportato_base", "chester_eyebone", "adventure_portal"
		},
	})
else
AddLevel(LEVELTYPE.SURVIVAL, {
		id="SURVIVAL_DEFAULT_PLUS",
		name=STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS[2],
		desc= STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC[2],
        location = "forest",
		overrides={				
				{"start_location", 	"plus"},
				{"boons", 			"often"},				
				{"spiders", 		"often"},
				{"berrybush", 		"rare"},
				{"carrot", 			"rare"},
				{"rabbits", 		"rare"},
				-- {"world_size",		"large"},	--large is now default, kept here for clarity	
				-- {"task_set", 		"default"}, --don't need to specify default, kept here for clarity		
		},
		numrandom_set_pieces = 5,
		random_set_pieces = 
		{
			"Chessy_1",
			"Chessy_2",
			"Chessy_3",
			"Chessy_4",
			"Chessy_5",
			"Chessy_6",
			"ChessSpot1",
			"ChessSpot2",
			"ChessSpot3",
			"Maxwell1",
			"Maxwell2",
			"Maxwell3",
			"Maxwell4",
			"Maxwell5",
			"Maxwell6",
			"Maxwell7",
			"Warzone_1",
			"Warzone_2",
			"Warzone_3",
		},

		ordered_story_setpieces = {
			-- "TeleportatoRingLayout",
			-- "TeleportatoBoxLayout",
			-- "TeleportatoCrankLayout",
			-- "TeleportatoPotatoLayout",
			-- "AdventurePortalLayout",
			-- "TeleportatoBaseLayout",
		},
		required_prefabs = {
            "multiplayer_portal",
		},
	})
end

AddLevel(LEVELTYPE.SURVIVAL, {
		id="COMPLETE_DARKNESS",
		name=STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS[3],
		desc= STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC[3],
        location = "forest",
		overrides={				
				{"start_location",  "darkness"},
				{"day", 			"onlynight"}, 
				-- {"world_size",		"large"}, --large is now default, kept here for clarity	
				-- {"task_set", 		"default"},  --don't need to specify default, kept here for clarity		
		},		
		numrandom_set_pieces = 5,
		random_set_pieces = 
		{
			"Chessy_1",
			"Chessy_2",
			"Chessy_3",
			"Chessy_4",
			"Chessy_5",
			"Chessy_6",
			"ChessSpot1",
			"ChessSpot2",
			"ChessSpot3",
			"Maxwell1",
			"Maxwell2",
			"Maxwell3",
			"Maxwell4",
			"Maxwell5",
			"Maxwell6",
			"Maxwell7",
			"Warzone_1",
			"Warzone_2",
			"Warzone_3",
		},
		required_prefabs = {
            "multiplayer_portal",
		},
	})

	
