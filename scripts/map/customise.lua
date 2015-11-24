local tasks = require ("map/tasks")
local startlocations = require ("map/startlocations")

local freqency_descriptions
if PLATFORM ~= "PS4" then
	freqency_descriptions = {
		{ text = STRINGS.UI.SANDBOXMENU.SLIDENEVER, data = "never" },
		{ text = STRINGS.UI.SANDBOXMENU.SLIDERARE, data = "rare" },
		{ text = STRINGS.UI.SANDBOXMENU.SLIDEDEFAULT, data = "default" },
		{ text = STRINGS.UI.SANDBOXMENU.SLIDEOFTEN, data = "often" },
		{ text = STRINGS.UI.SANDBOXMENU.SLIDEALWAYS, data = "always" },
	}
else
	freqency_descriptions = {
		{ text = STRINGS.UI.SANDBOXMENU.SLIDENEVER, data = "never" },
		{ text = STRINGS.UI.SANDBOXMENU.SLIDERARE, data = "rare" },
		{ text = STRINGS.UI.SANDBOXMENU.SLIDEDEFAULT, data = "default" }
	}
end

--local location_descriptions = {
    --{ text = STRINGS.UI.SANDBOXMENU.LOCATIONFOREST, data = "forest" },
    --{ text = STRINGS.UI.SANDBOXMENU.LOCATIONCAVE, data = "cave" },
--}

local speed_descriptions = {
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEVERYSLOW, data = "veryslow" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDESLOW, data = "slow" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEDEFAULT, data = "default" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEFAST, data = "fast" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEVERYFAST, data = "veryfast" },
}

local day_descriptions = {
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEDEFAULT, data = "default" },

	{ text = STRINGS.UI.SANDBOXMENU.SLIDELONG.." "..STRINGS.UI.SANDBOXMENU.DAY, data = "longday" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDELONG.." "..STRINGS.UI.SANDBOXMENU.DUSK, data = "longdusk" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDELONG.." "..STRINGS.UI.SANDBOXMENU.NIGHT, data = "longnight" },

	{ text = STRINGS.UI.SANDBOXMENU.EXCLUDE.." "..STRINGS.UI.SANDBOXMENU.DAY, data = "noday" },
	{ text = STRINGS.UI.SANDBOXMENU.EXCLUDE.." "..STRINGS.UI.SANDBOXMENU.DUSK, data = "nodusk" },
	{ text = STRINGS.UI.SANDBOXMENU.EXCLUDE.." "..STRINGS.UI.SANDBOXMENU.NIGHT, data = "nonight" },

	{ text = STRINGS.UI.SANDBOXMENU.SLIDEALL.." "..STRINGS.UI.SANDBOXMENU.DAY, data = "onlyday" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEALL.." "..STRINGS.UI.SANDBOXMENU.DUSK, data = "onlydusk" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEALL.." "..STRINGS.UI.SANDBOXMENU.NIGHT, data = "onlynight" },
}

local season_length_descriptions = {
	{ text = STRINGS.UI.SANDBOXMENU.SLIDENEVER, data = "noseason" },	
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEVERYSHORT, data = "veryshortseason" },	
	{ text = STRINGS.UI.SANDBOXMENU.SLIDESHORT, data = "shortseason" },	
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEDEFAULT, data = "default" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDELONG, data = "longseason" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEVERYLONG, data = "verylongseason" },
	{ text = STRINGS.UI.SANDBOXMENU.RANDOM, data = "random"},
}

