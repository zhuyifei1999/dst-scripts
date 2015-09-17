
------------------------------------------------------------
-- Caves Ruins Level
------------------------------------------------------------
-- AddTask("CityInRuins", {
--      locks={LOCKS.RUINS},
--      keys_given=KEYS.RUINS,
--      entrance_room="RuinedCityEntrance",
--      room_choices={
--          ["BGMaze"] = 10+math.random(SIZE_VARIATION), 
--      },
--      room_bg=GROUND.TILES,
--      maze_tiles = {rooms={"default", "hallway_shop", "hallway_residential", "room_residential" }, bosses={"room_residential"}},
--      background_room="BGMaze",
--      colour={r=1,g=0,b=0.6,a=1},
--  })
-- AddTask("AlterAhead", {
--      locks={LOCKS.RUINS},
--      keys_given=KEYS.RUINS,
--      entrance_room="LabyrinthCityEntrance",
--      room_choices={
--          ["BGMaze"] = 6+math.random(SIZE_VARIATION), 
--      },
--      room_bg=GROUND.TILES,
--      maze_tiles = {rooms={"default", "hallway", "hallway_armoury", "room_armoury" }, bosses={"room_armoury"}} ,
--      background_room="BGMaze",
--      colour={r=1,g=0,b=0.6,a=1},
--  })
-- AddTask("TownSquare", {
--      locks = {LOCKS.LABYRINTH},
--      keys_given = KEYS.NONE,
--      entrance_room = "RuinedCityEntrance",
--      room_choices =
--      {
--          ["BGMaze"] = 6+math.random(SIZE_VARIATION),
--      },
--      room_bg = GROUND.TILES,
--      maze_tiles = {"room_open"},
--      background_room="BGMaze",
--      colour={r=1,g=0,b=0.6,a=1},
--  })


for i=1,6 do
    AddTask("RuinsCavern"..i, {
            locks={LOCKS.TIER0},
            keys_given= {KEYS.RUINS, KEYS.TIER1},
            crosslink_factor = 0,
            room_choices={
                ["BGWilds"] = 4,
            },
            room_bg=GROUND.MUD,
            background_room="PitRoom",
            colour={r=1,g=0.7,b=0.0,a=1},
        })
    AddTask("CavesCavern"..i, {
            locks={LOCKS.TIER0},
            keys_given= {KEYS.CAVE, KEYS.TIER1},
            crosslink_factor = 0,
            room_choices={
                ["BGCaveRoom"] = 4,
            },
            room_bg=GROUND.MUD,
            background_room="PitRoom",
            colour={r=1,g=1,b=1.0,a=1},
        })
end

AddTask("RuinsCore", {
        locks={LOCKS.NONE},
        keys_given= {KEYS.TIER0},
        room_choices={
            ["PondWilds"] = math.random(1,3),
            ["SlurperWilds"] = math.random(1,3),
            ["LushWilds"] = math.random(1,2),
            ["LightWilds"] = math.random(1,3),
        },
        room_bg=GROUND.MUD,
        background_room="BGWilds",
        colour={r=0,g=0,b=0.0,a=1},
    })

AddTask("Residential", {
        locks = {LOCKS.TIER1, LOCKS.RUINS},
        keys_given = {KEYS.TIER2, KEYS.RUINS},
        entrance_room = "RuinedCityEntrance",
        room_choices =
        {
            ["Vacant"] = 4,
        },
        room_bg = GROUND.TILES,
        maze_tiles = {rooms = {"room_residential", "room_residential_two", "hallway_residential", "hallway_residential_two"}, bosses = {"room_residential"}},
        background_room="Blank",
        colour={r=0.2,g=0.2,b=0.0,a=1},
    })

AddTask("TheLabyrinth", {
        locks={LOCKS.RUINS, LOCKS.TIER2},
        keys_given= {KEYS.SACRED, KEYS.RUINS, KEYS.TIER3},
        entrance_room="LabyrinthEntrance",
        room_choices={
            ["BGLabyrinth"] = 3+math.random(SIZE_VARIATION), 
            ["LabyrinthGuarden"] = 1, 
        },
        room_bg=GROUND.BRICK,
        background_room="BGLabyrinth",
        colour={r=0.4,g=0.4,b=0.0,a=1},
    })


AddTask("Military", {
        locks = {LOCKS.RUINS, LOCKS.TIER3},
        keys_given = {KEYS.RUINS, KEYS.TIER4},
        entrance_room = "MilitaryEntrance",
        room_choices =
        {
            ["BGMilitary"] = 4,
        },
        room_bg = GROUND.TILES,
        maze_tiles = {rooms = {"pit_room_armoury", "pit_hallway_armoury", "pit_room_armoury_two"}, bosses = {"pit_room_armoury_two"}},
        background_room="BGMilitary",
        colour={r=0.6,g=0.6,b=0.0,a=1},
    })

