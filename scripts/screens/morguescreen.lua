local Screen = require "widgets/screen"
local AnimButton = require "widgets/animbutton"
local ImageButton = require "widgets/imagebutton"

local Text = require "widgets/text"
local Image = require "widgets/image"

local Widget = require "widgets/widget"
local Levels = require "map/levels"

local OnlineStatus = require "widgets/onlinestatus"

local ScrollableList = require "widgets/scrollablelist"

require("constants")

local controls_per_screen = 8
local controls_per_scroll = 8

local column_offsets_x_pos = -RESOLUTION_X*0.18;
local column_offsets_y_pos = RESOLUTION_Y*0.23;

local column_offsets
if JapaneseOnPS4() then
     column_offsets ={ 
        DAYS_LIVED = -35, --#srosen not updated
        DECEASED = 100,
        CAUSE = 290,
        MODE = 500,
        PLAYER_NAME = 50,
        PLAYER_CHAR = 160,
        SERVER_NAME = 285,
    }
else
    column_offsets ={ 
        DAYS_LIVED = 50,
        DECEASED = 160,
        CAUSE = 285,
        MODE = 400,
        PLAYER_NAME = 0,
        PLAYER_CHAR = 175,
        SERVER_NAME = 245,
    }
end

local header_height = 5

local screen_fade_time = .25

