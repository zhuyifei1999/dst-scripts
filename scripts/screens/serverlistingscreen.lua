local Screen = require "widgets/screen"
local AnimButton = require "widgets/animbutton"
local ImageButton = require "widgets/imagebutton"
local TextButton = require "widgets/textbutton"
local Button = require "widgets/button"
local InputDialogScreen = require "screens/inputdialog"
local PopupDialogScreen = require "screens/popupdialog"
local TextListPopupDialogScreen = require "screens/textlistpopupdialog"
local ListCursor = require "widgets/listcursor"
local TEMPLATES = require "widgets/templates"

local Text = require "widgets/text"
local Image = require "widgets/image"

local Spinner = require "widgets/spinner"
local NumericSpinner = require "widgets/numericspinner"
local TextEdit = require "widgets/textedit"

local Widget = require "widgets/widget"
local Levels = require "map/levels"

local ScrollableList = require "widgets/scrollablelist"

local ViewCustomizationModalScreen = require "screens/viewcustomizationmodalscreen"
local ViewPlayersModalScreen = require "screens/viewplayersmodalscreen"

local OnlineStatus = require "widgets/onlinestatus"

require("constants")

local listings_per_view = 13
local listings_per_scroll = 10
local list_spacing = 37.5

local filters_per_page = 6

local column_offsets_x_pos = -RESOLUTION_X*0.18;
local column_offsets_y_pos = RESOLUTION_Y*0.23;

local column_offsets ={ 
        NAME = -92,  
        DETAILS = 238,  
        PLAYERS = 413,
        PING = 509,        
    }

local dev_color = {80/255, 16/255, 158/255, 1}
local mismatch_color = {130/255, 19/255, 19/255, 1}

local font_size = 35
if JapaneseOnPS4() then
    font_size = 35 * 0.75;
end

