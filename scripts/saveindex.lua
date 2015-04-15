SaveIndex = Class(function(self)
	self:Init()
end)

function SaveIndex:Init()
	self.data =
	{
		slots=
		{
		}
	}
	for k = 1, NUM_SAVE_SLOTS do

		local filename = "latest_" .. tostring(k)

		if BRANCH ~= "release" then
			filename = filename .. "_" .. BRANCH
		end

		self.data.slots[k] = 
		{
			current_mode = nil,
			modes = {survival= {file = filename}},
			resurrectors = {},
			dlc = {},
			server = {},
		}
	end
	self.current_slot = 1
end

function SaveIndex:GuaranteeMinNumSlots(numslots)
	if #self.data.slots < numslots then
		local filename = nil
		for i = 1, numslots do
			if self.data.slots[i] == nil then
				filename = "latest_" .. tostring(i)
				if BRANCH ~= "release" then
					filename = filename .. "_" .. BRANCH
				end
				self.data.slots[i] = 
				{
					current_mode = nil,
					modes = {survival= {file = filename}},
					resurrectors = {},
					dlc = {},
				}
			end
		end
	end
end

function SaveIndex:GetSaveGameName(type, slot)

	local savename = nil
	type = type or "unknown"

	if type == "cave" then
		local cavenum = self:GetCurrentCaveNum(slot)
		local levelnum = self:GetCurrentCaveLevel(slot, cavenum)
		savename = type .. "_" .. tostring(cavenum) .. "_" .. tostring(levelnum) .. "_" .. tostring(slot)
	else
		savename = type.."_"..tostring(slot)
	end

	
	if BRANCH ~= "release" then
		savename = savename .. "_" .. BRANCH
	end
	return savename
end

function SaveIndex:GetSaveIndexName()
	local name = "saveindex" 
	if BRANCH ~= "release" then
		name = name .. "_"..BRANCH
	end
	return name
end

function SaveIndex:Save(callback)

	local data = DataDumper(self.data, nil, false)
    local insz, outsz = TheSim:SetPersistentString(self:GetSaveIndexName(), data, ENCODE_SAVES, callback)
end

function SaveIndex:Load(callback)
	--This happens on game start.
	local filename = self:GetSaveIndexName()
    TheSim:GetPersistentString(filename,
        function(load_success, str)
			local success, savedata = RunInSandbox(str)

			-- If we are on steam cloud this will stop a currupt saveindex file from 
			-- ruining everyones day..
			if success and string.len(str) > 0 and savedata ~= nil then
				self.data = savedata

				-- fix up deprecated server data stored in survival mode area
				self:FixupServerData()

				print ("loaded "..filename)
			else
				print ("Could not load "..filename)
			end

            --V2C: save files are organized differently in DST so
            --     don't use the old VerifyFiles.
            --     Just fire the callback and keep going.
            callback()
	        --[[if PLATFORM == "PS4" then
                -- PS4 doesn't need to verify files. If they're missing then the save was damaged and wouldn't have been loaded.
                -- Just fire the callback and keep going.
                callback()
            else
				if TheNet:GetIsClient() then
					-- Clients should not verify save slots,
					-- Because they don't exist for a downloaded map
					callback()
				else
					self:VerifyFiles(callback)
				end
            end]]
        end)
end

--this also does recovery of pre-existing save files (sort of)
function SaveIndex:VerifyFiles(completion_callback)

	local pending_slots = {}
	for k,v in ipairs(self.data.slots) do
		pending_slots[k] = true
	end
	
	for k,v in ipairs(self.data.slots) do
		local dirty = false
		local files = {}
		if v.current_mode == "empty" then
			v.current_mode = nil
		end
		if v.modes then
			v.modes.empty = nil
			for k, v in pairs(v.modes) do
				table.insert(files, v.file)
			end
		end
		if not v.save_id then
			v.save_id = self:GenerateSaveID(k)
		end

		CheckFiles(function(status) 

			if v.modes then
				for kk,vv in pairs (v.modes) do
					if vv.file and not status[vv.file] then
						vv.file = nil
					end
				end

			 	if v.current_mode == nil then
			 		if v.modes.survival and v.modes.survival.file then
			 			v.current_mode = "survival"
			 		end
			 	end
			 end

		 	pending_slots[k] = nil

		 	if not next(pending_slots) then
		 		self:Save(completion_callback)
		 	end

		 end, files)
	end
end

