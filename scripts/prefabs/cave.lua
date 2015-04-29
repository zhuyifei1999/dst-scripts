local cave_prefabs =
{
    "world",
    "cave_exit",
    "slurtle",
    "snurtle",
    "slurtlehole",
    "warningshadow",
    "cavelight",
    "flower_cave",
    "ancient_altar",
    "ancient_altar_broken",
    "stalagmite",
    "stalagmite_tall",
    "bat",
    "mushtree_tall",
    "mushtree_medium",
    "mushtree_small",
    "cave_banana_tree",
    "spiderhole",
    "ground_chunks_breaking",
    "tentacle_pillar",
    "tentacle_pillar_arm",
    "batcave",
    "rockyherd",
    "cave_fern",
    "monkey",
    "monkeybarrel",
    "rock_light",
    "ruins_plate",
    "ruins_bowl",
    "ruins_chair",
    "ruins_chipbowl",
    "ruins_vase",
    "ruins_table",
    "ruins_rubble_table",
    "ruins_rubble_chair",
    "ruins_rubble_vase",
    "lichen",
    "cutlichen",
    "rook_nightmare",
    "bishop_nightmare",
    "knight_nightmare",
    "ruins_statue_head",
    "ruins_statue_head_nogem",
    "ruins_statue_mage",
    "ruins_statue_mage_nogem",
    "nightmarelight",
    "pillar_ruins",
    "pillar_algae",
    "pillar_cave",
    "pillar_stalactite",
    "worm",
    "fissure",
    "fissure_lower",
    "slurper",
    "minotaur",
    "monkeybarrel",
    "spider_dropper",

}

local assets =
{
    Asset("SOUND", "sound/cave_AMB.fsb"),
    Asset("SOUND", "sound/cave_mem.fsb"),
    Asset("IMAGE", "images/colour_cubes/caves_default.tex"),

    Asset("IMAGE", "images/colour_cubes/ruins_light_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/ruins_dim_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/ruins_dark_cc.tex"),

    Asset("IMAGE", "images/colour_cubes/fungus_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/sinkhole_cc.tex"),
}

local function fn()
    --V2C: WARNING:
    --This is not supported for DST, so there is no network
    --component added yet! It just spawns it locally on the
    --server and then removes it on the next frame.
    if true then
        local inst = CreateEntity()
        inst.entity:Hide()
        inst:DoTaskInTime(0, inst.Remove)
        return inst
    end
    --    

    local inst = SpawnPrefab("world")
    inst:AddTag("cave")
    inst.prefab = "cave"

    --cave specifics
    inst:AddComponent("clock")
    inst:AddComponent("quaker")
    inst:AddComponent("seasons")
    inst.components.seasons:SetCaves()
    inst:AddComponent("colourcubemanager")

    inst:AddComponent("periodicthreat")
    local threats = require("periodicthreats")
    inst.components.periodicthreat:AddThreat("WORM", threats["WORM"])

    --add waves
    --local waves = inst.entity:AddWaveComponent()
    --[[waves:SetRegionSize( 32, 16 )
    waves:SetRegionNumWaves( 6 )
    waves:SetWaveTexture( "images/wave.tex" )
    waves:SetWaveEffect( "shaders/texture.ksh" )
    waves:SetWaveSize( 2048, 512 )--]]

    inst.components.ambientsoundmixer:SetReverbPreset("cave")

    return inst
end

return Prefab("cave", fn, assets, cave_prefabs)