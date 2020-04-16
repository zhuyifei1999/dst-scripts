local treasure_templates =
{
--	TREASUREPREFAB1 = -- Prefab to spawn at point
--	{
--		treasure_type_weight = 1, -- Relative container prefab appearance rate
--	
--		presets = -- OPTIONAL! If there are no presets the treasureprefab will simply spawn as is
--		{
--			PRESET1 = -- Preset names have no functionality other than making it easier to keep track of which one is which
--			{
--				preset_weight = 1, -- Relative preset appearance rate
--		
--				guaranteed_loot =
--				{
--					-- Container is guaranteed to contain this many of these prefabs
--					ITEMPREFAB1 = 5,
--					ITEMPREFAB2 = 7,
--					ITEMPREFAB3 = 9,
--				},
--				randomly_selected_loot =
--				{
--					-- One entry from each of these tables is randomly chosen based on weight and added to the container
--					{
--						ITEMPREFAB4 = 10,
--						ITEMPREFAB5 = 5,
--						ITEMPREFAB6 = 1,
--					},
--					... {}, ...
--				},
--				chance_loot =
--				{
--					-- Each of these have a chance to spawn and be added to the container
--					ITEMPREFAB7 = 0.5,
--					ITEMPREFAB8 = 0.5,
--					ITEMPREFAB9 = 0.1,
--				},
--			},
--			... PRESET2, PRESET3 ...
--		}
--	},
--	... TREASUREPREFAB2, TREASUREPREFAB3 ...

	sunkenchest =
	{
		treasure_type_weight = 1,

		presets =
		{
			---------------------------------------------------------------------------
			luxurytools =
			{
				preset_weight = 0.5,

				guaranteed_loot =
				{
					goldenaxe = 1,
					goldenshovel = 1,
					goldenpickaxe = 1,
				},
				randomly_selected_loot =
				{
					{
						goldenaxe = 2,
						goldenshovel = 2,
						goldenpickaxe = 2,
						redgem = 1,
						bluegem = 1,
						purplegem = 0.5,
						greengem = 0.5,
						orangegem = 0.5,
						yellowgem = 0.5,
					},
				},
				chance_loot =
				{
					hammer = 0.25,
					rocks = 0.65,
					cutstone = 0.5,
					cutstone = 0.5,
					log = 0.65,
					boards = 0.5,
					boards = 0.5,

					bluegem = 0.1,
					purplegem = 0.1,
				},
			},
			---------------------------------------------------------------------------
			saltminer =
			{
				preset_weight = 1,

				guaranteed_loot =
				{
					cookiecuttershell = 2,
					spear = 1,
					boatpatch = 2,
					saltrock = 2,
				},
				randomly_selected_loot =
				{
					{
						cookiecutterhat = 2,
						armormarble = 1,
						footballhat = 1,
						boat_item = 1,
					},
				},
				chance_loot =
				{
					spear = 0.5,
					cookiecuttershell = 0.5,
					cookiecuttershell = 0.25,
					saltrock = 0.5,
					saltrock = 0.5,
					saltrock = 0.25,
					boatpatch = 0.5,
					boatpatch = 0.5,
					boards = 0.25,
					boards = 0.25,
					boards = 0.25,
					boards = 0.25,
				},
			},
			---------------------------------------------------------------------------
			shadowmagic =
			{
				preset_weight = 0.5,

				guaranteed_loot =
				{
					nightmarefuel = 2,
					papyrus = 1,
				},
				randomly_selected_loot =
				{
					{
						pigskin = 1,
						livinglog = 1,
					},
					{
						pigskin = 1,
						livinglog = 1,
					},
					{
						redgem = 1,
						bluegem = 1,
						purplegem = 2,
						livinglog = 0.5,
					},
					{
						nightsword = 1,
						armor_sanity = 1,
						purpleamulet = 1,
					},
				},
				chance_loot =
				{
					nightmarefuel = 0.5,
					nightmarefuel = 0.5,
					purplegem = 0.75,
					purplegem = 0.25,
					goldnugget = 0.5,
					goldnugget = 0.5,
					goldnugget = 0.1,
					papyrus = 0.25,
				},
			},
			---------------------------------------------------------------------------
			traveler =
			{
				preset_weight = 1,

				guaranteed_loot =
				{
					strawhat = 1,
					compass = 1,
				},
				randomly_selected_loot =
				{
					{
						bedroll_straw = 1,
						bedroll_furry = 0.25,
					},
					{
						goggleshat = 1,
						trap = 1,
						birdtrap = 1,
						oceanfishingrod = 1,
						minerhat = 0.5,
						lantern = 0.5,
						cane = 0.75,
						orangestaff = 0.25,
					},
				},
				chance_loot =
				{
					strawhat = 0.1,
					papyrus = 0.5,
					papyrus = 0.5,
					papyrus = 0.5,
					rope = 0.5,
					rope = 0.5,
					rope = 0.5,
					orangegem = 0.1,
				},
			},
			---------------------------------------------------------------------------
			lunarisland =
			{
				preset_weight = 1,

				guaranteed_loot =
				{
					moonglass = 4,
				},
				randomly_selected_loot =
				{
					{
						moonglassaxe = 2,
						glasscutter = 1,
					},
					{
						turf_meteor = 1,
						turf_pebblebeach = 1,
						bathbomb = 1,
						dug_sapling_moon = 1,
					},
					{
						oar_driftwood = 1,
						driftwood_log = 1,
					}
				},
				chance_loot =
				{
					moonglass = 0.5,
					moonglass = 0.5,
					moonglass = 0.5,
					rock_avocado_fruit = 0.5,
					rock_avocado_fruit = 0.5,
					moonrocknugget = 0.25,
				},
			},
			---------------------------------------------------------------------------
			seafarer =
			{
				preset_weight = 1,
				
				guaranteed_loot =
				{
					boards = 3,
					boat_item = 1,
					rope = 2,
					oar = 1,
				},
				randomly_selected_loot =
				{
					{ anchor_item = 1, mast_item = 1, steeringwheel_item = 1, oar = 1, },
					{ anchor_item = 1, mast_item = 1, steeringwheel_item = 1, oar = 1, },
				},
				chance_loot =
				{
					rope = 0.25,
					boards = 0.5,
					boards = 0.5,
					bluegem = 0.1,
					redgem = 0.1,
					malbatross_feathered_weave = 0.1,
				},
			},
			---------------------------------------------------------------------------
			miner =
			{
				preset_weight = 1,
				
				guaranteed_loot =
				{
					goldnugget = 4,
					rocks = 2,
					pickaxe = 1,
				},
				randomly_selected_loot =
				{
					{ redgem = 1, bluegem = 1, yellowgem = 0.5, greengem = 0.5, orangegem = 0.5, purplegem = 0.5, },
					{ redgem = 1, bluegem = 1, yellowgem = 0.5, greengem = 0.5, orangegem = 0.5, purplegem = 0.5, },
					{ pickaxe = 3, goldenpickaxe = 1 },
				},
				chance_loot =
				{
					goldnugget = 0.5,
					goldnugget = 0.25,
					rocks = 0.5,
					redgem = 0.25,
					redgem = 0.25,
					bluegem = 0.25,
					bluegem = 0.25,
					cutstone = 0.5,
				},
			},
			---------------------------------------------------------------------------
			warpreparations =
			{
				preset_weight = 1,
				
				guaranteed_loot =
				{
					armorwood = 1,
					spear = 1,
				},
				randomly_selected_loot =
				{
					{
						armormarble = 1,
						footballhat = 1,
						staff_tornado = 1,
						whip = 0.5,
					},
					{
						boomerang = 1,
						spear = 1,
						axe = 1,
						blowdart_fire = 1,
						blowdart_sleep = 1,
						blowdart_yellow = 1,
					},
				},
				chance_loot =
				{
					trap_teeth = 0.5,
					trap_teeth = 0.5,
					blowdart_pipe = 0.5,
					blowdart_pipe = 0.5,
					blowdart_pipe = 0.5,
					flint = 0.5,
					flint = 0.25,
					flint = 0.25,
					flint = 0.25,
					flint = 0.25,
				},
			},
			---------------------------------------------------------------------------
			firehazard =
			{
				preset_weight = 1,
				
				guaranteed_loot =
				{
					ash = 8,
					firestaff = 1,
					charcoal = 3,
				},
				chance_loot =
				{
					ash = 0.5,
					ash = 0.5,
					ash = 0.5,
					ash = 0.5,
					ash = 0.5,
					ash = 0.5,
					firestaff = 0.05,
					charcoal = 0.5,
					charcoal = 0.5,
				},
			},
			---------------------------------------------------------------------------
			telelocator =
			{
				preset_weight = 0.5,
				
				guaranteed_loot =
				{
					telestaff = 1,
				},
				randomly_selected_loot =
				{
					{
						purplegem = 1,
						livinglog = 1,
						nightmarefuel = 1,
						goldnugget = 1,
					},
					{
						purplegem = 1,
						livinglog = 1,
						nightmarefuel = 1,
					},
				},
				chance_loot =
				{
					livinglog = 0.5,
					purplegem = 0.25,
					purplegem = 0.25,
					goldnugget = 0.5,
					nightmarefuel = 0.25,
				},
			},
			---------------------------------------------------------------------------
		},
	},
}

