require("recipe")
require("tuning")

--Note: If you want to add a new tech tree you must also add it into the "TECH" constant in constants.lua

mod_protect_Recipe = false

--LIGHT
Recipe("campfire", {Ingredient("cutgrass", 3),Ingredient("log", 2)}, RECIPETABS.LIGHT, TECH.NONE, "campfire_placer")
Recipe("firepit", {Ingredient("log", 2),Ingredient("rocks", 12)}, RECIPETABS.LIGHT, TECH.NONE, "firepit_placer")
Recipe("lighter", {Ingredient("rope", 1), Ingredient("goldnugget", 1), Ingredient("petals", 3)}, RECIPETABS.LIGHT, TECH.NONE, nil, nil, nil, nil, "pyromaniac")
Recipe("torch", {Ingredient("cutgrass", 2),Ingredient("twigs", 2)}, RECIPETABS.LIGHT, TECH.NONE)
Recipe("coldfire", {Ingredient("cutgrass", 3), Ingredient("nitre", 2)}, RECIPETABS.LIGHT, TECH.SCIENCE_ONE, "coldfire_placer")
Recipe("coldfirepit", {Ingredient("nitre", 2), Ingredient("cutstone", 4), Ingredient("transistor", 2)}, RECIPETABS.LIGHT, TECH.SCIENCE_TWO, "coldfirepit_placer")

Recipe("minerhat", {Ingredient("strawhat", 1),Ingredient("goldnugget", 1),Ingredient("fireflies", 1)}, RECIPETABS.LIGHT, TECH.SCIENCE_TWO)
--Recipe("molehat", {Ingredient("mole", 2), Ingredient("transistor", 2), Ingredient("wormlight", 1)}, RECIPETABS.LIGHT,  TECH.SCIENCE_TWO)
Recipe("pumpkin_lantern", {Ingredient("pumpkin", 1), Ingredient("fireflies", 1)}, RECIPETABS.LIGHT, TECH.SCIENCE_TWO)
Recipe("lantern", {Ingredient("twigs", 3), Ingredient("rope", 2), Ingredient("lightbulb", 2)}, RECIPETABS.LIGHT, TECH.SCIENCE_TWO)

--STRUCTURES
Recipe("spidereggsack", {Ingredient("silk", 12), Ingredient("spidergland", 6), Ingredient("papyrus", 6)}, RECIPETABS.TOWN, TECH.NONE, nil, nil, nil, nil, "spiderwhisperer")
Recipe("treasurechest", {Ingredient("boards", 3)}, RECIPETABS.TOWN, TECH.SCIENCE_ONE, "treasurechest_placer",1)
Recipe("homesign", {Ingredient("boards", 1)}, RECIPETABS.TOWN, TECH.SCIENCE_ONE, "homesign_placer")
Recipe("arrowsign_post", {Ingredient("boards", 1)}, RECIPETABS.TOWN, TECH.SCIENCE_ONE, "arrowsign_post_placer")

Recipe("wall_hay_item", {Ingredient("cutgrass", 4), Ingredient("twigs", 2) }, RECIPETABS.TOWN, TECH.SCIENCE_ONE,nil,nil,nil,4)
Recipe("wall_wood_item", {Ingredient("boards", 2),Ingredient("rope", 1)}, RECIPETABS.TOWN,  TECH.SCIENCE_ONE,nil,nil,nil,8)
Recipe("wall_stone_item", {Ingredient("cutstone", 2)}, RECIPETABS.TOWN, TECH.SCIENCE_TWO,nil,nil,nil,6)
Recipe("wall_moonrock_item", {Ingredient("moonrocknugget", 12)}, RECIPETABS.TOWN, TECH.SCIENCE_TWO,nil,nil,nil,4)

Recipe("pighouse", {Ingredient("boards", 4), Ingredient("cutstone", 3), Ingredient("pigskin", 4)}, RECIPETABS.TOWN, TECH.SCIENCE_TWO, "pighouse_placer")
Recipe("rabbithouse", {Ingredient("boards", 4), Ingredient("carrot", 10), Ingredient("manrabbit_tail", 4)}, RECIPETABS.TOWN, TECH.SCIENCE_TWO, "rabbithouse_placer")
Recipe("birdcage", {Ingredient("papyrus", 2), Ingredient("goldnugget", 6), Ingredient("seeds", 2)}, RECIPETABS.TOWN, TECH.SCIENCE_TWO, "birdcage_placer")

