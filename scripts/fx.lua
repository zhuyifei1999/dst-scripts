local fx =
{
    {
        name = "sanity_raise",
        bank = "blocker_sanity_fx",
        build = "blocker_sanity_fx",
        anim = "raise",
        tintalpha = 0.5,
    },
    {
        name = "sanity_lower",
        bank = "blocker_sanity_fx",
        build = "blocker_sanity_fx",
        anim = "lower",
        tintalpha = 0.5,
    },
    {
        name = "die_fx",
        bank = "die_fx",
        build = "die",
        anim = "small",
        sound = "dontstarve/common/deathpoof",
        tint = Vector3(90/255, 66/255, 41/255),
    },
    --[[{
        name = "sparks_fx",
        bank = "sparks",
        build = "sparks",
        anim = { "sparks_1", "sparks_2", "sparks_3" },
    },]]
    {
        name = "lightning_rod_fx",
        bank = "lightning_rod_fx",
        build = "lightning_rod_fx",
        anim = "idle",
    },
    {
        name = "splash",
        bank = "splash",
        build = "splash",
        anim = "splash",
    },
    {
        name = "waterballoon_splash",
        bank = "waterballoon",
        build = "waterballoon",
        anim = "used",
    },
    {
        name = "spat_splat_fx",
        bank = "spat_splat",
        build = "spat_splat",
        anim = "idle",
    },
    {
        name = "spat_splash_fx_full",
        bank = "spat_splash",
        build = "spat_splash",
        anim = "full",
    },
    {
        name = "spat_splash_fx_med",
        bank = "spat_splash",
        build = "spat_splash",
        anim = "med",
    },
    {
        name = "spat_splash_fx_low",
        bank = "spat_splash",
        build = "spat_splash",
        anim = "low",
    },
    {
        name = "spat_splash_fx_melted", 
        bank = "spat_splash", 
        build = "spat_splash", 
        anim = "melted",
    },
    {
        name = "small_puff",
        bank = "small_puff",
        build = "smoke_puff_small",
        anim = "puff",
        sound = "dontstarve/common/deathpoof",
    },
    {
        name = "splash_ocean",
        bank = "splash",
        build = "splash_ocean",
        anim = "idle",
    },
    {
        name = "maxwell_smoke",
        bank = "max_fx",
        build = "max_fx",
        anim = "anim",
    },
    {
        name = "shovel_dirt",
        bank = "shovel_dirt",
        build = "shovel_dirt",
        anim = "anim",
    },
    {
        name = "mining_fx",
        bank = "mining_fx",
        build = "mining_fx",
        anim = "anim",
    },
    --[[{
        name = "pine_needles",
        bank = "pine_needles",
        build = "pine_needles",
        anim = "fall",
    },]]
    {
        name = "pine_needles_chop",
        bank = "pine_needles",
        build = "pine_needles",
        anim = "chop",
    },
    {
        name = "green_leaves_chop",
        bank = "tree_leaf_fx",
        build = "tree_leaf_fx_green",
        anim = "chop",
        sound = "dontstarve_DLC001/fall/leaf_rustle",
    },
    {
        name = "red_leaves_chop",
        bank = "tree_leaf_fx",
        build = "tree_leaf_fx_red",
        anim = "chop",
        sound = "dontstarve_DLC001/fall/leaf_rustle",
    },
    {
        name = "orange_leaves_chop",
        bank = "tree_leaf_fx",
        build = "tree_leaf_fx_orange",
        anim = "chop",
        sound = "dontstarve_DLC001/fall/leaf_rustle",
    },
    {
        name = "yellow_leaves_chop",
        bank = "tree_leaf_fx",
        build = "tree_leaf_fx_yellow",
        anim = "chop",
        sound = "dontstarve_DLC001/fall/leaf_rustle",
    },
    {
        name = "purple_leaves_chop",
        bank = "tree_monster_fx",
        build = "tree_monster_fx",
        anim = "chop",
        sound = "dontstarve_DLC001/fall/leaf_rustle",
    },
    {
        name = "green_leaves",
        bank = "tree_leaf_fx",
        build = "tree_leaf_fx_green",
        anim = "fall",
        sound = "dontstarve_DLC001/fall/leaf_rustle",
    },
    {
        name = "red_leaves",
        bank = "tree_leaf_fx",
        build = "tree_leaf_fx_red",
        anim = "fall",
        sound = "dontstarve_DLC001/fall/leaf_rustle",
    },
    {
        name = "orange_leaves",
        bank = "tree_leaf_fx",
        build = "tree_leaf_fx_orange",
        anim = "fall",
        sound = "dontstarve_DLC001/fall/leaf_rustle",
    },
    {
        name = "yellow_leaves",
        bank = "tree_leaf_fx",
        build = "tree_leaf_fx_yellow",
        anim = "fall",
        sound = "dontstarve_DLC001/fall/leaf_rustle",
    },
    {
        name = "purple_leaves",
        bank = "tree_monster_fx",
        build = "tree_monster_fx",
        anim = "fall",
        sound = "dontstarve_DLC001/fall/leaf_rustle",
    },
    {
        name = "dr_warm_loop_1",
        bank = "diviningrod_fx",
        build = "diviningrod_fx",
        anim = "warm_loop",
        tint = Vector3(105/255, 160/255, 255/255),
    },
    {
        name = "dr_warm_loop_2",
        bank = "diviningrod_fx",
        build = "diviningrod_fx",
        anim = "warm_loop",
        tint = Vector3(105/255, 182/255, 239/255),
    },
    {
        name = "dr_warmer_loop",
        bank = "diviningrod_fx",
        build = "diviningrod_fx",
        anim = "warmer_loop",
        tint = Vector3(255/255, 163/255, 26/255),
    },
    {
        name = "dr_hot_loop",
        bank = "diviningrod_fx",
        build = "diviningrod_fx",
        anim = "hot_loop",
        tint = Vector3(181/255, 32/255, 32/255),
    },
    {
        name = "statue_transition",
        bank = "statue_ruins_fx",
        build = "statue_ruins_fx",
        anim = "transform_nightmare",
        tintalpha = 0.6,
    },
    {
        name = "statue_transition_2",
        bank = "die_fx",
        build = "die",
        anim = "small",
        sound = "dontstarve/common/deathpoof",
        tint = Vector3(0, 0, 0),
        tintalpha = 0.6,
    },
    {
        name = "shadow_despawn",
        bank = "statue_ruins_fx",
        build = "statue_ruins_fx",
        anim = "transform_nightmare",
        sound = "dontstarve/maxwell/shadowmax_despawn",
        tintalpha = 0.6,
    },
    {
        name = "mole_move_fx",
        bank = "mole_fx",
        build = "mole_move_fx",
        anim = "move",
        nameoverride = STRINGS.NAMES.MOLE_UNDERGROUND,
        description = function(inst, viewer)
                        return GetString(viewer, "DESCRIBE", { "MOLE", "UNDERGROUND" })
                    end,
    },
    --[[{
        name = "sparklefx",
        bank = "sparklefx",
        build = "sparklefx",
        anim = "sparkle",
        sound = "dontstarve/common/chest_positive",
        tintalpha = 0.6,
    },]]
    {
        name = "chester_transform_fx",
        bank = "die_fx",
        build = "die",
        anim = "small",
    },
    {
        name = "emote_fx",
        bank = "emote_fx",
        build = "emote_fx",
        anim = "emote_fx",
        fn = function(inst) inst.AnimState:SetFinalOffset(1) end,
    },
    {
        name = "tears",
        bank = "tears_fx",
        build = "tears",
        anim = "tears_fx",
        fn = function(inst) inst.AnimState:SetFinalOffset(1) end,
    },
    {
        name = "spawn_fx_tiny",
        bank = "spawn_fx",
        build = "puff_spawning",
        anim = "tiny",
        sound = "dontstarve/common/spawn/spawnportal_spawnplayer",
    },
    {
        name = "spawn_fx_small",
        bank = "spawn_fx",
        build = "puff_spawning",
        anim = "small",
        sound = "dontstarve/common/spawn/spawnportal_spawnplayer",
    },
    {
        name = "spawn_fx_medium",
        bank = "spawn_fx",
        build = "puff_spawning",
        anim = "medium",
        sound = "dontstarve/common/spawn/spawnportal_spawnplayer",
    },
    --[[{
        name = "spawn_fx_large",
        bank = "spawn_fx",
        build = "puff_spawning",
        anim = "large",
        sound = "dontstarve/common/spawn/spawnportal_spawnplayer",
    },]]
    --[[{
        name = "spawn_fx_huge",
        bank = "spawn_fx",
        build = "puff_spawning",
        anim = "huge",
        sound = "dontstarve/common/spawn/spawnportal_spawnplayer",
    },]]
    {
        name = "splash_snow_fx",
        bank = "splash",
        build = "splash_snow",
        anim = "idle",
    },
    {
        name = "icespike_fx_1",
        bank = "deerclops_icespike",
        build = "deerclops_icespike",
        anim = "spike1",
        sound = "dontstarve/creatures/deerclops/ice_small",
    },
    {
        name = "icespike_fx_2",
        bank = "deerclops_icespike",
        build = "deerclops_icespike",
        anim = "spike2",
        sound = "dontstarve/creatures/deerclops/ice_small",
    },
    {
        name = "icespike_fx_3",
        bank = "deerclops_icespike",
        build = "deerclops_icespike",
        anim = "spike3",
        sound = "dontstarve/creatures/deerclops/ice_small",
    },
    {
        name = "icespike_fx_4",
        bank = "deerclops_icespike",
        build = "deerclops_icespike",
        anim = "spike4",
        sound = "dontstarve/creatures/deerclops/ice_small",
    },
    {
        name = "shock_fx",
        bank = "shock_fx",
        build = "shock_fx",
        anim = "shock",
        sound = "dontstarve_DLC001/common/shocked",
        fn = function(inst) inst.AnimState:SetFinalOffset(1) end,
    },
    {
        name = "groundpound_fx",
        bank = "bearger_ground_fx",
        build = "bearger_ground_fx",
        sound = "dontstarve_DLC001/creatures/bearger/dustpoof",
        anim = "idle",
    },
    {
        name = "firesplash_fx",
        bank = "dragonfly_ground_fx",
        build = "dragonfly_ground_fx",
        anim = "idle",
        bloom = true,
    },
    {
        name = "tauntfire_fx",
        bank = "dragonfly_fx",
        build = "dragonfly_fx",
        anim = "taunt",
        bloom = true,
    },
    {
        name = "attackfire_fx",
        bank = "dragonfly_fx",
        build = "dragonfly_fx",
        anim = "atk",
        bloom = true,
    },
    {
        name = "vomitfire_fx",
        bank = "dragonfly_fx",
        build = "dragonfly_fx",
        anim = "vomit",
        twofaced = true,
        bloom = true,
    },
    {
        name = "wathgrithr_spirit",
        bank = "wathgrithr_spirit",
        build = "wathgrithr_spirit",
        anim = "wathgrithr_spirit",
        sound = "dontstarve_DLC001/characters/wathgrithr/valhalla",
        sounddelay = .2,
    },
    {
        name = "lucy_ground_transform_fx",
        bank = "lucy_axe_fx",
        build = "axe_transform_fx",
        anim = "transform_ground",
    },
    {
        name = "lucy_transform_fx",
        bank = "lucy_axe_fx",
        build = "axe_transform_fx",
        anim = "transform_chop",
    },
    {
        name = "werebeaver_transform_fx",
        bank = "werebeaver_fx",
        build = "werebeaver_fx",
        anim = "transform_back",
    },
    {
        name = "attune_out_fx",
        bank = "attune_fx",
        build = "attune_fx",
        anim = "attune_out",
        sound = "dontstarve/ghost/ghost_haunt",
    },
    {
        name = "attune_in_fx",
        bank = "attune_fx",
        build = "attune_fx",
        anim = "attune_in",
        sound = "dontstarve/ghost/ghost_haunt",
    },
    {
        name = "attune_ghost_in_fx",
        bank = "attune_fx",
        build = "attune_fx",
        anim = "attune_ghost_in",
        sound = "dontstarve/ghost/ghost_haunt",
    },
    {
        name = "beefalo_transform_fx",
        bank = "beefalo_fx",
        build = "beefalo_fx",
        anim = "transform",
        --#TODO: this one
        sound = "dontstarve/ghost/ghost_haunt",
    },
    {
        name = "disease_puff",
        bank = "small_puff",
        build = "smoke_puff_small",
        anim = "puff",
        sound = "dontstarve/common/together/diseased/small",
    },
    {
        name = "disease_fx_small",
        bank = "disease_fx",
        build = "disease_fx",
        anim = "disease_small",
        sound = "dontstarve/common/together/diseased/small",
    },
    {
        name = "disease_fx",
        bank = "disease_fx",
        build = "disease_fx",
        anim = "disease",
        sound = "dontstarve/common/together/diseased/small",
    },
    {
        name = "disease_fx_tall",
        bank = "disease_fx",
        build = "disease_fx",
        anim = "disease_tall",
        sound = "dontstarve/common/together/diseased/big",
    },
}

if ACCOMPLISHMENTS_ENABLED then
    table.insert(fx, {
        name = "firework_fx",
        bank = "firework",
        build = "accomplishment_fireworks",
        anim = "single_firework",
        sound = "dontstarve/common/shrine/sadwork_fire",
        sound2 = "dontstarve/common/shrine/sadwork_explo",
        sounddelay2 = 26/30,
        fn = function() TheWorld:PushEvent("screenflash", .65) end,
        fntime = 26/30,
    })
    table.insert(fx, {
        name = "multifirework_fx",
        bank = "firework",
        build = "accomplishment_fireworks",
        anim = "multi_firework",
        sound = "dontstarve/common/shrine/sadwork_fire",
        sound2 = "dontstarve/common/shrine/firework_explo",
        sounddelay2 = 26/30,
        fn = function() TheWorld:PushEvent("screenflash", 1) end,
        fntime = 26/30,
    })
end

return fx
