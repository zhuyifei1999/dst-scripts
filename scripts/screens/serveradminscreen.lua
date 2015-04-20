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
local Spinner = require "widgets/spinner"
local UIAnim = require "widgets/uianim"

local ScrollableList = require "widgets/scrollablelist"
local OnlineStatus = require "widgets/onlinestatus"

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

local screen_fade_time = .25


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
    btn:SetFont(BUTTONFONT)
    btn:SetTextSize(40)
    btn:SetOnClick(onclick)

    return btn
end

local function GetAvatar(character)

    local avatarname
    --#srosen this should eventually be a more robust check of whether or not the (mod) character has a valid badge
    if not character or character == "" or not table.contains(DST_CHARACTERLIST, character) then
        avatarname = "unknown" 
    else
        avatarname = character
    end
    
    return "avatar_".. avatarname ..".tex"
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

    self.onlinestatus = self.root:AddChild(OnlineStatus())
    self.onlinestatus:SetHAnchor(ANCHOR_RIGHT)
    self.onlinestatus:SetVAnchor(ANCHOR_BOTTOM)
    
    self.details_panel = self.root:AddChild(Widget("player_detail_panel"))
    self.details_panel:SetPosition(0,-10,0)
    self.details_panelbg = self.details_panel:AddChild(Image("images/fepanels_dst.xml", "wide_panel.tex"))
 
    self.details_playername = self.details_panel:AddChild(Text(BUTTONFONT, 44))
    self.details_playername:SetHAlign(ANCHOR_MIDDLE)
    self.details_playername:SetVAlign(ANCHOR_TOP)
    self.details_playername:SetPosition(30, 110, 0)
    self.details_playername:SetColour(0,0,0,1)
    
    if "" == entry.steamid then
        self.details_playername:SetString(STRINGS.UI.SERVERADMINSCREEN.UNKNOWN_USER_NAME)   
    else
        self.details_playername:SetString(entry.steamname)   
    end
    
    self.details_icon = self.details_panel:AddChild(Widget("target"))
    self.details_icon:SetScale(.8)
    local w,h = self.details_playername:GetRegionSize()
    self.details_icon:SetPosition(-w/2 - 30, 115)
    self.details_headbg = self.details_icon:AddChild(Image("images/avatars.xml", "avatar_bg.tex"))
    self.details_headicon = self.details_icon:AddChild(Image("images/avatars.xml", "avatar_bg.tex"))
    self.details_headicon:SetTexture("images/avatars.xml", GetAvatar(entry.character))
    self.details_headframe = self.details_icon:AddChild(Image("images/avatars.xml", "avatar_frame_white.tex"))
    self.details_headframe:SetTint(.5,.5,.5,1)
    
    self.details_date_label = self.details_panel:AddChild(Text(BUTTONFONT, 36))
    self.details_date_label:SetHAlign(ANCHOR_RIGHT)
    self.details_date_label:SetPosition(-200, 40, 0)
    self.details_date_label:SetRegionSize( 120, 40 )
    self.details_date_label:SetString(STRINGS.UI.SERVERADMINSCREEN.BANNED)
    self.details_date_label:SetColour(0,0,0,1)
    
    self.details_date = self.details_panel:AddChild(Text(BUTTONFONT, 36))
    self.details_date:SetHAlign(ANCHOR_LEFT)
    self.details_date:SetPosition(80, 40, 0)
    self.details_date:SetRegionSize( 400, 40 )
    if entry.date then
        self.details_date:SetString(entry.date)        
    else
        self.details_date:SetString(STRINGS.UI.SERVERADMINSCREEN.UNKNOWN)        
    end
    self.details_date:SetColour(0,0,0,1)
    
    self.details_servername_label = self.details_panel:AddChild(Text(BUTTONFONT, 36))
    self.details_servername_label:SetHAlign(ANCHOR_RIGHT)
    self.details_servername_label:SetPosition(-200, -10, 0)
    self.details_servername_label:SetRegionSize( 120, 80 )
    self.details_servername_label:SetString(STRINGS.UI.SERVERADMINSCREEN.SERVER_NAME)
    self.details_servername_label:SetColour(0,0,0,1)
    
    self.details_servername = self.details_panel:AddChild(Text(BUTTONFONT, 36))
    self.details_servername:SetHAlign(ANCHOR_LEFT)
    self.details_servername:SetVAlign(ANCHOR_TOP)
    self.details_servername:SetPosition(80, -30, 0)
    self.details_servername:SetRegionSize( 400, 80 )
    self.details_servername:EnableWordWrap( true )
    if entry.servername then
        self.details_servername:SetString(entry.servername)        
    else
        self.details_servername:SetString(STRINGS.UI.SERVERADMINSCREEN.UNKNOWN)        
    end
    self.details_servername:SetColour(0,0,0,1)
    
    self.details_serverdescription_label = self.details_panel:AddChild(Text(BUTTONFONT, 30))
    self.details_serverdescription_label:SetHAlign(ANCHOR_RIGHT)
    self.details_serverdescription_label:SetPosition(-200, -80, 0)
    self.details_serverdescription_label:SetRegionSize( 120, 90 )
    self.details_serverdescription_label:SetString(STRINGS.UI.SERVERADMINSCREEN.SERVER_DESCRIPTION)
    self.details_serverdescription_label:SetColour(0,0,0,1)
        
    self.details_serverdescription = self.details_panel:AddChild(Text(BUTTONFONT, 30))
    self.details_serverdescription:SetHAlign(ANCHOR_LEFT)
    self.details_serverdescription:SetVAlign(ANCHOR_TOP)
    self.details_serverdescription:SetPosition(80, -110, 0)
    self.details_serverdescription:SetRegionSize( 400, 90 )
    self.details_serverdescription:EnableWordWrap( true )
    if entry.serverdescription then
        self.details_serverdescription:SetString(entry.serverdescription)        
    else
        self.details_serverdescription:SetString(STRINGS.UI.SERVERADMINSCREEN.UNKNOWN)        
    end
    self.details_serverdescription:SetColour(0,0,0,1)
      
    local spacing = 200
	self.menu = self.root:AddChild(Menu(buttons, spacing, true))
	self.menu:SetPosition(-(spacing*(#buttons-1))/2, -200, 0) 
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

local ServerAdminScreen = Class(Screen, function(self, save_slot, in_game, cb)
    Widget._ctor(self, "ServerAdminScreen")

    self.cb = cb
    self.restored_snapshot = false
        	
    self.bg = self:AddChild(Image("images/bg_plain.xml", "bg.tex"))
    TintBackground(self.bg)
	
	self.save_slot = save_slot
	self.session_id = SaveGameIndex:GetSlotSession(save_slot)
    self.online_mode = SaveGameIndex:GetSlotServerData(save_slot).online_mode
	self.in_game = in_game
	
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

    
    local left_col = -RESOLUTION_X*.05 - 260
    local right_col = RESOLUTION_X*.40 - 130
    
    self.blacklist = TheNet:GetBlacklist()    
    self.blacklist_clean = deepcopy(self.blacklist)
    self:MakePlayerPanel(left_col, right_col)
    
    self.snapshots = nil
    self:ListSnapshots()
	
    self:MakeSnapshotPanel(left_col, right_col)
    
    self:MakeMenuButtons(left_col, right_col)

    self.onlinestatus = self.root:AddChild(OnlineStatus())
    self.onlinestatus:SetHAnchor(ANCHOR_RIGHT)
    self.onlinestatus:SetVAnchor(ANCHOR_BOTTOM)

    self:MakePlayersClean()
    
end)

function ServerAdminScreen:MakePlayerPanel(left_col, right_col)
        
    self.player_list = self.root:AddChild(Widget("player_list"))
    self.player_list:SetPosition(left_col,0,5)
    self.player_listbg = self.player_list:AddChild(Image("images/fepanels_dst.xml", "wide_panel.tex"))--"images/fepanels.xml", "panel_controls.tex")) --"images/serverbrowser.xml", "browser_grid.tex"
    -- self.player_listbg:SetScale(1.0, 1.05)
    self.player_listbg:SetScale(.8, 1.35)
            
    self.player_list_header = self.player_list:AddChild(Text(BUTTONFONT, 44))
    self.player_list_header:SetHAlign(ANCHOR_MIDDLE)
    self.player_list_header:SetVAlign(ANCHOR_TOP)
    self.player_list_header:SetPosition(0, 180, 0)
    self.player_list_header:SetString(STRINGS.UI.SERVERADMINSCREEN.BANNED_PLAYERS_HEADER) 
    self.player_list_header:SetColour(0,0,0,1)
        
    self.player_list_rows = self.player_list:AddChild(Widget("player_list_rows"))
    self.player_list_rows:SetPosition(column_offsets_x_pos, -8, 0) 
     
    self:MakePlayerList()    
end

function ServerAdminScreen:MakePlayerList()

    self.bgs = {}
    for i=1,7 do
        if i%2 == 1 then
            local bg = self.player_list:AddChild(Image("images/serverbrowser.xml", "greybar.tex"))
            bg:SetScale(.72,1.5)
            bg:SetPosition( -18, 132 - ((i-1)*50), 0)
            bg:SetTint(1,1,1,.7)
            table.insert(self.bgs, bg)
        end
    end

    local function bannedPlayerRowConstructor(entry, index)
        local font_size = font_size * .8
        local y_offset = 15

        if entry and not entry.empty then 
            local row = Widget("row")
            row.index = index
                    
            row.NAME = row:AddChild(Text(BUTTONFONT, font_size))        
            if "" == entry.steamid then
                if "" ~= entry.user_id then
                    row.NAME:SetString(entry.userid) 
                else
                    row.NAME:SetString(STRINGS.UI.SERVERADMINSCREEN.UNKNOWN_USER_NAME)
                end
            else
                row.NAME:SetString(entry.steamname) 
            end             
            
            row.NAME:SetPosition( column_offsets.NAME + 97, y_offset, 0 )
            row.NAME:SetRegionSize( 235, 50 )
            row.NAME:SetHAlign( ANCHOR_LEFT )
            row.NAME:SetColour(0,0,0,1)
            
            row.DETAILS = MakeImgButton(row, column_offsets.DETAILS, y_offset, STRINGS.UI.SERVERADMINSCREEN.PLAYER_DETAILS, function() self:ShowPlayerDetails(index) end)
            row.DETAILS:SetScale(0.5, 0.5)     
            if "" == entry.character and "" == entry.servername and "" == entry.serverdescription then
                row.DETAILS:Disable()
            end
            
            row.PROFILE = MakeImgButton(row, column_offsets.PROFILE, y_offset, STRINGS.UI.SERVERADMINSCREEN.PLAYER_PROFILE, function() self:ShowSteamProfile(index) end)
            row.PROFILE:SetScale(0.5, 0.5)      
            -- no steam id means we can't show the profile
            if "" == entry.steamid then
                row.PROFILE:Disable()
            end
              
            row.DELETE = MakeImgButton(row, column_offsets.DELETE, y_offset, STRINGS.UI.SERVERADMINSCREEN.PLAYER_DELETE, function() self:PromptDeletePlayer(index) end)
            row.DELETE:SetScale(0.5, 0.5)      

            return row
        else
            local row = Widget("row")
            row.index = index
                    
            row.NAME = row:AddChild(Text(BUTTONFONT, font_size))        
            row.NAME:SetString(STRINGS.UI.SERVERADMINSCREEN.EMPTY_SLOT)
            
            row.NAME:SetPosition( column_offsets.NAME + 97, y_offset, 0 )
            row.NAME:SetRegionSize( 235, 50 )
            row.NAME:SetHAlign( ANCHOR_LEFT )
            row.NAME:SetColour(0,0,0,1)

            return row
        end
    end

    self.player_scroll_list = self.player_list:AddChild(ScrollableList(self.blacklist, 550, 340, 40, 10, bannedPlayerRowConstructor, nil, nil, nil, nil, nil, -15))  
    if self.blacklist and #self.blacklist < self.player_scroll_list.widgets_per_view then
        while #self.blacklist < self.player_scroll_list.widgets_per_view do
            table.insert(self.blacklist, {empty=true})
        end
    end
    self.player_scroll_list:SetList(self.blacklist)
    self.player_scroll_list:SetPosition(10,-20)
end

function ServerAdminScreen:RefreshPlayers()
    if self.blacklist and #self.blacklist < self.player_scroll_list.widgets_per_view then
        while #self.blacklist < self.player_scroll_list.widgets_per_view do
            table.insert(self.blacklist, {empty=true})
        end
    end
    self.player_scroll_list:SetList(self.blacklist)
    if #self.blacklist == 0 then
        self.clear_button:Disable()
    else
        local allEmpties = true
        for i,v in pairs(self.blacklist) do
            if v and v.empty == nil or v.empty == false then
                allEmpties = false
                break
            end
        end
        if allEmpties then
            self.clear_button:Disable()
        else
            self.clear_button:Enable()
        end
    end
end

function ServerAdminScreen:MakePlayersDirty()
    self.players_dirty = true
    self.undo_button:Enable()
    self.apply_players_button:Enable()
end

function ServerAdminScreen:MakePlayersClean()
    self.players_dirty = false
    self.undo_button:Disable()
    self.apply_players_button:Disable()
end

function ServerAdminScreen:ShowPlayerDetails(selected_player)
    if selected_player and self.blacklist[selected_player] then
	    local popup = PlayerDetailsPopup(
	            self.blacklist[selected_player],
			    {{text=STRINGS.UI.SERVERADMINSCREEN.BACK, cb = function() TheFrontEnd:PopScreen() end}}
			)
		TheFrontEnd:PushScreen(popup)
    end
end

function ServerAdminScreen:ShowSteamProfile(selected_player)
    if selected_player then
        if self.blacklist[selected_player] then
            TheNet:ViewSteamProfile(self.blacklist[selected_player].steamid)
        end
    end
end

function ServerAdminScreen:PromptDeletePlayer(selected_player)
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
		    {text=STRINGS.UI.SERVERADMINSCREEN.NO, cb = function() TheFrontEnd:PopScreen() end}  })
	    TheFrontEnd:PushScreen(popup)		
    end	      