Recipe("turf_road", {Ingredient("turf_rocky", 1), Ingredient("boards", 1)}, RECIPETABS.TOWN,  TECH.SCIENCE_TWO)
Recipe("turf_woodfloor", {Ingredient("boards", 1)}, RECIPETABS.TOWN, TECH.SCIENCE_TWO)
Recipe("turf_checkerfloor", {Ingredient("marble", 1)}, RECIPETABS.TOWN, TECH.SCIENCE_TWO)
Recipe("turf_carpetfloor", {Ingredient("boards", 1), Ingredient("beefalowool", 1)}, RECIPETABS.TOWN, TECH.SCIENCE_TWO)
Recipe("turf_dragonfly", {Ingredient("dragon_scales", 1), Ingredient("cutstone", 2)}, RECIPETABS.TOWN, TECH.SCIENCE_TWO, nil, nil, nil, 6)

Recipe("pottedfern", {Ingredient("foliage", 5), Ingredient("slurtle_shellpieces",1 )}, RECIPETABS.TOWN, TECH.SCIENCE_TWO, "pottedfern_placer", 0.9)

Recipe("dragonflychest", {Ingredient("dragon_scales", 1), Ingredient("boards", 4), Ingredient("goldnugget", 10)}, RECIPETABS.TOWN, TECH.SCIENCE_TWO, "dragonflychest_placer", 1.5)


--FARM
Recipe("slow_farmplot", {Ingredient("cutgrass", 8),Ingredient("poop", 4),Ingredient("log", 4)}, RECIPETABS.FARM,  TECH.SCIENCE_ONE, "slow_farmplot_placer")
Recipe("fast_farmplot", {Ingredient("cutgrass", 10),Ingredient("poop", 6),Ingredient("rocks", 4)}, RECIPETABS.FARM,  TECH.SCIENCE_TWO, "fast_farmplot_placer")
Recipe("fertilizer", {Ingredient("poop",3), Ingredient("boneshard", 2), Ingredient("log", 4)}, RECIPETABS.FARM, TECH.SCIENCE_TWO)
Recipe("beebox", {Ingredient("boards", 2),Ingredient("honeycomb", 1),Ingredient("bee", 4)}, RECIPETABS.FARM, TECH.SCIENCE_ONE, "beebox_placer")
Recipe("meatrack", {Ingredient("twigs", 3),Ingredient("charcoal", 2), Ingredient("rope", 3)}, RECIPETABS.FARM, TECH.SCIENCE_ONE, "meatrack_placer")
Recipe("cookpot", {Ingredient("cutstone", 3),Ingredient("charcoal", 6), Ingredient("twigs", 6)}, RECIPETABS.FARM,  TECH.SCIENCE_ONE, "cookpot_placer")
Recipe("icebox", {Ingredient("goldnugget", 2), Ingredient("gears", 1), Ingredient("cutstone", 1)}, RECIPETABS.FARM,  TECH.SCIENCE_TWO, "icebox_placer", 1.5)

