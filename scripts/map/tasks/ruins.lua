
------------------------------------------------------------
-- Caves Ruins Level
------------------------------------------------------------

--


AddTask("LichenLand", {
    locks={LOCKS.TIER1},
    keys_given= {KEYS.TIER2, KEYS.RUINS},
    room_tags = {"Nightmare"},
    room_choices={
        ["WetWilds"] = math.random(1,2),
        ["LichenMeadow"] = math.random(1,2),
        ["LichenLand"] = 3,
        ["PitRoom"] = 2,
    },
    room_bg=GROUND.MUD,
    background_room="BGWilds",
    colour={r=0,g=0,b=0.0,a=1},
})

AddTask("CaveJungle", {
    locks={LOCKS.TIER2, LOCKS.RUINS},
    keys_given= {KEYS.TIER3, KEYS.RUINS},
    room_tags = {"Nightmare"},
    room_choices={
        ["WetWilds"] = math.random(1,2),
        ["LichenMeadow"] = 1,
        ["CaveJungle"] = math.random(1,2),
        ["MonkeyMeadow"] = math.random(1,2),
        ["PitRoom"] = 2,
    },
    room_bg=GROUND.MUD,
    background_room="BGWildsRoom",
    colour={r=0,g=0,b=0.0,a=1},
})

AddTask("Residential", {
    locks={LOCKS.TIER2, LOCKS.RUINS},
    keys_given= {KEYS.TIER3, KEYS.RUINS},
    room_tags = {"Nightmare"},
    entrance_room = "RuinedCityEntrance",
    room_choices =
    {
        ["Vacant"] = 2,
        ["LightHut"] = 1,
        ["PitRoom"] = 2,
    },
    room_bg = GROUND.TILES,
    maze_tiles = {rooms = {"room_residential", "room_residential_two", "hallway_residential", "hallway_residential_two"}, bosses = {"room_residential"}},
    background_room="RuinedCity",
    colour={r=0.2,g=0.2,b=0.0,a=1},
})


AddTask("MilitaryPits", {
    locks={LOCKS.TIER3, LOCKS.RUINS},
    keys_given= {KEYS.TIER4, KEYS.RUINS},
    room_tags = {"Nightmare"},
    entrance_room = "MilitaryEntrance",
    room_choices =
    {
        ["MilitaryMaze"] = 1,
        ["Barracks"] = 3,
    },
    room_bg = GROUND.TILES,
    maze_tiles = {rooms = {"pit_room_armoury", "pit_hallway_armoury", "pit_room_armoury_two"}, bosses = {"pit_room_armoury_two"}},
    background_room="MilitaryMaze",
    colour={r=0.6,g=0.6,b=0.0,a=1},
})

AddTask("Military", {
    locks={LOCKS.TIER3, LOCKS.RUINS},
    keys_given= {KEYS.TIER4, KEYS.RUINS},
    room_tags = {"Nightmare"},
    entrance_room = "MilitaryEntrance",
    room_choices =
    {
        ["MilitaryMaze"] = 4,
        ["Barracks"] = 1,
    },
    room_bg = GROUND.TILES,
    maze_tiles = {rooms = {"room_armoury", "hallway_armoury", "room_armoury_two"}, bosses = {"room_armoury_two"}},
    background_room="MilitaryMaze",
    colour={r=0.6,g=0.6,b=0.0,a=1},
})

AddTask("Sacred", {
    locks={LOCKS.TIER3, LOCKS.RUINS},
    keys_given= {KEYS.TIER4, KEYS.RUINS, KEYS.SACRED},
    room_tags = {"Nightmare"},
    entrance_room = "BridgeEntrance",
    room_choices =
    {
        ["SacredBarracks"] = math.random(1,2),
        ["Bishops"] = math.random(1,2),
        ["Spiral"] = math.random(1,2),
        ["BrokenAltar"] = math.random(1,2),
        ["PitRoom"] = 2,
    },
    room_bg = GROUND.TILES,
    background_room="Blank",
    colour={r=0.6,g=0.6,b=0.0,a=1},
})

