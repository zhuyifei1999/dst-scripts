local InputDialogScreen = require "screens/inputdialog"
local PopupDialogScreen = require "screens/popupdialog"
local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local ConnectingToGamePopup = require "screens/connectingtogamepopup"

local emotes = require("emotes")

FirstStartupForNetworking = false

function SpawnSecondInstance()
    if FirstStartupForNetworking then
        if TheNet:GetIsServer() then
            local exepath = CWD.."\\..\\bin\\dontstarve_r.exe"
            os.execute("start "..exepath)   -- run it in a separate process, or we'll be frozen until it exits
            FirstStartupForNetworking = false
        end
    end
end

--V2C: This is for server side processing of remote slash command requests
function Networking_SlashCmd(guid, cmd)
    local entity = Ents[guid]
    if entity ~= nil then
        if string.sub(cmd, 2, 7) == "rescue" then
            entity:PutBackOnGround()
        else
            local cmd, params = emotes.translate(cmd)
            if params ~= nil then
                entity:PushEvent("emote", params)
            end
        end
    end
end

function Networking_Announcement(message, colour, announce_type)
    if ThePlayer ~= nil and ThePlayer.HUD ~= nil and ThePlayer.HUD.eventannouncer.inst:IsValid() then
        ThePlayer.HUD.eventannouncer:ShowNewAnnouncement(message, colour, announce_type)
    end
end

function Networking_JoinAnnouncement(name, colour)
    Networking_Announcement(name.." "..STRINGS.UI.NOTIFICATION.JOINEDGAME, colour, "join_game")
end

function Networking_LeaveAnnouncement(name, colour)
    Networking_Announcement(name.." "..STRINGS.UI.NOTIFICATION.LEFTGAME, colour, "leave_game")
end

function Networking_SkinAnnouncement(user_name, user_colour, skin_name)
    if ThePlayer ~= nil and ThePlayer.HUD ~= nil and ThePlayer.HUD.eventannouncer.inst:IsValid() then
        ThePlayer.HUD.eventannouncer:ShowSkinAnnouncement(user_name, user_colour, skin_name)
    end
end

function Networking_Say(guid, userid, name, prefab, message, colour, whisper)
    local entity = Ents[guid]
    if entity ~= nil and entity.components.talker ~= nil then
        entity.components.talker:Say(entity:HasTag("mime") and "" or message, nil, nil, nil, true, colour)
    end
    if not whisper then
        local screen = TheFrontEnd:GetActiveScreen()
        if screen ~= nil and screen.name == "LobbyScreen" then
            screen.chatqueue:OnMessageReceived(userid, name, prefab, message, colour, whisper)
        end
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

function ValidateRecipeSkinRequest(user_id, prefab_name, skin)
    local validated_skin = nil
    if skin ~= nil and skin ~= "" and TheInventory:CheckClientOwnership(user_id, skin) then
        if table.contains( PREFAB_SKINS[prefab_name], skin ) then
            validated_skin = skin
        end
    end
    return validated_skin
end

function ValidateSpawnPrefabRequest(user_id, prefab_name, skin_base, clothing_body, clothing_hand, clothing_legs, clothing_feet)
    local in_mod_char_list = table.contains(MODCHARACTERLIST, prefab_name)

    local valid_chars = ExceptionArrays(DST_CHARACTERLIST, MODCHARACTEREXCEPTIONS_DST)
    local in_valid_char_list = table.contains(valid_chars, prefab_name)

    local validated_prefab = prefab_name
    local validated_skin_base = nil
    local validated_clothing_body = nil
    local validated_clothing_hand = nil
    local validated_clothing_legs = nil
    local validated_clothing_feet = nil

    if in_valid_char_list then
        if skin_base == prefab_name.."_none" then
            -- If default skin, we do not need to check
            validated_skin_base = skin_base
        elseif TheInventory:CheckClientOwnership(user_id, skin_base) then
            --check if the skin_base actually belongs to the prefab
            if table.contains( PREFAB_SKINS[prefab_name], skin_base ) then
                validated_skin_base = skin_base
            end
        end
    elseif in_mod_char_list then
        --if mod character, don't use a skin
    elseif table.getn(valid_chars) > 0 then
        validated_prefab = valid_chars[1]
    else
        validated_prefab = DST_CHARACTERLIST[1]
    end

    if clothing_body ~= "" and TheInventory:CheckClientOwnership(user_id, clothing_body) then
        validated_clothing_body = clothing_body 
    end

    if clothing_hand ~= "" and TheInventory:CheckClientOwnership(user_id, clothing_hand) then
        validated_clothing_hand = clothing_hand 
    end

    if clothing_legs ~= "" and TheInventory:CheckClientOwnership(user_id, clothing_legs) then
        validated_clothing_legs = clothing_legs 
    end

    if clothing_feet ~= "" and TheInventory:CheckClientOwnership(user_id, clothing_feet) then
        validated_clothing_feet = clothing_feet 
    end

    return validated_prefab, validated_skin_base, validated_clothing_body, validated_clothing_hand, validated_clothing_legs, validated_clothing_feet