--SURVIVAL
Recipe("reviver", {Ingredient("cutgrass", 3), Ingredient("spidergland", 1)}, RECIPETABS.SURVIVAL,  TECH.NONE)
Recipe("bernie_inactive", {Ingredient("beardhair", 2), Ingredient("beefalowool", 2), Ingredient("silk", 2)}, RECIPETABS.SURVIVAL,  TECH.NONE, nil, nil, nil, nil, "pyromaniac")
Recipe("trap", {Ingredient("twigs", 2),Ingredient("cutgrass", 6)}, RECIPETABS.SURVIVAL, TECH.NONE)
Recipe("birdtrap", {Ingredient("twigs", 3),Ingredient("silk", 4)}, RECIPETABS.SURVIVAL, TECH.SCIENCE_ONE)
Recipe("bugnet", {Ingredient("twigs", 4), Ingredient("silk", 2), Ingredient("rope", 1)}, RECIPETABS.SURVIVAL, TECH.SCIENCE_ONE)
Recipe("fishingrod", {Ingredient("twigs", 2),Ingredient("silk", 2)}, RECIPETABS.SURVIVAL, TECH.SCIENCE_ONE)
Recipe("grass_umbrella", {Ingredient("twigs", 4) ,Ingredient("cutgrass", 3), Ingredient("petals", 6)}, RECIPETABS.SURVIVAL, TECH.NONE)
Recipe("umbrella", {Ingredient("twigs", 6) ,Ingredient("pigskin", 1), Ingredient("silk",2 )}, RECIPETABS.SURVIVAL, TECH.SCIENCE_ONE)
Recipe("bandage", {Ingredient("papyrus", 1), Ingredient("honey", 2)}, RECIPETABS.SURVIVAL,  TECH.SCIENCE_TWO)
Recipe("healingsalve", {Ingredient("ash", 2), Ingredient("rocks", 1), Ingredient("spidergland",1)}, RECIPETABS.SURVIVAL,  TECH.SCIENCE_ONE)
Recipe("waterballoon", {Ingredient("mosquitosack", 2), Ingredient("ice", 1)}, RECIPETABS.SURVIVAL, TECH.SCIENCE_ONE, nil, nil, nil, 4)
Recipe("compass", {Ingredient("goldnugget", 1), Ingredient("flint", 1)}, RECIPETABS.SURVIVAL,  TECH.NONE)
Recipe("heatrock", {Ingredient("rocks", 10),Ingredient("pickaxe", 1),Ingredient("flint", 3)}, RECIPETABS.SURVIVAL, TECH.SCIENCE_TWO)
Recipe("backpack", {Ingredient("cutgrass", 4), Ingredient("twigs", 4)}, RECIPETABS.SURVIVAL, TECH.SCIENCE_ONE)
Recipe("piggyback", {Ingredient("pigskin", 4), Ingredient("silk", 6), Ingredient("rope", 2)}, RECIPETABS.SURVIVAL, TECH.SCIENCE_TWO)
Recipe("lifeinjector", {Ingredient("healingsalve", 2), Ingredient("papyrus", 3), Ingredient("stinger",1)}, RECIPETABS.SURVIVAL,  TECH.SCIENCE_TWO)
Recipe("bedroll_straw", {Ingredient("cutgrass", 6), Ingredient("rope", 1)}, RECIPETABS.SURVIVAL, TECH.SCIENCE_ONE)
Recipe("bedroll_furry", {Ingredient("bedroll_straw", 1), Ingredient("manrabbit_tail", 2)}, RECIPETABS.SURVIVAL, TECH.SCIENCE_TWO)
Recipe("tent", {Ingredient("silk", 6),Ingredient("twigs", 4),Ingredient("rope", 3)}, RECIPETABS.SURVIVAL, TECH.SCIENCE_TWO, "tent_placer")
Recipe("siestahut", {Ingredient("silk", 2),Ingredient("boards", 4),Ingredient("rope", 3)}, RECIPETABS.SURVIVAL, TECH.SCIENCE_TWO, "siestahut_placer")
Recipe("featherfan", {Ingredient("goose_feather", 5), Ingredient("cutreeds", 2), Ingredient("rope", 2)}, RECIPETABS.SURVIVAL, TECH.SCIENCE_TWO)
Recipe("icepack", {Ingredient("bearger_fur", 1), Ingredient("gears", 3), Ingredient("transistor", 3)}, RECIPETABS.SURVIVAL, TECH.SCIENCE_TWO)

--TOOLS
Recipe("axe", {Ingredient("twigs", 1),Ingredient("flint", 1)}, RECIPETABS.TOOLS, TECH.NONE)
Recipe("goldenaxe", {Ingredient("twigs", 4),Ingredient("goldnugget", 2)}, RECIPETABS.TOOLS,  TECH.SCIENCE_TWO)
Recipe("pickaxe", {Ingredient("twigs", 2),Ingredient("flint", 2)}, RECIPETABS.TOOLS, TECH.NONE)
Recipe("goldenpickaxe", {Ingredient("twigs", 4),Ingredient("goldnugget", 2)}, RECIPETABS.TOOLS,  TECH.SCIENCE_TWO)
Recipe("shovel", {Ingredient("twigs", 2),Ingredient("flint", 2)}, RECIPETABS.TOOLS,  TECH.SCIENCE_ONE)
Recipe("goldenshovel", {Ingredient("twigs", 4),Ingredient("goldnugget", 2)}, RECIPETABS.TOOLS,  TECH.SCIENCE_TWO)

