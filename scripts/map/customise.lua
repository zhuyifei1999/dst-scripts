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

local speed_descriptions = {
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEVERYSLOW, data = "veryslow" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDESLOW, data = "slow" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEDEFAULT, data = "default" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEFAST, data = "fast" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEVERYFAST, data = "veryfast" },
}

local day_descriptions = {
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEALL.." "..STRINGS.UI.SANDBOXMENU.DAY, data = "onlyday" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEALL.." "..STRINGS.UI.SANDBOXMENU.DUSK, data = "onlydusk" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEALL.." "..STRINGS.UI.SANDBOXMENU.NIGHT, data = "onlynight" },
	
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEDEFAULT, data = "default" },

	{ text = STRINGS.UI.SANDBOXMENU.SLIDELONG.." "..STRINGS.UI.SANDBOXMENU.DAY, data = "longday" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDELONG.." "..STRINGS.UI.SANDBOXMENU.DUSK, data = "longdusk" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDELONG.." "..STRINGS.UI.SANDBOXMENU.NIGHT, data = "longnight" },
}

local season_descriptions = { 
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEALL.." "..STRINGS.UI.SANDBOXMENU.SUMMER, data = "onlysummer" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEALL.." "..STRINGS.UI.SANDBOXMENU.WINTER, data = "onlywinter" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDEDEFAULT, data = "default" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDELONG.." "..STRINGS.UI.SANDBOXMENU.SUMMER, data = "longsummer" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDELONG.." "..STRINGS.UI.SANDBOXMENU.WINTER, data = "longwinter" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDELONG.." "..STRINGS.UI.SANDBOXMENU.BOTH, data = "longboth" },
	{ text = STRINGS.UI.SANDBOXMENU.SLIDESHORT.." "..STRINGS.UI.SANDBOXMENU.BOTH, data = "shortboth" },
}