local VALID_CHARS = [[ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:;[]\@!#$%&()'*+-/=?^_{|}~"]]
local STRING_MAX_LENGTH = 254 -- http://tools.ietf.org/html/rfc5321#section-4.5.3.1

local hover_text_params = { font = NEWFONT, size = 20, offset_x = -4, offset_y = 45, colour = {0,0,0,1} }

local ServerListingScreen = Class(Screen, function(self, filters, cb, offlineMode, session_mapping)
    Widget._ctor(self, "ServerListingScreen")

    self.bg = self:AddChild(TEMPLATES.AnimatedPortalBackground())

    self.fg = self:AddChild(TEMPLATES.AnimatedPortalForeground())

    -- Query all data related to user sessions
    self.session_mapping = session_mapping

    self.cb = cb
    self.offlinemode = offlineMode

    self.tickperiod = 0.5
    self.task = nil

    self.unjoinable_servers = 0
    
    self.root = self:AddChild(Widget("scaleroot"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.online = true

    local nav_col = -RESOLUTION_X*.415
    local left_col = -RESOLUTION_X*.047
    local right_col = RESOLUTION_X*.40

    self.menu_bg = self.root:AddChild(TEMPLATES.LeftGradient())

    self.server_list_frame = self.root:AddChild(Image("images/serverbrowser.xml", "frame.tex"))
    self.server_list_frame:SetPosition(75,-20)
    self.server_list_frame:SetScale(.66, .65)

    self.server_list = self.root:AddChild(Widget("server_list"))
    self.server_list:SetPosition(left_col,-15,0)    

    self.server_list_grid = self.server_list:AddChild(Image("images/options_bg.xml", "options_panel_bg.tex"))
    self.server_list_grid:SetScale(-.563,.66)
    self.server_list_grid:SetPosition(0,-5)

    self.server_list_bgs = self.server_list:AddChild(Widget("server_list_rows"))
    self.server_list_bgs:SetPosition(column_offsets_x_pos, -RESOLUTION_Y*0.075, 0)

    local vertical_line_y_offset = -35
    local slide = 280
    self.upper_horizontal_line = self.server_list:AddChild(Image("images/ui.xml", "line_horizontal_5.tex"))
    self.upper_horizontal_line:SetScale(.565, .66)
    self.upper_horizontal_line:SetPosition(-20, column_offsets_y_pos+22, 0)

    self.lower_horizontal_line = self.server_list:AddChild(Image("images/ui.xml", "line_horizontal_5.tex"))
    self.lower_horizontal_line:SetScale(.565, .66)
    self.lower_horizontal_line:SetPosition(-20, column_offsets_y_pos-11, 0)

    self.first_column_end = self.server_list:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
    self.first_column_end:SetScale(.66, .66)
    self.first_column_end:SetPosition(column_offsets.DETAILS-slide-10,vertical_line_y_offset, 0)

    self.second_column_end = self.server_list:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
    self.second_column_end:SetScale(.66, .66)
    self.second_column_end:SetPosition(column_offsets.PLAYERS-slide+1, vertical_line_y_offset, 0)

    self.third_column_end = self.server_list:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
    self.third_column_end:SetScale(.66, .66)
    self.third_column_end:SetPosition(column_offsets.PING-slide+15, vertical_line_y_offset, 0)
   
    self.server_list_titles = self.server_list:AddChild(Widget("server_list_titles"))
    self.server_list_titles:SetPosition(column_offsets_x_pos, column_offsets_y_pos, 0)

    self.nav_bar = self.root:AddChild(TEMPLATES.NavBarWithScreenTitle(STRINGS.UI.MAINSCREEN.BROWSE, "short"))

    self:MakeColumnHeaders()

    self.sort_ascending = nil
    self.sort_column = nil
    self:SetSort("DETAILS")

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

    self:MakeDetailPanel(right_col)

    self:MakeMenuButtons(left_col, right_col, nav_col)

    self:MakeFiltersPanel(filters)

    self.onlinestatus = self.root:AddChild(OnlineStatus())
    
    self:UpdateServerInformation(false)
    self:ToggleShowFilters()

    if self.offlinemode then
        self:SetTab("LAN")
    else
        self:SetTab("online")
    end
    self:RefreshView(false)

    self.servers_scroll_list:SetFocusChangeDir(MOVE_LEFT, function() return self.online_button end)
    self.filters_scroll_list:SetFocusChangeDir(MOVE_LEFT, function() return self.servers_scroll_list end)
    self.server_details_parent:SetFocusChangeDir(MOVE_LEFT, function() return self.servers_scroll_list end)-- self.detail_scroll_list:SetFocusChangeDir(MOVE_LEFT, self.servers_scroll_list)

    self.default_focus = self.online_button
end)

function ServerListingScreen:SetTab(tab)
    if tab == "LAN" then
        self.page = "LAN"
        self:SearchForServers(false)
        self.lan_button:Select()
        self.online_button:Unselect()
    elseif tab == "online" then
        self.page = "online"
        self:SearchForServers(true)
        self.lan_button:Unselect()
        self.online_button:Select()
    end
end

function ServerListingScreen:UpdateServerInformation( show )
	if show then
        if self.filters_shown then
            self:ToggleShowFilters(true)
        end
        self.details_servername:Show()
        self.details_serverdesc:Show()
        if self.selected_server ~= nil then
            self.server_details_parent:Show()-- self.detail_scroll_list:Show()
        end
	else
        if self.filters_shown then
		    self.details_servername:Hide()
            self.details_serverdesc:Hide()
        end
        self.server_details_parent:Hide()-- self.detail_scroll_list:Hide()
	end
end

function ServerListingScreen:ToggleShowFilters(forcehide)
    if not self.filters_shown and not forcehide then
        self.filters_shown = true
        self:UpdateServerInformation( false )
        self.filters_button:Disable()
        if TheInput:ControllerAttached() and self.server_details_parent.focus then--self.detail_scroll_list.focus then
            self.filters_scroll_list:SetFocus()
        end
        self.details_button:Enable()
        self.filters_scroll_list:Show()
        self.server_details_parent:Hide()--self.detail_scroll_list:Hide()
    else
        self.filters_scroll_list:Hide()
        if self.selected_server ~= nil then 
            self.server_details_parent:Show()--self.detail_scroll_list:Show() 
        end
        if TheInput:ControllerAttached() and self.filters_scroll_list.focus then
            self.server_details_parent:SetFocus()--self.detail_scroll_list:SetFocus()
        end
        self.filters_shown = false
        self.filters_button:Enable()
        self.details_button:Disable()
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
                                                text = STRINGS.UI.SERVERLISTINGSCREEN.OK, 
                                                cb = function()
                                                    TheNet:ReportListing(guid, InputDialogScreen:GetText())
                                                    TheFrontEnd:PopScreen()
                                                end
                                            },
                                                                                        {
                                                text = STRINGS.UI.SERVERLISTINGSCREEN.CANCEL, 
                                                cb = function()
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

local function SetChecked( widget, label, check )
	if check then
        label:SetColour(0,0,0,1)
        widget.off_image:Hide()
        widget.bg:Show()
        widget.img:Show()
	else
        label:SetColour(.4,.4,.4,1)
        widget.off_image:Show()
        widget.bg:Hide()
        widget.img:Hide()
	end
end

function ServerListingScreen:ViewServerMods()
    if self.selected_server ~= nil and self.selected_server.mods_enabled then
        local success = false
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
			else
                success = true
            end
		end
		
        if success then
            TheFrontEnd:PushScreen(TextListPopupDialogScreen(STRINGS.UI.SERVERLISTINGSCREEN.MODSTITLE, mods_list))
        else
            TheFrontEnd:PushScreen(PopupDialogScreen(
                    STRINGS.UI.SERVERLISTINGSCREEN.MODSTITLE, 
                    mods_list, 
                    {{ text = STRINGS.UI.SERVERLISTINGSCREEN.OK, cb = function() TheFrontEnd:PopScreen() end }}))
        end
    end
end

function ServerListingScreen:ViewServerTags()
    if self.selected_server ~= nil and self.selected_server.tags then            
        TheFrontEnd:PushScreen(TextListPopupDialogScreen(STRINGS.UI.SERVERLISTINGSCREEN.TAGSTITLE, self.selected_server.tags))
    end
end

function ServerListingScreen:ViewServerWorld()
    local worldgenoptions = self:ProcessServerWorldGenData()
    if worldgenoptions ~= nil then
        TheFrontEnd:PushScreen(ViewCustomizationModalScreen(Profile, worldgenoptions, false, false))
    end
end

function ServerListingScreen:ViewServerPlayers() 
    local players = self:ProcessServerPlayersData()
    if players ~= nil then
        TheFrontEnd:PushScreen(ViewPlayersModalScreen(players, self.selected_server.max_players))
    end
end

function ServerListingScreen:ProcessServerGameData()
    if self.selected_server == nil then
        return
    elseif self.selected_server._processed_game_data == nil
        and self.selected_server.game_data ~= nil
        and #self.selected_server.game_data > 0 then
        local success, data = RunInSandboxSafe(self.selected_server.game_data)
        if success and data ~= nil then
            self.selected_server._processed_game_data = data
        end
    end
    return self.selected_server._processed_game_data
end

function ServerListingScreen:ProcessServerWorldGenData()
    if self.selected_server == nil then
        return
    elseif self.selected_server._processed_world_gen_data == nil
        and self.selected_server.world_gen_data ~= nil
        and #self.selected_server.world_gen_data > 0 then
        local success, data = RunInSandboxSafe(self.selected_server.world_gen_data)
        if success and data ~= nil then
            self.selected_server._processed_world_gen_data = data
        end
    end
    return self.selected_server._processed_world_gen_data
end

function ServerListingScreen:ProcessServerPlayersData()
    if self.selected_server == nil then
        return
    elseif self.selected_server._processed_players_data == nil
        and self.selected_server.players_data ~= nil
        and #self.selected_server.players_data > 0 then
        local success, data = RunInSandboxSafe(self.selected_server.players_data)
        if success and data ~= nil then
            for i, v in ipairs(data) do
                if v.colour ~= nil then
                    local colourstr = "00000"..v.colour
                    local r = tonumber(colourstr:sub(-6, -5), 16) / 255
                    local g = tonumber(colourstr:sub(-4, -3), 16) / 255
                    local b = tonumber(colourstr:sub(-2), 16) / 255
                    v.colour = { r, g, b, 1 }
                end
            end
            self.selected_server._processed_players_data = data
        end
    end
    return self.selected_server._processed_players_data
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

        --A bunch of gross string processing so that servers with a single token that is wider than 240 still show a server name
        local nameString = self.selected_server.name
        -- Check if the server's name is long enough that we need to even do this
        local truncLen = TheFrontEnd:FindLengthForTruncatedString(nameString, self.details_servername.font, self.details_servername.size, 240)
        if truncLen < nameString:len() then
            local i = 1
            local spaceInd = truncLen

            -- Find the last space in the part of the string that fits on the first line
            -- This is a natural breakpoint for splitting the string
            while i < truncLen do
                if nameString:sub(i, i) == " " then
                    spaceInd = i
                end
                i = i+1
            end

            -- Grab the back half of the string and shorten it as necessary
            local nameString2 = nameString:sub(spaceInd+1)
            nameString2 = TheFrontEnd:GetTruncatedString(nameString2, self.details_servername.font, self.details_servername.size, 240, nil, true)

            if nameString:sub(spaceInd,spaceInd) == " " then
                -- If we found a natural break point, don't insert a newline
                nameString = nameString:sub(1, spaceInd)..nameString2
            else
                -- But if we didn't, we need to insert a newline so that it renders at all
                nameString = nameString:sub(1, spaceInd).."\n"..nameString2
            end
        end
        self.details_servername:SetString( nameString )
        self.details_serverdesc:SetString( self.selected_server.has_details and (self.selected_server.description ~= "" and self.selected_server.description or STRINGS.UI.SERVERLISTINGSCREEN.NO_DESC) or STRINGS.UI.SERVERLISTINGSCREEN.DESC_LOADING )
        
        self.game_mode_description.text:SetString( GetGameModeString( self.selected_server.mode ) )
        local w,h = self.game_mode_description.text:GetRegionSize()
        self.game_mode_description.info_button.o_pos = nil --wipe the o_pos in case it's been clicked and got set
        self.game_mode_description.info_button:SetPosition(w/2 + 7, -2)
        if self.selected_server.mode ~= "" then
            self.game_mode_description.info_button:Unselect()
        else
            self.game_mode_description.info_button:Select()
        end

        SetChecked( self.checkbox_dedicated_server, self.dedicated_server_description, self.selected_server.dedicated )
        SetChecked( self.checkbox_pvp, self.pvp_description, self.selected_server.pvp )
        SetChecked( self.checkbox_has_password, self.has_password_description, self.selected_server.has_password )

        if self.selected_server.mods_enabled then
            if self.page == "LAN" then
                self.viewmods_button:SetHoverText(STRINGS.UI.SERVERLISTINGSCREEN.VIEWMODS_LAN)
                self.viewmods_button:Select()
            else
                self.viewmods_button:SetHoverText(STRINGS.UI.SERVERLISTINGSCREEN.VIEWMODS)
                self.viewmods_button:Unselect()
            end
        else
            if self.selected_server.has_details then
                self.viewmods_button:SetHoverText(STRINGS.UI.SERVERLISTINGSCREEN.NOMODS)
            else
                self.viewmods_button:SetHoverText(STRINGS.UI.SERVERLISTINGSCREEN.MODS_LOADING)
            end
            self.viewmods_button:Select()
        end

        if self.selected_server.tags ~= "" then
            self.viewtags_button:SetHoverText(STRINGS.UI.SERVERLISTINGSCREEN.VIEWTAGS)
            self.viewtags_button:Unselect()
        else
            if self.selected_server.has_details then
                self.viewtags_button:SetHoverText(STRINGS.UI.SERVERLISTINGSCREEN.NOTAGS)
            else
                self.viewtags_button:SetHoverText(STRINGS.UI.SERVERLISTINGSCREEN.TAGS_LOADING)
            end
            self.viewtags_button:Select()
        end

        local gamedata = self:ProcessServerGameData()
        local day = gamedata ~= nil and gamedata.day or STRINGS.UI.SERVERLISTINGSCREEN.UNKNOWN
        self.day_description.text:SetString(STRINGS.UI.SERVERLISTINGSCREEN.DAYDESC..day)

        local seasondesc = self.selected_server.season ~= nil and STRINGS.UI.SERVERLISTINGSCREEN.SEASONS[string.upper(self.selected_server.season)] or nil
        if seasondesc ~= nil and
            gamedata ~= nil and
            gamedata.daysleftinseason ~= nil and
            gamedata.dayselapsedinseason ~= nil then

            if gamedata.daysleftinseason * 3 <= gamedata.dayselapsedinseason then
                seasondesc = STRINGS.UI.SERVERLISTINGSCREEN.LATE_SEASON_1..seasondesc..STRINGS.UI.SERVERLISTINGSCREEN.LATE_SEASON_2
            elseif gamedata.dayselapsedinseason * 3 <= gamedata.daysleftinseason then
                seasondesc = STRINGS.UI.SERVERLISTINGSCREEN.EARLY_SEASON_1..seasondesc..STRINGS.UI.SERVERLISTINGSCREEN.EARLY_SEASON_2
            end
        end
        self.season_description.text:SetString(seasondesc or STRINGS.UI.SERVERLISTINGSCREEN.UNKNOWN_SEASON)

        local worldgenoptions = self:ProcessServerWorldGenData()
        if worldgenoptions ~= nil then
            self.viewworld_button:Unselect()
            self.viewworld_button:SetHoverText(STRINGS.UI.SERVERLISTINGSCREEN.VIEWWORLD)
        else
            self.viewworld_button:Select()
            self.viewworld_button:SetHoverText(self.selected_server.has_details and STRINGS.UI.SERVERLISTINGSCREEN.WORLD_UNKNOWN or STRINGS.UI.SERVERLISTINGSCREEN.WORLD_LOADING)
        end

        local players = self:ProcessServerPlayersData()
        if players ~= nil then
            self.viewplayers_button:Unselect()
            self.viewplayers_button:SetHoverText(STRINGS.UI.SERVERLISTINGSCREEN.VIEWPLAYERS)
        else
            self.viewplayers_button:Select()
            self.viewplayers_button:SetHoverText(self.selected_server.has_details and STRINGS.UI.SERVERLISTINGSCREEN.PLAYERS_UNKNOWN or STRINGS.UI.SERVERLISTINGSCREEN.PLAYERS_LOADING)
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
        v.NAME:SetPosition(v.NAME._align.x, v.NAME._align.y, 0)
        v.CHAR:Hide()
        v.FRIEND_ICON:Hide()
        v.CLAN_OPEN_ICON:Hide()
        v.CLAN_CLOSED_ICON:Hide()
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

function ServerListingScreen:SearchForServers(online)
    self:ServerSelected(nil)
    self.servers = {}
    self.viewed_servers = {}
    self:RefreshView()
    self:ClearServerList()
    local num_servs = #self.servers-self.unjoinable_servers
    if num_servs < 0 then num_servs = 0 end
    self.servers_scroll_list:SetList(self.viewed_servers)

    if online ~= nil then
        self.online = online
    end

    if num_servs == 0 then
        self.server_count:SetString("("..STRINGS.UI.SERVERLISTINGSCREEN.SEARCHING_SERVERS..")")
    else
        self.server_count:SetString("("..#self.viewed_servers.." "..STRINGS.UI.SERVERLISTINGSCREEN.OUT_OF.." "..num_servs.." "..STRINGS.UI.SERVERLISTINGSCREEN.SHOWING..")")
    end
    if self.page == "online" and self.offlinemode then
        self.server_count:SetString("("..STRINGS.UI.SERVERLISTINGSCREEN.NO_CONNECTION..")")
    elseif not self.online then
        self.server_count:SetString("("..STRINGS.UI.SERVERLISTINGSCREEN.LAN..")")
    end
    
    for i,v in pairs(self.filters) do
        if v.name == "VERSIONCHECK" then
            local version_check = v.spinner:GetSelectedData()
			TheNet:SetCheckVersionOnQuery( version_check )
        end
    end

    if self.online and not self.offlinemode then -- search LAN and online if online
        self.servers_scroll_list.focused_index = 1
        TheNet:SearchServers()
    elseif self.page == "LAN" then -- otherwise just LAN
        self.servers_scroll_list.focused_index = 1
        TheNet:SearchLANServers()
    end
    
	self:StartPeriodicRefreshTask()
	self:RefreshView(true)
end

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
    -- If we're fading, don't mess with stuff
    if TheFrontEnd:GetFadeLevel() > 0 then return end

    if TheNet:IsSearchingServers() then
        self.refresh_button:Disable()
        self.refresh_button:SetHoverText(STRINGS.UI.SERVERLISTINGSCREEN.REFRESHING)
        --if self.lan_spinner then self.lan_spinner.spinner:Disable() end
    else
        self.refresh_button:Enable()
        self.refresh_button:SetHoverText(STRINGS.UI.SERVERLISTINGSCREEN.REFRESH)
        local num_servs = #self.servers-self.unjoinable_servers
        if num_servs < 0 then num_servs = 0 end
        self.server_count:SetString("("..#self.viewed_servers.." "..STRINGS.UI.SERVERLISTINGSCREEN.OUT_OF.." "..num_servs.." "..STRINGS.UI.SERVERLISTINGSCREEN.SHOWING..")")
        if not self.online then
            self.server_count:SetString("("..STRINGS.UI.SERVERLISTINGSCREEN.LAN..")")
        end
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

    local bg_y_offset = -215
    for i=1, listings_per_view do        
        local row = self.server_list_rows:AddChild(Widget("server_list_row"))

        local font_size = font_size * .7
        local y_offset = 15

        if i%2 == 1 then
            local bg = self.server_list_bgs:AddChild(Image("images/serverbrowser.xml", "whitebar.tex"))
            bg:SetScale(.7,.7)
            bg:SetPosition( 213, bg_y_offset+(i*30)+y_offset-1, 0)
            bg:SetTint(1,1,1,.7)
            bg:MoveToBack()
        end

        row.index = -1

        row.cursor = row:AddChild( ListCursor() )
        row.cursor:SetPosition( 221, y_offset-1, 0)
        row.cursor:SetOnDown(  function() self:OnStartClickServerInList(i)  end)
        row.cursor:SetOnClick( function() self:OnFinishClickServerInList(i) end)
        row.cursor:Hide()
        
        row.NAME = row:AddChild(Text(NEWFONT, font_size))
        row.NAME:SetHAlign(ANCHOR_MIDDLE)
        row.NAME:SetString("")
        row.NAME._align =
        {
            maxwidth = 300,
            maxchars = 80,
            x = column_offsets.NAME - 25,
            y = y_offset,
        }
        row.NAME:SetPosition(row.NAME._align.x, row.NAME._align.y, 0)
        
        row.DETAILS = row.cursor:AddChild(Widget("detail_icons"))
        row.DETAILS:SetPosition(column_offsets.DETAILS-200, -1, 0)

        local details_x = -56

        row.HAS_PASSWORD_ICON = row.DETAILS:AddChild(TEMPLATES.ServerDetailIcon("images/servericons.xml", "password.tex", "rust", STRINGS.UI.SERVERLISTINGSCREEN.PASSWORD_ICON_HOVER, nil, {-1,0}, .08, .073))
        row.HAS_PASSWORD_ICON:SetPosition(details_x,1)
        row.HAS_PASSWORD_ICON:Hide()
        details_x = details_x + 26

        row.DEDICATED_ICON = row.DETAILS:AddChild(TEMPLATES.ServerDetailIcon("images/servericons.xml", "dedicated.tex", "burnt", STRINGS.UI.SERVERLISTINGSCREEN.DEDICATED_ICON_HOVER, nil, {0,0}, .08, .073))
        row.DEDICATED_ICON:SetPosition(details_x,1)
        row.DEDICATED_ICON:Hide()
        details_x = details_x + 26

        row.MODS_ENABLED_ICON = row.DETAILS:AddChild(TEMPLATES.ServerDetailIcon("images/servericons.xml", "mods.tex", "orange", STRINGS.UI.SERVERLISTINGSCREEN.MODS_ICON_HOVER, nil, {0,0}, .077, .077))
        row.MODS_ENABLED_ICON:SetPosition(details_x,1)
        row.MODS_ENABLED_ICON:Hide()
        details_x = details_x + 26

        row.PVP_ICON = row.DETAILS:AddChild(TEMPLATES.ServerDetailIcon("images/servericons.xml", "pvp.tex", "brown", STRINGS.UI.SERVERLISTINGSCREEN.PVP_ICON_HOVER, nil, {0,0}, .075, .075))
        row.PVP_ICON:SetPosition(details_x,1)
        row.PVP_ICON:Hide()
        details_x = details_x + 26

        local bgColor = "yellow"--"beige"
        row.CHAR = row.DETAILS:AddChild(Widget("char"))
        row.CHAR_ICON_BG = row.CHAR:AddChild(Image("images/servericons.xml", "bg_"..bgColor..".tex" or "bg_burnt.tex"))
        row.CHAR_ICON_BG:SetScale(.09)
        row.CHAR_ICON = row.CHAR:AddChild(Image("images/saveslot_portraits.xml", "unknown.tex"))
        row.CHAR_ICON:SetScale(.21, .22, 1)
        row.CHAR:SetHoverText(STRINGS.UI.SERVERLISTINGSCREEN.CHAR_AGE_1.."0"..STRINGS.UI.SERVERLISTINGSCREEN.CHAR_AGE_2, { font = NEWFONT_OUTLINE, size = 22, offset_x = 1, offset_y = 28, colour = {1,1,1,1} })
        row.CHAR:SetPosition(details_x,1)
        row.CHAR:Hide()
        details_x = details_x + 27

        row.FRIEND_ICON = row.DETAILS:AddChild(TEMPLATES.ServerDetailIcon("images/servericons.xml", "friend.tex", "green", STRINGS.UI.SERVERLISTINGSCREEN.FRIEND_ICON_HOVER, nil, {0,0}, .075, .08))
        row.FRIEND_ICON:SetPosition(details_x,1)
        row.FRIEND_ICON:Hide()
        details_x = details_x + 26
        
        row.CLAN_OPEN_ICON = row.DETAILS:AddChild(TEMPLATES.ServerDetailIcon("images/servericons.xml", "group.tex", "blue", STRINGS.UI.SERVERLISTINGSCREEN.CLAN_OPEN_ICON_HOVER, nil, {0,0}, .075, .075))
        row.CLAN_OPEN_ICON:SetPosition(details_x,1)
        row.CLAN_OPEN_ICON:Hide()
        
        row.CLAN_CLOSED_ICON = row.DETAILS:AddChild(TEMPLATES.ServerDetailIcon("images/servericons.xml", "group.tex", "blue", STRINGS.UI.SERVERLISTINGSCREEN.CLAN_CLOSED_ICON_HOVER, nil, {0,0}, .075, .075))
        row.CLAN_CLOSED_ICON.img:SetTint(238/255, 99/255, 99/255, 255/255)
        row.CLAN_CLOSED_ICON:SetPosition(details_x,1)
        row.CLAN_CLOSED_ICON:Hide()
        details_x = details_x + 26

        row.PLAYERS = row:AddChild(Text(BUTTONFONT, font_size))
        row.PLAYERS = row:AddChild(Text(NEWFONT, font_size))
        row.PLAYERS:SetHAlign(ANCHOR_MIDDLE)
        row.PLAYERS:SetPosition(column_offsets.PLAYERS + 20, y_offset, 0)
        row.PLAYERS:SetRegionSize( 400, 70 )
        row.PLAYERS:SetString("")

        row.PING = row:AddChild(Text(NEWFONT, font_size))
        row.PING:SetHAlign(ANCHOR_MIDDLE)
        row.PING:SetPosition(column_offsets.PING + 20, y_offset, 0)
        row.PING:SetRegionSize( 400, 70 )
        row.PING:SetString("")  

        row.focus_forward = row.cursor

        row:SetFocusChangeDir(MOVE_RIGHT, function() 
            if self.filters_scroll_list:IsVisible() then
                return self.filters_scroll_list
            elseif self.server_details_parent:IsVisible() then--self.detail_scroll_list:IsVisible() then
                return self.viewworld_button
            end
        end)
        row:SetFocusChangeDir(MOVE_LEFT, function() return self.online_button end)

        table.insert(self.list_widgets, row)--, id=i})    
    end

    local function UpdateServerListWidget(widget, serverdata)
        if not widget then return end
                
        if not serverdata then
            widget.index = -1
            widget.NAME:SetString("")
            widget.NAME:SetPosition(widget.NAME._align.x, widget.NAME._align.y, 0)
            widget.PLAYERS:SetString("")
            widget.PING:SetString("")
            widget.CHAR:Hide()
            widget.FRIEND_ICON:Hide()
            widget.CLAN_OPEN_ICON:Hide()
            widget.CLAN_CLOSED_ICON:Hide()
            widget.HAS_PASSWORD_ICON:Hide()
            widget.DEDICATED_ICON:Hide()
            widget.PVP_ICON:Hide()
            widget.MODS_ENABLED_ICON:Hide()
            widget.cursor:Hide()
            widget.cursor:Disable()
            widget:Disable()
        else
            widget:Enable()
            widget.cursor:Enable()

            local dev_server = serverdata.version == -1
            local version_check_failed = serverdata.version ~= tonumber(APP_VERSION)

            local font_size = font_size * .8
            local y_offset = 15

            widget.index = serverdata.actualindex --actual index is wrong

            widget.version = serverdata.version

            widget.cursor:Show()
            
            widget.NAME:SetTruncatedString(serverdata.name, widget.NAME._align.maxwidth, widget.NAME._align.maxchars, true)
            local w, h = widget.NAME:GetRegionSize()
            widget.NAME:SetPosition(widget.NAME._align.x + w * .5, widget.NAME._align.y, 0)
            if dev_server then widget.NAME:SetColour(unpack(dev_color))
            elseif version_check_failed then widget.NAME:SetColour(unpack(mismatch_color)) end

            self:ProcessPlayerData( serverdata.session )
	    
            if self.sessions[serverdata.session] ~= nil and self.sessions[serverdata.session] ~= false then
                local playerdata = self.sessions[serverdata.session]
                local character = playerdata.prefab or ""
                local atlas = "images/saveslot_portraits"
                if not table.contains(DST_CHARACTERLIST, character) then
                    if table.contains(MODCHARACTERLIST, character) then
                        atlas = atlas.."/"..character
                    else
                        character = #character > 0 and "mod_small" or "unknown"
                    end
                end
                atlas = atlas..".xml"
                widget.CHAR_ICON:SetTexture(atlas, character..".tex")
                local age = playerdata.age or "???"
                widget.CHAR:SetHoverText(STRINGS.UI.SERVERLISTINGSCREEN.CHAR_AGE_1..age..STRINGS.UI.SERVERLISTINGSCREEN.CHAR_AGE_2)
                widget.CHAR:Show()
            else
                widget.CHAR:Hide()
            end
            
            if serverdata.friend_playing then 
                widget.FRIEND_ICON:Show()
            else
                widget.FRIEND_ICON:Hide()
            end
            if serverdata.clan_server and serverdata.belongs_to_clan then
                if serverdata.clan_only then
                    widget.CLAN_OPEN_ICON:Hide()
                    widget.CLAN_CLOSED_ICON:Show()
                else
                    widget.CLAN_OPEN_ICON:Show()
                    widget.CLAN_CLOSED_ICON:Hide()
                end
            else
                widget.CLAN_OPEN_ICON:Hide()
                widget.CLAN_CLOSED_ICON:Hide()
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
            if dev_server then widget.PLAYERS:SetColour(unpack(dev_color))
            elseif version_check_failed then widget.PLAYERS:SetColour(unpack(mismatch_color)) end

            widget.PING:SetString(serverdata.ping)  
            if serverdata.ping < 0 then
                widget.PING:SetString("???")
            end
            if dev_server then widget.PING:SetColour(unpack(dev_color))
            elseif version_check_failed then widget.PING:SetColour(unpack(mismatch_color)) end 
        end
    end

    self.servers_scroll_list = self.server_list_titles:AddChild(ScrollableList(self.viewed_servers, 320, 385, 20, 10, UpdateServerListWidget, self.list_widgets, 150, true))
    self.servers_scroll_list:SetPosition(418, -207)
    self.servers_scroll_list:LayOutStaticWidgets(3, true)
    self.servers_scroll_list.onscrollcb = function()
        self:GuaranteeSelectedServerHighlighted()
    end
    for i,v in pairs(self.list_widgets) do
        if v and v.cursor then
            v.cursor:SetParentList(self.servers_scroll_list)
        end
    end

    self.first_column_end:MoveToFront()
    self.second_column_end:MoveToFront()
    self.third_column_end:MoveToFront()
    self.server_list_rows:MoveToFront()
end

function ServerListingScreen:GuaranteeSelectedServerHighlighted()
    for i,v in pairs(self.list_widgets) do
        local dev_server = v.version and v.version == -1 or false
        local version_check_failed = v.version and v.version ~= tonumber(APP_VERSION) or false
		if v and v.index ~= -1 and v.index == self.selected_index_actual then
            if dev_server then 
                v.NAME:SetColour(unpack(dev_color))
                v.PLAYERS:SetColour(unpack(dev_color))
                v.PING:SetColour(unpack(dev_color))
            elseif version_check_failed then 
                v.NAME:SetColour(unpack(mismatch_color))
                v.PLAYERS:SetColour(unpack(mismatch_color))
                v.PING:SetColour(unpack(mismatch_color))
            else
                v.NAME:SetFont(NEWFONT)
                v.PLAYERS:SetFont(NEWFONT)
                v.PING:SetFont(NEWFONT)
                v.NAME:SetColour(0,0,0,1)
                v.PLAYERS:SetColour(0,0,0,1)
                v.PING:SetColour(0,0,0,1)
            end
            v.cursor:SetSelected(true)
        else
            v.NAME:SetFont(NEWFONT)
            v.PLAYERS:SetFont(NEWFONT)
            v.PING:SetFont(NEWFONT)
            if dev_server then 
                v.NAME:SetColour(unpack(dev_color))
                v.PLAYERS:SetColour(unpack(dev_color))
                v.PING:SetColour(unpack(dev_color))
            elseif version_check_failed then
                v.NAME:SetColour(unpack(mismatch_color))
                v.PLAYERS:SetColour(unpack(mismatch_color))
                v.PING:SetColour(unpack(mismatch_color))
            else
                v.NAME:SetColour(0,0,0,1)
                v.PLAYERS:SetColour(0,0,0,1)
                v.PING:SetColour(0,0,0,1)
            end
            v.cursor:SetSelected(false)
        end
    end
end

function ServerListingScreen:CycleColumnSort()
    if self.sort_ascending then
        self:SetSort(self.sort_column)
    else
        if self.sort_column == "DETAILS" then
            self:SetSort("PLAYERS")    
        elseif self.sort_column == "PLAYERS" then
            self:SetSort("PING")
        elseif self.sort_column == "PING" then
            self:SetSort("NAME")
        else
            self:SetSort("DETAILS")
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
                v.text:SetFont(NEWFONT)
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
                    v.text:SetFont(NEWFONT_OUTLINE)
                    v.text:SetColour(1,1,1,1)
                    v.text:SetSize(33)
                else
                    v.text:SetFont(NEWFONT)
                    v.text:SetColour(0,0,0,1)
                    v.text:SetSize(35)
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
                    if a.friend_playing and not b.friend_playing then
                        return true
                    elseif not a.friend_playing and b.friend_playing then
                        return false
                    end
                    if a.belongs_to_clan and not b.belongs_to_clan then
                        return true
                    elseif not a.belongs_to_clan and b.belongs_to_clan then
                        return false
                    end
                    if a.ping < 0 and b.ping >= 0 then
                        return false
                    elseif a.ping >= 0 and b.ping < 0 then
                        return true
                    elseif a.ping == b.ping then
                        return string.lower(a.name) < string.lower(b.name)
                    else
                        return a.ping < b.ping
                    end
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
                    if a.friend_playing and not b.friend_playing then
                        return false
                    elseif not a.friend_playing and b.friend_playing then
                        return true
                    end
                    if a.belongs_to_clan and not b.belongs_to_clan then
                        return false
                    elseif not a.belongs_to_clan and b.belongs_to_clan then
                        return true
                    end
                    if a.ping < 0 and b.ping >= 0 then
                        return false
                    elseif a.ping >= 0 and b.ping < 0 then
                        return true
                    elseif a.ping == b.ping then
                        return string.lower(a.name) > string.lower(b.name)
                    else
                        return a.ping > b.ping
                    end
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
        self.unjoinable_servers = self.unjoinable_servers + 1
    end

    -- Filter servers that we aren't allowed to join.
    if server.clan_only and not server.belongs_to_clan then
        valid = false
        self.unjoinable_servers = self.unjoinable_servers + 1
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
                or (v.name == "FRIENDSONLY" and v.spinner:GetSelectedData() ~= "ANY" and v.spinner:GetSelectedData() ~= server.friend_playing )
                or (v.name == "CLANONLY" and v.spinner:GetSelectedData() ~= "ANY" and not server.belongs_to_clan )
                or (v.name == "CLANONLY" and v.spinner:GetSelectedData() == "PRIVATE" and not server.clan_only )
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
            v.spinner.changed_image:Hide()
            if v.name == "GAMEMODE" then
                v.spinner:SetHoverText("")
            end
        end
    end
    self.searchbox.textbox:SetString("")
    self:DoFiltering()
end

function ServerListingScreen:DoFiltering(doneSearching)
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
                        friend_playing=v.friend_playing, 
                        clan_server = v.clan_server,
                        clan_only = v.clan_only,
                        belongs_to_clan=v.belongs_to_clan, 
                        actualindex=i,
                        mods_enabled = v.mods_enabled,
                        tags = v.tags,
                        session = v.session,
                        has_details = v.has_details,
                        -- data = v.data,
                    })
            end
        end

        if self.selected_server ~= nil and self:IsValidWithFilters(self.selected_server) == false then
            self:ServerSelected(nil)
        end
    end
    
    if CompareTable(self.viewed_servers, filtered_servers) and not doneSearching then
        return
    end
    self.viewed_servers = {}
    self.viewed_servers = filtered_servers
    local num_servs = #self.servers-self.unjoinable_servers
    if num_servs < 0 then num_servs = 0 end
    if num_servs == 0 and not doneSearching then
        self.server_count:SetString("("..STRINGS.UI.SERVERLISTINGSCREEN.SEARCHING_SERVERS..")")
    else
        self.server_count:SetString("("..#self.viewed_servers.." "..STRINGS.UI.SERVERLISTINGSCREEN.OUT_OF.." "..num_servs.." "..STRINGS.UI.SERVERLISTINGSCREEN.SHOWING..")")
    end
    if not self.online then
        self.server_count:SetString("("..STRINGS.UI.SERVERLISTINGSCREEN.LAN..")")
    end
    self:DoSorting()
    self.servers_scroll_list:SetList(self.viewed_servers)
end

function ServerListingScreen:Cancel()
    TheNet:StopSearchingServers()
    self:Disable()
    TheFrontEnd:Fade(false, SCREEN_FADE_TIME, function()
        if self.cb then
            local filters = {}
            for i,v in pairs(self.filters) do
                if v.spinner then 
                    table.insert(filters, {name=v.name, data=v.spinner:GetSelectedData()})
                elseif v.textbox then
                    table.insert(filters, {name="search", data=v.textbox:GetString()})
                end
            end
            self.cb(filters)
        end
        TheFrontEnd:PopScreen()
        TheFrontEnd:Fade(true, SCREEN_FADE_TIME)
    end)
end

local function CreateSpinner( self, name, text, spinnerOptions, numeric, onchanged )
    local spacing = 62
    local label_width = 150
    local group = self.server_detail_panel:AddChild(Widget( "SpinnerGroup" ))
    group.label = group:AddChild( Text( NEWFONT, 20, text ) )
    group.label:SetPosition( -3, 0, 0 )
    group.label:SetRegionSize( label_width, 50 )
    group.label:SetHAlign( ANCHOR_RIGHT )
    group.label:SetColour(0,0,0,1)

    local bg = group:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
    bg:SetSize(255, 30)
    bg:SetPosition(66, 2, 0)
    bg:MoveToBack()

    group.spinner = nil
    if numeric then
        group.spinner = group:AddChild(NumericSpinner(spinnerOptions.min, spinnerOptions.max, 190, 40, {font=NEWFONT, size=20}, nil, nil, nil, true, nil, nil, .63, .74))
    else
        group.spinner = group:AddChild(Spinner(spinnerOptions, 190, 40, {font=NEWFONT, size=20}, nil, nil, nil, true, nil, nil, .63, .74))
    end
    group.spinner:SetTextColour(0,0,0,1)
    group.spinner.changed_image = group.spinner:AddChild(Image("images/ui.xml", "option_highlight.tex"))
    group.spinner.changed_image:ScaleToSize(117,27)
    group.spinner.changed_image:SetPosition(-1,1)
    group.spinner.changed_image:SetClickable(false)
    group.spinner.changed_image:MoveToBack()
    group.spinner.changed_image:Hide()
    group.spinner.OnChanged =
        function( _, data )
            self:DoFiltering()
            if group.spinner:GetSelectedIndex() ~= 1 then
                group.spinner.changed_image:Show()
            else
                group.spinner.changed_image:Hide()
            end
            if onchanged then
                onchanged(_,data)
            end
        end
    group.spinner:SetPosition( 57 + label_width/2, 0, 0 )

    group.name = name

    --pass focus down to the spinner
    group.focus_forward = group.spinner

    

    return group
end

function ServerListingScreen:MakeFiltersPanel(filter_data)
    local any_on_off = {{ text = STRINGS.UI.SERVERLISTINGSCREEN.ANY, data = "ANY" }, { text = STRINGS.UI.SERVERLISTINGSCREEN.ON, data = true }, { text = STRINGS.UI.SERVERLISTINGSCREEN.OFF, data = false }}
    local any_no_yes = {{ text = STRINGS.UI.SERVERLISTINGSCREEN.ANY, data = "ANY" }, { text = STRINGS.UI.SERVERLISTINGSCREEN.NO, data = false }, { text = STRINGS.UI.SERVERLISTINGSCREEN.YES, data = true }}
    local any_yes_no = {{ text = STRINGS.UI.SERVERLISTINGSCREEN.ANY, data = "ANY" }, { text = STRINGS.UI.SERVERLISTINGSCREEN.YES, data = true }, { text = STRINGS.UI.SERVERLISTINGSCREEN.NO, data = false }}
    local any_mine_private = {{ text = STRINGS.UI.SERVERLISTINGSCREEN.ANY, data = "ANY" }, { text = STRINGS.UI.SERVERLISTINGSCREEN.MINE, data = "MINE" }, { text = STRINGS.UI.SERVERLISTINGSCREEN.PRIVATE, data = "PRIVATE" }}
    local yes_no = {{ text = STRINGS.UI.SERVERLISTINGSCREEN.YES, data = true }, { text = STRINGS.UI.SERVERLISTINGSCREEN.NO, data = false }}
    local no_yes = {{ text = STRINGS.UI.SERVERLISTINGSCREEN.NO, data = false }, { text = STRINGS.UI.SERVERLISTINGSCREEN.YES, data = true }}
    local any_dedicated_hosted = {{ text = STRINGS.UI.SERVERLISTINGSCREEN.ANY, data = "ANY" }, { text = STRINGS.UI.SERVERLISTINGSCREEN.DEDICATED, data = true }, { text = STRINGS.UI.SERVERLISTINGSCREEN.HOSTED, data = false }}
    
    local seasons = {{ text = STRINGS.UI.SERVERLISTINGSCREEN.ANY, data = "ANY" },
                    { text = STRINGS.UI.SERVERLISTINGSCREEN.SEASONS.AUTUMN, data = "autumn" },
                    { text = STRINGS.UI.SERVERLISTINGSCREEN.SEASONS.WINTER, data = "winter" },
                    { text = STRINGS.UI.SERVERLISTINGSCREEN.SEASONS.SPRING, data = "spring" },
                    { text = STRINGS.UI.SERVERLISTINGSCREEN.SEASONS.SUMMER, data = "summer" }}
    
    local game_modes = {{ text = STRINGS.UI.SERVERLISTINGSCREEN.ANY, data = "ANY" }}
    local m = GetGameModesSpinnerData()
 	for i,v in ipairs(m) do
        table.insert( game_modes, { text = v.text, data = v.data} )
    end
	table.insert( game_modes, { text = STRINGS.UI.SERVERLISTINGSCREEN.CUSTOM, data = "custom" } )
    local player_slots = {{ text = STRINGS.UI.SERVERLISTINGSCREEN.ANY, data = "ANY" }}
    local i = TUNING.MAX_SERVER_SIZE
    while i > 0 do
        table.insert(player_slots,{text=i, data=i})
        i = i - 1
    end

    local reset = self.server_detail_panel:AddChild(Widget("resetfilters"))
    reset.button = reset:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "undo.tex", STRINGS.UI.SERVERLISTINGSCREEN.FILTER_RESET, true, false, function() self:ResetFilters() end))
    reset.button:SetPosition(125,0)
    reset.button:SetScale(.45)
    reset.button.label:SetSize(20/.45)
    reset.button.label:SetRegionSize(300,70)
    reset.button.label:SetPosition(-210, 7)
    reset.bg = reset:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
    reset.bg:SetSize(255, 30)
    reset.bg:SetPosition(66, 2, 0)
    reset.bg:MoveToBack()
    reset.bg:SetClickable(false)
    reset.focus_forward = reset.button

    local searchbox = self.server_detail_panel:AddChild(Widget("searchbox"))
    local nudgex = 75
    local nudgey = 2
    local bg = searchbox:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
    bg:SetSize(255, 30)
    bg:SetPosition(66, nudgey, 0)
    bg:MoveToBack()
    searchbox.bg = searchbox:AddChild( Image("images/textboxes.xml", "textbox2_small_grey.tex") )
    local box_size = 155
    searchbox.bg:ScaleToSize( box_size, 28 )
    searchbox.textbox = searchbox:AddChild(TextEdit( NEWFONT, 20, nil, {0,0,0,1} ) )
    searchbox.textbox:SetForceEdit(true)
    searchbox.bg:SetPosition((box_size * .5) - 100 + 25 + nudgex, nudgey, 0)
    searchbox.textbox:SetPosition((box_size * .5) - 100 + 26 + nudgex, nudgey, 0)
    searchbox.textbox:SetRegionSize( box_size - 20, 35 )
    searchbox.textbox:SetHAlign(ANCHOR_LEFT)
    searchbox.textbox:SetFocusedImage( searchbox.bg, "images/textboxes.xml", "textbox2_small_grey.tex", "textbox2_small_gold.tex", "textbox2_small_gold_greyfill.tex" )
    searchbox.textbox:SetTextLengthLimit( STRING_MAX_LENGTH )
    searchbox.textbox:SetCharacterFilter( VALID_CHARS )
    searchbox.label = searchbox:AddChild(Text(NEWFONT, 20))
    searchbox.label:SetString(STRINGS.UI.SERVERLISTINGSCREEN.SEARCH)
    searchbox.label:SetRegionSize( 165, 50 )
    searchbox.label:SetHAlign(ANCHOR_LEFT)
    searchbox.label:SetPosition(-40 + nudgex, nudgey)
    searchbox.label:SetColour(0,0,0,1)
    searchbox.gobutton = searchbox:AddChild(ImageButton("images/lobbyscreen.xml", "button_send.tex", "button_send_over.tex", "button_send_down.tex", "button_send_down.tex", "button_send_down.tex", {.15, .15}, {0,0}))
    searchbox.gobutton:SetPosition(box_size - 62 + nudgex, nudgey)
    searchbox.gobutton:SetScale(.8)
    searchbox.gobutton.image:SetTint(.6,.6,.6,1)
    searchbox.textbox.OnTextEntered = function() self:DoFiltering() end
    searchbox.gobutton:SetOnClick( function() self.searchbox.textbox:OnTextEntered() end )

    self.searchbox = searchbox -- Need a ref to this for reasons

    local screen = self
    self.searchbox.OnGainFocus = function(self)
        Widget.OnGainFocus(self)
        screen.searchbox.textbox:OnGainFocus()
    end
    self.searchbox.OnLoseFocus = function(self)
        Widget.OnLoseFocus(self)
        screen.searchbox.textbox:OnLoseFocus()
    end
    self.searchbox.GetHelpText = function(self)
        local controller_id = TheInput:GetControllerID()
        local t = {}
        if not screen.searchbox.textbox.editing and not screen.searchbox.textbox.focus then
            table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT, false, false ) .. " " .. STRINGS.UI.HELP.CHANGE_TEXT)   
        end
        return table.concat(t, "  ")
    end

    table.insert(self.filters, reset)
    table.insert(self.filters, searchbox)
    table.insert(self.filters, CreateSpinner( self, "GAMEMODE", STRINGS.UI.SERVERLISTINGSCREEN.GAMEMODE, game_modes, false ))
    table.insert(self.filters, CreateSpinner( self, "SEASON", STRINGS.UI.SERVERLISTINGSCREEN.SEASONFILTER, seasons, false ))
    table.insert(self.filters, CreateSpinner( self, "HASPVP", STRINGS.UI.SERVERLISTINGSCREEN.HASPVP, any_on_off, false ))
    table.insert(self.filters, CreateSpinner( self, "MODSENABLED", STRINGS.UI.SERVERLISTINGSCREEN.MODSENABLED, any_no_yes, false ))
    table.insert(self.filters, CreateSpinner( self, "HASPASSWORD", STRINGS.UI.SERVERLISTINGSCREEN.HASPASSWORD, any_no_yes, false ))
    table.insert(self.filters, CreateSpinner( self, "ISDEDICATED", STRINGS.UI.SERVERLISTINGSCREEN.SERVERTYPE, any_dedicated_hosted, false ))
    table.insert(self.filters, CreateSpinner( self, "HASCHARACTER", STRINGS.UI.SERVERLISTINGSCREEN.HASCHARACTER, any_yes_no, false ))
    table.insert(self.filters, CreateSpinner( self, "FRIENDSONLY", STRINGS.UI.SERVERLISTINGSCREEN.FRIENDSONLY, any_yes_no, false ))
    table.insert(self.filters, CreateSpinner( self, "CLANONLY", STRINGS.UI.SERVERLISTINGSCREEN.CLANONLY, any_mine_private, false ))
    -- table.insert(self.filters, CreateSpinner( "MINCURRPLAYERS", STRINGS.UI.SERVERLISTINGSCREEN.MINCURRPLAYERS, {min=0,max=4}, true ))
    -- table.insert(self.filters, CreateSpinner( self, "MAXCURRPLAYERS", STRINGS.UI.SERVERLISTINGSCREEN.MAXCURRPLAYERS, players, false ))--STRINGS.UI.SERVERLISTINGSCREEN.MAXCURRPLAYERS, {min=0,max=4}, true ))
    table.insert(self.filters, CreateSpinner( self, "ISFULL", STRINGS.UI.SERVERLISTINGSCREEN.ISFULL, yes_no, false ))
    table.insert(self.filters, CreateSpinner( self, "MINOPENSLOTS", STRINGS.UI.SERVERLISTINGSCREEN.MINOPENSLOTS, player_slots, false ))
    table.insert(self.filters, CreateSpinner( self, "ISEMPTY", STRINGS.UI.SERVERLISTINGSCREEN.ISEMPTY, yes_no, false ))
    -- table.insert(self.filters, CreateSpinner( "MAXSERVERSIZE", STRINGS.UI.SERVERLISTINGSCREEN.MAXSERVERSIZE, {min=2,max=4}, true ))
    
    if APP_VERSION == "-1" then
        table.insert(self.filters, CreateSpinner( self, "VERSIONCHECK", STRINGS.UI.SERVERLISTINGSCREEN.VERSIONCHECK, no_yes, false ))
    else
        TheNet:SetCheckVersionOnQuery( true )
    end

    if APP_VERSION ~= "-1" then
        self.filters_scroll_list = self.server_detail_panel:AddChild(ScrollableList(self.filters, 10, 440, 20, 13, nil, nil, 205))
        self.filters_scroll_list:SetPosition(-332,-35)
    else
        self.filters_scroll_list = self.server_detail_panel:AddChild(ScrollableList(self.filters, 10, 470, 20, 11, nil, nil, 205))
        self.filters_scroll_list:SetPosition(-332,-45)
    end

    if filter_data then
        for i,v in pairs(filter_data) do
            for j,k in pairs(self.filters) do
                if v.name == k.name then
                    if k.spinner then
                        k.spinner:SetSelected(v.data)
                        if k.spinner:GetSelectedIndex() ~= 1 then
                            k.spinner.changed_image:Show()
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
    if not style or style == "large" then
        btn = parent:AddChild(ImageButton())
        btn.image:SetScale(.7)
        btn:SetDisabledFont(NEWFONT)
    elseif style == "tab" then
        btn = parent:AddChild(TEMPLATES.TabButton(xPos, yPos, text, onclick, "large"))
        btn.text:SetSize(24)
    elseif style == "nav" then
        btn = parent:AddChild(TEMPLATES.NavBarButton(yPos, text, onclick))
    elseif style == "refresh" or style == "tags" or style == "mods" or style == "world" or style == "view_players" then
        btn = parent:AddChild(TEMPLATES.IconButton("images/button_icons.xml", style..".tex", text, false, false, onclick))
    end
    
    btn:SetPosition(xPos, yPos)
    
    if not style or style == "large" then
        btn:SetTextColour(0,0,0,1)
        btn:SetTextSize(40)
        btn:SetOnClick(onclick)
    end

    if style ~= "tags" and style ~= "mods" and style ~= "world" and style ~= "view_players" and style ~= "refresh" then
        btn:SetText(text)
    end
    
    if style ~= "tab" then
        btn:SetFont(NEWFONT)
        btn:SetDisabledFont(NEWFONT)
    end

    return btn