function SaveIndex:GetModeData(slot, mode)
	if slot and mode and self.data.slots[slot] then
		if not self.data.slots[slot].modes then
			self.data.slots[slot].modes = {}
		end
		if not self.data.slots[slot].modes[mode] then
			self.data.slots[slot].modes[mode] = {}
		end
		return self.data.slots[slot].modes[mode]
	end

	return {}
end

function SaveIndex:GetServerData(slot)
    local server_data = {}
    if slot and self.data.slots and self.data.slots[slot] then
        server_data = self.data.slots[slot].server
    end
    
    return server_data
end

function SaveIndex:GetSaveFollowers(doer)
	local followers = {}

	if doer.components.leader then
		for follower,v in pairs(doer.components.leader.followers) do
			local ent_data = follower:GetPersistData()
			table.insert(followers, {prefab = follower.prefab, data = follower:GetPersistData()})
			follower:Remove()
		end
	end

	--special case for the chester_eyebone: look for inventory items with followers
	if doer.components.inventory then
		for k,item in pairs(doer.components.inventory.itemslots) do
			if item.components.leader then
				for follower,v in pairs(item.components.leader.followers) do
					local ent_data = follower:GetPersistData()
					table.insert(followers, {prefab = follower.prefab, data = follower:GetPersistData()})
					follower:Remove()
				end
			end
		end

		-- special special case, look inside equipped containers
		for k,equipped in pairs(doer.components.inventory.equipslots) do
			if equipped and equipped.components.container then
				local container = equipped.components.container
				for j,item in pairs(container.slots) do
					if item.components.leader then
						for follower,v in pairs(item.components.leader.followers) do
							local ent_data = follower:GetPersistData()
							table.insert(followers, {prefab = follower.prefab, data = follower:GetPersistData()})
							follower:Remove()
						end
					end
				end
			end
		end
	end

	if self.data~= nil and self.data.slots ~= nil and self.data.slots[self.current_slot] ~= nil then
	 	self.data.slots[self.current_slot].followers = followers
	end	
end

function SaveIndex:LoadSavedFollowers(doer)
    local x,y,z = doer.Transform:GetWorldPosition()

	if doer.components.leader and self.data.slots[self.current_slot].followers then
		for idx,follower in pairs(self.data.slots[self.current_slot].followers) do
			local ent  = SpawnPrefab(follower.prefab)
			if ent ~= nil then
				ent:SetPersistData(follower.data)

		        local angle = TheCamera.headingtarget + math.random()*10*DEGREES-5*DEGREES
		        x = x + .5*math.cos(angle)
		        z = z + .5*math.sin(angle)
		 		ent.Transform:SetPosition(x,y,z)
		 		if ent.MakeFollowerFn then
		 			ent.MakeFollowerFn(ent, doer)
		 		end
		 		ent.components.follower:SetLeader(doer)
			end
		end
		self.data.slots[self.current_slot].followers = nil
		self:Save(function () print("LoadSavedFollowers CB") end)
	end
end

function SaveIndex:GetResurrectorName( res )
	return self:GetSaveGameName(self.data.slots[self.current_slot].current_mode, self.current_slot)..":"..tostring(res.GUID)
end

function SaveIndex:GetResurrectorPenalty()
	if self.data.slots[self.current_slot].current_mode == "adventure" then
		return nil
	end

	local penalty = 0

	for k,v in pairs(self.data.slots[self.current_slot].resurrectors) do
		penalty = penalty + v
	end

	return penalty
end

function SaveIndex:ClearCurrentResurrectors()
	if self.data.slots[self.current_slot].resurrectors == nil then
		self.data.slots[self.current_slot].resurrectors = {}
		return
	end

	for k,v in pairs(self.data.slots[self.current_slot].resurrectors) do
		if string.find(k, self:GetSaveGameName(self.data.slots[self.current_slot].current_mode, self.current_slot))~= nil then
			self.data.slots[self.current_slot].resurrectors[k] = nil
		end
	end
	self:Save(function () print("ClearCurrentResurrectors CB") end)
end

function SaveIndex:RegisterResurrector(res, penalty)

	if self.data.slots[self.current_slot].resurrectors == nil then
		self.data.slots[self.current_slot].resurrectors = {}
	end
	print("RegisterResurrector", res)
	self.data.slots[self.current_slot].resurrectors[self:GetResurrectorName(res)] = penalty
	
	if PLATFORM ~= "PS4" then 
	    -- Don't need to save on each of these events as regular saveindex save will be enough to keep these consistent
	    self:Save(function () print("RegisterResurrector CB") end)
	end
end

