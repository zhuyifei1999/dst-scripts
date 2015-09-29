require "map/room_functions"

------------------------------------------------------------------------------------
-- Ruins ---------------------------------------------------------------------------
------------------------------------------------------------------------------------


---------------------------------------------
-- Ruins Wilds
-- Lichen, ponds, monkeys, bananas, ferns
---------------------------------------------

--Wet Wilds
AddRoom("WetWilds", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.MUD,
    contents =  {
        distributepercent = 0.25,
        distributeprefabs=
        {
            lichen = .25,
            cave_fern = 0.1,
            pillar_algae = .01,
            pond_cave = 0.1,
            slurper = .05,
            fissure_lower = 0.05,
        }
    }
})

--Lichen Meadow
AddRoom("LichenMeadow", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.MUD,
    contents =  {
        distributepercent = 0.15,
        distributeprefabs=
        {
            lichen = 1.0,
            cave_fern = 1.0,
            pillar_algae = 0.1,
            slurper = 0.35,
            fissure_lower = 0.05,

            flower_cave = .05,
            flower_cave_double = .03,
            flower_cave_triple = .01,

            worm = 0.07,
            wormlight_plant = 0.15,
        }
    }
})

--Jungle
AddRoom("CaveJungle", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.MUD,
    contents =  {
        distributepercent = 0.35,
        distributeprefabs=
        {
            lichen = 0.3,
            cave_fern = 1,
            pillar_algae = 0.05,

            cave_banana_tree = 0.5,
            monkeybarrel = 0.1,

            slurper = 0.06,
            pond_cave = 0.07,
            fissure_lower = 0.04,
            worm = 0.04,
            wormlight_plant = 0.08,
        }
    }
})

--Monkey Meadow
AddRoom("MonkeyMeadow", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.MUD,
    contents =  {
        distributepercent = 0.1,
        distributeprefabs=
        {
            lichen = 0.3,
            cave_fern = 1,
            pillar_algae = 0.05,

            cave_banana_tree = 0.1,
            monkeybarrel = 0.06,

            slurper = 0.06,
            pond_cave = 0.07,
            fissure_lower = 0.04,
            worm = 0.04,
            wormlight_plant = 0.08,
        }
    }
})

--Lichen Land
AddRoom("LichenLand", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.MUD,
    contents =  {
        distributepercent = 0.35,
        distributeprefabs=
        {
            lichen = 2.0,
            cave_fern = 0.5,
            pillar_algae = 0.5,
            slurper = 0.05,
            fissure_lower = 0.05,
        }
    }
})

bgwilds = {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.MUD,
    contents =  {
        distributepercent = 0.15,
        distributeprefabs=
        {
            lichen = 0.1,
            cave_fern = 1,
            pillar_algae = 0.01,

            cave_banana_tree = 0.01,
            monkeybarrel = 0.01,

            flower_cave = 0.05,
            flower_cave_double = 0.03,
            flower_cave_triple = 0.01,

            worm = 0.07,
            wormlight_plant = 0.15,

            fissure_lower = 0.04,
        }
    }
}
AddRoom("BGWilds", bgwilds)
AddRoom("BGWildsRoom", Roomify(bgwilds))

---------------------------------------------
-- Residential
-- Debris, monkeys, light plants, ferns
---------------------------------------------

--Entrance
AddRoom("RuinedCityEntrance", {
    colour={r=0.2,g=0.0,b=0.2,a=0.3},
    value = GROUND.MUD,
    tags = {"ForceConnected", "MazeEntrance", "Nightmare"},--"Maze",
    contents =  {
        distributepercent = .07,
        distributeprefabs=
        {
            blue_mushroom = 1,
            cave_fern = 1,
            lichen = .5,
        },
    }
})

--City
AddRoom("RuinedCity", {-- Maze used to define room connectivity
    colour={r=.25,g=.28,b=.25,a=.50},
    value = GROUND.CAVE,
    tags = {"Maze", "Nightmare"},
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
    contents =  {
        distributepercent = 0.09,
        distributeprefabs=
        {
            lichen = .3,
            cave_fern = 1,
            pillar_algae = .05,

            cave_banana_tree = 0.1,
            monkeybarrel = 0.06,
            slurper = 0.06,
            pond_cave = 0.07,
            fissure_lower = 0.04,
            worm = 0.04,
        }
    }
})

--Houses
AddRoom("Vacant", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.MUD,
    tags = {"Nightmare"},
    contents =  {
        countstaticlayouts =
        {
            ["CornerWall"] = math.random(2,3),
            ["StraightWall"] = math.random(2,3),
            ["CornerWall2"] = math.random(2,3),
            ["StraightWall2"] = math.random(2,3),
        },
        distributepercent = 0.5,
        distributeprefabs=
        {
            lichen = .4,
            cave_fern = .6,
            pillar_algae = .01,
            slurper = .15,
            cave_banana_tree = .1,
            monkeybarrel = .2,
            dropperweb = .1,
            ruins_rubble_table = 0.1,
            ruins_rubble_chair = 0.1,
            ruins_rubble_vase = 0.1,
        }
    }
})

--Light Hut
AddRoom("LightHut", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.MUD,
    tags = {"Nightmare"},
    contents =  {
        countstaticlayouts =
        {
            ["THREE_WAY_N"] = 1,
        },
        distributepercent = 0.2,
        distributeprefabs=
        {
            lichen = 0.4,
            cave_fern = 0.6,
            pillar_algae = 0.01,
            slurper = 0.15,
            cave_banana_tree = 0.1,
            monkeybarrel = 0.2,
            dropperweb = 0.1,

            flower_cave = 0.5,
            flower_cave_double = 0.5,
            flower_cave_triple = 0.5,
        }
    }
})