local season_start_descriptions = {
	{ text = STRINGS.UI.SANDBOXMENU.DEFAULT, data = "default"},-- 	image = "season_start_autumn.tex" },
	{ text = STRINGS.UI.SANDBOXMENU.WINTER, data = "winter"},-- 	image = "season_start_winter.tex" },
	{ text = STRINGS.UI.SANDBOXMENU.SPRING, data = "spring"},-- 	image = "season_start_summer.tex" },
	{ text = STRINGS.UI.SANDBOXMENU.SUMMER, data = "summer"},-- 	image = "season_start_summer.tex" },
	{ text = STRINGS.UI.SANDBOXMENU.AUTUMN_SPRING, data = "autumnorspring"},-- 	image = "season_start_summer.tex" },
	{ text = STRINGS.UI.SANDBOXMENU.WINTER_SUMMER, data = "winterorsummer"},-- 	image = "season_start_summer.tex" },
	{ text = STRINGS.UI.SANDBOXMENU.RANDOM, data = "random"},-- 	image = "season_start_summer.tex" },
}

local size_descriptions = nil
if PLATFORM == "PS4" then
	size_descriptions = {
		{ text = STRINGS.UI.SANDBOXMENU.SLIDESMALL, data = "default"},-- 	image = "world_size_small.tex"}, 	--350x350
		{ text = STRINGS.UI.SANDBOXMENU.SLIDESMEDIUM, data = "medium"},-- 	image = "world_size_medium.tex"},	--450x450
		{ text = STRINGS.UI.SANDBOXMENU.SLIDESLARGE, data = "large"},-- 	image = "world_size_large.tex"},	--550x550
	}
else
	size_descriptions = {
		-- { text = STRINGS.UI.SANDBOXMENU.SLIDETINY, data = "teeny"},-- 		image = "world_size_tiny.tex"}, 	--1x1
		{ text = STRINGS.UI.SANDBOXMENU.SLIDESMALL, data = "small"},-- 	image = "world_size_small.tex"}, 	--350x350
		{ text = STRINGS.UI.SANDBOXMENU.SLIDESMEDIUM, data = "medium"},-- 	image = "world_size_medium.tex"},	--450x450
		{ text = STRINGS.UI.SANDBOXMENU.SLIDESLARGE, data = "default"},-- 	image = "world_size_large.tex"},	--550x550
		{ text = STRINGS.UI.SANDBOXMENU.SLIDESHUGE, data = "huge"},-- 		image = "world_size_huge.tex"},	--800x800
		-- { text = STRINGS.UI.SANDBOXMENU.SLIDESHUMONGOUS, data = "humongous"},-- 		image = "world_size_huge.tex"},	--800x800
	}
end

local branching_descriptions = {
	{ text = STRINGS.UI.SANDBOXMENU.BRANCHINGNEVER, data = "never" },
	{ text = STRINGS.UI.SANDBOXMENU.BRANCHINGLEAST, data = "least" },
	{ text = STRINGS.UI.SANDBOXMENU.BRANCHINGANY, data = "default" },
	{ text = STRINGS.UI.SANDBOXMENU.BRANCHINGMOST, data = "most" },
}

local loop_descriptions = {
	{ text = STRINGS.UI.SANDBOXMENU.LOOPNEVER, data = "never" },
	{ text = STRINGS.UI.SANDBOXMENU.LOOPRANDOM, data = "default" },
	{ text = STRINGS.UI.SANDBOXMENU.LOOPALWAYS, data = "always" },
}

local complexity_descriptions = {
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEVERYSIMPLE, data = "verysimple" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDESIMPLE, data = "simple" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEDEFAULT, data = "default" },	
	{ text = STRINGS.UI.SANDBOXMENU.SLIDECOMPLEX, data = "complex" },	
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEVERYCOMPLEX, data = "verycomplex" },	
}

-- Read this from the levels.lua
local preset_descriptions = {
}

-- TODO: Read this from the tasks.lua
local yesno_descriptions = {
	{ text = STRINGS.UI.SANDBOXMENU.YES, data = "default" },
	{ text = STRINGS.UI.SANDBOXMENU.NO, data = "never" },
}

