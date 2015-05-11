PI = 3.14159
DEGREES = PI/180
FRAMES = 1/30
TILE_SCALE = 4

RESOLUTION_X = 1280
RESOLUTION_Y = 720

FACING_RIGHT = 0
FACING_UP = 1
FACING_LEFT = 2
FACING_DOWN = 3

-- Careful inserting into here. You will have to update game\render\RenderLayer.h
LAYER_BACKGROUND = 1
LAYER_WORLD_BACKGROUND = 2
LAYER_WORLD = 3
LAYER_WORLD_CEILING = 4
LAYER_FRONTEND = 6

ANCHOR_MIDDLE = 0
ANCHOR_LEFT = 1
ANCHOR_RIGHT = 2
ANCHOR_TOP = 1
ANCHOR_BOTTOM = 2

SCALEMODE_NONE = 0
SCALEMODE_FILLSCREEN = 1
SCALEMODE_PROPORTIONAL = 2
SCALEMODE_FIXEDPROPORTIONAL = 3
SCALEMODE_FIXEDSCREEN_NONDYNAMIC = 4

PHYSICS_TYPE_ANIMATION_CONTROLLED = 0
PHYSICS_TYPE_PHYSICS_CONTROLLED = 1


MOVE_UP = 1
MOVE_DOWN = 2
MOVE_LEFT = 3
MOVE_RIGHT = 4

NUM_CRAFTING_RECIPES = 10

--push priorities
STATIC_PRIORITY = 10000

-- Controls: 
-- Must match the Control enum in DontStarveInputHandler.h
-- Must match STRINGS.UI.CONTROLSSCREEN.CONTROLS

-- player action controls
CONTROL_PRIMARY = 0
CONTROL_SECONDARY = 1
CONTROL_ATTACK = 2
CONTROL_INSPECT = 3
CONTROL_ACTION = 4

-- player movement controls
CONTROL_MOVE_UP = 5
CONTROL_MOVE_DOWN = 6
CONTROL_MOVE_LEFT = 7
CONTROL_MOVE_RIGHT = 8

-- view controls
CONTROL_ZOOM_IN = 9
CONTROL_ZOOM_OUT = 10
CONTROL_ROTATE_LEFT = 11
CONTROL_ROTATE_RIGHT = 12


-- player movement controls
CONTROL_PAUSE = 13
CONTROL_MAP = 14
CONTROL_INV_1 = 15
CONTROL_INV_2 = 16
CONTROL_INV_3 = 17
CONTROL_INV_4 = 18
CONTROL_INV_5 = 19
CONTROL_INV_6 = 20
CONTROL_INV_7 = 21
CONTROL_INV_8 = 22
CONTROL_INV_9 = 23
CONTROL_INV_10 = 24

CONTROL_FOCUS_UP = 25
CONTROL_FOCUS_DOWN = 26
CONTROL_FOCUS_LEFT = 27
CONTROL_FOCUS_RIGHT = 28

CONTROL_ACCEPT = 29
CONTROL_CANCEL = 30
CONTROL_SCROLLBACK = 31
CONTROL_SCROLLFWD = 32

CONTROL_PREVVALUE = 33
CONTROL_NEXTVALUE = 34

CONTROL_SPLITSTACK = 35
CONTROL_TRADEITEM = 36
CONTROL_TRADESTACK = 37
CONTROL_FORCE_INSPECT = 38
CONTROL_FORCE_ATTACK = 39
CONTROL_FORCE_TRADE = 40
CONTROL_FORCE_STACK = 41

CONTROL_OPEN_DEBUG_CONSOLE = 42
CONTROL_TOGGLE_LOG = 43
CONTROL_TOGGLE_DEBUGRENDER = 44

CONTROL_OPEN_INVENTORY = 45
CONTROL_OPEN_CRAFTING = 46
CONTROL_INVENTORY_LEFT = 47
CONTROL_INVENTORY_RIGHT = 48
CONTROL_INVENTORY_UP = 49
CONTROL_INVENTORY_DOWN = 50
CONTROL_INVENTORY_EXAMINE = 51
CONTROL_INVENTORY_USEONSELF = 52
CONTROL_INVENTORY_USEONSCENE = 53
CONTROL_INVENTORY_DROP = 54
CONTROL_PUTSTACK = 55
CONTROL_CONTROLLER_ATTACK = 56
CONTROL_CONTROLLER_ACTION = 57
CONTROL_CONTROLLER_ALTACTION = 58
CONTROL_USE_ITEM_ON_ITEM = 59