end

function ServerAdminScreen:DeletePlayer(selected_player)
    if selected_player then                
        table.remove(self.blacklist, selected_player)    
                
        self:MakePlayersDirty()        
        self:RefreshPlayers()        
    end       
end

function ServerAdminScreen:UndoPlayerChanges()
    if self.players_dirty then        
	    local popup = PopupDialogScreen(STRINGS.UI.SERVERADMINSCREEN.LOSE_CHANGES_TITLE, STRINGS.UI.SERVERADMINSCREEN.LOSE_CHANGES_BODY, 
			{{text=STRINGS.UI.SERVERADMINSCREEN.YES, cb = function() 			
                self.blacklist = deepcopy(self.blacklist_clean)
                self:MakePlayersClean()
                self:RefreshPlayers() 
			    TheFrontEnd:PopScreen()
			end},
			{text=STRINGS.UI.SERVERADMINSCREEN.NO, cb = function() TheFrontEnd:PopScreen() end}  })
		TheFrontEnd:PushScreen(popup)
    end    
end

function ServerAdminScreen:ClearPlayers()
    local popup = PopupDialogScreen(STRINGS.UI.SERVERADMINSCREEN.CLEAR_LIST_TITLE, STRINGS.UI.SERVERADMINSCREEN.CLEAR_LIST_BODY, 
		{{text=STRINGS.UI.SERVERADMINSCREEN.YES, cb = function() 			
            self.blacklist = {}
            self:MakePlayersDirty()
            self:RefreshPlayers()
		    TheFrontEnd:PopScreen()
		end},
		{text=STRINGS.UI.SERVERADMINSCREEN.NO, cb = function() TheFrontEnd:PopScreen() end}  })
	TheFrontEnd:PushScreen(popup)		