Recipe("hammer", {Ingredient("twigs", 3),Ingredient("rocks", 3), Ingredient("cutgrass", 6)}, RECIPETABS.TOOLS, TECH.NONE)
Recipe("pitchfork", {Ingredient("twigs", 2),Ingredient("flint", 2)}, RECIPETABS.TOOLS,  TECH.SCIENCE_ONE)
Recipe("razor", {Ingredient("twigs", 2), Ingredient("flint", 2)}, RECIPETABS.TOOLS,  TECH.SCIENCE_ONE)



--SCIENCE
Recipe("researchlab", {Ingredient("goldnugget", 1),Ingredient("log", 4),Ingredient("rocks", 4)}, RECIPETABS.SCIENCE, TECH.NONE, "researchlab_placer")
Recipe("researchlab2", {Ingredient("boards", 4),Ingredient("cutstone", 2), Ingredient("transistor", 2)}, RECIPETABS.SCIENCE,  TECH.SCIENCE_ONE, "researchlab2_placer")
Recipe("transistor", {Ingredient("goldnugget", 2), Ingredient("cutstone", 1)}, RECIPETABS.SCIENCE, TECH.SCIENCE_ONE)
Recipe("diviningrod", {Ingredient("twigs", 1), Ingredient("nightmarefuel", 4), Ingredient("gears", 1)}, RECIPETABS.SCIENCE, TECH.SCIENCE_TWO)
Recipe("winterometer", {Ingredient("boards", 2), Ingredient("goldnugget", 2)}, RECIPETABS.SCIENCE,  TECH.SCIENCE_ONE, "winterometer_placer")
Recipe("rainometer", {Ingredient("boards", 2), Ingredient("goldnugget", 2), Ingredient("rope",2)}, RECIPETABS.SCIENCE,  TECH.SCIENCE_ONE, "rainometer_placer")
Recipe("gunpowder", {Ingredient("rottenegg", 1), Ingredient("charcoal", 1), Ingredient("nitre", 1)}, RECIPETABS.SCIENCE,  TECH.SCIENCE_TWO)
Recipe("lightning_rod", {Ingredient("goldnugget", 4), Ingredient("cutstone", 1)}, RECIPETABS.SCIENCE,  TECH.SCIENCE_ONE, "lightning_rod_placer")
Recipe("firesuppressor", {Ingredient("gears", 2),Ingredient("ice", 15),Ingredient("transistor", 2)}, RECIPETABS.SCIENCE,  TECH.SCIENCE_TWO, "firesuppressor_placer")

--MAGIC
Recipe("abigail_flower", {Ingredient("petals", 6), Ingredient("nightmarefuel", 1)}, RECIPETABS.MAGIC, TECH.NONE, nil, nil, nil, nil, "ghostlyfriend")
Recipe("researchlab4", {Ingredient("rabbit", 4), Ingredient("boards", 4), Ingredient("tophat", 1)}, RECIPETABS.MAGIC, TECH.SCIENCE_ONE, "researchlab4_placer")
Recipe("researchlab3", {Ingredient("livinglog", 3), Ingredient("purplegem", 1), Ingredient("nightmarefuel", 7)}, RECIPETABS.MAGIC, TECH.MAGIC_TWO, "researchlab3_placer")
Recipe("resurrectionstatue", {Ingredient("boards", 4),Ingredient("cookedmeat", 4),Ingredient("beardhair", 4)}, RECIPETABS.MAGIC,  TECH.MAGIC_TWO, "resurrectionstatue_placer")
Recipe("panflute", {Ingredient("cutreeds", 5), Ingredient("mandrake", 1), Ingredient("rope", 1)}, RECIPETABS.MAGIC,  TECH.MAGIC_TWO)
Recipe("onemanband", {Ingredient("goldnugget", 2),Ingredient("nightmarefuel", 4),Ingredient("pigskin", 2)}, RECIPETABS.MAGIC, TECH.MAGIC_TWO)
Recipe("nightlight", {Ingredient("goldnugget", 8), Ingredient("nightmarefuel", 2),Ingredient("redgem", 1)}, RECIPETABS.MAGIC,  TECH.MAGIC_TWO, "nightlight_placer")
Recipe("armor_sanity", {Ingredient("nightmarefuel", 5),Ingredient("papyrus", 3)}, RECIPETABS.MAGIC,  TECH.MAGIC_THREE)
Recipe("nightsword", {Ingredient("nightmarefuel", 5),Ingredient("livinglog", 1)}, RECIPETABS.MAGIC,  TECH.MAGIC_THREE)
Recipe("batbat", {Ingredient("batwing", 5), Ingredient("livinglog", 2), Ingredient("purplegem", 1)}, RECIPETABS.MAGIC, TECH.MAGIC_THREE)
Recipe("armorslurper", {Ingredient("slurper_pelt", 6),Ingredient("rope", 2),Ingredient("nightmarefuel", 2)}, RECIPETABS.MAGIC,  TECH.MAGIC_THREE)

