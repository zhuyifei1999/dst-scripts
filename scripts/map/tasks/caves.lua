

AddTaskSet("cave_default", {
    name = STRINGS.UI.CUSTOMIZATIONSCREEN.TASKSETNAMES.CAVE_DEFAULT,
    tasks={
        "MudWorld",
        "MudCave",
        "MudLights",
        "MudPit",

        "BigBatCave",
        "RockyLand",
        "RedForest",
        "GreenForest",
        "BlueForest",
        "SpillagmiteCaverns",

        "CaveExitTask1",
        "CaveExitTask2",
        "CaveExitTask3",
        "CaveExitTask4",
        "CaveExitTask5",
        "CaveExitTask6",
        "CaveExitTask7",
        "CaveExitTask8",
        "CaveExitTask9",
        "CaveExitTask10",

        -- ruins
        "LichenLand",
        "Residential",
        "Military",
        "Sacred",
        "TheLabyrinth",
        "SacredAltar",
    },
    numoptionaltasks = 8,
    optionaltasks = {
        "SwampySinkhole",
        "CaveSwamp",
        "UndergroundForest",
        "PleasantSinkhole",
        "FungalNoiseForest",
        "FungalNoiseMeadow",
        "BatCloister",
        "RabbitTown",
        "RabbitCity",
        "SpiderLand",
        "RabbitSpiderWar",

        --ruins
        "MoreAltars",
        "CaveJungle",
        "SacredDanger",
        "MilitaryPits",
        "MuddySacred",
        "Residential2",
        "Residential3",
    },
    valid_start_tasks = {
        "CaveExitTask1",
        "CaveExitTask2",
        "CaveExitTask3",
        "CaveExitTask4",
        "CaveExitTask5",
        "CaveExitTask6",
        "CaveExitTask7",
        "CaveExitTask8",
        "CaveExitTask9",
        "CaveExitTask10",
    },
    set_pieces = { -- if you add or remove tasks, don't forget to update this list!
        ["TentaclePillar"] = { count = 10, tasks= {
            "MudWorld", "MudCave", "MudLights", "MudPit", "BigBatCave", "RockyLand", "RedForest", "GreenForest", "BlueForest", "SpillagmiteCaverns", "SwampySinkhole", "CaveSwamp", "UndergroundForest", "PleasantSinkhole", "FungalNoiseForest", "FungalNoiseMeadow", "BatCloister", "RabbitTown", "RabbitCity", "SpiderLand", "RabbitSpiderWar",
        } },
        ["ResurrectionStone"] = { count = 2, tasks={
            "MudWorld", "MudCave", "MudLights", "MudPit", "BigBatCave", "RockyLand", "RedForest", "GreenForest", "BlueForest", "SpillagmiteCaverns", "SwampySinkhole", "CaveSwamp", "UndergroundForest", "PleasantSinkhole", "FungalNoiseForest", "FungalNoiseMeadow", "BatCloister", "RabbitTown", "RabbitCity", "SpiderLand", "RabbitSpiderWar",
        } },
    },
})


------------------------------------------------------------
-- One of every room
------------------------------------------------------------

