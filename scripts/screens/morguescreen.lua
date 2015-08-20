local Screen = require "widgets/screen"
local ImageButton = require "widgets/imagebutton"

local Text = require "widgets/text"
local Image = require "widgets/image"

local Widget = require "widgets/widget"
local Levels = require "map/levels"

local OnlineStatus = require "widgets/onlinestatus"

local ScrollableList = require "widgets/scrollablelist"

local TEMPLATES = require "widgets/templates"


require("constants")

-- Note: values are the position of the line at the right side of the named column
local column_offsets
if JapaneseOnPS4() then --NB: JP PS4 values have NOT been updated for the new screen (6/14/2015)
     column_offsets ={ 
        DAYS_LIVED = -35, 
        DECEASED = 100,
        CAUSE = 290,
        MODE = 500,
        PLAYER_NAME = 50,
        PLAYER_CHAR = 160,
        SERVER_NAME = 285,
    }
else
    column_offsets ={ 
        DAYS_LIVED = -200,
        DECEASED = -50,
        CAUSE = 125,
        MODE = 400,
        PLAYER_NAME = -155,
        PLAYER_CHAR = -78,
        SERVER_NAME = 210,
        SEEN_DATE = 340,
        PLAYER_AGE = 415,
        STEAM_ID = 520,
    }
end

local header_height = 210
local row_height = 30
local num_rows = 14

local portrait_scale = 0.25


local function obit_widget_constructor(data, parent, obit_button)
    if not data and data.character and data.days_survived and data.location and data.killed_by and (data.world or data.server) then return end

     -- obits scroll list
    local font_size = 28
    if JapaneseOnPS4() then
     font_size = 28 * 0.75
    end
    
    local function tchelper(first, rest)
      return first:upper()..rest:lower()
    end

    local group = parent:AddChild(Widget("control-morgue"))
    group.bg = group:AddChild(Image("images/serverbrowser.xml", "textwidget_over.tex"))
    group.bg:SetPosition(355,0)
    group.bg:SetSize(880,37)
    group.bg:Hide()
    group.OnGainFocus = function()
        group.bg:Show()
    end
    group.OnLoseFocus = function()
        group.bg:Hide()
    end

    local slide_factor = 185

    group.DAYS_LIVED = group:AddChild(Text(NEWFONT, font_size))
    group.DAYS_LIVED:SetHAlign(ANCHOR_MIDDLE)
    group.DAYS_LIVED:SetPosition(column_offsets.DAYS_LIVED+slide_factor, 0, 0)
    group.DAYS_LIVED:SetRegionSize( 135, 30 )
    group.DAYS_LIVED:SetString(data.days_survived or "?")
    group.DAYS_LIVED:SetColour(0,0,0,1)

    group.DECEASED = group:AddChild(Widget("DECEASED"))
    group.DECEASED:SetPosition(column_offsets.DECEASED+slide_factor-10, 0, 0)

    group.DECEASED.portraitbg = group.DECEASED:AddChild(Image("images/saveslot_portraits.xml", "background.tex"))
    group.DECEASED.portraitbg:SetScale(portrait_scale, portrait_scale, 1)
    group.DECEASED.portraitbg:SetClickable(false)   
    group.DECEASED.base = group.DECEASED:AddChild(Widget("base"))
    
    group.DECEASED.portrait = group.DECEASED.base:AddChild(Image())
    group.DECEASED.portrait:SetClickable(false) 

    local character = data.character
    if character == nil then
        group.DECEASED.portrait:Hide()
    else
        local atlas = "images/saveslot_portraits"
        if not table.contains(DST_CHARACTERLIST, character) then
            if table.contains(MODCHARACTERLIST, character) then
                atlas = atlas.."/"..character
            else
                character = #character > 0 and "mod" or "unknown"
            end
        end
        atlas = atlas..".xml"
        group.DECEASED.portrait:SetTexture(atlas, character..".tex")
    end
    group.DECEASED.portrait:SetScale(portrait_scale, portrait_scale, 1)

    group.CAUSE = group:AddChild(Text(NEWFONT, font_size))
    group.CAUSE:SetHAlign(ANCHOR_MIDDLE)
    group.CAUSE:SetPosition(column_offsets.CAUSE+slide_factor-23, 0, 0)
    group.CAUSE:SetRegionSize( 175, 30 )
    local killed_by = data.killed_by
    --If it's a PK, then don't do any remapping or reformatting on the player's name
    if not data.pk then
        killed_by = data.killed_by
        if killed_by == "nil" then
            if character == "waxwell" then
                killed_by = "charlie"
            else
                killed_by = "darkness"
            end
        elseif killed_by == "unknown" then
            killed_by = "shenanigans"
        elseif killed_by == "moose" then
            if math.random() < .5 then
                killed_by = "moose1"
            else
                killed_by = "moose2"
            end
        end
        killed_by = STRINGS.NAMES[string.upper(killed_by)] or STRINGS.NAMES.SHENANIGANS
        killed_by = killed_by:gsub("(%a)([%w_']*)", tchelper)
    end
    group.CAUSE:SetString(killed_by)
    group.CAUSE:SetColour(0,0,0,1)

    group.MODE = group:AddChild(Text(NEWFONT, font_size))
    group.MODE:SetHAlign(ANCHOR_MIDDLE)
    group.MODE:SetPosition(column_offsets.MODE + slide_factor-5, 0, 0)
    group.MODE:SetRegionSize( 400, 30 )
    group.MODE:SetString(data.server or STRINGS.UI.MORGUESCREEN.LEVELTYPE[Levels.GetTypeForLevelID(data.world)])
    group.MODE:SetColour(0,0,0,1)

    group:SetFocusChangeDir(MOVE_LEFT, obit_button)

    return group