CONTROL_MAP_ZOOM_IN = 60
CONTROL_MAP_ZOOM_OUT = 61

CONTROL_OPEN_DEBUG_MENU = 62

CONTROL_TOGGLE_SAY = 63
CONTROL_TOGGLE_WHISPER = 64
CONTROL_TOGGLE_SLASH_COMMAND = 65
CONTROL_TOGGLE_PLAYER_STATUS = 66
CONTROL_SHOW_PLAYER_STATUS = 67

CONTROL_MENU_MISC_1 = 68
CONTROL_MENU_MISC_2 = 69
CONTROL_MENU_MISC_3 = 70
CONTROL_MENU_MISC_4 = 71

CONTROL_CUSTOM_START = 100



KEY_TAB = 9
KEY_KP_PERIOD		= 266
KEY_KP_DIVIDE		= 267
KEY_KP_MULTIPLY		= 268
KEY_KP_MINUS		= 269
KEY_KP_PLUS			= 270
KEY_KP_ENTER		= 271
KEY_KP_EQUALS		= 272
KEY_MINUS = 45
KEY_EQUALS = 61
KEY_SPACE = 32
KEY_ENTER = 13
KEY_ESCAPE = 27
KEY_HOME = 278
KEY_INSERT = 277
KEY_DELETE = 127
KEY_END    = 279
KEY_PAUSE = 19
KEY_PRINT = 316
KEY_CAPSLOCK = 301
KEY_SCROLLOCK = 302
KEY_RSHIFT = 303 -- use KEY_SHIFT instead
KEY_LSHIFT = 304 -- use KEY_SHIFT instead
KEY_RCTRL = 305 -- use KEY_CTRL instead
KEY_LCTRL = 306 -- use KEY_CTRL instead
KEY_RALT = 307 -- use KEY_ALT instead
KEY_LALT = 308 -- use KEY_ALT instead
KEY_ALT = 400
KEY_CTRL = 401
KEY_SHIFT = 402
KEY_BACKSPACE = 8
KEY_PERIOD = 46
KEY_SLASH = 47
KEY_LEFTBRACKET	= 91
KEY_BACKSLASH	= 92
KEY_RIGHTBRACKET= 93
KEY_TILDE = 96
KEY_A = 97
KEY_B = 98
KEY_C = 99
KEY_D = 100
KEY_E = 101
KEY_F = 102
KEY_G = 103
KEY_H = 104
KEY_I = 105
KEY_J = 106
KEY_K = 107
KEY_L = 108
KEY_M = 109
KEY_N = 110
KEY_O = 111
KEY_P = 112
KEY_Q = 113
KEY_R = 114
KEY_S = 115
KEY_T = 116
KEY_U = 117
KEY_V = 118
KEY_W = 119
KEY_X = 120
KEY_Y = 121
KEY_Z = 122
KEY_F1 = 282
KEY_F2 = 283
KEY_F3 = 284
KEY_F4 = 285
KEY_F5 = 286
KEY_F6 = 287
KEY_F7 = 288
KEY_F8 = 289
KEY_F9 = 290
KEY_F10 = 291
KEY_F11 = 292
KEY_F12 = 293

KEY_UP			= 273
KEY_DOWN		= 274
KEY_RIGHT		= 275
KEY_LEFT		= 276
KEY_PAGEUP		= 280
KEY_PAGEDOWN	= 281

KEY_0 = 48
KEY_1 = 49
KEY_2 = 50
KEY_3 = 51
KEY_4 = 52
KEY_5 = 53
KEY_6 = 54
KEY_7 = 55
KEY_8 = 56
KEY_9 = 57

-- DO NOT use these for gameplay!
MOUSEBUTTON_LEFT = 1000
MOUSEBUTTON_RIGHT = 1001
MOUSEBUTTON_MIDDLE = 1002
MOUSEBUTTON_SCROLLUP = 1003
MOUSEBUTTON_SCROLLDOWN = 1004


GESTURE_ZOOM_IN = 900
GESTURE_ZOOM_OUT = 901
GESTURE_ROTATE_LEFT = 902
GESTURE_ROTATE_RIGHT = 903
GESTURE_MAX = 904

