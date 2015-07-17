local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Spinner = require "widgets/spinner"
local NumericSpinner = require "widgets/numericspinner"
local TextEdit = require "widgets/textedit"
local ScrollableList = require "widgets/scrollablelist"
local PopupDialogScreen = require "screens/popupdialog"
local TEMPLATES = require "widgets/templates"

local label_height = 40
local edit_width = 500
local space_between = 17
local font_size = 25
if JapaneseOnPS4() then
    font_size = 25 * 0.75;
end
local textbox_font_ratio = .8

local VALID_CHARS = [[ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:;[]\@!#$%&()'*+-/=?^_{|}~"]]
local VALID_PASSWORD_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local STRING_MAX_LENGTH = 254 -- http://tools.ietf.org/html/rfc5321#section-4.5.3.1
local SERVER_NAME_MAX_LENGTH = 80

local ServerSettingsTab = Class(Widget, function(self, slotdata, servercreationscreen)
    Widget._ctor(self, "ServerSettingsTab")

    self.slotdata = slotdata or {}

    self.servercreationscreen = servercreationscreen
  
    self.server_settings_page = self:AddChild(Widget("server_settings_page"))

    self.left_line = self.server_settings_page:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
    self.left_line:SetScale(1, .6)
    self.left_line:SetPosition(-530, 5, 0)

    self.server_name = Widget("name")
    self.server_name.line = self.server_name:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
    self.server_name.line:SetScale(1.2, .85)
    self.server_name.label = self.server_name:AddChild(Text(NEWFONT, 25))
    self.server_name.label:SetString(STRINGS.UI.SERVERCREATIONSCREEN.SERVERNAME)
    self.server_name.label:SetHAlign(ANCHOR_RIGHT)
    self.server_name.label:SetRegionSize(200,70)
    self.server_name.label:SetPosition(-230,0)
    self.server_name.label:SetColour(0,0,0,1)
    local w,h = self.server_name.label:GetRegionSize()
    self.server_name.textbox_bg = self.server_name.label:AddChild( Image("images/textboxes.xml", "textbox2_grey.tex") )
    self.server_name.textbox_bg:ScaleToSize(edit_width - w + space_between, label_height )
    self.server_name.textbox_bg:SetPosition( edit_width - 240, 0, 0)
    self.server_name.textbox = self.server_name.label:AddChild(TextEdit( NEWFONT, font_size*textbox_font_ratio, TheNet:GetDefaultServerName(), {0,0,0,1} ) )
    self.server_name.textbox:SetForceEdit(true)
    self.server_name.textbox:SetPosition(edit_width - 225 - space_between/2-5, 0, 0)
    self.server_name.textbox:SetRegionSize( edit_width - w - space_between+10, label_height )
    self.server_name.textbox:SetHAlign(ANCHOR_LEFT)
    self.server_name.textbox:SetFocusedImage( self.server_name.textbox_bg, "images/textboxes.xml", "textbox2_grey.tex", "textbox2_gold.tex", "textbox2_gold_greyfill.tex" )
    self.server_name.textbox:SetTextLengthLimit( SERVER_NAME_MAX_LENGTH )
    self.server_name.textbox:SetCharacterFilter( VALID_CHARS )
    
    self.server_name.textbox.OnTextInputted = function()
  		self.servercreationscreen:UpdateTitle(self.servercreationscreen.saveslot, true)
        self.servercreationscreen:MakeDirty()
   	end
    
    local screen = self
    self.server_name.OnGainFocus = function(self)
        Widget.OnGainFocus(self)
        screen.server_name.textbox:OnGainFocus()
    end
    self.server_name.OnLoseFocus = function(self)
        Widget.OnLoseFocus(self)
        screen.server_name.textbox:OnLoseFocus()
    end
    self.server_name.GetHelpText = function(self)
        local controller_id = TheInput:GetControllerID()
        local t = {}
        if not screen.server_name.textbox.editing and not screen.server_name.textbox.focus then
            table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT, false, false ) .. " " .. STRINGS.UI.HELP.CHANGE_TEXT)   
        end
        return table.concat(t, "  ")
    end

    self.server_pw = Widget("pw")
    self.server_pw.line = self.server_pw:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
    self.server_pw.line:SetScale(1.2, .85)
    self.server_pw.label = self.server_pw:AddChild(Text(NEWFONT, 25))
    self.server_pw.label:SetString(STRINGS.UI.SERVERCREATIONSCREEN.SERVERPASSWORD)
    self.server_pw.label:SetHAlign(ANCHOR_RIGHT)
    self.server_pw.label:SetRegionSize(200,70)
    self.server_pw.label:SetPosition(-230,0)
    self.server_pw.label:SetColour(0,0,0,1)
    local w,h = self.server_pw.label:GetRegionSize()
    self.server_pw.textbox_bg = self.server_pw.label:AddChild( Image("images/textboxes.xml", "textbox2_grey.tex") )
    self.server_pw.textbox_bg:ScaleToSize(edit_width - w + space_between, label_height )
    self.server_pw.textbox_bg:SetPosition( edit_width - 240, 0, 0)
    self.server_pw.textbox = self.server_pw.label:AddChild(TextEdit( NEWFONT, font_size*textbox_font_ratio, TheNet:GetDefaultServerPassword(), {0,0,0,1} ) )
    self.server_pw.textbox:SetForceEdit(true)
    self.server_pw.textbox:SetPosition(edit_width - 225 - space_between/2-5, 0, 0)
    self.server_pw.textbox:SetRegionSize( edit_width - w - space_between+10, label_height )
    self.server_pw.textbox:SetHAlign(ANCHOR_LEFT)
    self.server_pw.textbox:SetFocusedImage( self.server_pw.textbox_bg, "images/textboxes.xml", "textbox2_grey.tex", "textbox2_gold.tex", "textbox2_gold_greyfill.tex" )
    self.server_pw.textbox:SetTextLengthLimit( STRING_MAX_LENGTH )
    self.server_pw.textbox:SetCharacterFilter( VALID_PASSWORD_CHARS )
    
    -- if not Profile:GetShowPasswordEnabled() then
        -- self.server_pw.textbox:SetPassword(true)
    -- end
    self.server_pw.OnGainFocus = function(self)
        Widget.OnGainFocus(self)
        screen.server_pw.textbox:OnGainFocus()
    end
    self.server_pw.OnLoseFocus = function(self)
        Widget.OnLoseFocus(self)
        screen.server_pw.textbox:OnLoseFocus()
    end
    self.server_pw.GetHelpText = function(self)
        local controller_id = TheInput:GetControllerID()
        local t = {}
        if not screen.server_pw.textbox.editing and not screen.server_pw.textbox.focus then
            table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT, false, false ) .. " " .. STRINGS.UI.HELP.CHANGE_TEXT)   
        end
        return table.concat(t, "  ")
    end
    self.server_pw.textbox.OnTextInputted = function()
        self.servercreationscreen:MakeDirty()
    end

    self.server_desc = Widget("desc")
    self.server_desc.line = self.server_desc:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
    self.server_desc.line:SetScale(1.2, .85)
    self.server_desc.label = self.server_desc:AddChild(Text(NEWFONT, 25))
    self.server_desc.label:SetString(STRINGS.UI.SERVERCREATIONSCREEN.SERVERDESC)
    self.server_desc.label:SetHAlign(ANCHOR_RIGHT)
    self.server_desc.label:SetRegionSize(200,70)
    self.server_desc.label:SetPosition(-230,0)
    self.server_desc.label:SetColour(0,0,0,1)
    local w,h = self.server_desc.label:GetRegionSize()
    self.server_desc.textbox_bg = self.server_desc.label:AddChild( Image("images/textboxes.xml", "textbox2_grey.tex") )
    self.server_desc.textbox_bg:ScaleToSize(edit_width - w + space_between, label_height )
    self.server_desc.textbox_bg:SetPosition( edit_width - 240, 0, 0)
    self.server_desc.textbox = self.server_desc.label:AddChild(TextEdit( NEWFONT, font_size*textbox_font_ratio, TheNet:GetDefaultServerDescription(), {0,0,0,1} ) )
    self.server_desc.textbox:SetForceEdit(true)
    self.server_desc.textbox:SetPosition(edit_width - 225 - space_between/2-5, 0, 0)
    self.server_desc.textbox:SetRegionSize( edit_width - w - space_between+10, label_height )
    self.server_desc.textbox:SetHAlign(ANCHOR_LEFT)
    self.server_desc.textbox:SetFocusedImage( self.server_desc.textbox_bg, "images/textboxes.xml", "textbox2_grey.tex", "textbox2_gold.tex", "textbox2_gold_greyfill.tex" )
    self.server_desc.textbox:SetTextLengthLimit( STRING_MAX_LENGTH )
    self.server_desc.textbox:SetCharacterFilter( VALID_CHARS )
    
    self.server_desc.OnGainFocus = function(self)
        Widget.OnGainFocus(self)
        screen.server_desc.textbox:OnGainFocus()
    end
    self.server_desc.OnLoseFocus = function(self)
        Widget.OnLoseFocus(self)
        screen.server_desc.textbox:OnLoseFocus()
    end
    self.server_desc.GetHelpText = function(self)
        local controller_id = TheInput:GetControllerID()
        local t = {}
        if not screen.server_desc.textbox.editing and not screen.server_desc.textbox.focus then
            table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT, false, false ) .. " " .. STRINGS.UI.HELP.CHANGE_TEXT)   
        end
        return table.concat(t, "  ")
    end
    self.server_desc.textbox.OnTextInputted = function()
        self.servercreationscreen:MakeDirty()
    end

    self.server_name.textbox:SetOnTabGoToTextEditWidget(function()
        if self.server_pw.textbox:IsVisible() then
            return self.server_pw.textbox
        elseif self.server_desc.textbox:IsVisible() then
            return self.server_desc.textbox
        else
            return nil
        end        
    end)
    self.server_pw.textbox:SetOnTabGoToTextEditWidget(function()
        if self.server_desc.textbox:IsVisible() then
            return self.server_desc.textbox
        elseif self.server_name.textbox:IsVisible() then
            return self.server_name.textbox
        else
            return nil
        end  
    end)
    self.server_desc.textbox:SetOnTabGoToTextEditWidget(function()
        if self.server_name.textbox:IsVisible() then
            return self.server_name.textbox
        elseif self.server_pw.textbox:IsVisible() then
            return self.server_pw.textbox
        else
            return nil
        end  
    end)

    local label_x = -20
    local spinner_x = 65
    local spinner_y = -2
    local spinner_scale_x = .76
    local spinner_scale_y = .63

    self.game_mode = Widget( "SpinnerGroup" )   
    self.game_mode.line = self.game_mode:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
    self.game_mode.line:SetScale(1.2, .85)
    self.game_mode.label = self.game_mode:AddChild( Text( NEWFONT, 25, STRINGS.UI.SERVERCREATIONSCREEN.GAMEMODE) )
    self.game_mode.label:SetPosition( -self.game_mode.label:GetRegionSize()/2 + label_x, 0, 0 )
    self.game_mode.label:SetHAlign( ANCHOR_RIGHT )
    self.game_mode.label:SetColour(0,0,0,1)
    self.game_mode.spinner = self.game_mode:AddChild(Spinner( GetGameModesSpinnerData(SaveGameIndex:GetEnabledMods(self.saveslot)),210,64,{font=NEWFONT, size=font_size},nil,nil,nil,true,nil,nil, spinner_scale_x, spinner_scale_y ))
    self.game_mode.spinner:SetPosition( spinner_x, spinner_y, 0 )
    self.game_mode.spinner:SetTextColour(0,0,0,1)
    self.game_mode.focus_forward = self.game_mode.spinner
    self.game_mode.spinner:SetOnChangedFn(function()
        self.servercreationscreen:MakeDirty()
    end)

    self.game_mode.info_button = self.game_mode:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "info.tex", "", false, false, function() 
            local mode_title = GetGameModeString( self.game_mode.spinner:GetSelectedData() )
            if mode_title == "" then
                mode_title = STRINGS.UI.GAMEMODES.UNKNOWN
            end
            local mode_body = GetGameModeDescriptionString( self.game_mode.spinner:GetSelectedData() )
            if mode_body == "" then
                mode_body = STRINGS.UI.GAMEMODES.UNKNOWN_DESCRIPTION
            end
            TheFrontEnd:PushScreen(PopupDialogScreen(
                    mode_title, 
                    mode_body, 
                    {{ text = STRINGS.UI.SERVERLISTINGSCREEN.OK, cb = function() TheFrontEnd:PopScreen() end }}))
        end))
    self.game_mode.info_button:SetPosition(160, -2)
    self.game_mode.info_button:SetScale(.4)
    self.game_mode.info_button:SetFocusChangeDir(MOVE_LEFT, self.game_mode.spinner)
    self.game_mode.spinner:SetFocusChangeDir(MOVE_RIGHT, self.game_mode.info_button)

    self.max_players = Widget( "SpinnerGroup" )
    self.max_players.line = self.max_players:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
    self.max_players.line:SetScale(1.2, .85)
    self.max_players.label = self.max_players:AddChild( Text( NEWFONT, 25, STRINGS.UI.SERVERCREATIONSCREEN.MAXPLAYERS) )
    self.max_players.label:SetPosition( -self.max_players.label:GetRegionSize()/2 + label_x, 0, 0 )
    self.max_players.label:SetHAlign( ANCHOR_RIGHT )
    self.max_players.label:SetColour(0,0,0,1)
    local numplayer_options = {}
    for i=2, TUNING.MAX_SERVER_SIZE do
        table.insert(numplayer_options,{text=i, data=i})
    end
    self.max_players.spinner = self.max_players:AddChild(Spinner(numplayer_options,210,64,{font=NEWFONT, size=font_size},nil,nil,nil,true,nil,nil, spinner_scale_x, spinner_scale_y ))
    self.max_players.spinner:SetPosition( spinner_x, spinner_y, 0 )
    self.max_players.spinner:SetTextColour(0,0,0,1)
    self.max_players.focus_forward = self.max_players.spinner
    self.max_players.spinner:SetSelected(TheNet:GetDefaultMaxPlayers())
    self.max_players.spinner:SetOnChangedFn(function() self.servercreationscreen:MakeDirty() end)

    self.pvp = Widget( "SpinnerGroup" )
    self.pvp.line = self.pvp:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
    self.pvp.line:SetScale(1.2, .85)
    self.pvp.label = self.pvp:AddChild( Text( NEWFONT, 25, STRINGS.UI.SERVERCREATIONSCREEN.PVP) )
    self.pvp.label:SetPosition( -self.pvp.label:GetRegionSize()/2 + label_x, 0, 0 )
    self.pvp.label:SetHAlign( ANCHOR_RIGHT )
    self.pvp.label:SetColour(0,0,0,1)
    self.pvp.spinner = self.pvp:AddChild(Spinner({{ text = STRINGS.UI.SERVERLISTINGSCREEN.OFF, data = false }, { text = STRINGS.UI.SERVERLISTINGSCREEN.ON, data = true }},210,64,{font=NEWFONT, size=font_size},nil,nil,nil, true,nil,nil, spinner_scale_x, spinner_scale_y ))
    self.pvp.spinner:SetPosition( spinner_x, spinner_y, 0 )
    self.pvp.spinner:SetTextColour(0,0,0,1)
    self.pvp.focus_forward = self.pvp.spinner
    self.pvp.spinner:SetOnChangedFn(function() self.servercreationscreen:MakeDirty() end)

    self.friends_only = Widget( "SpinnerGroup" )
    self.friends_only.line = self.friends_only:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
    self.friends_only.line:SetScale(1.2, .85)
    self.friends_only.label = self.friends_only:AddChild( Text( NEWFONT, 25, STRINGS.UI.SERVERCREATIONSCREEN.FRIENDSONLY) )
    self.friends_only.label:SetPosition( -self.friends_only.label:GetRegionSize()/2 + label_x, 0, 0 )
    self.friends_only.label:SetHAlign( ANCHOR_RIGHT )
    self.friends_only.label:SetColour(0,0,0,1)
    self.friends_only.spinner = self.friends_only:AddChild(Spinner({{ text = STRINGS.UI.SERVERLISTINGSCREEN.OFF, data = false }, { text = STRINGS.UI.SERVERLISTINGSCREEN.ON, data = true  }},210,64,{font=NEWFONT, size=font_size},nil,nil,nil, true,nil,nil, spinner_scale_x, spinner_scale_y ))
    self.friends_only.spinner:SetPosition( spinner_x, spinner_y, 0 )
    self.friends_only.spinner:SetTextColour(0,0,0,1)
    self.friends_only.focus_forward = self.friends_only.spinner
    self.friends_only.spinner:SetOnChangedFn(function() self.servercreationscreen:MakeDirty() end)
    
    self.online_mode = Widget( "SpinnerGroup" )
    self.online_mode.line = self.online_mode:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
    self.online_mode.line:SetScale(1.2, .85)
    self.online_mode.label = self.online_mode:AddChild( Text( NEWFONT, 25, STRINGS.UI.SERVERCREATIONSCREEN.SERVERTYPE) )
    self.online_mode.label:SetPosition( -self.online_mode.label:GetRegionSize()/2 + label_x, 0, 0 )
    self.online_mode.label:SetHAlign( ANCHOR_RIGHT )
    self.online_mode.label:SetColour(0,0,0,1)
    self.online_mode.spinner = self.online_mode:AddChild(Spinner({{ text = STRINGS.UI.SERVERLISTINGSCREEN.ONLINE, data = true }, { text = STRINGS.UI.SERVERLISTINGSCREEN.LAN, data = false  }},210,64,{font=NEWFONT, size=font_size},nil,nil,nil, true,nil,nil, spinner_scale_x, spinner_scale_y ))
    self.online_mode.spinner:SetPosition( spinner_x, spinner_y, 0 )
    self.online_mode.spinner:SetTextColour(0,0,0,1)
    self.online_mode.focus_forward = self.online_mode.spinner
    self.online_mode.spinner:SetOnChangedFn(function()
        self.servercreationscreen:MakeDirty()
        if self.online_mode.spinner:GetSelectedData() == false then
            self.friendssetting = self.friends_only.spinner:GetSelectedData()
            self.friends_only.spinner:SetSelected(false)
            self.friends_only.spinner:Disable()
        else
            self.friends_only.spinner:SetSelected(self.friendssetting)
            self.friends_only.spinner:Enable()
        end
    end)
    
    if not TheNet:IsOnlineMode() or TheFrontEnd:GetIsOfflineMode() then
		self.online_mode.spinner:Disable()
        self.online_mode.spinner:SetSelected(false)
        self.friends_only.spinner:Disable()
        self.friends_only.spinner:SetSelected(false)
    end

    self.page_widgets = 
    {
        self.server_name,
        self.server_pw,
        self.server_desc,
        self.game_mode,
        self.pvp,
        self.max_players,
        self.friends_only,
        self.online_mode,
    }
    self.scroll_list = self.server_settings_page:AddChild(ScrollableList(self.page_widgets, 270, 360, 35, 10))
    self.scroll_list:SetPosition(20,0)

    self.default_focus = self.scroll_list
    self.focus_forward = self.scroll_list
