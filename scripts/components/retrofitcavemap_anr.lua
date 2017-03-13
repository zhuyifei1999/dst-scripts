

--------------------------------------------------------------------------
--[[ RetrofitCaveMap_ANR class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "RetrofitCaveMapA_NR should not exist on client")

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local MAX_PLACEMENT_ATTEMPTS = 50

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local retrofit_warts = false

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function RetrofitNewCaveContentPrefab(inst, prefab, min_space, dist_from_structures, nightmare)
	local attempt = 1
	local topology = TheWorld.topology

	local ret = nil

	nightmare = nightmare or false

	local searchnodes = {}
	for k = 1, #topology.nodes do
		if (nightmare == table.contains(topology.nodes[k].tags, "Nightmare")) 
			and not table.contains(topology.nodes[k].tags, "Atrium") 
			and not string.find(topology.ids[k], "RuinedGuarden") then

			table.insert(searchnodes, k)
		end
	end
	
	while attempt <= MAX_PLACEMENT_ATTEMPTS do
		local searchnode = searchnodes[math.random(#searchnodes)]
		local area =  topology.nodes[searchnode]
        
		local points_x, points_y = TheWorld.Map:GetRandomPointsForSite(area.x, area.y, area.poly, 1)
		if #points_x == 1 and #points_y == 1 then
			local x = points_x[1]
			local z = points_y[1]

			if TheWorld.Map:CanPlacePrefabFilteredAtPoint(x, 0, z, prefab) and
				TheWorld.Map:CanPlacePrefabFilteredAtPoint(x + min_space, 0, z, prefab) and
				TheWorld.Map:CanPlacePrefabFilteredAtPoint(x, 0, z + min_space, prefab) and
				TheWorld.Map:CanPlacePrefabFilteredAtPoint(x - min_space, 0, z, prefab) and
				TheWorld.Map:CanPlacePrefabFilteredAtPoint(x, 0, z - min_space, prefab) then
				
				local ents = TheSim:FindEntities(x, 0, z, min_space)
				if #ents == 0 then
					if dist_from_structures ~= nil then
						ents = TheSim:FindEntities(x, 0, z, dist_from_structures, {"structure"} )
					end
					
					if #ents == 0 then
						ret = SpawnPrefab(prefab)
						ret.Transform:SetPosition(x, 0, z)
						break
					end
				end
			end
		end
		attempt = attempt + 1
	end
	print ("Retrofitting world for " .. prefab .. ": " .. (attempt < MAX_PLACEMENT_ATTEMPTS and ("Success after "..attempt.." attempts.") or ("Failed to find a valid tile in "..#searchnodes.." nodes.")))
	return attempt < MAX_PLACEMENT_ATTEMPTS, ret
end

--------------------------------------------------------------------------
--[[ Private Heart of the Ruins functions ]]
--------------------------------------------------------------------------

local function HeartOfTheRuinsAtriumRetrofitting(inst)
	local obj_layout = require("map/object_layout")
	local entities = {}
	
	local map_width, map_height = TheWorld.Map:GetSize()

	local add_fn = {fn=function(prefab, points_x, points_y, current_pos_idx, entitiesOut, width, height, prefab_list, prefab_data, rand_offset) 
				local x = (points_x[current_pos_idx] - width/2.0)*TILE_SCALE
				local y = (points_y[current_pos_idx] - height/2.0)*TILE_SCALE
				x = math.floor(x*100)/100.0
				y = math.floor(y*100)/100.0
				if prefab == "wormhole_MARKER" then
					local p1 = SpawnPrefab("tentacle_pillar")
					p1.Transform:SetPosition(x, 0, y)

					local _,p2 = RetrofitNewCaveContentPrefab(inst, "tentacle_pillar", 3, 20)
					while p2 == nil do
						_, p2 = RetrofitNewCaveContentPrefab(inst, "tentacle_pillar", 3, 5)
					end
					
					p1.components.teleporter:Target(p2)
					p2.components.teleporter:Target(p1)
				else
					SpawnPrefab(prefab).Transform:SetPosition(x, 0, y)
				end
			end,
			args={entitiesOut=entities, width=map_width, height=map_height, rand_offset = false, debug_prefab_list=nil}
		}


	local top, left = 8, 8	
	local area_size = 6*8
	
	local function isvalidarea(_left, _top)
		for x = 0, 5*8 do
			for y = 0, 5*8 do
				if TheWorld.Map:GetTile(_left + x, _top + y) ~= GROUND.IMPASSABLE then
					return false
				end
			end
		end
		return true
	end

	local foundarea = false
	
	for x = 0, 5 do
		for y = 0, 5 do
			if (x == 0 or x == 5) or (y == 0 or y == 5) then
				left = 8 + (x > 0 and ((x * (map_width / 5)) - area_size - 16) or 0)
				top  = 8 + (y > 0 and ((y * (map_height / 5)) - area_size - 16) or 0)
				if isvalidarea(left, top) then
					foundarea = true
					break
				end
			end
		end
		if foundarea then
			break
		end
	end			
	
	if foundarea then
		local maze = {	{ "SINGLE_NORTH",	"L_EAST",		"SINGLE_NORTH",	"L_EAST" },
						{ "L_NORTH",		"FOUR_WAY",		"TUNNEL_NS",	"THREE_WAY_E" },
						{ "L_SOUTH",		"TUNNEL_EW",	"SINGLE_EAST",	"TUNNEL_EW" },
						{ "",				"SINGLE_WEST",	"L_WEST",		"THREE_WAY_S" } }

		for x = 1, 4 do
			for y = 1, 4 do
				if maze[x][y] ~= "" then
					obj_layout.Place({left + (x*8), top + (y*8)}, maze[x][y], add_fn, {"atrium_hallway", "atrium_hallway_two"}, TheWorld.Map)
				end
			end
		end
		
		obj_layout.Place({left + (3*8), top }, "SINGLE_NORTH", add_fn, {"atrium_end"}, TheWorld.Map)
		obj_layout.Place({left + (4*8), top + (5*8)}, "SINGLE_SOUTH", add_fn, {"atrium_start"}, TheWorld.Map)
		
		
		inst.components.retrofitcavemap_anr.requiresreset = true

		print ("Retrofitting for A New Reign: Heart of the Ruins - Successfully added atruim into the world.")
	else
		print ("Retrofitting for A New Reign: Heart of the Ruins - FAILED! Could not find anywhere to add the atruim into the world.")
	end
end


local function AddRuinsRespawner(prefab, spawnerprefab)
	local count = 0
	spawnerprefab = spawnerprefab or prefab
	for _, v in pairs(Ents) do
		if v ~= inst and v.prefab == prefab then
			local respawner = SpawnPrefab(spawnerprefab.."_ruinsrespawner_inst")
			respawner.Transform:SetPosition(v.Transform:GetWorldPosition())
			if prefab == spawnerprefab then
				respawner.components.objectspawner:TakeOwnership(v)
			end
			count = count + 1
		end
	end	
	
	if count == 0 then
		print ("Retrofitting for A New Reign: Heart of the Ruins - Could not find any "..spawnerprefab.." to add respawners for.")
	else
		print ("Retrofitting for A New Reign: Heart of the Ruins - Added "..count.." respawners for "..spawnerprefab.."." )
	end
	
	return count
end

local function HeartOfTheRuinsRuinsRetrofitting(inst)
	local function RepopNear(count, spawnerprefab, target, radius, repop)
		if count < repop then
			local targets = {}
			for _, v in pairs(Ents) do
				if v.prefab == target then
					table.insert(targets, v)
				end
			end
			
			if #targets > 0 then
				targets = shuffleArray(targets)
				local num_spawned = 0 
				for i = 1, (repop-count) do
					local pt = targets[math.random(#targets)]:GetPosition()
					local offset = FindWalkableOffset(pt, math.random(360), radius, 12, true, true)
					if offset ~= nil then
						local respawner = SpawnPrefab(spawnerprefab.."_ruinsrespawner_inst")
						respawner.Transform:SetPosition((pt+offset):Get())
						num_spawned = num_spawned + 1
					end
				end
				if num_spawned == 0 then
					print ("Retrofitting for A New Reign: Heart of the Ruins -   Could not find anywhere to added "..spawnerprefab.."_ruinsrespawner_inst.")
				else
					print ("Retrofitting for A New Reign: Heart of the Ruins -   Added "..num_spawned.." respawners for "..spawnerprefab.." near "..target.."." )
				end
			else
				print ("Retrofitting for A New Reign: Heart of the Ruins -   Could not find any "..target.." to add "..spawnerprefab.."_ruinsrespawner_inst near.")
			end
		end
	end
	
	local function RepopRandom(count, spawnerprefab, repop)
		if count < repop then
			print ("Retrofitting for A New Reign: Heart of the Ruins - Adding "..(repop-count).." new "..spawnerprefab.." to repopulate the ruins." )
			for i = count, (repop-1) do
				local _, respawner = RetrofitNewCaveContentPrefab(inst, spawnerprefab.."_ruinsrespawner_inst", 1, 1, true)
				if respawner ~= nil then
					count = count + 1
				end
			end
		end

		return count
	end

	RepopNear(AddRuinsRespawner("bishop_nightmare"), "bishop_nightmare", "nightmarelight", 6, 8)
	RepopNear(AddRuinsRespawner("knight_nightmare"), "knight_nightmare", "nightmarelight", 6, 8)
	RepopNear(AddRuinsRespawner("rook_nightmare"), "rook_nightmare", "nightmarelight", 6, 5)

	RepopRandom( AddRuinsRespawner("monkeybarrel"), "monkeybarrel", 15)
	RepopRandom( AddRuinsRespawner("slurper"), "slurper", 10)
	RepopRandom( AddRuinsRespawner("worm"), "worm", 7)
	
	local minotaur_respawner = true
	local minotaur_is_dead = false
	if AddRuinsRespawner("minotaur") == 0 then
		minotaur_is_dead = true
		if AddRuinsRespawner("minotaurchest", "minotaur") == 0 then
			minotaur_respawner = false
			for k,v in ipairs(TheWorld.topology.ids) do
				if string.find(v, "RuinedGuarden") then
					local node = TheWorld.topology.nodes[k]
					local respawner = SpawnPrefab("minotaur_ruinsrespawner_inst")
					respawner.Transform:SetPosition(node.cent[1], 0, node.cent[2])
					minotaur_respawner = true
					print ("Retrofitting for A New Reign: Heart of the Ruins - Added worst case respawner for the minotaur." )
				end
			end
		end
	end
	if minotaur_respawner == false then
		print ("Retrofitting for A New Reign: Heart of the Ruins - Could not find anywhere to add the minotaur respawern the world.")
	else
		if minotaur_is_dead then
			for _, v in pairs(Ents) do
				if v.prefab == "minotaur_ruinsrespawner_inst" then
					local offset =
						FindWalkableOffset(v:GetPosition(), 0, 2, 8, true, true) or
						FindWalkableOffset(v:GetPosition(), 0, 4, 16, true, true) or
						Vector3(0, 0, 0)

						SpawnPrefab("atrium_key").Transform:SetPosition((v:GetPosition() + offset):Get())
						print ("Retrofitting for A New Reign: Heart of the Ruins - Added atrium_key to world." )
				end
			end
		else
			print ("Retrofitting for A New Reign: Heart of the Ruins - Added minotaur is alive so atrium_key does not require retrofitting." )
		end
	end

end

local function HeartOfTheRuinsRuinsRetrofittingRespawnerFix(inst, first_hotr_retrofit)
	if first_hotr_retrofit then
		return -- this step is not needed
	end
	
	local function NoSpawnOnLoadAndReduce(prefab, cap)
		local remove_spawners = {}
		local count = 0
		local spawner_prefab = prefab.."_ruinsrespawner_inst"
		for _, v in pairs(Ents) do
			if v.prefab == spawner_prefab then
				v.resetruins = nil
				
				count = count + 1
				if count > cap then
					table.insert(remove_spawners, v)
				end
			end
		end	
		
		if #remove_spawners > 0 then
			print ("Retrofitting for A New Reign: Heart of the Ruins + Respawn Fix: Reducing from " .. count .. " to " .. cap .. " " .. prefab .. "'s.")

			inst:DoTaskInTime(0, function()
				for _,v in ipairs(remove_spawners) do 
					if v.components.objectspawner ~= nil and (#v.components.objectspawner.objects == 1) then
						v.components.objectspawner.objects[1]:Remove()
					end
					v:Remove()
				end
			end)
		end
	end
	
	NoSpawnOnLoadAndReduce("bishop_nightmare", 10)
	NoSpawnOnLoadAndReduce("knight_nightmare", 14)
	NoSpawnOnLoadAndReduce("rook_nightmare", 5)
	NoSpawnOnLoadAndReduce("monkeybarrel", 20)
	NoSpawnOnLoadAndReduce("slurper", 10)
	NoSpawnOnLoadAndReduce("worm", 7)
	NoSpawnOnLoadAndReduce("minotaur", 1)
end

local function HeartOfTheRuinsRuinsRetrofittingAltar(inst)
	AddRuinsRespawner("ancient_altar_broken")
	AddRuinsRespawner("ancient_altar")
	
	for k,v in ipairs(TheWorld.topology.ids) do
		if string.sub(v, -string.len("Altar")) == "Altar" then
			local node = TheWorld.topology.nodes[k]
			
			if TheWorld.Map:IsAboveGroundAtPoint(node.x, 0, node.y) then
				local altars = TheSim:FindEntities(node.x, 0, node.y, 32, {"altar"})
				if #altars == 0 then
					local respawner = SpawnPrefab("ancient_altar_broken_ruinsrespawner_inst")
					respawner.Transform:SetPosition(node.x, 0, node.y)
					print ("Retrofitting for A New Reign: Heart of the Ruins + Altar Respawner - Added respawner to " .. v .. " for missing ancient_altar_broken.")
				end
			end
		end
	end	
end

local function HeartOfTheRuinsRuinsRetrofittingCaveHoles(inst)
	local count = 8
	for _,v in pairs(Ents) do
		if v.prefab == "cave_hole" then
			count = count - 1
		end
	end
	
	if count <= 0 then
		print ("Retrofitting for A New Reign: Heart of the Ruins + Cave Holes - Not Required!")
	else
		for i = 0, count do
			RetrofitNewCaveContentPrefab(inst, "cave_hole", 4, 20, true)
		end
	end

end

--------------------------------------------------------------------------
--[[ Post initialization ]]
--------------------------------------------------------------------------

function self:OnPostInit()
	if retrofit_warts then
		print ("Retrofitting for A New Reign: Warts and All.")
		local success = false
		success = RetrofitNewCaveContentPrefab(inst, "toadstool_cap", 7, 40) or success
		success = RetrofitNewCaveContentPrefab(inst, "toadstool_cap", 7, 40) or success
		success = RetrofitNewCaveContentPrefab(inst, "toadstool_cap", 7, 40) or success
		while not success do
			print ("Retrofitting for A New Reign: Warts and All. - Trying really hard to find a spot for Toadstool.")
			success = RetrofitNewCaveContentPrefab(inst, "toadstool_cap", 4, 40)
		end
	end

	if self.retrofit_artsandcrafts then
		self.retrofit_artsandcrafts = nil
		
		local count = 10
	    for k,v in pairs(Ents) do
			if v ~= inst and v.prefab == "spiderhole" then
				count = count - 1
				if count == 0 then
					break
				end
			end
		end
		
		if count > 0 then
			print ("Retrofitting for A New Reign: Arts and Crafts.")
			for i = 1,count do
				RetrofitNewCaveContentPrefab(inst, "fossil_piece", 1)
			end
		else
			print ("Retrofitting for A New Reign: Arts and Crafts is not required.")
		end
	end

	local first_hotr_retrofit = self.retrofit_heartoftheruins ~= nil
	if self.retrofit_heartoftheruins then
		self.retrofit_heartoftheruins = nil
		
		print ("Retrofitting for A New Reign: Heart of the Ruins.")
		HeartOfTheRuinsAtriumRetrofitting(inst)
		HeartOfTheRuinsRuinsRetrofitting(inst)
	end	
	
	if self.retrofit_heartoftheruins_respawnerfix then
		self.retrofit_heartoftheruins_respawnerfix = nil
		HeartOfTheRuinsRuinsRetrofittingRespawnerFix(inst, first_hotr_retrofit)
	end
	
	if self.retrofit_heartoftheruins_altars then
		self.retrofit_heartoftheruins_altars = nil
		
		print ("Retrofitting for A New Reign: Heart of the Ruins + Altar Respawner" )
		HeartOfTheRuinsRuinsRetrofittingAltar(inst)
	end	
	
	if self.retrofit_heartoftheruins_caveholes then
		self.retrofit_heartoftheruins_caveholes = nil
		
		print ("Retrofitting for A New Reign: Heart of the Ruins + Cave Holes" )
		HeartOfTheRuinsRuinsRetrofittingCaveHoles(inst)
	end	
	
	
	---------------------------------------------------------------------------
	if inst.components.retrofitcavemap_anr.requiresreset then
		-- not quite working in all cases...

		print ("Retrofitting for A New Reign. Savefile retrofitting requires the server to be restarted to fully take effect.")
		print ("Retrofitting for A New Reign. Restarting caves in 40 seconds.")

        inst:DoTaskInTime(5, function() TheNet:Announce("World will reload in 35 seconds to complete retrofitting.") end)
        inst:DoTaskInTime(10, function() TheNet:Announce("World will reload in 30 seconds to complete retrofitting.") end)
        inst:DoTaskInTime(15, function() TheNet:Announce("World will reload in 25 seconds to complete retrofitting.") end)
        inst:DoTaskInTime(20, function() TheNet:Announce("World will reload in 20 seconds to complete retrofitting.") end)
        inst:DoTaskInTime(25, function() TheNet:Announce("World will reload in 15 seconds to complete retrofitting.") end)
		inst:DoTaskInTime(30, function() TheWorld:PushEvent("ms_save") TheNet:Announce("World will reload in 10 seconds to complete retrofitting.") end)
		inst:DoTaskInTime(35, function() TheNet:Announce("World will reload in 5 seconds to complete retrofitting.") end)
		inst:DoTaskInTime(40, function() TheNet:SendWorldRollbackRequestToServer(0) end)
	end

end

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
	return {}
end

function self:OnLoad(data)
    if data ~= nil then
		retrofit_warts = data.retrofit_warts or false
		self.retrofit_artsandcrafts = data.retrofit_artsandcrafts
		self.retrofit_heartoftheruins = data.retrofit_heartoftheruins
		self.retrofit_heartoftheruins_respawnerfix = data.retrofit_heartoftheruins_respawnerfix
		self.retrofit_heartoftheruins_altars = data.retrofit_heartoftheruins_altars
		self.retrofit_heartoftheruins_caveholes = data.retrofit_heartoftheruins_caveholes
    end
end

--------------------------------------------------------------------------
end)