--Legacy table, not for DST
MAIN_CHARACTERLIST = 
{
	"wilson", "willow", "wolfgang", "wendy", "wx78", "wickerbottom", "woodie", "wes", "waxwell",
}

--Legacy table, not for DST
ROG_CHARACTERLIST =
{
	"wathgrithr", "webber",
}

DST_CHARACTERLIST =
{
	"wilson", "willow", "wolfgang", "wendy", "wx78", "wickerbottom", "wathgrithr", "webber",
}

MAINSCREEN_CHAR_1 = "corner_dude"
MAINSCREEN_CHAR_2 = "corner_dude"

MAINSCREEN_TOOL_LIST = 
{
	"swap_axe", "swap_spear", "swap_pickaxe", "swap_shovel", "swap_staffs", "swap_cane",
}

MAINSCREEN_TOOL_1 = "swap_axe"
MAINSCREEN_TOOL_2 = "swap_axe"

MAINSCREEN_TORSO_LIST = 
{
	"", "", "", "", "armor_wood", "armor_sweatervest", "torso_amulets", "armor_trunkvest_winter", "armor_ruins",
}

MAINSCREEN_TORSO_1 = ""
MAINSCREEN_TORSO_2 = ""

MAINSCREEN_HAT_LIST = 
{
	"", "", "", "", "hat_top", "hat_beefalo", "hat_football", "hat_winter", "hat_spider", "hat_bee",
}

MAINSCREEN_HAT_1 = ""
MAINSCREEN_HAT_2 = ""

MODCHARACTERLIST = 
{
	-- this gets populated by mods
}

CHARACTER_GENDERS = 
{
	FEMALE = {
		"willow",
		"wendy",
		"wickerbottom",
		"wathgrithr",
	},
	MALE = {
		"wilson",
		"woodie",
		"waxwell",
		"wolfgang",
		"wes",
		"webber",
	},
	ROBOT = {
		"wx78",
		"pyro",
	},
	NEUTRAL = {}, --empty, for modders to add to
	PLURAL = {}, --empty, for modders to add to
}

MAXITEMSLOTS = 15

EQUIPSLOTS=
{
    HANDS = "hands",
    HEAD = "head",
    BODY = "body",
}

ITEMTAG=
{
    FOOD = "food",
    MEAT = "meat",
    WEAPON = "weapon",
    TOOL = "tool",
    TREASURE = "treasure",
    FUEL = "fuel",
    FIRE = "fire",
    STACKABLE = "stackable",
    FX = "FX",
}

-- See map_painter.h
GROUND =
{
	INVALID = 255,
    IMPASSABLE = 1,
    
    ROAD = 2,
    ROCKY = 3,
    DIRT = 4,
	SAVANNA = 5,
	GRASS = 6,
	FOREST = 7,
	MARSH = 8,
	WEB = 9,
	WOODFLOOR = 10,
	CARPET = 11,
	CHECKER = 12,

	-- CAVES
	CAVE = 13,
	FUNGUS = 14,
	SINKHOLE = 15,
    UNDERROCK = 16,
    MUD = 17,
    BRICK = 18,
    BRICK_GLOW = 19,
    TILES = 20,
    TILES_GLOW = 21,
    TRIM = 22,
    TRIM_GLOW = 23,
	FUNGUSRED = 24,
	FUNGUSGREEN = 25,

	DECIDUOUS = 30,
	DESERT_DIRT = 31,

    -- Noise
    DIRT_NOISE = 123,
	ABYSS_NOISE = 124,
	GROUND_NOISE = 125,
	CAVE_NOISE = 126,
	FUNGUS_NOISE = 127,

	UNDERGROUND = 128,
	
	WALL_ROCKY = 151,
	WALL_DIRT = 152,
	WALL_MARSH = 153,
	WALL_CAVE = 154,
	WALL_FUNGUS = 155,
	WALL_SINKHOLE = 156,
	WALL_MUD = 157,
	WALL_TOP = 158,
	WALL_WOOD = 159,
	WALL_HUNESTONE = 160,
	WALL_HUNESTONE_GLOW = 161,
	WALL_STONEEYE = 162,
	WALL_STONEEYE_GLOW = 163,

--	STILL_WATER_SHALLOW = 130,
--	STILL_WATER_DEEP = 131,
--	MOVING_WATER_SHALLOW = 132,
--	MOVING_WATER_DEEP = 133,
--	SALT_WATER_SHALLOW = 134,
--	SALT_WATER_DEEP = 135,
}