Recipe("amulet", {Ingredient("goldnugget", 3), Ingredient("nightmarefuel", 2),Ingredient("redgem", 1)}, RECIPETABS.MAGIC,  TECH.MAGIC_TWO)
Recipe("blueamulet", {Ingredient("goldnugget", 3), Ingredient("bluegem", 1)}, RECIPETABS.MAGIC,  TECH.MAGIC_TWO)
Recipe("purpleamulet", {Ingredient("goldnugget", 6), Ingredient("nightmarefuel", 4),Ingredient("purplegem", 2)}, RECIPETABS.MAGIC,  TECH.MAGIC_THREE)
Recipe("firestaff", {Ingredient("nightmarefuel", 2), Ingredient("spear", 1), Ingredient("redgem", 1)}, RECIPETABS.MAGIC, TECH.MAGIC_THREE)
Recipe("icestaff", {Ingredient("spear", 1),Ingredient("bluegem", 1)}, RECIPETABS.MAGIC,  TECH.MAGIC_TWO)
Recipe("telestaff", {Ingredient("nightmarefuel", 4), Ingredient("livinglog", 2), Ingredient("purplegem", 2)}, RECIPETABS.MAGIC, TECH.MAGIC_THREE)
Recipe("telebase", {Ingredient("nightmarefuel", 4), Ingredient("livinglog", 4), Ingredient("goldnugget", 8)}, RECIPETABS.MAGIC, TECH.MAGIC_THREE, "telebase_placer")

--REFINE
Recipe("rope", {Ingredient("cutgrass", 3)}, RECIPETABS.REFINE,  TECH.SCIENCE_ONE)
Recipe("boards", {Ingredient("log", 4)}, RECIPETABS.REFINE,  TECH.SCIENCE_ONE)
Recipe("cutstone", {Ingredient("rocks", 3)}, RECIPETABS.REFINE,  TECH.SCIENCE_ONE)
Recipe("papyrus", {Ingredient("cutreeds", 4)}, RECIPETABS.REFINE,  TECH.SCIENCE_ONE)
Recipe("bearger_fur", {Ingredient("furtuft", 90)}, RECIPETABS.REFINE, TECH.SCIENCE_TWO, nil, nil, nil, 3)
Recipe("nightmarefuel", {Ingredient("petals_evil", 4)}, RECIPETABS.REFINE, TECH.MAGIC_TWO)
Recipe("purplegem", {Ingredient("redgem",1), Ingredient("bluegem", 1)}, RECIPETABS.REFINE, TECH.MAGIC_TWO)

