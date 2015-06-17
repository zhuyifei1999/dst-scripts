local Screen = require "widgets/screen"
local AnimButton = require "widgets/animbutton"
local ImageButton = require "widgets/imagebutton"
local TextButton = require "widgets/textbutton"
local Button = require "widgets/button"
local InputDialogScreen = require "screens/inputdialog"
local BigPopupDialogScreen = require "screens/bigpopupdialog"
local ListCursor = require "widgets/listcursor"

local Text = require "widgets/text"
local Image = require "widgets/image"

local Spinner = require "widgets/spinner"
local NumericSpinner = require "widgets/numericspinner"
local TextEdit = require "widgets/textedit"

local Widget = require "widgets/widget"
local Levels = require "map/levels"

local ScrollableList = require "widgets/scrollablelist"

local ServerCreationScreen = require "screens/servercreationscreen"
local CustomizationScreen = require "screens/customizationscreen"

--local OnlineStatus = require "widgets/onlinestatus"

require("constants")

local listings_per_view = 13
local listings_per_scroll = 10
local list_spacing = 37.5

local filters_per_page = 6

local column_offsets_x_pos = -RESOLUTION_X*0.18;
local column_offsets_y_pos = RESOLUTION_Y*0.23;

local column_offsets ={ 
        NAME = -57,  
        DETAILS = 245,  
        PLAYERS = 430,
        PING = 540,        
    }

local dev_color = {80/255, 16/255, 158/255, 1}
local mismatch_color = {130/255, 19/255, 19/255, 1}

local font_size = 35
if JapaneseOnPS4() then
    font_size = 35 * 0.75;
end

local screen_fade_time = .25