end

function ServerAdminScreen:ApplyPlayers()
    local list = {}
    for i,v in pairs(self.blacklist) do
        if v and not v.empty then
            table.insert(list, v)
        end
    end
    TheNet:SetBlacklist(list)
    self:MakePlayersClean()
end

function ServerAdminScreen:MakeSnapshotPanel(left_col, right_col)
    self.snapshot_panel = self.root:AddChild(Widget("snapshotpanel"))
    self.snapshot_panel:SetPosition(right_col, 0)

    self.snapshot_panel_bg = self.snapshot_panel:AddChild(Image("images/fepanels_dst.xml", "tall_panel.tex"))
    self.snapshot_panel_bg:SetScale(1.1,1.1)
    self.snapshot_panel_bg:SetPosition(0,-10)
        
    self.snapshot_header = self.snapshot_panel:AddChild(Text(BUTTONFONT, 40))
    self.snapshot_header:SetColour(0, 0, 0, 1)
    self.snapshot_header:SetPosition(0, 240, 0)
    self.snapshot_header:SetHAlign(ANCHOR_MIDDLE)
    self.snapshot_header:SetTruncatedString(SaveGameIndex:GetSlotServerData(self.save_slot).name or STRINGS.UI.SERVERADMINSCREEN.EMPTY_SLOT_TITLE, 370, 70)
    
    self.snapshot_view_offset = 0
    
    self:MakeSnapshotsMenu()