local trinkets =
{
	"trinket_3",
	"trinket_4",
	"trinket_5",
	"trinket_6",
	"trinket_7",
	"trinket_8",
	"trinket_9",
	"trinket_17",
	"trinket_22",
	"trinket_27",
}

-- local TRINKET_CHANCE = 0.015
local TRINKET_CHANCE = 0.99--@felix

local weighted_treasure_prefabs = {}
local weighted_treasure_contents = {}
for prefabname, data in pairs(treasure_templates) do
	weighted_treasure_prefabs[prefabname] = data.treasure_type_weight

	if data.presets ~= nil then -- If nil the prefab being spawned is not a container
		weighted_treasure_contents[prefabname] = {}
		for _, loottable in pairs(data.presets) do
			weighted_treasure_contents[prefabname][loottable] = loottable.preset_weight
		end
	end
end

local function GenerateTreasure(pt, overrideprefab, spawn_as_empty, postfn)
	local prefab = overrideprefab or weighted_random_choice(weighted_treasure_prefabs)

	local treasure = SpawnPrefab(prefab)
	if treasure ~= nil then
		local x, y, z = pt.x, pt.y, pt.z
		treasure.Transform:SetPosition(x, y, z)

		-- If overrideprefab is supplied but it has no entry in the 'treasure_templates' loot
		-- table in this file the prefab instance will be empty regardless of spawn_as_empty.

		if not spawn_as_empty and (treasure.components.container ~= nil or treasure.components.inventory ~= nil) and weighted_treasure_contents[prefab] ~= nil and type(weighted_treasure_contents) == "table" and next(weighted_treasure_contents[prefab]) ~= nil then
			local lootpreset = weighted_random_choice(weighted_treasure_contents[prefab])
			local prefabstospawn = {}
			
			if lootpreset.guaranteed_loot ~= nil then
				for itemprefab, count in pairs(lootpreset.guaranteed_loot) do
					for i = 1, count do
						table.insert(prefabstospawn, itemprefab)
					end
				end
			end
			
			if lootpreset.randomly_selected_loot ~= nil then
				for i, one_of in ipairs(lootpreset.randomly_selected_loot) do
					table.insert(prefabstospawn, weighted_random_choice(one_of))
				end
			end

			if lootpreset.chance_loot ~= nil then
				for itemprefab, chance in pairs(lootpreset.chance_loot) do
					if math.random() < chance then
						table.insert(prefabstospawn, itemprefab)
					end
				end
			end
			
			local item = nil
			for i, itemprefab in ipairs(prefabstospawn) do
				item = SpawnPrefab(itemprefab)
				item.Transform:SetPosition(x, y, z)
				if treasure.components.container ~= nil then
					treasure.components.container:GiveItem(item)
				else
					treasure.components.inventory:GiveItem(item)
				end
			end

			if math.random() < TRINKET_CHANCE then
				if treasure.components.container ~= nil then
					if not treasure.components.container:IsFull() then
						treasure.components.container:GiveItem(SpawnPrefab(trinkets[#trinkets]))
					end
				elseif treasure.components.inventory ~= nil then
					if not treasure.components.inventory:IsFull() then
						treasure.components.inventory:GiveItem(SpawnPrefab(trinkets[#trinkets]))
					end
				end
			end
		end

		if postfn ~= nil then
			postfn(treasure)
		end
	end

	return treasure
end

local function GetPrefabs()
	local prefabscontain = {}
	for treasureprefab, weighted_lists in pairs(weighted_treasure_contents) do
		prefabscontain[treasureprefab] = true -- Chests, etc

		if weighted_lists ~= nil and type(weighted_lists) == "table" and next(weighted_lists) ~= nil then
			for weighted_list, _--[[weight]] in pairs(weighted_lists) do
				if weighted_list.guaranteed_loot ~= nil then
					for itemprefab, _--[[count]] in pairs(weighted_list.guaranteed_loot) do
						prefabscontain[itemprefab] = true
					end
				end
				
				if weighted_list.randomly_selected_loot ~= nil then
					for i, v in ipairs(weighted_list.randomly_selected_loot) do
						for itemprefab, _--[[weight]] in pairs(v) do
							prefabscontain[itemprefab] = true
						end
					end
				end

				if weighted_list.chance_loot ~= nil then
					for itemprefab, _--[[chance]] in pairs(weighted_list.chance_loot) do
						prefabscontain[itemprefab] = true
					end
				end
			end
		end
	end

	local prefablist = {}
	for prefab, _ in pairs(prefabscontain) do
		table.insert(prefablist, prefab)
	end

	for i, trinketprefab in ipairs(trinkets) do
		table.insert(prefablist, trinketprefab)
	end

	return prefablist
end

return { GenerateTreasure = GenerateTreasure, GetPrefabs = GetPrefabs, treasure_templates = treasure_templates }