end

function ServerListingScreen:MakeMenuButtons(left_col, right_col, nav_col)
    self.refresh_button = MakeImgButton(self.server_list_titles, left_col-35, 51, STRINGS.UI.SERVERLISTINGSCREEN.REFRESH, function() self:SearchForServers() end, "refresh")
    self.lan_button = MakeImgButton(self.nav_bar, 10, -23, STRINGS.UI.SERVERLISTINGSCREEN.LAN, function() self:SetTab("LAN") end, "nav")
    self.online_button = MakeImgButton(self.nav_bar, 10, 25, STRINGS.UI.SERVERLISTINGSCREEN.ONLINE, function() 
        if self.offlinemode then
            TheFrontEnd:PushScreen(PopupDialogScreen(
                    STRINGS.UI.SERVERLISTINGSCREEN.OFFLINE_MODE_TITLE, 
                    STRINGS.UI.SERVERLISTINGSCREEN.OFFLINE_MODE_BODY, 
                    {{ text = STRINGS.UI.SERVERLISTINGSCREEN.OK, cb = function() TheFrontEnd:PopScreen() end }}))
        else
            self:SetTab("online") 
        end
    end, "nav")
    self.join_button = MakeImgButton(self.server_detail_panel, -55, -RESOLUTION_Y*.5 + BACK_BUTTON_Y - 15, STRINGS.UI.SERVERLISTINGSCREEN.JOIN, function() self:Join() end, "large")
    local tab_height = 212
    self.filters_button = MakeImgButton(self.server_detail_panel, -132, tab_height, STRINGS.UI.SERVERLISTINGSCREEN.FILTERS, function() self:ToggleShowFilters() end, "tab")
    self.details_button = MakeImgButton(self.server_detail_panel, -1, tab_height, STRINGS.UI.SERVERLISTINGSCREEN.SERVERDETAILS, function() self:ToggleShowFilters() end, "tab")
    
    if not self.offlinemode then
        self.refresh_button:Disable()
        self.refresh_button:SetHoverText(STRINGS.UI.SERVERLISTINGSCREEN.REFRESHING)
    end
    self.join_button:Disable()

    self.details_shown = false
    self.filters_shown = false

    self.cancel_button = self.root:AddChild(TEMPLATES.BackButton(function() self:Cancel() end))

    self.online_button:SetFocusChangeDir(MOVE_DOWN, function() return self.lan_button end)
    self.lan_button:SetFocusChangeDir(MOVE_UP, function() return self.online_button end)

    self.online_button:SetFocusChangeDir(MOVE_RIGHT, function() return self.servers_scroll_list end)
    self.lan_button:SetFocusChangeDir(MOVE_RIGHT, function() return self.servers_scroll_list end)

    if TheInput:ControllerAttached() then
        -- self.refresh_button:Hide()
        self.join_button:Hide()
        self.cancel_button:Hide()
    else
        self.lan_button:SetFocusChangeDir(MOVE_DOWN, function() return self.cancel_button end)
        self.cancel_button:SetFocusChangeDir(MOVE_UP, function() return self.lan_button end)
        self.cancel_button:SetFocusChangeDir(MOVE_RIGHT, function() return self.servers_scroll_list end)
    end
