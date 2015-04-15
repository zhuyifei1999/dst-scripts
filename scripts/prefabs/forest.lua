local assets =
{
    Asset("IMAGE", "images/colour_cubes/day05_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/dusk03_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/night03_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/snow_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/snowdusk_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/night04_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/insane_day_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/insane_dusk_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/insane_night_cc.tex"),

    Asset("ANIM", "anim/snow.zip"),
    Asset("ANIM", "anim/lightning.zip"),
    Asset("ANIM", "anim/splash_ocean.zip"),
    Asset("ANIM", "anim/frozen.zip"),

    Asset("SOUND", "sound/forest_stream.fsb"),
    Asset("IMAGE", "levels/textures/snow.tex"),
    Asset("IMAGE", "images/wave.tex"),
}

local prefabs = 
{
    "world",
    "adventure_portal",
    "resurrectionstone",
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
    "koalefant_summer",
    "koalefant_winter",
    "beehive",
    "wasphive",
    "walrus_camp",
    "pighead",
    "mermhead",
    "rabbithole",
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
    "shadowmeteor",
    "meteorwarning",
    "warg",
    "spat",
    "multiplayer_portal",
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
        inst:AddComponent("colourcube")
        inst:AddComponent("hallucinations")
    end

    if inst.ismastersim then
        --Spawners
        inst:AddComponent("birdspawner")
        inst:AddComponent("butterflyspawner")
        inst:AddComponent("hounded")
        inst:AddComponent("kramped")
        --inst:AddComponent("frograin") --Adventure mode not supported in DST
        inst:AddComponent("penguinspawner")
        inst:AddComponent("basehassler")
        inst:AddComponent("hunter")
        inst:AddComponent("lureplantspawner")
        inst:AddComponent("shadowcreaturespawner")
        inst:AddComponent("shadowhandspawner")
        inst:AddComponent("forestresourcespawner")

        if METRICS_ENABLED then
            inst:AddComponent("worldoverseer")
        end

        --world health management
        inst:AddComponent("skeletonsweeper")
    end

    inst.Map:SetOverlayTexture("levels/textures/snow.tex")

    return inst
end

return Prefab("forest", fn, assets, prefabs)