
AddTaskSet("cave_default", {
    name = STRINGS.UI.CUSTOMIZATIONSCREEN.TASKSETNAMES.CAVE_DEFAULT,
    location = "cave",
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