AddTask("Sacred", {
        locks = {LOCKS.SACRED, LOCKS.RUINS, LOCKS.TIER3},
        keys_given = {KEYS.SACRED, KEYS.RUINS, KEYS.TIER4},
        room_choices =
        {
            ["Barracks"] = math.random(1,2),
            ["Bishops"] = math.random(1,2),
            ["Spiral"] = math.random(1,2),
            ["BrokenAltar"] = math.random(1,2),
        },
        room_bg = GROUND.TILES,
        background_room="Blank",
        colour={r=0.6,g=0.6,b=0.0,a=1},
    })

AddTask("SacredAltar",{
        locks = {LOCKS.SACRED, LOCKS.RUINS, LOCKS.TIER4},
        keys_given = {KEYS.SACRED, KEYS.RUINS, KEYS.TIER5},
        room_choices =
        {
            ["Altar"] = 1
        },
        room_bg = GROUND.TILES,
        entrance_room="BridgeEntrance",
        background_room="Blank",
        colour={r=0.6,g=0.3,b=0.0,a=1},
    })



----Optional Ruins Tasks----



AddTask("MoreAltars", {
        locks = {LOCKS.SACRED, LOCKS.RUINS, LOCKS.TIER3},
        keys_given = {KEYS.SACRED, KEYS.RUINS, KEYS.TIER4},
        room_choices =
        {
            ["BrokenAltar"] =  math.random(1,2),
            ["Altar"] = math.random(1,2)
        },
        room_bg = GROUND.TILES,
        background_room="BGSacredGround",
        colour={r=1,g=0,b=0.6,a=1},
    })
AddTask("SacredDanger", {
        locks = {LOCKS.SACRED, LOCKS.RUINS, LOCKS.TIER4},
        keys_given = {KEYS.SACRED, KEYS.RUINS, KEYS.TIER5},
        room_choices =
        {
            ["Barracks"] = math.random(1,2),
        },
        room_bg = GROUND.TILES,
        background_room="BGSacredGround",
        colour={r=1,g=0,b=0.6,a=1},
    })
AddTask("FailedCamp", {
        locks={LOCKS.ANYTIER, LOCKS.PASSAGE},
        keys_given= {KEYS.CAVERN},
        room_choices={
            ["RuinsCamp"] = 1,          
        },
        room_bg=GROUND.MUD,
        background_room="BGWilds",
        colour={r=1,g=0,b=0.6,a=1},
    })

AddTask("Military2", {
        locks = {LOCKS.RUINS, LOCKS.TIER3},
        keys_given = {KEYS.RUINS, KEYS.TIER4},
        entrance_room = "MilitaryEntrance",
        room_choices =
        {
            ["BGMilitary"] = 1+math.random(SIZE_VARIATION),
        },
        room_bg = GROUND.TILES,
        maze_tiles = {rooms = {"room_armoury", "hallway_armoury", "room_armoury_two"}, bosses = {"room_armoury_two"}},
        background_room="BGMilitary",
        colour={r=1,g=0,b=0.6,a=1},
    })
AddTask("Sacred2", {
        locks = {LOCKS.SACRED, LOCKS.RUINS, LOCKS.TIER3},
        keys_given = {KEYS.SACRED, KEYS.RUINS, KEYS.TIER4},
        room_choices =
        {
            ["Barracks"] = math.random(1,2),
            ["Bishops"] = math.random(1,2),
            ["Spiral"] = math.random(1,2),
            ["BrokenAltar"] = math.random(1,2),
        },
        room_bg = GROUND.TILES,
        background_room="BGSacredGround",
        colour={r=1,g=0,b=0.6,a=1},
    })

AddTask("Residential2", {
        locks = {LOCKS.TIER1, LOCKS.RUINS},
        keys_given = {KEYS.TIER2},
        entrance_room = "RuinedCityEntrance",
        room_choices =
        {
            ["BGMonkeyWilds"] = 1 + math.random(SIZE_VARIATION),
        },
        room_bg = GROUND.TILES,
        maze_tiles = {rooms = {"room_residential", "room_residential_two", "hallway_residential", "hallway_residential_two"}, bosses = {"room_residential"}},
        background_room="BGMonkeyWilds",
        colour={r=1,g=0,b=0.6,a=1},
    })

AddTask("Residential3", {
        locks = {LOCKS.OUTERTIER, LOCKS.RUINS},
        keys_given = {KEYS.TIER4},
        room_choices =
        {
            ["Vacant"] = 1 + math.random(SIZE_VARIATION),
        },
        room_bg = GROUND.TILES,
        background_room="BGWilds",
        colour={r=1,g=0,b=0.6,a=1},
    })
