-- require "stats_schema"    -- for when we actually organize 

STATS_ENABLE = false
-- NOTE: There is also a call to 'anon/start' in dontstarve/main.cpp which has to be un/commented

--- non-user-facing Tracking stats  ---
TrackingEventsStats = {}
TrackingTimingStats = {}
local GameStats = {}
GameStats.StatsLastTrodCount = 0
local OnLoadGameInfo = {}

function IncTrackingStat(stat, subtable)

	if not STATS_ENABLE then
		return
	end

    local t = TrackingEventsStats
    if subtable then
        t = TrackingEventsStats[subtable]

        if not t then
            t = {}
            TrackingEventsStats[subtable] = t
        end
    end

    t[stat] = 1 + (t[stat] or 0)
end

function SetTimingStat(subtable, stat, value)

	if not STATS_ENABLE then
		return
	end

    local t = TrackingTimingStats
    if subtable then
        t = TrackingTimingStats[subtable]

        if not t then
            t = {}
            TrackingTimingStats[subtable] = t
        end
    end

    t[stat] = math.floor(value/1000)
end


function SendTrackingStats()

	if not STATS_ENABLE then
		return
	end

	if GetTableSize(TrackingEventsStats) then
    	local stats = json.encode({events=TrackingEventsStats, timings=TrackingTimingStats})
    	TheSim:LogBulkMetric(stats)
    end
end


function BuildContextTable()
    local sendstats = {}

    sendstats.user = TheNet:GetUserID()
    sendstats.user =
        (sendstats.user ~= nil and (sendstats.user.."@chester")) or
        (BRANCH == "dev" and "testing") or
        "unknown"

	local steamID = TheSim:GetSteamUserID()
	if steamID ~= "" and steamID ~= "unknownID" then
		sendstats.steamid = steamID
	end

	sendstats.branch = BRANCH

	local modnames = KnownModIndex:GetModNames()
	for i, name in ipairs(modnames) do
		if KnownModIndex:IsModEnabled(name) then
			sendstats.branch = sendstats.branch .. "_modded"
			break
		end
	end

	sendstats.build = APP_VERSION
	sendstats.platform = PLATFORM

    if TheWorld and TheWorld.meta then
        sendstats.session = TheWorld.meta.session_identifier
    end

	return sendstats
end


--- GAME Stats and details to be sent to server on game complete ---
ProfileStats = {}
MainMenuStats = {}

function SuUsed(item,value)
    GameStats.super = true
    ProfileStatsSet(item, value)
end

function SetSuper(value)
    dprint("Setting SUPER",value)
    OnLoadGameInfo.super = value
end

function SuUsedAdd(item,value)
    GameStats.super = true
    ProfileStatsAdd(item, value)
end

function WasSuUsed()
    return GameStats.super
end

function GetProfileStats(wipe)
	if GetTableSize(ProfileStats) == 0 then
		return json.encode( {} )
	end

	wipe = wipe or false
	local jsonstats = ''
	local sendstats = BuildContextTable()

	sendstats.stats = ProfileStats
	dprint("_________________++++++ Sending Accumulated profile stats...\n")
	ddump(sendstats)

	jsonstats = json.encode( sendstats )

	if wipe then
		ProfileStats = {}
    end
    return jsonstats
end


function RecordEndOfDayStats()
	if not STATS_ENABLE then
		return
	end

    -- Do local analysis of game session so far
    dprint("RecordEndOfDayStats")
end

function RecordQuitStats()
	if not STATS_ENABLE then
		return
	end

    -- Do local analysis of game session
    dprint("RecordQuitStats")
end

function RecordPauseStats()         -- Run some analysis and save stats when player pauses
	if not STATS_ENABLE or not IsPaused() then
		return
	end
    dprint("RecordPauseStats")
end