local VALID_CHARS = [[ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:;[]\@!#$%&()'*+-/=?^_{|}~"]]
local STRING_MAX_LENGTH = 254 -- http://tools.ietf.org/html/rfc5321#section-4.5.3.1

local ServerListingScreen = Class(Screen, function(self, filters, cb, customoptions, slotdata, offlineMode, session_mapping)
    Widget._ctor(self, "ServerListingScreen")

    self.bg = self:AddChild(Image("images/bg_plain.xml", "bg.tex"))
    TintBackground(self.bg)

    -- Query all data related to user sessions
    self.session_mapping = session_mapping

    self.cb = cb
    self.customoptions = customoptions
    self.slotdata = slotdata
    self.offlinemode = offlineMode

    self.tickperiod = 0.5
    self.task = nil

    self.unjoinable_servers = 0

    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg:SetVAnchor(ANCHOR_MIDDLE)
    self.bg:SetHAnchor(ANCHOR_MIDDLE)
    self.bg:SetScaleMode(SCALEMODE_FILLSCREEN)
    
    self.scaleroot = self:AddChild(Widget("scaleroot"))
    self.scaleroot:SetVAnchor(ANCHOR_MIDDLE)
    self.scaleroot:SetHAnchor(ANCHOR_MIDDLE)
    self.scaleroot:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.root = self.scaleroot:AddChild(Widget("root"))
    self.root:SetScale(.9)
    self.root:SetPosition(0,10,0)

    self.online = true

    local left_col = -RESOLUTION_X*.05 - 340
    local right_col = RESOLUTION_X*.40 - 260

    --add the controls panel	
    self.server_list = self.root:AddChild(Widget("server_list"))
    self.server_list:SetPosition(right_col,0,0)
    -- self.server_listbg = self.server_list:AddChild(Image("images/fepanels.xml", "panel_controls.tex"))
    self.server_listgrid = self.server_list:AddChild(Image("images/serverbrowser.xml", "browser_grid.tex"))
    self.server_listgrid:SetPosition(30,35)
   
    self.server_list_titles = self.server_list:AddChild(Widget("server_list_titles"))
    self.server_list_titles:SetPosition(column_offsets_x_pos, column_offsets_y_pos, 0)

    self:MakeColumnHeaders()

    self.sort_ascending = nil
    self.sort_column = nil
    self:SetSort("PING")

    self.selected_index_actual = -1
    self.selected_server = nil
    self.selected_row = -1
    self.list_widgets = {}
    self.view_offset = 0
    self.viewed_servers = {}
    self.servers = {}
    self.filters = {}
    self.sessions = {}

    self.server_list_rows = self.server_list:AddChild(Widget("server_list_rows"))
    self.server_list_rows:SetPosition(column_offsets_x_pos, -RESOLUTION_Y*0.075, 0)
    -- self.server_list_rows:SetVAlign(ANCHOR_MIDDLE)
    self:MakeServerListWidgets()

    self:MakeDetailPanel(left_col)

    self:MakeMenuButtons(left_col, right_col)

    self:MakeFiltersPanel(filters)
--[[
    self.onlinestatus = self.root:AddChild(OnlineStatus())
    self.onlinestatus:SetHAnchor(ANCHOR_RIGHT)
    self.onlinestatus:SetVAnchor(ANCHOR_BOTTOM)
]]    
    self:UpdateServerInformation(false)
    self:ToggleShowFilters()

    self:SearchForServers()
    self:RefreshView(false)
end)

function ServerListingScreen:UpdateServerInformation( show )
	if show then
        if self.filters_shown then
            self:ToggleShowFilters(true)
        end
        self.details_servername:Show()
        self.details_serverdesc:Show()
        if self.selected_server ~= nil then
            -- self.game_mode_description:Show()
    		-- self.checkbox_has_password:Show()
    		-- self.has_password_description:Show()
    		-- self.checkbox_dedicated_server:Show()
    		-- self.dedicated_server_description:Show()
    		-- self.checkbox_pvp:Show()
    		-- self.pvp_description:Show()
    		-- self.viewmods_button:Show()
            -- self.viewtags_button:Show()
            -- self.viewworld_button:Show()
            self.detail_scroll_list:Show()
        end
	else
        if self.filters_shown then
		    self.details_servername:Hide()
            self.details_serverdesc:Hide()
        end
        -- self.game_mode_description:Hide()
		-- self.checkbox_has_password:Hide()
		-- self.has_password_description:Hide()
		-- self.checkbox_dedicated_server:Hide()
		-- self.dedicated_server_description:Hide()
		-- self.checkbox_pvp:Hide()
		-- self.pvp_description:Hide()
		-- self.viewmods_button:Hide()
        -- self.viewtags_button:Hide()
        -- self.viewworld_button:Hide()
        self.detail_scroll_list:Hide()
	end
end

function ServerListingScreen:ToggleShowFilters(forcehide)
    if not self.filters_shown and not forcehide then
        self.filters_shown = true
        self:UpdateServerInformation( false )
        self.filters_button.image:Hide()
        self.filters_button:Disable()
        self.filters_reset_button:Show()
        self.details_button:Enable()
        self.details_button.image:Show()
        self.server_detail_panelbg2:SetTexture("images/serverbrowser.xml", "server_detail_left_tab.tex")
        self.filters_scroll_list:Show()
        self.detail_scroll_list:Hide()
    else
        self.filters_scroll_list:Hide()
        self.detail_scroll_list:Show()
        self.filters_shown = false
        self.filters_button:Enable()
        self.filters_button.image:Show()
        self.filters_reset_button:Hide()
        self.details_button.image:Hide()
        self.details_button:Disable()
        self.server_detail_panelbg2:SetTexture("images/serverbrowser.xml", "server_detail_right_tab.tex")
        self:UpdateServerInformation( true )
    end
end

function ServerListingScreen:OnBecomeActive()
    ServerListingScreen._base.OnBecomeActive(self)
    self:Enable()
    
    self:StartPeriodicRefreshTask()
end

function ServerListingScreen:OnBecomeInactive()
    ServerListingScreen._base.OnBecomeInactive(self)

    self:StopPeriodicRefreshTask()
end

function ServerListingScreen:OnDestroy()
	self._base.OnDestroy(self)
end
local function tchelper(first, rest)
  return first:upper()..rest:lower()
end

function ServerListingScreen:Join()
	if self.selected_server ~= nil then
        local filters = {}
        for i,v in pairs(self.filters) do
            if v.spinner then 
                table.insert(filters, {name=v.name, data=v.spinner:GetSelectedData()})
            elseif v.textbox then
                table.insert(filters, {name="search", data=v.textbox:GetString()})
            end
        end
        Profile:SaveFilters(filters)
		JoinServer( self.selected_server )	
	else
		assert(false, "Invalid server selection")
	end
end

function ServerListingScreen:Report()
    local index = self.selected_index_actual
    local guid = self.servers[index] and self.servers[index].guid
    local servname = string.len(self.servers[index].name) > 18 and string.sub(self.servers[index].name,1,18).."..." or self.servers[index].name
    local report_dialog = InputDialogScreen( STRINGS.UI.SERVERLISTINGSCREEN.REPORTREASON.." ("..servname..")", 
                                        {
                                            {
                                                text = STRINGS.UI.SERVERLISTINGSCREEN.CANCEL, 
                                                cb = function()
                                                    TheFrontEnd:PopScreen()
                                                end
                                            },
                                            {
                                                text = STRINGS.UI.SERVERLISTINGSCREEN.OK, 
                                                cb = function()
                                                    TheNet:ReportListing(guid, InputDialogScreen:GetText())
                                                    TheFrontEnd:PopScreen()
                                                end
                                            },
                                        },
                                    true )
    report_dialog.edit_text.OnTextEntered = function()
        TheNet:ReportListing(guid, InputDialogScreen:GetText())
        TheFrontEnd:PopScreen()
    end
    report_dialog:SetValidChars([[ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,[]@!()'*+-/?{}" ]])
    TheFrontEnd:PushScreen(report_dialog)  
    report_dialog.edit_text:OnControl(CONTROL_ACCEPT, false)
end

local function SetChecked( widget, label, checked )
	if checked then
        widget:SetTexture("images/ui.xml", "button_checkbox2.tex")
        widget:SetTint(1,1,1,1)
        label:SetColour(0,0,0,1)
	else
        widget:SetTexture("images/ui.xml", "button_checkbox1.tex")
        widget:SetTint(1,1,1,.6)
        label:SetColour(.4,.4,.4,1)
	end
end

function ServerListingScreen:ViewServerMods()
    if self.selected_server ~= nil and self.selected_server.mods_enabled then
        local mods_list = ""
		if self.selected_server.mods_failed_deserialization then
			mods_list = STRINGS.UI.SERVERLISTINGSCREEN.MODS_HIDDEN_MISMATCH
		else
			local added_mod_name = false
			for k,v in pairs(self.selected_server.mods_description) do
				mods_list = mods_list .. v.modinfo_name .. ", "
				added_mod_name = true
			end
			mods_list = string.sub( mods_list, 1, string.len(mods_list)-2 )
			
			if not added_mod_name then
				mods_list = STRINGS.UI.SERVERLISTINGSCREEN.MODS_HIDDEN_LAN
			end
		end
		
        TheFrontEnd:PushScreen(BigPopupDialogScreen(STRINGS.UI.SERVERLISTINGSCREEN.MODSENABLED, 
                                                    mods_list,
                                                    {{text=STRINGS.UI.SERVERLISTINGSCREEN.OK, cb = function() TheFrontEnd:PopScreen() end}}
                                                    )
        )
    end
end

function ServerListingScreen:ViewServerTags()
    if self.selected_server ~= nil and self.selected_server.tags then            
        TheFrontEnd:PushScreen(BigPopupDialogScreen(STRINGS.UI.SERVERLISTINGSCREEN.TAGSTITLE, 
                                                    self.selected_server.tags,
                                                    {{text=STRINGS.UI.SERVERLISTINGSCREEN.OK, cb = function() TheFrontEnd:PopScreen() end}}
                                                    )
        )
    end
end

function ServerListingScreen:ViewServerWorld()
    if self.selected_server ~= nil and self.selected_server.data then
        local success, data = RunInSandboxSafe(self.selected_server.data)
        if success and data then
            TheFrontEnd:Fade(false, screen_fade_time, function()
                TheFrontEnd:PushScreen(CustomizationScreen(Profile, function() end, data.worldgenoptions, false, false))
                TheFrontEnd:Fade(true, screen_fade_time)
            end)
        end
    end
end

local function CompareTable(table_a, table_b)

  -- Basic validation
  if table_a==table_b then return true end
  
  -- Null check
  if table_a == nil or table_b == nil then return false end

  -- Validate type
  if type(table_a) ~= "table" then return false end
  
  -- Compare meta tables
  local meta_table_a = getmetatable(table_a)
  local meta_table_b = getmetatable(table_b)
  if not CompareTable(meta_table_a,meta_table_b) then return false end

  -- Compare nested tables
  for index,value_a in pairs(table_a) do
    local value_b = table_b[index]
    if not CompareTable(value_a,value_b) then return false end
  end
  for index,value_b in pairs(table_b) do
    local value_a = table_a[index]
    if not CompareTable(value_a,value_b) then return false end
  end
  
  return true  
  
end

function ServerListingScreen:UpdateServerData( selected_index_actual )
    local sel_serv = TheNet:GetServerListingFromActualIndex( selected_index_actual ) 
    if sel_serv and CompareTable(sel_serv, self.selected_server) == false then
        self.selected_server = sel_serv
        self.selected_index_actual = selected_index_actual

        self.details_servername:SetString( self.selected_server.name )
        self.details_serverdesc:SetString( self.selected_server.description )
        
        if self.selected_server.description == "" then
            self.details_servername:SetPosition(-10, RESOLUTION_Y*0.16 - 20, 0)
        else
            self.details_servername:SetPosition(-10, RESOLUTION_Y*0.16 + 10, 0)
        end

        self.game_mode_description.text:SetString( GetGameModeString( self.selected_server.mode ) )
        self.game_mode_description.text:SetHoverText( GetGameModeHoverTextString( self.selected_server.mode ) )

        SetChecked( self.checkbox_dedicated_server, self.dedicated_server_description, self.selected_server.dedicated )
        SetChecked( self.checkbox_pvp, self.pvp_description, self.selected_server.pvp )
        SetChecked( self.checkbox_has_password, self.has_password_description, self.selected_server.has_password )

        if self.selected_server.mods_enabled then
            self.viewmods_button:SetText(STRINGS.UI.SERVERLISTINGSCREEN.VIEWMODS)
            self.viewmods_button:Enable()
        else
            self.viewmods_button:SetText(STRINGS.UI.SERVERLISTINGSCREEN.NOMODS)
            self.viewmods_button:Disable()
        end

        if self.selected_server.tags ~= "" then
            self.viewtags_button:SetText(STRINGS.UI.SERVERLISTINGSCREEN.VIEWTAGS)
            self.viewtags_button:Enable()
        else
            self.viewtags_button:SetText(STRINGS.UI.SERVERLISTINGSCREEN.NOTAGS)
            self.viewtags_button:Disable()
        end

        local seasondesc = self.selected_server.season and STRINGS.UI.SERVERLISTINGSCREEN.SEASONS[string.upper(self.selected_server.season)] or STRINGS.UI.SERVERLISTINGSCREEN.UNKNOWN_SEASON
        self.season_description.text:SetString(seasondesc)


        local success, data = RunInSandboxSafe(self.selected_server.data)
        if success and data then
            if data.worldgenoptions then
                self.viewworld_button:Enable()
            else
                self.viewworld_button:Disable()
            end

            local phasename = ""--data and data.clockphase and STRINGS.UI.SERVERLISTINGSCREEN.PHASES[string.upper(data.clockphase)] or STRINGS.UI.SERVERLISTINGSCREEN.UNKNOWN_PHASE
            local day = data and data.day or STRINGS.UI.SERVERLISTINGSCREEN.UNKNOWN
            self.day_description.text:SetString(phasename..STRINGS.UI.SERVERLISTINGSCREEN.DAYDESC..day)

            local players = data and data.players or nil
            while self.detail_panel_widgets[self.first_player_row] do
                local row = table.remove(self.detail_panel_widgets, self.first_player_row)
                row:KillAllChildren()
                row:Kill()
            end
            if players then
                self.players_header.text:SetString(STRINGS.UI.SERVERLISTINGSCREEN.PLAYERS.." ("..#players..")")
                for i,v in ipairs(players) do
                    local nextPlayer = Widget("player")
                    nextPlayer.avatarbg = nextPlayer:AddChild(Image("images/saveslot_portraits.xml", "background.tex"))
                    local char = v.prefab
                    local atlas = (table.contains(MODCHARACTERLIST, char) and "images/saveslot_portraits/"..char..".xml") or "images/saveslot_portraits.xml"
                    if not table.contains(GetActiveCharacterList(), char) then
                        char = "random" -- Use a question mark if the character isn't currently active
                    end
                    nextPlayer.avatar = nextPlayer:AddChild(Image(atlas, char..".tex"))
                    nextPlayer.avatarbg:SetScale(.3)
                    nextPlayer.avatar:SetScale(.3)
                    nextPlayer.avatarbg:SetPosition(-50,0)
                    nextPlayer.avatar:SetPosition(-50,0)
                    nextPlayer.name = nextPlayer:AddChild(Text(BUTTONFONT, 30))
                    nextPlayer.name:SetString(v.name)
                    nextPlayer.name:SetHAlign(ANCHOR_MIDDLE)
                    nextPlayer.name:SetPosition(-20,0)
                    nextPlayer.name:SetRegionSize(60, 40)
                    nextPlayer.name:SetColour(0,0,0,1)
                    nextPlayer.age = nextPlayer:AddChild(Text(BUTTONFONT, 30))
                    nextPlayer.age:SetString(STRINGS.UI.SERVERLISTINGSCREEN.CHAR_AGE_1..v.playerage..STRINGS.UI.SERVERLISTINGSCREEN.CHAR_AGE_2)
                    nextPlayer.age:SetHAlign(ANCHOR_MIDDLE)
                    nextPlayer.age:SetPosition(30,0)
                    nextPlayer.age:SetRegionSize(60, 40)
                    nextPlayer.age:SetColour(0,0,0,1)

                    table.insert(self.detail_panel_widgets, nextPlayer)
                end
            else
                self.players_header.text:SetString(STRINGS.UI.SERVERLISTINGSCREEN.PLAYERS.." (0)")
            end
            self.detail_scroll_list:SetList(self.detail_panel_widgets, true)
        else
            self.viewworld_button:Disable()
            self.season_description.text:SetString(STRINGS.UI.SERVERLISTINGSCREEN.UNKNOWN_SEASON)
            self.day_description.text:SetString(STRINGS.UI.SERVERLISTINGSCREEN.DAYDESC..STRINGS.UI.SERVERLISTINGSCREEN.UNKNOWN)--STRINGS.UI.SERVERLISTINGSCREEN.UNKNOWN_PHASE..STRINGS.UI.SERVERLISTINGSCREEN.DAYDESC..STRINGS.UI.SERVERLISTINGSCREEN.UNKNOWN)
            while self.detail_panel_widgets[self.first_player_row] do
                local row = table.remove(self.detail_panel_widgets, self.first_player_row)
                row:KillAllChildren()
                row:Kill()
            end
            self.players_header.text:SetString(STRINGS.UI.SERVERLISTINGSCREEN.PLAYERS.." (0)")
            self.detail_scroll_list:SetList(self.detail_panel_widgets, true)
        end

        self.join_button:Enable()
    end
end

function ServerListingScreen:ServerSelected(new_index)
    if new_index and self.viewed_servers and self.viewed_servers[new_index] ~= nil then
		self.selected_index_actual = self.viewed_servers[new_index].actualindex
		if self.selected_row ~= self.viewed_servers[new_index].row then
			self.selected_row = self.viewed_servers[new_index].row
			TheNet:DownloadServerDetails( self.viewed_servers[new_index].row )
		end
        self:UpdateServerData( self.selected_index_actual )
        self:UpdateServerInformation(true)
    else
        self:UpdateServerInformation(false)
        self.selected_server = nil
        self.selected_index_actual = -1
        self.selected_row = -1
        self.details_servername:SetString(STRINGS.UI.SERVERLISTINGSCREEN.NOSERVERSELECTED)
        self.details_serverdesc:SetString("")
        self.join_button:Disable()
    end

    self:GuaranteeSelectedServerHighlighted()
end

function ServerListingScreen:StartPeriodicRefreshTask()
    if self.task then
        self.task:Cancel()
    end
    self.task = self.inst:DoPeriodicTask(self.tickperiod, function() self:RefreshView(false) end) 
end

function ServerListingScreen:StopPeriodicRefreshTask()
	if self.task then
		self.task:Cancel()
		self.task = nil
	end
end

function ServerListingScreen:ClearServerList()
    for i,v in pairs (self.list_widgets) do
        v.NAME:SetString("")
        v.CHAR_ICON_BG:Hide()
        v.CHAR_ICON:Hide()
        v.FRIEND_ICON:Hide()
        v.HAS_PASSWORD_ICON:Hide()
        v.DEDICATED_ICON:Hide()
        v.PVP_ICON:Hide()
        v.MODS_ENABLED_ICON:Hide()
        v.PLAYERS:SetString("")
        v.PING:SetString("")  
    end
    -- Scroll back to the top of the list
    if self.servers_scroll_list.items and #self.servers_scroll_list.items > 0 then
        self.servers_scroll_list:Scroll(-self.servers_scroll_list.view_offset, true) 
    end
end

function ServerListingScreen:SearchForServers()
    self:ServerSelected(nil)
    self.servers = {}
    self.viewed_servers = {}
    self:RefreshView()
    self:ClearServerList()
    local num_servs = #self.servers-self.unjoinable_servers
    if num_servs < 0 then num_servs = 0 end
    self.title:SetString(STRINGS.UI.SERVERLISTINGSCREEN.SERVER_LIST_TITLE.." ("..#self.viewed_servers.." "..STRINGS.UI.SERVERLISTINGSCREEN.OUT_OF.." "..num_servs.." "..STRINGS.UI.SERVERLISTINGSCREEN.SHOWING..")")
    if not self.online then
        self.title:SetString(STRINGS.UI.SERVERLISTINGSCREEN.SERVER_LIST_TITLE.." ("..STRINGS.UI.SERVERLISTINGSCREEN.LAN..")")
    end
    self.servers_scroll_list:SetList(self.viewed_servers)

    self.online = true
    
    for i,v in pairs(self.filters) do
        if v.name == "SHOWLAN" then
            self.online = v.spinner:GetSelectedData() == false
        elseif v.name == "VERSIONCHECK" then
            local version_check = v.spinner:GetSelectedData()
			TheNet:SetCheckVersionOnQuery( version_check )
        end
    end

    if self.online and not self.offlinemode then -- search LAN and online if online
        TheNet:SearchServers()
    else -- otherwise just LAN
        TheNet:SearchLANServers()
    end
    
	self:StartPeriodicRefreshTask()
	self:RefreshView(true)
end

local DOUBLE_CLICK_TIMEOUT = .5

function ServerListingScreen:OnStartClickServerInList(index)
    index = index + self.servers_scroll_list.view_offset
    if self.viewed_servers and self.viewed_servers[index] ~= nil and self.selected_index_actual ~= self.viewed_servers[index].actualindex then
        self.last_server_click_time = nil
    end
    self:ServerSelected(index)
end

function ServerListingScreen:OnFinishClickServerInList(index)
    if self.viewed_servers and self.viewed_servers[index] ~= nil and self.viewed_servers[index].actualindex == self.selected_index_actual then
        -- If we're clicking on the same server as the last click, check for double-click Join
        if self.last_server_click_time and GetTime() - self.last_server_click_time <= DOUBLE_CLICK_TIMEOUT then
            self:Join()
            return
        end
    end
    self.last_server_click_time = GetTime()
end

function ServerListingScreen:RefreshView(skipPoll)

    if TheNet:IsSearchingServers() then
        self.refresh_button:Disable()
        --if self.lan_spinner then self.lan_spinner.spinner:Disable() end
    else
        self.refresh_button:Enable()
        --if self.lan_spinner then self.lan_spinner.spinner:Enable() end
    end
		
    if not skipPoll then
        if TheNet:GetServerListingReadDirty() == false then
            return
        end
	
        local servers = {}
        servers = TheNet:GetServerListings()
        
        self.servers = servers

        self:DoFiltering() -- This also calls DoSorting
    end

	self.servers_scroll_list:RefreshView()
    self:GuaranteeSelectedServerHighlighted()
    self:UpdateServerData( self.selected_index_actual )
end

function ServerListingScreen:MakeServerListWidgets()
    self.list_widgets = {}

    for i=1, listings_per_view do        
        local row = self.server_list_rows:AddChild(Widget("control"))

        local font_size = font_size * .8
        local y_offset = 15

        if i%2 == 1 then
            row.bg = row:AddChild(Image("images/serverbrowser.xml", "greybar.tex"))
            row.bg:SetScale(.93,1)
            row.bg:SetPosition( 248, y_offset+2, 0)
            row.bg:SetTint(1,1,1,.7)
        end

        row.index = -1

        row.cursor = row:AddChild( ListCursor() )
        row.cursor:SetPosition( 256, y_offset+2, 0)
        row.cursor:SetOnDown(  function() self:OnStartClickServerInList(i)  end)
        row.cursor:SetOnClick( function() self:OnFinishClickServerInList(i) end)
        row.cursor:Hide()
        
        row.NAME = row:AddChild(Text(BUTTONFONT, font_size))
        row.NAME:SetHAlign(ANCHOR_MIDDLE)
        row.NAME:SetString("")
        row.NAME:SetPosition( column_offsets.NAME + 98, y_offset, 0 )
        row.NAME:SetRegionSize( 240, 50 )
        row.NAME:SetHAlign( ANCHOR_LEFT ) 
        
        row.DETAILS = row.cursor:AddChild(Widget("detail_icons"))
        row.DETAILS:SetPosition(column_offsets.DETAILS-231, -1, 0)

        row.CHAR_ICON_BG = row.DETAILS:AddChild(Image("images/saveslot_portraits.xml", "background.tex"))
        row.CHAR_ICON_BG:SetScale(.22, .22, 1)    
        row.CHAR_ICON = row.DETAILS:AddChild(Image())
        row.CHAR_ICON:SetScale(.22, .22, 1)
        --#srosen do we want to show the last time this char was played, too?
        row.CHAR_ICON.label = row.DETAILS:AddChild(Text(UIFONT, 23, STRINGS.UI.SERVERLISTINGSCREEN.CHAR_AGE_1.."0"..STRINGS.UI.SERVERLISTINGSCREEN.CHAR_AGE_2)) 
        row.CHAR_ICON.label:SetPosition(-31+3,1+22,0)
        row.CHAR_ICON.label:Hide()
        row.CHAR_ICON.OnGainFocus = function() row.CHAR_ICON.label:Show() end
        row.CHAR_ICON.OnLoseFocus = function() row.CHAR_ICON.label:Hide() end
        row.CHAR_ICON_BG:SetPosition(-31,1)
        row.CHAR_ICON:SetPosition(-31,1)
        row.CHAR_ICON_BG:Hide()
        row.CHAR_ICON:Hide()

        row.FRIEND_ICON = row.DETAILS:AddChild(Image("images/servericons.xml", "icons_friends.tex"))
        row.FRIEND_ICON:SetPosition(99,1)
        row.FRIEND_ICON.label = row.FRIEND_ICON:AddChild(Text(UIFONT, 23, STRINGS.UI.SERVERLISTINGSCREEN.FRIEND_ICON_HOVER)) 
        row.FRIEND_ICON.label:SetPosition(3,22,0)
        row.FRIEND_ICON.label:Hide()
        row.FRIEND_ICON.OnGainFocus = function() row.FRIEND_ICON.label:Show() end
        row.FRIEND_ICON.OnLoseFocus = function() row.FRIEND_ICON.label:Hide() end
        row.FRIEND_ICON:Hide()
        
        row.HAS_PASSWORD_ICON = row.DETAILS:AddChild(Image("images/servericons.xml", "icon_lock.tex"))
        row.HAS_PASSWORD_ICON:SetPosition(73,1)
        row.HAS_PASSWORD_ICON.label = row.HAS_PASSWORD_ICON:AddChild(Text(UIFONT, 23, STRINGS.UI.SERVERLISTINGSCREEN.PASSWORD_ICON_HOVER))
        row.HAS_PASSWORD_ICON.label:SetPosition(3,22,0)
        row.HAS_PASSWORD_ICON.label:Hide()
        row.HAS_PASSWORD_ICON.OnGainFocus = function() row.HAS_PASSWORD_ICON.label:Show() end
        row.HAS_PASSWORD_ICON.OnLoseFocus = function() row.HAS_PASSWORD_ICON.label:Hide() end
        row.HAS_PASSWORD_ICON:Hide()

        row.DEDICATED_ICON = row.DETAILS:AddChild(Image("images/servericons.xml", "icon_server.tex"))
        row.DEDICATED_ICON:SetPosition(47,1)
        row.DEDICATED_ICON.label = row.DEDICATED_ICON:AddChild(Text(UIFONT, 23, STRINGS.UI.SERVERLISTINGSCREEN.DEDICATED_ICON_HOVER))
        row.DEDICATED_ICON.label:SetPosition(3,22,0)
        row.DEDICATED_ICON.label:Hide()
        row.DEDICATED_ICON.OnGainFocus = function() row.DEDICATED_ICON.label:Show() end
        row.DEDICATED_ICON.OnLoseFocus = function() row.DEDICATED_ICON.label:Hide() end
        row.DEDICATED_ICON:Hide()
        
        row.PVP_ICON = row.DETAILS:AddChild(Image("images/servericons.xml", "icon_PvP.tex"))
        row.PVP_ICON:SetPosition(-5,1)
        row.PVP_ICON.label = row.PVP_ICON:AddChild(Text(UIFONT, 23, STRINGS.UI.SERVERLISTINGSCREEN.PVP_ICON_HOVER))
        row.PVP_ICON.label:SetPosition(3,22,0)
        row.PVP_ICON.label:Hide()
        row.PVP_ICON.OnGainFocus = function() row.PVP_ICON.label:Show() end
        row.PVP_ICON.OnLoseFocus = function() row.PVP_ICON.label:Hide() end
        row.PVP_ICON:Hide()
    
        row.MODS_ENABLED_ICON = row.DETAILS:AddChild(Image("images/servericons.xml", "icon_modserver.tex"))
        row.MODS_ENABLED_ICON:SetPosition(21,1)
        row.MODS_ENABLED_ICON.label = row.MODS_ENABLED_ICON:AddChild(Text(UIFONT, 23, STRINGS.UI.SERVERLISTINGSCREEN.MODS_ICON_HOVER))
        row.MODS_ENABLED_ICON.label:SetPosition(3,22,0)
        row.MODS_ENABLED_ICON.label:Hide()
        row.MODS_ENABLED_ICON.OnGainFocus = function() row.MODS_ENABLED_ICON.label:Show() end
        row.MODS_ENABLED_ICON.OnLoseFocus = function() row.MODS_ENABLED_ICON.label:Hide() end
        row.MODS_ENABLED_ICON:Hide()

        row.PLAYERS = row:AddChild(Text(BUTTONFONT, font_size))
        row.PLAYERS:SetHAlign(ANCHOR_MIDDLE)
        row.PLAYERS:SetPosition(column_offsets.PLAYERS, y_offset, 0)
        row.PLAYERS:SetRegionSize( 400, 70 )
        row.PLAYERS:SetString("")

        row.PING = row:AddChild(Text(BUTTONFONT, font_size))
        row.PING:SetHAlign(ANCHOR_MIDDLE)
        row.PING:SetPosition(column_offsets.PING, y_offset, 0)
        row.PING:SetRegionSize( 400, 70 )
        row.PING:SetString("")  

        table.insert(self.list_widgets, row)--, id=i})    
    end

    self.frame_overlay = self.server_list:AddChild(Image("images/fepanels_dst.xml","large_panel_left_overlay.tex"))
    self.frame_overlay:SetPosition(-355,24)
    self.frame_overlay:SetScale(1,.955)

    local function UpdateServerListWidget(widget, serverdata)
        if not widget then return end
                
        if not serverdata then
            widget.index = -1
            widget.NAME:SetString("")
            widget.PLAYERS:SetString("")
            widget.PING:SetString("")
            widget.CHAR_ICON:Hide()
            widget.CHAR_ICON_BG:Hide()
            widget.FRIEND_ICON:Hide()
            widget.HAS_PASSWORD_ICON:Hide()
            widget.DEDICATED_ICON:Hide()
            widget.PVP_ICON:Hide()
            widget.MODS_ENABLED_ICON:Hide()
            widget.cursor:Hide()
        else
            local dev_server = serverdata.version == -1
            local version_check_failed = serverdata.version ~= tonumber(APP_VERSION)

            local font_size = font_size * .8
            local y_offset = 15

            widget.index = serverdata.actualindex --actual index is wrong

            widget.version = serverdata.version

            widget.cursor:Show()
            
            widget.NAME:SetString(serverdata.name)
            if dev_server then widget.NAME:SetColour(dev_color[1], dev_color[2], dev_color[3], dev_color[4])
            elseif version_check_failed then widget.NAME:SetColour(mismatch_color[1], mismatch_color[2], mismatch_color[3], mismatch_color[4]) end

            self:ProcessPlayerData( serverdata.session )
	    
            if self.sessions[serverdata.session] ~= nil and self.sessions[serverdata.session] ~= false then
                local playerdata = self.sessions[serverdata.session]
                local character = playerdata.prefab
                if character == "maxwell" then
                    character = "waxwell"
                end

                local atlas = (table.contains(MODCHARACTERLIST, character) and "images/saveslot_portraits/"..character..".xml") or "images/saveslot_portraits.xml"
                if not table.contains(GetActiveCharacterList(), character) then
                    character = "random" -- Use a question mark if the character isn't currently active
                end
                widget.CHAR_ICON:SetTexture(atlas, character..".tex")
                local age = playerdata.age or "???"
                widget.CHAR_ICON.label:SetString(STRINGS.UI.SERVERLISTINGSCREEN.CHAR_AGE_1..age..STRINGS.UI.SERVERLISTINGSCREEN.CHAR_AGE_2)
                widget.CHAR_ICON_BG:Show()
                widget.CHAR_ICON:Show()
            else
                widget.CHAR_ICON_BG:Hide()
                widget.CHAR_ICON:Hide()
            end
            
            if serverdata.friend then 
                widget.FRIEND_ICON:Show()
            else
                widget.FRIEND_ICON:Hide()
            end
            if serverdata.has_password then 
                widget.HAS_PASSWORD_ICON:Show()
            else
                widget.HAS_PASSWORD_ICON:Hide()
            end
            if serverdata.dedicated then 
                widget.DEDICATED_ICON:Show()
            else
                widget.DEDICATED_ICON:Hide()
            end
            if serverdata.pvp then 
                widget.PVP_ICON:Show()
            else
                widget.PVP_ICON:Hide()
            end
            if serverdata.mods_enabled then 
                widget.MODS_ENABLED_ICON:Show()
            else
                widget.MODS_ENABLED_ICON:Hide()
            end

            widget.PLAYERS:SetString(serverdata.current_players .. "/" .. serverdata.max_players)
            if dev_server then widget.PLAYERS:SetColour(dev_color[1], dev_color[2], dev_color[3], dev_color[4])
            elseif version_check_failed then widget.PLAYERS:SetColour(mismatch_color[1], mismatch_color[2], mismatch_color[3], mismatch_color[4]) end

            widget.PING:SetString(serverdata.ping)  
            if serverdata.ping < 0 then
                widget.PING:SetString("???")
            end
            if dev_server then widget.PING:SetColour(dev_color[1], dev_color[2], dev_color[3], dev_color[4])
            elseif version_check_failed then widget.PING:SetColour(mismatch_color[1], mismatch_color[2], mismatch_color[3], mismatch_color[4])  end 
        end
    end

    self.servers_scroll_list = self.server_list_titles:AddChild(ScrollableList(self.viewed_servers, 320, 385, 20, 10, nil, UpdateServerListWidget, self.list_widgets, 150, true))
    self.servers_scroll_list:SetPosition(450, -202)
    self.servers_scroll_list:LayOutStaticWidgets(9)
    self.servers_scroll_list.onscrollcb = function()
        self:GuaranteeSelectedServerHighlighted()
    end
end

function ServerListingScreen:GuaranteeSelectedServerHighlighted()
    for i,v in pairs(self.list_widgets) do
        local dev_server = v.version and v.version == -1 or false
        local version_check_failed = v.version and v.version ~= tonumber(APP_VERSION) or false
		if v and v.index ~= -1 and v.index == self.selected_index_actual then
            if dev_server then 
                v.NAME:SetColour(dev_color[1], dev_color[2], dev_color[3], dev_color[4]) 
                v.PLAYERS:SetColour(dev_color[1], dev_color[2], dev_color[3], dev_color[4]) 
                v.PING:SetColour(dev_color[1], dev_color[2], dev_color[3], dev_color[4])
            elseif version_check_failed then 
                v.NAME:SetColour(mismatch_color[1], mismatch_color[2], mismatch_color[3], mismatch_color[4])
                v.PLAYERS:SetColour(mismatch_color[1], mismatch_color[2], mismatch_color[3], mismatch_color[4])
                v.PING:SetColour(mismatch_color[1], mismatch_color[2], mismatch_color[3], mismatch_color[4]) 
            else
                v.NAME:SetFont(UIFONT)
                v.PLAYERS:SetFont(UIFONT)
                v.PING:SetFont(UIFONT)
                v.NAME:SetColour(1,1,1,1)
                v.PLAYERS:SetColour(1,1,1,1)
                v.PING:SetColour(1,1,1,1)
            end
            v.cursor:SetSelected(true)
        else
            v.NAME:SetFont(BUTTONFONT)
            v.PLAYERS:SetFont(BUTTONFONT)
            v.PING:SetFont(BUTTONFONT)
            if dev_server then 
                v.NAME:SetColour(dev_color[1], dev_color[2], dev_color[3], dev_color[4]) 
                v.PLAYERS:SetColour(dev_color[1], dev_color[2], dev_color[3], dev_color[4]) 
                v.PING:SetColour(dev_color[1], dev_color[2], dev_color[3], dev_color[4])                
            elseif version_check_failed then 
                v.NAME:SetColour(mismatch_color[1], mismatch_color[2], mismatch_color[3], mismatch_color[4])
                v.PLAYERS:SetColour(mismatch_color[1], mismatch_color[2], mismatch_color[3], mismatch_color[4])
                v.PING:SetColour(mismatch_color[1], mismatch_color[2], mismatch_color[3], mismatch_color[4]) 
            else
                v.NAME:SetColour(0,0,0,1)
                v.PLAYERS:SetColour(0,0,0,1)
                v.PING:SetColour(0,0,0,1)
            end
            v.cursor:SetSelected(false)
        end
    end
end

function ServerListingScreen:SetSort(column)
    local function DoSortArrow()
        local col = self.column_buttons[self.sort_column]
        for i,v in pairs(self.column_buttons) do
            if v ~= col then
                v.arrow:Hide()
                v.text:SetColour(0,0,0,1)
                v.text:SetFont(BUTTONFONT)
            else
                if self.sort_ascending then
                    if v.bg.focus then
                        v.arrow:SetTexture("images/ui.xml", "arrow2_up_over.tex")
                    else
                        v.arrow:SetTexture("images/ui.xml", "arrow2_up.tex")
                    end
                    v.arrow.ascending = true
                else
                    if v.bg.focus then
                        v.arrow:SetTexture("images/ui.xml", "arrow2_down_over.tex")
                    else
                        v.arrow:SetTexture("images/ui.xml", "arrow2_down.tex")
                    end
                    v.arrow.ascending = false
                end
                v.arrow:Show()
                if v.bg.focus then
                    v.text:SetFont(UIFONT)
                    v.text:SetColour(1,1,1,1)
                else
                    v.text:SetFont(BUTTONFONT)
                    v.text:SetColour(0,0,0,1)
                    -- v.text:SetColour(.4,.4,.4,1)
                end
            end
        end
    end

    if column == self.sort_column then
        self.sort_ascending = not self.sort_ascending
    else
        self.sort_ascending = true
    end
    self.sort_column = column

    DoSortArrow()

    self:DoSorting()
end

function ServerListingScreen:DoSorting()
    -- This does the trick, but we might want more clever criteria for how a certain column gets ordered
    -- ("Server 5" < "Server 50" < "Server 6" is current result for Name)
    if self.viewed_servers then
        table.sort(self.viewed_servers, function(a,b)
            if self.sort_ascending then
                if self.sort_column == "NAME" then
                    return string.lower(a.name) < string.lower(b.name)
                elseif self.sort_column == "DETAILS" then
                    -- return a.details < b.details -- decided to just not let you sort on details, since that's basically what the filters are for
                elseif self.sort_column == "PLAYERS" then
                    return a.current_players < b.current_players
                else
                    if a.ping < 0 and b.ping >= 0 then
                        return false
                    elseif a.ping >= 0 and b.ping < 0 then
                        return true
                    elseif a.ping == b.ping then
                        return string.lower(a.name) < string.lower(b.name)
                    else
                        return a.ping < b.ping
                    end
                end
            else
                if self.sort_column == "NAME" then
                    return string.lower(a.name) > string.lower(b.name)
                elseif self.sort_column == "DETAILS" then
                    -- return a.details > b.details --  decided to just not let you sort on details, since that's basically what the filters are for
                elseif self.sort_column == "PLAYERS" then
                    return a.current_players > b.current_players
                else
                    if a.ping < 0 and b.ping >= 0 then
                        return false
                    elseif a.ping >= 0 and b.ping < 0 then
                        return true
                    elseif a.ping == b.ping then
                        return string.lower(a.name) > string.lower(b.name)
                    else
                        return a.ping > b.ping
                    end
                end
            end
        end)
        self:RefreshView(true)
    end
end

function ServerListingScreen:ProcessPlayerData(session)
    if self.sessions[session] == nil and self.session_mapping ~= nil then
        local data = self.session_mapping[session]
        if data ~= nil then
            local success, playerdata = RunInSandboxSafe(data)
            self.sessions[session] = success and playerdata or false
            self.session_mapping[session] = nil
        end
    end 
end

function ServerListingScreen:IsValidWithFilters(server)

    local function gameModeInvalid(serverMode, spinnerMode)
        if spinnerMode == "ANY" then
            return false
        elseif spinnerMode == "custom" then
            --The user is looking for any modded game mode
            return not GetIsModGameMode( serverMode )
        else
            --The user is looking for a specific game mode
            return serverMode ~= spinnerMode
        end
    end

    local function charInvalid(session, spinnerSelection)
		
        self:ProcessPlayerData( session )
        
        if self.sessions[session] ~= nil then
            local char = self.sessions[session]
            if spinnerSelection == true then
                return char == false
            else
                return char ~= false
            end
        elseif spinnerSelection == true then
            return true
        else
            return false
        end
    end

    if not server or type(server) ~= "table" then return end

    local valid = true

    -- Filter our friends only servers that are not our friend
    if server.friends_only and not server.friend then
        valid = false
    end
	 
    -- Filter out unjoinable servers, if we are online
    if valid and self.online and not server.steamroom and server.ping < 0 then
        valid = false
        self.unjoinable_servers = self.unjoinable_servers + 1
    end
    
    -- If we are in offline mode, don't show non-lan servers
    if valid and self.offlinemode and not server.lan then
        valid = false
    end
	 
    -- Hide version mismatched servers on live builds
    local version_mismatch = APP_VERSION ~= tostring(server.version)
    local dev_build = APP_VERSION == "-1" or BRANCH == "dev"
    if version_mismatch and not dev_build then
        valid = false
    end
	
    -- Check spinner validation
    if valid then
        for i,v in pairs(self.filters) do
            -- First check with the spinners
            if v and v.spinner then
                if ((v.name == "HASPVP" and server.pvp ~= v.spinner:GetSelectedData() and v.spinner:GetSelectedData() ~= "ANY")
                or (v.name == "GAMEMODE" and v.spinner:GetSelectedData() ~= "ANY" and gameModeInvalid(server.mode, v.spinner:GetSelectedData()))
                or (v.name == "HASPASSWORD" and (v.spinner:GetSelectedData() ~= "ANY" and server.has_password ~= v.spinner:GetSelectedData()))
                or (v.name == "MINCURRPLAYERS" and v.spinner:GetSelectedData() ~= "ANY" and (server.current_players < v.spinner:GetSelectedData()))
                or (v.name == "MAXCURRPLAYERS" and v.spinner:GetSelectedData() ~= "ANY" and (server.current_players > v.spinner:GetSelectedData()))
                or (v.name == "MAXSERVERSIZE" and v.spinner:GetSelectedData() ~= "ANY" and server.max_players > v.spinner:GetSelectedData())
                or (v.name == "MINOPENSLOTS" and v.spinner:GetSelectedData() ~= "ANY" and server.max_players - server.current_players < v.spinner:GetSelectedData())
                or (v.name == "ISFULL" and (server.current_players >= server.max_players and v.spinner:GetSelectedData() == false))
                or (v.name == "ISEMPTY" and (server.current_players <= 0 and v.spinner:GetSelectedData() == false))
                or (v.name == "FRIENDSONLY" and v.spinner:GetSelectedData() ~= "ANY" and v.spinner:GetSelectedData() ~= server.friend )
                or (v.name == "SEASON" and v.spinner:GetSelectedData() ~= "ANY" and v.spinner:GetSelectedData() ~= server.season )
                or (v.name == "VERSIONCHECK" and v.spinner:GetSelectedData() and version_mismatch )
                or (v.name == "ISDEDICATED" and v.spinner:GetSelectedData() ~= "ANY" and server.dedicated ~= v.spinner:GetSelectedData())
                or (v.name == "MODSENABLED" and v.spinner:GetSelectedData() ~= "ANY" and server.mods_enabled ~= v.spinner:GetSelectedData())
                or (v.name == "HASCHARACTER" and v.spinner:GetSelectedData() ~= "ANY" and charInvalid(server.session, v.spinner:GetSelectedData()))) then
    				valid = false
    			end
                --more stuff coming later (see server browser spec doc)
                if not valid then break end
            end
        end
    end

    -- Then check with the search box (but only if it hasn't already been invalidated)
    if valid and #self.queryTokens > 0 then
        -- Then check if our servers' names and tags contain any of those tokens
        local searchMatch = true -- Assume match until we find a non-match
        for j,k in pairs(self.queryTokens) do
            if not string.find(string.lower(server.name), k, 1, true) and not string.find(string.lower(server.tags), k, 1, true) then
                searchMatch = false
                break
            end
        end

        if not searchMatch then
            valid = false
        end
    end

    return valid
end

function ServerListingScreen:ResetFilters()
    for i,v in pairs(self.filters) do
        if v and v.spinner then 
            v.spinner:SetSelectedIndex(1)
            if v.name == "GAMEMODE" then
                v.spinner:SetHoverText("")
            end
        end
    end
    self.searchbox.textbox:SetString("")
    self:DoFiltering()
end

function ServerListingScreen:DoFiltering()
    if not self.filters then return end

    -- Reset the number of unjoinable servers
    self.unjoinable_servers = 0

    -- If there's a query, build the table of query tokens for checking against
    self.queryTokens = {}
    local query = self.searchbox.textbox:GetString()
    if query ~= "" then
        local startPos = 1
        local endPos = 1
        local token = ""
        if string.len(query) == 1 then
            table.insert(self.queryTokens, string.lower(query))
        else
            for i=1, string.len(query) do
                -- Separate search tokens by , (and make sure we grab the trailing token)
                if string.sub(query,i,i) == "," or i == string.len(query) then
                    endPos = i
                end
                if (endPos ~= startPos and endPos > startPos) or (endPos == string.len(query)) then
                    if endPos < string.len(query) or (endPos == string.len(query) and string.sub(query, endPos, endPos) == ",") then endPos = endPos - 1 end
                    token = string.sub(query, startPos, endPos) -- Grab the token
                    token = string.gsub(token, "^%s*(.-)%s*$", "%1") -- Get rid of whitespace on the ends
                    table.insert(self.queryTokens, string.lower(token))
                    startPos = endPos + 2 -- Increase startPos so we skip the comma for the next token
                end
            end
        end
    end

    local filtered_servers = {}
    if self.servers and #self.servers > 0 then
        for i,v in pairs(self.servers) do
            if v and self:IsValidWithFilters(v) then
                table.insert(filtered_servers, 
                    {
                        name=v.name, 
                        mode = v.mode,
                        has_password=v.has_password, 
                        description=v.description,
                        mods_description=v.mods_description,
                        mods_failed_deserialization=v.mods_failed_deserialization,
                        dedicated=v.dedicated, 
                        pvp=v.pvp,
                        current_players=v.current_players, 
                        max_players=v.max_players, 
                        ping=v.ping, 
                        ip=v.ip,  
                        port=v.port, 
                        row=v.row, 
                        version=v.version,
                        friend=v.friend, 
                        actualindex=i,
                        mods_enabled = v.mods_enabled,
                        tags = v.tags,
                        session = v.session,
                        -- data = v.data,
                    })
            end
        end

        if self.selected_server ~= nil and self:IsValidWithFilters(self.selected_server) == false then
            self:ServerSelected(nil)
        end
    end

    if CompareTable(self.viewed_servers, filtered_servers) then
        return
    end
    self.viewed_servers = {}
    self.viewed_servers = filtered_servers
    local num_servs = #self.servers-self.unjoinable_servers
    if num_servs < 0 then num_servs = 0 end
    self.title:SetString(STRINGS.UI.SERVERLISTINGSCREEN.SERVER_LIST_TITLE.." ("..#self.viewed_servers.." "..STRINGS.UI.SERVERLISTINGSCREEN.OUT_OF.." "..num_servs.." "..STRINGS.UI.SERVERLISTINGSCREEN.SHOWING..")")
    if not self.online then
        self.title:SetString(STRINGS.UI.SERVERLISTINGSCREEN.SERVER_LIST_TITLE.." ("..STRINGS.UI.SERVERLISTINGSCREEN.LAN..")")
    end
    self:DoSorting()
    self.servers_scroll_list:SetList(self.viewed_servers)
end

function ServerListingScreen:Create()
    local function cb(customoptions, slotdata)
        self.customoptions = customoptions
        self.slotdata = slotdata
    end

    TheNet:StopSearchingServers()
    self:Disable()
    local filters = {}
    for i,v in pairs(self.filters) do
        if v.spinner then 
            table.insert(filters, {name=v.name, data=v.spinner:GetSelectedData()})
        elseif v.textbox then
            table.insert(filters, {name="search", data=v.textbox:GetString()})
        end
    end
    Profile:SaveFilters(filters)
    TheFrontEnd:Fade(false, screen_fade_time, function()
        TheFrontEnd:PushScreen(ServerCreationScreen(self.customoptions, self.slotdata, cb))
        TheFrontEnd:Fade(true, screen_fade_time)
    end)
end

function ServerListingScreen:Cancel()
    --IsServerListingScreenActive = false
    TheNet:StopSearchingServers()
    self:Disable()
    TheFrontEnd:Fade(false, screen_fade_time*1.5, function()
        if self.cb then
            local filters = {}
            for i,v in pairs(self.filters) do
                if v.spinner then 
                    table.insert(filters, {name=v.name, data=v.spinner:GetSelectedData()})
                elseif v.textbox then
                    table.insert(filters, {name="search", data=v.textbox:GetString()})
                end
            end
            self.cb(filters, self.customoptions, self.slotdata)
        end
        TheFrontEnd:PopScreen()
        TheFrontEnd:Fade(true, screen_fade_time*1.5)
    end)
end

function ServerListingScreen:OnControl(control, down)
    if ServerListingScreen._base.OnControl(self, control, down) then return true end
    
    if self.server_name_textbox and self.server_name_textbox.editing then
        self.server_name_textbox:OnControl(control, down)
        return true
    end

    if not down then
        if control == CONTROL_CANCEL then 
            if TheFrontEnd:GetFadeLevel() > 0 then 
                TheNet:Disconnect()
                HideCancelTip()
                TheFrontEnd:Fade(true, screen_fade_time)
            else
                self:Cancel()
            end
        else
            return false
        end

        return true
    end
end

function ServerListingScreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}

    table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)

    return table.concat(t, "  ")
end

local function CreateSpinner( self, name, text, spinnerOptions, numeric, onchanged )
    local spacing = 62
    local label_width = 200
    local group = self.server_detail_panel:AddChild(Widget( "SpinnerGroup" ))
    group.label = group:AddChild( Text( BUTTONFONT, 35, text ) )
    group.label:SetPosition( -label_width/2 + 30, 0, 0 )
    group.label:SetRegionSize( label_width, 50 )
    group.label:SetHAlign( ANCHOR_RIGHT )
    group.label:SetColour(0,0,0,1)

    group.spinner = nil
    if numeric then
        group.spinner = group:AddChild(NumericSpinner(spinnerOptions.min, spinnerOptions.max, nil,nil,nil,nil,nil,nil, true))
    else
        group.spinner = group:AddChild(Spinner(spinnerOptions, nil,nil,nil,nil,nil,nil, true))
    end
    group.spinner:SetTextColour(0,0,0,1)
    if name == "GAMEMODE" then
        group.spinner.OnChanged =
            function( _, data )
                self:DoFiltering()
                group.spinner:SetHoverText(STRINGS.UI.SERVERCREATIONSCREEN[string.upper(group.spinner:GetSelectedData()).."_TOOLTIP"])
                if onchanged then
                    onchanged(_,data)
                end
            end
        group.spinner:SetHoverText(STRINGS.UI.SERVERCREATIONSCREEN[string.upper(group.spinner:GetSelectedData()).."_TOOLTIP"])
    else
        group.spinner.OnChanged =
            function( _, data )
                self:DoFiltering()
                if onchanged then
                    onchanged(_,data)
                end
            end
    end
    group.spinner:SetPosition( 120, 0, 0 )

    group.name = name

    --pass focus down to the spinner
    group.focus_forward = group.spinner

    

    return group
end

function ServerListingScreen:MakeFiltersPanel(filter_data)
    local any_on_off = {{ text = STRINGS.UI.SERVERLISTINGSCREEN.ANY, data = "ANY" }, { text = STRINGS.UI.SERVERLISTINGSCREEN.ON, data = true }, { text = STRINGS.UI.SERVERLISTINGSCREEN.OFF, data = false }}
    local any_no_yes = {{ text = STRINGS.UI.SERVERLISTINGSCREEN.ANY, data = "ANY" }, { text = STRINGS.UI.SERVERLISTINGSCREEN.NO, data = false }, { text = STRINGS.UI.SERVERLISTINGSCREEN.YES, data = true }}
    local any_yes_no = {{ text = STRINGS.UI.SERVERLISTINGSCREEN.ANY, data = "ANY" }, { text = STRINGS.UI.SERVERLISTINGSCREEN.YES, data = true }, { text = STRINGS.UI.   SERVERLISTINGSCREEN.NO, data = false }}
    local yes_no = {{ text = STRINGS.UI.SERVERLISTINGSCREEN.YES, data = true }, { text = STRINGS.UI.SERVERLISTINGSCREEN.NO, data = false }}
    local no_yes = {{ text = STRINGS.UI.SERVERLISTINGSCREEN.NO, data = false }, { text = STRINGS.UI.SERVERLISTINGSCREEN.YES, data = true }}
    local any_dedicated_hosted = {{ text = STRINGS.UI.SERVERLISTINGSCREEN.ANY, data = "ANY" }, { text = STRINGS.UI.SERVERLISTINGSCREEN.DEDICATED, data = true }, { text = STRINGS.UI.SERVERLISTINGSCREEN.HOSTED, data = false }}
    
    local seasons = {{ text = STRINGS.UI.SERVERLISTINGSCREEN.ANY, data = "ANY" },
                    { text = STRINGS.UI.SERVERLISTINGSCREEN.SEASONS.SPRING, data = "spring" }, 
                    { text = STRINGS.UI.SERVERLISTINGSCREEN.SEASONS.SUMMER, data = "summer" },
                    { text = STRINGS.UI.SERVERLISTINGSCREEN.SEASONS.AUTUMN, data = "autumn" },
                    { text = STRINGS.UI.SERVERLISTINGSCREEN.SEASONS.WINTER, data = "winter" }}
    
    local game_modes = {{ text = STRINGS.UI.SERVERLISTINGSCREEN.ANY, data = "ANY" }}
 	for gm_name,game_mode_details in pairs(GAME_MODES) do
		table.insert( game_modes, { text = game_mode_details.text, data = gm_name} )
	end
	table.insert( game_modes, { text = STRINGS.UI.SERVERLISTINGSCREEN.CUSTOM, data = "custom" } )
    local player_slots = {{ text = STRINGS.UI.SERVERLISTINGSCREEN.ANY, data = "ANY" }}
    local i = TUNING.MAX_SERVER_SIZE
    while i > 0 do
        table.insert(player_slots,{text=i, data=i})
        i = i - 1
    end

    local searchbox = self.server_detail_panel:AddChild(Widget("searchbox"))
    searchbox.bg = searchbox:AddChild( Image("images/textboxes.xml", "textbox_long.tex") )
    searchbox.bg:ScaleToSize( 250 + 30, 50 )
    searchbox.textbox = searchbox:AddChild(TextEdit( BODYTEXTFONT, font_size *.8 ) )
    searchbox.textbox:SetForceEdit(true)
    searchbox.bg:SetPosition((250 * .5) - 100 + 12, 8, 0)
    searchbox.textbox:SetPosition((250 * .5) - 100 + 15, 8, 0)
    searchbox.textbox:SetRegionSize( 250, 50 )
    searchbox.textbox:SetHAlign(ANCHOR_LEFT)
    searchbox.textbox:SetFocusedImage( searchbox.bg, "images/textboxes.xml", "textbox_long_over.tex", "textbox_long.tex" )
    searchbox.textbox:SetTextLengthLimit( STRING_MAX_LENGTH )
    searchbox.textbox:SetCharacterFilter( VALID_CHARS )
    searchbox.label = searchbox:AddChild(Text(BUTTONFONT, 35))
    searchbox.label:SetString(STRINGS.UI.SERVERLISTINGSCREEN.SEARCH)
    searchbox.label:SetRegionSize( 165, 50 )
    searchbox.label:SetHAlign(ANCHOR_LEFT)
    searchbox.label:SetPosition(-75,0)
    searchbox.label:SetColour(0,0,0,1)
    searchbox.gobutton = searchbox:AddChild(ImageButton("images/ui.xml", "next_arrow.tex", "next_arrow_over.tex", "next_arrow.tex"))
    searchbox.gobutton:SetPosition(200,8)
    searchbox.gobutton:SetScale(.6)
    searchbox.gobutton.image:SetTint(.6,.6,.6,1)
    searchbox.textbox.OnTextEntered = function() self:DoFiltering() end
    searchbox.gobutton:SetOnClick( function() self.searchbox.textbox:OnTextEntered() end )

    self.searchbox = searchbox -- Need a ref to this for reasons

    table.insert(self.filters, searchbox)
    table.insert(self.filters, CreateSpinner( self, "GAMEMODE", STRINGS.UI.SERVERLISTINGSCREEN.GAMEMODE, game_modes, false ))
    table.insert(self.filters, CreateSpinner( self, "HASPVP", STRINGS.UI.SERVERLISTINGSCREEN.HASPVP, any_on_off, false ))
    table.insert(self.filters, CreateSpinner( self, "HASCHARACTER", STRINGS.UI.SERVERLISTINGSCREEN.HASCHARACTER, any_yes_no, false )) --#srosen disabled until we can get perf better on this
    table.insert(self.filters, CreateSpinner( self, "ISFULL", STRINGS.UI.SERVERLISTINGSCREEN.ISFULL, yes_no, false ))
    table.insert(self.filters, CreateSpinner( self, "FRIENDSONLY", STRINGS.UI.SERVERLISTINGSCREEN.FRIENDSONLY, any_yes_no, false ))
    table.insert(self.filters, CreateSpinner( self, "SEASON", STRINGS.UI.SERVERLISTINGSCREEN.SEASONFILTER, seasons, false ))
    table.insert(self.filters, CreateSpinner( self, "ISDEDICATED", STRINGS.UI.SERVERLISTINGSCREEN.SERVERTYPE, any_dedicated_hosted, false ))
    table.insert(self.filters, CreateSpinner( self, "HASPASSWORD", STRINGS.UI.SERVERLISTINGSCREEN.HASPASSWORD, any_no_yes, false ))
    table.insert(self.filters, CreateSpinner( self, "MODSENABLED", STRINGS.UI.SERVERLISTINGSCREEN.MODSENABLED, any_no_yes, false ))
    -- table.insert(self.filters, CreateSpinner( "MINCURRPLAYERS", STRINGS.UI.SERVERLISTINGSCREEN.MINCURRPLAYERS, {min=0,max=4}, true ))
    -- table.insert(self.filters, CreateSpinner( self, "MAXCURRPLAYERS", STRINGS.UI.SERVERLISTINGSCREEN.MAXCURRPLAYERS, players, false ))--STRINGS.UI.SERVERLISTINGSCREEN.MAXCURRPLAYERS, {min=0,max=4}, true ))
    table.insert(self.filters, CreateSpinner( self, "MINOPENSLOTS", STRINGS.UI.SERVERLISTINGSCREEN.MINOPENSLOTS, player_slots, false ))
    -- table.insert(self.filters, CreateSpinner( "MAXSERVERSIZE", STRINGS.UI.SERVERLISTINGSCREEN.MAXSERVERSIZE, {min=2,max=4}, true ))
    table.insert(self.filters, CreateSpinner( self, "ISEMPTY", STRINGS.UI.SERVERLISTINGSCREEN.ISEMPTY, yes_no, false ))
    
    if APP_VERSION == "-1" then
        table.insert(self.filters, CreateSpinner( self, "VERSIONCHECK", STRINGS.UI.SERVERLISTINGSCREEN.VERSIONCHECK, no_yes, false ))
    else
        TheNet:SetCheckVersionOnQuery( true )
    end
    
    if not self.offlinemode then
        self.lan_spinner = CreateSpinner( self, "SHOWLAN", STRINGS.UI.SERVERLISTINGSCREEN.SHOWLAN, no_yes, false, function() 
            self:SearchForServers() 
        end )
        table.insert(self.filters, self.lan_spinner)
    end

    self.filters_scroll_list = self.server_detail_panel:AddChild(ScrollableList(self.filters, 240, 340, 30, 13))
    self.filters_scroll_list:SetPosition(60,-20)

    if filter_data then
        for i,v in pairs(filter_data) do
            for j,k in pairs(self.filters) do
                if v.name == k.name then
                    if k.spinner then
                        k.spinner:SetSelected(v.data)
                        if v.name == "GAMEMODE" then
                            k.spinner:SetHoverText(STRINGS.UI.SERVERCREATIONSCREEN[string.upper(v.data).."_TOOLTIP"])
                        end
                    end
                elseif v.name == "search" then
                    if k.textbox then
                        k.textbox:SetString(v.data or "")
                    end
                end
            end
        end
    end
end

local function MakeImgButton(parent, xPos, yPos, text, onclick, style)
    if not parent or not xPos or not yPos or not text or not onclick then return end

    local btn 
    if not style then
        btn = parent:AddChild(ImageButton())
    elseif style == "tab" then
        btn = parent:AddChild(ImageButton("images/serverbrowser.xml", "server_detail_button.tex", "server_detail_button_over.tex"))
    elseif style == "large" then
        btn = parent:AddChild(ImageButton("images/ui.xml", "button_large.tex", "button_large_over.tex", "button_large_disabled.tex", "button_large_onclick.tex"))
    elseif style == "reset" then
        btn = parent:AddChild(ImageButton("images/lobbyscreen.xml", "button_send.tex", "button_send_over.tex", "button_send_down.tex", "button_send_over.tex"))
        btn.image:SetTint(.6,.6,.6,1)
        btn.image:SetScale(-.18,.18)
        btn.image:SetRotation(-45)
    end
    btn:SetPosition(xPos, yPos)
    btn:SetText(text)
    btn.text:SetColour(0,0,0,1)
    btn:SetFont(BUTTONFONT)
    btn:SetTextSize(40)
    btn:SetOnClick(onclick)

    return btn
end

function ServerListingScreen:MakeMenuButtons(left_col, right_col)
    self.create_button = MakeImgButton(self.server_list_titles, left_col+457, 125, STRINGS.UI.SERVERLISTINGSCREEN.CREATE, function() self:Create() end)
    self.refresh_button = MakeImgButton(self.server_list_titles, left_col+875, 125, STRINGS.UI.SERVERLISTINGSCREEN.REFRESH, function() self:SearchForServers() end)
    self.join_button = MakeImgButton(self.server_detail_panel, 108, -272, STRINGS.UI.SERVERLISTINGSCREEN.JOIN, function() self:Join() end, "large")
    self.join_button.text:SetPosition(-3,0)
    self.cancel_button = MakeImgButton(self.server_detail_panel, -120, -270, STRINGS.UI.SERVERLISTINGSCREEN.BACK, function() self:Cancel() end)
    self.filters_button = MakeImgButton(self.server_detail_panel, -140, 218, STRINGS.UI.SERVERLISTINGSCREEN.FILTERS, function() self:ToggleShowFilters() end, "tab")
    self.filters_button.text:SetPosition(3,-5)
    self.filters_button.disabledfont = TITLEFONT
    self.filters_reset_button = MakeImgButton(self.server_detail_panel, -80, 218, "", function() self:ResetFilters() end, "reset")
    self.filters_reset_button.label = self.filters_reset_button:AddChild(Text(UIFONT, 30, STRINGS.UI.SERVERLISTINGSCREEN.FILTER_RESET))
    self.filters_reset_button.label:SetPosition(3,33,0)
    self.filters_reset_button.label:Hide()
    self.filters_reset_button.OnGainFocus =
        function()
            if self.filters_reset_button:IsEnabled() and TheFrontEnd:GetFadeLevel() <= 0 then
                TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
            end
            if self.filters_reset_button:IsEnabled() then
                self.filters_reset_button.image:SetTexture(self.filters_reset_button.atlas, self.filters_reset_button.image_focus)
            end
            self.filters_reset_button.label:Show()
        end
    self.filters_reset_button.OnLoseFocus =
        function()
            if self.filters_reset_button:IsEnabled() then
                self.filters_reset_button.image:SetTexture(self.filters_reset_button.atlas, self.filters_reset_button.image_normal)
            end
            if self.filters_reset_button.o_pos then
                self.filters_reset_button:SetPosition(self.filters_reset_button.o_pos)
            end
            self.filters_reset_button.label:Hide()
        end
    self.details_button = MakeImgButton(self.server_detail_panel, 110, 218, STRINGS.UI.SERVERLISTINGSCREEN.SERVERDETAILS, function() self:ToggleShowFilters() end, "tab")
    self.details_button.text:SetPosition(3,-5)
    self.details_button.disabledfont = TITLEFONT
    self.filters_button.image:SetScale(-1.6,1)
    self.details_button.image:SetScale(1.6,1)

    self.join_button:Disable()

    self.details_shown = false
    self.filters_shown = false
end

function ServerListingScreen:MakeDetailPanel(right_col)
    self.server_detail_panel = self.root:AddChild(Widget("server_detail_panel"))
    self.server_detail_panel:SetPosition(right_col+10,20,0)
    self.server_detail_panelbg = self.server_detail_panel:AddChild(Image("images/serverbrowser.xml", "server_detail_bg.tex"))
    self.server_detail_panelbg:SetScale(1.2,1,1)
    self.server_detail_panelbg2 = self.server_detail_panel:AddChild(Image("images/serverbrowser.xml", "server_detail_left_tab.tex"))
    self.server_detail_panelbg2:SetScale(1.2,1,1)
    self.server_detail_panelbg2:SetPosition(-13,0)
 
    self.details_servername = self.server_detail_panel:AddChild(Text(BUTTONFONT, 44))
    self.details_servername:SetHAlign(ANCHOR_MIDDLE)
    self.details_servername:SetVAlign(ANCHOR_TOP)
    self.details_servername:SetPosition(-10, RESOLUTION_Y*0.16 - 20, 0)
    self.details_servername:SetRegionSize( 435, 90 )
    self.details_servername:SetString(STRINGS.UI.SERVERLISTINGSCREEN.NOSERVERSELECTED)
    self.details_servername:EnableWordWrap( true )
    self.details_servername:SetColour(0,0,0,1)

    self.details_serverdesc = self.server_detail_panel:AddChild(Text(BUTTONFONT, 30))
    self.details_serverdesc:SetHAlign(ANCHOR_MIDDLE)
    self.details_serverdesc:SetVAlign(ANCHOR_TOP)
    self.details_serverdesc:SetPosition(-10, 85, 0)
    self.details_serverdesc:SetRegionSize( 435, 70 )
    self.details_serverdesc:SetString("")
    self.details_serverdesc:EnableWordWrap( true )
    self.details_serverdesc:SetColour(0,0,0,1)
    --#srosen we should add the ability to set a single dimension of a text widgets' region size so that we can have word wrap and still have unlimited (but queryable) height
    -- use this for the name, desc, and chat

    self.viewmods_button = MakeImgButton(self.server_detail_panel, -10, 6, STRINGS.UI.SERVERLISTINGSCREEN.NOMODS, function() self:ViewServerMods() end)
    self.viewmods_button:SetScale(.7)
    self.viewmods_button:Disable()

    self.viewtags_button = MakeImgButton(self.server_detail_panel, -125, 6, STRINGS.UI.SERVERLISTINGSCREEN.NOTAGS, function() self:ViewServerTags() end)
    self.viewtags_button:SetScale(.7)
    self.viewtags_button:Disable()

    self.viewworld_button = MakeImgButton(self.server_detail_panel, 105, 6, STRINGS.UI.SERVERLISTINGSCREEN.VIEWWORLD, function() self:ViewServerWorld() end)
    self.viewworld_button:SetScale(.7)
    self.viewworld_button:Disable()

    local buttons = Widget("buttons")
    buttons:AddChild(self.viewmods_button)
    buttons:AddChild(self.viewtags_button)
    buttons:AddChild(self.viewworld_button)
    
    self.game_mode_description = Widget("gamemodedesc")
    self.game_mode_description.text = self.game_mode_description:AddChild(Text(BUTTONFONT, 40))
    self.game_mode_description.text:SetString(STRINGS.UI.SERVERLISTINGSCREEN.SURVIVAL)
    self.game_mode_description.text:SetPosition(-10,0)
    self.game_mode_description.text:SetHAlign(ANCHOR_MIDDLE)
    self.game_mode_description.text:SetRegionSize( 200, 50 )
    self.game_mode_description.text:SetString("")
    self.game_mode_description.text:SetColour(0,0,0,1)

    local has_password = Widget("pw")
    self.checkbox_has_password = has_password:AddChild(Image("images/ui.xml", "button_checkbox1.tex"))
    self.checkbox_has_password:SetPosition(-120, 0, 0)
    self.has_password_description = has_password:AddChild(Text(BUTTONFONT, 40))
    self.has_password_description:SetPosition(10, 0, 0)
    self.has_password_description:SetString(STRINGS.UI.SERVERLISTINGSCREEN.HASPASSWORD_DETAIL)
    self.has_password_description:SetHAlign(ANCHOR_LEFT)
    self.has_password_description:SetRegionSize( 200, 50 )
    self.has_password_description:SetColour(0,0,0,1)
    
    local dedicated_server = Widget("ded")
    self.checkbox_dedicated_server = dedicated_server:AddChild(Image("images/ui.xml", "button_checkbox2.tex"))
    self.checkbox_dedicated_server:SetPosition(-120, 0, 0)
    self.dedicated_server_description = dedicated_server:AddChild(Text(BUTTONFONT, 40))
    self.dedicated_server_description:SetPosition(10, 0, 0)
    self.dedicated_server_description:SetString(STRINGS.UI.SERVERLISTINGSCREEN.ISDEDICATED)
    self.dedicated_server_description:SetHAlign(ANCHOR_LEFT)
    self.dedicated_server_description:SetRegionSize( 200, 50 )
    self.dedicated_server_description:SetColour(0,0,0,1)
    
    local pvp = Widget("pvp")
    self.checkbox_pvp = pvp:AddChild(Image("images/ui.xml", "button_checkbox2.tex"))
    self.checkbox_pvp:SetPosition(-120, 0, 0)
    self.pvp_description = pvp:AddChild(Text(BUTTONFONT, 40))
    self.pvp_description:SetPosition(10, 0, 0)
    self.pvp_description:SetString(STRINGS.UI.SERVERLISTINGSCREEN.HASPVP_DETAIL)
    self.pvp_description:SetHAlign(ANCHOR_LEFT)
    self.pvp_description:SetRegionSize( 200, 50 )
    self.pvp_description:SetColour(0,0,0,1)

    self.season_description = Widget("seasondesc")
    self.season_description.text = self.season_description:AddChild(Text(BUTTONFONT, 40))
    self.season_description.text:SetPosition(-10,0)
    self.season_description.text:SetHAlign(ANCHOR_MIDDLE)
    self.season_description.text:SetRegionSize( 400, 50 )
    self.season_description.text:SetString("")
    self.season_description.text:SetColour(0,0,0,1)

    self.day_description = Widget("daydesc")
    self.day_description.text = self.day_description:AddChild(Text(BUTTONFONT, 40))
    self.day_description.text:SetPosition(-10,0)
    self.day_description.text:SetHAlign(ANCHOR_MIDDLE)
    self.day_description.text:SetRegionSize( 400, 50 )
    self.day_description.text:SetString("")
    self.day_description.text:SetColour(0,0,0,1)

    --#srosen this is disabled for now
    self.players_header = Widget("playersheader")
    self.players_header.text = self.players_header:AddChild(Text(BUTTONFONT, 40))
    self.players_header.text:SetPosition(-10,0)
    self.players_header.text:SetHAlign(ANCHOR_MIDDLE)
    self.players_header.text:SetRegionSize( 400, 50 )
    self.players_header.text:SetString(STRINGS.UI.SERVERLISTINGSCREEN.PLAYERS.." (0)")
    self.players_header.text:SetColour(0,0,0,1)

    self.detail_panel_widgets = {}
    table.insert(self.detail_panel_widgets, buttons)
    table.insert(self.detail_panel_widgets, self.game_mode_description)
    table.insert(self.detail_panel_widgets, self.day_description)
    table.insert(self.detail_panel_widgets, self.season_description)
    table.insert(self.detail_panel_widgets, pvp)
    table.insert(self.detail_panel_widgets, dedicated_server)
    table.insert(self.detail_panel_widgets, has_password)
    -- table.insert(self.detail_panel_widgets, self.players_header)
    self.first_player_row = #self.detail_panel_widgets + 1

    self.detail_scroll_list = self.server_detail_panel:AddChild(ScrollableList(self.detail_panel_widgets, 180, 265, 35, 10, nil, nil, nil, nil, nil, nil, -10))
    self.detail_scroll_list:SetPosition(90,-80)
    self.detail_scroll_list:Hide()
end

local function MakeHeader(self, parent, xPos, name, onclick)

    local root_y_offset = 3
    local text_x_offset = -5
    local text_y_offset = 13
    local frame_color = {0, 0, 0, 1}
    local arrow_x_offset = 6.5
    local arrow_y_offset = 14
    local bg_y_scale = 14
    local bg_x_offset = 10

    local header = parent:AddChild(Widget("control"))
    header:SetPosition(xPos, root_y_offset)
    header.text = header:AddChild(Text(BUTTONFONT, font_size, name))
    header.text:SetPosition(text_x_offset,text_y_offset,0)
    header.text:SetColour(frame_color[1], frame_color[2], frame_color[3], frame_color[4])
    header.bg = header.text:AddChild(ImageButton("images/ui.xml", "blank.tex", "blank.tex", "blank.tex"))
    header.bg:MoveToBack()
    header.arrow = header:AddChild(Image("images/ui.xml", "arrow2_down.tex"))
    header.arrow.ascending = true
    header.arrow:SetScale(.33)
    header.arrow:SetPosition(header.text:GetRegionSize()/2 + arrow_x_offset + 4, arrow_y_offset, 0)
    header.arrow:SetClickable(false)
    header.arrow:Hide()
    if name == STRINGS.UI.SERVERLISTINGSCREEN.NAME then
        header.bg:SetScale((header.text:GetRegionSize()/2 + arrow_x_offset)*3.1,bg_y_scale,1)
        header.bg:SetPosition(bg_x_offset+100,3,0)
    elseif name == STRINGS.UI.SERVERLISTINGSCREEN.DETAILS then
        header.bg:SetScale(header.text:GetRegionSize()/2 + arrow_x_offset,bg_y_scale,1)
        header.bg:SetPosition(bg_x_offset,3,0)
    elseif name == STRINGS.UI.SERVERLISTINGSCREEN.PLAYERS then
        header.bg:SetScale((header.text:GetRegionSize()/2 + arrow_x_offset)*1,bg_y_scale,1)
        header.bg:SetPosition(bg_x_offset+10,3,0)
    else
        header.bg:SetScale((header.text:GetRegionSize()/2 + arrow_x_offset)*1.5+3,bg_y_scale,1)
        header.bg:SetPosition(bg_x_offset+20,3,0)
    end

    header.bg.OnGainFocus =
        function()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
            header.text:SetFont(UIFONT)
            header.text:SetColour(1,1,1,1)
            if header.arrow.ascending then
                header.arrow:SetTexture("images/ui.xml", "arrow2_up_over.tex")
            else
                header.arrow:SetTexture("images/ui.xml", "arrow2_down_over.tex")
            end
        end
    header.bg.OnLoseFocus =
        function()
            if self.sort_column == string.upper(name) then
                header.text:SetColour(0,0,0,1)
                -- header.text:SetColour(.4,.4,.4,1)
            else
                header.text:SetColour(frame_color[1], frame_color[2], frame_color[3], frame_color[4])
            end
            header.text:SetFont(BUTTONFONT)
            if header.arrow.ascending then
                header.arrow:SetTexture("images/ui.xml", "arrow2_up.tex")
            else
                header.arrow:SetTexture("images/ui.xml", "arrow2_down.tex")
            end
        end
    header.bg:SetOnClick( onclick )

    return header
end

function ServerListingScreen:MakeColumnHeaders()
    self.title = self.server_list_titles:AddChild(Text(BUTTONFONT, 40, STRINGS.UI.SERVERLISTINGSCREEN.SERVER_LIST_TITLE.." (0)"))
    self.title:SetColour(0,0,0,1)
    self.title:SetPosition(column_offsets.DETAILS+20,70)

    self.NAME = MakeHeader(self, self.server_list_titles, column_offsets.NAME, STRINGS.UI.SERVERLISTINGSCREEN.NAME, function() self:SetSort("NAME") end)
    self.DETAILS = MakeHeader(self, self.server_list_titles, column_offsets.DETAILS, STRINGS.UI.SERVERLISTINGSCREEN.DETAILS, function() self:SetSort("DETAILS") end)
    self.PLAYERS = MakeHeader(self, self.server_list_titles, column_offsets.PLAYERS+4, STRINGS.UI.SERVERLISTINGSCREEN.PLAYERS, function() self:SetSort("PLAYERS") end)
    self.PING = MakeHeader(self, self.server_list_titles, column_offsets.PING, STRINGS.UI.SERVERLISTINGSCREEN.PING, function() self:SetSort("PING") end)

    self.DETAILS:SetClickable(false) -- No sorting on Details since filters kind of cover your bases there

    self.column_buttons = {
        NAME = self.NAME,
        DETAILS = self.DETAILS,
        PLAYERS = self.PLAYERS,
        PING = self.PING
    }
end

return ServerListingScreen