---------------------------------------------
-- Military
-- Fat maze, ruins, thulecite walls, chessjunk
---------------------------------------------

--Entrance
AddRoom("MilitaryEntrance", {
    colour={r=0.2,g=0.0,b=0.2,a=0.3},
    value = GROUND.UNDERROCK,
    tags = {"ForceConnected", "MazeEntrance", "Nightmare"},
    contents =  {
        countstaticlayouts =
        {
            ["MilitaryEntrance"] = 1,
        },
    }
})

--Maze
AddRoom("MilitaryMaze",  { -- layout contents determined by maze
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.WALL_ROCKY,
    tags = {"Maze", "Nightmare"},
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
})

--Barracks
AddRoom("Barracks",{
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.CAVE,
    tags = {"Nightmare"},
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeSite,
    contents =  {
        countstaticlayouts =
        {
            ["Barracks"] = 1,
        },
        distributepercent = 0.03,
        distributeprefabs=
        {
            chessjunk1 = .1,
            chessjunk2 = .1,
            chessjunk3 = .1,

            nightmarelight = 1,

            rook_nightmare = .07,
            bishop_nightmare = .07,
            knight_nightmare = .07,
        }
    }
})

---------------------------------------------
-- Sacred
-- Ground patterns, statues, debris, pits, pillars
---------------------------------------------

--Bridge Entrance
AddRoom("BridgeEntrance",{
    colour={r=0.0,g=0.2,b=0.2,a=0.3},
    value = GROUND.IMPASSABLE,
    tags = {"ForceConnected", "RoadPoison", "Nightmare"},
    contents = {},
})

--Worship Area
AddRoom("Bishops",{
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.IMPASSABLE,
    tags = {"Nightmare"},
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeSite,
    contents =  {
        countstaticlayouts =
        {
            ["Barracks2"] = 1,
        },
    }
})

--Sacred Barracks
AddRoom("SacredBarracks",{
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.IMPASSABLE,
    tags = {"Nightmare"},
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeSite,
    contents =  {
        countstaticlayouts =
        {
            ["SacredBarracks"] = 1,
        },
    }
})

--Living quarters
AddRoom("Spiral",{
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.IMPASSABLE,
    tags = {"Nightmare"},
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeSite,
    contents =  {
        countstaticlayouts =
        {
            ["Spiral"] = 1,
        },
    }
})

--BrokenAltar
AddRoom("BrokenAltar", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.IMPASSABLE,
    tags = {"Nightmare"},
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeSite,
    contents =  {
        countstaticlayouts =
        {
            ["BrokenAltar"] = 1,
        },
    }
})

bgsacred = {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.BRICK,
    tags = {"Nightmare"},
    contents =  {
        distributepercent = 0.03,
        distributeprefabs=
        {
            chessjunk1 = .1,
            chessjunk2 = .1,
            chessjunk3 = .1,

            nightmarelight = 1,

            pillar_ruins = 0.5,

            ruins_statue_head = .1,
            ruins_statue_head_nogem = .2,

            ruins_statue_mage =.1,
            ruins_statue_mage_nogem = .2,

            rook_nightmare = .07,
            bishop_nightmare = .07,
            knight_nightmare = .07,
        }
    }
}
AddRoom("BGSacred", bgsacred)
AddRoom("BGSacredRoom", Roomify(bgsacred))


---------------------------------------------
-- Altar
-- Altar, statues, thulecite walls, pillars
---------------------------------------------

--The Altar
AddRoom("Altar", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.IMPASSABLE,
    tags = {"Nightmare"},
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeSite,
    contents =  {
        countstaticlayouts =
        {
            ["AltarRoom"] = 1,
        },
    }
})

---------------------------------------------
-- Labyrith
-- Thin maze, spider droppers, treasure, guardian
---------------------------------------------

--Entrance
AddRoom("LabyrinthEntrance", {
    colour={r=0.2,g=0.0,b=0.2,a=0.3},
    value = GROUND.MUD,
    tags = {"ForceConnected",  "LabyrinthEntrance", "Nightmare"},--"Labyrinth",
    contents =  {
        distributepercent = .2,
        distributeprefabs=
        {
            lichen = .8,
            cave_fern = 1,
            pillar_algae = .05,

            flower_cave = .2,
            flower_cave_double = .1,
            flower_cave_triple = .05,
        },
    }
})

--Maze
AddRoom("Labyrinth", {-- Not a real Labyrinth.. more of a maze really.
    colour={r=.25,g=.28,b=.25,a=.50},
    value = GROUND.BRICK,
    tags = {"Labyrinth", "Nightmare"},
    --internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
    contents =  {
        distributepercent = 0.1,
        distributeprefabs = {
            dropperweb = 0.5,

            ruins_rubble_vase = 0.1,
            ruins_rubble_chair = 0.1,
            ruins_rubble_table = 0.1,

            chessjunk1 = 0.01,
            chessjunk2 = 0.01,
            chessjunk3 = 0.01,

            rook_nightmare = 0.01,
            bishop_nightmare = 0.01,
            knight_nightmare = 0.01,

            thulecite_pieces = 0.05,
        },
    }
})

--Guarden
AddRoom("RuinedGuarden", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.MUD,
    tags = {"Nightmare"},
    type = NODE_TYPE.Room,
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeSite,
    contents =  {
        countstaticlayouts = {
            ["WalledGarden"] = 1,
        },
        countprefabs= {
            mushtree = function () return 3 + math.random(3) end,
            flower_cave = function () return 5 + math.random(3) end,
            gravestone = function () return 4 + math.random(4) end,
            mound = function () return 4 + math.random(4) end
        }
    }
})



---------------------------------------------
-- Expedition
-- Little bits to scatter elsewhere
-- Would this be better as just setpieces?? Easier to add tags if it's rooms...
---------------------------------------------