end

function SpawnNewPlayerOnServerFromSim(player_guid, skin_base, clothing_body, clothing_hand, clothing_legs, clothing_feet)
    local player = Ents[player_guid]
    if player ~= nil then
        local skinner = player.components.skinner
        skinner:SetClothing(clothing_body)
        skinner:SetClothing(clothing_hand)
        skinner:SetClothing(clothing_legs)
        skinner:SetClothing(clothing_feet)
        skinner:SetSkinName(skin_base)
        skinner:SetSkinMode("normal_skin")

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
                    print("Failed to find mod "..mod.mod_name.." v:"..mod.version )
                    
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
                            local all_mods_good = true
                            local mod_with_invalid_version = nil
                            KnownModIndex:UpdateModInfo() --Make sure we're verifying against the latest data in the mod folder
                            for k,mod in pairs(server_listing.mods_description) do
                                if mod.all_clients_require_mod then
                                    if not KnownModIndex:DoesModExist( mod.mod_name, mod.version, mod.version_compatible ) then
                                        all_mods_good = false
                                        mod_with_invalid_version = mod                                      
                                    end
                                end
                            end

                            if all_mods_good then
                                enable_server_mods()
                                TheNet:ServerModsDownloadCompleted(true, "", "")
                            else
                                local workshop_version = ""
                                if KnownModIndex:GetModInfo(mod_with_invalid_version.mod_name) ~= nil then
                                    workshop_version = KnownModIndex:GetModInfo(mod_with_invalid_version.mod_name).version
                                else
                                    print("ERROR: " .. (mod_with_invalid_version.mod_name or "") .. " has no modinfo, why???" )
                                end
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

function ShowConnectingToGamePopup()
    local active_screen = TheFrontEnd:GetActiveScreen()
    if active_screen == nil or active_screen.name ~= "ConnectingToGamePopup" then
        TheFrontEnd:PushScreen(ConnectingToGamePopup())
    end
end