end

local function obit_widget_update(widget, data, index)
    if not widget then return end

    local function tchelper(first, rest)
      return first:upper()..rest:lower()
    end

    if data.days_survived then
        widget.DAYS_LIVED:SetString(data.days_survived or "?")
    else
        widget.DAYS_LIVED:SetString("")
    end

    local character = data.character
    if character == nil then
        widget.DECEASED:Hide()
    else
        local atlas = "images/saveslot_portraits"
        if not table.contains(DST_CHARACTERLIST, character) then
            if table.contains(MODCHARACTERLIST, character) then
                atlas = atlas.."/"..character
            else
                character = #character > 0 and "mod" or "unknown"
            end
        end
        atlas = atlas..".xml"
        widget.DECEASED:Show()
        widget.DECEASED.portrait:SetTexture(atlas, character..".tex")
    end

    local killed_by = data.killed_by or "none"
    if killed_by == "none" then
        widget.CAUSE:SetString("")
    else
        --If it's a PK, then don't do any remapping or reformatting on the player's name
        if not data.pk then
            killed_by = data.killed_by
            if killed_by == "nil" then
                if character == "waxwell" then
                    killed_by = "charlie"
                else
                    killed_by = "darkness"
                end
            elseif killed_by == "unknown" then
                killed_by = "shenanigans"
            elseif killed_by == "moose" then
                if math.random() < .5 then
                    killed_by = "moose1"
                else
                    killed_by = "moose2"
                end
            end
            killed_by = STRINGS.NAMES[string.upper(killed_by)] or STRINGS.NAMES.SHENANIGANS
            killed_by = killed_by:gsub("(%a)([%w_']*)", tchelper)
        end
        widget.CAUSE:SetString(killed_by)
    end

    if data.server then
        widget.MODE:SetString(data.server or STRINGS.UI.MORGUESCREEN.LEVELTYPE[Levels.GetTypeForLevelID(data.world)])
    else
        widget.MODE:SetString("")
    end
end