TECH = {
	NONE = { SCIENCE = 0, MAGIC = 0, ANCIENT = 0 },
	SCIENCE_ONE = {SCIENCE = 1},
	SCIENCE_TWO = {SCIENCE = 2},
	SCIENCE_THREE = {SCIENCE = 3},
	-- Magic starts at level 2 so it's not teased from the start.
	MAGIC_TWO = {MAGIC = 2},
	MAGIC_THREE = {MAGIC = 3},

	LOST = {MAGIC = 10, SCIENCE = 10, ANCIENT = 10},

	ANCIENT_TWO = {ANCIENT = 2},
	ANCIENT_THREE = {ANCIENT = 3},
	ANCIENT_FOUR = {ANCIENT = 4},
}

-- See cell_data.h
NODE_TYPE =
{
	Default = 0, 
	Blank = 1, 
	Background = 2, 
	Random = 3, 
	Blocker = 4, 
	Room = 5,
}

-- See cell_data.h
NODE_INTERNAL_CONNECTION_TYPE =
{
	EdgeCentroid = 0, 
	EdgeSite = 1, 
	EdgeEdgeDirect = 2, 
	EdgeEdgeLeft = 3, 
	EdgeEdgeRight = 4, 
	EdgeData = 5,
}

CA_SEED_MODE =
{
	SEED_RANDOM = 0,
	SEED_CENTROID = 1,
	SEED_SITE = 2,
	SEED_WALLS = 3
}

-- See maze.h
MAZE_TYPE =
{
	MAZE_DFS_4WAY_META = 0,
	MAZE_DFS_4WAY = 1,
	MAZE_DFS_8WAY = 2,
	MAZE_GROWINGTREE_4WAY = 3,
	MAZE_GROWINGTREE_8WAY = 4,
	MAZE_GROWINGTREE_4WAY_INV = 5,
}

-- NORTH	1
-- EAST		2
-- SOUTH	4
-- WEST		8
--[[
Meta maze def:
5 room types:
4 way,	3 way,	2 way,	1 way,	L shape
	1,		4,		2,		4,		4
	15 tiles needed
--]]

MAZE_CELL_EXITS =
{
	NO_EXITS = 		0, -- Dont place a cell here.
	SINGLE_NORTH = 	1,
	SINGLE_EAST = 	2,
	L_NORTH = 		3,
	SINGLE_SOUTH = 	4,
	TUNNEL_NS = 	5,
	L_EAST = 		6,
	THREE_WAY_N = 	7,
	SINGLE_WEST = 	8,
	L_WEST = 		9,
	TUNNEL_EW =		10,
	THREE_WAY_W = 	11,
	L_SOUTH = 		12,
	THREE_WAY_S = 	13,
	THREE_WAY_E = 	14,
	FOUR_WAY = 		15,
}

MAZE_CELL_EXITS_INV =
{
	"SINGLE_NORTH",
	"SINGLE_EAST",
	"L_NORTH",
	"SINGLE_SOUTH",
	"TUNNEL_NS",
	"L_EAST",
	"THREE_WAY_N",
	"SINGLE_WEST",
	"L_WEST",
	"TUNNEL_EW",
	"THREE_WAY_W",
	"L_SOUTH" ,
	"THREE_WAY_S",
	"THREE_WAY_E",
	"FOUR_WAY",
}

LAYOUT =
{
	STATIC = 0,
	CIRCLE_EDGE = 1,
	CIRCLE_RANDOM = 2,
	GRID = 3,
	RECTANGLE_EDGE = 4,
	CIRCLE_FILLED = 5,
}

LAYOUT_POSITION =
{
	RANDOM = 0,
	CENTER = 1,
}

LAYOUT_ROTATION =
{
	NORTH = 0, 	-- 0 Degrees
	EAST = 1, 	-- 90 Degrees
	SOUTH = 2, 	-- 180 Degrees
	WEST = 3, 	-- 270 Degrees
}

