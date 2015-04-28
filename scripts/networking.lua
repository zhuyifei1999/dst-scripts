local InputDialogScreen = require "screens/inputdialog"
local PopupDialogScreen = require "screens/popupdialog"

local emotes = require("emotes")

FirstStartupForNetworking = false

function SpawnSecondInstance()
	if FirstStartupForNetworking then
		if TheNet:GetIsServer() then
			local exepath = CWD.."\\..\\bin\\dontstarve_r.exe"
			os.execute("start "..exepath)	-- run it in a separate process, or we'll be frozen until it exits
			FirstStartupForNetworking = false
		end
	end
end

--V2C: This is for server side processing of remote slash command requests
function Networking_SlashCmd(guid, cmd)
    local entity = Ents[guid]
    if entity ~= nil then
        local cmd, params = emotes.translate(cmd)
        if params ~= nil then
            entity:PushEvent("emote", params)
        end
    end
end

function Networking_Announcement(message, colour)
    if ThePlayer ~= nil and ThePlayer.HUD ~= nil then
        ThePlayer.HUD.eventannouncer:ShowNewAnnouncement(message, colour)
    end
end

function Networking_Say(guid, userid, name, prefab, message, colour, whisper)
    local entity = Ents[guid]
    if entity ~= nil and entity.components.talker ~= nil then
        entity.components.talker:Say(message, nil, nil, nil, true, colour)
    end
    local hud = ThePlayer ~= nil and ThePlayer.HUD or nil
    if hud ~= nil
        and (not whisper
            or (entity ~= nil
                and (hud:HasTargetIndicator(entity) or
                    entity.entity:FrustumCheck()))) then
        hud.controls.networkchatqueue:OnMessageReceived(userid, name, prefab, message, colour, whisper)
    end
end

function Networking_Talk(guid, message)
    local entity = Ents[guid]
    if entity ~= nil and entity.components.talker ~= nil then
        entity.components.talker:Say(message, nil, nil, nil, true)
    end
end

function OnTwitchMessageReceived(username, message, colour)
    if TheWorld ~= nil then
        TheWorld:PushEvent("twitchmessage", {
            username = username,
            message = message,
            colour = colour,
        })
    end
end

function OnTwitchLoginAttempt(success, result)
    if TheWorld ~= nil then
        TheWorld:PushEvent("twitchloginresult", {
            success = success,
            result = result,
        })
    end
end

function OnTwitchChatStatusUpdate(status)
    if TheWorld ~= nil then
        TheWorld:PushEvent("twitchstatusupdate", {
            status = status,
        })
    end
end

function ValidateSpawnPrefabRequest(prefab_name, skin_name)
    local in_dst_char_list = table.contains(DST_CHARACTERLIST, prefab_name)
    local in_mod_char_list = table.contains(MODCHARACTERLIST, prefab_name)
    --TODO: validate skin_name!
    --      second return value is the skin_name if it is valid,
    --      or nil for no skin
    if in_dst_char_list then
        return prefab_name, skin_name
    elseif in_mod_char_list then
        return prefab_name, nil
    else
        return DST_CHARACTERLIST[1], nil
    end
end

function SpawnNewPlayerOnServerFromSim(player_guid, skin_name)
    local player = Ents[player_guid]
    if player ~= nil then
        if player.OnSetSkin ~= nil then
            player:OnSetSkin(skin_name)
        end
        if player.OnNewSpawn ~= nil then
            player:OnNewSpawn()
            player.OnNewSpawn = nil
        end
        TheWorld.components.playerspawner:SpawnAtNextLocation(TheWorld, player)
        SerializeUserSession(player, true)
    end
end

--NOTE: this is called from sim as well, so please check it before any
--      interface changes! (NetworkManager)
function SerializeUserSession(player, isnewspawn)
    if player ~= nil and player.userid ~= nil and (player == ThePlayer or TheNet:GetIsServer()) then
        --we don't care about references for player saves
        local playerinfo--[[, refs]] = player:GetSaveRecord()
        local data = DataDumper(playerinfo, nil, BRANCH ~= "dev")
        TheNet:SerializeUserSession(player.userid, data, isnewspawn == true)
    end
