local Screen = require "widgets/screen"
local AnimButton = require "widgets/animbutton"
local ImageButton = require "widgets/imagebutton"
local TextButton = require "widgets/textbutton"
local Button = require "widgets/button"
local PopupDialogScreen = require "screens/popupdialog"
local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local Menu = require "widgets/menu"
local UIAnim = require "widgets/uianim"

local ScrollableList = require "widgets/scrollablelist"
local TEMPLATES = require "widgets/templates"

require("constants")

local player_listings_per_view = 10
local player_listings_per_scroll = 10
local player_list_spacing = 37.5

local column_offsets_x_pos = -RESOLUTION_X*0.18;
local column_offsets_y_pos = RESOLUTION_Y*0.23;

local column_offsets ={ 
        NAME = -1,       
        DETAILS = 257,  
        PROFILE = 363,
        DELETE = 468,  
    }

local font_size = 35
if JapaneseOnPS4() then
    font_size = 35 * 0.75;
end

local function MakeImgButton(parent, xPos, yPos, text, onclick, largeBtn)
    if not parent or not xPos or not yPos or not text or not onclick then return end

    local btn 
    if largeBtn then
        btn = parent:AddChild(ImageButton("images/ui.xml", "button_large.tex", "button_large_over.tex", "button_large_disabled.tex", "button_large_onclick.tex"))
        btn.text:SetPosition(-3,0)
    else
        btn = parent:AddChild(ImageButton())
    end
    btn:SetPosition(xPos, yPos)
    btn:SetText(text)
    btn.text:SetColour(0,0,0,1)
    btn:SetFont(NEWFONT)
    btn:SetTextSize(40)
    btn:SetOnClick(onclick)

    return btn
end

local DEFAULT_ATLAS = "images/avatars.xml"
local DEFAULT_AVATAR = "avatar_unknown.tex"

local function GetAvatar(character, is_mod_character)
    return character ~= "" and ("avatar_"..character..".tex")
        or (is_mod_character and "avatar_mod.tex" or DEFAULT_AVATAR)
end

local function GetAvatarAtlas(character, is_mod_character)
    if is_mod_character and character ~= "" then
        local location = MOD_AVATAR_LOCATIONS["Default"]
        if MOD_AVATAR_LOCATIONS[character] ~= nil then
            location = MOD_AVATAR_LOCATIONS[character]
        end
        
        return location .. "avatar_" .. character .. ".xml"
    end
    return DEFAULT_ATLAS
end