PLACE_MASK = 
{
	NORMAL = 0,
	IGNORE_IMPASSABLE = 1,
	IGNORE_BARREN = 2,
	IGNORE_IMPASSABLE_BARREN = 3,
	IGNORE_RESERVED = 4,
	IGNORE_IMPASSABLE_RESERVED = 5,
	IGNORE_BARREN_RESERVED = 6,
	IGNORE_IMPASSABLE_BARREN_RESERVED = 7,
}

COLLISION =
{

    GROUND = 64, -- See BpWorld.cpp (ocean walls)
    LIMITS = 128,
    WORLD = 192, --limits and ground
    ITEMS = 256,
    OBSTACLES = 512,
    CHARACTERS = 1024,
    FLYERS = 2048,
    SANITY = 4096,
    SMALLOBSTACLES = 8192,	-- collide with characters but not giants
    GIANTS = 16384,	-- collide with obstacles but not small obstacles
}

BLENDMODE =
{
	Disabled = 0,
	AlphaBlended = 1,
	Additive = 2,
	Premultiplied = 3,
	InverseAlpha = 4,
}

ANIM_ORIENTATION =
{
	Default = 0,
	OnGround = 1,
}


RECIPETABS=
{
    TOOLS = {str = "TOOLS", sort=0, icon = "tab_tool.tex"},
    LIGHT = {str = "LIGHT", sort=1, icon = "tab_light.tex"},
    SURVIVAL = {str = "SURVIVAL", sort=2, icon = "tab_trap.tex"},
    FARM = {str = "FARM", sort=3, icon = "tab_farm.tex"},
    SCIENCE = {str = "SCIENCE", sort=4, icon = "tab_science.tex"},
    WAR = {str = "WAR", sort=5, icon = "tab_fight.tex"},
    TOWN = {str = "TOWN", sort=6, icon = "tab_build.tex"},
    REFINE = {str = "REFINE", sort=7, icon = "tab_refine.tex"},
    MAGIC = {str = "MAGIC", sort=8, icon = "tab_arcane.tex"},
    DRESS = {str = "DRESS", sort=9, icon = "tab_dress.tex"},
    ANCIENT = {str = "ANCIENT", sort = 10, icon = "tab_crafting_table.tex"},
}

CUSTOM_RECIPETABS =
{
    BOOKS = { str = "BOOKS", sort = 999, icon = "tab_book.tex" },
}

VERBOSITY =
{
	ERROR = 0,
	WARNING = 1,
	INFO = 2,
	DEBUG = 3,
}

RENDERPASS =
{
	Z = 0,
	BLOOM = 1,
	DEFAULT = 2,
}

NUM_TRINKETS = 13

SEASONS =
{
	AUTUMN = "autumn",
	WINTER = "winter",
	SPRING = "spring",
	SUMMER = "summer",
	CAVES = "caves",
}

RENDER_QUALITY = 
{
	LOW = 0,
	DEFAULT = 1,
	HIGH = 2,
}

CREATURE_SIZE =
{
	SMALL = 0,
	MEDIUM = 1,
	LARGE = 2,
}

ROAD_PARAMETERS =
{
	NUM_SUBDIVISIONS_PER_SEGMENT = 50,
	MIN_WIDTH = 2,
	MAX_WIDTH = 3,
	MIN_EDGE_WIDTH = 0.5,
	MAX_EDGE_WIDTH = 1,
	WIDTH_JITTER_SCALE=1,
}

local function RGB(r, g, b)
    return { r / 255, g / 255, b / 255, 1 }
end

BGCOLOURS =
{
	RED =          RGB(255, 89,  46 ),
	PURPLE =       RGB(184, 87,  198),
	YELLOW =       RGB(255, 196, 45 ),
	GREY =         RGB(75,  75,  75 ),
	FULL =         RGB(255, 255, 255),
}