--WAR
Recipe("spear_wathgrithr", {Ingredient("twigs", 2), Ingredient("flint", 2), Ingredient("goldnugget", 2)}, RECIPETABS.WAR, {SCIENCE = 0, MAGIC = 0, ANCIENT = 0}, nil, nil, nil, nil, "valkyrie")
Recipe("wathgrithrhat", {Ingredient("goldnugget", 2), Ingredient("rocks", 2)}, RECIPETABS.WAR, {SCIENCE = 0, MAGIC = 0, ANCIENT = 0}, nil, nil, nil, nil, "valkyrie")
Recipe("spear", {Ingredient("twigs", 2),Ingredient("rope", 1),Ingredient("flint", 1) }, RECIPETABS.WAR,  TECH.SCIENCE_ONE)
Recipe("hambat", {Ingredient("pigskin", 1), Ingredient("twigs", 2), Ingredient("meat", 2)}, RECIPETABS.WAR,  TECH.SCIENCE_TWO)
Recipe("nightstick", {Ingredient("lightninggoathorn", 1), Ingredient("transistor", 2), Ingredient("nitre", 2)}, RECIPETABS.WAR, TECH.SCIENCE_TWO)
Recipe("armorgrass", {Ingredient("cutgrass", 10), Ingredient("twigs", 2)}, RECIPETABS.WAR,  TECH.NONE)
Recipe("armorwood", {Ingredient("log", 8),Ingredient("rope", 2)}, RECIPETABS.WAR,  TECH.SCIENCE_ONE)
Recipe("armormarble", {Ingredient("marble", 12),Ingredient("rope", 4)}, RECIPETABS.WAR,  TECH.SCIENCE_TWO)
Recipe("footballhat", {Ingredient("pigskin", 1), Ingredient("rope", 1)}, RECIPETABS.WAR,  TECH.SCIENCE_TWO)
Recipe("blowdart_sleep", {Ingredient("cutreeds", 2),Ingredient("stinger", 1),Ingredient("feather_crow", 1) }, RECIPETABS.WAR,  TECH.SCIENCE_ONE)
Recipe("blowdart_fire", {Ingredient("cutreeds", 2),Ingredient("charcoal", 1),Ingredient("feather_robin", 1) }, RECIPETABS.WAR,  TECH.SCIENCE_ONE)
Recipe("blowdart_pipe", {Ingredient("cutreeds", 2),Ingredient("houndstooth", 1),Ingredient("feather_robin_winter", 1) }, RECIPETABS.WAR,  TECH.SCIENCE_ONE)
Recipe("boomerang", {Ingredient("boards", 1),Ingredient("silk", 1),Ingredient("charcoal", 1)}, RECIPETABS.WAR,  TECH.SCIENCE_TWO)
Recipe("beemine", {Ingredient("boards", 1),Ingredient("bee", 4),Ingredient("flint", 1) }, RECIPETABS.WAR,  TECH.SCIENCE_ONE)
Recipe("trap_teeth", {Ingredient("log", 1),Ingredient("rope", 1),Ingredient("houndstooth", 1)}, RECIPETABS.WAR,  TECH.SCIENCE_TWO)
Recipe("armordragonfly", {Ingredient("dragon_scales", 1), Ingredient("armorwood", 1), Ingredient("pigskin", 3)}, RECIPETABS.WAR,  TECH.SCIENCE_TWO)
Recipe("staff_tornado", {Ingredient("goose_feather", 10), Ingredient("lightninggoathorn", 1), Ingredient("gears", 1)}, RECIPETABS.WAR,  TECH.SCIENCE_TWO)


--DRESSUP

Recipe("sewing_kit", {Ingredient("log", 1), Ingredient("silk", 8), Ingredient("houndstooth", 2)}, RECIPETABS.DRESS, TECH.SCIENCE_TWO)