function JoinServer(server_listing, optional_password_override)
    local function send_response(password)
        -- Just pass the guid in here, the network manager should have this listing
        local start_worked = TheNet:JoinServerResponse( false, server_listing.guid, password )

        if start_worked then
            DisableAllDLC()
        end
        ShowConnectingToGamePopup()
    end

    local function on_cancelled()
        TheNet:JoinServerResponse( true )
    end

    local function after_mod_warning(pop_screen)
        if pop_screen then
            TheFrontEnd:PopScreen()
        end

        if server_listing.has_password and (optional_password_override == "" or optional_password_override == nil) then
            local password_prompt_screen
            password_prompt_screen = InputDialogScreen( STRINGS.UI.SERVERLISTINGSCREEN.PASSWORDREQUIRED, 
                                            {
                                                {
                                                    text = STRINGS.UI.SERVERLISTINGSCREEN.OK,
                                                    cb = function()
                                                        TheFrontEnd:PopScreen()
                                                        send_response( password_prompt_screen:GetActualString() )
                                                    end
                                                },
                                                {
                                                    text = STRINGS.UI.SERVERLISTINGSCREEN.CANCEL,
                                                    cb = function()
                                                        TheFrontEnd:PopScreen()
                                                        on_cancelled()
                                                    end
                                                },
                                            },
                                        true )
            password_prompt_screen.edit_text.OnTextEntered = function()
                if password_prompt_screen:GetActualString() ~= "" then
                    TheFrontEnd:PopScreen()
                    send_response( password_prompt_screen:GetActualString() ) 
                else
                    password_prompt_screen.edit_text:SetEditing(true)
                end
            end
            if not Profile:GetShowPasswordEnabled() then
                password_prompt_screen.edit_text:SetPassword(true)
            end
            TheFrontEnd:PushScreen(password_prompt_screen)  
            password_prompt_screen.edit_text:SetForceEdit(true)
            password_prompt_screen.edit_text:OnControl(CONTROL_ACCEPT, false)
        else
            send_response( optional_password_override or "" )
        end
    end

    if server_listing.mods_enabled and
        not IsMigrating() and
        (server_listing.dedicated or not server_listing.owner) and
        Profile:ShouldWarnModsEnabled() then

        local checkbox_parent = Widget("checkbox_parent")
        local checkbox = checkbox_parent:AddChild(ImageButton("images/ui.xml", "checkbox_off.tex", "checkbox_off_highlight.tex", "checkbox_off_disabled.tex", nil, nil, {1,1}, {0,0}))
        local text = checkbox_parent:AddChild(Text(NEWFONT, 40, STRINGS.UI.SERVERLISTINGSCREEN.SHOW_MOD_WARNING))
        local textW, textH = text:GetRegionSize()
        local imageW, imageH = checkbox:GetSize()
        text:SetVAlign(ANCHOR_LEFT)
        text:SetColour(0,0,0,1)
        local checkbox_x = -textW/2 - (imageW*2) 
        local region = 600
        checkbox:SetPosition(checkbox_x, 0)
        text:SetRegionSize(region,50)
        text:SetPosition(checkbox_x + textW/2 + imageW/1.5, 0)
        local bg = checkbox_parent:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
        bg:MoveToBack()
        bg:SetClickable(false)
        bg:ScaleToSize(textW + imageW + 40, 50)
        bg:SetPosition(-75,2)
        checkbox_parent.do_warning = true
        checkbox_parent.focus_forward = checkbox
        checkbox:SetOnClick(function()
            checkbox_parent.do_warning = not checkbox_parent.do_warning
            if checkbox_parent.do_warning then
                checkbox:SetTextures("images/ui.xml", "checkbox_off.tex", "checkbox_off_highlight.tex", "checkbox_off_disabled.tex", nil, nil, {1,1}, {0,0})
            else
                checkbox:SetTextures("images/ui.xml", "checkbox_on.tex", "checkbox_on_highlight.tex", "checkbox_on_disabled.tex", nil, nil, {1,1}, {0,0})
            end
        end)
        local menuitems =
        {
            {widget=checkbox_parent, offset=Vector3(250,70,0)},
            {text=STRINGS.UI.SERVERLISTINGSCREEN.CONTINUE,
                cb = function()
                    Profile:SetWarnModsEnabled(checkbox_parent.do_warning)
                    after_mod_warning(true)
                end, offset=Vector3(-90,0,0)},
            {text=STRINGS.UI.SERVERLISTINGSCREEN.CANCEL,
                cb = function()
                    TheFrontEnd:PopScreen()
                    on_cancelled()
                end, offset=Vector3(-90,0,0)}
        }

        --let the user know the warning about mods
        local mod_warning = PopupDialogScreen(STRINGS.UI.SERVERLISTINGSCREEN.MOD_WARNING_TITLE, STRINGS.UI.SERVERLISTINGSCREEN.MOD_WARNING_BODY, menuitems)
        mod_warning.menu.items[1]:SetFocusChangeDir(MOVE_DOWN, mod_warning.menu.items[2])
        mod_warning.menu.items[1]:SetFocusChangeDir(MOVE_RIGHT, nil)
        mod_warning.menu.items[2]:SetFocusChangeDir(MOVE_LEFT, nil)
        mod_warning.menu.items[2]:SetFocusChangeDir(MOVE_RIGHT, mod_warning.menu.items[3])
        mod_warning.menu.items[2]:SetFocusChangeDir(MOVE_UP, mod_warning.menu.items[1])
        mod_warning.menu.items[3]:SetFocusChangeDir(MOVE_LEFT, mod_warning.menu.items[2])
        mod_warning.menu.items[3]:SetFocusChangeDir(MOVE_UP, mod_warning.menu.items[1])

        mod_warning.menu.items[2]:SetScale(.7)
        mod_warning.menu.items[3]:SetScale(.7)
        mod_warning.text:SetPosition(5, 10, 0)

        TheFrontEnd:PushScreen( mod_warning )
    else
        after_mod_warning( false )
    end
end

function MigrateToServer(serverIp, serverPort, serverPassword, serverNetId)
    local function do_join_server()
        serverNetId = serverNetId or ""

        StartNextInstance({
            reset_action = RESET_ACTION.JOIN_SERVER,
            serverIp = serverIp,
            serverPort = serverPort,
            serverPassword = serverPassword,
            serverNetId = serverNetId,
        })
    end

    if InGamePlay() then
        do_join_server()
    else
        DoLoadingPortal(do_join_server)
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

local function DoReset()
    StartNextInstance({
        reset_action = RESET_ACTION.LOAD_SLOT,
        save_slot = SaveGameIndex:GetCurrentSaveSlot()
    })
end

function WorldResetFromSim()
    if TheWorld ~= nil and TheWorld.ismastersim then
        print("Received world reset request")
        TheWorld:PushEvent("ms_worldreset")
        SaveGameIndex:DeleteSlot(
            SaveGameIndex:GetCurrentSaveSlot(),
            DoReset,
            true -- true causes world gen options to be preserved
        )
    end
end

