
--[[
-- small fish 30 to 70ish
#	name				weight			COSTAL	SWELL	ROUGH	BRINEPOOL	HAZARDOUS		lures			Catching Behaviours
1	Runty Guppy			48.34, 60.30	++		++											SMALL_OMNI		put up an initial struggle and then very easy, slow, moves towards you when tired, pretty much a free catch
2	Needlenosed Squirt	37.54, 57.62	+++													SMALL_OMNI		fast, darting, lots of short bursts
3	Bitty Baitfish		39.66, 63.58	+		+		+									SMALL_MEAT		long bursts, low stamina drain
4	Smolt Fry			39.70, 56.26	++++												SMALL_OMNI		quick and easy catch
5	Popperfish			33.08, 47.74	+++													SMALL_VEGGIE	quick and easy catch

--pond fish weight 
fish	40.89, 55.28
eel		n/a for now?

-- medium fish 150 to 310ish
#	name				weight			COSTAL	SWELL	ROUGH	BRINEPOOL	HAZARDOUS		lures			Catching Behaviours
1	Mudfish				154.32, 214.97	++		+++											OMNI			easy-medium catch
2	Deep Bass			172.41, 228.88  		++		+++									MEAT			not a hard catch, doesn't like to fight, runs towards the fisher trying to unhook itself with line slack, a fun fight while on a boat with one sail active
3	Dandy Lionfish		246.77, 302.32					++					++++			MEAT			hard catch, short tired times and high run speed 
4	Black Catfish		193.27, 278.50			++		+++									OMNI			long slow pulls, totally not worth fishing, unless you want some braging rights
5	Corn Cod			161.48, 241.80			+++		++									VEGGIE			medium catch
]]

--[[ Catching Behaviours
-- default
num		walk	run		stam.drain	stam.recover	stam.struggle_time	stam.tired_time		tired_ang_good	tired_ang_good		
n/a		1.2		3		0.05		0.10			3+1		8+1			4+1		2+1			80				120				

-- small fish
num		walk	run		stam.drain	stam.recover	stam.struggle_time	stam.tired_time		tired_ang_good	tired_ang_low		
1		0.8		2.5		1.0			0.1				2+1		5+1			6+1		4+1			45				80				
2		1.5		3.0		0.1			0.5				1+2		3+2			1+2		1+1			80				120				
3		1.2		2.5		0.05		0.01			5+1		5+3			2+2		2+1			60				90				
4		1.2		2.0		0.5			0.5				1+1		3+1			5+1		3+1			80				120				
5		1.0		2.0		0.5			0.5				1+1		3+1			5+1		3+1			80				160				

-- medium fish
num		walk	run		stam.drain	stam.recover	stam.struggle_time	stam.tired_time		tired_ang_good	tired_ang_low		
1		1.2		3.0		0.05		0.10			3+1		6+1			3+1		2+1			80				120				
2		2.5		2.5		0.25		0.05			2+0		2+1			4+1		2+1			15				15				
3		2.2		3.5		0.1			0.25			4+2		6+2			1+1		1+0			45				90				
4		1.4		2.5		0.05		0.10			5+1		12+6		4+1		2+1			60				90				
5		1.3		2.8		0.05		0.10			3+1		8+1			4+1		2+1			80				120				

]]

local SCHOOL_SIZE = {
	TINY = 		{min=1,max=3},
	SMALL = 	{min=2,max=5},
	MEDIUM = 	{min=4,max=6},
	LARGE = 	{min=6,max=10},	
}

local SCHOOL_AREA = {
	TINY = 		2,
	SMALL = 	3,
	MEDIUM = 	6,
	LARGE = 	10,	
}

local WANDER_DIST = {
	SHORT = 	{min=5,max=15},
	MEDIUM = 	{min=15,max=30},
	LONG = 		{min=20,max=40},
}

local ARRIVE_DIST = {
	CLOSE = 	3,
	MEDIUM = 	8,
	FAR = 		12,
}

local WANDER_DELAY = {
	SHORT = 	{min=0,max=10},
	MEDIUM = 	{min=10,max=30},
	LONG = 		{min=30,max=60},
}

local SEG = 30
local DAY = SEG*16

