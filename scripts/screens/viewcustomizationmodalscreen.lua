local Screen = require "widgets/screen"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local Grid = require "widgets/grid"
local CustomizationList = require "widgets/customizationlist"
local TEMPLATES = require "widgets/templates"

local Customise = require "map/customise"
local Levels = require "map/levels"

local ViewCustomizationModalScreen = Class(Screen, function(self, worldgenoptions)
    Widget._ctor(self, "ViewCustomizationModalScreen")

    self.currentmultilevel = 1
    self.options = Customise.GetOptions()
    self.presets = {}

    for i, level in pairs(Levels.sandbox_levels) do
        table.insert(self.presets, {text=level.name, data=level.id, desc = level.desc, overrides = level.overrides})
    end

    if worldgenoptions then
        if not worldgenoptions.supportsmultilevel then -- handle pre-multilevel server settings
            self.current_option_settings = {}
            self.current_option_settings[1] = deepcopy(worldgenoptions)
        else
            self.current_option_settings = deepcopy(worldgenoptions)
        end

        for i, level in ipairs(self.current_option_settings) do
            level.tweak = level.tweak or {}
        end

        print("###############")
        dumptable(self.current_option_settings)
    else
        print("ACK! Showing the customizationmodalscreen, but no input preset?")
    end

    -- Populate the settings with preset data.
    -- Note: this tries "preset" before "actualpreset" becuase the "actualpreset" is usually a custom preset and so won't be present/accurate on a remote machine
    if self.current_option_settings[1].presetdata == nil then
        local preset = self.current_option_settings[1].preset or self.current_option_settings[1].actualpreset or self.presets[1].data
        self:LoadPresetData(1, preset)
    end
    if self.current_option_settings[2] ~= nil and self.current_option_settings[2].presetdata == nil then
        local preset = self.current_option_settings[2].preset or self.current_option_settings[2].actualpreset or self.presets[1].data
        self:LoadPresetData(2, preset)
    end

    self.ismultilevel = self.current_option_settings[2] ~= nil

        print("!!!###############")
        dumptable(self.current_option_settings,0,5)
	
    self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
	self.black:SetTint(0,0,0,.75)
    
    self.root = self:AddChild(Widget("root"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.clickroot = self:AddChild(Widget("clickroot"))
    self.clickroot:SetVAnchor(ANCHOR_MIDDLE)
    self.clickroot:SetHAnchor(ANCHOR_MIDDLE)
    self.clickroot:SetPosition(0,0,0)
    self.clickroot:SetScaleMode(SCALEMODE_PROPORTIONAL)
    
    --menu buttons
    self.optionspanel = self.clickroot:AddChild(Widget("optionspanel"))
    self.optionspanel:SetPosition(0,20,0)

    self.optionspanelbg = self.root:AddChild(TEMPLATES.CurlyWindow(40, 365, 1, 1, 67, -41))
    self.optionspanelbg.fill = self.root:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tall.tex"))
    if not self.ismultilevel then
        self.optionspanelbg.fill:SetScale(.64, -.57)
        self.optionspanelbg.fill:SetPosition(9, 12)
    else
        self.optionspanelbg.fill:SetScale(.64, -.493)
        self.optionspanelbg.fill:SetPosition(9, -15)
    end
    self.optionspanelbg:SetPosition(0,0,0)

    if self.ismultilevel then
        self.multileveltabs = self.optionspanel:AddChild(Widget("multileveltabs"))
        self.multileveltabs:SetPosition(9, 180, 0)

        self.multileveltabs.tabs = {}
        local level1title = self.current_option_settings[1].presetdata.text
        if next(self.current_option_settings[1].tweak) ~= nil then
            level1title = self.current_option_settings[1].presetdata.text .. " " .. STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOM
        end
        self.level1tab = self.multileveltabs:AddChild(TEMPLATES.TabButton(-123, 0, level1title, function() self:SelectMultilevel(1) end, "small" ))
        self.level1tab.image:SetScale(1.135,1)
        table.insert(self.multileveltabs.tabs, self.level1tab)

        local level2title = self.current_option_settings[2].presetdata.text
        if next(self.current_option_settings[2].tweak) ~= nil then
            level2title = self.current_option_settings[2].presetdata.text .. " " .. STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOM
        end
        self.level2tab = self.multileveltabs:AddChild(TEMPLATES.TabButton(123, 0, level2title, function() self:SelectMultilevel(2) end, "small"))
        self.level2tab.image:SetScale(1.135,1)
        table.insert(self.multileveltabs.tabs, self.level2tab)

        self:UpdateMultilevelUI()
    else
        local level1title = self.current_option_settings[1].presetdata.text
        if next(self.current_option_settings[1].tweak) ~= nil then
            level1title = self.current_option_settings[1].presetdata.text .. " " .. STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOM
        end
        self.title = self.optionspanel:AddChild(Text(BUTTONFONT, 45, level1title, {0,0,0,1}))
        self.title:SetPosition(0,175)
    end
    
    if not TheInput:ControllerAttached() then
    	self.button = self.optionspanel:AddChild(ImageButton())
		self.button:SetText(STRINGS.UI.SERVERLISTINGSCREEN.OK)
    	self.button:SetOnClick(function() self:Cancel() end)
    	self.button:SetPosition(0,-257)
	end


    self.customizationlist = self.optionspanel:AddChild(CustomizationList(self.options, false))
    self.customizationlist:SetPosition(-3, -40, 0)
    self.customizationlist:SetScale(.85)
    self.customizationlist:SetEditable(false)

    self.default_focus = self.customizationlist

    self:RefreshSpinnerValues()
end)

function ViewCustomizationModalScreen:LoadPresetData(level, preset_id)
    assert(self.current_option_settings[level].presetdata == nil, "Trying to load presetdata but it already exists!")

    local preset = nil
    for k,v in pairs(self.presets) do
        if v.data == preset_id then
            preset = v
            break
        end
    end

    self.current_option_settings[level].presetdata = preset
end

function ViewCustomizationModalScreen:SelectMultilevel(level)
    self.currentmultilevel = level
    self:RefreshSpinnerValues()
    self:UpdateMultilevelUI()
end

function ViewCustomizationModalScreen:UpdateMultilevelUI()
    for i,tab in ipairs(self.multileveltabs.tabs) do
        if i == self.currentmultilevel then
            tab:Disable()
        else
            tab:Enable()
        end
    end
end

function ViewCustomizationModalScreen:RefreshSpinnerValues()
    for i,v in ipairs(self.options) do
        self.customizationlist:SetValueForOption(v.name, self:GetValueForOption(v.name))
    end
end

function ViewCustomizationModalScreen:GetValueForOption(option)
    local levelopts = self.current_option_settings[self.currentmultilevel]
    for idx,opt in ipairs(self.options) do
        if (opt.name == option) then
            if self.current_option_settings[self.currentmultilevel].tweak[opt.group] then
                local value = self.current_option_settings[self.currentmultilevel].tweak[opt.group][opt.name]
                if value then
                    return value
                end
            end
            for i,override in ipairs(levelopts.presetdata.overrides) do
                if override[1] == option then
                    return override[2]
                end
            end
            return opt.default
        end
    end
    return nil
end


function ViewCustomizationModalScreen:Cancel()
    TheFrontEnd:PopScreen()
end

function ViewCustomizationModalScreen:OnControl(control, down)
    if ViewCustomizationModalScreen._base.OnControl(self, control, down) then return true end
    if not down and control == CONTROL_CANCEL then
    	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
		self:Cancel()
		return true
    end
end

function ViewCustomizationModalScreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}
	table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)
    return table.concat(t, "  ")
end

return ViewCustomizationModalScreen
