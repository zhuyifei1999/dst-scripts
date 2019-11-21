require("prefabs/world")

local assets =
{
    Asset("SCRIPT", "scripts/prefabs/world.lua"),

    Asset("IMAGE", "images/colour_cubes/day05_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/dusk03_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/night03_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/snow_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/snowdusk_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/night04_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/summer_day_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/summer_dusk_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/summer_night_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/spring_day_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/spring_dusk_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/spring_night_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/insane_day_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/insane_dusk_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/insane_night_cc.tex"),
	Asset("IMAGE", "images/colour_cubes/lunacy_regular_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/purple_moon_cc.tex"),

    Asset("ANIM", "anim/snow.zip"),
    Asset("ANIM", "anim/lightning.zip"),

    Asset("SOUND", "sound/forest_stream.fsb"),
    Asset("SOUND", "sound/amb_stream.fsb"),    
    Asset("SOUND", "sound/turnoftides_music.fsb"),
    Asset("SOUND", "sound/turnoftides_amb.fsb"),

    Asset("IMAGE", "levels/textures/snow.tex"),
    Asset("IMAGE", "levels/textures/mud.tex"),
    Asset("IMAGE", "images/wave.tex"),
    Asset("IMAGE", "images/wave_shadow.tex"),

    Asset("PKGREF", "levels/models/waterfalls.bin"),

    Asset("ANIM", "anim/swimming_ripple.zip"), -- common water fx symbols

    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0001.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0003.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0004.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0002.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0005.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0006.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0007.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0008.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0009.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0010.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0011.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0012.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0013.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0014.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0015.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0016.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0017.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0018.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0019.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0020.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0021.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0022.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0023.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0024.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0025.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0026.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0027.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0028.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0029.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0030.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0031.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0032.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0033.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0034.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0035.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0036.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0037.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0038.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0039.tex"),
    Asset("IMAGE", "images/lunacy_corner_lunacy_corner0040.tex"),

    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0001.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0003.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0004.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0002.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0005.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0006.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0007.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0008.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0009.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0010.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0011.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0012.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0013.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0014.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0015.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0016.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0017.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0018.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0019.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0020.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0021.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0022.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0023.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0024.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0025.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0026.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0027.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0028.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0029.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0030.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0031.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0032.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0033.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0034.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0035.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0036.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0037.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0038.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0039.xml"),
    Asset("ATLAS", "images/lunacy_corner_lunacy_corner0040.xml"),

    Asset("IMAGE", "images/lunacy_over_lunacy_over0001.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0002.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0003.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0004.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0005.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0006.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0007.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0008.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0009.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0010.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0011.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0012.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0013.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0014.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0015.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0016.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0017.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0018.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0019.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0020.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0021.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0022.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0023.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0024.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0025.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0026.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0027.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0028.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0029.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0030.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0031.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0032.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0033.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0034.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0035.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0036.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0037.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0038.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0039.tex"),
    Asset("IMAGE", "images/lunacy_over_lunacy_over0040.tex"),    
    Asset("IMAGE", "images/lunacy_over_lunacy_over0041.tex"),    
    Asset("IMAGE", "images/lunacy_over_lunacy_over0042.tex"),    
    Asset("IMAGE", "images/lunacy_over_lunacy_over0043.tex"),    
    Asset("IMAGE", "images/lunacy_over_lunacy_over0044.tex"),  

    Asset("ATLAS", "images/lunacy_over_lunacy_over0001.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0002.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0003.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0004.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0005.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0006.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0007.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0008.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0009.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0010.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0011.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0012.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0013.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0014.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0015.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0016.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0017.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0018.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0019.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0020.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0021.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0022.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0023.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0024.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0025.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0026.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0027.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0028.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0029.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0030.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0031.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0032.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0033.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0034.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0035.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0036.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0037.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0038.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0039.xml"),
    Asset("ATLAS", "images/lunacy_over_lunacy_over0040.xml"),    
    Asset("ATLAS", "images/lunacy_over_lunacy_over0041.xml"),    
    Asset("ATLAS", "images/lunacy_over_lunacy_over0042.xml"),    
    Asset("ATLAS", "images/lunacy_over_lunacy_over0043.xml"),    
    Asset("ATLAS", "images/lunacy_over_lunacy_over0044.xml"),          
}

