local WORLDOVERSEER_HEARTBEAT = 5 * 60

local WorldOverseer = Class(function(self, inst)
	self.inst = inst
    self.data = {}
	self._seenplayers = {}
	self._cycles = 0

	self.inst:DoPeriodicTask(WORLDOVERSEER_HEARTBEAT, function() self:Heartbeat() end )
	self.inst:ListenForEvent("ms_playerjoined", function(src, player) self:OnPlayerJoined(src, player) end , TheWorld)
	self.inst:ListenForEvent("ms_playerleft", function(src, player) self:OnPlayerLeft(src, player) end, TheWorld)
    self.inst:ListenForEvent("cycleschanged", function(inst, data) self:OnCyclesChanged(data) end, TheWorld)

	for i, v in ipairs(AllPlayers) do
		self:OnPlayerJoined(self.inst, v)
	end
end)


function WorldOverseer:OnCyclesChanged(cycles)
    self._cycles = cycles
end

function WorldOverseer:RecordPlayerJoined(player)
	local playerstats = self._seenplayers[player]
	local time = GetTime()

	local current_skins = player.components.skinner:GetClothing()
	local items = {}
	for k,v in pairs(current_skins) do
		local item = {}
		item.item_name = v
		item.starttime = time
		item.endtime = nil
		table.insert(items, item)
	end

	if not playerstats then
		self._seenplayers[player] = {
									starttime = time,
									secondsplayed = 0,
									endtime = nil,
									worn_items = items,
									crafted_items = {},
								}
	else
		-- player was here before this timeframe
		playerstats.secondsplayed = playerstats.endtime - playerstats.starttime
		playerstats.starttime = time
		playerstats.endtime = nil
		playerstats.worn_items = items

	end
end

function WorldOverseer:RecordPlayerLeft(player)
	local playerstats = self._seenplayers[player]
	local time = GetTime()
	if playerstats then
		playerstats.endtime = time

		for k,v in pairs(playerstats.worn_items) do
			if v.endtime == nil then
				v.endtime = time
			end
		end

	end
end

function WorldOverseer:BuildContextTable(player)
    local sendstats = {}
    -- can be called with a player or a userid
    if type(player) == "table" then
        sendstats.user = player.userid
    else
        sendstats.user = player
    end

    sendstats.user =
        (sendstats.user ~= nil and (sendstats.user.."@chester")) or
        (BRANCH == "dev" and "testing") or
        "unknown"

    return sendstats
end