local SCHOOL_WORLD_TIME = {
	SHORT = 	{min=SEG*8,max=SEG*16},
	MEDIUM = 	{min=DAY,max=DAY*2},	
	LONG = 		{min=DAY*2,max=DAY*4},
}

local LOOT = {
	TINY = 		{ "fishmeat_small" },
	SMALL = 	{ "fishmeat_small" },
	MEDIUM = 	{ "fishmeat" },
	LARGE = 	{ "fishmeat" },
	HUGE = 		{ "fishmeat" },
}

local COOKING_PRODUCT = {
	TINY = 		"fishmeat_small_cooked",
	SMALL = 	"fishmeat_small_cooked",
	MEDIUM = 	"fishmeat_cooked",
	LARGE = 	"fishmeat_cooked",
	HUGE = 		"fishmeat_cooked",
}

local DIET = {
	OMNI = { caneat = { FOODGROUP.OMNI } },--, preferseating = { FOODGROUP.OMNI } },
	VEGGIE = { caneat = { FOODGROUP.VEGETARIAN } },
	MEAT = { caneat = { FOODTYPE.MEAT } },
}

-- crokpot values
COOKER_INGREDIENT_SMALL = { meat = .5, fish = .5 }
COOKER_INGREDIENT_MEDIUM = { meat = 1, fish = 1 }

-- how long the player has to set the hook before it escapes
local SET_HOOK_TIME_SHORT = { base = 1, var = 0.5 }
local SET_HOOK_TIME_MEDIUM = { base = 2, var = 0.5 }

local BREACH_FX_SMALL = { "ocean_splash_small1", "ocean_splash_small2"}
local BREACH_FX_MEDIUM = { "ocean_splash_med1", "ocean_splash_med2"}