AddTask("CavesTEST", {
    locks = {},
    room_choices = {
        ["BatCave"] = 1,
        ["BattyCave"] = 1,
        ["FernyBatCave"] = 1,
        ["BGBatCave"] = 1,
        ["BGBatCaveRoom"] = 1,

        ["RabbitArea"] = 1,
        ["RabbitTown"] = 1,
        ["RabbitCity"] = 1,
        ["RabbitSinkhole"] = 1,
        ["SpiderIncursion"] = 1,

        ["SinkholeForest"] = 1,
        ["SinkholeCopses"] = 1,
        ["SparseSinkholes"] = 1,
        ["SinkholeOasis"] = 1,
        ["GrasslandSinkhole"] = 1,
        ["BGSinkhole"] = 1,
        ["BGSinkholeRoom"] = 1,

        ["RedMushForest"] = 1,
        ["RedSpiderForest"] = 1,
        ["RedMushPillars"] = 1,
        ["StalagmiteForest"] = 1,
        ["SpillagmiteMeadow"] = 1,
        ["BGRedMush"] = 1,
        ["BGRedMushRoom"] = 1,

        ["GreenMushForest"] = 1,
        ["GreenMushPonds"] = 1,
        ["GreenMushSinkhole"] = 1,
        ["GreenMushMeadow"] = 1,
        ["GreenMushRabbits"] = 1,
        ["GreenMushNoise"] = 1,
        ["BGGreenMush"] = 1,
        ["BGGreenMushRoom"] = 1,

        ["BlueMushForest"] = 1,
        ["BlueMushMeadow"] = 1,
        ["BlueSpiderForest"] = 1,
        ["BlueDropperDesolation"] = 1,
        ["BGBlueMush"] = 1,
        ["BGBlueMushRoom"] = 1,

        ["LightPlantField"] = 1,
        ["WormPlantField"] = 1,
        ["FernGully"] = 1,
        ["SlurtlePlains"] = 1,
        ["MudWithRabbit"] = 1,
        ["BGMud"] = 1,
        ["BGMudRoom"] = 1,

        ["SlurtleCanyon"] = 1,
        ["BatsAndSlurtles"] = 1,
        ["RockyPlains"] = 1,
        ["RockyHatchingGrounds"] = 1,
        ["BatsAndRocky"] = 1,
        ["BGRocky"] = 1,
        ["BGRockyRoom"] = 1,

        ["SpillagmiteForest"] = 1,
        ["DropperCanyon"] = 1,
        ["StalagmitesAndLights"] = 1,
        ["SpidersAndBats"] = 1,
        ["ThuleciteDebris"] = 1,
        ["BGSpillagmite"] = 1,
        ["BGSpillagmiteRoom"] = 1,

        ["FungusNoiseForest"] = 1,
        ["FungusNoiseMeadow"] = 1,

        ["SinkholeSwamp"] = 1,
        ["DarkSwamp"] = 1,
        ["TentacleMud"] = 1,
        ["TentaclesAndTrees"] = 1,
        ["BGSinkholeSwamp"] = 1,
        ["BGSinkholeSwampRoom"] = 1,

    },
    room_bg=GROUND.WALL_ROCKY,
    background_room="Blank",--"BGCaveRoom",
    colour={r=1,g=0.8,b=1,a=1},
})

------------------------------------------------------------
-- Central Cave Node + Antechamber nodes to decompress the middle
------------------------------------------------------------
-- Mud World
AddTask("MudWorld", {
    locks={ LOCKS.NONE },
    keys_given={ KEYS.CAVE, KEYS.TIER1 },
    room_choices={
        ["LightPlantField"] = 2,
        ["WormPlantField"] = 1,
        ["FernGully"] = 1,
        ["SlurtlePlains"] = 1,
        ["MudWithRabbit"] = 1,
        ["PitRoom"] = 2,
    },
    background_room="BGMud",
    room_bg=GROUND.MUD,
    colour={r=0.6,g=0.4,b=0.0,a=0.9},
})

AddTask("MudCave", {
    locks={ LOCKS.CAVE, LOCKS.TIER1 },
    keys_given={ KEYS.CAVE, KEYS.TIER2 },
    room_choices={
        ["WormPlantField"] = 1,
        ["SlurtlePlains"] = 1,
        ["MudWithRabbit"] = 1,
        ["PitRoom"] = 2,
    },
    background_room="BGBatCaveRoom",
    room_bg=GROUND.MUD,
    colour={r=0.7,g=0.5,b=0.0,a=0.9},
})

AddTask("MudLights", {
    locks={ LOCKS.CAVE, LOCKS.TIER1 },
    keys_given={ KEYS.CAVE, KEYS.TIER2 },
    room_choices={
        ["LightPlantField"] = 3,
        ["WormPlantField"] = 1,
        ["PitRoom"] = 2,
    },
    background_room="WormPlantField",
    room_bg=GROUND.MUD,
    colour={r=0.7,g=0.5,b=0.0,a=0.9},
})