function SaveIndex:DeregisterResurrector(res)

	if self.data.slots[self.current_slot].resurrectors == nil then
		self.data.slots[self.current_slot].resurrectors = {}
		return
	end

	print("DeregisterResurrector", res.inst)

	local name = self:GetResurrectorName(res)
	for k,v in pairs(self.data.slots[self.current_slot].resurrectors) do
		if k == name then
			print("DeregisterResurrector found", name)
			self.data.slots[self.current_slot].resurrectors[name] = nil
			
	        if PLATFORM ~= "PS4" then 
	            -- Don't need to save on each of these events as regular saveindex save will be enough to keep these consistent
			    self:Save(function () print("DeregisterResurrector CB") end)
			end
			return
		end
	end

	print("DeregisterResurrector", res.inst, "not found")
end

function SaveIndex:GetResurrector()
	if self.data.slots[self.current_slot].current_mode == "adventure" then
		return nil
	end
	if self.data.slots[self.current_slot].resurrectors == nil then
		return nil
	end
	for k,v in pairs(self.data.slots[self.current_slot].resurrectors) do
		return k
	end

	return nil
end

function SaveIndex:CanUseExternalResurector()
	return self.data.slots[self.current_slot].current_mode ~= "adventure"
end
function SaveIndex:GotoResurrector(cb)
	print ("SaveIndex:GotoResurrector()")

	if self.data.slots[self.current_slot].current_mode == "adventure" then
		assert(nil, "SaveIndex:GotoResurrector() In adventure mode! why are we here!!??")
		return
	end
	
	if self.data.slots[self.current_slot].resurrectors == nil then
		self.data.slots[self.current_slot].resurrectors = {}
		return
	end

	local file = string.split(self:GetResurrector(), ":")[1]
	local mode = string.split(file, "_")[1]

	print ("SaveIndex:GotoResurrector() File:", file, "Mode:", mode)
	if mode == "survival" then
		self:LeaveCave(cb)
	else
		local cavenum, level = string.match(file, "cave_(%d+)_(%d+)")
		cavenum = tonumber(cavenum)
		level = tonumber(level)
		print ("SaveIndex:GotoResurrector() File:", cavenum, "Mode:", level)
		self:EnterCave(cb, self.current_slot, cavenum, level)
	end

	print ("SaveIndex:GotoResurrector() done")
end

