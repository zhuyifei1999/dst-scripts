--local tuning_backups = {}

local function OverrideTuningVariables(tuning)
    for k, v in pairs(tuning) do
        --tuning_backups[k] = TUNING[k] 
        TUNING[k] = v
    end
end

--[[
local function ResetTuningVariables()
    for k, v in pairs(tuning_backups) do
        TUNING[k] = v
    end
end
--]]

local SPAWN_MODE_FN =
{
    never = "SpawnModeNever",
    always = "SpawnModeHeavy",
    often = "SpawnModeMed",
    rare = "SpawnModeLight",
}

local function SetSpawnMode(spawner, difficulty)
    if spawner then
        spawner[SPAWN_MODE_FN[difficulty]](spawner)
    end
end

return
{
    hounds = function(difficulty)
        SetSpawnMode(TheWorld.components.hounded, difficulty)
    end,

    deerclops = function(difficulty)
        local basehassler = TheWorld.components.basehassler
        if basehassler then
            if difficulty == "never" then
                basehassler:OverrideAttacksPerSeason("DEERCLOPS", 0)
                basehassler:OverrideAttackDuringOffSeason("DEERCLOPS", false)
            elseif difficulty == "rare" then
                basehassler:OverrideAttacksPerSeason("DEERCLOPS", 1)
                basehassler:OverrideAttackDuringOffSeason("DEERCLOPS", false)
            elseif difficulty == "often" then
                basehassler:OverrideAttacksPerSeason("DEERCLOPS", 2)
                basehassler:OverrideAttackDuringOffSeason("DEERCLOPS", false)
            elseif difficulty == "always" then
                basehassler:OverrideAttacksPerSeason("DEERCLOPS", 3)
                basehassler:OverrideAttackDuringOffSeason("DEERCLOPS", true)
            end
        end
    end,

    perd = function(difficulty)
        local tuning_vars =
        {
            never = { PERD_SPAWNCHANCE = 0, PERD_ATTACK_PERIOD = 1 },
            rare = { PERD_SPAWNCHANCE = .1, PERD_ATTACK_PERIOD = 1 },
            often = { PERD_SPAWNCHANCE = .2, PERD_ATTACK_PERIOD = 1 },
            always = { PERD_SPAWNCHANCE = .4, PERD_ATTACK_PERIOD = 1 },
        }
        OverrideTuningVariables(tuning_vars[difficulty])
    end,

    hunt = function(difficulty)
        local tuning_vars =
        {
            never = { HUNT_COOLDOWN = -1, HUNT_COOLDOWNDEVIATION = 0, HUNT_RESET_TIME = 0, HUNT_SPRING_RESET_TIME = -1 },
            rare = { HUNT_COOLDOWN = TUNING.TOTAL_DAY_TIME * 2.4, HUNT_COOLDOWNDEVIATION = TUNING.TOTAL_DAY_TIME * .3, HUNT_RESET_TIME = 5, HUNT_SPRING_RESET_TIME = TUNING.TOTAL_DAY_TIME * 5 },
            often = { HUNT_COOLDOWN = TUNING.TOTAL_DAY_TIME * .6, HUNT_COOLDOWNDEVIATION = TUNING.TOTAL_DAY_TIME * .3, HUNT_RESET_TIME = 5, HUNT_SPRING_RESET_TIME = TUNING.TOTAL_DAY_TIME * 2 },
            always = { HUNT_COOLDOWN = TUNING.TOTAL_DAY_TIME * .3, HUNT_COOLDOWNDEVIATION = TUNING.TOTAL_DAY_TIME * .2, HUNT_RESET_TIME = 5, HUNT_SPRING_RESET_TIME = TUNING.TOTAL_DAY_TIME * 1 },
        }
        OverrideTuningVariables(tuning_vars[difficulty])
    end,

    alternatehunt = function(difficulty)
        local tuning_vars =
        {
            never = { HUNT_ALTERNATE_BEAST_CHANCE_MIN = 0, HUNT_ALTERNATE_BEAST_CHANCE_MAX = 0 },
            rare = { HUNT_ALTERNATE_BEAST_CHANCE_MIN = TUNING.HUNT_ALTERNATE_BEAST_CHANCE_MIN * 0.25, HUNT_ALTERNATE_BEAST_CHANCE_MAX = TUNING.HUNT_ALTERNATE_BEAST_CHANCE_MAX * 0.25 },
            often = { HUNT_ALTERNATE_BEAST_CHANCE_MIN = TUNING.HUNT_ALTERNATE_BEAST_CHANCE_MIN * 2, HUNT_ALTERNATE_BEAST_CHANCE_MAX = TUNING.HUNT_ALTERNATE_BEAST_CHANCE_MAX * 2 },
            always = { HUNT_ALTERNATE_BEAST_CHANCE_MIN = 0.7, HUNT_ALTERNATE_BEAST_CHANCE_MAX = 0.9 },
        }
        OverrideTuningVariables(tuning_vars[difficulty])
    end,

	krampus = function(difficulty)
        local tuning_vars =
        {
            never = { KRAMPUS_THRESHOLD = -1, KRAMPUS_THRESHOLD_VARIATION = 0, KRAMPUS_INCREASE_LVL1 = -1, KRAMPUS_INCREASE_LVL2 = -1, KRAMPUS_INCREASE_RAMP = -1, KRAMPUS_NAUGHTINESS_DECAY_PERIOD = 1 },
            rare = { KRAMPUS_THRESHOLD = 45, KRAMPUS_THRESHOLD_VARIATION = 30, KRAMPUS_INCREASE_LVL1 = 75, KRAMPUS_INCREASE_LVL2 = 125, KRAMPUS_INCREASE_RAMP = 1, KRAMPUS_NAUGHTINESS_DECAY_PERIOD = 30 },
            often = { KRAMPUS_THRESHOLD = 20, KRAMPUS_THRESHOLD_VARIATION = 15, KRAMPUS_INCREASE_LVL1 = 37, KRAMPUS_INCREASE_LVL2 = 75, KRAMPUS_INCREASE_RAMP = 3, KRAMPUS_NAUGHTINESS_DECAY_PERIOD = 90 },
            always = { KRAMPUS_THRESHOLD = 10, KRAMPUS_THRESHOLD_VARIATION = 5, KRAMPUS_INCREASE_LVL1 = 25, KRAMPUS_INCREASE_LVL2 = 50, KRAMPUS_INCREASE_RAMP = 4, KRAMPUS_NAUGHTINESS_DECAY_PERIOD = 120 },
        }
        OverrideTuningVariables(tuning_vars[difficulty])
    end,

    butterfly = function(difficulty)
        SetSpawnMode(TheWorld.components.butterflyspawner, difficulty)
    end,

    birds = function(difficulty)
        SetSpawnMode(TheWorld.components.birdspawner, difficulty)
    end,

    penguins = function(difficulty)
        SetSpawnMode(TheWorld.components.penguinspawner, difficulty)
    end,

    lureplants = function(difficulty)
        SetSpawnMode(TheWorld.components.lureplantspawner, difficulty)
    end,

    beefaloheat = function(difficulty)
        local tuning_vars =
        {
            never = { BEEFALO_MATING_SEASON_LENGTH = 0, BEEFALO_MATING_SEASON_WAIT = -1 },
            rare = { BEEFALO_MATING_SEASON_LENGTH = 2, BEEFALO_MATING_SEASON_WAIT = 18 },
            often = { BEEFALO_MATING_SEASON_LENGTH = 4, BEEFALO_MATING_SEASON_WAIT = 6 },
            always = { BEEFALO_MATING_SEASON_LENGTH = -1, BEEFALO_MATING_SEASON_WAIT = 0 },
        }
        OverrideTuningVariables(tuning_vars[difficulty])
    end,

    liefs = function(difficulty)
        local tuning_vars =
        {
            never = { LEIF_MIN_DAY = 9999, LEIF_PERCENT_CHANCE = 0 },
            rare = { LEIF_MIN_DAY = 5, LEIF_PERCENT_CHANCE = 1 / 100 },
            often = { LEIF_MIN_DAY = 2, LEIF_PERCENT_CHANCE = 1 / 70 },
            always = { LEIF_MIN_DAY = 1, LEIF_PERCENT_CHANCE = 1 / 55 },
        }
        OverrideTuningVariables(tuning_vars[difficulty])
    end,

    day = function(difficulty)
        local lookup =
        {
            onlyday =
            {
                summer = { day = 16, dusk = 0, night = 0 },
            },
            onlydusk =
            {
                summer = { day = 0, dusk = 16, night = 0 },
            },
            onlynight =
            {
                summer = { day = 0, dusk = 0, night = 16 },
            },
            default =
            {
                summer = { day = 10, dusk = 2, night = 4 },
                winter = { day = 6, dusk = 5, night = 5 },
            },
            longday =
            {
                summer = { day = 14, dusk = 1, night = 1 },
                winter = { day = 13, dusk = 1, night = 2 },
            },
            longdusk =
            {
                summer = { day = 7, dusk = 6, night = 3 },
                winter = { day = 3, dusk = 8, night = 5 },
            },
            longnight =
            {
                summer ={ day = 5, dusk = 2, night = 9 },
                winter ={ day = 2, dusk = 2, night = 12 },
            },
        }
        TheWorld:PushEvent("ms_setseasonclocksegs", lookup[difficulty])
    end,

    season = function(difficulty)
        if difficulty == "preonlywinter" then
            TheWorld:PushEvent("ms_setseasonmode", "endless")
            TheWorld:PushEvent("ms_setseason", "summer")
        elseif difficulty == "preonlysummer" then
            TheWorld:PushEvent("ms_setseasonmode", "endless")
            TheWorld:PushEvent("ms_setseason", "winter")
        elseif difficulty == "onlysummer" then
            TheWorld:PushEvent("ms_setseasonmode", "always")
            TheWorld:PushEvent("ms_setseason", "summer")
        elseif difficulty == "onlywinter" then
            TheWorld:PushEvent("ms_setseasonmode", "always")
            TheWorld:PushEvent("ms_setseason", "summer")
        else
            local lookup =
            {
                longsummer = { summer = 50, winter = 10 },
                longwinter = { summer = 10, winter = 50 },
                longboth = { summer = 50, winter = 50 },
                shortboth = { summer = 10, winter = 10 },
                autumn = { summer = 5, winter = 3 },
                spring = { summer = 3, winter = 5 },
            }
            TheWorld:PushEvent("ms_setseasonlengths", lookup[difficulty])
        end
    end,

    season_start = function(difficulty)
        if difficulty == "summer" then
            TheWorld:PushEvent("ms_setseason", "summer")
            TheWorld:PushEvent("ms_setsnowlevel", 0)
        else
            TheWorld:PushEvent("ms_setseason", "winter")
            TheWorld:PushEvent("ms_setsnowlevel", 1)
        end
    end,

    weather = function(difficulty)
        if difficulty == "never" then
            TheWorld:PushEvent("ms_setprecipmode", "never")
        elseif difficulty == "rare" then
            TheWorld:PushEvent("ms_setmoisturescale", .5)
        elseif difficulty == "often" then
            TheWorld:PushEvent("ms_setmoisturescale", 2)
        elseif difficulty == "squall" then
            TheWorld:PushEvent("ms_setmoisturescale", 30)
        elseif difficulty == "always" then
            TheWorld:PushEvent("ms_setprecipmode", "always")
        end
    end,

    lightning = function(difficulty)
        if difficulty == "never" then
            TheWorld:PushEvent("ms_setlightningmode", "never")
            TheWorld:PushEvent("ms_setlightningdelay", {})
        elseif difficulty == "rare" then
            TheWorld:PushEvent("ms_setlightningmode", "rain")
            TheWorld:PushEvent("ms_setlightningdelay", { min = 60, max = 90 })
        elseif difficulty == "often" then
            TheWorld:PushEvent("ms_setlightningmode", "any")
            TheWorld:PushEvent("ms_setlightningdelay", { min = 10, max = 20 })
        elseif difficulty == "always" then
            TheWorld:PushEvent("ms_setlightningmode", "always")
            TheWorld:PushEvent("ms_setlightningdelay", { min = 10, max = 30 })
        end
    end,

    creepyeyes = function(difficulty)
        local tuning_vars =
        {
            always =
            {
                CREEPY_EYES =
                {
                    { maxsanity = 1, maxeyes = 6 },
                },
            },
        }
        OverrideTuningVariables(tuning_vars[difficulty])
    end,

    areaambient = function(data)
        -- HACK HACK HACK
        local world = TheWorld
        world:PushEvent("overrideambientsound", { tile = GROUND.ROAD, override = data })
        world:PushEvent("overrideambientsound", { tile = GROUND.ROAD, override = data })
        world:PushEvent("overrideambientsound", { tile = GROUND.ROCKY, override = data })
        world:PushEvent("overrideambientsound", { tile = GROUND.DIRT, override = data })
        world:PushEvent("overrideambientsound", { tile = GROUND.WOODFLOOR, override = data })
        world:PushEvent("overrideambientsound", { tile = GROUND.GRASS, override = data })
        world:PushEvent("overrideambientsound", { tile = GROUND.SAVANNA, override = data })
        world:PushEvent("overrideambientsound", { tile = GROUND.FOREST, override = data })
        world:PushEvent("overrideambientsound", { tile = GROUND.MARSH, override = data })
        world:PushEvent("overrideambientsound", { tile = GROUND.IMPASSABLE, override = data })
    end,

    areaambientdefault = function(data)
        local world = TheWorld
        if data == "cave" then
            -- Clear out the above ground (forest) sounds
            world:PushEvent("overrideambientsound", { tile = GROUND.ROAD, override = "SINKHOLE" })
            world:PushEvent("overrideambientsound", { tile = GROUND.ROCKY, override = "SINKHOLE" })
            world:PushEvent("overrideambientsound", { tile = GROUND.DIRT, override = "SINKHOLE" })
            world:PushEvent("overrideambientsound", { tile = GROUND.WOODFLOOR, override = "SINKHOLE" })
            world:PushEvent("overrideambientsound", { tile = GROUND.SAVANNA, override = "SINKHOLE" })
            world:PushEvent("overrideambientsound", { tile = GROUND.GRASS, override = "SINKHOLE" })
            world:PushEvent("overrideambientsound", { tile = GROUND.FOREST, override = "SINKHOLE" })
            world:PushEvent("overrideambientsound", { tile = GROUND.CHECKER, override = "SINKHOLE" })
            world:PushEvent("overrideambientsound", { tile = GROUND.MARSH, override = "SINKHOLE" })
            world:PushEvent("overrideambientsound", { tile = GROUND.IMPASSABLE, override = "ABYSS" })
        else
            -- Clear out the cave sounds
            world:PushEvent("overrideambientsound", { tile = GROUND.CAVE, override = "ROCKY" })
            world:PushEvent("overrideambientsound", { tile = GROUND.FUNGUSRED, override = "ROCKY" })
            world:PushEvent("overrideambientsound", { tile = GROUND.FUNGUSGREEN, override = "ROCKY" })
            world:PushEvent("overrideambientsound", { tile = GROUND.FUNGUS, override = "ROCKY" })
            world:PushEvent("overrideambientsound", { tile = GROUND.SINKHOLE, override = "ROCKY" })
            world:PushEvent("overrideambientsound", { tile = GROUND.UNDERROCK, override = "ROCKY" })
            world:PushEvent("overrideambientsound", { tile = GROUND.MUD, override = "ROCKY" })
            world:PushEvent("overrideambientsound", { tile = GROUND.UNDERGROUND, override = "ROCKY" })
            world:PushEvent("overrideambientsound", { tile = GROUND.BRICK, override = "ROCKY" })
            world:PushEvent("overrideambientsound", { tile = GROUND.BRICK_GLOW, override = "ROCKY" })
            world:PushEvent("overrideambientsound", { tile = GROUND.TILES, override = "ROCKY" })
            world:PushEvent("overrideambientsound", { tile = GROUND.TILES_GLOW, override = "ROCKY" })
            world:PushEvent("overrideambientsound", { tile = GROUND.TRIM, override = "ROCKY" })
            world:PushEvent("overrideambientsound", { tile = GROUND.TRIM_GLOW, override = "ROCKY" })
        end
    end,

        meteorshowers = function(difficulty)
        local tuning_vars =
        {
            never = 
            { 
                METEOR_SHOWER_LVL1_BASETIME = 0,
                METEOR_SHOWER_LVL1_VARTIME = 0,
                METEOR_SHOWER_LVL2_BASETIME = 0,
                METEOR_SHOWER_LVL2_VARTIME = 0,
                METEOR_SHOWER_LVL3_BASETIME = 0,
                METEOR_SHOWER_LVL3_VARTIME = 0,

                METEOR_SHOWER_LVL1_DURATION_BASE = 0,
                METEOR_SHOWER_LVL1_DURATIONVAR_MIN = 0,
                METEOR_SHOWER_LVL1_DURATIONVAR_MAX = 0,
                METEOR_SHOWER_LVL1_METEORSPERSEC_MIN = 0,
                METEOR_SHOWER_LVL1_METEORSPERSEC_MAX = 0,
                METEOR_SHOWER_LVL1_MEDMETEORS_MIN = 0,
                METEOR_SHOWER_LVL1_MEDMETEORS_MAX = 0,
                METEOR_SHOWER_LVL1_LRGMETEORS_MIN = 0,
                METEOR_SHOWER_LVL1_LRGMETEORS_MAX = 0,

                METEOR_SHOWER_LVL2_DURATION_BASE = 0,
                METEOR_SHOWER_LVL2_DURATIONVAR_MIN = 0,
                METEOR_SHOWER_LVL2_DURATIONVAR_MAX = 0,
                METEOR_SHOWER_LVL2_METEORSPERSEC_MIN = 0,
                METEOR_SHOWER_LVL2_METEORSPERSEC_MAX = 0,
                METEOR_SHOWER_LVL2_MEDMETEORS_MIN = 0,
                METEOR_SHOWER_LVL2_MEDMETEORS_MAX = 0,
                METEOR_SHOWER_LVL2_LRGMETEORS_MIN = 0,
                METEOR_SHOWER_LVL2_LRGMETEORS_MAX = 0,

                METEOR_SHOWER_LVL3_DURATION_BASE = 0,
                METEOR_SHOWER_LVL3_DURATIONVAR_MIN = 0,
                METEOR_SHOWER_LVL3_DURATIONVAR_MAX = 0,
                METEOR_SHOWER_LVL3_METEORSPERSEC_MIN = 0,
                METEOR_SHOWER_LVL3_METEORSPERSEC_MAX = 0,
                METEOR_SHOWER_LVL3_MEDMETEORS_MIN = 0,
                METEOR_SHOWER_LVL3_MEDMETEORS_MAX = 0,
                METEOR_SHOWER_LVL3_LRGMETEORS_MIN = 0,
                METEOR_SHOWER_LVL3_LRGMETEORS_MAX = 0, 
            },
            rare = 
            { 
                METEOR_SHOWER_LVL1_BASETIME = TUNING.TOTAL_DAY_TIME*12,
                METEOR_SHOWER_LVL1_VARTIME = TUNING.TOTAL_DAY_TIME*8,
                METEOR_SHOWER_LVL2_BASETIME = TUNING.TOTAL_DAY_TIME*18,
                METEOR_SHOWER_LVL2_VARTIME = TUNING.TOTAL_DAY_TIME*12,
                METEOR_SHOWER_LVL3_BASETIME = TUNING.TOTAL_DAY_TIME*24,
                METEOR_SHOWER_LVL3_VARTIME = TUNING.TOTAL_DAY_TIME*16,

                METEOR_SHOWER_LVL1_DURATION_BASE = 5,
                METEOR_SHOWER_LVL1_DURATIONVAR_MIN = 5,
                METEOR_SHOWER_LVL1_DURATIONVAR_MAX = 10,
                METEOR_SHOWER_LVL1_METEORSPERSEC_MIN = 2,
                METEOR_SHOWER_LVL1_METEORSPERSEC_MAX = 4,
                METEOR_SHOWER_LVL1_MEDMETEORS_MIN = 1,
                METEOR_SHOWER_LVL1_MEDMETEORS_MAX = 3,
                METEOR_SHOWER_LVL1_LRGMETEORS_MIN = 1,
                METEOR_SHOWER_LVL1_LRGMETEORS_MAX = 4,

                METEOR_SHOWER_LVL2_DURATION_BASE = 5,
                METEOR_SHOWER_LVL2_DURATIONVAR_MIN = 10,
                METEOR_SHOWER_LVL2_DURATIONVAR_MAX = 20,
                METEOR_SHOWER_LVL2_METEORSPERSEC_MIN = 3,
                METEOR_SHOWER_LVL2_METEORSPERSEC_MAX = 7,
                METEOR_SHOWER_LVL2_MEDMETEORS_MIN = 2,
                METEOR_SHOWER_LVL2_MEDMETEORS_MAX = 4,
                METEOR_SHOWER_LVL2_LRGMETEORS_MIN = 2,
                METEOR_SHOWER_LVL2_LRGMETEORS_MAX = 7,

                METEOR_SHOWER_LVL3_DURATION_BASE = 5,
                METEOR_SHOWER_LVL3_DURATIONVAR_MIN = 15,
                METEOR_SHOWER_LVL3_DURATIONVAR_MAX = 30,
                METEOR_SHOWER_LVL3_METEORSPERSEC_MIN = 4,
                METEOR_SHOWER_LVL3_METEORSPERSEC_MAX = 10,
                METEOR_SHOWER_LVL3_MEDMETEORS_MIN = 3,
                METEOR_SHOWER_LVL3_MEDMETEORS_MAX = 6,
                METEOR_SHOWER_LVL3_LRGMETEORS_MIN = 3,
                METEOR_SHOWER_LVL3_LRGMETEORS_MAX = 10, 
            },
            often = 
            { 
                METEOR_SHOWER_LVL1_BASETIME = TUNING.TOTAL_DAY_TIME*3,
                METEOR_SHOWER_LVL1_VARTIME = TUNING.TOTAL_DAY_TIME*2,
                METEOR_SHOWER_LVL2_BASETIME = TUNING.TOTAL_DAY_TIME*5,
                METEOR_SHOWER_LVL2_VARTIME = TUNING.TOTAL_DAY_TIME*3,
                METEOR_SHOWER_LVL3_BASETIME = TUNING.TOTAL_DAY_TIME*6,
                METEOR_SHOWER_LVL3_VARTIME = TUNING.TOTAL_DAY_TIME*4,

                METEOR_SHOWER_LVL1_DURATION_BASE = 5,
                METEOR_SHOWER_LVL1_DURATIONVAR_MIN = 5,
                METEOR_SHOWER_LVL1_DURATIONVAR_MAX = 10,
                METEOR_SHOWER_LVL1_METEORSPERSEC_MIN = 2,
                METEOR_SHOWER_LVL1_METEORSPERSEC_MAX = 4,
                METEOR_SHOWER_LVL1_MEDMETEORS_MIN = 1,
                METEOR_SHOWER_LVL1_MEDMETEORS_MAX = 3,
                METEOR_SHOWER_LVL1_LRGMETEORS_MIN = 1,
                METEOR_SHOWER_LVL1_LRGMETEORS_MAX = 4,

                METEOR_SHOWER_LVL2_DURATION_BASE = 5,
                METEOR_SHOWER_LVL2_DURATIONVAR_MIN = 10,
                METEOR_SHOWER_LVL2_DURATIONVAR_MAX = 20,
                METEOR_SHOWER_LVL2_METEORSPERSEC_MIN = 3,
                METEOR_SHOWER_LVL2_METEORSPERSEC_MAX = 7,
                METEOR_SHOWER_LVL2_MEDMETEORS_MIN = 2,
                METEOR_SHOWER_LVL2_MEDMETEORS_MAX = 4,
                METEOR_SHOWER_LVL2_LRGMETEORS_MIN = 2,
                METEOR_SHOWER_LVL2_LRGMETEORS_MAX = 7,

                METEOR_SHOWER_LVL3_DURATION_BASE = 5,
                METEOR_SHOWER_LVL3_DURATIONVAR_MIN = 15,
                METEOR_SHOWER_LVL3_DURATIONVAR_MAX = 30,
                METEOR_SHOWER_LVL3_METEORSPERSEC_MIN = 4,
                METEOR_SHOWER_LVL3_METEORSPERSEC_MAX = 10,
                METEOR_SHOWER_LVL3_MEDMETEORS_MIN = 3,
                METEOR_SHOWER_LVL3_MEDMETEORS_MAX = 6,
                METEOR_SHOWER_LVL3_LRGMETEORS_MIN = 3,
                METEOR_SHOWER_LVL3_LRGMETEORS_MAX = 10, 
            },
            always = 
            { 
                METEOR_SHOWER_LVL1_BASETIME = TUNING.TOTAL_DAY_TIME*2,
                METEOR_SHOWER_LVL1_VARTIME = TUNING.TOTAL_DAY_TIME*1,
                METEOR_SHOWER_LVL2_BASETIME = TUNING.TOTAL_DAY_TIME*3,
                METEOR_SHOWER_LVL2_VARTIME = TUNING.TOTAL_DAY_TIME*2,
                METEOR_SHOWER_LVL3_BASETIME = TUNING.TOTAL_DAY_TIME*4,
                METEOR_SHOWER_LVL3_VARTIME = TUNING.TOTAL_DAY_TIME*2,

                METEOR_SHOWER_LVL1_DURATION_BASE = 5,
                METEOR_SHOWER_LVL1_DURATIONVAR_MIN = 5,
                METEOR_SHOWER_LVL1_DURATIONVAR_MAX = 10,
                METEOR_SHOWER_LVL1_METEORSPERSEC_MIN = 2,
                METEOR_SHOWER_LVL1_METEORSPERSEC_MAX = 4,
                METEOR_SHOWER_LVL1_MEDMETEORS_MIN = 1,
                METEOR_SHOWER_LVL1_MEDMETEORS_MAX = 3,
                METEOR_SHOWER_LVL1_LRGMETEORS_MIN = 1,
                METEOR_SHOWER_LVL1_LRGMETEORS_MAX = 4,

                METEOR_SHOWER_LVL2_DURATION_BASE = 5,
                METEOR_SHOWER_LVL2_DURATIONVAR_MIN = 10,
                METEOR_SHOWER_LVL2_DURATIONVAR_MAX = 20,
                METEOR_SHOWER_LVL2_METEORSPERSEC_MIN = 3,
                METEOR_SHOWER_LVL2_METEORSPERSEC_MAX = 7,
                METEOR_SHOWER_LVL2_MEDMETEORS_MIN = 2,
                METEOR_SHOWER_LVL2_MEDMETEORS_MAX = 4,
                METEOR_SHOWER_LVL2_LRGMETEORS_MIN = 2,
                METEOR_SHOWER_LVL2_LRGMETEORS_MAX = 7,

                METEOR_SHOWER_LVL3_DURATION_BASE = 5,
                METEOR_SHOWER_LVL3_DURATIONVAR_MIN = 15,
                METEOR_SHOWER_LVL3_DURATIONVAR_MAX = 30,
                METEOR_SHOWER_LVL3_METEORSPERSEC_MIN = 4,
                METEOR_SHOWER_LVL3_METEORSPERSEC_MAX = 10,
                METEOR_SHOWER_LVL3_MEDMETEORS_MIN = 3,
                METEOR_SHOWER_LVL3_MEDMETEORS_MAX = 6,
                METEOR_SHOWER_LVL3_LRGMETEORS_MIN = 3,
                METEOR_SHOWER_LVL3_LRGMETEORS_MAX = 10, 
            },
        }
        OverrideTuningVariables(tuning_vars[difficulty])
    end,

    waves = function(data)
        if data == "off" and TheWorld.WaveComponent then
            TheWorld.WaveComponent:SetRegionNumWaves(0)
        end
    end,

    colourcube = function(data)
        TheWorld:PushEvent("overridecolourcube", "images/colour_cubes/"..data..".tex")
    end,

}