end)

function ServerSettingsTab:OnControl(control, down)
    if ServerSettingsTab._base.OnControl(self, control, down) then return true end


    -- Force these damn things to gobble controls if they're editing (stupid missing focus/hover distinction)
    if (self.server_name.textbox and self.server_name.textbox.editing) or (TheInput:ControllerAttached() and self.server_name.focus and control == CONTROL_ACCEPT) then
        self.server_name.textbox:OnControl(control, down)
        return true
    elseif (self.server_pw.textbox and self.server_pw.textbox.editing) or (TheInput:ControllerAttached() and self.server_pw.focus and control == CONTROL_ACCEPT) then
        self.server_pw.textbox:OnControl(control, down)
        return true
    elseif (self.server_desc.textbox and self.server_desc.textbox.editing) or (TheInput:ControllerAttached() and self.server_desc.focus and control == CONTROL_ACCEPT)  then
        self.server_desc.textbox:OnControl(control, down)
        return true
    end
end


function ServerSettingsTab:UpdateDetails(slotnum, prevslot, fromDelete)
    
    self.game_mode.spinner:SetOptions( GetGameModesSpinnerData( SaveGameIndex:GetEnabledMods(slotnum) ) )
    
    -- No save data
    if slotnum < 0 or SaveGameIndex:IsSlotEmpty(slotnum) then
        -- no slot, so hide all the details and set all the text boxes back to their defaults
        if prevslot and prevslot > 0 then
            -- Remember what was typed/set
            self.slotdata[prevslot] =
            {
                pvp = self.pvp.spinner:GetSelectedData(),
                game_mode = self.game_mode.spinner:GetSelectedData(),
                friends_only = self.friends_only.spinner:GetSelectedData(),
                online_mode = self.online_mode.spinner:GetSelectedData(),-- and TheNet:IsOnlineMode(),
                max_players = self.max_players.spinner:GetSelectedData(),
                server_name = self.server_name.textbox:GetString(),
                server_pw = self.server_pw.textbox:GetLineEditString(),
                server_desc = self.server_desc.textbox:GetString(),
            }
            
            
            -- Duplicate prevslot's data into our new slot if it was also a blank slot
            if not fromDelete and SaveGameIndex:IsSlotEmpty(prevslot) then
                self.slotdata[slotnum] =
                {
                    pvp = self.pvp.spinner:GetSelectedData(),
                    game_mode = self.game_mode.spinner:GetSelectedData(),
                    friends_only = self.friends_only.spinner:GetSelectedData(),
                    online_mode = self.online_mode.spinner:GetSelectedData(),-- and TheNet:IsOnlineMode(),
                    max_players = self.max_players.spinner:GetSelectedData(),
                    server_name = self.server_name.textbox:GetString(),
                    server_pw = self.server_pw.textbox:GetLineEditString(),
                    server_desc = self.server_desc.textbox:GetString(),
                }
            end
        end

        -- Wipe the current slot if we're updating due to a delete
        if fromDelete then
            self.slotdata[slotnum] = {}
        end

        local pvp = false
        if self.slotdata[slotnum] ~= nil and self.slotdata[slotnum].pvp ~= nil then
            pvp = self.slotdata[slotnum].pvp
        end
        local online = true
        if self.slotdata[slotnum] ~= nil and self.slotdata[slotnum].online_mode ~= nil then
            online = self.slotdata[slotnum].online_mode
        end 
        self.game_mode.spinner:SetSelected(self.slotdata[slotnum] and self.slotdata[slotnum].game_mode or DEFAULT_GAME_MODE )
        self.pvp.spinner:SetSelected(pvp)
        self.max_players.spinner:SetSelected(self.slotdata[slotnum] and self.slotdata[slotnum].max_players or TUNING.MAX_SERVER_SIZE)
        self.server_name.textbox:SetString(self.slotdata[slotnum] and self.slotdata[slotnum].server_name or TheNet:GetLocalUserName()..STRINGS.UI.SERVERCREATIONSCREEN.NEWGAME_SUFFIX)
        self.server_pw.textbox:SetString(self.slotdata[slotnum] and self.slotdata[slotnum].server_pw or "")
        self.server_desc.textbox:SetString(self.slotdata[slotnum] and self.slotdata[slotnum].server_desc or "")

		if TheNet:IsOnlineMode() and not TheFrontEnd:GetIsOfflineMode() then
            self.online_mode.spinner:SetSelected(online)
            self.friends_only.spinner:SetSelected(self.slotdata[slotnum] and self.slotdata[slotnum].friends_only or false)
			self.online_mode.spinner:Enable()
            self.friends_only.spinner:Enable()
        else
            self.online_mode.spinner:SetSelected(false)
            self.friends_only.spinner:SetSelected(false)
            self.online_mode.spinner:Disable()
            self.friends_only.spinner:Disable()
        end

        self.game_mode.spinner:Enable()
		
    else -- Save data
        if prevslot and prevslot > 0 then
            -- remember what was typed/set
            self.slotdata[prevslot] =
            {
                pvp = self.pvp.spinner:GetSelectedData(),
                game_mode = self.game_mode.spinner:GetSelectedData(),
                friends_only = self.friends_only.spinner:GetSelectedData(),
                online_mode = self.online_mode.spinner:GetSelectedData(),
                max_players = self.max_players.spinner:GetSelectedData(),
                server_name = self.server_name.textbox:GetString(),
                server_pw = self.server_pw.textbox:GetLineEditString(),
                server_desc = self.server_desc.textbox:GetString(),
            }
        end
            
        -- world = 1, -- world (i.e. teleportato) doesn't exist yet, but leaving this here as a reminder
        -- waiting on hooks for char details
        
        local server_data = SaveGameIndex:GetSlotServerData(slotnum)
        if server_data ~= nil then
            local pvp = false
            if self.slotdata[slotnum] ~= nil and self.slotdata[slotnum].pvp ~= nil then
                pvp = self.slotdata[slotnum].pvp
            else
                pvp = server_data.pvp
            end
            local online = true
            if self.slotdata[slotnum] ~= nil and self.slotdata[slotnum].online_mode ~= nil then
                online = self.slotdata[slotnum].online_mode
            else
                online = server_data.online_mode
            end 
            self.game_mode.spinner:SetSelected(self.slotdata[slotnum] and self.slotdata[slotnum].game_mode or (server_data.game_mode ~= nil and server_data.game_mode or DEFAULT_GAME_MODE ))
            self.pvp.spinner:SetSelected(pvp)

            self.friends_only.spinner:SetSelected(self.slotdata[slotnum] and self.slotdata[slotnum].friends_only or server_data.friends_only)
            self.online_mode.spinner:SetSelected(online)
            self.max_players.spinner:SetSelected(self.slotdata[slotnum] and self.slotdata[slotnum].max_players or server_data.maxplayers)
            self.server_name.textbox:SetString(self.slotdata[slotnum] and self.slotdata[slotnum].server_name or server_data.name)
            self.server_pw.textbox:SetString(self.slotdata[slotnum] and self.slotdata[slotnum].server_pw or server_data.password)
            self.server_desc.textbox:SetString(self.slotdata[slotnum] and self.slotdata[slotnum].server_desc or server_data.description)
        end
		
		-- No editing online or game mode for servers that have already been created
		self.online_mode.spinner:Disable()
        self.game_mode.spinner:Disable()
        if self.online_mode.spinner:GetSelectedData() == false then
            self.friends_only.spinner:Disable()
        else
            self.friends_only.spinner:Enable()
        end
    end
end

function ServerSettingsTab:GetServerName()
	return self.server_name.textbox:GetString()
end

function ServerSettingsTab:GetServerDescription()
	return self.server_desc.textbox:GetString()
end

function ServerSettingsTab:GetPassword()
	return self.server_pw.textbox:GetLineEditString()
end

function ServerSettingsTab:GetGameMode()
	return self.game_mode.spinner:GetSelectedData()
end

function ServerSettingsTab:GetMaxPlayers()
	return self.max_players.spinner:GetSelectedData()
end

function ServerSettingsTab:GetPVP()
	return self.pvp.spinner:GetSelectedData()
end

function ServerSettingsTab:GetFriendsOnly()
	return self.friends_only.spinner:GetSelectedData()
end

function ServerSettingsTab:GetOnlineMode()
	return self.online_mode.spinner:GetSelectedData()
end

function ServerSettingsTab:SetEditingTextboxes(edit)
	self.server_name.textbox:SetEditing(edit)
	self.server_pw.textbox:SetEditing(edit)
	self.server_desc.textbox:SetEditing(edit)
end

return ServerSettingsTab