function SaveIndex:GetSaveDataFile(file, mode, cb)
	TheSim:GetPersistentString(file, function(load_success, str)
		
		if not load_success then
			if TheNet:GetIsClient() then
				assert(load_success, "SaveIndex:GetSaveData: Load failed for file ["..file.."] Please try joining again.")
			else
				assert(load_success, "SaveIndex:GetSaveData: Load failed for file ["..file.."] please consider deleting this save slot and trying again.")
			end
		end
		
		assert(str, "SaveIndex:GetSaveData: Encoded Savedata is NIL on load ["..file.."]")
		assert(#str>0, "SaveIndex:GetSaveData: Encoded Savedata is empty on load ["..file.."]")

        print("Deserialize world session from "..file)
		local success, savedata = RunInSandbox(str)
		
		--[[
		if not success then
			local file = io.open("badfile.lua", "w")
			if file then
				str = string.gsub(str, "},", "},\n")
				file:write(str)
				
				file:close()
			end
		end--]]

		assert(success, "Corrupt Save file ["..file.."]")
		assert(savedata, "SaveIndex:GetSaveData: Savedata is NIL on load ["..file.."]")
		assert(GetTableSize(savedata)>0, "SaveIndex:GetSaveData: Savedata is empty on load ["..file.."]")

		cb(savedata)
	end)
end

function SaveIndex:GetSaveData(slot, mode, cb)
	self.current_slot = slot
    local file =
        TheNet:GetWorldSessionFile(self.data.slots[slot].session_id) or
        self:GetModeData(slot, mode).file --backward compatibility
	SaveGameIndex:GetSaveDataFile(file, mode, cb)
end

function SaveIndex:GetPlayerData(slot, mode)
	local slot = slot or self.current_slot
	return self:GetModeData(slot, mode or self.data.slots[slot].current_mode).playerdata
end

function SaveIndex:DeleteSlot(slot, cb, save_options)
	local dlc = self.data.slots[slot].dlc
	local server = self.data.slots[slot].server
	local options = nil
	if  self.data.slots[slot] and  self.data.slots[slot].modes and self.data.slots[slot].modes.survival then
		options = self.data.slots[slot].modes.survival.options
	end

    --Old file stuff
	local files = {}
	for k,v in pairs(self.data.slots[slot].modes) do
		local add_file = true
		if v.files then
			for kk, vv in pairs(v.files) do
				if vv == v.file then
					add_file = false
				end
				table.insert(files, vv)
			end
		end
		
		if add_file then
			table.insert(files, v.file)
		end
	end

	if next(files) then
		EraseFiles(nil, files)
	end

    --DST session file stuff
    if self.data.slots[slot].session_id ~= nil then
        TheNet:DeleteSession(self.data.slots[slot].session_id)
    end

	local slot_exists = self.data.slots[slot] and self.data.slots[slot].current_mode
	if slot_exists then
		self.data.slots[slot] = { current_mode = nil, modes = {}}
		if save_options == true then
			self.data.slots[slot].dlc = dlc
			self.data.slots[slot].server = server
			self.data.slots[slot].current_mode = "survival"
			self.data.slots[slot].modes["survival"] = {options = options}
		end
		self:Save(cb)
    elseif cb ~= nil then
		cb()
	end
end


function SaveIndex:ResetCave(cavenum, cb)
	
	local slot = self.current_slot

	if slot and cavenum and self.data.slots[slot] and self.data.slots[slot].modes.cave then
		
		local del_files = {}
		for k,v in pairs(self.data.slots[slot].modes.cave.files) do
			
			local cave_num = string.match(v, "cave_(%d+)_")
			if cave_num and tonumber(cave_num) == cavenum then
				table.insert(del_files, v)
			end
		end
		
		EraseFiles(cb, del_files)
	else
		if cb then
			cb()
		end
	end

end


function SaveIndex:EraseCaves(cb)
	local function onerased()
		self.data.slots[self.current_slot].modes.cave = {}
		self:Save(cb)
	end

	local files = {}
	
	if self.data.slots[self.current_slot] and self.data.slots[self.current_slot].modes and self.data.slots[self.current_slot].modes.cave then
		if self.data.slots[self.current_slot].modes.cave.file then
			table.insert(files, self.data.slots[self.current_slot].modes.cave.file)
		end
		if self.data.slots[self.current_slot].modes.cave.files then
			for kk, vv in pairs(self.data.slots[self.current_slot].modes.cave.files) do
				table.insert(files, vv)
			end
		end
	end
	EraseFiles(onerased, files)
end



function SaveIndex:EraseCurrent(cb)
	
	local current_mode = self.data.slots[self.current_slot].current_mode

	local function docaves()
		if current_mode == "survival" then
			self:EraseCaves(cb)
		else
			cb()
		end
	end

	local filename = ""
	local function onerased()	
		EraseFiles(docaves, {filename})
	end
	
	local data = self:GetModeData(self.current_slot, current_mode)
	filename = data.file
	data.file = nil
	data.playerdata = nil
	data.day = nil
	data.world = nil
	self:Save(onerased)
end

function SaveIndex:GetDirectionOfTravel()
	return self.data.slots[self.current_slot].direction,
			self.data.slots[self.current_slot].cave_num
end
function SaveIndex:GetCaveNumber()
	return  (self.data.slots[self.current_slot].modes and
			self.data.slots[self.current_slot].modes.cave and
			self.data.slots[self.current_slot].modes.cave.current_cave) or nil
end

--isshutdown means players have been cleaned up by OnDespawn()
--and the sim will shutdown after saving
function SaveIndex:SaveCurrent(onsavedcb, isshutdown, direction, cave_num)
    -- Only servers save games in DST
    if TheNet:GetIsClient() then
        return
    end

    assert(TheWorld ~= nil, "missing world?")
    local level_number = TheWorld.topology.level_number or 1
    local day_number = TheWorld.state.cycles + 1

    local current_mode = self.data.slots[self.current_slot].current_mode
    local data = self:GetModeData(self.current_slot, current_mode)
    --local dlc = self.data.slots[self.current_slot].dlc
    --V2C: commented out dlc lines cuz it doesn't achieve anything

    self.data.slots[self.current_slot].direction = direction
    self.data.slots[self.current_slot].cave_num = cave_num
    --self.data.slots[self.current_slot].dlc = dlc
    self.data.slots[self.current_slot].session_id = TheNet:GetSessionIdentifier()

    data.day = day_number
    data.playerdata = nil
    data.file = nil
    data.files = nil

    SaveGame(self:GetSaveGameName(current_mode, self.current_slot), isshutdown, onsavedcb)
end

function SaveIndex:GetSlotDLC(slot)
	local dlc = self.data.slots[slot or self.current_slot].dlc
	if not dlc then dlc = NO_DLC_TABLE end
	return dlc
end

function SaveIndex:SetCurrentIndex(saveslot)
	self.current_slot = saveslot
end

function SaveIndex:GetCurrentSaveSlot()
	return self.current_slot
end

function SaveIndex:GetCurrentMode(slot)
    local mode
    if slot then
        mode = self.data.slots[slot].current_mode
    else
        mode = self.data.slots[self.current_slot].current_mode
    end
    return mode
end


--called upon relaunch when a new level needs to be loaded
function SaveIndex:OnGenerateNewWorld(saveslot, savedata, session_identifier, cb)
	--local playerdata = nil
	self.current_slot = saveslot
	local filename = self:GetSaveGameName(self.data.slots[self.current_slot].current_mode, self.current_slot)
	
	local function onindexsaved()
		cb()
		--cb(playerdata)
	end		

	local function onsavedatasaved()
		self.data.slots[self.current_slot].continue_pending = false
		self.data.slots[self.current_slot].session_id = session_identifier
		local current_mode = self.data.slots[self.current_slot].current_mode
		local data = self:GetModeData(self.current_slot, current_mode)
		data.day = 1
        data.file = nil
        data.files = nil

		--playerdata = data.playerdata
		--data.playerdata = nil

		self:Save(onindexsaved)
	end

    SerializeWorldSession(savedata, session_identifier, onsavedatasaved)
end


function SaveIndex:GetOrCreateSlot(saveslot)
	if self.data.slots[saveslot] == nil then
		self.data.slots[saveslot] = {}
	end
	return self.data.slots[saveslot]
end


function SaveIndex:UpdateServerData(saveslot, onsavedcb, serverdata)
	self.current_slot = saveslot
--	local data = self:GetModeData(saveslot, "survival")
	local slot = self:GetOrCreateSlot(saveslot)
	local pvpSetting = TheNet:GetDefaultPvpSetting()
	if serverdata and serverdata.pvp ~= nil then
		pvpSetting = serverdata.pvp
	end

	print("SaveIndex:UpdateServerData!:", serverdata.name)

	if slot then
		slot.server.game_mode = serverdata and serverdata.game_mode or slot.server.game_mode
		slot.server.name = serverdata and serverdata.name or slot.server.name
		slot.server.password = serverdata and serverdata.password or slot.server.password
		slot.server.description = serverdata and serverdata.description or slot.server.description
		slot.server.maxplayers = serverdata and serverdata.maxplayers or slot.server.maxplayers
		slot.server.friends_only = serverdata and serverdata.friends_only or slot.server.friends_only
		slot.server.online_mode = serverdata and serverdata.online_mode or slot.server.online_mode
		slot.server.pvp = pvpSetting ~= nil and pvpSetting or slot.server.pvp
	end

	self.data.last_used_slot = saveslot
 	
 	self:Save(onsavedcb)

    -- local starts = Profile:GetValue("starts") or 0
    -- Profile:SetValue("starts", starts+1)
    -- Profile:Save()
end


--call after you have worldgen data to initialize a new survival save slot
function SaveIndex:StartSurvivalMode(saveslot, character, customoptions, onsavedcb, dlc, serverdata)
	self.current_slot = saveslot
--	local data = self:GetModeData(saveslot, "survival")
	local slot = self:GetOrCreateSlot(saveslot)
	slot.current_mode = "survival"
	slot.save_id = self:GenerateSaveID(self.current_slot)
	slot.session_id = TheNet:GetSessionIdentifier()
	slot.dlc = dlc and dlc or NO_DLC_TABLE
	local pvpSetting = TheNet:GetDefaultPvpSetting()
	if serverdata and serverdata.pvp ~= nil then
		pvpSetting = serverdata.pvp
	end
	local onlineSetting = TheNet:IsOnlineMode()
	if serverdata and serverdata.online_mode ~= nil then
		onlineSetting = serverdata.online_mode
	end

	print("SaveIndex:StartSurvivalMode!:", slot.dlc.REIGN_OF_GIANTS)

	slot.modes = 
	{
		survival = {
			--file = self:GetSaveGameName("survival", self.current_slot),
			day = 1,
			world = 1,
			options = customoptions,
		},
	}

	slot.server = 
	{
	    game_mode = serverdata and serverdata.game_mode or TheNet:GetDefaultGameMode(),
	    name = serverdata and serverdata.name or TheNet:GetDefaultServerName(),
        password = serverdata and serverdata.password or "",
        description = serverdata and serverdata.description or TheNet:GetDefaultServerDescription(),
        maxplayers = serverdata and serverdata.maxplayers or TheNet:GetDefaultMaxPlayers(),
        friends_only = serverdata and serverdata.friends_only or TheNet:GetFriendsOnlyServer(),
        online_mode = onlineSetting,
        pvp = pvpSetting,
	}
	
	self.data.last_used_slot = saveslot
 	
 	self:Save(onsavedcb)

    local starts = Profile:GetValue("starts") or 0
    Profile:SetValue("starts", starts+1)
    Profile:Save()

end

function SaveIndex:GetLastUsedSlot()
	print(self.data.last_used_slot)
	return self.data.last_used_slot or -1
end

function SaveIndex:GenerateSaveID(slot)
	local now = os.time()
	return TheSim:GetSteamUserID() .."-".. tostring(now) .."-".. tostring(slot)
end

function SaveIndex:GetSaveID(slot)
	slot = slot or self.current_slot
	return self.data.slots[slot].save_id
end

function SaveIndex:OnFailCave(onsavedcb)
	self.data.slots[self.current_slot].modes.cave.playerdata = nil
	self.data.slots[self.current_slot].current_mode = "survival"
	local playerdata = {}
    local player = ThePlayer
    if player then
    	--remember our unlocked recipes
        playerdata.builder = player:GetSaveRecord().data.builder
        
        --set our meters to the standard resurrection amounts
        playerdata.health = {health = TUNING.RESURRECT_HEALTH}
		playerdata.hunger = {hunger = player.components.hunger.max*.66}
		playerdata.sanity = {current = player.components.sanity.max*.5}
        playerdata.leader = nil
        playerdata.sanitymonsterspawner = nil
		
   	end 

	if self.data.slots[self.current_slot].modes.survival then
		self.data.slots[self.current_slot].modes.survival.playerdata = playerdata
	end
	self:Save(onsavedcb)
end

function SaveIndex:LeaveCave(onsavedcb)
	local playerdata = {}
    local player = ThePlayer
    if player then
        playerdata = player:GetSaveRecord().data
        playerdata.leader = nil
        playerdata.sanitymonsterspawner = nil
        
   	end 
	self.data.slots[self.current_slot].modes.cave.playerdata = nil
	self.data.slots[self.current_slot].current_mode = "survival"
	
	if self.data.slots[self.current_slot].modes.survival then
		self.data.slots[self.current_slot].modes.survival.playerdata = playerdata
	end
	self:Save(onsavedcb)
end


function SaveIndex:EnterCave(onsavedcb, saveslot, cavenum, level)
	self.current_slot = saveslot or self.current_slot

	--get the current player, and maintain his player data
 	local playerdata = {}
    local player = ThePlayer
    if player then
        playerdata = player:GetSaveRecord().data
        playerdata.leader = nil
        playerdata.sanitymonsterspawner = nil
   	end  

	level = level or 1
	cavenum = cavenum or 1

	self.data.slots[self.current_slot].current_mode = "cave"
	
	if not self.data.slots[self.current_slot].modes.cave then
		self.data.slots[self.current_slot].modes.cave = {}
	end

	self.data.slots[self.current_slot].modes.cave.files = self.data.slots[self.current_slot].modes.cave.files or {}
	self.data.slots[self.current_slot].modes.cave.current_level = self.data.slots[self.current_slot].modes.cave.current_level or {}
	self.data.slots[self.current_slot].modes.cave.world = level or 1

	self.data.slots[self.current_slot].modes.cave.current_level[cavenum] = level
	self.data.slots[self.current_slot].modes.cave.current_cave = cavenum
	
	local savename = self:GetSaveGameName("cave", self.current_slot)
	self.data.slots[self.current_slot].modes.cave.playerdata = playerdata
	self.data.slots[self.current_slot].modes.cave.file = nil
	
	
	TheSim:CheckPersistentStringExists(savename, function(exists) 
		if exists then
			self.data.slots[self.current_slot].modes.cave.file = savename
		end
		self:Save(onsavedcb)
	 end)

end

function SaveIndex:OnFailAdventure(cb)
	local filename = self.data.slots[self.current_slot].modes.adventure.file

	local function onsavedindex()
		EraseFiles(cb, {filename})
	end
	self.data.slots[self.current_slot].current_mode = "survival"
	self.data.slots[self.current_slot].modes.adventure = {}
	self:Save(onsavedindex)
end

function SaveIndex:FakeAdventure(cb, slot, start_world)
	self.data.slots[slot].current_mode = "adventure"
	self.data.slots[slot].modes.adventure = {world = start_world, playlist = {1,2,3,4,5,6}}
 	self:Save(cb)
end

function SaveIndex:StartAdventure(cb)

	local function ongamesaved()
		local playlist = self.BuildAdventurePlaylist()
		self.data.slots[self.current_slot].current_mode = "adventure"
		self.data.slots[self.current_slot].modes.adventure = {world = 1, playlist = playlist}
	 	self:Save(cb)
	end

	self:SaveCurrent(ongamesaved)

end

function SaveIndex:BuildAdventurePlaylist()
	local levels = require("map/levels")

	local playlist = {}

	local remaining_keys = shuffledKeys(levels.story_levels)
	for i=1,levels.CAMPAIGN_LENGTH+1 do -- the end level is at position length+1
		for k_idx,k in ipairs(remaining_keys) do
			local level_candidate = levels.story_levels[k]
			if level_candidate.min_playlist_position <= i and level_candidate.max_playlist_position >= i then
				table.insert(playlist, k)
				table.remove(remaining_keys, k_idx)
				break
			end
		end
	end

	assert(#playlist == levels.CAMPAIGN_LENGTH+1)

	--debug
	print("Chosen levels:")
	for _,k in ipairs(playlist) do
		print("",levels.story_levels[k].name)
	end

	return playlist
end

--call when you have finished a survival or adventure level to increment the world number and save off the continue information
function SaveIndex:CompleteLevel(cb)
	local adventuremode = self.data.slots[self.current_slot].current_mode == "adventure"

    local playerdata = {}
    local player = ThePlayer
    if player then
    	player:OnProgress()

		-- bottom out the player's stats so they don't start the next level and die
		local minhealth = 0.2
		if player.components.health:GetPercent() < minhealth then
			player.components.health:SetPercent(minhealth)
		end
		local minsanity = 0.3
		if  player.components.sanity:GetPercent() < minsanity then
			player.components.sanity:SetPercent(minsanity)
		end
		local minhunger = 0.4
		if  player.components.hunger:GetPercent() < minhunger then
			player.components.hunger:SetPercent(minhunger)
		end


        playerdata = player:GetSaveRecord().data
   	 end   

   	local function onerased()
   		if adventuremode then
   			self:Save(cb)
   		else
   			self:EraseCaves(cb)
   		end
   		--self:Save(cb)
   	end

	self.data.slots[self.current_slot].continue_pending = true

	local current_mode = self.data.slots[self.current_slot].current_mode
	local data = self:GetModeData(self.current_slot, current_mode)

	data.day = 1
	data.world = data.world and (data.world + 1) or 2
 	data.playerdata = playerdata
	local file = data.file 
	data.file = nil
	EraseFiles( onerased, { file } )		
end

function SaveIndex:GetSlotDay(slot)
	slot = slot or self.current_slot
	local current_mode = self.data.slots[slot].current_mode
	local data = self:GetModeData(slot, current_mode)
	return data.day or 1
end

function SaveIndex:SetSlotDay(slot, day)
	slot = slot or self.current_slot
	local current_mode = self.data.slots[slot].current_mode
	local data = self:GetModeData(slot, current_mode)
	data.day = day
end

function SaveIndex:GetSlotMode(slot)
	slot = slot or self.current_slot
	return self.data.slots[slot].current_mode
end

-- The WORLD is the "depth" the player has traversed through the teleporters. 1, 2, 3, 4...
-- Contrast with the LEVEL, below.
function SaveIndex:GetSlotWorld(slot)
	slot = slot or self.current_slot
	local current_mode = self.data.slots[slot].current_mode
	local data = self:GetModeData(slot, current_mode)
	return data.world or 1
end

-- The LEVEL is the index from levels.lua to load. This gets shuffled via the playlist.
function SaveIndex:GetSlotLevelIndexFromPlaylist(slot)
	slot = slot or self.current_slot
	local current_mode = self.data.slots[slot].current_mode
	local data = self:GetModeData(slot, current_mode)
	local world = data.world or 1
	if data.playlist and world <= #data.playlist then
		local level = data.playlist[world]
		return level
	else
		return world
	end
end

function SaveIndex:HasWorld(slot, mode)
	slot = slot or self.current_slot
	local current_mode = mode or self.data.slots[slot].current_mode
	local data = self:GetModeData(slot, current_mode)
	return data ~= nil
        and self.data.slots[slot].session_id ~= nil
        and (data.file ~= nil or --backward compatibility
            TheNet:GetWorldSessionFile(self.data.slots[slot].session_id) ~= nil)
end

function SaveIndex:GetSlotGenOptions(slot, mode)
	slot = slot or self.current_slot
	local current_mode = self.data.slots[slot].current_mode
	local data = self:GetModeData(slot, current_mode)
	return data.options
end

function SaveIndex:GetSlotSession(slot)
    return self.data.slots[slot or self.current_slot].session_id
end

--V2C: This is no longer cheap because it's not cached, but supports
--     dynamically switching user accounts locally, mmm'kay
function SaveIndex:LoadSlotCharacter(slot)
    slot = slot or self.current_slot
    local character = nil
    local theslot = self.data.slots[slot]
    if theslot ~= nil and theslot.server ~= nil then
        local session_id = theslot.session_id
        local online_mode = theslot.server.online_mode
        if session_id ~= nil and online_mode ~= nil then
            local file = TheNet:GetUserSessionFile(session_id, nil, online_mode)
            if file ~= nil then
                TheSim:GetPersistentString(file,
                    function(success, str)
                        if success and str ~= nil and #str > 0 then
                            local success, savedata = RunInSandbox(str)
                            if success and savedata ~= nil and GetTableSize(savedata) > 0 then
                                character = savedata.prefab
                            end
                        end
                    end)
            end
        end
    end
    return character ~= nil and (table.contains(GetActiveCharacterList(), character) or table.contains(MODCHARACTERLIST, character)) and character or nil
end

function SaveIndex:IsContinuePending(slot)
	return self.data.slots[slot or self.current_slot].continue_pending
end

function SaveIndex:GetCurrentMode(slot)
	return self.data.slots[slot or self.current_slot].current_mode
end

function SaveIndex:GetGameMode(slot)
	local theslot = self.data.slots[slot or self.current_slot]
	return theslot ~= nil and theslot.server ~= nil and theslot.server.game_mode or nil
end

function SaveIndex:GetSlotOnlineMode(slot)
    local theslot = self.data.slots[slot or self.current_slot]
    if theslot == nil or theslot.server == nil then
        --so we can distinguish btwn nil and false returns
        return
    end
    return theslot.server.online_mode
end

function SaveIndex:GetCurrentCaveLevel(slot, cavenum)
	slot = slot or self.current_slot
	cavenum = cavenum or self:GetModeData(slot, "cave").current_cave or cavenum or 1
	local cave_data = self:GetModeData(slot, "cave")
	if cave_data.current_level and cave_data.current_level[cavenum] then
		return cave_data.current_level[cavenum]
	end
	return 1
end

function SaveIndex:GetCurrentCaveNum(slot)
	slot = slot or self.current_slot
	return self:GetModeData(slot, "cave").current_cave or 1
end

function SaveIndex:GetNumCaves(slot)
	slot = slot or self.current_slot
	return self:GetModeData(slot, "cave").num_caves or 0
end


function SaveIndex:AddCave(slot, cb)
	slot = slot or self.current_slot
	
	self:GetModeData(slot, "cave").num_caves = self:GetModeData(slot, "cave").num_caves and self:GetModeData(slot, "cave").num_caves + 1 or 1
	self:Save(cb)
end

function SaveIndex:FixupServerData()
    -- V2C: THIS IS WRONG if it runs on clients
    --      however it looks like it's for deprecated stuff so....
    --      I don't know =) ask charles.
    for idx, slot in ipairs(self.data.slots) do
        if nil == slot.server then
            if slot and slot.modes and slot.modes[slot.current_mode] then
                local mode_data = slot.modes[slot.current_mode]
                
                -- copy deprecated data to correct place
                slot.server = 
                {
                    game_mode = mode_data.game_mode or TheNet:GetDefaultGameMode(),
                    friends_only = mode_data.friends_only or false,
                    online_mode = mode_data.online_mode or true,
                    maxplayers = mode_data.maxplayers or TheNet:GetDefaultMaxPlayers(),
                    pvp = mode_data.pvp or TheNet:GetDefaultPvpSetting(),
                    name = mode_data.servername or TheNet:GetDefaultServerName(),
                    description = mode_data.serverdescription or TheNet:GetDefaultServerDescription(),
                    password = mode_data.serverpassword or TheNet:GetDefaultServerPassword(),
                }
                
                -- clear deprecated data
                mode_data.game_mode = nil
                mode_data.friends_only = nil
                mode_data.maxplayers = nil
                mode_data.online_mode = nil
                mode_data.pvp = nil
                mode_data.serverdescription = nil
                mode_data.servername = nil
                mode_data.serverpassword = nil
            else
                slot.server = {}
            end
        end
    end
end