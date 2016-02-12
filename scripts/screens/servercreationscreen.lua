local Screen = require "widgets/screen"
local Widget = require "widgets/widget"

local Text = require "widgets/text"
local Image = require "widgets/image"
local Button = require "widgets/button"
local ImageButton = require "widgets/imagebutton"

local ServerSettingsTab = require "widgets/serversettingstab"
local CustomizationTab = require "widgets/customizationtab"
local ModsTab = require "widgets/modstab"
local TopModsPanel = require "widgets/topmodspanel"
local SnapshotTab = require "widgets/snapshottab"
local BanTab = require "widgets/bantab"

local TEMPLATES = require "widgets/templates"
local OnlineStatus = require "widgets/onlinestatus"
local PopupDialogScreen = require "screens/popupdialog"
local TextListPopupDialogScreen = require "screens/textlistpopupdialog"
local LaunchingServerPopup = require "screens/launchingserverpopup"

require("constants")
require("tuning")

local DEFAULT_ATLAS = "images/saveslot_portraits.xml"
local DEFAULT_AVATAR = "unknown.tex"

local ServerCreationScreen = Class(Screen, function(self)
    Widget._ctor(self, "ServerCreationScreen")

    local left_col = -RESOLUTION_X*.05 - 285
    local right_col = RESOLUTION_X*.30 - 230
	
    self.bg = self:AddChild(TEMPLATES.AnimatedPortalBackground())

    self.fg = self:AddChild(TEMPLATES.AnimatedPortalForeground())

    self.root = self:AddChild(Widget("root"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.menu_bg = self.root:AddChild(TEMPLATES.LeftGradient())

    self.detail_panel_frame_parent = self.root:AddChild(Widget("detail_frame"))
    self.detail_panel_frame_parent:SetPosition(5, -15)
    self.detail_panel_frame = self.detail_panel_frame_parent:AddChild(TEMPLATES.CenterPanel(.65, .67, true, 610, 500, 46, -28))
    self.detail_panel_frame.bg:SetScale(.67, .61)
    self.detail_panel_frame.bg:SetPosition(5, -20)
    self.detail_panel_frame.bg:SetRotation(180)

    self.top_line = self.detail_panel_frame_parent:AddChild(Image("images/ui.xml", "line_horizontal_5.tex"))
    self.top_line:SetScale(.705, 1)
    self.top_line:SetPosition(0, 132, 0)

    self.bottom_line = self.detail_panel_frame_parent:AddChild(Image("images/ui.xml", "line_horizontal_5.tex"))
    self.bottom_line:SetScale(.705, 1)
    self.bottom_line:SetPosition(0, -253, 0)

    self.right_line = self.detail_panel_frame_parent:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
    self.right_line:SetScale(1, .6)
    self.right_line:SetPosition(420, -60, 0)

    self.RoG = false

    self.dirty = false

    self.saveslot = -1

    self.nav_bar = self.root:AddChild(TEMPLATES.NavBarWithScreenTitle(STRINGS.UI.SERVERCREATIONSCREEN.HOST_GAME, "tall"))
    --self.load_panel was prev thing


    self.detail_panel = self.root:AddChild( Widget("detail_panel") )
    self.detail_panel:SetPosition(right_col, 0)

    self:RefreshNavButtons()

    self:MakeButtons()

    -- Set up all the tabs and the buttons to nav
    self:MakeSettingsTab()
    self:MakeWorldTab()
    self:MakeModsTab()
    self:MakeSnapshotTab()
    self:MakeBansTab()

    self:HideAllTabs()

    self.onlinestatus = self.fg:AddChild(OnlineStatus())

    self.refresh_load_panel = false

    self.title_portrait_bg = self.detail_panel_frame_parent:AddChild(Image("images/saveslot_portraits.xml", "background.tex"))
    self.title_portrait_bg:SetScale(.65, .65, 1)
    self.title_portrait_bg:SetPosition(-367, 175, 0)
    self.title_portrait_bg:SetClickable(false)   

    self.title_portrait = self.title_portrait_bg:AddChild(Image())
    self.title_portrait:SetClickable(false)

    self.title = self.detail_panel_frame_parent:AddChild(Text(BUTTONFONT, 50, "", {0,0,0,1}))
    self.title:SetPosition(-20, 182)
    self.title:SetRegionSize(600, 60)
    self.title:SetHAlign(ANCHOR_LEFT)

    self.day_title  = self.detail_panel_frame_parent:AddChild(Text(BUTTONFONT, 22, "", {0,0,0,1}))
    self.day_title:SetPosition(-20, 148)
    self.day_title:SetRegionSize(600, 60)
    self.day_title:SetHAlign(ANCHOR_LEFT)

    self.default_focus = self.save_slots[1]

    self:DoFocusHookUps()

    local startingsaveslot = SaveGameIndex:GetLastUsedSlot()
    if startingsaveslot < 0 or SaveGameIndex:IsSlotEmpty(startingsaveslot) then
        for k = 1, NUM_DST_SAVE_SLOTS do
            if SaveGameIndex:IsSlotEmpty(k) then
                startingsaveslot = k
                break
            end
        end
    end
    if startingsaveslot < 0 then
        startingsaveslot = 1 --if we have no empty slots and no last slot used, pick the first slot
    end

    self:OnClickSlot(startingsaveslot, true) --This also sets the tab to be server settings when "true" is passed
end)

function ServerCreationScreen:OnBecomeActive()
    ServerCreationScreen._base.OnBecomeActive(self)
    self:Enable()
    self.mods_tab:OnBecomeActive()
    if self.last_focus then self.last_focus:SetFocus() end
end

function ServerCreationScreen:OnBecomeInactive()
    ServerCreationScreen._base.OnBecomeInactive(self)
end

function ServerCreationScreen:OnDestroy()
    self.mods_tab:OnDestroy()
	self._base.OnDestroy(self)
end

function ServerCreationScreen:UpdateTitle(slotnum, fromTextEntered)
    if not fromTextEntered then
        if self.save_slots[slotnum] and self.save_slots[slotnum].character ~= nil and not self.save_slots[slotnum].isempty then
            self.title_portrait:SetTexture(self.save_slots[slotnum].character_atlas, self.save_slots[slotnum].character..".tex")
        else
            self.title_portrait:SetTexture(DEFAULT_ATLAS, DEFAULT_AVATAR)
        end
    end

    self.title:SetString(self.server_settings_tab:GetServerName())

    if SaveGameIndex:GetSlotDay(slotnum) == nil then
        --V2C: slot day is never updated in the new cluster save slots,
        --     but the nil check for new slots is still valid... - __-"
        self.day_title:SetString(STRINGS.UI.SERVERCREATIONSCREEN.SERVERDAY_NEW)
    elseif TheNet:GetUseLegacyClientHosting() then
        self.day_title:SetString(STRINGS.UI.SERVERCREATIONSCREEN.SERVERDAY.." "..SaveGameIndex:GetSlotDay(slotnum))
    else
        local session_id = SaveGameIndex:GetClusterSlotSession(slotnum)
        if session_id ~= nil then
            local day = 1
            local season = nil
            local file = TheNet:GetWorldSessionFileInClusterSlot(slotnum, "Master", session_id)
            if file ~= nil then
                TheSim:GetPersistentStringInClusterSlot(slotnum, "Master", file,
                    function(success, str)
                        if success and str ~= nil and #str > 0 then
                            local success, savedata = RunInSandbox(str)
                            if success and savedata ~= nil and GetTableSize(savedata) > 0 then
                                local worlddata = savedata.world_network ~= nil and savedata.world_network.persistdata or nil
                                if worlddata ~= nil then
                                    if worlddata.clock ~= nil then
                                        day = (worlddata.clock.cycles or 0) + 1
                                    end

                                    if worlddata.seasons ~= nil and worlddata.seasons.season ~= nil then
                                        season = STRINGS.UI.SERVERLISTINGSCREEN.SEASONS[string.upper(worlddata.seasons.season)]
                                        if season ~= nil and
                                            worlddata.seasons.elapseddaysinseason ~= nil and
                                            worlddata.seasons.remainingdaysinseason ~= nil then
                                            if worlddata.seasons.remainingdaysinseason * 3 <= worlddata.seasons.elapseddaysinseason then
                                                season = STRINGS.UI.SERVERLISTINGSCREEN.LATE_SEASON_1..season..STRINGS.UI.SERVERLISTINGSCREEN.LATE_SEASON_2
                                            elseif worlddata.seasons.elapseddaysinseason * 3 <= worlddata.seasons.remainingdaysinseason then
                                                season = STRINGS.UI.SERVERLISTINGSCREEN.EARLY_SEASON_1..season..STRINGS.UI.SERVERLISTINGSCREEN.EARLY_SEASON_2
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
            end
            self.day_title:SetString((season ~= nil and (season.." ") or "")..STRINGS.UI.SERVERCREATIONSCREEN.SERVERDAY.." "..day)
        else
            self.day_title:SetString(STRINGS.UI.SERVERCREATIONSCREEN.SERVERDAY_NEW)
        end
    end

    -- may also want to update the string used on the nav button...
end

function ServerCreationScreen:UpdateModeSpinner(slotnum)
    self.server_settings_tab:UpdateModeSpinner(slotnum)
end

function ServerCreationScreen:UpdateTabs(slotnum, prevslot, fromDelete)
	self.server_settings_tab:SavePrevSlot(prevslot) --needs to happen before mods_tab:SetSaveSlot so that we don't lose the current game mode selection when the next slot's mods are applied

    self.mods_tab:SetSaveSlot(slotnum, fromDelete) --needs to happen before server_settings_tab:UpdateDetails
    
    self.server_settings_tab:UpdateDetails(slotnum, prevslot, fromDelete)

    self.world_tab:UpdateSlot(slotnum, prevslot, fromDelete)

    self.snapshot_tab:SetSaveSlot(slotnum, prevslot, fromDelete)

    self:UpdateButtons(slotnum)
end

function ServerCreationScreen:UpdateButtons(slotnum)
    -- No save data
    if not slotnum or (slotnum < 0 or SaveGameIndex:IsSlotEmpty(slotnum)) then
        if self.delete_button then self.delete_button:Disable() end
        if self.create_button then self.create_button.text:SetString(STRINGS.UI.SERVERCREATIONSCREEN.CREATE) end
    else -- Save data            
        if self.delete_button then self.delete_button:Enable() end
        if self.create_button then self.create_button.text:SetString(STRINGS.UI.SERVERCREATIONSCREEN.RESUME) end
    end
    self.mods_button:SetText(STRINGS.UI.MAINSCREEN.MODS.." ("..self.mods_tab:GetNumberOfModsEnabled()..")")
end

local function BuildTagsStringHosting(creationScreen)
    if TheNet:IsDedicated() then return nil end

    local tagsTable = {}

    table.insert(tagsTable, creationScreen.server_settings_tab:GetGameMode())
    
    if creationScreen.server_settings_tab:GetPVP() then
        table.insert(tagsTable, STRINGS.TAGS.PVP)
    end

    if creationScreen.server_settings_tab:GetPrivacyType() == PRIVACY_TYPE.FRIENDS then
        table.insert(tagsTable, STRINGS.TAGS.FRIENDSONLY)
    elseif creationScreen.server_settings_tab:GetPrivacyType() == PRIVACY_TYPE.CLAN then
        table.insert(tagsTable, STRINGS.TAGS.CLAN)
    elseif creationScreen.server_settings_tab:GetPrivacyType() == PRIVACY_TYPE.LOCAL then
        table.insert(tagsTable, STRINGS.TAGS.LOCAL)
    end

    return BuildTagsStringCommon(tagsTable)
end

function ServerCreationScreen:DeleteSlot(slot, cb)
    local menu_items = 
    {
        -- ENTER
        {
            text=STRINGS.UI.SERVERCREATIONSCREEN.DELETE, 
            cb = function()
                TheFrontEnd:PopScreen()
                
                SaveGameIndex:DeleteSlot(slot, function() 
                    self.save_slots[slot]:Kill()
                    self.save_slots[slot] = self.save_slots:AddChild(self:MakeSaveSlotButton(slot))
                    self:UpdateTabs(slot, nil, true)
                end)

                self:RefreshNavButtons()
                self:OnClickSlot(self.saveslot, true)
                self:Enable()
            end
        },
        -- ESC
        {
            text=STRINGS.UI.SERVERCREATIONSCREEN.CANCEL, 
            cb = function() 
                TheFrontEnd:PopScreen() 
            end
        },
    }

    self.last_focus = TheFrontEnd:GetFocusWidget()
    TheFrontEnd:PushScreen(PopupDialogScreen(STRINGS.UI.SERVERCREATIONSCREEN.DELETE.." "..STRINGS.UI.SERVERCREATIONSCREEN.SLOT.." "..slot, STRINGS.UI.SERVERCREATIONSCREEN.SURE, menu_items ) )
end

function ServerCreationScreen:Create(warnedOffline, warnedDisabledMods, warnedOutOfDateMods)

	local launchingServerPopup = nil

    local function onsaved()
        if TheNet:GetUseLegacyClientHosting() then
            StartNextInstance({reset_action=RESET_ACTION.LOAD_SLOT, save_slot = self.saveslot})

        else
            ShowLoading()
            launchingServerPopup = LaunchingServerPopup({}, 
                function()
                    local start_worked = TheNet:StartClient(DEFAULT_JOIN_IP, 10999, -1, self.server_settings_tab:GetServerData().password)
                    if start_worked then
                        DisableAllDLC()
                    end
                end,
                function()
                    OnNetworkDisconnect("ID_DST_DEDICATED_SERVER_STARTUP_FAILED", false, false)
                    TheSystemService:StopDedicatedServers()
                end)

            TheFrontEnd:PushScreen(launchingServerPopup)
        end
    end

	local function onCreate()
		-- Check that the player has selected a spot
		if self.saveslot < 0 then
			-- If not, look for the first empty one
			local emptySlot = nil
			for k = 1, NUM_DST_SAVE_SLOTS do
				if SaveGameIndex:IsSlotEmpty(k) then
					emptySlot = k
					break
				end
			end

			-- If we found an empty slot, make that our save slot and call Create() again
			if emptySlot then
				self.saveslot = emptySlot
				self:Create()
			else -- Otherwise, show dialog informing that they must either load a game or delete a game
                self.last_focus = TheFrontEnd:GetFocusWidget()
				local popup = PopupDialogScreen(STRINGS.UI.SERVERCREATIONSCREEN.FULLSLOTSTITLE, STRINGS.UI.SERVERCREATIONSCREEN.FULLSLOTSBODY,
					{
						{text=STRINGS.UI.SERVERCREATIONSCREEN.OK, cb = function()
							TheFrontEnd:PopScreen() 
						end},
					})
				TheFrontEnd:PushScreen( popup )
			end
		else
            self.server_settings_tab:SetEditingTextboxes(false)

            local serverdata = self.server_settings_tab:GetServerData()
            local worldoptions = self.world_tab:CollectOptions()

            local world1datastring = ""
            if worldoptions[1] ~= nil then
                local world1data = deepcopy(worldoptions[1].tweak)
                world1data.preset = worldoptions[1].actualpreset
                world1data.override_enabled = true
                world1datastring = worldoptions[1] and DataDumper(world1data, nil, false) or ""
            end

            local world2datastring = ""
            if worldoptions[2] ~= nil then
                local world2data = deepcopy(worldoptions[2].tweak)
                world2data.preset = worldoptions[2].actualpreset
                world2data.override_enabled = true
                world2datastring = worldoptions[2] and DataDumper(world2data, nil, false) or ""
            end

            --[[ Legacy: Starting a "client" server
            TheNet:SetDefaultServerIntention(serverdata.intention)
            TheNet:SetDefaultServerName(serverdata.name)
            TheNet:SetDefaultServerPassword(serverdata.password)
            TheNet:SetDefaultServerDescription(serverdata.description)
            TheNet:SetDefaultGameMode(serverdata.game_mode)
            TheNet:SetDefaultMaxPlayers(serverdata.max_players)
            TheNet:SetDefaultPvpSetting(serverdata.pvp)
            TheNet:SetDefaultFriendsOnlyServer(serverdata.privacy_type == PRIVACY_TYPE.FRIENDS)
            TheNet:SetDefaultLANOnlyServer(serverdata.privacy_type == PRIVACY_TYPE.LOCAL)
            if serverdata.privacy_type == PRIVACY_TYPE.CLAN then
                TheNet:SetDefaultClanInfo(serverdata.clan.id, serverdata.clan.only, serverdata.clan.admin)
            else
                TheNet:SetDefaultClanInfo("0", false, false)
            end
            --]]

            -- Apply the mods
            self.mods_tab:Apply()

            -- Fill serverInfo object
            local cluster_info = {}

            local mod_data = DataDumper(SaveGameIndex:GetEnabledMods(self.saveslot), nil, false)
            --print("V v v v v v v v v v v v v v v v")
            --print(mod_data)
            --print("^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^")
            cluster_info.mods_config                             = mod_data
            cluster_info.world1gen                               = world1datastring
            cluster_info.world2gen                               = world2datastring
            cluster_info.friends_only                            = serverdata.privacy_type == PRIVACY_TYPE.FRIENDS

            cluster_info.settings                                = {}
            cluster_info.settings.NETWORK                        = {}
            cluster_info.settings.NETWORK.cluster_name           = serverdata.name
            cluster_info.settings.NETWORK.cluster_password       = serverdata.password
            cluster_info.settings.NETWORK.cluster_description    = serverdata.description
            cluster_info.settings.NETWORK.lan_only_cluster       = tostring(serverdata.privacy_type == PRIVACY_TYPE.LOCAL)
			cluster_info.settings.NETWORK.server_intention       = serverdata.intention
            cluster_info.settings.NETWORK.offline_server         = tostring(not serverdata.online_mode)

            cluster_info.settings.GAMEPLAY                       = {}
            cluster_info.settings.GAMEPLAY.game_mode             = serverdata.game_mode
            cluster_info.settings.GAMEPLAY.pvp                   = tostring(serverdata.pvp)
            cluster_info.settings.GAMEPLAY.max_players           = tostring(serverdata.max_players)

            if serverdata.privacy_type == PRIVACY_TYPE.CLAN then
                cluster_info.settings.STEAM                      = {}
                cluster_info.settings.STEAM.steam_group_only     = tostring(serverdata.clan.only)
                cluster_info.settings.STEAM.steam_group_id       = tostring(serverdata.clan.id)
                cluster_info.settings.STEAM.steam_group_admins   = tostring(serverdata.clan.admin)
            end

            -- Collect the tags we want and set the tags string now that we have our mods enabled
            TheNet:SetServerTags(BuildTagsStringHosting(self))

            if SaveGameIndex:IsSlotEmpty(self.saveslot) then
                SaveGameIndex:StartSurvivalMode(self.saveslot, worldoptions, serverdata, onsaved)
                self:RefreshNavButtons()
                self:OnClickSlot(self.saveslot)
            else
                SaveGameIndex:UpdateServerData(self.saveslot, serverdata, onsaved)
            end


            --[[ Legacy: Starting a "client" server
            local start_in_online_mode = serverdata.online_mode
            if TheFrontEnd:GetIsOfflineMode() then
                start_in_online_mode = false
            end
            local server_started = TheNet:StartServer( start_in_online_mode )
            --]]

            self:Disable()

            if not TheSystemService:StartDedicatedServers(self.saveslot, worldoptions[2] ~= nil, cluster_info) then
                if launchingServerPopup ~= nil then
                    launchingServerPopup:SetErrorStartingServers()
                end
                self:Enable()
            end
        end
    end

    if not self:ValidateSettings() then
        -- popups are handled inside validate
        return
    end

    -- Build the list of mods that are newly disabled for this slot
    local disabledmods = {}
    if not warnedDisabledMods then
        disabledmods = self:CheckForDisabledMods()
    end

    -- Build the lost of mods that are enabled and also out of date
    local outofdatemods = {}
    if not warnedOutOfDateMods then
        outofdatemods = self.mods_tab:GetOutOfDateEnabledMods()
    end

    -- Warn if they're starting an offline game that it will always be offline
    if warnedOffline ~= true and not self.server_settings_tab:GetOnlineMode() then
        local offline_mode_body = ""
        if not SaveGameIndex:IsSlotEmpty(self.saveslot) then
            offline_mode_body = STRINGS.UI.SERVERCREATIONSCREEN.OFFLINEMODEBODYRESUME
        else
            offline_mode_body = STRINGS.UI.SERVERCREATIONSCREEN.OFFLINEMODEBODYCREATE
        end

        local confirm_offline_popup = PopupDialogScreen(STRINGS.UI.SERVERCREATIONSCREEN.OFFLINEMODETITLE, offline_mode_body,
                            {
                                {text=STRINGS.UI.SERVERCREATIONSCREEN.OK, cb = function()
                                    -- If player is okay with offline mode, go ahead
                                    TheFrontEnd:PopScreen()
                                    self:Create(true)
                                end},
                                {text=STRINGS.UI.SERVERCREATIONSCREEN.CANCEL, cb = function()
                                    TheFrontEnd:PopScreen() 
                                end}
                            })
        self.last_focus = TheFrontEnd:GetFocusWidget()
        TheFrontEnd:PushScreen(confirm_offline_popup)

    -- Can't start an online game if we're offline
    elseif self.server_settings_tab:GetOnlineMode() and (not TheNet:IsOnlineMode() or TheFrontEnd:GetIsOfflineMode()) then
        local online_only_popup = PopupDialogScreen(STRINGS.UI.SERVERCREATIONSCREEN.ONLINEONYTITLE, STRINGS.UI.SERVERCREATIONSCREEN.ONLINEONLYBODY,
                            {
                                {text=STRINGS.UI.SERVERCREATIONSCREEN.OK, cb = function()
                                    TheFrontEnd:PopScreen() 
                                end}
                            })
        self.last_focus = TheFrontEnd:GetFocusWidget()
        TheFrontEnd:PushScreen(online_only_popup)

    -- Warn if starting a server with mods disabled that were previously enabled on that server
    elseif warnedDisabledMods ~= true and #disabledmods > 0 then
        local modnames = {}
        for i,v in ipairs(disabledmods) do
            table.insert(modnames, KnownModIndex:GetModFancyName(v) or v)
        end

        self.last_focus = TheFrontEnd:GetFocusWidget()
        TheFrontEnd:PushScreen(TextListPopupDialogScreen(STRINGS.UI.SERVERCREATIONSCREEN.MODSDISABLEDWARNINGTITLE,
                            modnames,
                            STRINGS.UI.SERVERCREATIONSCREEN.MODSDISABLEDWARNINGBODY, 
                            {
                                {text=STRINGS.UI.SERVERCREATIONSCREEN.CONTINUE, 
                                cb = function()
                                    TheFrontEnd:PopScreen()
                                    self:Create(true, true)
                                end,
                                controller_control=CONTROL_ACCEPT},
                                {text=STRINGS.UI.SERVERCREATIONSCREEN.CANCEL,
                                cb = function()
                                    TheFrontEnd:PopScreen()
                                end,
                                controller_control=CONTROL_CANCEL}
                            }))

    -- Warn if starting a server with mods enabled that are currently out of date
    elseif warnedOutOfDateMods ~= true and #outofdatemods > 0 then
        local modnames = {}
        for i,v in ipairs(outofdatemods) do
            table.insert(modnames, KnownModIndex:GetModFancyName(v) or v)
        end

        self.last_focus = TheFrontEnd:GetFocusWidget()
        local warning = TextListPopupDialogScreen(STRINGS.UI.SERVERCREATIONSCREEN.MODSOUTOFDATEWARNINGTITLE,
                            modnames,
                            STRINGS.UI.SERVERCREATIONSCREEN.MODSOUTOFDATEWARNINGBODY,
                            {
                                {text=STRINGS.UI.SERVERCREATIONSCREEN.CONTINUE,
                                cb = function()
                                    TheFrontEnd:PopScreen()
                                    self:Create(true, true, true)
                                end,
                                controller_control=CONTROL_ACCEPT},
                                {text=STRINGS.UI.MODSSCREEN.UPDATEALL,
                                cb = function()
                                    TheFrontEnd:PopScreen()
                                    self.mods_tab:UpdateAllButton(true)
                                    self:SetTab("mods")
                                end,
                                controller_control=CONTROL_MENU_MISC_2},
                                {text=STRINGS.UI.SERVERCREATIONSCREEN.CANCEL,
                                cb = function()
                                    TheFrontEnd:PopScreen()
                                end,
                                controller_control=CONTROL_CANCEL}
                            },
                            165)
        if warning.menu then
            for i,v in ipairs(warning.menu.items) do
                v.image:SetScale(.52, .7)
            end
            warning.menu:SetPosition(86 + -(200*(#warning.menu.items-1))/2, -203, 0) 
        end
        TheFrontEnd:PushScreen(warning)

    -- We passed all our checks, go ahead and create
    else
        onCreate()
    end
end

function ServerCreationScreen:ValidateSettings()
    -- Check if our season settings are valid (i.e. at least one season has a duration)
    self.last_focus = TheFrontEnd:GetFocusWidget()
    if not self.world_tab:VerifyValidSeasonSettings() then
        TheFrontEnd:PushScreen(PopupDialogScreen(STRINGS.UI.CUSTOMIZATIONSCREEN.INVALIDSEASONCOMBO_TITLE, STRINGS.UI.CUSTOMIZATIONSCREEN.INVALIDSEASONCOMBO_BODY,
                    {{text=STRINGS.UI.CUSTOMIZATIONSCREEN.OKAY, cb = function() TheFrontEnd:PopScreen() self:SetTab("world") end}}))
        return false
    elseif not self.server_settings_tab:VerifyValidServerName() then
        self.last_focus = TheFrontEnd:GetFocusWidget()
        TheFrontEnd:PushScreen(PopupDialogScreen(STRINGS.UI.SERVERCREATIONSCREEN.INVALIDSERVERNAME_TITLE, STRINGS.UI.SERVERCREATIONSCREEN.INVALIDSERVERNAME_BODY,
                    {{text=STRINGS.UI.CUSTOMIZATIONSCREEN.OKAY, cb = function() TheFrontEnd:PopScreen() self:SetTab("settings") end}}))
        return false
    elseif not self.server_settings_tab:VerifyValidClanSettings() then
        self.last_focus = TheFrontEnd:GetFocusWidget()
        TheFrontEnd:PushScreen(PopupDialogScreen(STRINGS.UI.SERVERCREATIONSCREEN.INVALIDCLANSETTINGS_TITLE, STRINGS.UI.SERVERCREATIONSCREEN.INVALIDCLANSETTINGS_BODY,
                    {{text=STRINGS.UI.CUSTOMIZATIONSCREEN.OKAY, cb = function() TheFrontEnd:PopScreen() self:SetTab("settings") end}}))
        return false
    elseif not self.server_settings_tab:VerifyValidServerIntention() then
        self.last_focus = TheFrontEnd:GetFocusWidget()
        TheFrontEnd:PushScreen(PopupDialogScreen(STRINGS.UI.SERVERCREATIONSCREEN.INVALIDINTENTIONSETTINGS_TITLE, STRINGS.UI.SERVERCREATIONSCREEN.INVALIDINTENTIONSETTINGS_BODY,
                    {{text=STRINGS.UI.CUSTOMIZATIONSCREEN.OKAY, cb = function() TheFrontEnd:PopScreen() self:SetTab("settings") end}}))
        return false
    end

    return true
end

function ServerCreationScreen:CheckForDisabledMods()

    local function isModEnabled(mod, enabledmods)
        for i,v in pairs(enabledmods) do
            if mod == v then
                return true
            end
        end
        return false
    end

    local disabled = {}

    local savedmods = SaveGameIndex:GetSlotMods(self.saveslot)
    local currentlyenabledmods = ModManager:GetEnabledServerModNames()

    for i,v in pairs(savedmods) do
        if not isModEnabled(i, currentlyenabledmods) then
            table.insert(disabled, i)
        end
    end

    return disabled
end

function ServerCreationScreen:MakeDirty()
    self.dirty = true
end

function ServerCreationScreen:MakeClean()
    self.dirty = false
end

function ServerCreationScreen:IsDirty()
    return self.dirty
end

function ServerCreationScreen:Cancel()
    if self:IsDirty() then
        TheFrontEnd:PushScreen(
            PopupDialogScreen( STRINGS.UI.SERVERCREATIONSCREEN.CANCEL_TITLE, STRINGS.UI.SERVERCREATIONSCREEN.CANCEL_BODY,
              { 
                { 
                    text = STRINGS.UI.SERVERCREATIONSCREEN.OK, 
                    cb = function()
                        self:MakeClean()
                        self:Disable()
                        self.server_settings_tab:SetEditingTextboxes(false)
                        TheFrontEnd:Fade(FADE_OUT, SCREEN_FADE_TIME, function()
                            self.mods_tab:Cancel()
                            TheFrontEnd:PopScreen()
                            TheFrontEnd:PopScreen()
                            TheFrontEnd:Fade(FADE_IN, SCREEN_FADE_TIME)
                        end)
                    end
                },
                
                { 
                    text = STRINGS.UI.SERVERCREATIONSCREEN.CANCEL, 
                    cb = function()
                        TheFrontEnd:PopScreen()                 
                    end
                }
              }
            )
        )       
    else
        self:Disable()
        self.server_settings_tab:SetEditingTextboxes(false)
        TheFrontEnd:Fade(FADE_OUT, SCREEN_FADE_TIME, function()
            self.mods_tab:Cancel()
            TheFrontEnd:PopScreen()
            TheFrontEnd:Fade(FADE_IN, SCREEN_FADE_TIME)
        end)
    end
end

function ServerCreationScreen:OnControl(control, down)
    if ServerCreationScreen._base.OnControl(self, control, down) then return true end

    if not down then
        if control == CONTROL_CANCEL then 
            self:Cancel()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        else
            if control == CONTROL_OPEN_CRAFTING then
                self:SetTab(nil, -1)
                TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
            elseif control == CONTROL_OPEN_INVENTORY then
                self:SetTab(nil, 1)
                TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
            elseif self.saveslot < 0 or SaveGameIndex:IsSlotEmpty(self.saveslot) then
                if control == CONTROL_PAUSE and TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse then
                    self:Create()
                    TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
                else
                    return false
                end
            else
                if control == CONTROL_MAP and TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse then
                    self:DeleteSlot(self.saveslot)
                    TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
                elseif control == CONTROL_PAUSE and TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse then
                    self:Create()
                    TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
                else
                    return false
                end
            end
        end

        return true
    end
end

function ServerCreationScreen:RefreshNavButtons()

    if self.save_slots then
        self.save_slots:Kill()
    end
    
    self.save_slots = self.nav_bar:AddChild(Widget("save_slots"))

    for k = 1, NUM_DST_SAVE_SLOTS do
        local btn = self:MakeSaveSlotButton(k)
        self.save_slots[k] = self.save_slots:AddChild(btn)
    end

    self:DoFocusHookUps()
end

function ServerCreationScreen:MakeSaveSlotButton(slotnum)
    local isempty = SaveGameIndex:IsSlotEmpty(slotnum)
    local isnoname = false
    local slotName
    if isempty then
        slotName = STRINGS.UI.SERVERCREATIONSCREEN.NEWGAME
    else
        slotName = SaveGameIndex:GetSlotServerData(slotnum).name or ""
        if #slotName <= 0 then
            slotName = STRINGS.UI.SERVERCREATIONSCREEN.NONAMEGAME
            isnoname = true
        end
    end

    local btn = TEMPLATES.NavBarButton((1 - slotnum) * 47 - 10, slotName, function() self:OnClickSlot(slotnum) end, not (isempty or isnoname))
    btn.slot = slotnum

    -- SaveGameIndex:LoadSlotCharacter is not cheap! Use it in FE only.
    -- V2C: This comment is here as a warning to future copy&pasters - __-"
    local character = SaveGameIndex:LoadSlotCharacter(slotnum) or ""
    local atlas = "images/saveslot_portraits"
    if not table.contains(DST_CHARACTERLIST, character) then
        if table.contains(MODCHARACTERLIST, character) then
            atlas = atlas.."/"..character
        else
            character = #character > 0 and "mod" or "unknown"
        end
    end
    atlas = atlas..".xml"

    btn.character_atlas = atlas
    btn.character = character
    btn.isempty = isempty

    return btn
end

function ServerCreationScreen:OnClickSlot(slotnum, goToSettings)
    local lastslot = self.saveslot
    self.saveslot = slotnum
    for i,v in ipairs(self.save_slots) do
        if v.slot == slotnum then
            v:Select()
        else
            v:Unselect()
        end
    end

    self:UpdateTabs(slotnum, lastslot)

    self:UpdateTitle(slotnum)

    if goToSettings then
        self:SetTab("settings")
    end
end

function ServerCreationScreen:MakeSettingsTab()
    self.server_settings_tab = self.detail_panel:AddChild(ServerSettingsTab({}, self))
    self.server_settings_tab:SetPosition(-30,-80)
end

function ServerCreationScreen:MakeWorldTab()
    self.world_tab = self.detail_panel:AddChild(CustomizationTab(self))
    self.world_tab:SetPosition(-30,-80)
end

function ServerCreationScreen:MakeModsTab()
    self.mods_tab = self.detail_panel:AddChild(ModsTab(self))
    self.top_mods_panel = self.detail_panel_frame_parent:AddChild(TopModsPanel(self))
    self.top_mods_panel:SetPosition(300,-30)
    self.top_mods_panel:MoveToBack()
    self.top_mods_panel:Hide()
    self.top_mods_panel:SetModsTab(self.mods_tab)
    self.mods_tab:SetTopModsPanel(self.top_mods_panel)

    self.mods_tab:SetPosition(-30,-80)
end

function ServerCreationScreen:MakeSnapshotTab()
    local function cb()
        self:RefreshNavButtons()
        self:OnClickSlot(self.saveslot)
    end

    self.snapshot_tab = self.detail_panel:AddChild(SnapshotTab(cb))
    self.snapshot_tab:SetPosition(-30,-80)
end

function ServerCreationScreen:MakeBansTab()
    self.bans_tab = self.detail_panel:AddChild(BanTab(self))
    self.bans_tab:SetPosition(-30,-80)
end

local function MakeImgButton(parent, xPos, yPos, text, onclick, style)
    if not parent or not xPos or not yPos or not text or not onclick or not style then return end

    local btn
    if style == "create" then
        btn = parent:AddChild(ImageButton())
        btn.image:SetScale(.7)
        btn:SetText(text)
        btn:SetFont(NEWFONT)
        btn:SetDisabledFont(NEWFONT)
    elseif style == "delete" then
        btn = parent:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "delete.tex", text, true, false, onclick))
    end
    
    btn:SetPosition(xPos, yPos)
    btn:SetOnClick(onclick)

    return btn
end

function ServerCreationScreen:MakeButtons()
    --720 total space, divided by 4 for 180 btween each button (might want to turn into a calculation for fiddling/spacing)
    local tab_height = 232
    self.settings_button = self.detail_panel:AddChild(TEMPLATES.TabButton(-502, tab_height, STRINGS.UI.SERVERCREATIONSCREEN.SERVERSETTINGS, function() self:SetTab("settings") end, "small"))
    self.configure_world_button = self.detail_panel:AddChild(TEMPLATES.TabButton(-323, tab_height, STRINGS.UI.SERVERCREATIONSCREEN.WORLD, function() self:SetTab("world") end, "small"))
    self.mods_button = self.detail_panel:AddChild(TEMPLATES.TabButton(-144, tab_height, STRINGS.UI.MAINSCREEN.MODS, function() self:SetTab("mods") end, "small"))
    self.snapshot_button = self.detail_panel:AddChild(TEMPLATES.TabButton(35, tab_height, STRINGS.UI.SERVERCREATIONSCREEN.SNAPSHOTS, function() self:SetTab("snapshot") end, "small"))
    self.ban_admin_button = self.detail_panel:AddChild(TEMPLATES.TabButton(214, tab_height, STRINGS.UI.SERVERCREATIONSCREEN.BANS, function() self:SetTab("bans") end, "small"))

    self.settings_button.image:SetPosition(0,-1)
    self.configure_world_button.image:SetPosition(0,-1)
    self.mods_button.image:SetPosition(0,-1)
    self.snapshot_button.image:SetPosition(0,-1)
    self.ban_admin_button.image:SetPosition(0,-1)

    self.settings_button.image:SetScale(.83, .92)
    self.configure_world_button.image:SetScale(.83, .92)
    self.mods_button.image:SetScale(.83, .92)
    self.snapshot_button.image:SetScale(.83, .92)
    self.ban_admin_button.image:SetScale(.83, .92)

    self.settings_button.text:SetPosition(2,8)
    self.configure_world_button.text:SetPosition(2,8)
    self.mods_button.text:SetPosition(2,8)
    self.snapshot_button.text:SetPosition(2,8)
    self.ban_admin_button.text:SetPosition(2,8)

    self.cancel_button = self.root:AddChild(TEMPLATES.BackButton(function() self:Cancel() end))
    self.create_button = MakeImgButton(self.detail_panel, 170, -RESOLUTION_Y*.5 + BACK_BUTTON_Y - 7, STRINGS.UI.SERVERCREATIONSCREEN.CREATE, function() self:Create() end, "create")
    self.create_button.text:SetPosition(-3,0)
    self.delete_button = MakeImgButton(self.detail_panel, 240, 170, STRINGS.UI.SERVERCREATIONSCREEN.DELETE_SLOT_BUTTON, function() self:DeleteSlot(self.saveslot) end, "delete")
    if TheInput:ControllerAttached() then
        self.cancel_button:Hide()
        self.create_button:Hide()
        self.delete_button:Hide()
    end
end

function ServerCreationScreen:DoFocusHookUps()
    if self.save_slots[1] then
        if self.server_settings_tab then self.server_settings_tab:SetFocusChangeDir(MOVE_LEFT, self.save_slots[1]) end
        if self.world_tab then self.world_tab:SetFocusChangeDir(MOVE_LEFT, self.save_slots[1]) end
        if self.mods_tab then self.mods_tab:SetFocusChangeDir(MOVE_LEFT, self.save_slots[1]) end
        if self.snapshot_tab then self.snapshot_tab:SetFocusChangeDir(MOVE_LEFT, self.save_slots[1]) end
        if self.bans_tab then self.bans_tab:SetFocusChangeDir(MOVE_LEFT, self.save_slots[1]) end
    end

    for i,v in ipairs(self.save_slots) do
        if self.save_slots[i-1] then
            self.save_slots[i]:SetFocusChangeDir(MOVE_UP, self.save_slots[i-1])
        end

        if self.save_slots[i+1] then
            self.save_slots[i]:SetFocusChangeDir(MOVE_DOWN, self.save_slots[i+1])
        end

        self.save_slots[i]:SetFocusChangeDir(MOVE_RIGHT, function()
            if self.active_tab == "settings" then
                return self.server_settings_tab
            elseif self.active_tab == "world" then
                return (self.world_tab.presetspinner:IsVisible() and self.world_tab.presetspinner)
                    or (self.world_tab.addmultilevel:IsEnabled() and self.world_tab.addmultilevel)
                    or self.world_tab.level1tab
            elseif self.active_tab == "mods" then
                return self.mods_tab.servermodsbutton
            elseif self.active_tab == "snapshot" then
                return self.snapshot_tab.snapshot_scroll_list
            elseif self.active_tab == "bans" then
                return self.bans_tab.player_scroll_list
            end 
        end)
    end

    self.save_slots[#self.save_slots]:SetFocusChangeDir(MOVE_DOWN, self.cancel_button)
end

function ServerCreationScreen:SetTab(tabName, direction)
    if not tabName and not direction then return end

    self:HideAllTabs(tabName)

    if tabName then
        if tabName == "settings" then
            self:ShowServerSettingsTab()
        elseif tabName == "world" then
            self:ShowWorldTab()
        elseif tabName == "mods" then
            self:ShowModsTab()
        elseif tabName == "snapshot" then
            self:ShowSnapshotTab()
        elseif tabName == "bans" then
            self:ShowBanTab()
        end
    elseif direction then
        if direction < 0 then --left
            if self.active_tab == "settings" then
                self:ShowBanTab()
            elseif self.active_tab == "world" then
                self:ShowServerSettingsTab()
            elseif self.active_tab == "mods" then
                self:ShowWorldTab()
            elseif self.active_tab == "snapshot" then
                self:ShowModsTab()
            elseif self.active_tab == "bans" then
                self:ShowSnapshotTab()                
            end
        elseif direction > 0 then --right
            if self.active_tab == "settings" then
                self:ShowWorldTab()
            elseif self.active_tab == "world" then
                self:ShowModsTab()
            elseif self.active_tab == "mods" then
                self:ShowSnapshotTab()
            elseif self.active_tab == "snapshot" then
                self:ShowBanTab()
            elseif self.active_tab == "bans" then
                self:ShowServerSettingsTab()
            end
        end
    end
end

function ServerCreationScreen:HideAllTabs(tab)
    --hide all the parent widgets and enable all tab buttons
    self.server_settings_tab:Hide()
    self.world_tab:Hide()
    self.mods_tab:Hide()
    self.snapshot_tab:Hide()
    self.bans_tab:Hide()

    if tab ~= "mods" then
        self.top_mods_panel:HidePanel()
    end

    self.settings_button:Enable()
    self.configure_world_button:Enable()
    self.mods_button:Enable()
    self.snapshot_button:Enable()
    self.ban_admin_button:Enable()
end

function ServerCreationScreen:IsTabPageFocused()
    if not TheInput:ControllerAttached() or TheFrontEnd.tracking_mouse then
        return false
    end

    local slotButtonHasFocus = false
    for i,v in ipairs(self.save_slots) do
        if v.focus then
            slotButtonHasFocus = true
            break
        end
    end

    return not slotButtonHasFocus
end

function ServerCreationScreen:ShowServerSettingsTab(forceFocus)
    self.settings_button:Disable()
    self.active_tab = "settings"
    self.server_settings_tab:Show()
    if forceFocus or self:IsTabPageFocused() then
        self.server_settings_tab:SetFocus()
    end
end

function ServerCreationScreen:ShowWorldTab(forceFocus)
    self.configure_world_button:Disable()
    self.active_tab = "world"
    self.world_tab:Show()
    if forceFocus or self:IsTabPageFocused() then
        self.world_tab:SetFocus()
    end
end

function ServerCreationScreen:ShowModsTab(forceFocus)
    self.mods_button:Disable()
    self.active_tab = "mods"
    self.mods_tab:Show()
    self.top_mods_panel:ShowPanel()
    if forceFocus or self:IsTabPageFocused() then
        self.mods_tab:SetFocus()
    end
end

function ServerCreationScreen:ShowSnapshotTab(forceFocus)
    self.snapshot_button:Disable()
    self.active_tab = "snapshot"
    self.snapshot_tab:Show()
    if forceFocus or self:IsTabPageFocused() then
        self.snapshot_tab:SetFocus()
    end
end

function ServerCreationScreen:ShowBanTab(forceFocus)
    self.ban_admin_button:Disable()
    self.active_tab = "bans"
    self.bans_tab:Show()
    if forceFocus or self:IsTabPageFocused() then
        self.bans_tab:SetFocus()
    end
end

function ServerCreationScreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}

    table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)

    if self.saveslot > 0 or not SaveGameIndex:IsSlotEmpty(self.saveslot) then
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MAP) .. " " .. STRINGS.UI.SERVERCREATIONSCREEN.DELETE_SLOT)
    end

    table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_OPEN_CRAFTING).."/"..TheInput:GetLocalizedControl(controller_id, CONTROL_OPEN_INVENTORY).. " " .. STRINGS.UI.HELP.CHANGE_TAB)

    table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_PAUSE).." "..(self.delete_button:IsEnabled() and STRINGS.UI.SERVERCREATIONSCREEN.RESUME or STRINGS.UI.SERVERCREATIONSCREEN.CREATE))

    return table.concat(t, "  ")
end

return ServerCreationScreen