local MorgueScreen = Class(Screen, function(self, in_game)
    Widget._ctor(self, "MorgueScreen")
    	
	self.bg = self:AddChild(Image("images/bg_plain.xml", "bg.tex"))
    TintBackground(self.bg)

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
    self.root:SetPosition(0,0,0)
	
	--add the controls panel	
	
	self.control_offset = 0
    self.panel = self.root:AddChild(Widget("panel"))
    self.panel:SetPosition(0,0,0)
    self.panelbg = self.panel:AddChild(Image("images/historyscreen.xml", "history_panel.tex"))
    if JapaneseOnPS4() then
        self.panelbg:SetScale(1.15,1,1)
    end

    self.obitsroot = self.panel:AddChild(Widget("obitsroot"))
    self.obitsroot:SetPosition(-270,0)

    self.obitstitle = self.obitsroot:AddChild(Text(BUTTONFONT, 55))
    self.obitstitle:SetHAlign(ANCHOR_MIDDLE)
    self.obitstitle:SetPosition(0, RESOLUTION_Y*0.32, 0)
    self.obitstitle:SetRegionSize( 400, 70 )
    self.obitstitle:SetString(STRINGS.UI.MORGUESCREEN.TITLE)
    self.obitstitle:SetColour(0,0,0,1)

    local font_size = 35
    if JapaneseOnPS4() then
        font_size = 35 * 0.75;
    end
   
    self.obits_titles = self.obitsroot:AddChild(Widget("obits_titles"))
    self.obits_titles:SetPosition(column_offsets_x_pos, column_offsets_y_pos, 0)

    if JapaneseOnPS4() then
        self.DAYS_LIVED = self.obits_titles:AddChild(Text(BUTTONFONT, font_size * 0.8))
    else
        self.DAYS_LIVED = self.obits_titles:AddChild(Text(BUTTONFONT, font_size))
    end
    self.DAYS_LIVED:SetHAlign(ANCHOR_MIDDLE)
    self.DAYS_LIVED:SetPosition(column_offsets.DAYS_LIVED, header_height, 0)
    self.DAYS_LIVED:SetRegionSize( 400, 70 )
    self.DAYS_LIVED:SetString(STRINGS.UI.MORGUESCREEN.DAYS_LIVED)
    self.DAYS_LIVED:SetColour(0, 0, 0, 1)

    self.DECEASED = self.obits_titles:AddChild(Text(BUTTONFONT, font_size))
    self.DECEASED:SetHAlign(ANCHOR_MIDDLE)
    self.DECEASED:SetPosition(column_offsets.DECEASED, header_height, 0)
    self.DECEASED:SetRegionSize( 400, 70 )
    self.DECEASED:SetString(STRINGS.UI.MORGUESCREEN.DECEASED)
    self.DECEASED:SetColour(0, 0, 0, 1)

    self.CAUSE = self.obits_titles:AddChild(Text(BUTTONFONT, font_size))
    self.CAUSE:SetHAlign(ANCHOR_MIDDLE)
    self.CAUSE:SetPosition(column_offsets.CAUSE, header_height, 0)
    self.CAUSE:SetRegionSize( 400, 70 )
    self.CAUSE:SetString(STRINGS.UI.MORGUESCREEN.CAUSE)
    self.CAUSE:SetColour(0, 0, 0, 1)

    self.MODE = self.obits_titles:AddChild(Text(BUTTONFONT, font_size))
    self.MODE:SetHAlign(ANCHOR_MIDDLE)
    self.MODE:SetPosition(column_offsets.MODE, header_height, 0)
    self.MODE:SetRegionSize( 400, 70 )
    self.MODE:SetString(STRINGS.UI.MORGUESCREEN.MODE)
    self.MODE:SetColour(0, 0, 0, 1)

    self.obits_rows = self.obitsroot:AddChild(Widget("obits_rows"))
    self.obits_rows:SetPosition(column_offsets_x_pos, -RESOLUTION_Y*0.075, 0)
    -- self.obits_rows:SetVAlign(ANCHOR_MIDDLE)

    self.encountersroot = self.panel:AddChild(Widget("encountersroot"))
    self.encountersroot:SetPosition(250,0)

    self.encounterstitle = self.encountersroot:AddChild(Text(BUTTONFONT, 55))
    self.encounterstitle:SetHAlign(ANCHOR_MIDDLE)
    self.encounterstitle:SetPosition(0, RESOLUTION_Y*0.32, 0)
    self.encounterstitle:SetRegionSize( 400, 70 )
    self.encounterstitle:SetString(STRINGS.UI.MORGUESCREEN.ENCOUNTERSTITLE.." (WIP)")
    self.encounterstitle:SetColour(0,0,0,1)

    self.encounters_titles = self.encountersroot:AddChild(Widget("obits_titles"))
    self.encounters_titles:SetPosition(column_offsets_x_pos, column_offsets_y_pos, 0)

    if JapaneseOnPS4() then
        self.PLAYER_NAME = self.encounters_titles:AddChild(Text(BUTTONFONT, font_size * 0.8))
    else
        self.PLAYER_NAME = self.encounters_titles:AddChild(Text(BUTTONFONT, font_size))
    end
    self.PLAYER_NAME:SetHAlign(ANCHOR_MIDDLE)
    self.PLAYER_NAME:SetPosition(column_offsets.PLAYER_NAME, header_height, 0)
    self.PLAYER_NAME:SetRegionSize( 400, 70 )
    self.PLAYER_NAME:SetString(STRINGS.UI.MORGUESCREEN.PLAYER_NAME)
    self.PLAYER_NAME:SetColour(0, 0, 0, 1)

    self.PLAYER_CHAR = self.encounters_titles:AddChild(Text(BUTTONFONT, font_size))
    self.PLAYER_CHAR:SetHAlign(ANCHOR_MIDDLE)
    self.PLAYER_CHAR:SetPosition(column_offsets.PLAYER_CHAR, header_height, 0)
    self.PLAYER_CHAR:SetRegionSize( 400, 70 )
    self.PLAYER_CHAR:SetString(STRINGS.UI.MORGUESCREEN.PLAYER_CHAR)
    self.PLAYER_CHAR:SetColour(0, 0, 0, 1)

    self.SERVER_NAME = self.encounters_titles:AddChild(Text(BUTTONFONT, font_size))
    self.SERVER_NAME:SetHAlign(ANCHOR_MIDDLE)
    self.SERVER_NAME:SetPosition(column_offsets.SERVER_NAME, header_height, 0)
    self.SERVER_NAME:SetRegionSize( 400, 70 )
    self.SERVER_NAME:SetString(STRINGS.UI.MORGUESCREEN.SERVER_NAME)
    self.SERVER_NAME:SetColour(0, 0, 0, 1)

 	self.list_widgets = {}
    self.control_offset = 0
    self.morgue = Morgue:GetRows()
    self:RefreshControls()

    self.fg = self.root:AddChild(Image("images/fg_trees.xml", "trees.tex"))
    self.fg:SetVRegPoint(ANCHOR_MIDDLE)
    self.fg:SetHRegPoint(ANCHOR_MIDDLE)
    self.fg:SetVAnchor(ANCHOR_MIDDLE)
    self.fg:SetHAnchor(ANCHOR_MIDDLE)
    self.fg:SetScaleMode(SCALEMODE_FILLSCREEN)

    self.onlinestatus = self.fg:AddChild(OnlineStatus())
    self.onlinestatus:SetHAnchor(ANCHOR_RIGHT)
    self.onlinestatus:SetVAnchor(ANCHOR_BOTTOM)  

    if not Input:ControllerAttached() then
        self.OK_button = self.root:AddChild(ImageButton("images/ui.xml", "button_large.tex", "button_large_over.tex", "button_large_disabled.tex", "button_large_onclick.tex"))
        self.OK_button:SetScale(.75)
        self.OK_button:SetPosition(0, -290, 0)
        self.OK_button:SetText(STRINGS.UI.MORGUESCREEN.BACK)
        self.OK_button.text:SetColour(0,0,0,1)
        self.OK_button:SetOnClick( function() self:OK() end )
        self.OK_button:SetFont(BUTTONFONT)
        self.OK_button:SetTextSize(40)
    end

    -- obits scroll list
    local font_size = 28
    if JapaneseOnPS4() then
     font_size = 28 * 0.75
    end
    local portrate_scale = 0.25

    local function tchelper(first, rest)
      return first:upper()..rest:lower()
    end

    local function obit_widget_constructor(data)
        if not data and data.character and data.days_survived and data.location and data.killed_by and (data.world or data.server) then return end

        local group = Widget("control")

        local DAYS_LIVED = group:AddChild(Text(BUTTONFONT, font_size))
        DAYS_LIVED:SetHAlign(ANCHOR_MIDDLE)
        DAYS_LIVED:SetPosition(column_offsets.DAYS_LIVED+20, 0, 0)
        DAYS_LIVED:SetRegionSize( 400, 70 )
        DAYS_LIVED:SetString(data.days_survived or "?")
        DAYS_LIVED:SetColour(0,0,0,1)

        local DECEASED = group:AddChild(Widget("DECEASED"))
        DECEASED:SetPosition(column_offsets.DECEASED+20, 4, 0)

        DECEASED.portraitbg = DECEASED:AddChild(Image("images/saveslot_portraits.xml", "background.tex"))
        DECEASED.portraitbg:SetScale(portrate_scale, portrate_scale, 1)
        DECEASED.portraitbg:SetClickable(false)   
        DECEASED.base = DECEASED:AddChild(Widget("base"))
        
        DECEASED.portrait = DECEASED.base:AddChild(Image())
        DECEASED.portrait:SetClickable(false) 

        local character = data.character
        if character == "maxwell" then
            character = "waxwell"
        end

        local atlas = (table.contains(MODCHARACTERLIST, character) and "images/saveslot_portraits/"..character..".xml") or "images/saveslot_portraits.xml"
        if not table.contains(GetActiveCharacterList(), character) then
            character = "random" -- Use a question mark if the character isn't currently active
        end
        DECEASED.portrait:SetTexture(atlas, character..".tex")
        DECEASED.portrait:SetScale(portrate_scale, portrate_scale, 1)

        local CAUSE = group:AddChild(Text(BUTTONFONT, font_size))
        CAUSE:SetHAlign(ANCHOR_MIDDLE)
        CAUSE:SetPosition(column_offsets.CAUSE+15, 0, 0)
        CAUSE:SetRegionSize( 400, 70 )
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
        CAUSE:SetString(killed_by)
        CAUSE:SetColour(0,0,0,1)

        local MODE = group:AddChild(Text(BUTTONFONT, font_size))
        MODE:SetHAlign(ANCHOR_MIDDLE)
        MODE:SetPosition(column_offsets.MODE + 15, 0, 0)
        MODE:SetRegionSize( 400, 70 )
        MODE:SetString(data.server or STRINGS.UI.MORGUESCREEN.LEVELTYPE[Levels.GetTypeForLevelID(data.world)])
        MODE:SetColour(0,0,0,1)

        return group
    end
    self.obitslistroot = self.scaleroot:AddChild(Widget("obitsroot"))
    self.obitslistroot:SetPosition(-270,0)
    self.obits_scroll_list = self.obitslistroot:AddChild(ScrollableList(self.morgue, 500, 400, 30, 1, obit_widget_constructor))
    self.obits_scroll_list:SetPosition(0, -50)

    self.default_focus = self.obits_scroll_list

    -- encounters scroll list
    --#srosen need support for list of recent players
end)

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
    
	-- for k,v in pairs(self.list_widgets) do
	-- 	v.root:Kill()
	-- end
	-- self.list_widgets = {}

    -- killed_by
    -- days_survived
    -- character
    -- location
    -- world    

    

 --            table.insert(self.list_widgets, {root = group, id=idx})	    
	-- 	end
	-- end	
end

function MorgueScreen:OnControl(control, down)
    if MorgueScreen._base.OnControl(self, control, down) then return true end
    if not down then
        if control == CONTROL_CANCEL then 
            self:OK()
        else
            return false
        end

        return true
    end
end

function MorgueScreen:OK()
    self:Disable()
    TheFrontEnd:Fade(false, screen_fade_time, function()
        TheFrontEnd:PopScreen()
        TheFrontEnd:Fade(true, screen_fade_time)
    end)
end


function MorgueScreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}

    table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)

    return table.concat(t, "  ")
end



return MorgueScreen