end

function ServerAdminScreen:RefreshSnapshots()
    if self.snapshots == nil then
        return
    end
    local widgets_per_view = self.snapshot_scroll_list.widgets_per_view
    local has_scrollbar = #self.snapshots > widgets_per_view
    if not has_scrollbar and #self.snapshots < widgets_per_view then
        for i = widgets_per_view - #self.snapshots, 1, -1 do
            table.insert(self.snapshots, { empty = true })
        end
    end
    self.snapshot_scroll_list:SetList(self.snapshots)
    self.snapshot_scroll_list:SetPosition(has_scrollbar and 78 or 98, -35, 0)
end

function ServerAdminScreen:MakeSnapshotsMenu()

    local function MakeSnapshotTile(data, index)
        local widget = Widget("savetile")
        widget.base = widget:AddChild(Widget("base"))
        
        widget.bg = widget.base:AddChild(UIAnim())
        widget.bg:GetAnimState():SetBuild("savetile")
        widget.bg:GetAnimState():SetBank("savetile")
        widget.bg:GetAnimState():PlayAnimation("anim")
        widget.bg:GetAnimState():SetMultColour(.5,.5,.5,1)
        widget.bg:SetScale(1,.95,1)

        if data and not data.empty then
            local snapshot = data
            local character = snapshot.character
            local atlas = "images/saveslot_portraits"
            if character ~= nil then
                if not table.contains(GetActiveCharacterList(), character) then
                    character = "random"
                elseif table.contains(MODCHARACTERLIST, character) then
                    atlas = atlas.."/"..character
                end
                atlas = atlas..".xml"
            end

            widget.portraitbg = widget.base:AddChild(Image("images/saveslot_portraits.xml", "background.tex"))
            widget.portraitbg:SetScale(.65, .65, 1)
            widget.portraitbg:SetPosition(-100, 2, 0)
            widget.portraitbg:SetClickable(false)
            
            widget.portrait = widget.base:AddChild(Image())
            widget.portrait:SetClickable(false)
            if character ~= nil then
                widget.portrait:SetTexture(atlas, character..".tex")
            else
                widget.portraitbg:Hide()
            end
            widget.portrait:SetScale(.65, .65, 1)
            widget.portrait:SetPosition(-100, 2, 0)
            
            local day_text = string.format("%s %d", STRINGS.UI.SERVERADMINSCREEN.DAY, snapshot.world_day)
            widget.day = widget.base:AddChild(Text(BUTTONFONT, 36))
            widget.day:SetColour(0, 0, 0, 1)
            widget.day:SetString(day_text)
            widget.day:SetPosition(character ~= nil and 40 or 0, 0, 0)
            widget.day:SetHAlign(ANCHOR_MIDDLE)
            widget.day:SetVAlign(ANCHOR_MIDDLE)

            widget.OnGainFocus = function(self)
                Widget.OnGainFocus(self)
                TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
                widget.bg:SetScale(1.05,1,1)
                widget.bg:GetAnimState():PlayAnimation("over")
            end

            local screen = self
            widget.OnLoseFocus = function(self)
                Widget.OnLoseFocus(self)
                widget.base:SetPosition(0,0,0)
                widget.bg:SetScale(1,.95,1)
                widget.bg:GetAnimState():PlayAnimation("anim")
            end

            widget.OnControl = function(self, control, down)
                if control == CONTROL_ACCEPT then
                    if down then 
                        widget.base:SetPosition(0,-3,0)
                    else
                        widget.base:SetPosition(0,0,0) 
                        screen:OnClickSnapshot(index)
                    end
                    return true
                end
            end

            widget.GetHelpText = function(self)
                local controller_id = TheInput:GetControllerID()
                local t = {}
                table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT).." "..STRINGS.UI.HELP.SELECT)
                return table.concat(t, "  ")
            end
        else
            widget.day = widget.base:AddChild(Text(BUTTONFONT, 28))
            widget.day:SetColour(0, 0, 0, 1)
            widget.day:SetString(STRINGS.UI.SERVERADMINSCREEN.EMPTY_SLOT)
            widget.day:SetPosition(0, 0, 0)
            widget.day:SetHAlign(ANCHOR_MIDDLE)
            widget.day:SetVAlign(ANCHOR_MIDDLE)
        end

        return widget
    end

    self.snapshot_scroll_list = self.snapshot_panel:AddChild(ScrollableList(self.snapshots, 200, 465, 90, 3, MakeSnapshotTile, nil, nil, nil, nil, nil, -27))
    self:RefreshSnapshots()