PLAYERCOLOURS =
{
	BLUE =          RGB(149, 191, 242),
	--RED =           RGB(242, 99,  99 ), --RED redefined below
	YELLOW =        RGB(222, 222, 99 ),
	GREEN =         RGB(59,  222, 99 ),
	CORAL =         RGB(216, 60,  84 ),
	GRASS =         RGB(129, 168, 99 ),
	TEAL =          RGB(150, 206, 169),
	LAVENDER =      RGB(206, 145, 192),
	OTHERBLUE =     RGB(113, 125, 194),
	OTHERYELLOW =   RGB(205, 191, 121),
	FUSCHIA =       RGB(170, 85,  129),
	OTHERTEAL =     RGB(150, 201, 206),
	LIGHTORANGE =   RGB(206, 150, 100),
	ORANGE =        RGB(208, 120, 86 ),
	PURPLE =        RGB(125, 81,  156),

    --Colour theme to better match the world tones
    TOMATO =        RGB(205, 79,  57 ),
    TAN =           RGB(255, 165, 79 ),
    PLUM =          RGB(205, 150, 205),
    BURLYWOOD =     RGB(205, 170, 125),
    RED =           RGB(238, 99,  99 ),
    PERU =          RGB(205, 133, 63 ),
    DARKPLUM =      RGB(139, 102, 139),
    EGGSHELL =      RGB(252, 230, 201),
    SALMON =        RGB(255, 140, 105),
    CHOCOLATE =     RGB(255, 127, 36 ),
    VIOLETRED =     RGB(139, 71,  93 ),
    SANDYBROWN =    RGB(244, 164, 96 ),
    BROWN =         RGB(165, 42,  42 ),
    BISQUE =        RGB(205, 183, 158),
    PALEVIOLETRED = RGB(255, 130, 171),
    GOLDENROD =     RGB(255, 193, 37 ),
    ROSYBROWN =     RGB(255, 193, 193),
    LIGHTTHISTLE =  RGB(255, 225, 255),
    PINK =          RGB(255, 192, 203),
    LEMON =         RGB(255, 250, 205),
    FIREBRICK =     RGB(238, 44,  44 ),
    LIGHTGOLD =     RGB(255, 236, 139),
    MEDIUMPURPLE =  RGB(171, 130, 255),
    THISTLE =       RGB(205, 181, 205),
}
DEFAULT_PLAYER_COLOUR = RGB(153, 153, 153) -- GREY

SAY_COLOR =         RGB(255, 255, 255)
WHISPER_COLOR =     RGB(153, 153, 153)
TWITCH_COLOR  =     RGB(153, 153, 255)

MAX_CHAT_NAME_LENGTH = 13

WET_TEXT_COLOUR = RGB(149, 191, 242)
NORMAL_TEXT_COLOUR = RGB(255, 255, 255)

ROAD_STRIPS = 
{
	CORNERS = 0,
	ENDS = 1,
	EDGES = 2,
	CENTER = 3,
}

WRAP_MODE = 
{
	WRAP = 0,
	CLAMP = 1,
	MIRROR = 2,
	CLAMP_TO_EDGE = 3,
}

RESET_ACTION =
{
	LOAD_FRONTEND = 0,
	LOAD_SLOT = 1,
	LOAD_FILE = 2,
	DO_DEMO = 3,
	MODS_SCREEN_PUSH = 4,
}

HUD_ATLAS = "images/hud.xml"
UI_ATLAS = "images/ui.xml"

SNOW_THRESH = .015

VIBRATION_CAMERA_SHAKE = 0
VIBRATION_BLOOD_FLASH = 1
VIBRATION_BLOOD_OVER = 2

NUM_SAVE_SLOTS = 5

SAVELOAD = 
{    
    OPERATION = 
    {
        PREPARE = 0,
        LOAD = 1,
        SAVE = 2,
        DELETE = 3,
        NONE = 4,
    },
    
    STATUS = 
    {
        OK = 0,
        DAMAGED = 1,
        NOT_FOUND = 2,
        NO_SPACE = 3,
        FAILED = 4,
    },
}

--Extended for DST

MATERIALS =
{
    WOOD = "wood",
    STONE = "stone",
    HAY = "hay",
    THULECITE = "thulecite",
    GEM = "gem",
    GEARS = "gears",
    MOONROCK = "moonrock",
    ICE = "ice",
}

UPGRADETYPES =
{
	DEFAULT = "default",
	SPIDER = "spider",
}

LOCKTYPE =
{
    DOOR = "door",
    MAXWELL = "maxwell",
}

FUELTYPE =
{
    BURNABLE = "BURNABLE",
    USAGE = "USAGE",
    MAGIC = "MAGIC",
    CAVE = "CAVE",
    SPIDERHAT = "SPIDERHAT",
    NIGHTMARE = "NIGHTMARE",
    ONEMANBAND = "ONEMANBAND",
    PIGTORCH = "PIGTORCH",
    CHEMICAL = "CHEMICAL",
}