local prefabs =
{
    "cave",
    "forest_network",
    "adventure_portal",
    "resurrectionstone",
    "deer",
    "deerspawningground",
    "deerclops",
    "gravestone",
    "flower",
    "animal_track",
    "dirtpile",
    "beefaloherd",
    "beefalo",
    "penguinherd",
    "penguin_ice",
    "penguin",
    "mutated_penguin",
    "koalefant_summer",
    "koalefant_winter",
    "beehive",
    "wasphive",
    "walrus_camp",
    "pighead",
    "mermhead",
    "rabbithole",
    "molehill",
    "carrot_planted",
    "tentacle",
    "wormhole",
    "cave_entrance",
    "teleportato_base",
    "teleportato_ring",
    "teleportato_box",
    "teleportato_crank",
    "teleportato_potato",
    "pond", 
    "marsh_tree", 
    "marsh_bush", 
    "burnt_marsh_bush",
    "reeds", 
    "mist",
    "snow",
    "rain",
    "pollen",
    "marblepillar",
    "marbletree",
    "statueharp",
    "statuemaxwell",
    "beemine_maxwell",
    "trap_teeth_maxwell",
    "sculpture_knight",
    "sculpture_bishop",
    "sculpture_rook",
    "statue_marble",
    "eyeplant",
    "lureplant",
    "purpleamulet",
    "monkey",
    "livingtree",
	"livingtree_halloween",
	"livingtree_root",
    "tumbleweed",
    "rock_ice",
    "catcoonden",
    "shadowmeteor",
    "meteorwarning",
    "warg",
    "claywarg",
    "spat",
    "multiplayer_portal",
    "lavae",
    "lava_pond",
    "scorchedground",
    "scorched_skeleton",
    "lavae_egg",
    "terrorbeak",
    "crawlinghorror",
    "creepyeyes",
    "shadowskittish",
    "shadowwatcher",
    "shadowhand",
    "stagehand",
    "tumbleweedspawner",
    "meteorspawner",
    "dragonfly_spawner",
    "moose",
    "mossling",
    "bearger",
    "dragonfly",
    "chester",
    "grassgekko",
    "petrify_announce",
    "moonbase",
    "moonrock_pieces",
    "shadow_rook",
    "shadow_knight",
    "shadow_bishop",
    "beequeenhive",
    "klaus_sack",
    "antlion_spawner",
    "oasislake",
    "succulent_plant",
	"fish", -- the old fish, keeping this here for mod support

	-- ocean
    "boat",
    "wave_shimmer",
    "wave_shore",
    "seastack",
    "seastack_spawner_swell",
    "seastack_spawner_rough",
    "splash_sink",
	"bullkelp_plant",
	"bullkelp_beachedroot",
    "fishingnet",
    "antchovies_group",
    "driftwood_small1",
    "driftwood_small2",
    "driftwood_tall",
    "driftwood_log",
	"waterchest",
	"saltstack",
	"cookiecutter",
	"cookiecutter_spawner",
    "gnarwail",
    "malbatross",
    "squid",    

    -- moon island
	"gestalt",
	"moon_fissure",
    "hotspring",
    "rock_avocado_bush",
    "dead_sea_bones",
    "trap_starfish",
    "moon_tree",
	"moon_tree_blossom",
	"moonbutterfly",
    "moonglass_rock",
	"fruitdragon",
    "moonspiderden",
	"moon_altar_rock_idol",
	"moon_altar_rock_glass",
	"moon_altar_rock_seed",
    "carrat_planted",

	-- fish
	"oceanfish_shoalspawner",
	"fishschoolspawnblocker",
	"oceanfishableflotsam_water",
}

local FISH_DATA = require("prefabs/oceanfishdef")
for fish, _ in pairs(FISH_DATA.fish) do
    table.insert(prefabs, fish)
end

local monsters =
{
    { "hound", 4 },
    { "deerclops", 4 },
    { "bearger", 4 },
    { "krampus", 3 },
}
for i, v in ipairs(monsters) do
    for level = 1, v[2] do
        table.insert(prefabs, v[1].."warning_lvl"..tostring(level))
    end
end
monsters = nil