local season_start_descriptions = {
	{ text = STRINGS.UI.SANDBOXMENU.SUMMER, data = "summer"},-- 	image = "season_start_summer.tex" },
	{ text = STRINGS.UI.SANDBOXMENU.WINTER, data = "winter"},-- 	image = "season_start_winter.tex" },
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
		{ text = STRINGS.UI.SANDBOXMENU.SLIDESMALL, data = "default"},-- 	image = "world_size_small.tex"}, 	--350x350
		{ text = STRINGS.UI.SANDBOXMENU.SLIDESMEDIUM, data = "medium"},-- 	image = "world_size_medium.tex"},	--450x450
		{ text = STRINGS.UI.SANDBOXMENU.SLIDESLARGE, data = "large"},-- 	image = "world_size_large.tex"},	--550x550
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
							["spiders"] = {value = "default", enable = false, spinner = nil, image = "spiders.tex", order = 1}, 
							["tentacles"] = {value = "default", enable = false, spinner = nil, image = "tentacles.tex", order = 4}, 
							["hounds"] = {value = "default", enable = false, spinner = nil, image = "hounds.tex", order = 2}, 
							["liefs"] = {value = "default", enable = false, spinner = nil, image = "liefs.tex", order = 7}, 
							["walrus"] = {value = "default", enable = false, spinner = nil, image = "mactusk.tex", order = 6}, 
							["krampus"] = {value = "default", enable = false, spinner = nil, image = "krampus.tex", order = 9}, 
							["deerclops"] = {value = "default", enable = false, spinner = nil, image = "deerclops.tex", order = 10}, 
							["merm"] = {value = "default", enable = false, spinner = nil, image = "merms.tex", order = 3}, 
							["lureplants"] = {value = "default", enable = false, spinner = nil, image = "lureplant.tex", order = 5},
							["chess"] = {value = "default", enable = false, spinner = nil, image = "chess_monsters.tex", order = 8}, 
						}
					},
	["animals"] =  	{	-- These guys live and let live
						order= 4,
						text = STRINGS.UI.SANDBOXMENU.CHOICEANIMALS, 
						desc = freqency_descriptions,
						enable = false,
						items={
							--#srosen this is the original: when we add mandrakes back in, uncomment this entire block and DELETE the one below
							-- ["pigs"] = {value = "default", enable = false, spinner = nil, image = "pigs.tex", order = 6}, 
							-- ["tallbirds"] = {value = "default", enable = false, spinner = nil, image = "tallbirds.tex", order = 15}, 
							-- ["rabbits"] = {value = "default", enable = false, spinner = nil, image = "rabbits.tex", order = 2}, 
							-- ["beefalo"] = {value = "default", enable = false, spinner = nil, image = "beefalo.tex", order = 7}, 
							-- ["beefaloheat"] = {value = "default", enable = false, spinner = nil, image = "beefaloheat.tex", order = 8}, 
							-- ["hunt"] = {value = "default", enable = false, spinner = nil, image = "tracks.tex", order = 9}, 
							-- ["alternatehunt"] = {value = "default", enable = false, spinner = nil, image = "alternatehunt.tex", order = 10},  
							-- ["bees"] = {value = "default", enable = false, spinner = nil, image = "beehive.tex", order = 13}, 
							-- ["angrybees"] = {value = "default", enable = false, spinner = nil, image = "wasphive.tex", order = 14}, 
							-- ["birds"] = {value = "default", enable = false, spinner = nil, image = "birds.tex", order = 4}, 
							-- ["perd"] = {value = "default", enable = false, spinner = nil, image = "perd.tex", order = 5}, 
							-- ["frogs"] = {value = "default", enable = false, spinner = nil, image = "ponds.tex", order = 12}, 
							-- ["butterfly"] = {value = "default", enable = false, spinner = nil, image = "butterfly.tex", order = 3}, 
							-- ["penguins"] = {value = "default", enable = false, spinner = nil, image = "pengull.tex", order = 11}, 
							-- ["mandrake"] = {value = "default", enable = false, spinner = nil, image = "mandrake.tex", order = 1},



							--#srosen delete this when Mandrakes go back in
							["pigs"] = {value = "default", enable = false, spinner = nil, image = "pigs.tex", order = 3}, 
							["tallbirds"] = {value = "default", enable = false, spinner = nil, image = "tallbirds.tex", order = 14}, 
							["rabbits"] = {value = "default", enable = false, spinner = nil, image = "rabbits.tex", order = 1}, 
							["beefalo"] = {value = "default", enable = false, spinner = nil, image = "beefalo.tex", order = 6}, 
							["beefaloheat"] = {value = "default", enable = false, spinner = nil, image = "beefaloheat.tex", order = 7},
							["hunt"] = {value = "default", enable = false, spinner = nil, image = "tracks.tex", order = 8},  
							["alternatehunt"] = {value = "default", enable = false, spinner = nil, image = "alternatehunt.tex", order = 9},  
							["frogs"] = {value = "default", enable = false, spinner = nil, image = "ponds.tex", order = 11}, 
							["bees"] = {value = "default", enable = false, spinner = nil, image = "beehive.tex", order = 12}, 
							["angrybees"] = {value = "default", enable = false, spinner = nil, image = "wasphive.tex", order = 13}, 
							["perd"] = {value = "default", enable = false, spinner = nil, image = "perd.tex", order = 2}, 
							["butterfly"] = {value = "default", enable = false, spinner = nil, image = "butterfly.tex", order = 4}, 
							["birds"] = {value = "default", enable = false, spinner = nil, image = "birds.tex", order = 5},
							["penguins"] = {value = "default", enable = false, spinner = nil, image = "pengull.tex", order = 10},
						}
					},
	["resources"] = {
						order= 2,
						text = STRINGS.UI.SANDBOXMENU.CHOICERESOURCES, 
						desc = freqency_descriptions,
						enable = false,
						items={
							["grass"] = {value = "default", enable = false, spinner = nil, image = "grass.tex", order = 1}, 
							["rock"] = {value = "default", enable = false, spinner = nil, image = "rock.tex", order = 6}, 
							["sapling"] = {value = "default", enable = false, spinner = nil, image = "sapling.tex", order = 2}, 
							["reeds"] = {value = "default", enable = false, spinner = nil, image = "reeds.tex", order = 10}, 
							["trees"] = {value = "default", enable = false, spinner = nil, image = "trees.tex", order = 3}, 
							["marshbush"] = {value = "default", enable = false, spinner = nil, image = "marsh_bush.tex", order = 11}, 
							["flowers"] = {value = "default", enable = false, spinner = nil, image = "flowers.tex", order = 9},
							["flint"] = {value = "default", enable = false, spinner = nil, image = "flint.tex", order = 4},
							["rocks"] = {value = "default", enable = false, spinner = nil, image = "rocks.tex", order = 5},
							["meteorspawner"] = {value = "default", enable = false, spinner = nil, image = "burntground.tex", order = 7}, 
							["meteorshowers"] = {value = "default", enable = false, spinner = nil, image = "meteor.tex", order = 8}, 
						}
					},
	["unprepared"] ={
						order= 3,
						text = STRINGS.UI.SANDBOXMENU.CHOICEFOOD, 
						desc = freqency_descriptions,
						enable = true,
						items={
							["carrot"] = {value = "default", enable = true, spinner = nil, image = "carrot.tex", order = 2
--											images ={
--												"carrot_never.tex",
--												"carrot_rare.tex",
--												"carrot_default.tex",
--												"carrot_often.tex",
--												"carrot_always.tex",
--											}
										}, 
							["berrybush"] = {value = "default", enable = true, spinner = nil, image = "berrybush.tex", order = 1}, 
							["mushroom"] = {value = "default", enable = false, spinner = nil, image = "mushrooms.tex", order = 3}, 
						}
					},
	["misc"] =		{
						order= 1,
						text = STRINGS.UI.SANDBOXMENU.CHOICEMISC, 
						desc = nil,
						enable = true,
						items={
							--#srosen this is the original: when we add Caves back in, uncomment this entire block and DELETE the one below
							-- ["day"] = {value = "default", enable = false, spinner = nil, image = "day.tex", desc = day_descriptions, order = 6}, 
							-- ["season"] = {value = "default", enable = true, spinner = nil, image = "season.tex", desc = season_descriptions, order = 4}, 
							-- ["season_start"] = {value = "summer", enable = false, spinner = nil, image = "season_start.tex", desc = season_start_descriptions, order = 5}, 
							-- ["weather"] = {value = "default", enable = false, spinner = nil, image = "rain.tex", desc = freqency_descriptions, order = 7}, 
							-- ["lightning"] = {value = "default", enable = false, spinner = nil, image = "lightning.tex", desc = freqency_descriptions, order = 8}, 
							-- ["world_size"] = {value = "default", enable = false, spinner = nil, image = "world_size.tex", desc = size_descriptions, order = 1}, 
							-- ["branching"] = {value = "default", enable = false, spinner = nil, image = "world_branching.tex", desc = branching_descriptions, order = 2}, 
							-- ["loop"] = {value = "default", enable = false, spinner = nil, image = "world_loop.tex", desc = loop_descriptions, order = 3}, 
							-- ["boons"] = {value = "default", enable = false, spinner = nil, image = "skeletons.tex", desc = freqency_descriptions, order = 11}, 
							-- ["touchstone"] = {value = "default", enable = false, spinner = nil, image = "resurrection.tex", desc = freqency_descriptions, order = 10}, 
							-- ["cave_entrance"] = {value = "default", enable = false, spinner = nil, image = "caves.tex", desc = yesno_descriptions, order = 9},


							--#srosen delete this when Caves go back in
							["day"] = {value = "default", enable = false, spinner = nil, image = "day.tex", desc = day_descriptions, order = 6}, 
							["season"] = {value = "default", enable = true, spinner = nil, image = "season.tex", desc = season_descriptions, order = 4}, 
							["season_start"] = {value = "summer", enable = false, spinner = nil, image = "season_start.tex", desc = season_start_descriptions, order = 5}, 
							["weather"] = {value = "default", enable = false, spinner = nil, image = "rain.tex", desc = freqency_descriptions, order = 7}, 
							["lightning"] = {value = "default", enable = false, spinner = nil, image = "lightning.tex", desc = freqency_descriptions, order = 8}, 
							["world_size"] = {value = "default", enable = false, spinner = nil, image = "world_size.tex", desc = size_descriptions, order = 1}, 
							["branching"] = {value = "default", enable = false, spinner = nil, image = "world_branching.tex", desc = branching_descriptions, order = 2}, 
							["loop"] = {value = "default", enable = false, spinner = nil, image = "world_loop.tex", desc = loop_descriptions, order = 3}, 
							["boons"] = {value = "default", enable = false, spinner = nil, image = "skeletons.tex", desc = freqency_descriptions, order = 10}, 
							["touchstone"] = {value = "default", enable = false, spinner = nil, image = "resurrection.tex", desc = freqency_descriptions, order = 9}, 
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

return {GetGroupForItem=GetGroupForItem, GROUP=GROUP, preset_descriptions=preset_descriptions}