function RecordOverseerStats(data)

	if not STATS_ENABLE or GetTableSize(data.foeList) <= 0 then
        dprint("^^^^^^^^^^^^^^^^^^^^ NO FOES!")
		return
	end

    dprint("FoeList-----------------------")
    ddump(data.foeList)

    if GetTableSize(data.eluded) == 0 then
        data.eluded = nil
    end


	local sendstats = BuildContextTable()
	sendstats.fight = {
        duration       = data.duration,
        dmg_taken      = data.damage_taken,
        dmg_given      = data.damage_given,
        wield          = data.wield,
        wear           = data.wear,
        head           = data.head,
        sanity         = data.sanity_start,
        hunger         = data.hunger_start,
        health_lvl     = data.health_start,
        health_start   = data.health_abs,
        health_end     = data.health_end_abs,
        health_end_lvl = data.health_end,
        died           = data.died,
        trod           = data.trod,
        attacked_by    = data.attacked_by,
        targeted_by    = data.targeted_by,
        foes_total     = data.foes_total,
        eluded_total   = data.eluded_total,
        eluded         = data.eluded,
        kill_total     = data.kill_total,
        armor_broken   = data.armor_broken,
        caught_total   = data.caught_total,
        kills          = data.kills,
        absorbed       = data.armor_absorbed,
        AFK            = data.AFK,
        used           = data.used,
        minions        = data.minions,
        minion_kill    = data.minion_kills,
        minions_lost   = data.minions_lost,
        minion_dmg     = data.minion_hits,
        trap_sprung    = data.traps_sprung,
        trap_dmg       = data.trap_damage,
        trap_kill      = data.trap_kills,
        heal           = data.heal,
        --fight          = data.fight,
	}
    
    FightStat_EndFight()

	dprint("_________________________________________________________________Sending fight stats...")
	ddump(sendstats.fight)
	dprint("_________________________________________________________________<END>")
	local jsonstats = json.encode( sendstats )
	--TODO: STATS TheSim:SendProfileStats( jsonstats )
end

function RecordDeathStats(killed_by, time_of_day, sanity, hunger, will_resurrect)
	if not STATS_ENABLE then
		return
	end

	local sendstats = BuildContextTable()
    local map = TheWorld ~= nil and TheWorld.Map or nil
	sendstats.death = {
		killed_by=killed_by,
		time_of_day=time_of_day,
		sanity=math.floor(sanity*100),
		hunger=math.floor(hunger*100),
		will_resurrect=will_resurrect,
        AFK = IsAwayFromKeyBoard(),
        trod = map ~= nil and map:GetNumVisitedTiles() or nil,
        tiles = map ~= nil and map:GetNumWalkableTiles() or nil,
        last_armor = ProfileStatsGet("armor"),
        armor_absorbed = ProfileStatsGet("armor_absorb"),
	}

	dprint("_________________________________________________________________Sending death stats...")
	ddump(sendstats)
	local jsonstats = json.encode( sendstats )
	--TODO:STATS TheSim:SendProfileStats( jsonstats )
end

function RecordSessionStartStats()
	if not STATS_ENABLE then
		return
	end

	-- TODO: This should actually just write the specific start stats, and it will eventually
	-- be rolled into the "quit" stats and sent off all at once.
	local sendstats = BuildContextTable()

	--[[if IsDLCInstalled(REIGN_OF_GIANTS) and not IsDLCEnabled(REIGN_OF_GIANTS) then
		sendstats.Session.Loads.Mods.mod = true
		table.insert(sendstats.Session.Loads.Mods.list, "RoG-NotPlaying")
	end
	if IsDLCEnabled(REIGN_OF_GIANTS) then
		sendstats.Session.Loads.Mods.mod = true
		table.insert(sendstats.Session.Loads.Mods.list, "RoG-Playing")
	end]]

    --local map = TheWorld ~= nil and TheWorld.Map or nil
    --sendstats.Session.map_trod = map ~= nil and map:GetNumVisitedTiles() or 0

--KAJ: TODO: stats, commented out for now
--    if ThePlayer ~= nil then
--        sendstats.Session.character = ThePlayer.prefab
--    end

    --GameStats = {}
    --GameStats.StatsLastTrodCount = map ~= nil and map:GetNumVisitedTiles() or 0
    --GameStats.super = OnLoadGameInfo.super
    --OnLoadGameInfo.super = nil
	
	dprint("_________________++++++ Sending sessions start stats...\n")
	ddump(sendstats)
	local jsonstats = json.encode( sendstats )
	TheSim:SendProfileStats( jsonstats )

end

-- value is optional, 1 if nil
function ProfileStatsAdd(item, value)
    --print ("ProfileStatsAdd", item)
    if value == nil then
        value = 1
    end

    if ProfileStats[item] then
    	ProfileStats[item] = ProfileStats[item] + value
    else
    	ProfileStats[item] = value
    end
end

function ProfileStatsAddItemChunk(item, chunk)
    if ProfileStats[item] == nil then
    	ProfileStats[item] = {}
    end

    if ProfileStats[item][chunk] then
    	ProfileStats[item][chunk] =ProfileStats[item][chunk] +1
    else
    	ProfileStats[item][chunk] = 1
    end
end

function ProfileStatsSet(item, value)
	ProfileStats[item] = value
end

function ProfileStatsGet(item)
	return ProfileStats[item]
end

-- The following takes advantage of table.setfield (util.lua) which
-- takes a string representation of a table field (e.g. "foo.bar.bleah.eeek")
-- and creates all the intermediary tables if they do not exist