Recipe("flowerhat", {Ingredient("petals", 12)}, RECIPETABS.DRESS, TECH.NONE)
Recipe("strawhat", {Ingredient("cutgrass", 12)}, RECIPETABS.DRESS,  TECH.NONE)
Recipe("tophat", {Ingredient("silk", 6)}, RECIPETABS.DRESS,  TECH.SCIENCE_ONE)
Recipe("rainhat", {Ingredient("mole", 2), Ingredient("strawhat", 1), Ingredient("boneshard", 1)}, RECIPETABS.DRESS, TECH.SCIENCE_TWO)
Recipe("earmuffshat", {Ingredient("rabbit", 2), Ingredient("twigs",1)}, RECIPETABS.DRESS, TECH.SCIENCE_ONE)
Recipe("beefalohat", {Ingredient("beefalowool", 8),Ingredient("horn", 1)}, RECIPETABS.DRESS,  TECH.SCIENCE_ONE)
Recipe("winterhat", {Ingredient("beefalowool", 4),Ingredient("silk", 4)}, RECIPETABS.DRESS,  TECH.SCIENCE_TWO)
Recipe("catcoonhat", {Ingredient("coontail", 4), Ingredient("silk", 4)}, RECIPETABS.DRESS, TECH.SCIENCE_TWO)
Recipe("watermelonhat", {Ingredient("watermelon", 1), Ingredient("twigs", 3)}, RECIPETABS.DRESS, TECH.SCIENCE_ONE)
Recipe("icehat", {Ingredient("transistor", 2), Ingredient("rope", 4), Ingredient("ice", 10)}, RECIPETABS.DRESS,  TECH.SCIENCE_TWO)
Recipe("beehat", {Ingredient("silk", 8), Ingredient("rope", 1)}, RECIPETABS.DRESS,  TECH.SCIENCE_TWO)
Recipe("featherhat", {Ingredient("feather_crow", 3),Ingredient("feather_robin", 2), Ingredient("tentaclespots", 2)}, RECIPETABS.DRESS,  TECH.SCIENCE_TWO)
Recipe("bushhat", {Ingredient("strawhat", 1),Ingredient("rope", 1),Ingredient("dug_berrybush", 1)}, RECIPETABS.DRESS,  TECH.SCIENCE_TWO)
Recipe("raincoat", {Ingredient("tentaclespots", 2), Ingredient("rope", 2), Ingredient("boneshard", 2)}, RECIPETABS.DRESS, TECH.SCIENCE_ONE)
Recipe("sweatervest", {Ingredient("houndstooth", 8),Ingredient("silk", 6)}, RECIPETABS.DRESS,  TECH.SCIENCE_TWO)
Recipe("trunkvest_summer", {Ingredient("trunk_summer", 1),Ingredient("silk", 8)}, RECIPETABS.DRESS,  TECH.SCIENCE_TWO)
Recipe("trunkvest_winter", {Ingredient("trunk_winter", 1),Ingredient("silk", 8), Ingredient("beefalowool", 2)}, RECIPETABS.DRESS,  TECH.SCIENCE_TWO)
Recipe("reflectivevest", {Ingredient("rope", 1), Ingredient("feather_robin", 3), Ingredient("pigskin", 2)}, RECIPETABS.DRESS,  TECH.SCIENCE_ONE)
Recipe("hawaiianshirt", {Ingredient("papyrus", 3), Ingredient("silk", 3), Ingredient("cactus_flower", 5)}, RECIPETABS.DRESS,  TECH.SCIENCE_TWO)
Recipe("cane", {Ingredient("goldnugget", 2), Ingredient("walrus_tusk", 1), Ingredient("twigs", 4)}, RECIPETABS.DRESS,  TECH.SCIENCE_TWO)
Recipe("beargervest", {Ingredient("bearger_fur", 1), Ingredient("sweatervest", 1), Ingredient("rope", 2)}, RECIPETABS.DRESS,  TECH.SCIENCE_TWO)
Recipe("eyebrellahat", {Ingredient("deerclops_eyeball", 1), Ingredient("twigs", 15), Ingredient("boneshard", 4)}, RECIPETABS.DRESS,  TECH.SCIENCE_TWO)


----GEMS----


----ANCIENT----
Recipe("thulecite", {Ingredient("thulecite_pieces", 6)}, RECIPETABS.ANCIENT, TECH.ANCIENT_TWO, nil, nil, true)

Recipe("wall_ruins_item", {Ingredient("thulecite", 1)}, RECIPETABS.ANCIENT, TECH.ANCIENT_TWO, nil, nil, true, 6)

Recipe("nightmare_timepiece", {Ingredient("thulecite", 2), Ingredient("nightmarefuel", 2)}, RECIPETABS.ANCIENT, TECH.ANCIENT_TWO, nil, nil, true)

Recipe("orangeamulet", {Ingredient("thulecite", 2), Ingredient("nightmarefuel", 3),Ingredient("orangegem", 1)}, RECIPETABS.ANCIENT,  TECH.ANCIENT_FOUR, nil, nil, true)
Recipe("yellowamulet", {Ingredient("thulecite", 2), Ingredient("nightmarefuel", 3),Ingredient("yellowgem", 1)}, RECIPETABS.ANCIENT, TECH.ANCIENT_TWO, nil, nil, true)
Recipe("greenamulet", {Ingredient("thulecite", 2), Ingredient("nightmarefuel", 3),Ingredient("greengem", 1)}, RECIPETABS.ANCIENT,  TECH.ANCIENT_TWO, nil, nil, true)

