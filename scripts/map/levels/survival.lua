require("map/level")


----------------------------------
-- Survival levels
----------------------------------

AddLevel(LEVELTYPE.SURVIVAL, { 
		id = "SURVIVAL_TOGETHER",
		name = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS[10],
		desc = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC[10],
		overrides = {
			-- {"start_setpeice", 	"DefaultStart"}, --deprecated, kept here for clarity	
			-- {"start_node",		"Clearing"}, --deprecated, kept here for clarity	
			-- {"start_location", 	"default"}, --don't need to specify default, kept here for clarity	
			-- {"season_start",	"default"}, --don't need to specify default, kept here for clarity	
			-- {"world_size",		"large"}, --large is now default, kept here for clarity	
			{"cave_entrance",	"never"},
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
		},
	})

AddLevel(LEVELTYPE.SURVIVAL, { 
		id = "SURVIVAL_TOGETHER_CLASSIC",
		name = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS[11],
		desc = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC[11],
		overrides = {
			-- {"start_setpeice", 	"DefaultStart"},	--deprecated, kept here for clarity		
			-- {"start_node",		"Clearing"}, --deprecated, kept here for clarity	
			-- {"start_location", 	"default"} ,--don't need to specify default, kept here for clarity	
			-- {"season_start",	"default"}, --don't need to specify default, kept here for clarity	
			{"task_set", 		"classic"},

			-- {"world_size",		"large"}, --large is now default, kept here for clarity	
			{"cave_entrance",	"never"},

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
		},
	})
	
if PLATFORM == "PS4" then   -- boons and spiders at default values rather than "often"
AddLevel(LEVELTYPE.SURVIVAL, {
		id="SURVIVAL_DEFAULT_PLUS",
		name=STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS[2],
		desc= STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC[2],
		overrides={				
				-- {"start_setpeice", 	"DefaultPlusStart"},	 --deprecated, kept here for clarity		
				-- {"start_node",		{"DeepForest", "Forest", "SpiderForest", "Plain", "Rocky", "Marsh"}}, --deprecated, kept here for clarity		
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
		overrides={				
				-- {"start_setpeice", 	"DefaultPlusStart"},	  --deprecated, kept here for clarity		
				-- {"start_node",		{"DeepForest", "Forest", "SpiderForest", "Plain", "Rocky", "Marsh"}},  --deprecated, kept here for clarity		
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
			-- "teleportato_ring",  "teleportato_box",  "teleportato_crank", "teleportato_potato", "teleportato_base", "chester_eyebone", "adventure_portal"
		},
	})
end

AddLevel(LEVELTYPE.SURVIVAL, {
		id="COMPLETE_DARKNESS",
		name=STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS[3],
		desc= STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC[3],
		overrides={				
				-- {"start_setpeice", 	"DarknessStart"},	 --deprecated, kept here for clarity		
				-- {"start_node",		{"DeepForest", "Forest"}},	 --deprecated, kept here for clarity			
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
	})

	-- AddLevel(LEVELTYPE.SURVIVAL, { 
	-- 	id="SURVIVAL_CAVEPREVIEW",
	-- 	name=STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS[3],
	-- 	desc=STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC[3],
	-- 	overrides={
	-- 			{"start_setpeice", 	"CaveTestStart"},		
	-- 			{"start_node",		"Clearing"},
	-- 	},
	-- 	tasks = {
	-- 			"Make a pick",
	-- 			"Dig that rock",
	-- 			"Great Plains",
	-- 			"Squeltch",
	-- 			"Beeeees!",
	-- 			"Speak to the king",
	-- 			"Forest hunters",
	-- 	},
	-- 	numoptionaltasks = 4,
	-- 	optionaltasks = {
	-- 			"Befriend the pigs",
	-- 			"For a nice walk",
	-- 			"Kill the spiders",
	-- 			"Killer bees!",
	-- 			"Make a Beehat",
	-- 			"The hunters",
	-- 			"Magic meadow",
	-- 			"Frogs and bugs",
	-- 	},
	-- 	set_pieces = {
	-- 		["ResurrectionStone"] = { count=2, tasks={"Make a pick", "Dig that rock", "Great Plains", "Squeltch", "Beeeees!", "Speak to the king", "Forest hunters" } },
	-- 		["WormholeGrass"] = { count=8, tasks={"Make a pick", "Dig that rock", "Great Plains", "Squeltch", "Beeeees!", "Speak to the king", "Forest hunters", "Befriend the pigs", "For a nice walk", "Kill the spiders", "Killer bees!", "Make a Beehat", "The hunters", "Magic meadow", "Frogs and bugs"} },
	-- 	},
	-- })

	
