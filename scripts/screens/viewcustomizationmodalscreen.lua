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

local DEFAULT_TAB_LOCATIONS =
{
    "forest",
    "cave",
}

local function DoMultiLevelUpgrade(self)
    --V2C: TODO: get rid of this upgrade eventually
    --NOTE: Also in saveindex.lua
    if self.current_option_settings.presetdata ~= nil or
        self.current_option_settings.tweak ~= nil or
        self.current_option_settings.actualpreset ~= nil or
        self.current_option_settings.preset ~= nil or
        next(self.current_option_settings) == nil then
        --V2C: Detected legacy single-level world options table
        self.current_option_settings = { self.current_option_settings }
    end
end

local function OnClickTab(self, level)
    self:SelectMultilevel(level)
    if TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse then
        self:OnFocusMove(MOVE_DOWN, true)
    end
end

local ViewCustomizationModalScreen = Class(Screen, function(self, worldgenoptions)
    Widget._ctor(self, "ViewCustomizationModalScreen")

    self.currentmultilevel = 1
    self.presets = {}

    for i, level in pairs(Levels.sandbox_levels) do
        table.insert(self.presets, {text=level.name, data=level.id, desc = level.desc, overrides = level.overrides, location = level.location})
    end

    --V2C: assert comment is here just as a reminder
    --assert(worldgenoptions ~= nil)

    self.current_option_settings = deepcopy(worldgenoptions)
    DoMultiLevelUpgrade(self)

    -- Populate the settings with preset data.
    -- Note: this tries "actualpreset" before "preset". "actualpreset" may be a custom preset and so won't be present/accurate on a remote machine
    for i, level in ipairs(self.current_option_settings) do
        level.tweak = level.tweak or {}
        if level.presetdata == nil then
            if self:FindPresetData(level.actualpreset) ~= nil then
                self:LoadPresetData(i, level.actualpreset)
            elseif self:FindPresetData(level.preset) ~= nil then
                self:LoadPresetData(i, level.preset)
            else
                self:LoadPresetData(i, self.presets[i].data)
            end
        end
    end

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
    self.optionspanelbg.fill:SetScale(.64, -.493)
    self.optionspanelbg.fill:SetPosition(9, -15)
    self.optionspanelbg:SetPosition(0,0,0)

    self.multileveltabs = self.optionspanel:AddChild(Widget("multileveltabs"))
    self.multileveltabs:SetPosition(9, 180, 0)

    self.multileveltabs.tabs =
    {
        self.multileveltabs:AddChild(TEMPLATES.TabButton(-123, 0, "", function() OnClickTab(self, 1) end, "small")),
        self.multileveltabs:AddChild(TEMPLATES.TabButton(123, 0, "", function() OnClickTab(self, 2) end, "small")),
    }

    for i, v in ipairs(self.multileveltabs.tabs) do
        if self:IsLevelEnabled(i) then
            v:SetText(STRINGS.UI.SANDBOXMENU.LOCATIONTABNAME[string.upper(self.current_option_settings[i].presetdata.location or "")] or STRINGS.UI.SANDBOXMENU.LOCATIONTABNAME.UNKNOWN)
        else
            if self:IsLevelEnabled(1) and self.current_option_settings[1].presetdata.location == DEFAULT_TAB_LOCATIONS[1] then
                v:SetText(STRINGS.UI.SANDBOXMENU.DISABLEDLEVEL.." "..STRINGS.UI.SANDBOXMENU.LOCATIONTABNAME[string.upper(DEFAULT_TAB_LOCATIONS[i])])
            end
            v:SetTextures("images/frontend.xml", "tab2_button.tex", "tab2_button.tex", nil, nil, { 1, 1 }, { 0, 0 })
        end
        v.image:SetScale(1.135, 1)
    end

    self:HookupFocusMoves()
    self:UpdateMultilevelUI()

    if not TheInput:ControllerAttached() then
        self.button = self.optionspanel:AddChild(ImageButton())
        self.button:SetText(STRINGS.UI.SERVERLISTINGSCREEN.OK)
        self.button:SetOnClick(function() self:Cancel() end)
        self.button:SetPosition(0,-257)
    end

    self:RefreshSpinnerValues()
end)

function ViewCustomizationModalScreen:FindPresetData(preset_id)
    local preset = nil
    for k,v in pairs(self.presets) do
        if v.data == preset_id then
            return v
        end
    end
    return nil
end

function ViewCustomizationModalScreen:LoadPresetData(level, preset_id)
    assert(self.current_option_settings[level].presetdata == nil, "Trying to load presetdata but it already exists!")

    self.current_option_settings[level].presetdata = self:FindPresetData(preset_id)
end

function ViewCustomizationModalScreen:SelectMultilevel(level)
    self.currentmultilevel = level
    self:RefreshSpinnerValues()
    self:UpdateMultilevelUI()
end

function ViewCustomizationModalScreen:IsLevelEnabled(level)
    return self.current_option_settings[level] ~= nil
end

function ViewCustomizationModalScreen:UpdateMultilevelUI()
    for i,tab in ipairs(self.multileveltabs.tabs) do
        if i == self.currentmultilevel or not self:IsLevelEnabled(i) then
            tab:Disable()
        else
            tab:Enable()
        end
    end
end

function ViewCustomizationModalScreen:RefreshSpinnerValues()
    --[[self.title = self.optionspanel:AddChild(Text(BUTTONFONT, 45, nil, { 0, 0, 0, 1 }))
    self.title:SetPosition(0, 175)
    self.title:SetString(self.current_option_settings[1].presetdata.text)]]

    local location = self.current_option_settings[self.currentmultilevel].presetdata.location or DEFAULT_TAB_LOCATIONS[self.currentmultilevel]
    self.options = Customise.GetOptions(location, self.currentmultilevel == 1)

    if self.customizationlist ~= nil then
        self.customizationlist:Kill()
    end

    self.customizationlist = self.optionspanel:AddChild(CustomizationList(location, self.options, nil))
    self.customizationlist:SetPosition(-3, -40, 0)
    self.customizationlist:SetScale(.85)
    self.customizationlist:SetEditable(false)

    local function toleveltab()
        return self.multileveltabs.tabs[self.currentmultilevel < #self.multileveltabs.tabs and self.currentmultilevel + 1 or self.currentmultilevel - 1]
    end
    self.customizationlist:SetFocusChangeDir(MOVE_UP, toleveltab)

    local title = self.current_option_settings[self.currentmultilevel].presetdata.text
    if next(self.current_option_settings[self.currentmultilevel].tweak) ~= nil then
        title = title.." "..STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOM
    end
    self.customizationlist:SetTitle(title)

    self.default_focus = self.customizationlist

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

function ViewCustomizationModalScreen:HookupFocusMoves()
    local function tocustomizationlist()
        return self.customizationlist
    end

    for i, v in ipairs(self.multileveltabs.tabs) do
        v:SetFocusChangeDir(MOVE_DOWN, tocustomizationlist)
        if i < #self.multileveltabs.tabs then
            v:SetFocusChangeDir(MOVE_RIGHT, self.multileveltabs.tabs[i + 1])
        end
        if i > 1 then
            v:SetFocusChangeDir(MOVE_LEFT, self.multileveltabs.tabs[i - 1])
        end
    end
end

return ViewCustomizationModalScreen
