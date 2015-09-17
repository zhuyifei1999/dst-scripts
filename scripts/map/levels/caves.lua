require("map/level")

----------------------------------
-- Cave levels
----------------------------------

-- AddLevel(LEVELTYPE.CAVE, {
-- 		id="CAVE_LEVEL_1",
-- 		name="CAVE_LEVEL_1",
-- 		overrides={
-- 			{"world_size", 		"tiny"},
-- 			-- {"day", 			"onlynight"}, 
-- 			{"waves", 			"off"},
-- 			{"location",		"cave"},
-- 			{"boons", 			"never"},
-- 			{"poi", 			"never"},
-- 			{"traps", 			"never"},
-- 			{"protected", 		"never"},
-- 			{"start_setpeice", 	"CaveStart"},
-- 			{"start_node",		"BGSinkholeRoom"},
-- 		},
-- 		tasks={
-- 			"CavesStart",
-- 			"CavesAlternateStart",
-- 			"FungalBatCave",
-- 			"BatCaves",
-- 			"TentacledCave",
-- 			"SingleBatCaveTask",
-- 			"RabbitsAndFungs",
-- 			"FungalPlain",
-- 			"Cavern",
-- 		},
-- 		numoptionaltasks = math.random(2,3),
-- 		optionaltasks = {
-- 			"CaveBase",
-- 			"MushBase",
-- 			"SinkBase",
-- 			"RabbitTown",
-- 			"RedFungalComplex",
-- 			"GreenFungalComplex",
-- 			"BlueFungalComplex",
-- 		},
-- 	})

-- AddLevel(LEVELTYPE.CAVE, {
-- 		id="CAVE_LEVEL_2",
-- 		name="CAVE_LEVEL_2",
-- 		overrides={
-- 			{"world_size", 		"tiny"},
-- 			{"day", 			"onlynight"}, 
-- 			{"waves", 			"off"},
-- 			{"location",		"cave"},
-- 			{"boons", 			"never"},
-- 			{"poi", 			"never"},
-- 			{"traps", 			"never"},
-- 			{"protected", 		"never"},
-- 			{"start_setpeice", 	"RuinsStart"},
-- 			{"start_node",		"BGWilds"},
-- 		},
-- 		tasks={
-- 			"RuinsStart",

-- 		},
-- 		numoptionaltasks = math.random(1,2),
-- 		optionaltasks = {
-- 			"MoreAltars",
-- 			"SacredDanger",
-- 			"FailedCamp",
-- 			"Residential2",
-- 			"Residential3",
-- 			"Military2",
-- 			"Sacred2",
-- 		},

-- 	})

AddLevel(LEVELTYPE.SURVIVAL, {
	id="DST_CAVE",
	name=STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS[12],
	desc= STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC[12],

	overrides={
        {"task_set",        "cave_default"},
        {"start_location",  "caves"},

		{"world_size", 		"large"},
		--{"day", 			"onlynight"}, 
		{"waves", 			"off"},
		{"location",		"cave"},
		{"boons", 			"never"},
		{"poi", 			"never"},
		{"traps", 			"never"},
		{"protected", 		"never"},
        {"layout_mode",     "RestrictNodesByKey"},
        {"wormhole_prefab", "tentacle_pillar" },
	},
})