AddTask("TheLabyrinth", {
    locks={LOCKS.TIER4, LOCKS.RUINS},
    keys_given= {KEYS.TIER5, KEYS.RUINS, KEYS.SACRED},
    room_tags = {"Nightmare"},
    entrance_room="LabyrinthEntrance",
    room_choices={
        ["Labyrinth"] = 3+math.random(3),
        ["RuinedGuarden"] = 1,
    },
    room_bg=GROUND.IMPASSABLE,
    background_room="Labyrinth",
    colour={r=0.4,g=0.4,b=0.0,a=1},
})

AddTask("SacredAltar",{
    locks={LOCKS.TIER4, LOCKS.RUINS},
    keys_given= {KEYS.TIER5, KEYS.RUINS, KEYS.SACRED},
    room_tags = {"Nightmare"},
    room_choices =
    {
        ["Altar"] = 1,
        ["PitRoom"] = 2,
    },
    room_bg = GROUND.TILES,
    entrance_room="BridgeEntrance",
    background_room="Blank",
    colour={r=0.6,g=0.3,b=0.0,a=1},
})



----Optional Ruins Tasks----



AddTask("MoreAltars", {
    locks = {LOCKS.SACRED, LOCKS.RUINS, LOCKS.OUTERTIER},
    keys_given = {KEYS.SACRED, KEYS.RUINS},
    room_tags = {"Nightmare"},
    room_choices =
    {
        [math.random(1,4) > 1 and "BrokenAltar" or "Altar"] = 1,
        ["PitRoom"] = 2,
    },
    room_bg = GROUND.TILES,
    background_room="Blank",
    colour={r=1,g=0,b=0.6,a=1},
})
AddTask("SacredDanger", {
    locks = {LOCKS.SACRED, LOCKS.RUINS, LOCKS.OUTERTIER},
    keys_given = {KEYS.SACRED, KEYS.RUINS},
    room_tags = {"Nightmare"},
    room_choices =
    {
        ["SacredBarracks"] = math.random(1,2),
        ["Barracks"] = math.random(1,2),
    },
    room_bg = GROUND.TILES,
    background_room="BGSacred",
    colour={r=1,g=0,b=0.6,a=1},
})

AddTask("MuddySacred", {
    locks = {LOCKS.SACRED, LOCKS.RUINS, LOCKS.OUTERTIER},
    keys_given = {KEYS.SACRED, KEYS.RUINS, KEYS.TIER4},
    room_tags = {"Nightmare"},
    room_choices =
    {
        ["SacredBarracks"] = math.random(0,1),
        ["Bishops"] = math.random(0,1),
        ["Spiral"] = math.random(0,1),
        ["BrokenAltar"] = math.random(0,1),
        ["WetWilds"] = 1,
        ["MonkeyMeadow"] = 1,
    },
    room_bg = GROUND.TILES,
    background_room="BGWildsRoom",
    colour={r=1,g=0,b=0.6,a=1},
})

AddTask("Residential2", {
    locks = {LOCKS.RUINS},
    keys_given = {KEYS.RUINS},
    room_tags = {"Nightmare"},
    entrance_room = "RuinedCityEntrance",
    room_choices =
    {
        ["CaveJungle"] = 1,
        ["Vacant"] = 1,
        ["RuinedCity"] = 2,
    },
    room_bg = GROUND.TILES,
    maze_tiles = {rooms = {"room_residential", "room_residential_two", "hallway_residential", "hallway_residential_two"}, bosses = {"room_residential"}},
    background_room="BGWilds",
    colour={r=1,g=0,b=0.6,a=1},
})

AddTask("Residential3", {
    locks = {LOCKS.RUINS},
    keys_given = {KEYS.RUINS},
    room_tags = {"Nightmare"},
    room_choices =
    {
        ["Vacant"] = math.random(3,4),
    },
    room_bg = GROUND.TILES,
    background_room="BGWilds",
    colour={r=1,g=0,b=0.6,a=1},
})