end

function ServerListingScreen:MakeDetailPanel(right_col)
    self.server_detail_panel = self.root:AddChild(Widget("server_detail_panel"))
    self.server_detail_panel:SetPosition(right_col,0,0)
    self.server_detail_panelbg = self.server_detail_panel:AddChild(Image("images/serverbrowser.xml", "side_panel.tex"))
    self.server_detail_panelbg:SetScale(-.66,.7)
    self.server_detail_panelbg:SetPosition(-62,-45)
    
    local detail_x = -65
    local width = 240

    self.details_servername = self.server_detail_panel:AddChild(Text(BUTTONFONT, 40))
    self.details_servername:SetHAlign(ANCHOR_MIDDLE)
    self.details_servername:SetVAlign(ANCHOR_TOP)
    self.details_servername:SetPosition(detail_x, RESOLUTION_Y*0.16 + 10, 0)
    self.details_servername:SetRegionSize( width, 90 )
    self.details_servername:SetString(STRINGS.UI.SERVERLISTINGSCREEN.NOSERVERSELECTED)
    self.details_servername:EnableWordWrap( true )
    self.details_servername:SetColour(0,0,0,1)

    self.details_serverdesc = self.server_detail_panel:AddChild(Text(NEWFONT, 20))
    self.details_serverdesc:SetHAlign(ANCHOR_MIDDLE)
    self.details_serverdesc:SetVAlign(ANCHOR_TOP)
    self.details_serverdesc:SetPosition(detail_x, 55, 0)
    self.details_serverdesc:SetRegionSize( width, 70 )
    self.details_serverdesc:SetString("")
    self.details_serverdesc:EnableWordWrap( true )
    self.details_serverdesc:SetColour(0,0,0,1)

    self.viewworld_button = MakeImgButton(self.server_detail_panel, -93, 6, STRINGS.UI.SERVERLISTINGSCREEN.WORLD_UNKNOWN, function() self:ViewServerWorld() end, "world")
    self.viewworld_button:Select()

    self.viewplayers_button = MakeImgButton(self.server_detail_panel, -36, 6, STRINGS.UI.SERVERLISTINGSCREEN.PLAYERS_UNKNOWN, function() self:ViewServerPlayers() end, "view_players")
    self.viewplayers_button:Select()

    self.viewmods_button = MakeImgButton(self.server_detail_panel, 20, 6, STRINGS.UI.SERVERLISTINGSCREEN.NOMODS, function() self:ViewServerMods() end, "mods")
    self.viewmods_button:Select()

    self.viewtags_button = MakeImgButton(self.server_detail_panel, 77, 6, STRINGS.UI.SERVERLISTINGSCREEN.NOTAGS, function() self:ViewServerTags() end, "tags")
    self.viewtags_button:Select()

    self.viewworld_button:SetScale(.9)
    self.viewplayers_button:SetScale(.9)
    self.viewmods_button:SetScale(.9)
    self.viewtags_button:SetScale(.9)

    local buttons = Widget("buttons")
    buttons:AddChild(self.viewmods_button)
    buttons:AddChild(self.viewtags_button)
    buttons:AddChild(self.viewworld_button)
    buttons:AddChild(self.viewplayers_button)
    buttons.focus_forward = self.viewtags_button
    self.viewworld_button:SetFocusChangeDir(MOVE_LEFT, function() return self.servers_scroll_list end)
    self.viewworld_button:SetFocusChangeDir(MOVE_RIGHT, function() return self.viewplayers_button end)
    self.viewplayers_button:SetFocusChangeDir(MOVE_LEFT, function() return self.viewworld_button end)
    self.viewplayers_button:SetFocusChangeDir(MOVE_RIGHT, function() return self.viewmods_button end)
    self.viewmods_button:SetFocusChangeDir(MOVE_LEFT, function() return self.viewplayers_button end)
    self.viewmods_button:SetFocusChangeDir(MOVE_RIGHT, function() return self.viewtags_button end)
    self.viewtags_button:SetFocusChangeDir(MOVE_LEFT, function() return self.viewmods_button end)

    self.game_mode_description = Widget("gamemodedesc")
    self.game_mode_description.text = self.game_mode_description:AddChild(Text(NEWFONT, 20))
    self.game_mode_description.text:SetString(STRINGS.UI.SERVERLISTINGSCREEN.SURVIVAL)
    self.game_mode_description.text:SetPosition(-10,0)
    self.game_mode_description.text:SetHAlign(ANCHOR_MIDDLE)
    -- self.game_mode_description.text:SetRegionSize( 200, 50 )
    self.game_mode_description.text:SetString("???")
    self.game_mode_description.text:SetColour(0,0,0,1)
    self.game_mode_description.info_button = self.game_mode_description:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "info.tex", "", false, false, function()  
            local mode_title = GetGameModeString( self.selected_server.mode )
            if mode_title == "" then
                mode_title = STRINGS.UI.GAMEMODES.UNKNOWN
            end
            local mode_body = GetGameModeDescriptionString( self.selected_server.mode )
            if mode_body == "" then
                mode_body = STRINGS.UI.GAMEMODES.UNKNOWN_DESCRIPTION
            end
            TheFrontEnd:PushScreen(PopupDialogScreen(
                mode_title, 
                mode_body, 
                {{ text = STRINGS.UI.SERVERLISTINGSCREEN.OK, cb = function() TheFrontEnd:PopScreen() end }}))
        end))
    local w,h = self.game_mode_description.text:GetRegionSize()
    self.game_mode_description.info_button:SetPosition(w/2 + 7, -2)
    self.game_mode_description.info_button:SetScale(.4)
    self.game_mode_description.info_button:SetFocusChangeDir(MOVE_UP, function() return self.viewworld_button end)
    self.viewworld_button:SetFocusChangeDir(MOVE_DOWN, function() return self.game_mode_description.info_button end)
    self.viewplayers_button:SetFocusChangeDir(MOVE_DOWN, function() return self.game_mode_description.info_button end)
    self.viewmods_button:SetFocusChangeDir(MOVE_DOWN, function() return self.game_mode_description.info_button end)
    self.viewtags_button:SetFocusChangeDir(MOVE_DOWN, function() return self.game_mode_description.info_button end)

    local check_x = -90
    local label_x = 40

    local has_password = Widget("pw")        
    self.checkbox_has_password = has_password:AddChild(TEMPLATES.ServerDetailIcon("images/servericons.xml", "password.tex", "rust", "", nil, {-1,0}, .08, .073))
    self.checkbox_has_password:SetPosition(check_x, 0, 0)
    self.checkbox_has_password.off_image = self.checkbox_has_password:AddChild(Image("images/servericons.xml", "bg_grey.tex"))
    self.checkbox_has_password.off_image:SetTint(1,1,1,.7)
    self.checkbox_has_password.off_image:SetScale(.09)
    self.checkbox_has_password.off_image:Hide()
    self.has_password_description = has_password:AddChild(Text(NEWFONT, 20))
    self.has_password_description:SetPosition(label_x, 0, 0)
    self.has_password_description:SetString(STRINGS.UI.SERVERLISTINGSCREEN.HASPASSWORD_DETAIL)
    self.has_password_description:SetHAlign(ANCHOR_LEFT)
    self.has_password_description:SetRegionSize( 200, 50 )
    self.has_password_description:SetColour(0,0,0,1)
    SetChecked( self.checkbox_has_password, self.has_password_description, false )

    local dedicated_server = Widget("ded")
    self.checkbox_dedicated_server = dedicated_server:AddChild(TEMPLATES.ServerDetailIcon("images/servericons.xml", "dedicated.tex", "burnt", "", nil, {0,0}, .08, .073))
    self.checkbox_dedicated_server:SetPosition(check_x, 0, 0)
    self.checkbox_dedicated_server.off_image = self.checkbox_dedicated_server:AddChild(Image("images/servericons.xml", "bg_grey.tex"))
    self.checkbox_dedicated_server.off_image:SetTint(1,1,1,.7)
    self.checkbox_dedicated_server.off_image:SetScale(.09)
    self.checkbox_dedicated_server.off_image:Hide()
    self.dedicated_server_description = dedicated_server:AddChild(Text(NEWFONT, 20))
    self.dedicated_server_description:SetPosition(label_x, 0, 0)
    self.dedicated_server_description:SetString(STRINGS.UI.SERVERLISTINGSCREEN.ISDEDICATED)
    self.dedicated_server_description:SetHAlign(ANCHOR_LEFT)
    self.dedicated_server_description:SetRegionSize( 200, 50 )
    self.dedicated_server_description:SetColour(0,0,0,1)
    SetChecked( self.checkbox_dedicated_server, self.dedicated_server_description, false )
    
    local pvp = Widget("pvp")
    self.checkbox_pvp = pvp:AddChild(TEMPLATES.ServerDetailIcon("images/servericons.xml", "pvp.tex", "brown", "", nil, {0,0}, .075, .075))
    self.checkbox_pvp:SetPosition(check_x, 0, 0)
    self.checkbox_pvp.off_image = self.checkbox_pvp:AddChild(Image("images/servericons.xml", "bg_grey.tex"))
    self.checkbox_pvp.off_image:SetTint(1,1,1,.7)
    self.checkbox_pvp.off_image:SetScale(.09)
    self.checkbox_pvp.off_image:Hide()
    self.pvp_description = pvp:AddChild(Text(NEWFONT, 20))
    self.pvp_description:SetPosition(label_x, 0, 0)
    self.pvp_description:SetString(STRINGS.UI.SERVERLISTINGSCREEN.HASPVP_DETAIL)
    self.pvp_description:SetHAlign(ANCHOR_LEFT)
    self.pvp_description:SetRegionSize( 200, 50 )
    self.pvp_description:SetColour(0,0,0,1)
    SetChecked( self.checkbox_pvp, self.pvp_description, false )

    self.season_description = Widget("seasondesc")
    self.season_description.text = self.season_description:AddChild(Text(NEWFONT, 20))
    self.season_description.text:SetPosition(-10,0)
    self.season_description.text:SetHAlign(ANCHOR_MIDDLE)
    self.season_description.text:SetRegionSize( 400, 50 )
    self.season_description.text:SetString("???")
    self.season_description.text:SetColour(0,0,0,1)

    self.day_description = Widget("daydesc")
    self.day_description.text = self.day_description:AddChild(Text(NEWFONT, 20))
    self.day_description.text:SetPosition(-10,0)
    self.day_description.text:SetHAlign(ANCHOR_MIDDLE)
    self.day_description.text:SetRegionSize( 400, 50 )
    self.day_description.text:SetString("???")
    self.day_description.text:SetColour(0,0,0,1)

    self.detail_panel_widgets = { 
        buttons,
        self.game_mode_description,
        self.day_description,
        self.season_description,
        pvp,
        dedicated_server,
        has_password,
    }

    self.server_details_parent = self.server_detail_panel:AddChild(Widget("servdetails"))
    self.server_details_parent:SetPosition(detail_x-230,-120)
    self.server_details_parent.focus_forward = self.viewworld_button
    for i,v in ipairs(self.detail_panel_widgets) do
        self.server_details_parent:AddChild(v)
        v:SetPosition(240, 125 - (33*i-1))
    end
    self.server_details_parent:Hide()