function WorldOverseer:CalcPlayerStats()
	-- Gather player playtimes for this segment
	local result = {}

	local time = GetTime()
	local secondsplayed = 0
	local toRemove = {}
	for player, playerstats in pairs(self._seenplayers) do
		if playerstats.endtime then
			-- player left
			secondsplayed = playerstats.endtime - playerstats.starttime + playerstats.secondsplayed
			table.insert(toRemove, player)
		else
			-- still there
			secondsplayed = time - playerstats.starttime + playerstats.secondsplayed
			playerstats.starttime = time
			playerstats.secondsplayed = 0
		end

		-- Calculates the time for each individual skin, check if it's already contained on the list
		-- if not, insert it, if so, append the time
		local total_worn_items = {}
		local totaltime = 0
		for index, worn_item in pairs(playerstats.worn_items) do
			if worn_item.endtime then
				totaltime = worn_item.endtime - worn_item.starttime
			else
				totaltime = time - worn_item.starttime
			end

			if not table.containskey(total_worn_items, worn_item.item_name) then
				total_worn_items[worn_item.item_name] = totaltime
			else
				total_worn_items[worn_item.item_name] = total_worn_items[worn_item.item_name] + totaltime
			end
		end

		local total_crafted_items = {}
		for index,crafted_item in pairs(playerstats.crafted_items) do
			if not table.containskey(total_crafted_items, crafted_item) then
				total_crafted_items[crafted_item] = 1
			else
				total_crafted_items[crafted_item] = total_crafted_items[crafted_item] + 1
			end
			playerstats.crafted_items[index] = nil
		end

		result[#result+1] = 
		{
			player = player, 
			secondsplayed = secondsplayed, 
			worn_items = total_worn_items, 
			crafted_items = total_crafted_items
		}
	end
	-- cleanup
	for i,v in ipairs(toRemove) do
		self._seenplayers[v] = nil
	end
	return result
end


function WorldOverseer:DumpPlayerStats()
	local playerstats = self:CalcPlayerStats() 
	for i,stat in ipairs(playerstats) do
		local sendstats = self:BuildContextTable(stat.player)
		sendstats.play_t = RoundBiasedUp(stat.secondsplayed,2)
        sendstats.character = stat.player and stat.player.prefab or nil
        sendstats.save_id = self.inst.meta.session_identifier
        sendstats.worn_items = stat.worn_items
        sendstats.crafted_items = stat.crafted_items
	
		--print("_________________________________________________________________Sending playtime heartbeat stats...")
		--ddump(sendstats)
		--print("_________________________________________________________________<END>")
		local jsonstats = json.encode(sendstats)
		TheSim:SendProfileStats(jsonstats)
	end
end

function WorldOverseer:OnPlayerDeath(player, data)
	local age = player.components.age:GetAgeInDays()
	local worldAge = self._cycles
	local sendstats = self:BuildContextTable(player)
	sendstats.playerdeath = {
                                save_id = self.inst.meta.session_identifier,
								playerage = RoundBiasedUp(age,2),
								worldage = worldAge,
								cause = data and data.cause or ""
							}
	--print("_________________________________________________________________Sending playerdeath stats...")
	--ddump(sendstats)
	--print("_________________________________________________________________<END>")
	local jsonstats = json.encode(sendstats)
	TheSim:SendProfileStats(jsonstats)
end

function WorldOverseer:OnPlayerChangedSkin(player, data)
	if not data then return end
	if not data.new_skin then return end
	if data.new_skin == data.old_skin then return end

	local playerstats = self._seenplayers[player]
	local time = GetTime()

	for k,v in pairs(playerstats.worn_items) do
		if v.item_name == data.old_skin and v.endtime == nil then
			v.endtime = time
			break
		end
	end

	local item = {}
	item.item_name = data.new_skin
	item.starttime = time
	item.endtime = nil
	table.insert(playerstats.worn_items, item)
end

function WorldOverseer:OnItemCrafted(player, data)
	if not data then return end
	if not data.skin then return end

	local playerstats = self._seenplayers[player]
	table.insert (playerstats.crafted_items, data.skin)
end

function WorldOverseer:OnEquipSkinnedItem(player, data)
	if not data then return end

	local playerstats = self._seenplayers[player]
	local time = GetTime()

	local item ={}
	item.item_name = data
	item.starttime = time
	item.endtime = nil

	table.insert(playerstats.worn_items, item)
end

function WorldOverseer:OnUnequipSkinnedItem(player, data)
	if not data then return end

	local playerstats = self._seenplayers[player]
	local time = GetTime()

	for k,v in pairs(playerstats.worn_items) do
		if v.item_name == data and v.endtime == nil then
			v.endtime = time
			break
		end
	end
end

function WorldOverseer:GetSessionStats()
end

function WorldOverseer:DumpSessionStats()
	local hosting = TheNet:GetUserID()
	local sendstats = self:BuildContextTable(hosting)
	-- we don't have to send the host, as the sending user will be the host

    local clients = TheNet:GetClientTable() or {}

    sendstats.mpsession = {
                            save_id = self.inst.meta.session_identifier,
                            worldage = self._cycles,
                            num_players = #clients,
                            max_players = TheNet:GetServerMaxPlayers(),
                            password = TheNet:GetServerHasPassword(),
                            gamemode = TheNet:GetServerGameMode(),
                            dedicated = not TheNet:GetServerIsClientHosted(),
                            administrated = TheNet:GetServerHasPresentAdmin(),
                            modded = TheNet:GetServerModsEnabled(),
                            privacy = (TheNet:GetServerClanID() ~= "" and "CLAN")
                                    or (TheNet:GetServerLANOnly() and "LAN")
                                    or (TheNet:GetServerFriendsOnly() and "FRIENDS")
                                    or "PUBLIC",
                            offline = not TheNet:IsOnlineMode(),
                            pvp = TheNet:GetServerPVP(),
                        }
    local clanid = TheNet:GetServerClanID()
    if clanid ~= "" then
        sendstats.mpsession.clan_id = clanid
        sendstats.mpsession.clan_only = TheNet:GetServerClanOnly()
        --sendstats.clan_admins = TheNet:GetServerClanAdmins() -- not available in the handshake!
    end
	--print("_________________________________________________________________Sending session heartbeat stats...")
	--ddump(sendstats)
	--print("_________________________________________________________________<END>")
	local jsonstats = json.encode(sendstats)
	TheSim:SendProfileStats(jsonstats)
end

function WorldOverseer:OnPlayerJoined(src,player)

	self:RecordPlayerJoined(player)
	self.inst:ListenForEvent("death", function(inst, data) self:OnPlayerDeath(inst, data) end, player)
	self.inst:ListenForEvent("changeclothes", function (inst, data) self:OnPlayerChangedSkin(inst, data) end, player)
	self.inst:ListenForEvent("buildstructure", function (inst, data) self:OnItemCrafted(inst, data) end, player)
	self.inst:ListenForEvent("builditem", function (inst, data) self:OnItemCrafted(inst, data) end, player)
	self.inst:ListenForEvent("equipskinneditem", function(inst, data) self:OnEquipSkinnedItem(inst, data) end, player)
	self.inst:ListenForEvent("unequipskinneditem", function(inst, data) self:OnUnequipSkinnedItem(inst, data) end, player)

	-- The initial clothing is set before the Overseer starts listening to the events
	-- so we have to manually grab the items for the analytics
	if player.components.skinner then
		local initial_clothing = player.components.skinner:GetClothing()
		for k,v in pairs(initial_clothing) do
			if v and v ~= "" then
				self:OnEquipSkinnedItem(player, v)
			end
		end
	end

end

function WorldOverseer:OnPlayerLeft(src,player)
	self:RecordPlayerLeft(player)
end

function WorldOverseer:Heartbeat(dt)
	self:DumpPlayerStats()
	self:DumpSessionStats()
end

return WorldOverseer