end

function DeleteUserSession(player)
    if player ~= nil and
        player.userid ~= nil and
        (player == ThePlayer or TheNet:GetIsServer()) then
        TheNet:DeleteUserSession(player.userid)
    end
end

function SerializeWorldSession(data, session_identifier, callback)
    TheNet:SerializeWorldSession(data, session_identifier, ENCODE_SAVES, callback)
end

function DownloadMods( server_listing )
	local function enable_server_mods()
		print("We now have the required mods, enable them for server")
		for k,mod in pairs(server_listing.mods_description) do
			if mod.all_clients_require_mod then
				print("Temp Enabling " .. mod.mod_name)
				KnownModIndex:TempEnable(mod.mod_name)
			end
		end
		
		local success, temp_config_data = RunInSandboxSafe(server_listing.mods_config_data)
        if success and temp_config_data then
			KnownModIndex:SetTempModConfigData( temp_config_data )
		end
		
		print("Mods are setup for server, save the mod index and proceed.")
		KnownModIndex:Save()
	end
	
	local function server_listing_contains(mod_desc_table, mod_name )
		for _,mod in pairs(mod_desc_table) do
			if mod.mod_name == mod_name then
				return true
			end
		end
		return false
	end
	
	print("DownloadMods and temp disable")
	KnownModIndex:ClearAllTempModFlags() --clear all old temp mod flags when connecting incase someone killed the process before disconnecting
	
	KnownModIndex:UpdateModInfo()
	for _,mod_name in pairs(KnownModIndex:GetServerModNames()) do
		local modinfo = KnownModIndex:GetModInfo(mod_name)
		if not modinfo.client_only_mod then
			if server_listing_contains( server_listing.mods_description, mod_name ) then
				--we found it, so leave the mod enabled	
			else
				--this mod is required by all clients but the server doesn't have it enabled or it's a server mod, so locally disable it temporarily.
				--print("Temp disabling ",mod_name)
				KnownModIndex:TempDisable(mod_name)
			end
		end
	end
	KnownModIndex:Save()
	
	if server_listing.mods_enabled then
		--verify that you have the same mods enabled as the server
		local have_required_mods = true
		local needed_mods_in_workshop = true
		local mod_count = 0
		for k,mod in pairs(server_listing.mods_description) do
			mod_count = mod_count + 1
			
			if Profile:GetAutoSubscribeModsEnabled() then
				TheSim:SubscribeToMod(mod.mod_name)
			end
			
			if mod.all_clients_require_mod then
				if not KnownModIndex:DoesModExist( mod.mod_name, mod.version ) then
					print("Failed to find mod "..mod.mod_name.." v:"..mod.version)
					
					have_required_mods = false
					local can_dl_mod = TheSim:QueueDownloadTempMod(mod.mod_name, mod.version)
					if not can_dl_mod then
						print("Unable to download mod " .. mod.mod_name .. " from SteamWorkshop")
						needed_mods_in_workshop = false
					end
				end
			end
		end
		if mod_count == 0 then
			print("ERROR: Mods are enabled but the mods_description table has none in it?")
		end
		
		if have_required_mods then
			enable_server_mods()
			TheNet:ServerModsDownloadCompleted(true, "", "")
		else
			if needed_mods_in_workshop then
				TheSim:StartDownloadTempMods( 
					function( success, msg )
						if success then
							--downloading of mods succeeded, now double check if the right versions exists, if it doesn't then we downloaded the wrong version
							local all_mods_good	= true
							local mod_with_invalid_version = nil
							KnownModIndex:UpdateModInfo() --Make sure we're verifying against the latest data in the mod folder
							for k,mod in pairs(server_listing.mods_description) do
								if mod.all_clients_require_mod then
									if not KnownModIndex:DoesModExist( mod.mod_name, mod.version ) then
										all_mods_good = false
										mod_with_invalid_version = mod										
									end
								end
							end
							
							if all_mods_good then
								enable_server_mods()
								TheNet:ServerModsDownloadCompleted(true, "", "")
							else
								local workshop_version = KnownModIndex:GetModInfo(mod_with_invalid_version.mod_name).version
								if workshop_version == nil then
									workshop_version = ""
								end
								local version_mismatch_msg = "The server's version of " .. mod_with_invalid_version.modinfo_name .. " does not match the version on the Steam Workshop. Server version: " .. mod_with_invalid_version.version .. " Workshop version: " .. workshop_version
								TheNet:ServerModsDownloadCompleted(false, version_mismatch_msg, "SERVER_MODS_WORKSHOP_VERSION_MISMATCH" )
							end
						else
							if msg == "Access to mod denied" then
								TheNet:ServerModsDownloadCompleted(false, msg, "SERVER_MODS_WORKSHOP_ACCESS_DENIED")								
							else
								TheNet:ServerModsDownloadCompleted(false, msg, "SERVER_MODS_WORKSHOP_FAILURE")
							end
						end
					end
				)
			else
				TheNet:ServerModsDownloadCompleted(false, "You don't have the required mods to play on this server and they don't exist on the Workshop. You will need to download them manually.", "SERVER_MODS_NOT_ON_WORKSHOP" )
			end
		end
	else
		TheNet:ServerModsDownloadCompleted(true, "", "")
	end