local function encounter_widget_constructor(data, parent, obit_button)	
	local font_size = 28
    if JapaneseOnPS4() then
     font_size = 28 * 0.75
    end

    local slide_factor = 200

    local group = parent:AddChild(Widget("control-encounter"))

    group.bg = group:AddChild(Image("images/serverbrowser.xml", "textwidget_over.tex"))
    group.bg:SetPosition(355,0)
    group.bg:SetSize(880,37)
    group.bg:Hide()
    group.OnGainFocus = function()
        group.bg:Show()
    end
    group.OnLoseFocus = function()
        group.bg:Hide()
    end
        
    group.PLAYER_NAME = group:AddChild(Text(NEWFONT, font_size))
    group.PLAYER_NAME:SetHAlign(ANCHOR_MIDDLE)
    group.PLAYER_NAME:SetPosition(column_offsets.PLAYER_NAME-35+slide_factor, 0, 0)
    group.PLAYER_NAME:SetRegionSize( 170, 30 )
    group.PLAYER_NAME:SetString(data.name or "?")
    group.PLAYER_NAME:SetColour(0,0,0,1)

    group.PLAYER_CHAR = group:AddChild(Widget("PLAYER_CHAR"))
    group.PLAYER_CHAR:SetPosition(column_offsets.PLAYER_CHAR+12+slide_factor, 0, 0)

    group.SERVER_NAME = group:AddChild(Text(NEWFONT, font_size))
    group.SERVER_NAME:SetHAlign(ANCHOR_MIDDLE)
    group.SERVER_NAME:SetPosition(column_offsets.SERVER_NAME-90+slide_factor, 0, 0)
    group.SERVER_NAME:SetRegionSize( 285, 30 )
    group.SERVER_NAME:SetString(data.server_name or "?")
    group.SERVER_NAME:SetColour(0,0,0,1)

    group.PLAYER_CHAR.base = group.PLAYER_CHAR:AddChild(Widget("base"))
    group.PLAYER_CHAR.base:SetPosition(1,0)
    group.PLAYER_CHAR.portraitbg = group.PLAYER_CHAR.base:AddChild(Image("images/saveslot_portraits.xml", "background.tex"))
    group.PLAYER_CHAR.portraitbg:SetScale(portrait_scale, portrait_scale, 1)
    group.PLAYER_CHAR.portraitbg:SetClickable(false)
    group.PLAYER_CHAR.portrait = group.PLAYER_CHAR.base:AddChild(Image())
    group.PLAYER_CHAR.portrait:SetClickable(false)

    local character = data.prefab
    if character == nil then
        group.PLAYER_CHAR.portrait:Hide()
    else
        local atlas = "images/saveslot_portraits"
        if not table.contains(DST_CHARACTERLIST, character) then
            if table.contains(MODCHARACTERLIST, character) then
                atlas = atlas.."/"..character
            else
                character = #character > 0 and "mod" or "unknown"
            end
        end
        atlas = atlas..".xml"
        group.PLAYER_CHAR.portrait:SetTexture(atlas, character..".tex")
    end

    group.PLAYER_CHAR.portrait:SetScale(portrait_scale, portrait_scale, 1)

    group.SEEN_DATE = group:AddChild(Text(NEWFONT, font_size))
    group.SEEN_DATE:SetHAlign(ANCHOR_MIDDLE)
    group.SEEN_DATE:SetPosition(column_offsets.SEEN_DATE-13+slide_factor, 0, 0)
    group.SEEN_DATE:SetRegionSize( 135, 30 )
    group.SEEN_DATE:SetString(data.date)
    group.SEEN_DATE:SetColour(0,0,0,1)
    
    group.PLAYER_AGE = group:AddChild(Text(NEWFONT, font_size))
    group.PLAYER_AGE:SetHAlign(ANCHOR_MIDDLE)
    group.PLAYER_AGE:SetPosition(column_offsets.PLAYER_AGE+15+slide_factor+20, 0, 0)
    group.PLAYER_AGE:SetRegionSize( 75, 30 )
    local suffix = tonumber(data.playerage) > 1 and STRINGS.UI.MORGUESCREEN.DAYS or STRINGS.UI.MORGUESCREEN.DAY
    group.PLAYER_AGE:SetString(data.playerage .. " " .. suffix)
    group.PLAYER_AGE:SetColour(0,0,0,1)

    group.STEAM_ID = group:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "steam.tex", "", false, false, function() VisitURL("http://steamcommunity.com/profiles/"..data.steamid) end))
    --STEAM_ID:SetHAlign(ANCHOR_MIDDLE)
    group.STEAM_ID:SetPosition(column_offsets.STEAM_ID+8+slide_factor+18, -1, 0)
	group.STEAM_ID:SetScale(.45)
    group.STEAM_ID:SetHelpTextMessage(STRINGS.UI.PLAYERSTATUSSCREEN.VIEWPROFILE)

    group.focus_forward = group.STEAM_ID

    group:SetFocusChangeDir(MOVE_LEFT, obit_button)

    return group