end

function ServerAdminScreen:OnClickSnapshot(snapshot_num)

    if not self.snapshots[snapshot_num] then return end
    
    TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")   
    
    local day_text = string.format("%s %d", STRINGS.UI.SERVERADMINSCREEN.DAY, self.snapshots[snapshot_num].world_day)
    local header = string.format(STRINGS.UI.SERVERADMINSCREEN.RESTORE_SNAPSHOT_HEADER, day_text)
    local popup = PopupDialogScreen(header, STRINGS.UI.SERVERADMINSCREEN.RESTORE_SNAPSHOT_BODY, 
		{{text=STRINGS.UI.SERVERADMINSCREEN.YES, cb = function() 	
            local function onSaved()
                self:ListSnapshots()
                self:RefreshSnapshots()
                self.restored_snapshot = true
                TheFrontEnd:PopScreen()
            end
            local truncate_to_id = self.snapshots[snapshot_num].snapshot_id
            if truncate_to_id ~= nil and truncate_to_id > 0 then
                TheNet:TruncateSnapshots(self.session_id, truncate_to_id)
            end
		    SaveGameIndex:SetSlotDay(self.save_slot, self.snapshots[snapshot_num].world_day)
            SaveGameIndex:Save(onSaved)
		end},
		{text=STRINGS.UI.SERVERADMINSCREEN.NO, cb = function() TheFrontEnd:PopScreen() end}  })
	TheFrontEnd:PushScreen(popup)	
	