AddTask("MudPit", {
    locks={ LOCKS.CAVE, LOCKS.TIER1 },
    keys_given={ KEYS.CAVE, KEYS.TIER2 },
    room_choices={
        ["SlurtlePlains"] = 1,
        ["PitRoom"] = 4,
    },
    background_room="FernGully",
    room_bg=GROUND.MUD,
    colour={r=0.6,g=0.4,b=0.0,a=0.9},
})

------------------------------------------------------------
-- Main Caves Branches
------------------------------------------------------------
-- Big Bat Cave
AddTask("BigBatCave", {
    locks={ LOCKS.CAVE, LOCKS.TIER2 },
    keys_given={ KEYS.CAVE, KEYS.TIER3, KEYS.BATS },
    room_choices={
        ["BatCave"] = 3,
        ["BattyCave"] = 1,
        ["FernyBatCave"] = 2,
        ["PitRoom"] = 4,
    },
    background_room="BGBatCaveRoom",
    room_bg=GROUND.CAVE,
    colour={r=0.8,g=0.8,b=0.8,a=0.9},
})

-- Rocky Land
AddTask("RockyLand",{
    locks={ LOCKS.CAVE, LOCKS.TIER2 },
    keys_given={ KEYS.CAVE, KEYS.TIER3, KEYS.ROCKY },
    room_choices={
        ["SlurtleCanyon"] = 1,
        ["BatsAndSlurtles"] = 1,
        ["RockyPlains"] = 2,
        ["RockyHatchingGrounds"] = 1,
        ["BatsAndRocky"] = 1,
        ["PitRoom"] = 2,
    },
    background_room="BGRockyRoom",
    room_bg=GROUND.CAVE,
    colour={r=0.5,g=0.5,b=0.5,a=0.9},
})

-- Red Forest
AddTask("RedForest",{
    locks={ LOCKS.CAVE, LOCKS.TIER2 },
    keys_given={ KEYS.CAVE, KEYS.TIER3, KEYS.RED, KEYS.ENTRANCE_INNER },
    room_choices={
        ["RedMushForest"] = 2,
        ["RedSpiderForest"] = 1,
        ["RedMushPillars"] = 1,
        ["StalagmiteForest"] = 1,
        ["SpillagmiteMeadow"] = 1,
        ["PitRoom"] = 2,
    },
    background_room="BGRedMush",
    room_bg=GROUND.FUNGUSRED,
    colour={r=1.0,g=0.5,b=0.5,a=0.9},
})

-- Green Forest
AddTask("GreenForest",{
    locks={ LOCKS.CAVE, LOCKS.TIER2 },
    keys_given={ KEYS.CAVE, KEYS.TIER3, KEYS.GREEN, KEYS.ENTRANCE_INNER },
    room_choices={
        ["GreenMushForest"] = 2,
        ["GreenMushPonds"] = 1,
        ["GreenMushSinkhole"] = 1,
        ["GreenMushMeadow"] = 1,
        ["GreenMushRabbits"] = 1,
        ["GreenMushNoise"] = 1,
        ["PitRoom"] = 2,
    },
    background_room="BGGreenMush",
    room_bg=GROUND.FUNGUSGREEN,
    colour={r=0.5,g=1.0,b=0.5,a=0.9},
})

-- Blue Forest
AddTask("BlueForest",{
    locks={ LOCKS.CAVE, LOCKS.TIER2 },
    keys_given={ KEYS.CAVE, KEYS.TIER3, KEYS.BLUE, KEYS.ENTRANCE_INNER },
    room_choices={
        ["BlueMushForest"] = 3,
        ["BlueMushMeadow"] = 2,
        ["BlueSpiderForest"] = 1,
        ["DropperDesolation"] = 1,
        ["PitRoom"] = 2,
    },
    background_room="BGBlueMush",
    room_bg=GROUND.FUNGUS,
    colour={r=0.5,g=0.5,b=1.0,a=0.9},
})

-- Ruins
-- TODO