local houndspawn =
{
    base_prefab = "hound",
    winter_prefab = "icehound",
    summer_prefab = "firehound",

    attack_levels =
    {
        intro   = { warnduration = function() return 120 end, numspawns = function() return 2 end },
        light   = { warnduration = function() return 60 end, numspawns = function() return 2 + math.random(2) end },
        med     = { warnduration = function() return 45 end, numspawns = function() return 3 + math.random(3) end },
        heavy   = { warnduration = function() return 30 end, numspawns = function() return 4 + math.random(3) end },
        crazy   = { warnduration = function() return 30 end, numspawns = function() return 6 + math.random(4) end },
    },

    attack_delays =
    {
        rare        = function() return TUNING.TOTAL_DAY_TIME * 6, math.random() * TUNING.TOTAL_DAY_TIME * 7 end,
        occasional  = function() return TUNING.TOTAL_DAY_TIME * 4, math.random() * TUNING.TOTAL_DAY_TIME * 7 end,
        frequent    = function() return TUNING.TOTAL_DAY_TIME * 3, math.random() * TUNING.TOTAL_DAY_TIME * 5 end,
    },

    warning_speech = "ANNOUNCE_HOUNDS",

    --Key = time, Value = sound prefab
    warning_sound_thresholds =
    {
        { time = 30, sound =  "LVL4" },
        { time = 60, sound =  "LVL3" },
        { time = 90, sound =  "LVL2" },
        { time = 500, sound = "LVL1" },
    },
}

local function common_postinit(inst)
    --Add waves
    inst.entity:AddWaveComponent()
    inst.WaveComponent:SetWaveParams(13.5, 2.5, -7.5)    			-- wave texture u repeat, forward distance between waves
    inst.WaveComponent:SetWaveSize(80, 3.5)							-- wave mesh width and height
    inst.WaveComponent:SetWaveTexture("images/wave_shadow.tex")
    --See source\game\components\WaveRegion.h
    inst.WaveComponent:SetWaveEffect("shaders/waves.ksh")
    --inst.WaveComponent:SetWaveEffect("shaders/texture.ksh")

    --Initialize lua components
    inst:AddComponent("ambientlighting")

    --Dedicated server does not require these components
    --NOTE: ambient lighting is required by light watchers
    if not TheNet:IsDedicated() then
        inst:AddComponent("dynamicmusic")
        inst:AddComponent("ambientsound")
        inst:AddComponent("dsp")
        inst:AddComponent("colourcube")
        inst:AddComponent("hallucinations")        
        inst:AddComponent("wavemanager")

        inst.Map:SetTransparentOcean(true)
    end
end

local function master_postinit(inst)
    --Spawners
    inst:AddComponent("birdspawner")
    inst:AddComponent("butterflyspawner")
    inst:AddComponent("hounded")
    inst:AddComponent("schoolspawner")
    inst:AddComponent("squidspawner")

    inst.components.hounded:SetSpawnData(houndspawn)

    inst:AddComponent("worlddeciduoustreeupdater")
    inst:AddComponent("kramped")
    inst:AddComponent("frograin")
    inst:AddComponent("penguinspawner")
    inst:AddComponent("deerherdspawner")
    inst:AddComponent("deerherding")
    inst:AddComponent("klaussackspawner")
    inst:AddComponent("deerclopsspawner")
    inst:AddComponent("beargerspawner")
    inst:AddComponent("moosespawner")
    inst:AddComponent("hunter")
    inst:AddComponent("lureplantspawner")
    inst:AddComponent("shadowcreaturespawner")
    inst:AddComponent("shadowhandspawner")
    inst:AddComponent("brightmarespawner")
    inst:AddComponent("wildfires")
    inst:AddComponent("worldwind")
    inst:AddComponent("forestresourcespawner")
    inst:AddComponent("regrowthmanager")
    inst:AddComponent("desolationspawner")
    inst:AddComponent("forestpetrification")
    inst:AddComponent("chessunlocks")
    inst:AddComponent("retrofitforestmap_anr")
    inst:AddComponent("specialeventsetup")
    inst:AddComponent("townportalregistry")
    inst:AddComponent("sandstorms")
    inst:AddComponent("worldmeteorshower")
    inst:AddComponent("mermkingmanager")
    inst:AddComponent("malbatrossspawner")

    inst:AddComponent("flotsamgenerator")

    if METRICS_ENABLED then
        inst:AddComponent("worldoverseer")
    end
end

return MakeWorld("forest", prefabs, assets, common_postinit, master_postinit, {"forest"})
