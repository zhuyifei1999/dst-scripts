local assets =
{
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
    Asset("IMAGE", "images/colour_cubes/purple_moon_cc.tex"),

    Asset("ANIM", "anim/snow.zip"),
    Asset("ANIM", "anim/lightning.zip"),
    Asset("ANIM", "anim/splash_ocean.zip"),
    Asset("ANIM", "anim/frozen.zip"),

    Asset("SOUND", "sound/forest_stream.fsb"),
    Asset("SOUND", "sound/amb_stream.fsb"),

    Asset("IMAGE", "levels/textures/snow.tex"),
    Asset("IMAGE", "levels/textures/mud.tex"),
    Asset("IMAGE", "images/wave.tex"),
}

local prefabs = 
{
    "world",
    "adventure_portal",
    "resurrectionstone",
    "deerclops",
    "bearger",
    "gravestone",
    "flower",
    "animal_track",
    "dirtpile",
    "beefaloherd",
    "beefalo",
    "penguinherd",
    "penguin_ice",
    "penguin",
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
    "reeds", 
    "mist",
    "snow",
    "rain",
    "pollen",
    "maxwellthrone",
    "maxwellendgame",
    "maxwelllight",
    "maxwelllock",
    "maxwellphonograph",
    "puppet_wilson",
    "puppet_willow",
    "puppet_wendy",
    "puppet_wickerbottom",
    "puppet_wolfgang",
    "puppet_wx78",
    "puppet_wes",
    "marblepillar",
    "marbletree",
    "statueharp",
    "statuemaxwell",
    "eyeplant",
    "lureplant",
    "purpleamulet",
    "monkey",
    "livingtree",
    "tumbleweed",
    "rock_ice",
    "catcoonden",
    "shadowmeteor",
    "meteorwarning",
    "warg",
    "spat",
    "multiplayer_portal",
    "lavae",
    "lava_pond",
    "scorchedground",
    "lavae_egg",
    "terrorbeak",
    "crawlinghorror",
    "creepyeyes",
    "shadowskittish",
    "shadowwatcher",
    "shadowhand",
}

local function fn()
    local inst = SpawnPrefab("world")
    inst.prefab = "forest"

    --Add waves
    local waves = inst.entity:AddWaveComponent()
    waves:SetRegionSize(40, 20)
    waves:SetRegionNumWaves(8)
    waves:SetWaveTexture("images/wave.tex")
    --See source\game\components\WaveRegion.h
    waves:SetWaveEffect("shaders/waves.ksh")
    --waves:SetWaveEffect("shaders/texture.ksh")
    waves:SetWaveSize(2048, 512)

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
    end

    if inst.ismastersim then
        --Spawners
        --inst:AddComponent("flowerspawner")
        inst:AddComponent("birdspawner")
        inst:AddComponent("butterflyspawner")
        inst:AddComponent("hounded")
        inst:AddComponent("worlddeciduoustreeupdater")
        inst:AddComponent("kramped")
        inst:AddComponent("frograin")
        inst:AddComponent("penguinspawner")
        inst:AddComponent("deerclopsspawner")
        inst:AddComponent("beargerspawner")
        inst:AddComponent("moosespawner")
        inst:AddComponent("hunter")
        inst:AddComponent("lureplantspawner")
        inst:AddComponent("shadowcreaturespawner")
        inst:AddComponent("shadowhandspawner")
        inst:AddComponent("wildfires")
        inst:AddComponent("worldwind")
        inst:AddComponent("forestresourcespawner")
        inst:AddComponent("regrowthmanager")
        inst:AddComponent("desolationspawner")
        if METRICS_ENABLED then
            inst:AddComponent("worldoverseer")
        end

        --world health management
        inst:AddComponent("skeletonsweeper")
    end

    return inst
end

return Prefab("forest", fn, assets, prefabs)