local FISH_DEFS = 
{
	-- Short wander distance
	-- large school
	oceanfish_small_1 = { 
	  	prefab = "oceanfish_small_1", 
	  	bank = "oceanfish_small", 
	  	build = "oceanfish_small_1",		
	  	weight_min = 48.34, 
	  	weight_max = 60.30, 

	  	walkspeed = 0.8,
	  	runspeed = 2.5,
		stamina =
		{
			drain_rate = 1.0,
			recover_rate = 0.1,
			struggle_times	= {low = 2, r_low = 1, high = 5, r_high = 1},
			tired_times		= {low = 6, r_low = 1, high = 4, r_high = 1},
			tiredout_angles = {has_tention = 45, low_tention = 80},
		},

	  	schoolmin = SCHOOL_SIZE.LARGE.min,
	  	schoolmax = SCHOOL_SIZE.LARGE.max,
	  	schoolrange = SCHOOL_AREA.TINY,	  
	  	schoollifetimemin = SCHOOL_WORLD_TIME.MEDIUM.min,
	  	schoollifetimemax = SCHOOL_WORLD_TIME.MEDIUM.max,

	  	herdwandermin = WANDER_DIST.SHORT.min,
	  	herdwandermax = WANDER_DIST.SHORT.max,
	  	herdarrivedist = ARRIVE_DIST.MEDIUM,
	  	herdwanderdelaymin = WANDER_DELAY.SHORT.min,
		herdwanderdelaymax = WANDER_DELAY.SHORT.max,
		
		set_hook_time = SET_HOOK_TIME_SHORT,
		breach_fx = BREACH_FX_SMALL,
		loot = LOOT.SMALL,
		cooking_product = COOKING_PRODUCT.SMALL,
        fishtype = "meat",

		lures = TUNING.OCEANFISH_LURE_PREFERENCE.SMALL_OMNI,
		diet = DIET.OMNI,
		cooker_ingredient_value = COOKER_INGREDIENT_SMALL, 
	},

	oceanfish_small_2 = { 
		prefab = "oceanfish_small_2", 
		bank = "oceanfish_small", 
		build = "oceanfish_small_2",		
	  	weight_min = 37.54, 
	  	weight_max = 57.62, 

	  	walkspeed = 1.5,
	  	runspeed = 3.0,
		stamina =
		{
			drain_rate = 0.1,
			recover_rate = 0.5,
			struggle_times	= {low = 1, r_low = 2, high = 3, r_high = 2},
			tired_times		= {low = 1, r_low = 2, high = 1, r_high = 1},
			tiredout_angles = {has_tention = 80, low_tention = 120},
		},

	  	schoolmin = SCHOOL_SIZE.MEDIUM.min,
	  	schoolmax = SCHOOL_SIZE.MEDIUM.max,
	  	schoolrange = SCHOOL_AREA.SMALL,		 		
	  	schoollifetimemin = SCHOOL_WORLD_TIME.MEDIUM.min,
	  	schoollifetimemax = SCHOOL_WORLD_TIME.MEDIUM.max,

	  	herdwandermin = WANDER_DIST.MEDIUM.min,
	  	herdwandermax = WANDER_DIST.MEDIUM.max,
	  	herdarrivedist = ARRIVE_DIST.MEDIUM,
	  	herdwanderdelaymin = WANDER_DELAY.SHORT.min,
		herdwanderdelaymax = WANDER_DELAY.SHORT.max,

		set_hook_time = SET_HOOK_TIME_MEDIUM,
		breach_fx = BREACH_FX_SMALL,
		loot = LOOT.SMALL,
		cooking_product = COOKING_PRODUCT.SMALL,
        fishtype = "meat",

		lures = TUNING.OCEANFISH_LURE_PREFERENCE.SMALL_OMNI,
		diet = DIET.OMNI,
		cooker_ingredient_value = COOKER_INGREDIENT_SMALL, 
	},

	oceanfish_small_3 = { 
		prefab = "oceanfish_small_3", 
		bank = "oceanfish_small", 
		build = "oceanfish_small_3",		
	  	weight_min = 39.66, 
	  	weight_max = 63.58, 

	  	walkspeed = 1.2,
	  	runspeed = 2.5,
		stamina =
		{
			drain_rate = 0.05,
			recover_rate = 0.01,
			struggle_times	= {low = 5, r_low = 1, high = 5, r_high = 3},
			tired_times		= {low = 2, r_low = 2, high = 2, r_high = 1},
			tiredout_angles = {has_tention = 60, low_tention = 90},
		},

	  	schoolmin = SCHOOL_SIZE.MEDIUM.min,
	  	schoolmax = SCHOOL_SIZE.MEDIUM.max,
	  	schoolrange = SCHOOL_AREA.SMALL,
	  	schoollifetimemin = SCHOOL_WORLD_TIME.MEDIUM.min,
	  	schoollifetimemax = SCHOOL_WORLD_TIME.MEDIUM.max,	

	  	herdwandermin = WANDER_DIST.MEDIUM.min,
	  	herdwandermax = WANDER_DIST.MEDIUM.max, 
	  	herdarrivedist = ARRIVE_DIST.MEDIUM,
	  	herdwanderdelaymin = WANDER_DELAY.LONG.min,
		herdwanderdelaymax = WANDER_DELAY.LONG.max,

		set_hook_time = SET_HOOK_TIME_SHORT,
		breach_fx = BREACH_FX_SMALL,
		loot = LOOT.SMALL,
		cooking_product = COOKING_PRODUCT.SMALL,
        fishtype = "meat",

		lures = TUNING.OCEANFISH_LURE_PREFERENCE.SMALL_MEAT,
		diet = DIET.MEAT,
		cooker_ingredient_value = COOKER_INGREDIENT_SMALL, 
	},

	oceanfish_small_4 = { 
		prefab = "oceanfish_small_4", 
		bank = "oceanfish_small", 
		build = "oceanfish_small_4",		
	  	weight_min = 39.70, 
	  	weight_max = 56.26, 

	  	walkspeed = 1.2,
	  	runspeed = 2.0,
		stamina =
		{
			drain_rate = 0.5,
			recover_rate = 0.5,
			struggle_times	= {low = 3, r_low = 0, high = 3, r_high = 1},
			tired_times		= {low = 5, r_low = 1, high = 3, r_high = 1},
			tiredout_angles = {has_tention = 80, low_tention = 120},
		},

	  	schoolmin = SCHOOL_SIZE.MEDIUM.min,
	  	schoolmax = SCHOOL_SIZE.MEDIUM.max,
	  	schoolrange = SCHOOL_AREA.SMALL,	
	  	schoollifetimemin = SCHOOL_WORLD_TIME.MEDIUM.min,
	  	schoollifetimemax = SCHOOL_WORLD_TIME.MEDIUM.max,

	  	herdwandermin = WANDER_DIST.MEDIUM.min,
	  	herdwandermax = WANDER_DIST.MEDIUM.max,
	  	herdarrivedist = ARRIVE_DIST.MEDIUM,	
	  	herdwanderdelaymin = WANDER_DELAY.SHORT.min,
		herdwanderdelaymax = WANDER_DELAY.SHORT.max,

		set_hook_time = SET_HOOK_TIME_MEDIUM,
		breach_fx = BREACH_FX_SMALL,
		loot = LOOT.SMALL,
		cooking_product = COOKING_PRODUCT.SMALL,
        fishtype = "meat",

		lures = TUNING.OCEANFISH_LURE_PREFERENCE.SMALL_OMNI,
		diet = DIET.OMNI,
		cooker_ingredient_value = COOKER_INGREDIENT_SMALL, 
	},

	oceanfish_small_5 = { 
		prefab = "oceanfish_small_5", 
		bank = "oceanfish_small", 
		build = "oceanfish_small_5",		
	  	weight_min = 33.08, 
	  	weight_max = 47.74, 

	  	walkspeed = 1.0,
	  	runspeed = 2.0,
		stamina =
		{
			drain_rate = 0.5,
			recover_rate = 0.5,
			struggle_times	= {low = 3, r_low = 0, high = 3, r_high = 1},
			tired_times		= {low = 5, r_low = 1, high = 3, r_high = 1},
			tiredout_angles = {has_tention = 80, low_tention = 160},
		},

	  	schoolmin = SCHOOL_SIZE.MEDIUM.min,
	  	schoolmax = SCHOOL_SIZE.MEDIUM.max,
	  	schoolrange = SCHOOL_AREA.SMALL,	
	  	schoollifetimemin = SCHOOL_WORLD_TIME.MEDIUM.min,
	  	schoollifetimemax = SCHOOL_WORLD_TIME.MEDIUM.max,

	  	herdwandermin = WANDER_DIST.MEDIUM.min,
	  	herdwandermax = WANDER_DIST.MEDIUM.max,
	  	herdarrivedist = ARRIVE_DIST.MEDIUM,	
	  	herdwanderdelaymin = WANDER_DELAY.SHORT.min,
		herdwanderdelaymax = WANDER_DELAY.SHORT.max,

		set_hook_time = SET_HOOK_TIME_MEDIUM,
		breach_fx = BREACH_FX_SMALL,
		loot = { "corn_cooked" },
		cooking_product = "corn_cooked",
        fishtype = "veggie",

		lures = TUNING.OCEANFISH_LURE_PREFERENCE.SMALL_VEGGIE,
		diet = DIET.VEGGIE,
		cooker_ingredient_value = {veggie=1}, 
	},

	oceanfish_medium_1 = { 
		prefab = "oceanfish_medium_1", 
		bank = "oceanfish_medium", 
		build = "oceanfish_medium_1",	
	  	weight_min = 154.32, 
	  	weight_max = 214.97, 

	  	walkspeed = 1.2,
	  	runspeed = 3.0,
		stamina =
		{
			drain_rate = 0.05,
			recover_rate = 0.1,
			struggle_times	= {low = 2, r_low = 1, high = 6, r_high = 1},
			tired_times		= {low = 3, r_low = 1, high = 2, r_high = 1},
			tiredout_angles = {has_tention = 80, low_tention = 120},
		},

	  	schoolmin = SCHOOL_SIZE.MEDIUM.min,
	  	schoolmax = SCHOOL_SIZE.MEDIUM.max,
	  	schoolrange = SCHOOL_AREA.SMALL,
	  	schoollifetimemin = SCHOOL_WORLD_TIME.MEDIUM.min,
	  	schoollifetimemax = SCHOOL_WORLD_TIME.MEDIUM.max,	

	  	herdwandermin = WANDER_DIST.MEDIUM.min,
	  	herdwandermax = WANDER_DIST.MEDIUM.max,
	  	herdarrivedist = ARRIVE_DIST.MEDIUM,	 
	  	herdwanderdelaymin = WANDER_DELAY.SHORT.min,
		herdwanderdelaymax = WANDER_DELAY.SHORT.max,

		set_hook_time = SET_HOOK_TIME_MEDIUM,
		breach_fx = BREACH_FX_MEDIUM,
		loot = LOOT.MEDIUM,
		cooking_product = COOKING_PRODUCT.MEDIUM,
        fishtype = "meat",

		lures = TUNING.OCEANFISH_LURE_PREFERENCE.OMNI,
		diet = DIET.OMNI,
		cooker_ingredient_value = COOKER_INGREDIENT_MEDIUM, 
	},

	oceanfish_medium_2 = { 
		prefab = "oceanfish_medium_2", 
		bank = "oceanfish_medium", 
		build = "oceanfish_medium_2",	
	  	weight_min = 172.41, 
	  	weight_max = 228.88, 

	  	walkspeed = 2.5,
	  	runspeed = 2.5,
		stamina =
		{
			drain_rate		= 0.25,
			recover_rate	= 0.05,
			struggle_times	= {low = 2, r_low = 0, high = 2, r_high = 1},
			tired_times		= {low = 4, r_low = 1, high = 2, r_high = 1},
			tiredout_angles = {has_tention = 15, low_tention = 15},
		},

	  	schoolmin = SCHOOL_SIZE.SMALL.min,
	  	schoolmax = SCHOOL_SIZE.SMALL.max,
	  	schoolrange = SCHOOL_AREA.MEDIUM,
	  	schoollifetimemin = SCHOOL_WORLD_TIME.MEDIUM.min,
	  	schoollifetimemax = SCHOOL_WORLD_TIME.MEDIUM.max,	

	  	herdwandermin = WANDER_DIST.LONG.min,
	  	herdwandermax = WANDER_DIST.LONG.max,
	  	herdarrivedist = ARRIVE_DIST.MEDIUM,	
	  	herdwanderdelaymin = WANDER_DELAY.LONG.min,
		herdwanderdelaymax = WANDER_DELAY.LONG.max,

		set_hook_time = SET_HOOK_TIME_MEDIUM,
		breach_fx = BREACH_FX_MEDIUM,
		loot = LOOT.MEDIUM,
		cooking_product = COOKING_PRODUCT.MEDIUM,
        fishtype = "meat",

		lures = TUNING.OCEANFISH_LURE_PREFERENCE.MEAT,
		diet = DIET.MEAT,
		cooker_ingredient_value = COOKER_INGREDIENT_MEDIUM, 
	},

	oceanfish_medium_3 = { 
		prefab = "oceanfish_medium_3", 
		bank = "oceanfish_medium", 
		build = "oceanfish_medium_3",	
	  	weight_min = 246.77, 
	  	weight_max = 302.32, 

	  	walkspeed = 2.2,
	  	runspeed = 3.5,
		stamina =
		{
			drain_rate = 0.1,
			recover_rate = 0.25,
			struggle_times	= {low = 4, r_low = 2, high = 6, r_high = 2},
			tired_times		= {low = 1, r_low = 1, high = 1, r_high = 0},
			tiredout_angles = {has_tention = 45, low_tention = 90},
		},

	  	schoolmin = SCHOOL_SIZE.MEDIUM.min,
	  	schoolmax = SCHOOL_SIZE.MEDIUM.max,
	  	schoolrange = SCHOOL_AREA.SMALL,
	  	schoollifetimemin = SCHOOL_WORLD_TIME.MEDIUM.min,
	  	schoollifetimemax = SCHOOL_WORLD_TIME.MEDIUM.max,

	  	herdwandermin = WANDER_DIST.MEDIUM.min,
	  	herdwandermax = WANDER_DIST.MEDIUM.max,
	  	herdarrivedist = ARRIVE_DIST.MEDIUM, 	
	  	herdwanderdelaymin = WANDER_DELAY.SHORT.min,
		herdwanderdelaymax = WANDER_DELAY.SHORT.max,

		set_hook_time = SET_HOOK_TIME_SHORT,
		breach_fx = BREACH_FX_MEDIUM,
		loot = LOOT.MEDIUM,
		cooking_product = COOKING_PRODUCT.MEDIUM,
        fishtype = "meat",

		lures = TUNING.OCEANFISH_LURE_PREFERENCE.MEAT,
		diet = DIET.MEAT,
		cooker_ingredient_value = COOKER_INGREDIENT_MEDIUM, 
	},

	-- mostly found in the ROUGH water
	oceanfish_medium_4 = { 
		prefab = "oceanfish_medium_4", 
		bank = "oceanfish_medium", 
		build = "oceanfish_medium_4",	
	  	weight_min = 193.27, 
	  	weight_max = 278.50, 

	  	walkspeed = 1.4,
	  	runspeed = 2.5,
		stamina =
		{
			drain_rate		= 0.02,
			recover_rate	= 0.10,
			struggle_times	= {low = 5, r_low = 1, high = 12, r_high = 6},
			tired_times		= {low = 4, r_low = 1, high = 2, r_high = 1},
			tiredout_angles = {has_tention = 60, low_tention = 90},
		},

	  	schoolmin = SCHOOL_SIZE.MEDIUM.min,
	  	schoolmax = SCHOOL_SIZE.MEDIUM.max,
	  	schoolrange = SCHOOL_AREA.SMALL,
	  	schoollifetimemin = SCHOOL_WORLD_TIME.MEDIUM.min,
	  	schoollifetimemax = SCHOOL_WORLD_TIME.MEDIUM.max,

	  	herdwandermin = WANDER_DIST.MEDIUM.min,
	  	herdwandermax = WANDER_DIST.MEDIUM.max,	 
	  	herdarrivedist = ARRIVE_DIST.MEDIUM,
	  	herdwanderdelaymin = WANDER_DELAY.SHORT.min,
		herdwanderdelaymax = WANDER_DELAY.SHORT.max,

		set_hook_time = SET_HOOK_TIME_SHORT,
		breach_fx = BREACH_FX_MEDIUM,
		loot = LOOT.MEDIUM,
		cooking_product = COOKING_PRODUCT.MEDIUM,
        fishtype = "meat",

		lures = TUNING.OCEANFISH_LURE_PREFERENCE.OMNI,
		diet = DIET.OMNI,
		cooker_ingredient_value = COOKER_INGREDIENT_MEDIUM, 
	},

	oceanfish_medium_5 = { 
		prefab = "oceanfish_medium_5", 
		bank = "oceanfish_medium", 
		build = "oceanfish_medium_5",	
	  	weight_min = 161.48, 
	  	weight_max = 241.80, 

	  	walkspeed = 1.3,
	  	runspeed = 2.8,
		stamina =
		{
			drain_rate = 0.05,
			recover_rate = 0.1,
			struggle_times	= {low = 3, r_low = 1, high = 8, r_high = 1},
			tired_times		= {low = 4, r_low = 1, high = 2, r_high = 1},
			tiredout_angles = {has_tention = 80, low_tention = 120},
		},

	  	schoolmin = SCHOOL_SIZE.MEDIUM.min,
	  	schoolmax = SCHOOL_SIZE.MEDIUM.max,
	  	schoolrange = SCHOOL_AREA.SMALL,
	  	schoollifetimemin = SCHOOL_WORLD_TIME.MEDIUM.min,
	  	schoollifetimemax = SCHOOL_WORLD_TIME.MEDIUM.max,	  	

	  	herdwandermin = WANDER_DIST.MEDIUM.min,
	  	herdwandermax = WANDER_DIST.MEDIUM.max,	 
	  	herdarrivedist = ARRIVE_DIST.MEDIUM,
	  	herdwanderdelaymin = WANDER_DELAY.SHORT.min,
		herdwanderdelaymax = WANDER_DELAY.SHORT.max,

		set_hook_time = SET_HOOK_TIME_SHORT,
		breach_fx = BREACH_FX_MEDIUM,
		loot = { "corn" },
		cooking_product = "corn_cooked",
        fishtype = "veggie",

		lures = TUNING.OCEANFISH_LURE_PREFERENCE.VEGGIE,
		diet = DIET.VEGGIE,
		cooker_ingredient_value = {veggie=1}, 
	},
--[[
	-- large school
	oceanfish_antchovy = { 
		prefab = "oceanfish_antchovy", 
		bank = "antchovy", 
		build = "antchovy",
	  	weight_min = WEIGHTS.TINY.min, 
	  	weight_max = WEIGHTS.TINY.max, 

	  	schoolmin = SCHOOL_SIZE.LARGE.min,
	  	schoolmax = SCHOOL_SIZE.LARGE.max,
	  	schoolrange = SCHOOL_AREA.MEDIUM,	
	  	schoollifetimemin = SCHOOL_WORLD_TIME.MEDIUM.min,
	  	schoollifetimemax = SCHOOL_WORLD_TIME.MEDIUM.max,	  	

	  	herdwandermin = WANDER_DIST.MEDIUM.min,
	  	herdwandermax = WANDER_DIST.MEDIUM.max,
	  	herdarrivedist = ARRIVE_DIST.MEDIUM,		
	  	herdwanderdelaymin = WANDER_DELAY.SHORT.min,
		herdwanderdelaymax = WANDER_DELAY.SHORT.max,

		set_hook_time = SET_HOOK_TIME_MEDIUM,
		breach_fx = BREACH_FX_SMALL,
		loot = LOOT.TINY,
		cooking_product = COOKING_PRODUCT.TINY,
	},
]]
}