-- Spillagmite Caverns
AddTask("SpillagmiteCaverns",{
    locks={ LOCKS.CAVE, LOCKS.TIER2 },
    keys_given={ KEYS.CAVE, KEYS.TIER3 },
    room_choices={
        ["SpillagmiteForest"] = 1,
        ["DropperCanyon"] = 1,
        ["StalagmitesAndLights"] = 1,
        ["SpidersAndBats"] = 1,
        ["ThuleciteDebris"] = 1,
        ["PitRoom"] = 2,
    },
    background_room="BGSpillagmiteRoom",
    room_bg=GROUND.UNDERROCK,
    colour={r=0.3,g=0.3,b=0.3,a=0.9},
})

------------------------------------------------------------
-- Minor Caves Branches
------------------------------------------------------------
-- Swampy Sinkhole
AddTask("SwampySinkhole",{
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ KEYS.CAVE, KEYS.SWAMP, KEYS.TIER4 },
    room_choices={
        ["SinkholeSwamp"] = 1,
        ["TentacleMud"] = 1,
        ["TentaclesAndTrees"] = 1,
        ["PitRoom"] = 2,
    },
    background_room="BGSinkholeSwampRoom",
    room_bg=GROUND.SWAMP,
    colour={r=0.6,g=0.1,b=0.7,a=0.9},
})

-- Cave Swamp
AddTask("CaveSwamp",{
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ KEYS.CAVE, KEYS.SWAMP, KEYS.TIER4 },
    room_choices={
        ["DarkSwamp"] = 2,
        ["TentacleMud"] = 1,
        ["PitRoom"] = 2,
    },
    background_room="BGSinkholeSwamp",
    room_bg=GROUND.SWAMP,
    colour={r=0.7,g=0.1,b=0.6,a=0.9},
})

-- Underground Forest
AddTask("UndergroundForest",{
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ KEYS.CAVE, KEYS.SINKHOLE, KEYS.TIER4, KEYS.ENTRANCE_OUTER },
    room_choices={
        ["SinkholeForest"] = 3,
        ["SinkholeCopses"] = 1,
        ["SparseSinkholes"] = 1,
        ["PitRoom"] = 2,
    },
    background_room="BGSinkhole",
    room_bg=GROUND.SINKHOLE,
    colour={r=0.0,g=0.3,b=0.0,a=0.9},
})

-- Pleasant Sinkhole
AddTask("PleasantSinkhole",{
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ KEYS.CAVE, KEYS.SINKHOLE, KEYS.TIER4, KEYS.ENTRANCE_OUTER },
    room_choices={
        ["GrasslandSinkhole"] = 3,
        ["SinkholeOasis"] = 1,
        ["SparseSinkholes"] = 1,
        ["PitRoom"] = 2,
    },
    background_room="BGSinkhole",
    room_bg=GROUND.SINKHOLE,
    colour={r=0.0,g=0.5,b=0.0,a=0.9},
})

-- Soggy Sinkhole
AddTask("SoggySinkhole",{
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ KEYS.CAVE, KEYS.SINKHOLE, KEYS.TIER4, KEYS.ENTRANCE_OUTER },
    room_choices={
        ["SinkholeOasis"] = 3,
        ["SinkholeCopses"] = 1,
        ["SparseSinkholes"] = 1,
        ["PitRoom"] = 2,
    },
    background_room="BGSinkhole",
    room_bg=GROUND.SINKHOLE,
    colour={r=0.0,g=0.5,b=0.0,a=0.9},
})

-- Fungal Noise Forest
AddTask("FungalNoiseForest",{
    locks={ LOCKS.CAVE, LOCKS.TIER3, LOCKS.ROCKY },
    keys_given={ KEYS.CAVE, KEYS.TIER4, KEYS.ENTRANCE_OUTER },
    room_choices={
        ["FungusNoiseForest"] = 3,
        ["RedMushForest"] = 1,
        ["BlueMushForest"] = 1,
        ["GreenMushForest"] = 1,
        ["PitRoom"] = 2,
    },
    background_room="FungusNoiseMeadow",
    room_bg=GROUND.FUNGUS,
    colour={r=0.0,g=0.5,b=1.0,a=0.9},
})