local PlayerDetailsPopup = Class(Screen, function(self, entry, buttons)
	Screen._ctor(self, "PlayerDetailsPopup")

	--darken everything behind the dialog
    self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
	self.black:SetTint(0,0,0,.75)	
	
	self.root = self:AddChild(Widget("ROOT"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetPosition(0,0,0)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.details_panel = self.root:AddChild(Widget("player_detail_panel"))
    self.details_panel:SetPosition(0,-10,0)
    self.bg = self.details_panel:AddChild(TEMPLATES.CurlyWindow(130, 150, 1, 1, 68, -40))
    self.bg.fill = self.details_panel:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tiny.tex"))
    self.bg.fill:SetScale(.92, .68)
    self.bg.fill:SetPosition(8, 12)
 
    local title_height = 70

    self.details_playername = self.details_panel:AddChild(Text(NEWFONT, 44))
    self.details_playername:SetHAlign(ANCHOR_MIDDLE)
    self.details_playername:SetVAlign(ANCHOR_TOP)
    self.details_playername:SetPosition(30, title_height, 0)
    self.details_playername:SetColour(0,0,0,1)
    
    if "" == entry.steamid then
        self.details_playername:SetString(STRINGS.UI.SERVERADMINSCREEN.UNKNOWN_USER_NAME)   
    else
        self.details_playername:SetString(entry.steamname)   
    end
    
    self.details_icon = self.details_panel:AddChild(Widget("target"))
    self.details_icon:SetScale(.8)
    local w,h = self.details_playername:GetRegionSize()
    self.details_icon:SetPosition(-w/2 - 30, title_height+5)

    local character = entry.character or ""
    local is_mod_character = false
    if not table.contains(DST_CHARACTERLIST, character) then
        if table.contains(MODCHARACTERLIST, character) then
            is_mod_character = true
        elseif #character > 0 then
            is_mod_character = true
            character = ""
        end
    end

    self.details_headbg = self.details_icon:AddChild(Image("images/avatars.xml", "avatar_bg.tex"))

    self.details_headicon = self.details_icon:AddChild(Image(GetAvatarAtlas(character, is_mod_character), GetAvatar(character, is_mod_character), DEFAULT_AVATAR))

    self.details_headframe = self.details_icon:AddChild(Image("images/avatars.xml", "avatar_frame_white.tex"))
    self.details_headframe:SetTint(.5,.5,.5,1)
    
    self.details_date_label = self.details_panel:AddChild(Text(NEWFONT, 25))
    -- self.details_date_label:SetHAlign(ANCHOR_RIGHT)
    self.details_date_label:SetPosition(0, 10, 0)
    self.details_date_label:SetString(STRINGS.UI.SERVERADMINSCREEN.BANNED..(entry.date or STRINGS.UI.SERVERADMINSCREEN.UNKNOWN_DATE))
    self.details_date_label:SetColour(0,0,0,1)
    
    self.details_servername_label = self.details_panel:AddChild(Text(NEWFONT, 27))
    self.details_servername_label:SetHAlign(ANCHOR_RIGHT)
    self.details_servername_label:SetPosition(-193, -25, 0)
    self.details_servername_label:SetRegionSize( 200, 40 )
    self.details_servername_label:SetString(STRINGS.UI.SERVERADMINSCREEN.SERVER_NAME)
    self.details_servername_label:SetColour(0,0,0,1)
    
    self.details_servername = self.details_panel:AddChild(Text(NEWFONT, 27))
    self.details_servername:SetHAlign(ANCHOR_LEFT)
    self.details_servername:SetPosition(97, -25, 0)
    self.details_servername:SetRegionSize( 360, 40 )
    if entry.servername then
        self.details_servername:SetString(entry.servername)        
    else
        self.details_servername:SetString(STRINGS.UI.SERVERADMINSCREEN.UNKNOWN)        
    end
    self.details_servername:SetColour(0,0,0,1)
    
    self.details_serverdescription_label = self.details_panel:AddChild(Text(NEWFONT, 27))
    self.details_serverdescription_label:SetHAlign(ANCHOR_RIGHT)
    self.details_serverdescription_label:SetPosition(-193, -60, 0)
    self.details_serverdescription_label:SetRegionSize( 200, 40 )
    self.details_serverdescription_label:SetString(STRINGS.UI.SERVERADMINSCREEN.SERVER_DESCRIPTION)
    self.details_serverdescription_label:SetColour(0,0,0,1)
        
    self.details_serverdescription = self.details_panel:AddChild(Text(NEWFONT, 27))
    self.details_serverdescription:SetHAlign(ANCHOR_LEFT)
    self.details_serverdescription:SetPosition(97, -60, 0)
    self.details_serverdescription:SetRegionSize( 360, 40 )
    if entry.serverdescription then
        self.details_serverdescription:SetString(entry.serverdescription)        
    else
        self.details_serverdescription:SetString(STRINGS.UI.SERVERADMINSCREEN.UNKNOWN)        
    end
    self.details_serverdescription:SetColour(0,0,0,1)
      
    local spacing = 200
	self.menu = self.root:AddChild(Menu(buttons, spacing, true))
	self.menu:SetPosition(-(spacing*(#buttons-1))/2, -145, 0) 
	self.buttons = buttons
	self.default_focus = self.menu
end)

function PlayerDetailsPopup:OnControl(control, down)
    if PlayerDetailsPopup._base.OnControl(self,control, down) then return true end
    
    if control == CONTROL_CANCEL and not down then    
        if self.buttons then
            self.buttons[#self.buttons].cb()
            return true
        end
    end
end

function PlayerDetailsPopup:GetHelpText()
	local controller_id = TheInput:GetControllerID()
	local t = {}
	if #self.buttons > 1 and self.buttons[#self.buttons] then
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)	
    end
	return table.concat(t, "  ")
end

local BanTab = Class(Screen, function(self, save_slot, servercreationscreen)
    Widget._ctor(self, "BanTab")

	self.save_slot = save_slot

    self.servercreationscreen = servercreationscreen
    
    self.ban_page = self:AddChild(Widget("ban_page"))

    self.left_line = self.ban_page:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
    self.left_line:SetScale(1, .6)
    self.left_line:SetPosition(-530, 5, 0)

    self.blacklist = TheNet:GetBlacklist() --TestObjs
    self.blacklist_clean = deepcopy(self.blacklist)

    self:MakeMenuButtons()

    self:MakePlayerPanel()

    self.default_focus = self.player_scroll_list    
    self.focus_forward = self.player_scroll_list    
end)

function BanTab:MakePlayerPanel()                    
    self.player_list_rows = self.ban_page:AddChild(Widget("player_list_rows"))
    self.player_list_rows:SetPosition(0, -8, 0) 
     
    self:MakePlayerList()    
end

function BanTab:MakePlayerList()

    local function bannedPlayerRowConstructor(entry, index, parent)
        local widget = parent:AddChild(Widget("option"))
        widget:SetScale(.8)

        widget.white_bg = widget:AddChild(Image("images/ui.xml", "single_option_bg_large.tex"))
        widget.white_bg:SetScale(.63, .9)

        widget.state_bg = widget:AddChild(Image("images/ui.xml", "single_option_bg_large_gold.tex"))
        widget.state_bg:SetScale(.63, .9)
        widget.state_bg:Hide()

        widget.OnGainFocus = function(self)
            if not widget:IsEnabled() then return end
            Widget.OnGainFocus(self)
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
            widget.state_bg:Show()
        end
        widget.OnLoseFocus = function(self)
            if not widget:IsEnabled() then return end
            Widget.OnLoseFocus(self)
            widget.state_bg:Hide()
        end

        local y_offset = 0

        widget.index = index

        widget.NAME = widget:AddChild(Text(NEWFONT, font_size))
        widget.NAME:SetPosition( -75, y_offset, 0 )
        widget.NAME:SetRegionSize( 140, 50 )
        widget.NAME:SetHAlign( ANCHOR_LEFT )
        widget.NAME:SetColour(0,0,0,1)

        widget.EMPTY = widget:AddChild(Text(NEWFONT, font_size, STRINGS.UI.SERVERADMINSCREEN.EMPTY_SLOT))
        widget.EMPTY:SetPosition( 0, y_offset, 0 )
        widget.EMPTY:SetHAlign( ANCHOR_LEFT )
        widget.EMPTY:SetColour(0,0,0,1)
        widget.EMPTY:Hide()

        local buttons = 
        {
            {widget=TEMPLATES.IconButton("images/button_icons.xml", "view_ban.tex", STRINGS.UI.SERVERADMINSCREEN.PLAYER_DETAILS, false, false, function() self:ShowPlayerDetails(index) end, {size=22/.85})},
            {widget=TEMPLATES.IconButton("images/button_icons.xml", "player_info.tex", STRINGS.UI.PLAYERSTATUSSCREEN.VIEWPROFILE, false, false, function() self:ShowSteamProfile(index) end, {size=22/.85})},
            {widget=TEMPLATES.IconButton("images/button_icons.xml", "unban.tex", STRINGS.UI.SERVERADMINSCREEN.PLAYER_DELETE, false, false, function() self:PromptDeletePlayer(index) end, {size=22/.85})},
        }
        for i,v in pairs(buttons) do
            v.widget:SetScale(.85)
        end

        widget.MENU = widget:AddChild(Menu(buttons, 55, true))
        widget.MENU:SetPosition(20,y_offset-2)

        if entry and not entry.empty then 
            if "" == entry.steamid then
                if "" ~= entry.user_id then
                    widget.NAME:SetString(entry.userid) 
                else
                    widget.NAME:SetString(STRINGS.UI.SERVERADMINSCREEN.UNKNOWN_USER_NAME)
                end
            else
                widget.NAME:SetString(entry.steamname) 
            end          
            
            if "" == entry.character and "" == entry.servername and "" == entry.serverdescription then
                widget.MENU.items[1]:Select()
            end
            -- no steam id means we can't show the profile
            if "" == entry.steamid then
                widget.MENU.items[2]:Select()
            end

            widget.focus_forward = widget.MENU   
        else                           
            widget.NAME:Hide()
            widget.EMPTY:Show()

            widget.MENU:Hide()
        end

        return widget
    end

    local function bannedPlayerRowUpdate(widget, data, index)
        local y_offset = 15
        if data and not data.empty then 
            widget.index = index
                    
            if "" == data.steamid then
                if "" ~= data.user_id then
                    widget.NAME:SetString(data.userid) 
                else
                    widget.NAME:SetString(STRINGS.UI.SERVERADMINSCREEN.UNKNOWN_USER_NAME)
                end
            else
                widget.NAME:SetString(data.steamname) 
            end          
            widget.NAME:Show()
            widget.EMPTY:Hide()
            
            widget.MENU.items[1]:SetOnClick(function() self:ShowPlayerDetails(index) end)
            widget.MENU.items[2]:SetOnClick(function() self:ShowSteamProfile(index) end)
            widget.MENU.items[3]:SetOnClick(function() self:PromptDeletePlayer(index) end)

            if "" == data.character and "" == data.servername and "" == data.serverdescription then
                widget.MENU.items[1]:Select()
            else
                widget.MENU.items[1]:Unselect()
            end
            -- no steam id means we can't show the profile
            if "" == data.steamid then
                widget.MENU.items[2]:Select()
            else
                widget.MENU.items[2]:Unselect()
            end

            widget.MENU:Show()
            widget:Enable()
            widget.focus_forward = widget.MENU
        else
            widget.index = index
                       
            widget.NAME:Hide()
            widget.EMPTY:Show()
            
            widget.MENU:Hide()
            widget.focus_forward = nil
        end
    end

    self.ban_page_scroll_root = self.ban_page:AddChild(Widget("scroll_root"))
    self.ban_page_scroll_root:SetPosition(-80, 0)

    self.ban_page_row_root = self.ban_page:AddChild(Widget("row_root"))
    self.ban_page_row_root:SetPosition(-80, 0)

    self.banned_player_widgets = {}
    for i=1,5 do
        table.insert(self.banned_player_widgets, bannedPlayerRowConstructor(self.blacklist[i] or {empty=true}, i, self.ban_page_row_root))
    end
    self.player_scroll_list = self.ban_page_scroll_root:AddChild(ScrollableList(self.blacklist, 183, 450, 70, 3, bannedPlayerRowUpdate, self.banned_player_widgets, 40, nil, nil, -15))  
    self.player_scroll_list:LayOutStaticWidgets(-55)
    if self.blacklist and #self.blacklist < self.player_scroll_list.widgets_per_view then
        while #self.blacklist < self.player_scroll_list.widgets_per_view do
            table.insert(self.blacklist, {empty=true})
        end
    end
    self.player_scroll_list:SetList(self.blacklist)
    self.player_scroll_list:SetPosition(-152, 0)
end

function BanTab:RefreshPlayers()
    if self.blacklist and #self.blacklist < self.player_scroll_list.widgets_per_view then
        while #self.blacklist < self.player_scroll_list.widgets_per_view do
            table.insert(self.blacklist, {empty=true})
        end
    end
    self.player_scroll_list:SetList(self.blacklist)
    if #self.blacklist == 0 then
        self.clear_button:Disable()
    else
        self.allEmpties = true
        for i,v in pairs(self.blacklist) do
            if v and v.empty == nil or v.empty == false then
                self.allEmpties = false
                break
            end
        end
        if self.allEmpties then
            self.clear_button:Disable()
        else
            self.clear_button:Enable()
        end
    end

    if self.allEmpties then
        self.player_scroll_list:Disable()
    else
        self.player_scroll_list:Enable()
    end
end

function BanTab:ShowPlayerDetails(selected_player)
    if selected_player and self.blacklist[selected_player] then
	    local popup = PlayerDetailsPopup(
	            self.blacklist[selected_player],
			    {{text=STRINGS.UI.SERVERADMINSCREEN.BACK, cb = function() TheFrontEnd:PopScreen() end}}
			)
		TheFrontEnd:PushScreen(popup)
    end
end

function BanTab:ShowSteamProfile(selected_player)
    if selected_player then
        if self.blacklist[selected_player] then
        	--TheFrontEnd:PushScreen(PlayerAvatarPopupScreen(self.blacklist[selected_player].name, self.blacklist[selected_player]))
            TheNet:ViewSteamProfile(self.blacklist[selected_player].steamid)
        end
    end
end

function BanTab:PromptDeletePlayer(selected_player)
    if selected_player then
        local name = ""
        if "" == self.blacklist[selected_player].steamid then
            name = STRINGS.UI.SERVERADMINSCREEN.UNKNOWN_USER_NAME
        else
            name = self.blacklist[selected_player].steamname
        end
        local popup = PopupDialogScreen(STRINGS.UI.SERVERADMINSCREEN.DELETE_ENTRY_TITLE, STRINGS.UI.SERVERADMINSCREEN.DELETE_ENTRY_BODY..name..STRINGS.UI.SERVERADMINSCREEN.DELETE_ENTRY_BODY_2, 
		    {{text=STRINGS.UI.SERVERADMINSCREEN.YES, cb = function() 			
                self:DeletePlayer(selected_player)
                TheFrontEnd:PopScreen()		        
		    end},
		    {text=STRINGS.UI.SERVERADMINSCREEN.NO, cb = function() 
                TheFrontEnd:PopScreen() 
            end}})
	    TheFrontEnd:PushScreen(popup)		
    end	      
end

function BanTab:DeletePlayer(selected_player)
    if selected_player then                
        table.remove(self.blacklist, selected_player)    

        local list = {}
        for i,v in pairs(self.blacklist) do
            if v and not v.empty then
                table.insert(list, v)
            end
        end
        TheNet:SetBlacklist(list)
                
        self:RefreshPlayers()        
    end       
end

function BanTab:ClearPlayers()
    local popup = PopupDialogScreen(STRINGS.UI.SERVERADMINSCREEN.CLEAR_LIST_TITLE, STRINGS.UI.SERVERADMINSCREEN.CLEAR_LIST_BODY, 
		{{text=STRINGS.UI.SERVERADMINSCREEN.YES, cb = function() 			
            self.blacklist = {}
            TheNet:SetBlacklist(self.blacklist)
            self:RefreshPlayers()
		    TheFrontEnd:PopScreen()
		end},
		{text=STRINGS.UI.SERVERADMINSCREEN.NO, cb = function() TheFrontEnd:PopScreen() end}  })
	TheFrontEnd:PushScreen(popup)		
end

function BanTab:MakeMenuButtons()    
    self.clear_button = self.ban_page:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "unbanall.tex", STRINGS.UI.SERVERADMINSCREEN.CLEAR_PLAYERS, true, false, function() self:ClearPlayers() end))
    self.clear_button:SetPosition(270, -155)
    if #self.blacklist == 0 then
        self.clear_button:Disable()
    else
        self.allEmpties = true
        for i,v in pairs(self.blacklist) do
            if v and v.empty == nil or v.empty == false then
                self.allEmpties = false
                break
            end
        end
        if self.allEmpties then
            self.clear_button:Disable()
        else
            self.clear_button:Enable()
        end
    end

    if TheInput:ControllerAttached() then
        self.clear_button:Hide()
    end

    self.servercreationscreen.create_button:SetFocusChangeDir(MOVE_UP, self.clear_button)
    self.clear_button:SetFocusChangeDir(MOVE_DOWN, self.servercreationscreen.create_button)
end

function BanTab:OnControl(control, down)
    if BanTab._base.OnControl(self, control, down) then return true end
    
    if not down then 
        if TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse then 
            if control == CONTROL_INSPECT then 
                self:ClearPlayers()
                return true
            end
        end
    end

end

function BanTab:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}

    if not self.allEmpties then
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_INSPECT) .. " " .. STRINGS.UI.SERVERADMINSCREEN.CLEAR_PLAYERS_HELPTEXT)
    end
    
    return table.concat(t, "  ")
end

return BanTab