end

function JoinServer( server_listing, optional_password_override )
		
	local function start_client( password )
		local start_worked = TheNet:StartClient( server_listing.ip, server_listing.port, server_listing.guid, password )
		if start_worked then
			DisableAllDLC()
		end
		ShowCancelTip()
		ShowLoading()
		TheFrontEnd:Fade(false, 1)
	end
	
	local function after_mod_warning(pop_screen)
		if pop_screen then
			TheFrontEnd:PopScreen()
		end

		if server_listing.has_password and (optional_password_override == "" or optional_password_override == nil) then
			TheFrontEnd:Fade(true, 0)
			local password_prompt_screen
			password_prompt_screen = InputDialogScreen( STRINGS.UI.SERVERLISTINGSCREEN.PASSWORDREQUIRED, 
											{   { 
													text = STRINGS.UI.SERVERLISTINGSCREEN.OK, 
													cb = function()
														start_client( password_prompt_screen:GetActualString() ) 
														TheFrontEnd:PopScreen()             
													end
												},
												{ 
													text = STRINGS.UI.SERVERLISTINGSCREEN.CANCEL, 
													cb = function()
														TheFrontEnd:PopScreen()                 
													end
											}   } 
										)
			password_prompt_screen.edit_text.OnTextEntered = function()
				start_client( password_prompt_screen:GetActualString() ) 
				TheFrontEnd:PopScreen()
			end
			if not Profile:GetShowPasswordEnabled() then
				password_prompt_screen.edit_text:SetPassword(true)
			end
			TheFrontEnd:PushScreen(password_prompt_screen)	
			password_prompt_screen.edit_text:OnControl(CONTROL_ACCEPT, false)
		else
			start_client( optional_password_override or "" )
		end
	end
	
	if server_listing.mods_enabled then
		--let the user know the warning about mods
		local mod_warning = PopupDialogScreen(STRINGS.UI.SERVERLISTINGSCREEN.MOD_WARNING_TITLE, STRINGS.UI.SERVERLISTINGSCREEN.MOD_WARNING_BODY,
			{
				{text=STRINGS.UI.SERVERLISTINGSCREEN.OK, cb = function() after_mod_warning( true ) end},
				{text=STRINGS.UI.SERVERLISTINGSCREEN.CANCEL, cb = function() TheFrontEnd:PopScreen() end}
			}
		)
		TheFrontEnd:PushScreen( mod_warning )
	else
		after_mod_warning( false )
	end