-- Fungal Noise Meadow
AddTask("FungalNoiseMeadow",{
    locks={ LOCKS.CAVE, LOCKS.TIER3, LOCKS.BATS },
    keys_given={ KEYS.CAVE, KEYS.TIER4, KEYS.ENTRANCE_OUTER },
    room_choices={
        ["FungusNoiseMeadow"] = 3,
        ["SpillagmiteMeadow"] = 1,
        ["BlueMushMeadow"] = 1,
        ["GreenMushMeadow"] = 1,
        ["PitRoom"] = 2,
    },
    background_room="FungusNoiseMeadow",
    room_bg=GROUND.FUNGUS,
    colour={r=0.0,g=0.5,b=0.8,a=0.9},
})

-- Bat Cloister
AddTask("BatCloister",{
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ KEYS.CAVE, KEYS.TIER4 },
    room_choices={
        ["PitRoom"] = 2,
    },
    background_room="BatCave",
    room_bg=GROUND.CAVE,
    colour={r=0.7,g=0.7,b=0.7,a=0.9},
})

-- Rabbit Town
AddTask("RabbitTown",{
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ KEYS.CAVE, KEYS.RABBIT, KEYS.TIER4, KEYS.ENTRANCE_OUTER },
    room_choices={
        ["RabbitTown"] = 1,
        ["RabbitArea"] = 1,
        ["RabbitSinkhole"] = 1,
        ["PitRoom"] = 2,
    },
    background_room="BGSinkhole",
    room_bg=GROUND.SINKHOLE,
    colour={r=2.0,g=0.6,b=0.0,a=0.9},
})

-- Rabbit City
AddTask("RabbitCity",{
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ KEYS.CAVE, KEYS.RABBIT, KEYS.TIER4, KEYS.ENTRANCE_OUTER },
    room_choices={
        ["RabbitCity"] = 1,
        ["RabbitTown"] = 2,
        ["RabbitArea"] = 1,
        ["PitRoom"] = 2,
    },
    background_room="BGSinkhole",
    room_bg=GROUND.SINKHOLE,
    colour={r=1.0,g=0.8,b=0.2,a=0.9},
})

-- Spider Land
AddTask("SpiderLand",{
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ KEYS.CAVE, KEYS.SPIDERS, KEYS.TIER4 },
    room_choices={
        ["SpiderIncursion"] = 1,
        ["SpiderMarsh"] = 1,
        ["SpidersAndBats"] = 1,
        ["PitRoom"] = 2,
    },
    background_room="PitRoom",
    room_bg=GROUND.SINKHOLE,
    colour={r=0.2,g=0.5,b=0.2,a=0.9},
})

-- Rabbit-Spider War
AddTask("RabbitSpiderWar",{
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ KEYS.CAVE, KEYS.SPIDERS, KEYS.RABBIT, KEYS.TIER4 },
    room_choices={
        ["SpiderIncursion"] = 1,
        ["RabbitArea"] = 1,
        ["PitRoom"] = 2,
    },
    background_room="SparseSinkholes",
    room_bg=GROUND.SINKHOLE,
    colour={r=0.6,g=0.2,b=0.0,a=0.9},
})

-- Ancient Annex

------------------------------------------------------------
-- Bumps and one-offs
------------------------------------------------------------
-- Ancients Expedition
-- Bat Barrens
-- Wee Sinkhole
-- Wee Swamp
-- Rabbit Hamlet

------------------------------------------------------------
-- Starts
------------------------------------------------------------
local startrooms = {
    "RabbitArea",
    "RabbitTown",
    "RabbitSinkhole",
    "SpiderIncursion",
    "SinkholeForest",
    "SinkholeCopses",
    "SinkholeOasis",
    "GrasslandSinkhole",
    "GreenMushSinkhole",
    "GreenMushRabbits",
}
for i=1,10 do
    AddTask("CaveExitTask"..i, {
        locks={ (i <= 4 and LOCKS.ENTRANCE_INNER or LOCKS.ENTRANCE_OUTER) },
        keys_given={},
        room_choices={
            ["CaveExitRoom"] = 1,
            [startrooms[i]] = 1,
        },
        background_room="BGSinkhole",
        room_bg=GROUND.SINKHOLE,
        colour={r=1,g=0,b=1,a=1},
    })
end