end

function ServerAdminScreen:Back()
    if not self.players_dirty then
        self:Disable()
        TheFrontEnd:Fade(false, screen_fade_time*1.5, function()
            if self.cb then
                self.cb(self.restored_snapshot)
            end
            TheFrontEnd:PopScreen()
            TheFrontEnd:Fade(true, screen_fade_time*1.5)
            
            if self.in_game then
	            StartNextInstance({reset_action = RESET_ACTION.LOAD_SLOT, save_slot=self.save_slot})
            end
        end)
    else    
	    local popup = PopupDialogScreen(STRINGS.UI.SERVERADMINSCREEN.LOSE_CHANGES_TITLE, STRINGS.UI.SERVERADMINSCREEN.LOSE_CHANGES_BODY, 
			{{text=STRINGS.UI.SERVERADMINSCREEN.YES, cb = function() 
				self.players_dirty = false  
			    TheFrontEnd:PopScreen()
				self:Back()
			end},
			{text=STRINGS.UI.SERVERADMINSCREEN.NO, cb = function() TheFrontEnd:PopScreen() end}  })
		TheFrontEnd:PushScreen(popup)
    end
end

function ServerAdminScreen:OnControl(control, down)
    if ServerAdminScreen._base.OnControl(self, control, down) then return true end
    if not down then
        if control == CONTROL_CANCEL then 
            if TheFrontEnd:GetFadeLevel() > 0 then 
                HideCancelTip()
                TheFrontEnd:Fade(true, screen_fade_time)
            else
                self:Back()
            end
        else
            return false
        end

        return true
    end