Recipe("orangestaff", {Ingredient("nightmarefuel", 2), Ingredient("cane", 1), Ingredient("orangegem", 2)}, RECIPETABS.ANCIENT, TECH.ANCIENT_FOUR, nil, nil, true)
Recipe("yellowstaff", {Ingredient("nightmarefuel", 4), Ingredient("livinglog", 2), Ingredient("yellowgem", 2)}, RECIPETABS.ANCIENT, TECH.ANCIENT_TWO, nil, nil, true)
Recipe("greenstaff", {Ingredient("nightmarefuel", 4), Ingredient("livinglog", 2), Ingredient("greengem", 2)}, RECIPETABS.ANCIENT, TECH.ANCIENT_TWO, nil, nil, true)

Recipe("multitool_axe_pickaxe", {Ingredient("goldenaxe", 1),Ingredient("goldenpickaxe", 1), Ingredient("thulecite", 2)}, RECIPETABS.ANCIENT, TECH.ANCIENT_FOUR, nil, nil, true)

Recipe("ruinshat", {Ingredient("thulecite", 4), Ingredient("nightmarefuel", 4)}, RECIPETABS.ANCIENT, TECH.ANCIENT_FOUR, nil, nil, true)
Recipe("armorruins", {Ingredient("thulecite", 6), Ingredient("nightmarefuel", 4)}, RECIPETABS.ANCIENT, TECH.ANCIENT_FOUR, nil, nil, true)
Recipe("ruins_bat", {Ingredient("livinglog", 3), Ingredient("thulecite", 4), Ingredient("nightmarefuel", 4)}, RECIPETABS.ANCIENT, TECH.ANCIENT_FOUR, nil, nil, true)
Recipe("eyeturret_item", {Ingredient("deerclops_eyeball", 1), Ingredient("minotaurhorn", 1), Ingredient("thulecite", 5)}, RECIPETABS.ANCIENT, TECH.ANCIENT_FOUR, nil, nil, true)

if ACCOMPLISHMENTS_ENABLED then
	Recipe("accomplishment_shrine", {Ingredient("goldnugget", 10), Ingredient("cutstone", 1), Ingredient("gears", 6)}, RECIPETABS.SCIENCE, TECH.SCIENCE_TWO, "accomplishment_shrine_placer")
end

----BOOK----
Recipe("book_birds", {Ingredient("papyrus", 2), Ingredient("bird_egg", 2)}, CUSTOM_RECIPETABS.BOOKS, {SCIENCE = 0, MAGIC = 0, ANCIENT = 0}, nil, nil, nil, nil, "bookbuilder")
Recipe("book_gardening", {Ingredient("papyrus", 2), Ingredient("seeds", 1), Ingredient("poop", 1)}, CUSTOM_RECIPETABS.BOOKS, {SCIENCE = 1}, nil, nil, nil, nil, "bookbuilder")
Recipe("book_sleep", {Ingredient("papyrus", 2), Ingredient("nightmarefuel", 2)}, CUSTOM_RECIPETABS.BOOKS, {MAGIC = 2}, nil, nil, nil, nil, "bookbuilder")
Recipe("book_brimstone", {Ingredient("papyrus", 2), Ingredient("redgem", 1)}, CUSTOM_RECIPETABS.BOOKS, {MAGIC = 3}, nil, nil, nil, nil, "bookbuilder")
Recipe("book_tentacles", {Ingredient("papyrus", 2), Ingredient("tentaclespots", 1)}, CUSTOM_RECIPETABS.BOOKS, {SCIENCE = 3}, nil, nil, nil, nil, "bookbuilder")


----UNCRAFTABLE----
--NOTE: These recipes are not supposed to be craftable!
Recipe("pighead", {Ingredient("pigskin", 4), Ingredient("twigs", 4)}, nil, TECH.LOST)
Recipe("mermhead", {Ingredient("spoiled_food", 4), Ingredient("twigs", 4)}, nil, TECH.LOST)


mod_protect_Recipe = true
