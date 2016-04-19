local PREFAB_SWAPS = {}

local next_swaps = nil

local function addPrefabSwap(t)
	if not PREFAB_SWAPS[t.category] then
		PREFAB_SWAPS[t.category] = {}
	end
	table.insert(PREFAB_SWAPS[t.category],t)
end

local function petrifyForest(world)
	-- only run if there is a world
	local area = nil
	local potentialList = {}
	for i, node in ipairs(world.topology.nodes) do

		local densities = world.generated.densities[world.topology.ids[i] ]
		if densities then
			for k,v in pairs(densities)do
				if k == "evergreen" or k == "evergreen_sparse" then
					table.insert(potentialList,i)
				end
			end
		end
	end

	for loop=1,3,1 do
		if #potentialList > 0 then
			local index = math.random(#potentialList)
			area = potentialList[index]

			table.remove(potentialList,index)
		end

		if area then
            world:PushEvent("ms_petrifyforest", { area = area })

            local function startPetrifySound()
                local pos = world.topology.nodes[area].cent
                SpawnPrefab("petrify_announce").Transform:SetPosition(pos[1], 0, pos[2])
            end
            world:DoTaskInTime(TUNING.SEG_TIME, startPetrifySound)

			local function _DoPetrifiedSpeech(world,player)
				if player then
			    	player.components.talker:Say(GetString(player, "ANNOUNCE_PETRIFED_TREES"))
				end
			end
	 		for i, v in ipairs(AllPlayers) do
        		world:DoTaskInTime( (TUNING.SEG_TIME * 1) + 1 + (math.random() * 2), _DoPetrifiedSpeech, v)
    		end
	 	end
 	end
end

SPAWN_DELAY_TIME_BASIC = TUNING.SEG_TIME * 3
SPAWN_TIME_BASIC = TUNING.SEG_TIME 
SPAWN_TIME_RAND_BASIC = TUNING.SEG_TIME

-- GRASS
addPrefabSwap( {					
					category="grass", 		
					weight=3, 		
					prefabs={"grass"}, 
					name="regular grass", 
					primary = true,
					trigger={ 
								season="summer",
								event = "new",
								prefab_spawns={{prefab="grass", delayTime=SPAWN_DELAY_TIME_BASIC,   spawnTime=SPAWN_TIME_BASIC, spawnTimeRand=SPAWN_TIME_RAND_BASIC}}, 
								prefab_disease = {	{prefab="grass"} },		
								disease_check = "disease_check_grass",
								disease_immunities = {terrain=GROUND.SAVANNA },						
							}, 														
				})

addPrefabSwap( {
					category="grass", 		
					weight=1, 		
					prefabs={"grassgekko"}, 
					name="grass gekko",
					trigger={ 
								season="winter",
								event="snow", 
								prefab_spawns={ {prefab="grassgekko",  delayTime=SPAWN_DELAY_TIME_BASIC,   spawnTime=SPAWN_TIME_BASIC, spawnTimeRand=SPAWN_TIME_RAND_BASIC}}, 
								prefab_disease = {	{prefab="grassgekko"} },								
							}, 
				})

-- TWIGS
addPrefabSwap( {
					category="twigs", 							
					weight=3, 		
					prefabs={"sapling"}, 
					name="regular twigs", 
					primary = true,
					trigger={ 				
								season="autumn",
								event="new", 
								prefab_disease = {	{prefab="sapling"} },
								prefab_spawns={{prefab="sapling",  delayTime=SPAWN_DELAY_TIME_BASIC,   spawnTime=SPAWN_TIME_BASIC, spawnTimeRand=SPAWN_TIME_RAND_BASIC}}, 								
							},					
				})

addPrefabSwap( {	
					category="twigs", 		
					weight=1, 	
					prefabs={"twiggytree","ground_twigs"},					
					name="twiggy trees",
					mercy_items = {"twigs"},
					trigger={ 
					
								season="spring",
								event="rain", 
								prefab_disease = {  {prefab="twiggytree"} },
								prefab_spawns={ {prefab="twiggytree",  delayTime=SPAWN_DELAY_TIME_BASIC,   spawnTime=SPAWN_TIME_BASIC, spawnTimeRand=SPAWN_TIME_RAND_BASIC}}, 	
							},					
				})

-- ROCKS
addPrefabSwap( {	
					category="rocks", 		
					weight=3, 		
					prefabs={"rock1"}, 
					name="regular rocks", 
					primary = true
				})

addPrefabSwap( {
					category="rocks", 		
					weight=1, 	
					prefabs={"rock_petrified_tree"}, 
					name="petrified trees",
					noActive = true, -- this can happen again the next year. It's not a whole prefab swap. 
					trigger={						
								season="autumn", 
								event = "full",
								prefab_events = {petrifyForest},
							},
				})

-- BERRIES
addPrefabSwap( { 
					category = "berries", 
					name="regular berries", 
					primary = true, 	
					weight=3, 
					prefabs={"berrybush"},  
					
					trigger={ 
								season="winter",
								event="snow", 
								prefab_disease = {{prefab="berrybush"}},
								prefab_spawns={{prefab="berrybush",  delayTime=SPAWN_DELAY_TIME_BASIC,   spawnTime=SPAWN_TIME_BASIC, spawnTimeRand=SPAWN_TIME_RAND_BASIC}}, 								
							},
				})

addPrefabSwap( {
					category = "berries",
					name="juicy berries",
					weight=1,
					prefabs={"berrybush_juicy"},

					trigger={
								season="spring",
								event="rain",
								prefab_disease = {{prefab="berrybush_juicy"}},
								prefab_spawns={{prefab="berrybush_juicy",delayTime=SPAWN_DELAY_TIME_BASIC,   spawnTime=SPAWN_TIME_BASIC, spawnTimeRand=SPAWN_TIME_RAND_BASIC}},
							},
				})


--#############################################################################################################
--		Some prefabs listed in the world gen tables are are not actually real prefabs.
--		After the filtering is done, these temp names need to be replaced with the real prefab names.
--#############################################################################################################
local PREFAB_PROXIES = {}

local function addPrefabProxy(proxy,prefab)
	PREFAB_PROXIES[proxy] = prefab
end

addPrefabProxy("perma_grass","grass")-- perma grass is there so that it's not culled when the grass gekkos are chosen
addPrefabProxy("ground_twigs","twigs")-- ground twigs are culled when twiggy firs are not selected.

--#############################################################################################################


local function getPrefabSwapsForSwapManager()
	local data = deepcopy(PREFAB_SWAPS)
	for k,v in pairs(data)do
        for i,set in ipairs(v)do
        	set.status = "active"
        end
    end
	return data
end

local function getPrefabSwapsForWorldGen()
	local data = getPrefabSwapsForSwapManager()

	return data
end

local function getNextSwaps()
	return next_swaps
end

local function getDefaultPrefabSwaps()
	local swaps = deepcopy(PREFAB_SWAPS)

	for k,v in pairs(swaps)do
        for i,set in ipairs(v)do
        	if set.primary then
        		set.status = "active"
        	else
        		set.status = "inactive"
        	end
        end
    end

	return swaps 
end

local function setNextSwaps(set)
-- this variable is an unordered list where the indexes are the categories 
-- of prefab swaps and the data are the names of the swap for that category

--eg:

-- set = {}
-- set["grass"] = "grass gekko"
-- set["berries"] = "juicy berries"
	print("OVERRIDING NEXT SWAPS")
	dumptable(set)
	next_swaps = set
end

local function getPrefabProxiesForWorldGen()
	return PREFAB_PROXIES
end

return {
	getNextSwaps = getNextSwaps,
	setNextSwaps = setNextSwaps,
	addPrefabProxy = addPrefabProxy,
	addPrefabSwap = addPrefabSwap,
	getPrefabSwapsForSwapManager = getPrefabSwapsForSwapManager,
	getPrefabSwapsForWorldGen = getPrefabSwapsForWorldGen,
	getPrefabProxiesForWorldGen = getPrefabProxiesForWorldGen,
	petrifyForest = petrifyForest,
	getDefaultPrefabSwaps = getDefaultPrefabSwaps,
}