end

function ServerAdminScreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}

    table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)

    return table.concat(t, "  ")
end

function ServerAdminScreen:MakeMenuButtons(left_col, right_col)    
    --self.undo_button = MakeImgButton(self.player_list, left_col+110, 180, STRINGS.UI.SERVERADMINSCREEN.UNDO_PLAYERS, function() self:UndoPlayerChanges() end)
    self.undo_button = MakeImgButton(self.player_list, left_col+120, -240, STRINGS.UI.SERVERADMINSCREEN.UNDO_PLAYERS, function() self:UndoPlayerChanges() end)
    self.undo_button:SetScale(0.9, 0.9)
    --self.clear_button = MakeImgButton(self.player_list, left_col+540, 180, STRINGS.UI.SERVERADMINSCREEN.CLEAR_PLAYERS, function() self:ClearPlayers() end)
    self.clear_button = MakeImgButton(self.player_list, 10, -240, STRINGS.UI.SERVERADMINSCREEN.CLEAR_PLAYERS, function() self:ClearPlayers() end)
    self.clear_button:SetScale(0.9, 0.9)    
    if #self.blacklist == 0 then
        self.clear_button:Disable()
    else
        local allEmpties = true
        for i,v in pairs(self.blacklist) do
            if v and v.empty == nil or v.empty == false then
                allEmpties = false
                break
            end
        end
        if allEmpties then
            self.clear_button:Disable()
        else
            self.clear_button:Enable()
        end
    end
    self.apply_players_button = MakeImgButton(self.player_list, left_col+535, -240, STRINGS.UI.SERVERADMINSCREEN.APPLY, function() self:ApplyPlayers() end)
    self.apply_players_button:SetScale(0.9, 0.9)
    
    self.back_button = MakeImgButton(self.root, 85, -350, STRINGS.UI.SERVERADMINSCREEN.BACK, function() self:Back() end, true)
end

function ServerAdminScreen:ListSnapshots()
    self.snapshots = {}
    if self.session_id ~= nil then
        local snapshot_infos, has_more = TheNet:ListSnapshots(self.session_id, self.online_mode, 10)
        for i, v in ipairs(snapshot_infos) do
            if v.snapshot_id ~= nil then
                local info = { snapshot_id = v.snapshot_id }
                if v.world_file ~= nil then
                    TheSim:GetPersistentString(v.world_file,
                        function(success, str)
                            if success and str ~= nil and #str > 0 then
                                local success, savedata = RunInSandbox(str)
                                if success and savedata ~= nil and GetTableSize(savedata) > 0 then
                                    local worlddata = savedata.world_network ~= nil and savedata.world_network.persistdata or nil
                                    local clockdata = worlddata ~= nil and worlddata.clock or nil
                                    info.world_day = (clockdata ~= nil and clockdata.cycles or 0) + 1
                                end
                            end
                        end)
                end
                if v.user_file ~= nil then
                    TheSim:GetPersistentString(v.user_file,
                        function(success, str)
                            if success and str ~= nil and #str > 0 then
                                local success, savedata = RunInSandbox(str)
                                if success and savedata ~= nil and GetTableSize(savedata) > 0 then
                                    info.character = savedata.prefab
                                end
                            end
                        end)
                end
                table.insert(self.snapshots, info)
            end
        end
    end
end

return ServerAdminScreen