local GROUP = {
	["monsters"] = 	{	-- These guys come after you	
						order = 5,
						text = STRINGS.UI.SANDBOXMENU.CHOICEMONSTERS, 
						desc = freqency_descriptions,
						enable = false,
						items={
							["spiders"] = {value = "default", enable = false, image = "spiders.tex", order = 1, world={"forest"}}, 
							["cave_spiders"] = {value = "default", enable = false, image = "spiders.tex", order = 1, world={"cave"}}, 
							["hounds"] = {value = "default", enable = false, image = "hounds.tex", order = 2, world={"forest"}}, 
							["houndmound"] = {value = "default", enable = false, image = "houndmound.tex", order = 3, world={"forest"}},
							["merm"] = {value = "default", enable = false, image = "merms.tex", order = 4, world={"forest"}}, 
							["tentacles"] = {value = "default", enable = false, image = "tentacles.tex", order = 5}, 
							["chess"] = {value = "default", enable = false, image = "chess_monsters.tex", order = 6}, 
							["lureplants"] = {value = "default", enable = false, image = "lureplant.tex", order = 7, world={"forest"}},
							["walrus"] = {value = "default", enable = false, image = "mactusk.tex", order = 8, world={"forest"}},  
							["liefs"] = {value = "default", enable = false, image = "liefs.tex", order = 9}, 
							["deciduousmonster"] = {value = "default", enable = false, image = "deciduouspoison.tex", order = 10, world={"forest"}},
							["krampus"] = {value = "default", enable = false, image = "krampus.tex", order = 11, world={"forest"}},
							["bearger"] = {value = "default", enable = false, image = "bearger.tex", order = 12, world={"forest"}},
							["deerclops"] = {value = "default", enable = false, image = "deerclops.tex", order = 13, world={"forest"}},
							["goosemoose"] = {value = "default", enable = false, image = "goosemoose.tex", order = 14, world={"forest"}},
							["dragonfly"] = {value = "default", enable = false, image = "dragonfly.tex", order = 15, world={"forest"}},
							["bats"] = {value = "default", enable = false, image = "bats.tex", order = 16, world={"cave"}},
							["fissure"] = {value = "default", enable = false, image = "fissure.tex", order = 17, world={"cave"}},
							["worms"] = {value = "default", enable = false, image = "worms.tex", order = 18, world={"cave"}},
						}
					},
	["animals"] =  	{	-- These guys live and let live
						order= 4,
						text = STRINGS.UI.SANDBOXMENU.CHOICEANIMALS, 
						desc = freqency_descriptions,
						enable = false,
						items={
							-- ["mandrake"] = {value = "default", enable = false, image = "mandrake.tex", order = 1},
							["rabbits"] = {value = "default", enable = false, image = "rabbits.tex", order = 2, world={"forest"}},
							["moles"] = {value = "default", enable = false, image = "mole.tex", order = 3, world={"forest"}},
							["butterfly"] = {value = "default", enable = false, image = "butterfly.tex", order = 4, world={"forest"}},  
							["birds"] = {value = "default", enable = false, image = "birds.tex", order = 5, world={"forest"}},
							["buzzard"] = {value = "default", enable = false, image = "buzzard.tex", order = 6, world={"forest"}}, 
							["catcoon"] = {value = "default", enable = false, image = "catcoon.tex", order = 7, world={"forest"}}, 
							["perd"] = {value = "default", enable = false, image = "perd.tex", order = 8, world={"forest"}}, 
							["pigs"] = {value = "default", enable = false, image = "pigs.tex", order = 9, world={"forest"}}, 
							["lightninggoat"] = {value = "default", enable = false, image = "lightning_goat.tex", order = 10, world={"forest"}}, 
							["beefalo"] = {value = "default", enable = false, image = "beefalo.tex", order = 11, world={"forest"}}, 
							["beefaloheat"] = {value = "default", enable = false, image = "beefaloheat.tex", order = 12, world={"forest"}},
							["hunt"] = {value = "default", enable = false, image = "tracks.tex", order = 13, world={"forest"}},  
							["alternatehunt"] = {value = "default", enable = false, image = "alternatehunt.tex", order = 14, world={"forest"}},  
							["penguins"] = {value = "default", enable = false, image = "pengull.tex", order = 15, world={"forest"}},
							["ponds"] = {value = "default", enable = false, image = "ponds.tex", order = 16, world={"forest"}}, 
							["cave_ponds"] = {value = "default", enable = false, image = "ponds.tex", order = 16, world={"cave"}}, 
							["bees"] = {value = "default", enable = false, image = "beehive.tex", order = 17, world={"forest"}}, 
							["angrybees"] = {value = "default", enable = false, image = "wasphive.tex", order = 18, world={"forest"}}, 
							["tallbirds"] = {value = "default", enable = false, image = "tallbirds.tex", order = 19, world={"forest"}},  
							["slurper"] = {value = "default", enable = false, image = "slurper.tex", order = 20, world={"cave"}},
							["bunnymen"] = {value = "default", enable = false, image = "bunnymen.tex", order = 21, world={"cave"}},
							["slurtles"] = {value = "default", enable = false, image = "slurtles.tex", order = 22, world={"cave"}},
							["rocky"] = {value = "default", enable = false, image = "rocky.tex", order = 23, world={"cave"}},
							["monkey"] = {value = "default", enable = false, image = "monkey.tex", order = 24, world={"cave"}},
						}
					},
	["resources"] = {
						order= 2,
						text = STRINGS.UI.SANDBOXMENU.CHOICERESOURCES, 
						desc = freqency_descriptions,
						enable = false,
						items={
							["flowers"] = {value = "default", enable = false, image = "flowers.tex", order = 1, world={"forest"}},
							["grass"] = {value = "default", enable = false, image = "grass.tex", order = 2}, 
							["sapling"] = {value = "default", enable = false, image = "sapling.tex", order = 3}, 
							["marshbush"] = {value = "default", enable = false, image = "marsh_bush.tex", order = 4}, 
							["tumbleweed"] = {value = "default", enable = false, image = "tumbleweeds.tex", order = 5, world={"forest"}}, 
							["reeds"] = {value = "default", enable = false, image = "reeds.tex", order = 6}, 
							["trees"] = {value = "default", enable = false, image = "trees.tex", order = 7}, 
							["flint"] = {value = "default", enable = false, image = "flint.tex", order = 8},
							["rock"] = {value = "default", enable = false, image = "rock.tex", order = 9}, 
							["rock_ice"] = {value = "default", enable = false, image = "iceboulder.tex", order = 10, world={"forest"}}, 
							["meteorspawner"] = {value = "default", enable = false, image = "burntground.tex", order = 11, world={"forest"}}, 
							["meteorshowers"] = {value = "default", enable = false, image = "meteor.tex", order = 12, world={"forest"}}, 
							["mushtree"] = {value = "default", enable = false, image = "mushtree.tex", order = 13, world={"cave"}},
							["fern"] = {value = "default", enable = false, image = "fern.tex", order = 14, world={"cave"}},
							["flower_cave"] = {value = "default", enable = false, image = "flower_cave.tex", order = 15, world={"cave"}},
							["wormlights"] = {value = "default", enable = false, image = "wormlights.tex", order = 16, world={"cave"}},
						}
					},
	["unprepared"] ={
						order= 3,
						text = STRINGS.UI.SANDBOXMENU.CHOICEFOOD, 
						desc = freqency_descriptions,
						enable = true,
						items={
							["berrybush"] = {value = "default", enable = true, image = "berrybush.tex", order = 1}, 
							["carrot"] = {value = "default", enable = true, image = "carrot.tex", order = 2, world={"forest"}}, 
							["mushroom"] = {value = "default", enable = false, image = "mushrooms.tex", order = 3}, 
							["cactus"] = {value = "default", enable = false, image = "cactus.tex", order = 4, world={"forest"}}, 
							["banana"] = {value = "default", enable = false, image = "banana.tex", order = 5, world={"cave"}},
							["lichen"] = {value = "default", enable = false, image = "lichen.tex", order = 6, world={"cave"}},
						}
					},
	["misc"] =		{
						order= 1,
						text = STRINGS.UI.SANDBOXMENU.CHOICEMISC, 
						desc = nil,
						enable = true,
						items={
                            --["location"] = {value = "forest", enable = false, image = "world_map.tex", desc = location_descriptions, order = 0}, 
                            ["task_set"] = {value = "default", enable = false, image = "world_map.tex", desc = tasks.GetGenTaskLists, order = 1}, 
                            ["start_location"] = {value = "default", enable = false, image = "world_start.tex", desc = startlocations.GetGenStartLocations, order = 2}, 
							["world_size"] = {value = "default", enable = false, image = "world_size.tex", desc = size_descriptions, order = 3}, 
							["branching"] = {value = "default", enable = false, image = "world_branching.tex", desc = branching_descriptions, order = 4}, 
							["loop"] = {value = "default", enable = false, image = "world_loop.tex", desc = loop_descriptions, order = 5}, 
							["autumn"] = {value = "default", enable = true, image = "autumn.tex", desc = season_length_descriptions, order = 6},
							["winter"] = {value = "default", enable = true, image = "winter.tex", desc = season_length_descriptions, order = 7},
							["spring"] = {value = "default", enable = true, image = "spring.tex", desc = season_length_descriptions, order = 8},
							["summer"] = {value = "default", enable = true, image = "summer.tex", desc = season_length_descriptions, order = 9},
							["season_start"] = {value = "default", enable = false, image = "season_start.tex", desc = season_start_descriptions, order = 10}, 
							["day"] = {value = "default", enable = false, image = "day.tex", desc = day_descriptions, order = 11}, 
							["weather"] = {value = "default", enable = false, image = "rain.tex", desc = freqency_descriptions, order = 13}, 
							["lightning"] = {value = "default", enable = false, image = "lightning.tex", desc = freqency_descriptions, order = 14, world={"forest"}}, 
							["earthquakes"] = {value = "default", enable = false, image = "earthquakes.tex", desc = freqency_descriptions, order = 14, world={"cave"}}, 
							["frograin"] = {value = "default", enable = false, image = "frog_rain.tex", desc = freqency_descriptions, order = 15, world={"forest"}}, 
							["wildfires"] = {value = "default", enable = false, image = "smoke.tex", desc = freqency_descriptions, order = 16, world={"forest"}}, 
							["touchstone"] = {value = "default", enable = false, image = "resurrection.tex", desc = freqency_descriptions, order = 17}, 
							["boons"] = {value = "default", enable = false, image = "skeletons.tex", desc = freqency_descriptions, order = 18}, 
							["regrowth"] = {value = "default", enable = false, image = "regrowth.tex", desc = speed_descriptions, order = 17}, 
							["cavelight"] = {value = "default", enable = false, image = "cavelight.tex", desc = speed_descriptions, order = 18, world={"cave"}},
						}
					},
}

local function GetGroupForItem(target)
	for area,items in pairs(GROUP) do
		for name,item in pairs(items.items) do
			if name == target then
				return area
			end
		end
	end
	return "misc"
end

local function GetOptions(world)
    local options = {}

    local groups = {}
    for k,v in pairs(GROUP) do
        table.insert(groups,k)
    end

    table.sort(groups, function(a,b) return GROUP[a].order < GROUP[b].order end)

    for i,groupname in ipairs(groups) do
        local items = {}
        local group = GROUP[groupname]
        for k,v in pairs(group.items) do
            if world == nil or v.world == nil or table.contains(v.world, world) then
                table.insert(items, k)
            end
        end

        table.sort(items, function(a,b) return group.items[a].order < group.items[b].order end)

        for ii,itemname in ipairs(items) do
            local item = group.items[itemname]
            local values = item.desc and (type(item.desc)=="function" and item.desc(world) or item.desc) or group.desc
            table.insert(options, {name = itemname, image = item.image, options = values, default = item.value, group = groupname, grouplabel = group.text})
        end
    end

    return options
end

return {GetGroupForItem=GetGroupForItem, GROUP=GROUP, preset_descriptions=preset_descriptions, GetOptions=GetOptions}