end

local function MakeHeader(self, parent, xPos, name, onclick)

    local root_y_offset = 3
    local text_x_offset = -5
    local text_y_offset = 3
    local frame_color = {0, 0, 0, 1}
    local arrow_x_offset = 6.5
    local arrow_y_offset = 2
    local bg_y_scale = 15
    local bg_x_offset = 10
    local bg_y_offset = 0

    local header = parent:AddChild(Widget("control"))
    header:SetPosition(xPos, root_y_offset)
    header.text = header:AddChild(Text(NEWFONT, font_size, name))
    header.text:SetPosition(text_x_offset,text_y_offset,0)
    header.text:SetColour(frame_color[1], frame_color[2], frame_color[3], frame_color[4])
    header.bg = header.text:AddChild(ImageButton("images/ui.xml", "blank.tex", "blank.tex", "blank.tex"))
    header.bg:MoveToBack()
    header.arrow = header:AddChild(Image("images/ui.xml", "arrow2_down.tex"))
    header.arrow.ascending = true
    header.arrow:SetScale(.25)
    header.arrow:SetPosition(header.text:GetRegionSize()/2 + arrow_x_offset, arrow_y_offset, 0)
    header.arrow:SetClickable(false)
    header.arrow:Hide()
    if name == STRINGS.UI.SERVERLISTINGSCREEN.NAME then
        header.bg.image:SetSize(315, 35)
        header.bg:SetPosition(bg_x_offset+108, bg_y_offset)
    elseif name == STRINGS.UI.SERVERLISTINGSCREEN.DETAILS then
        header.bg.image:SetSize(185, 35)
        header.bg:SetPosition(bg_x_offset+41, bg_y_offset)
    elseif name == STRINGS.UI.SERVERLISTINGSCREEN.PLAYERS then
        header.bg.image:SetSize(110, 35)
        header.bg:SetPosition(bg_x_offset, bg_y_offset)
    else
        header.bg.image:SetSize(80, 35)
        header.bg:SetPosition(bg_x_offset+3, bg_y_offset)
    end

    header.bg.OnGainFocus =
        function()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
            header.text:SetFont(NEWFONT_OUTLINE)
            header.text:SetColour(1,1,1,1)
            header.text:SetSize(33)
            if header.arrow.ascending then
                header.arrow:SetTexture("images/ui.xml", "arrow2_up_over.tex")
            else
                header.arrow:SetTexture("images/ui.xml", "arrow2_down_over.tex")
            end
        end
    header.bg.OnLoseFocus =
        function()
            if self.sort_column == string.upper(name) then
                -- header.text:SetColour(.4,.4,.4,1)
            else
                -- header.text:SetColour(frame_color[1], frame_color[2], frame_color[3], frame_color[4])
            end
            header.text:SetFont(NEWFONT)
            header.text:SetColour(0,0,0,1)
            header.text:SetSize(35)
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
    self.title = self.server_list_titles:AddChild(Text(BUTTONFONT, 45, STRINGS.UI.SERVERLISTINGSCREEN.SERVER_LIST_TITLE))
    self.title:SetColour(0,0,0,1)
    self.title:SetPosition(column_offsets.DETAILS, 60)

    self.server_count = self.server_list_titles:AddChild(Text(NEWFONT, 25, "(0)"))
    self.server_count:SetColour(0,0,0,1)
    self.server_count:SetRegionSize(300,40)
    self.server_count:SetHAlign(ANCHOR_RIGHT)
    self.server_count:SetPosition(column_offsets.DETAILS+167, 53)    

    self.NAME = MakeHeader(self, self.server_list_titles, column_offsets.NAME, STRINGS.UI.SERVERLISTINGSCREEN.NAME, function() self:SetSort("NAME") end)
    self.DETAILS = MakeHeader(self, self.server_list_titles, column_offsets.DETAILS-13, STRINGS.UI.SERVERLISTINGSCREEN.DETAILS, function() self:SetSort("DETAILS") end)
    self.PLAYERS = MakeHeader(self, self.server_list_titles, column_offsets.PLAYERS, STRINGS.UI.SERVERLISTINGSCREEN.PLAYERS, function() self:SetSort("PLAYERS") end)
    self.PING = MakeHeader(self, self.server_list_titles, column_offsets.PING, STRINGS.UI.SERVERLISTINGSCREEN.PING, function() self:SetSort("PING") end)

    self.column_buttons = {
        NAME = self.NAME,
        DETAILS = self.DETAILS,
        PLAYERS = self.PLAYERS,
        PING = self.PING
    }