end

local function encounter_widget_update(widget, data, index)   
    if not widget then return end

    local name = data.name or "none"
    if name == "none" then
        widget.PLAYER_NAME:SetString("")
    else
        widget.PLAYER_NAME:SetString(data.name or "?")
    end

    local server = data.server_name or "none"
    if server == "none" then
        widget.SERVER_NAME:SetString("")
    else
        widget.SERVER_NAME:SetString(data.server_name or "?")
    end    

    local character = data.prefab
    if character == nil then
        widget.PLAYER_CHAR:Hide()
    else
        local atlas = "images/saveslot_portraits"
        if not table.contains(DST_CHARACTERLIST, character) then
            if table.contains(MODCHARACTERLIST, character) then
                atlas = atlas.."/"..character
            else
                character = #character > 0 and "mod" or "unknown"
            end
        end
        atlas = atlas..".xml"
        widget.PLAYER_CHAR:Show()
        widget.PLAYER_CHAR.portrait:SetTexture(atlas, character..".tex")
    end

    widget.SEEN_DATE:SetString(data.date or "")
    
    local age = data.playerage or "none"
    if age == "none" then
        widget.PLAYER_AGE:SetString("")
    else
        local suffix = tonumber(data.playerage) > 1 and STRINGS.UI.MORGUESCREEN.DAYS or STRINGS.UI.MORGUESCREEN.DAY
        widget.PLAYER_AGE:SetString(data.playerage .. " " .. suffix)
    end

    local steam = data.steamid or "none"
    if steam == "none" then
        widget.STEAM_ID:Hide()
    else
        widget.STEAM_ID:MoveToFront()
        widget.STEAM_ID:Show()
        widget.STEAM_ID:SetOnClick( function() VisitURL("http://steamcommunity.com/profiles/"..data.steamid) end )
    end
end

