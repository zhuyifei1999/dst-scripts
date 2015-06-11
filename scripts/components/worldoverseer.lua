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
	if not playerstats then
		self._seenplayers[player] = {
									starttime = time,
									secondsplayed = 0,
									endtime = nil
								}
	else
		-- player was here before this timeframe
		playerstats.secondsplayed = playerstats.endtime - playerstats.starttime
		playerstats.starttime = time
		playerstats.endtime = nil
	end
end

function WorldOverseer:RecordPlayerLeft(player)
	local playerstats = self._seenplayers[player]
	local time = GetTime()
	if playerstats then
		playerstats.endtime = time
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
	for player,playerstats in pairs(self._seenplayers) do
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
		result[#result+1] = {player = player, secondsplayed = secondsplayed}
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
	
		dprint("_________________________________________________________________Sending playtime heartbeat stats...")
		ddump(sendstats)
		dprint("_________________________________________________________________<END>")
		local jsonstats = json.encode( sendstats )
		TheSim:SendProfileStats( jsonstats )
	end
end

function WorldOverseer:OnPlayerDeath(player, data)
	local age = player.components.age:GetAgeInDays()
	local worldAge = self._cycles
	local sendstats = self:BuildContextTable(player)
	sendstats.playerdeath = {
								playerage = RoundBiasedUp(age,2),
								worldage = worldAge,
								cause = data and data.cause or ""
							}
	dprint("_________________________________________________________________Sending playerdeath stats...")
	ddump(sendstats)
	dprint("_________________________________________________________________<END>")
	local jsonstats = json.encode( sendstats )
	TheSim:SendProfileStats( jsonstats )
end

function WorldOverseer:GetSessionStats()
end

function WorldOverseer:DumpSessionStats()
	local hosting = TheNet:GetUserID()
	local sendstats = self:BuildContextTable(hosting)
	-- we don't have to send the host, as the sending user will be the host
	sendstats.mpsession = {
							worldage = self._cycles,
							players = {},
							characters = {},
							private = TheNet:GetServerHasPassword(),
							gamemode = TheNet:GetServerGameMode(),
						}
	for i,v in pairs(self._seenplayers) do
		table.insert(sendstats.mpsession.players, i.userid.."@chester")
		table.insert(sendstats.mpsession.characters, i.prefab or "None")
	end
	dprint("_________________________________________________________________Sending session heartbeat stats...")
	ddump(sendstats)
	dprint("_________________________________________________________________<END>")
	local jsonstats = json.encode( sendstats )
	TheSim:SendProfileStats( jsonstats )
end

function WorldOverseer:OnPlayerJoined(src,player)
	self:RecordPlayerJoined(player)
	self.inst:ListenForEvent("death", function(inst, data) self:OnPlayerDeath(inst, data) end, player)
end

function WorldOverseer:OnPlayerLeft(src,player)
	self:RecordPlayerLeft(player)
end

function WorldOverseer:Heartbeat(dt)
	self:DumpPlayerStats()
	self:DumpSessionStats()
end

return WorldOverseer