function ProfileStatsAddToField(field, value)
    --print ("ProfileStatsAdd", item)
    if value == nil then
        value = 1
    end

    local oldvalue = table.getfield(ProfileStats,field)
    if oldvalue then
    	table.setfield(ProfileStats,field, oldvalue + value)
    else
    	table.setfield(ProfileStats,field, value)
    end
end

function ProfileStatsSetField(field, value)
    if type(field) ~= "string" then
        return nil
    end
    table.setfield(ProfileStats, field, value)
    return value
end

function ProfileStatsAppendToField(field, value)
    if type(field) ~= "string" then
        return nil
    end
    -- If the field name ends with ".", setfield adds the value to the end of the array
    table.setfield(ProfileStats, field .. ".", value)
end


function SendAccumulatedProfileStats()
	if not STATS_ENABLE then
		return
	end

    local map = TheWorld ~= nil and TheWorld.Map or nil
    local visited = map ~= nil and map:GetNumVisitedTiles() or 0
    local trod = visited - GameStats.StatsLastTrodCount
    ProfileStatsSet("trod", trod)
    dprint(":::::::::::::::::::::::: TROD!", trod)
    GameStats.StatsLastTrodCount = visited
    
	local stats = GetProfileStats(true)
	-- TODO:STATS TheSim:SendProfileStats( stats )
end

--Periodically upload and refresh the player stats, so we always
--have up-to-date stats even if they close/crash the game.
StatsHeartbeatRemaining = 30

function AccumulatedStatsHeartbeat(dt)
    -- only fire this while in-game
--KAJ: TODO stats, commented out for now
--    local player = ThePlayer
--    if player then
--        ProfileStatsAdd("time_played", math.floor(dt*1000))
--        StatsHeartbeatRemaining = StatsHeartbeatRemaining - dt
--        if StatsHeartbeatRemaining < 0 then
--            SendAccumulatedProfileStats()
--            StatsHeartbeatRemaining = 120
--        end
--    end
end

function SubmitCompletedLevel()
	SendAccumulatedProfileStats()
end

function SubmitStartStats(playercharacter)
	if not STATS_ENABLE then
		return
	end
	
	-- At the moment there are no special start stats.
end

function SubmitExitStats()
	if not STATS_ENABLE then
	    Shutdown()
		return
	end

	-- At the moment there are no special exit stats.
	Shutdown()
end

function SubmitQuitStats()
	if not STATS_ENABLE then
		return
	end

	-- At the moment there are no special quit stats.
end

function GetTestGroup()
	local id = TheSim:GetSteamIDNumber()

	local groupid = id%2 -- group 0 must always be default, because GetSteamIDNumber returns 0 for non-steam users
	return groupid
end


function MainMenuStatsAdd(item, value)
    if value == nil then
        value = 1
    end

    if MainMenuStats[item] then
    	MainMenuStats[item] = MainMenuStats[item] + value
    else
    	MainMenuStats[item] = value
    end
end

function GetMainMenuStats(wipe)
	if GetTableSize(MainMenuStats) == 0 then
		return json.encode( {} )
	end

	wipe = wipe or false
	local jsonstats = ''
	local sendstats = BuildContextTable()

	sendstats.stats = MainMenuStats
	dprint("_________________++++++ Sending Accumulated main menu stats...\n")
	ddump(sendstats)

	jsonstats = json.encode( sendstats )

	if wipe then
		MainMenuStats = {}
    end

    return jsonstats
end

function SendMainMenuStats()
	if not STATS_ENABLE then
		return
	end
   
	local stats = GetMainMenuStats(true)
	-- TODO:STATS TheSim:SendProfileStats(stats)
end

function OnLaunchComplete()
	if STATS_ENABLE then
		local sendstats = BuildContextTable()
		sendstats.ownsds = TheSim:GetUserHasLicenseForApp(DONT_STARVE_APPID)
		sendstats.ownsrog = TheSim:GetUserHasLicenseForApp(REIGN_OF_GIANTS_APPID)
		sendstats.betabranch = TheSim:GetSteamBetaBranchName()
		local jsonstats = json.encode( sendstats )
	   	TheSim:SendProfileStats( jsonstats )
	end
end

local statsEventListener
local sessionStatsSent = false

function SuccesfulConnect(account_event, success, event_code, custom_message )
	if event_code == 3 and success == true or
           event_code == 6 and success == true and 
           not sessionStatsSent then
                sessionStatsSent = true
		OnLaunchComplete()
	end
end

function InitStats()
	statsEventListener = CreateEntity()
	statsEventListener.OnAccountEvent = SuccesfulConnect
	RegisterOnAccountEventListener(statsEventListener)
end