local MorgueScreen = Class(Screen, function(self, in_game)
    Widget._ctor(self, "MorgueScreen")
    	
	self.bg = self:AddChild(TEMPLATES.AnimatedPortalBackground())
    
	self.root = self:AddChild(Widget("ROOT"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetPosition(0,0,0)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
   
	self.fg = self.root:AddChild(TEMPLATES.AnimatedPortalForeground())

    self.menu_bg = self.root:AddChild(TEMPLATES.LeftGradient())

	self.onlinestatus = self.root:AddChild(OnlineStatus())
	self.cancel_button = self.root:AddChild(TEMPLATES.BackButton(function() self:OK() end))

	self.center_panel = self.root:AddChild(TEMPLATES.CenterPanel())
	-- self.center_panel:SetPosition(75, 0)

	self.nav_bar = self.root:AddChild(TEMPLATES.NavBarWithScreenTitle(STRINGS.UI.MORGUESCREEN.HISTORY, "short"))
	self.obituary_button = self.nav_bar:AddChild(TEMPLATES.NavBarButton(25, STRINGS.UI.MORGUESCREEN.TITLE, function() self:SetTab("obituary") end))
	self.encounters_button = self.nav_bar:AddChild(TEMPLATES.NavBarButton(-25, STRINGS.UI.MORGUESCREEN.ENCOUNTERSTITLE, function() self:SetTab("encounters") end))

	
	self.list_widgets = {}
    self.morgue = Morgue:GetRows()

    PlayerHistory:SortBackwards("sort_date")
    self.player_history = PlayerHistory:GetRows()


	self:BuildObituariesTab()
	self:BuildEncountersTab()

	self:RefreshControls()

	self:SetTab("obituary")
	self.default_focus = self.obituary_button

end)

function MorgueScreen:AddWhiteStripes(parent)

	local y_height = header_height-.5*row_height

	for i = 1, num_rows+1 do 
		if i % 2 ~= 0 then 
			local line = parent:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
			line:SetPosition(105, y_height)
			line:SetScale(1.66, .68)
            line:MoveToBack()
		end

		y_height = y_height - row_height
	end

end

function MorgueScreen:BuildObituariesTab()
	self.obituaryroot = self.center_panel:AddChild(Widget("ROOT"))

    self.obituaryroot:SetPosition(-110,0,0)

    self.obituary_title = self.obituaryroot:AddChild(Text(BUTTONFONT, 45, STRINGS.UI.MORGUESCREEN.TITLE))
    self.obituary_title:SetPosition(115,245) 
    self.obituary_title:SetColour(0,0,0,1)   

    self.obituary_lines = self.obituaryroot:AddChild(Widget("lines"))
    local vertical_line_y_offset = -20

    self.upper_horizontal_line = self.obituary_lines:AddChild(Image("images/ui.xml", "line_horizontal_5.tex"))
    self.upper_horizontal_line:SetScale(.7, .66)
    self.upper_horizontal_line:SetPosition(100, header_height, 0)

    self.lower_horizontal_line = self.obituary_lines:AddChild(Image("images/ui.xml", "line_horizontal_5.tex"))
    self.lower_horizontal_line:SetScale(.7, .66)
    self.lower_horizontal_line:SetPosition(100, header_height-row_height, 0)

    self.first_column_end = self.obituary_lines:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
    self.first_column_end:SetScale(.66, .68)
    self.first_column_end:SetPosition(column_offsets.DAYS_LIVED,vertical_line_y_offset, 0)

    self.second_column_end = self.obituary_lines:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
    self.second_column_end:SetScale(.66, .68)
    self.second_column_end:SetPosition(column_offsets.DECEASED, vertical_line_y_offset, 0)

    self.third_column_end = self.obituary_lines:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
    self.third_column_end:SetScale(.66, .68)
    self.third_column_end:SetPosition(column_offsets.CAUSE, vertical_line_y_offset, 0)

    local font_size = 30
    if JapaneseOnPS4() then
        font_size = 30 * 0.75;
    end
   
    self.obits_titles = self.obituaryroot:AddChild(Widget("obits_titles"))
    self.obits_titles:SetPosition(0, header_height-.5*row_height, 0)

    if JapaneseOnPS4() then
        self.DAYS_LIVED = self.obits_titles:AddChild(Text(NEWFONT, font_size * 0.8))
    else
        self.DAYS_LIVED = self.obits_titles:AddChild(Text(NEWFONT, font_size))
    end
    self.DAYS_LIVED:SetHAlign(ANCHOR_MIDDLE)
    self.DAYS_LIVED:SetPosition(column_offsets.DAYS_LIVED - 65, 0, 0)
    self.DAYS_LIVED:SetRegionSize( 400, 30 )
    self.DAYS_LIVED:SetString(STRINGS.UI.MORGUESCREEN.DAYS_LIVED)
    self.DAYS_LIVED:SetColour(0, 0, 0, 1)
    self.DAYS_LIVED:SetClickable(false)

    self.DECEASED = self.obits_titles:AddChild(Text(NEWFONT, font_size))
    self.DECEASED:SetHAlign(ANCHOR_MIDDLE)
    self.DECEASED:SetPosition(column_offsets.DECEASED - 75, 0, 0)
    self.DECEASED:SetRegionSize( 400, 30 )
    self.DECEASED:SetString(STRINGS.UI.MORGUESCREEN.DECEASED)
    self.DECEASED:SetColour(0, 0, 0, 1)
    self.DECEASED:SetClickable(false)

    self.CAUSE = self.obits_titles:AddChild(Text(NEWFONT, font_size))
    self.CAUSE:SetHAlign(ANCHOR_MIDDLE)
    self.CAUSE:SetPosition(column_offsets.CAUSE - 85, 0, 0)
    self.CAUSE:SetRegionSize( 400, 30 )
    self.CAUSE:SetString(STRINGS.UI.MORGUESCREEN.CAUSE)
    self.CAUSE:SetColour(0, 0, 0, 1)
    self.CAUSE:SetClickable(false)

    self.MODE = self.obits_titles:AddChild(Text(NEWFONT, font_size))
    self.MODE:SetHAlign(ANCHOR_MIDDLE)
    self.MODE:SetPosition(column_offsets.MODE - 71, 0, 0)
    self.MODE:SetRegionSize( 400, 30 )
    self.MODE:SetString(STRINGS.UI.MORGUESCREEN.MODE)
    self.MODE:SetColour(0, 0, 0, 1)
    self.MODE:SetClickable(false)
	
    self.obits_rows = self.obituaryroot:AddChild(Widget("obits_rows"))
    self:AddWhiteStripes(self.obits_rows)
    self.obits_rows:MoveToBack()

    self.obitslistroot = self.obituaryroot:AddChild(Widget("obitsroot"))
    self.obitslistroot:SetPosition(200,0)

    self.obitsrowsroot = self.obituaryroot:AddChild(Widget("obitsroot"))
    self.obitsrowsroot:SetPosition(200,0)

    self.obit_widgets = {}
    for i=1,num_rows do
        table.insert(self.obit_widgets, obit_widget_constructor(self.morgue[i] or {character="", days_survived="", location="", killed_by="", world=""}, self.obitsrowsroot, self.obituary_button))
    end

    self.obits_scroll_list = self.obitslistroot:AddChild(ScrollableList(self.morgue, 900, 420, row_height, 0, obit_widget_update, self.obit_widgets, nil, nil, nil, 30))
    self.obits_scroll_list:LayOutStaticWidgets(-25)
    self.obits_scroll_list:SetPosition(-95, -35)

end

function MorgueScreen:BuildEncountersTab()
	self.encountersroot = self.center_panel:AddChild(Widget("ROOT"))

    self.encountersroot:SetPosition(-110,0,0)

    self.encounters_title = self.encountersroot:AddChild(Text(BUTTONFONT, 45, STRINGS.UI.MORGUESCREEN.LONGENCOUNTERSTITLE))
    self.encounters_title:SetPosition(115,245) 
    self.encounters_title:SetColour(0,0,0,1)   

    self.encounters_lines = self.encountersroot:AddChild(Widget("lines"))
    local vertical_line_y_offset = -20

    self.upper_horizontal_line = self.encounters_lines:AddChild(Image("images/ui.xml", "line_horizontal_5.tex"))
    self.upper_horizontal_line:SetScale(.7, .66)
    self.upper_horizontal_line:SetPosition(100, header_height, 0)

    self.lower_horizontal_line = self.encounters_lines:AddChild(Image("images/ui.xml", "line_horizontal_5.tex"))
    self.lower_horizontal_line:SetScale(.7, .66)
    self.lower_horizontal_line:SetPosition(100, header_height-row_height, 0)

    self.first_column_end = self.encounters_lines:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
    self.first_column_end:SetScale(.66, .68)
    self.first_column_end:SetPosition(column_offsets.PLAYER_NAME,vertical_line_y_offset, 0)

    self.second_column_end = self.encounters_lines:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
    self.second_column_end:SetScale(.66, .68)
    self.second_column_end:SetPosition(column_offsets.PLAYER_CHAR, vertical_line_y_offset, 0)

    self.third_column_end = self.encounters_lines:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
    self.third_column_end:SetScale(.66, .68)
    self.third_column_end:SetPosition(column_offsets.SERVER_NAME, vertical_line_y_offset, 0)

    if not JapaneseOnPS4() then 
	    self.fourth_column_end = self.encounters_lines:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
	    self.fourth_column_end:SetScale(.66, .68)
	    self.fourth_column_end:SetPosition(column_offsets.SEEN_DATE, vertical_line_y_offset, 0)

	    self.fifth_column_end = self.encounters_lines:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
	    self.fifth_column_end:SetScale(.66, .68)
	    self.fifth_column_end:SetPosition(column_offsets.PLAYER_AGE+40, vertical_line_y_offset, 0)
	end

	self.encounters_rows = self.encountersroot:AddChild(Widget("encounters_rows"))
	self:AddWhiteStripes(self.encounters_rows)
	self.encounters_rows:MoveToBack()

    local font_size = 30
    if JapaneseOnPS4() then
        font_size = 30 * 0.75;
    end
    self.encounters_titles = self.encountersroot:AddChild(Widget("encounters_titles"))
    self.encounters_titles:SetPosition(-75, -.5*row_height, 0)

    if JapaneseOnPS4() then
        self.PLAYER_NAME = self.encounters_titles:AddChild(Text(NEWFONT, font_size * 0.8))
    else
        self.PLAYER_NAME = self.encounters_titles:AddChild(Text(NEWFONT, font_size))
    end
    self.PLAYER_NAME:SetHAlign(ANCHOR_MIDDLE)
    self.PLAYER_NAME:SetPosition(column_offsets.PLAYER_NAME - 10, header_height, 0)
    self.PLAYER_NAME:SetRegionSize( 400, 30 )
    self.PLAYER_NAME:SetString(STRINGS.UI.MORGUESCREEN.PLAYER_NAME)
    self.PLAYER_NAME:SetColour(0, 0, 0, 1)
    self.PLAYER_NAME:SetClickable(false)

    self.PLAYER_CHAR = self.encounters_titles:AddChild(Text(NEWFONT, font_size))
    self.PLAYER_CHAR:SetHAlign(ANCHOR_MIDDLE)
    self.PLAYER_CHAR:SetPosition(column_offsets.PLAYER_CHAR + 39, header_height, 0)
    self.PLAYER_CHAR:SetRegionSize( 400, 30 )
    self.PLAYER_CHAR:SetString(STRINGS.UI.MORGUESCREEN.PLAYER_CHAR)
    self.PLAYER_CHAR:SetColour(0, 0, 0, 1)
    self.PLAYER_CHAR:SetClickable(false)

    self.SERVER_NAME = self.encounters_titles:AddChild(Text(NEWFONT, font_size))
    self.SERVER_NAME:SetHAlign(ANCHOR_MIDDLE)
    self.SERVER_NAME:SetPosition(column_offsets.SERVER_NAME - 65, header_height, 0)
    self.SERVER_NAME:SetRegionSize( 400, 30 )
    self.SERVER_NAME:SetString(STRINGS.UI.MORGUESCREEN.SERVER_NAME)
    self.SERVER_NAME:SetColour(0, 0, 0, 1)
    self.SERVER_NAME:SetClickable(false)

    if not JapaneseOnPS4() then
    	self.SEEN_DATE = self.encounters_titles:AddChild(Text(NEWFONT, font_size))
    	self.SEEN_DATE:SetHAlign(ANCHOR_MIDDLE)
	    self.SEEN_DATE:SetPosition(column_offsets.SEEN_DATE + 12, header_height, 0)
	    self.SEEN_DATE:SetRegionSize( 400, 30 )
	    self.SEEN_DATE:SetString(STRINGS.UI.MORGUESCREEN.SEEN_DATE)
	    self.SEEN_DATE:SetColour(0, 0, 0, 1)
        self.SEEN_DATE:SetClickable(false)

	    self.PLAYER_AGE = self.encounters_titles:AddChild(Text(NEWFONT, font_size))
	    self.PLAYER_AGE:SetHAlign(ANCHOR_MIDDLE)
	    self.PLAYER_AGE:SetPosition(column_offsets.PLAYER_AGE + 40 + 20, header_height, 0)
	    self.PLAYER_AGE:SetRegionSize( 400, 30 )
	    self.PLAYER_AGE:SetString(STRINGS.UI.MORGUESCREEN.PLAYER_AGE)
	    self.PLAYER_AGE:SetColour(0, 0, 0, 1)
        self.PLAYER_AGE:SetClickable(false)

	    self.STEAM_ID = self.encounters_titles:AddChild(Text(NEWFONT, font_size))
	    self.STEAM_ID:SetHAlign(ANCHOR_MIDDLE)
	    self.STEAM_ID:SetPosition(column_offsets.STEAM_ID + 35 + 15, header_height, 0)
	    self.STEAM_ID:SetRegionSize( 400, 30 )
	    self.STEAM_ID:SetString(STRINGS.UI.MORGUESCREEN.STEAM_ID)
	    self.STEAM_ID:SetColour(0, 0, 0, 1)
        self.STEAM_ID:SetClickable(false)
	end


    self.encounterslistroot = self.encountersroot:AddChild(Widget("encounterslistroot"))
    self.encounterslistroot:SetPosition(200,0)

    self.encountersrowsroot = self.encountersroot:AddChild(Widget("encountersrowsroot"))
    self.encountersrowsroot:SetPosition(200,0)

    self.encounter_widgets = {}
    for i=1,num_rows do
        table.insert(self.encounter_widgets, encounter_widget_constructor(self.player_history[i] or {name="", playerage="0", steamid="", server_name="", date="", prefab=""}, self.encountersrowsroot, self.obituary_button))
    end

    self.encounters_scroll_list = self.encounterslistroot:AddChild(ScrollableList(self.player_history, 900, row_height * num_rows, row_height - 1, 1, encounter_widget_update, self.encounter_widgets, nil, nil, nil, 30))
    self.encounters_scroll_list:LayOutStaticWidgets(-25)
    self.encounters_scroll_list:SetPosition(-95, -35)
end

function MorgueScreen:SetTab(tab)
	if tab == "obituary" then
		self.selected_tab = "obituary"
		if self.obituary_button.shown then self.obituary_button:Select() end
		if self.encounters_button.shown then self.encounters_button:Unselect() end
		self.obituaryroot:Show()
		self.encountersroot:Hide()
	elseif tab == "encounters" then
		self.selected_tab = "encounters"
		if self.obituary_button.shown then self.obituary_button:Unselect() end
		if self.encounters_button.shown then self.encounters_button:Select() end
		self.obituaryroot:Hide()
		self.encountersroot:Show()
	end
	--self:UpdateMenu()
end

function MorgueScreen:OnBecomeActive()
    MorgueScreen._base.OnBecomeActive(self)
    --TheFrontEnd:GetSound():KillSound("FEMusic")    
end

function MorgueScreen:OnBecomeInactive()
    MorgueScreen._base.OnBecomeInactive(self)
    --TheFrontEnd:GetSound():PlaySound("dontstarve/music/music_FE","FEMusic")
end

function MorgueScreen:OnDestroy()
	self._base.OnDestroy(self)
end

function MorgueScreen:RefreshControls()
   self:RefreshNav()
end

function MorgueScreen:RefreshNav()
	
	local function torightcol()
        if self.selected_tab == "obituary" then
		    return self.obits_scroll_list
        else
            return self.encounters_scroll_list
        end
	end

	self.obits_scroll_list:SetFocusChangeDir(MOVE_LEFT, self.obituary_button)
	self.encounters_scroll_list:SetFocusChangeDir(MOVE_LEFT, self.obituary_button)

    self.cancel_button:SetFocusChangeDir(MOVE_UP, self.obituary_button)

    self.cancel_button:SetFocusChangeDir(MOVE_RIGHT, torightcol)
    self.obituary_button:SetFocusChangeDir(MOVE_RIGHT, torightcol)
    self.encounters_button:SetFocusChangeDir(MOVE_RIGHT, torightcol)

    self.obituary_button:SetFocusChangeDir(MOVE_DOWN, self.encounters_button)
    self.encounters_button:SetFocusChangeDir(MOVE_UP, self.obituary_button)
    self.encounters_button:SetFocusChangeDir(MOVE_DOWN, self.cancel_button)

    if TheInput:ControllerAttached() then
        self.cancel_button:Hide()
    else
        self.cancel_button:Show()
    end
end


function MorgueScreen:OnControl(control, down)
    if MorgueScreen._base.OnControl(self, control, down) then return true end

    if not down then 
		if control == CONTROL_CANCEL then 
			self:OK()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
			return true 
		end
	end
end

function MorgueScreen:OK()
    self:Disable()
    TheFrontEnd:Fade(false, SCREEN_FADE_TIME, function()
        TheFrontEnd:PopScreen()
        TheFrontEnd:Fade(true, SCREEN_FADE_TIME)
    end)
end


function MorgueScreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}
 	
 	table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)

    return table.concat(t, "  ")
end



return MorgueScreen