end

function ServerListingScreen:OnControl(control, down)
    if ServerListingScreen._base.OnControl(self, control, down) then return true end
    
    if self.searchbox and ((self.searchbox.textbox and self.searchbox.textbox.editing) or (TheInput:ControllerAttached() and self.searchbox.focus and control == CONTROL_ACCEPT)) then
        self.searchbox.textbox:OnControl(control, down)
        return true
    end

    if not down then
        if control == CONTROL_CANCEL then 
            if TheFrontEnd:GetFadeLevel() > 0 then 
                TheNet:Disconnect(false)
                HideCancelTip()
                TheFrontEnd:Fade(true, SCREEN_FADE_TIME)
            else
                self:Cancel()
                TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
            end
        elseif control == CONTROL_PAUSE and self.selected_server and TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse then
            self:Join()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        elseif control == CONTROL_OPEN_CRAFTING or control == CONTROL_OPEN_INVENTORY then
            self:ToggleShowFilters()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        elseif control == CONTROL_MENU_MISC_2 and not TheNet:IsSearchingServers() then
            self:SearchForServers()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        elseif control == CONTROL_MENU_MISC_1 then
            self:CycleColumnSort()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
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

    table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_OPEN_CRAFTING).."/"..TheInput:GetLocalizedControl(controller_id, CONTROL_OPEN_INVENTORY).. " " .. STRINGS.UI.HELP.CHANGE_TAB)

    table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MENU_MISC_1) .. " " .. STRINGS.UI.SERVERLISTINGSCREEN.CHANGE_SORT)

    if not TheNet:IsSearchingServers() then
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MENU_MISC_2) .. " " .. STRINGS.UI.SERVERLISTINGSCREEN.REFRESH)
    end

    if self.selected_server then
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_PAUSE) .. " " .. STRINGS.UI.SERVERLISTINGSCREEN.JOIN)
    end

    return table.concat(t, "  ")
end

function OnServerListingUpdated(row_id)
    local active_screen = TheFrontEnd:GetActiveScreen()
    if active_screen and tostring(active_screen) == "ServerListingScreen" and active_screen.selected_server 
    and active_screen.selected_server.row and active_screen.selected_server.row == row_id and active_screen.selected_server.actualindex then
        active_screen.selected_server = TheNet:GetServerListingFromActualIndex( active_screen.selected_server.actualindex ) 
    end
end

return ServerListingScreen