function WorldRollbackFromSim(count)
    if TheWorld ~= nil and TheWorld.ismastershard then
        print("Received world rollback request: count="..tostring(count))
        if count > 0 then
            if TheWorld.net == nil or
                TheWorld.net.components.autosaver == nil or
                GetTime() - TheWorld.net.components.autosaver:GetLastSaveTime() < 30 then
                count = count + 1
            end
            TheNet:TruncateSnapshots(TheWorld.meta.session_identifier, -count)
        end
        DoReset()
    end
end

function UpdateServerTagsString()
    --V2C: ughh... well at least try to keep this in sync with
    --     servercreationscreen.lua BuildTagsStringHosting()

    local tagsTable = {}

    table.insert(tagsTable, TheNet:GetDefaultGameMode())

    if TheNet:GetDefaultPvpSetting() then
        table.insert(tagsTable, STRINGS.TAGS.PVP)
    end

    if TheNet:GetDefaultFriendsOnlyServer() then
        table.insert(tagsTable, STRINGS.TAGS.FRIENDSONLY)
    end

    if TheNet:GetDefaultLANOnlyServer() then
        table.insert(tagsTable, STRINGS.TAGS.LOCAL)
    end

    if TheNet:GetDefaultClanID() ~= "" then
        table.insert(tagsTable, STRINGS.TAGS.CLAN)
    end

    local worldoptions = SaveGameIndex:GetSlotGenOptions()
    local worlddata = worldoptions ~= nil and worldoptions[1] or nil
    if worlddata ~= nil and worlddata.location ~= nil then
        local locationtag = STRINGS.TAGS.LOCATION[string.upper(worlddata.location)]
        if locationtag ~= nil then
            table.insert(tagsTable, locationtag)
        end
    end

    TheNet:SetServerTags(BuildTagsStringCommon(tagsTable))
end

function UpdateServerWorldGenDataString()
    local clusteroptions = {}
    local worldoptions = SaveGameIndex:GetSlotGenOptions()
    table.insert(clusteroptions, worldoptions ~= nil and worldoptions[1] or {})

    if TheShard:IsMaster() then
        -- Merge slave worldgen data
        for k, v in pairs(Shard_GetConnectedShards()) do
            if v.world ~= nil and v.world[1] ~= nil then
                table.insert(clusteroptions, v.world[1])
            end
        end
    end

    --V2C: TODO: Likely to exceed data size limit with custom multilevel worlds

    TheNet:SetWorldGenData(DataDumper(clusteroptions, nil, false))
end

function GetDefaultServerData()
    --V2C: Note for online_mode:
    --     As long as StartServer/StartDedicatedServers has been
    --     called before this, then TheNet:IsOnlineMode() should
    --     return the desired value.
    return
    {
        intention = TheNet:GetDefaultServerIntention(),
        pvp = TheNet:GetDefaultPvpSetting(),
        game_mode = TheNet:GetDefaultGameMode(),
        online_mode = TheNet:IsOnlineMode(),
        max_players = TheNet:GetDefaultMaxPlayers(),
        name = TheNet:GetDefaultServerName(),
        password = TheNet:GetDefaultServerPassword(),
        description = TheNet:GetDefaultServerDescription(),
        privacy_type =
            (TheNet:GetDefaultFriendsOnlyServer() and PRIVACY_TYPE.FRIENDS) or
            (TheNet:GetDefaultLANOnlyServer() and PRIVACY_TYPE.LOCAL) or
            (TheNet:GetDefaultClanOnly() and PRIVACY_TYPE.CLAN) or
            PRIVACY_TYPE.PUBLIC,
        clan =
        {
            id = TheNet:GetDefaultClanID(),
            only = TheNet:GetDefaultClanOnly(),
            admin = TheNet:GetDefaultClanAdmins(),
        },
    }
end

function StartDedicatedServer()
    print("Starting Dedicated Server Game")
    local start_in_online_mode = not TheNet:IsDedicatedOfflineCluster()
    local server_started = TheNet:StartServer(start_in_online_mode)
    if server_started == true then
        DisableAllDLC()

        --V2C: From now on, we want to actually write data into
        --     a slot before initiating LOAD_SLOT action on it!

        local slot = SaveGameIndex:GetCurrentSaveSlot()
        local serverdata = GetDefaultServerData()

        local function onsaved()
            -- Collect the tags we want and set the tags string
            UpdateServerTagsString()
            StartNextInstance({ reset_action = RESET_ACTION.LOAD_SLOT, save_slot = slot })
        end

        if SaveGameIndex:IsSlotEmpty(slot) then
            SaveGameIndex:StartSurvivalMode(slot, nil, serverdata, onsaved)
        else
            SaveGameIndex:UpdateServerData(slot, serverdata, onsaved)
        end
    end
end

function JoinServerFilter()
    return true
end

function LookupPlayerInstByUserID(userid)
    for i,v in ipairs(AllPlayers) do
        if v.userid == userid then
            return v
        end
    end
end