OCCUPANTTYPE =
{
    BIRD = "bird",
}

FOODTYPE =
{
    GENERIC = "GENERIC",
    MEAT = "MEAT",
    WOOD = "WOOD",
    VEGGIE = "VEGGIE",
    ELEMENTAL = "ELEMENTAL",
    GEARS = "GEARS",
    HORRIBLE = "HORRIBLE",
    INSECT = "INSECT",
    SEEDS = "SEEDS",
    BERRY = "BERRY", --hack for smallbird; berries are actually part of veggie
    RAW = "RAW", -- things which some animals can eat off the ground, but players need to cook
}

FOODGROUP =
{
    OMNI =
    {
        name = "OMNI",
        types =
        {
            FOODTYPE.MEAT,
            FOODTYPE.VEGGIE,
            FOODTYPE.INSECT,
            FOODTYPE.SEEDS,
            FOODTYPE.GENERIC,
        },
    },
    BERRIES_AND_SEEDS =
    {
        name = "BERRIES_AND_SEEDS",
        types =
        {
            FOODTYPE.SEEDS,
            FOODTYPE.BERRY,
        },
    },
    BEARGER =
    {
        name = "BEARGER",
        types =
        {
            FOODTYPE.MEAT,
            FOODTYPE.VEGGIE,
			FOODTYPE.BERRY,
			FOODTYPE.GENERIC,
        },
    },
    MOOSE =
    {
        name = "MOOSE",
        types =
        {
            FOODTYPE.MEAT,
            FOODTYPE.VEGGIE,
			FOODTYPE.SEEDS,
        },
    },
}

CONTAINERTEST =
{
    NONE = 0,
    COOKING = 1,
    PERISHABLE_FOOD = 2,
    TELEPORTATO = 3,
}

TOOLACTIONS =
{
    CHOP = true,
    DIG = true,
    HAMMER = true,
    MINE = true,
    NET = true,
    PLAY = true,
}

DEPLOYMODE =
{
    NONE = 0,
    DEFAULT = 1,
    ANYWHERE = 2,
    TURF = 3,
    PLANT = 4,
    WALL = 5,
}

DEPLOYSPACING =
{
    DEFAULT = 0,
    MEDIUM = 1,
    LESS = 2,
    NONE = 3,
}

DEPLOYSPACING_RADIUS =
{
    [DEPLOYSPACING.DEFAULT] = 2,
    [DEPLOYSPACING.MEDIUM] = 1,
    [DEPLOYSPACING.LESS] = .75,
    [DEPLOYSPACING.NONE] = 0,
}

DONT_STARVE_TOGETHER_APPID = 322330
DONT_STARVE_APPID = 219740
REIGN_OF_GIANTS_APPID = 282470

NUM_DST_SAVE_SLOTS = 5

-- keeping this here in case someone wants to mod it in. It won't be a default part of the game (or even an option), but we've already done the work
-- and someone might be able to do something cool with it.
HUMAN_MEAT_ENABLED = false

--Bit flags, currently supports up to 8
--Server may use these for things that clients need to know about
--other clients whose player entities may or may not be available
--e.g. Stuff that shows on the scoreboard
USERFLAGS =
{
    IS_GHOST			= 1,
    IS_AFK				= 2,
    CHARACTER_STATE_1	= 4,
    CHARACTER_STATE_2	= 8,
    -- = 16,
    -- = 32,
    -- = 64,
    -- = 128,
}

--Camera shake modes
CAMERASHAKE =
{
    FULL = 0,
    SIDE = 1,
    VERTICAL = 2,
}

--Badge/meter arrow sizes
RATE_SCALE =
{
    NEUTRAL = 0,
    INCREASE_HIGH = 1,
    INCREASE_MED = 2,
    INCREASE_LOW = 3,
    DECREASE_HIGH = 4,
    DECREASE_MED = 5,
    DECREASE_LOW = 6,
}

-- Twitch status codes
TWITCH = 
{
    UNDEFINED = -1,
    CHAT_CONNECTED = 0,
    CHAT_DISCONNECTED = 1,
    CHAT_CONNECT_FAILED = 2,
}