end

function GetAvailablePlayerColours()
    -- -Return an ordered list of player colours, and a default colour.
    --
    -- -Default colour should not be in the list, and it is only used
    --  when data is not available yet or in case of errors.
    --
    -- -Colours are assigned in order as players join, so modders can
    --  prerandomize this list if they want random assignments.
    --
    -- -Players will be reassigned their previous colour on a server if
    --  it hasn't been used, and the server is in the same session.

    --Using a better colour theme to match world tones
    local colours =
    {
        PLAYERCOLOURS.TOMATO,
        PLAYERCOLOURS.TAN,
        PLAYERCOLOURS.PLUM,
        PLAYERCOLOURS.BURLYWOOD,
        PLAYERCOLOURS.RED,
        PLAYERCOLOURS.PERU,
        PLAYERCOLOURS.DARKPLUM,
        PLAYERCOLOURS.EGGSHELL,
        PLAYERCOLOURS.SALMON,
        PLAYERCOLOURS.CHOCOLATE,
        PLAYERCOLOURS.VIOLETRED,
        PLAYERCOLOURS.SANDYBROWN,
        PLAYERCOLOURS.BROWN,
        PLAYERCOLOURS.BISQUE,
        PLAYERCOLOURS.PALEVIOLETRED,
        PLAYERCOLOURS.GOLDENROD,
        PLAYERCOLOURS.ROSYBROWN,
        PLAYERCOLOURS.LIGHTTHISTLE,
        PLAYERCOLOURS.PINK,
        PLAYERCOLOURS.LEMON,
        PLAYERCOLOURS.FIREBRICK,
        PLAYERCOLOURS.LIGHTGOLD,
        PLAYERCOLOURS.MEDIUMPURPLE,
        PLAYERCOLOURS.THISTLE,
    }
    --TODO: forward to a mod function before returning?
    return colours, DEFAULT_PLAYER_COLOUR
end

function SaveServerListingGameData( data )
	local encoded_data = DataDumper( data, nil, false )
	TheNet:SetGameData( encoded_data )
	return true
end

function Networking_ReceiveVote(id, poll, voter, choice, numVotes)
    if TheWorld.net then
        TheWorld.net.components.voting:ReceiveVote(id, poll, voter, choice, numVotes)
    end
end

function Networking_NotifyVoteStart(id, poll, voter, choice)
    if TheWorld.net then
        TheWorld.net.components.voting:NotifyVoteStart(id, poll, voter, choice)
    end
end

function Networking_NotifyVoteEnd(id, poll)
    if TheWorld.net then
        TheWorld.net.components.voting:NotifyVoteEnd(id, poll)
    end
end

function Networking_NotifyVoteCast(id, poll, voter, choice, numVotes)
    if TheWorld.net then
        TheWorld.net.components.voting:NotifyVoteCast(id, poll, voter, choice, numVotes)
    end
end

function WorldResetFromSim()
	print( "received reset request in WorldResetFromSim")
    if TheWorld ~= nil and TheWorld.ismastersim then
		print( "pushing ms_worldreset")
        TheWorld:PushEvent("ms_worldreset")
    end
end

function StartDedicatedServer()
	print "Starting Dedicated Server Game"
	local start_in_online_mode = not TheNet:IsDedicatedLanServer()
	local server_started = TheNet:StartServer( start_in_online_mode )
	if server_started == true then
		DisableAllDLC()
		local server_save_slot = TheNet:GetServerSaveSlot()
		if server_save_slot ~= SaveGameIndex:GetCurrentSaveSlot() then
			print( "Overriding server save slot to: ", server_save_slot )
			SaveGameIndex:SetCurrentIndex( server_save_slot )
		end
        
		StartNextInstance({reset_action = RESET_ACTION.LOAD_SLOT, save_slot=SaveGameIndex:GetCurrentSaveSlot()})
	end
end
	