local SCHOOL_VERY_COMMON		= 4
local SCHOOL_COMMON				= 2
local SCHOOL_UNCOMMON			= 1
local SCHOOL_RARE				= 0.25

local SCHOOL_WEIGHTS = {
	[SEASONS.AUTUMN] = {
	    [GROUND.OCEAN_COASTAL] = 
		{
	        oceanfish_small_1 = SCHOOL_UNCOMMON,
	        oceanfish_small_2 = SCHOOL_COMMON,
	        oceanfish_small_3 = SCHOOL_RARE,
	        oceanfish_small_4 = SCHOOL_VERY_COMMON,
	        oceanfish_small_5 = SCHOOL_COMMON,
	        oceanfish_medum_1 = SCHOOL_UNCOMMON,
	    },
	    [GROUND.OCEAN_COASTAL_SHORE] =
		{
	    },
	    [GROUND.OCEAN_SWELL] = 
		{
	        oceanfish_small_1 = SCHOOL_UNCOMMON,
	        oceanfish_small_3 = SCHOOL_RARE,
	        oceanfish_medium_1 = SCHOOL_COMMON,
	        oceanfish_medium_2 = SCHOOL_UNCOMMON,
	        oceanfish_medium_4 = SCHOOL_UNCOMMON,
	        oceanfish_medium_5 = SCHOOL_COMMON,
	    },
	    [GROUND.OCEAN_ROUGH] = 
		{
			oceanfish_small_3 = SCHOOL_RARE,
	        oceanfish_medium_2 = SCHOOL_COMMON,
			oceanfish_medium_3 = SCHOOL_UNCOMMON,
			oceanfish_medium_4 = SCHOOL_COMMON,
			oceanfish_medium_5 = SCHOOL_UNCOMMON,
		},
		[GROUND.OCEAN_BRINEPOOL] = 
		{
	    },
	    [GROUND.OCEAN_BRINEPOOL_SHORE] =
		{
	    },
	    [GROUND.OCEAN_HAZARDOUS] = 
		{
	        oceanfish_medium_3 = SCHOOL_VERY_COMMON,
		},
    },
}

SCHOOL_WEIGHTS[SEASONS.WINTER] = deepcopy(SCHOOL_WEIGHTS[SEASONS.AUTUMN])
SCHOOL_WEIGHTS[SEASONS.SPRING] = deepcopy(SCHOOL_WEIGHTS[SEASONS.AUTUMN])
SCHOOL_WEIGHTS[SEASONS.SUMMER] = deepcopy(SCHOOL_WEIGHTS[SEASONS.AUTUMN])

-- EXAMPLE OF EDITING THE SEASONAL data
--SCHOOL_WEIGHTS[SEASONS.WINTER][GROUND.OCEAN_COASTAL].oceanfish_medium_1 = 1
--SCHOOL_WEIGHTS[SEASONS.WINTER][GROUND.OCEAN_COASTAL].oceanfish_small_1 = nil
--SCHOOL_WEIGHTS[SEASONS.WINTER][GROUND.OCEAN_COASTAL_SHORE] = {
--	                                oceanfish_medium_4 = 10,
--	                            },



return {fish= FISH_DEFS,school = SCHOOL_WEIGHTS} 