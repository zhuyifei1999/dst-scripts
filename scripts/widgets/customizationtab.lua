local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Spinner = require "widgets/spinner"
local NumericSpinner = require "widgets/numericspinner"
local Grid = require "widgets/grid"
local PopupDialogScreen = require "screens/popupdialog"
local CustomizationList = require "widgets/customizationlist"
local TEMPLATES = require "widgets/templates"

local Customise = require "map/customise"
local Levels = require "map/levels"

local DEFAULT_PRESETS =
{
    "SURVIVAL_TOGETHER",
    "DST_CAVE",
}

local DEFAULT_TAB_LOCATIONS =
{
    "forest",
    "cave",
}

local function OnClickTab(self, level)
    if level ~= 1 and not self:IsLevelEnabled(level) then
        local locationname =
            STRINGS.UI.SANDBOXMENU.LOCATIONTABNAME[string.upper(self.activepresets[level].location or "")] or
            STRINGS.UI.SANDBOXMENU.LOCATIONTABNAME.UNKNOWN

        TheFrontEnd:PushScreen(
            PopupDialogScreen(
                STRINGS.UI.SANDBOXMENU.ADDLEVEL.." "..locationname.."?",
                string.format(STRINGS.UI.SANDBOXMENU.ADDLEVEL_WARNING, locationname),
                {
                    {
                        text = STRINGS.UI.MODSSCREEN.YES,
                        cb = function()
                            TheFrontEnd:PopScreen()
                            self:AddMultiLevel(level)
                            self:SelectMultilevel(level)
                            if TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse then
                                self:SetFocus(self.default_focus)
                            end
                        end,
                    },
                    {
                        text = STRINGS.UI.MODSSCREEN.NO,
                        cb = function() TheFrontEnd:PopScreen() end,
                    },
                }
            )
        )
    else
        self:SelectMultilevel(level)
        if TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse then
            self:SetFocus(self.default_focus)
        end
    end
end

local CustomizationTab = Class(Widget, function(self, servercreationscreen)
    Widget._ctor(self, "CustomizationTab")

    self.slotoptions = {}
    self.slot = -1
    self.currentmultilevel = 1
    self.allowEdit = true

    self.servercreationscreen = servercreationscreen

    -- Build the options menu so that the spinners are shown in an order that makes sense/in order of how impactful the changes are

    self.current_option_settings =
    {
        { tweak = {} }
        -- one level by default
    }

    local left_col =-RESOLUTION_X*.25 - 50
    local right_col = RESOLUTION_X*.25 - 75

    --set up the preset spinner

    self.max_custom_presets = 5

    self:ReloadPresetsFromProfile()

    self.presetpanel = self:AddChild(Widget("presetpanel"))
    self.presetpanel:SetPosition(left_col,15,0)

    self.multileveltabs = self.presetpanel:AddChild(Widget("multileveltabs"))
    self.multileveltabs:SetPosition(0, 140, 0)
    self.multileveltabs:Hide()

    self.multileveltabs_bg = self.multileveltabs:AddChild(Image("images/ui.xml", "black.tex"))
    self.multileveltabs_bg:SetSize(320, 60)
    self.multileveltabs_bg:SetPosition(0, 12)

    self.multileveltabs_bg_2 = self.multileveltabs:AddChild(Image("images/options_bg.xml", "options_panel_bg_narrow.tex"))
    self.multileveltabs_bg_2:SetSize(320, 334)
    self.multileveltabs_bg_2:SetPosition(0, -175)

    self.multileveltabs.tabs =
    {
        self.multileveltabs:AddChild(TEMPLATES.TabButton(-80, 0, "", function() OnClickTab(self, 1) end, "small")),
        self.multileveltabs:AddChild(TEMPLATES.TabButton(80, 0, "", function() OnClickTab(self, 2) end, "small")),
    }

    for i, v in ipairs(self.multileveltabs.tabs) do
        v:SetTextSize(24)
    end

    self.left_line = self:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
    self.left_line:SetScale(1, .6)
    self.left_line:SetPosition(-530, 5, 0)

    self.middle_line = self:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
    self.middle_line:SetScale(1, .59)
    self.middle_line:SetPosition(-210, 2, 0)

    self.presettitle = self.presetpanel:AddChild(Text(BUTTONFONT, 40))
    self.presettitle:SetColour(0,0,0,1)
    self.presettitle:SetHAlign(ANCHOR_MIDDLE)
    self.presettitle:SetRegionSize( 400, 70 )
    self.presettitle:SetString(STRINGS.UI.CUSTOMIZATIONSCREEN.USEPRESETS)

    self.presetdesc = self.presetpanel:AddChild(Text(NEWFONT, 25))
    self.presetdesc:SetColour(0,0,0,1)
    self.presetdesc:SetHAlign(ANCHOR_MIDDLE)
    self.presetdesc:SetRegionSize( 300, 110 )
    self.presetdesc:SetString(self.presets[1].desc)
    self.presetdesc:EnableWordWrap(true)

    local spinner_width = 290
    local spinner_height = nil -- use default height
    self.presetspinner = self.presetpanel:AddChild(Widget("presetspinner"))
    self.presetspinner.spinner = self.presetspinner:AddChild(Spinner( self.presets, spinner_width, spinner_height, {font=NEWFONT, size=22}, nil, nil, nil, true))
    self.presetspinner.focus_forward = self.presetspinner.spinner
    self.presetspinner.spinner:SetTextColour(0,0,0,1)
    self.presetspinner.bg = self.presetspinner:AddChild(Image("images/ui.xml", "single_option_bg_large.tex"))
    self.presetspinner.bg:SetScale(.57,.46)
    self.presetspinner.bg:SetPosition(-1,1)
    self.presetspinner.bg:MoveToBack()
    self.presetspinner.bg:SetClickable(false)
    self.presetspinner.spinner.OnChanged =
        function( _, data, oldData )
            if self.presetdirty[self.currentmultilevel] then
                if self.servercreationscreen then self.servercreationscreen.last_focus = TheFrontEnd:GetFocusWidget() end
                TheFrontEnd:PushScreen(PopupDialogScreen(STRINGS.UI.CUSTOMIZATIONSCREEN.LOSECHANGESTITLE, STRINGS.UI.CUSTOMIZATIONSCREEN.LOSECHANGESBODY,
                    {
                        {text=STRINGS.UI.CUSTOMIZATIONSCREEN.YES, cb = function()
                            self:ChangePresetForCurrentSlot(self.currentmultilevel, data, self.presetspinner.spinner:GetSelected().basepreset)
                            TheFrontEnd:PopScreen()
                        end},
                        {text=STRINGS.UI.CUSTOMIZATIONSCREEN.NO, cb = function()
                            self.presetspinner.spinner:SetSelected(oldData)
                            self:RefreshSpinnerValues()
                            self:RefreshTabValues() -- restore the "custom" text on the spinner
                            TheFrontEnd:PopScreen()
                        end}
                    }))
            else
                self:ChangePresetForCurrentSlot(self.currentmultilevel, data, self.presetspinner.spinner:GetSelected().basepreset)
            end
            self.servercreationscreen:UpdateButtons(self.slot)
            self.servercreationscreen:MakeDirty()
        end

    self.revertbutton = self.presetpanel:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "undo.tex", STRINGS.UI.CUSTOMIZATIONSCREEN.REVERTCHANGES, false, false, function() self:RevertChanges() end))
    self.revertbutton:Select()

    self.savepresetbutton = self.presetpanel:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "save.tex", STRINGS.UI.CUSTOMIZATIONSCREEN.SAVEPRESET, false, false, function() self:SavePreset() end))

    self.removemultilevel = self.presetpanel:AddChild(TEMPLATES.SmallButton(nil, 23, nil,
        function()
            local locationname =
                STRINGS.UI.SANDBOXMENU.LOCATIONTABNAME[string.upper(self.activepresets[self.currentmultilevel].location or "")] or
                STRINGS.UI.SANDBOXMENU.LOCATIONTABNAME.UNKNOWN
            TheFrontEnd:PushScreen(
                PopupDialogScreen(
                    STRINGS.UI.SANDBOXMENU.REMOVELEVEL.." "..locationname.."?",
                    string.format(STRINGS.UI.SANDBOXMENU.REMOVELEVEL_WARNING, locationname),
                    {
                        {
                            text = STRINGS.UI.MODSSCREEN.YES,
                            cb = function()
                                TheFrontEnd:PopScreen()
                                self:RemoveMultiLevel(self.currentmultilevel)
                                self:SelectMultilevel(1)
                                if TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse then
                                    self:SetFocus(self.default_focus)
                                end
                            end,
                        },
                        {
                            text = STRINGS.UI.MODSSCREEN.NO,
                            cb = function() TheFrontEnd:PopScreen() end,
                        },
                    }
                )
            )
        end))
    self.removemultilevel.image:SetScale(.5, .4)
    self.removemultilevel.text:SetPosition(0, -2, 0)
    self.removemultilevel:SetPosition(0, -170, 0)

    --add the custom options panel

    self.current_option_settingspanel = self:AddChild(Widget("optionspanel"))
    self.current_option_settingspanel:SetScale(.9)
    self.current_option_settingspanel:SetPosition(right_col,20,0)

    self:HookupFocusMoves()
    self:UpdateMultilevelUI()

    self.default_focus = self.presetspinner
    self.focus_forward = self.presetspinner
end)

function CustomizationTab:ReloadPresetsFromProfile()
    self.presets = {}
    self.activepresets = {}
    self.presetdirty = {}

    for i, level in pairs(Levels.sandbox_levels) do
        if not level.hideinfrontend then
            assert(level.id ~= nil, "Attempting to add an invalid level to the preset list. name: "..tostring(level.name))
            table.insert(self.presets, {text=level.name, data=level.id, desc = level.desc, overrides = level.overrides, location=level.location})
        end
    end

    local profilepresets = Profile:GetWorldCustomizationPresets()
    if profilepresets ~= nil then
        for i, level in pairs(profilepresets) do
            assert(level.data ~= nil, "Attempting to add an invalid custom preset to the preset list. name: "..tostring(level.text))
            table.insert(self.presets, {text=level.text, data=level.data, desc = level.desc, overrides = level.overrides, basepreset=level.basepreset, location=level.location})
        end
    end
end

function CustomizationTab:GetValueForOption(option)
    for idx,opt in ipairs(self.options) do
        if (opt.name == option) then
            local value = self.overrides[opt.name] or opt.default
            if self.current_option_settings[self.currentmultilevel].tweak[opt.group] then
                local possiblevalue = self.current_option_settings[self.currentmultilevel].tweak[opt.group][opt.name]
                value = possiblevalue or value
            end
            return value
        end
    end
    return nil
end

function CustomizationTab:AddMultiLevel(level)
    if level ~= 1 and self.slotoptions[self.slot][level] == nil then
        self.slotoptions[self.slot][level] =
        {
            actualpreset = DEFAULT_PRESETS[level],
            preset = DEFAULT_PRESETS[level],
            tweak = {},
        }
        self:UpdateMultilevelUI()
        self:UpdateOptions(level)
    end
end

function CustomizationTab:RemoveMultiLevel(level)
    if level ~= 1 and self.slotoptions[self.slot][level] ~= nil then
        self.slotoptions[self.slot][level] = nil
        self:UpdateMultilevelUI()
        self:UpdateOptions(level)
    end
end

function CustomizationTab:UpdateMultilevelUI()
    --V2C: Always show multilevel tabs
    --     Instead, clear out the info when the tab level is not enabled
    self.presettitle:SetPosition(0, 85, 0)
    self.presetdesc:SetPosition(0, -40, 0)
    self.presetspinner:SetPosition(0, 35, 0)
    self.revertbutton:SetPosition(-35, -125, 0)
    self.savepresetbutton:SetPosition(40, -125, 0)

    self.presettitle:Show()
    self.presetdesc:Show()
    self.presetspinner:Show()
    self.multileveltabs:Show()

    --[[ --Old code for no tabs layout
        self.presettitle:SetPosition(0, 105, 0)
        self.presetdesc:SetPosition(0, -20, 0)
        self.presetspinner:SetPosition(0, 55, 0)
        self.revertbutton:SetPosition(-35, -115, 0)
        self.savepresetbutton:SetPosition(40, -115, 0)

        self.multileveltabs:Hide()
        self.removemultilevel:Hide()
    ]]

    if self.allowEdit then
        self.revertbutton:Show()
        self.savepresetbutton:Show()
    else
        self.revertbutton:Hide()
        self.savepresetbutton:Hide()
    end

    if self.allowEdit and self.currentmultilevel ~= 1 then
        self.removemultilevel:Show()
    else
        self.removemultilevel:Hide()
    end

    local currentpresets = self.activepresets[self.currentmultilevel]
    local locationid = currentpresets ~= nil and string.upper(currentpresets.location or "") or nil

    local locationname = STRINGS.UI.SANDBOXMENU.LOCATION[locationid]
    locationname = locationname ~= nil and (locationname.." ") or ""
    self.presettitle:SetString(locationname.." "..STRINGS.UI.SANDBOXMENU.USEPRESETS)

    locationname = STRINGS.UI.SANDBOXMENU.LOCATIONTABNAME[locationid]
    locationname = locationname ~= nil and (locationname.." ") or ""
    self.removemultilevel:SetText(STRINGS.UI.SANDBOXMENU.REMOVELEVEL.." "..locationname)

    for i, tab in ipairs(self.multileveltabs.tabs) do
        if i == self.currentmultilevel or not (self.allowEdit or self:IsLevelEnabled(i)) then
            tab:Disable()
        else
            tab:Enable()
        end
    end
end

function CustomizationTab:SelectMultilevel(level)
    self.currentmultilevel = level
    self:RefreshSpinnerValues()
    self:RefreshTabValues()
    self:UpdateMultilevelUI()
end

function CustomizationTab:SetTweak(option, value)

    for idx,v in ipairs(self.options) do
        if (self.options[idx].name == option) then
            local group = self.options[idx].group

            if (value == self.overrides[option] or
                (value == v.default and self.overrides[option] == nil)) then

                if self.current_option_settings[self.currentmultilevel].tweak[group] then
                    self.current_option_settings[self.currentmultilevel].tweak[group][option] = nil
                    if not next(self.current_option_settings[self.currentmultilevel].tweak[group]) then
                        self.current_option_settings[self.currentmultilevel].tweak[group] = nil
                    end
                end
            else
                if not self.current_option_settings[self.currentmultilevel].tweak[group] then
                    self.current_option_settings[self.currentmultilevel].tweak[group] = {}
                end
                self.current_option_settings[self.currentmultilevel].tweak[group][option] = value
            end
        end
    end
end

function CustomizationTab:VerifyValidSeasonSettings()
    local autumn = self:GetValueForOption("autumn")
    local winter = self:GetValueForOption("winter")
    local spring = self:GetValueForOption("spring")
    local summer = self:GetValueForOption("summer")
    if autumn == "noseason" and winter == "noseason" and spring == "noseason" and summer == "noseason" then
        return false
    end
    return true
end

function CustomizationTab:LoadPreset(level, preset)
    for k,v in pairs(self.presets) do
        if preset == v.data then
            self.presetdirty[level] = false
            self.activepresets[level] = deepcopy(v)
            return
        end
    end

    -- We can only get here if a world was created before all preset data was being populated into the save index.
    print("Presets:")
    local s = {}
    for k,p in pairs(self.presets) do
        table.insert(s, p.data)
    end
    print(table.concat(s,", "))
    print("Error: Tried loading preset "..preset.." but we don't have that!")

    self:LoadUnknownPreset(level)
end

function CustomizationTab:LoadUnknownPreset(level)
    -- Populate a "fake" empty preset so that the screen still functions in case the loaded preset is missing.
    -- This is super gross, I know. I apologize. ~gjans
    self.presetspinner.spinner:UpdateText(STRINGS.UI.CUSTOMIZATIONSCREEN.UNKNOWN_PRESET)
    self.presetdesc:SetString(STRINGS.UI.CUSTOMIZATIONSCREEN.UNKNOWN_PRESET_DESC)
    self.presetdirty[level] = false
    self.activepresets[level] = {
        basepreset = "UNKNOWN_PRESET",
        data = "UNKNOWN_PRESET",
        overrides = {},
        text = STRINGS.UI.CUSTOMIZATIONSCREEN.UNKNOWN_PRESET,
        desc = STRINGS.UI.CUSTOMIZATIONSCREEN.UNKNOWN_PRESET_DESC,
    }

    table.insert(self.presets, 1, self.activepresets[level])
end

function CustomizationTab:SavePreset()

    local function AddPreset(index, presetdata)
        local presetid = "CUSTOM_PRESET_"..index
        local presetname = STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOM_PRESET.." "..index
        local presetdesc = STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOM_PRESET_DESC.." "..index..". "..STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOMDESC

        -- Add the preset to the preset spinner and make the preset the selected one

        local custom = GetTypeForLevelID(self.presetspinner.spinner:GetSelected().data) == LEVELTYPE.UNKNOWN
        local base = custom and self.presetspinner.spinner:GetSelected().basepreset or self.presetspinner.spinner:GetSelected().data
        local location = self.presetspinner.spinner:GetSelected().location
        local preset = {text=presetname, data=presetid, desc=presetdesc, overrides=presetdata, basepreset=base, location=location}
        -- just throw this to the end of the presets list for now
        self.presets[#self.presets + 1] = preset
        self.presetspinner.spinner:SetOptions(self.presets)
        self.presetspinner.spinner:SetSelectedIndex(#self.presets)

        -- And save it to the profile
        Profile:AddWorldCustomizationPreset(preset, index)
        Profile:Save()

        self:ReloadPresetsFromProfile()
        self:UpdateOptions()

        self:ChangePresetForCurrentSlot(self.currentmultilevel, preset.data, preset.basepreset)
        if self.servercreationscreen then self.servercreationscreen:UpdateButtons(self.slot) end
    end

    -- Grab the current data
    -- First, the current preset's values
    local newoverrides = {}
    for i,override in ipairs(self.activepresets[self.currentmultilevel].overrides) do
        table.insert(newoverrides, {override[1], override[2]})
    end

    -- Then, the current tweaks
    for group,tweaks in pairs(self.current_option_settings[self.currentmultilevel].tweak) do
        for tweakname, tweakvalue in pairs(tweaks) do
            local found = false
            for i,override in ipairs(newoverrides) do
                if override[1] == tweakname then
                    override[2] = tweakvalue
                    found = true
                    break
                end
            end

            if not found then
                table.insert(newoverrides, {tweakname, tweakvalue})
            end
        end
    end

    if #newoverrides <= 0 then return end

    -- Figure out what the id, name and description should be
    local presetnum = (Profile:GetWorldCustomizationPresets() and #Profile:GetWorldCustomizationPresets() or 0) + 1

    -- If we're at max num of presets, show a modal dialog asking which one to replace
    if presetnum > self.max_custom_presets then
        local modal = nil -- forward declare
        local menuitems =
        {
            {text=STRINGS.UI.CUSTOMIZATIONSCREEN.OVERWRITE, 
                cb = function()
                    TheFrontEnd:PopScreen()
                    AddPreset(modal.overwrite_spinner.spinner:GetSelectedIndex(), newoverrides)
                end},
            {text=STRINGS.UI.CUSTOMIZATIONSCREEN.CANCEL,
                cb = function()
                    TheFrontEnd:PopScreen()
                end}
        }
        modal = PopupDialogScreen(STRINGS.UI.CUSTOMIZATIONSCREEN.MAX_PRESETS_EXCEEDED_TITLE, STRINGS.UI.CUSTOMIZATIONSCREEN.MAX_PRESETS_EXCEEDED_BODY..STRINGS.UI.CUSTOMIZATIONSCREEN.MAX_PRESETS_EXCEEDED_BODYSPACING, menuitems)

        local spinner_options = {}
        for i=1,self.max_custom_presets do
            table.insert(spinner_options, {text=tostring(i), data=i})
        end
        local size = JapaneseOnPS4() and 28 or 30
        modal.overwrite_spinner = modal.proot:AddChild(TEMPLATES.LabelSpinner(STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOM_PRESET, spinner_options, 200, 110, 40, 5, NEWFONT, size))
        modal.overwrite_spinner.spinner:SetSelected("1")
        modal.overwrite_spinner:SetPosition(0,-60,0)
        local bg = modal.overwrite_spinner:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
        bg:MoveToBack()
        bg:SetClickable(false)
        bg:SetScale(.75,.95)


        modal.menu:SetFocusChangeDir(MOVE_UP, modal.overwrite_spinner)
        modal.overwrite_spinner:SetFocusChangeDir(MOVE_DOWN, modal.menu)

        modal.menu.items[1]:SetScale(.7)
        modal.menu.items[2]:SetScale(.7)
        modal.text:SetPosition(5, 10, 0)
        if self.servercreationscreen then self.servercreationscreen.last_focus = TheFrontEnd:GetFocusWidget() end
        TheFrontEnd:PushScreen(modal)
    else -- Otherwise, just save it
        AddPreset(presetnum, newoverrides)
    end
end

function CustomizationTab:ChangePresetForCurrentSlot(level, preset, basepreset)
    self.slotoptions[self.slot][level].actualpreset = preset
    self.slotoptions[self.slot][level].preset = basepreset
    self.slotoptions[self.slot][level].tweak = {}
    self:UpdateOptions(level)

    self.servercreationscreen:UpdateButtons(self.slot)
end

function CustomizationTab:RefreshSpinnerValues()
    --these are in kind of a weird format, so convert it to something useful...
    self.overrides = {}
    for i, v in ipairs(self.presets) do
        if self.activepresets[self.currentmultilevel].data == v.data then
            for k, v2 in pairs(v.overrides) do
                self.overrides[v2[1]] = v2[2]
            end
        end
    end

    local location = self.activepresets[self.currentmultilevel].location or "forest"
    self.options = Customise.GetOptions(location, self.currentmultilevel == 1)
    if self.customizationlist ~= nil then
        self.customizationlist:Kill()
    end

    if not self:IsLevelEnabled(self.currentmultilevel) then
        --Disabled level tab
        return
    end

    self.customizationlist = self.current_option_settingspanel:AddChild(CustomizationList(location, self.options,
        function(option, value)
            self:SetTweak(option, value)
            self:RefreshTabValues()
        end))
    self.customizationlist:SetPosition(-245, -24, 0)
    self.customizationlist:SetFocusChangeDir(MOVE_LEFT, self.presetspinner)
    self.customizationlist:SetPresetValues(self.overrides)
    self.customizationlist:SetEditable(self.allowEdit)

    for i,v in ipairs(self.options) do
        self.customizationlist:SetValueForOption(v.name, self:GetValueForOption(v.name))
    end
end

function CustomizationTab:UpdateOptions(singlelevel)

    if singlelevel == nil then
        self.current_option_settings = {}
        for i,leveldata in ipairs(self.slotoptions[self.slot]) do

            self.current_option_settings[i] = deepcopy(leveldata)
            if self.current_option_settings[i] ~= nil then
                local preset = self.current_option_settings[i].actualpreset
                    or self.current_option_settings[i].preset
                    or self.presets[i].data
                self:LoadPreset(i, preset)

                self.current_option_settings[i].tweak = self.current_option_settings[i].tweak or {}
            else
                self.current_option_settings[i] = { tweak = {} }
            end
        end
        --V2C: need to load the default preset for disabled levels too
        --     now that we don't hide any tabs
        for i, v in ipairs(DEFAULT_PRESETS) do
            if self.slotoptions[self.slot][i] == nil then
                self:LoadPreset(i, v)
            end
        end
    else
        self.current_option_settings[singlelevel] = deepcopy(self.slotoptions[self.slot][singlelevel])
        if self.current_option_settings[singlelevel] ~= nil then
            local preset = self.current_option_settings[singlelevel].actualpreset
                or self.current_option_settings[singlelevel].preset
                or self.presets[1].data
            self:LoadPreset(singlelevel, preset)

            self.current_option_settings[singlelevel].tweak = self.current_option_settings[singlelevel].tweak or {}
        end
        -- if it is nil, the level has been removed in the slotoptions. cool.
    end

    self:RefreshSpinnerValues()
    self:RefreshTabValues()
end

function CustomizationTab:IsLevelEnabled(level)
    return self.slotoptions[self.slot] ~= nil and self.slotoptions[self.slot][level] ~= nil
end

function CustomizationTab:RefreshTabValues()
    --V2C: filter presets for the tab based on the location of the current selection
    local tablocation = self.activepresets[self.currentmultilevel].location or DEFAULT_TAB_LOCATIONS[self.currentmultilevel]

    if tablocation ~= nil then
        local filteredpresets = {}
        for i, v in ipairs(self.presets) do
            if v.location == tablocation then
                table.insert(filteredpresets, v)
            end
        end
        self.presetspinner.spinner:SetOptions(filteredpresets)
    else
        --This is fallback, but shouldn't happen with normal data
        self.presetspinner.spinner:SetOptions(self.presets)
    end

    for i, presetdata in ipairs(self.activepresets) do
        local clean = self:GetNumberOfTweaks(i) == 0

        local locationname =
            STRINGS.UI.SANDBOXMENU.LOCATIONTABNAME[string.upper(self.activepresets[i].location or "")] or
            STRINGS.UI.SANDBOXMENU.LOCATIONTABNAME.UNKNOWN

        --self.multileveltabs.tabs[i]:SetText(self.activepresets[i].text .. (clean and "" or "*"))

        --V2C: make the tab heading very clear that one is Forest tab and one is Caves tab
        local tabbtn = self.multileveltabs.tabs[i]
        if self:IsLevelEnabled(i) then
            --tab is enabled, make it look like a regular tab
            tabbtn:SetText(locationname)
            tabbtn:SetTextures("images/frontend.xml", "tab2_button.tex", "tab2_button_highlight.tex", "tab2_selected.tex", nil, nil, { 1, 1 }, { 0, 0 })
            tabbtn.image:SetScale(.73)
            tabbtn:SetFont(NEWFONT_OUTLINE)
            tabbtn:SetDisabledFont(NEWFONT_SMALL)
            tabbtn:SetTextColour(unpack(GOLD))
            tabbtn:SetTextFocusColour(unpack(GOLD))
            tabbtn:SetTextDisabledColour(unpack(BLACK))
        elseif self.allowEdit then
            --tab is disabled, make it look like an "Add ___" button
            tabbtn:SetText(STRINGS.UI.SANDBOXMENU.ADDLEVEL.." "..locationname)
            tabbtn:SetTextures("images/frontend.xml", "button_long.tex", "button_long_highlight.tex", "button_long_disabled.tex", "button_long_halfshadow.tex", nil, { 1, 1 }, { 6, 2 })
            tabbtn.image:SetScale(.5, .6)
            tabbtn:SetFont(NEWFONT_SMALL)
            tabbtn:SetDisabledFont(NEWFONT_SMALL)
            tabbtn:SetTextColour(unpack(BLACK))
            tabbtn:SetTextFocusColour(unpack(BLACK))
            tabbtn:SetTextDisabledColour(unpack(BLACK))
        else
            --tab is disabled, but we can't add it because this slot is not editable
            tabbtn:SetText(STRINGS.UI.SANDBOXMENU.DISABLEDLEVEL.." "..locationname)
            tabbtn:SetTextures("images/frontend.xml", "tab2_button.tex", "tab2_button.tex", "tab2_button.tex", nil, nil, { 1, 1 }, { 0, 0 })
            tabbtn.image:SetScale(.73)
            tabbtn:SetFont(NEWFONT_SMALL)
            tabbtn:SetDisabledFont(NEWFONT_SMALL)
            tabbtn:SetTextColour(unpack(BLACK))
            tabbtn:SetTextFocusColour(unpack(BLACK))
            tabbtn:SetTextDisabledColour(unpack(BLACK))
        end

        if i == self.currentmultilevel then
            self.presetspinner.spinner:SetSelected(self.activepresets[i].data)
            self.presetdesc:SetString(self.activepresets[i].desc)

            if not clean then
                self.presetdesc:SetString(STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOMDESC)
                self.presetspinner.spinner:UpdateText(self.activepresets[i].text .. " " .. STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOM)
            end

            if not clean and self.allowEdit then
                self.presetdirty[i] = true
                self.revertbutton:Unselect()
            else
                self.presetdirty[i] = false
                self.revertbutton:Select()
            end
        end
    end

    if self.allowEdit then
        self.presetspinner.spinner:Enable()
    else
        self.presetspinner.spinner:Disable()
        self.presetspinner.spinner:SetTextColour(0,0,0,1)
    end

    for i, dirty in ipairs(self.presetdirty) do
        if dirty then
            self.servercreationscreen:MakeDirty()
            break
        end
    end

    if self.servercreationscreen ~= nil and self.servercreationscreen.UpdateButtons ~= nil then
        self.servercreationscreen:UpdateButtons(self.slot)
    end
end

function CustomizationTab:CollectOptions()
    local ret = deepcopy(self.current_option_settings)
    for i,level in ipairs(self.current_option_settings) do
        ret[i].presetdata = deepcopy(self.activepresets[i])
    end
    return ret
end

function CustomizationTab:UpdateSlot(slotnum, prevslot, delete)
    if not delete and (slotnum == prevslot or not slotnum or not prevslot) then return end

    self.allowEdit = true
    self.slot = slotnum

    -- Remember what was typed/set
    if prevslot and prevslot > 0 then
        self.slotoptions[prevslot] = deepcopy(self.current_option_settings)
    end

    -- No save data
    if slotnum < 0 or SaveGameIndex:IsSlotEmpty(slotnum) then
        -- no slot, so hide all the details and set all the text boxes back to their defaults
        if prevslot and prevslot > 0 and SaveGameIndex:IsSlotEmpty(prevslot) then
            -- Duplicate prevslot's data into our new slot if it was also a blank slot
            self.slotoptions[slotnum] = deepcopy(self.slotoptions[prevslot])
        else
            self.slotoptions[slotnum] = { { tweak = {} } }

            --Enable caves by default
            --(by uncommenting.. it's disabled by default now)
            --[[
            self.slotoptions[self.slot][2] = {
                actualpreset = DEFAULT_PRESETS[2],
                preset = DEFAULT_PRESETS[2],
                tweak={},
            }]]
        end
    else -- Save data
        self.allowEdit = false
        self.slotoptions[slotnum] = SaveGameIndex:GetSlotGenOptions(slotnum) or { { tweak = {} } }
    end

    local previouslevel = self.currentmultilevel
    self.currentmultilevel = 1

    self:UpdateOptions()
    self:UpdateMultilevelUI()

    if previouslevel ~= self.currentmultilevel and self:IsLevelEnabled(previouslevel) then
        self:SelectMultilevel(previouslevel)
    end
end

function CustomizationTab:GetNumberOfTweaks(levelonly)
    local numTweaks = 0

    if self.current_option_settings then
        for i, level in ipairs(self.current_option_settings) do
            if levelonly == nil or i == levelonly then
                if level.tweak then
                    for i,v in pairs(level.tweak) do
                        if v then
                            for j,k in pairs(v) do
                                numTweaks = numTweaks + 1
                            end
                        end
                    end
                end
            end
        end
        return numTweaks
    else
        return 0
    end
end

function CustomizationTab:GetPresetName()
    if self.slotoptions[self.slot][2] ~= nil then
        return "Multilevel World" -- #TODO: strings.lua
    elseif self.slotoptions[self.slot][1].presetdata then
        return self.slotoptions[self.slot][1].presetdata.text
    elseif self.slotoptions[self.slot][1].actualpreset ~= nil then
        for i,preset in ipairs(self.presets) do
            if preset.data == self.slotoptions[self.slot][1].actualpreset then
                return preset.text
            end
        end
    elseif self.slotoptions[self.slot][1].preset ~= nil then
        for i,preset in ipairs(self.presets) do
            if preset.data == self.slotoptions[self.slot][1].preset then
                return preset.text
            end
        end
    end
    return self.presets[1].text
end

function CustomizationTab:RevertChanges()
    if self.servercreationscreen then self.servercreationscreen.last_focus = TheFrontEnd:GetFocusWidget() end
    TheFrontEnd:PushScreen(
        PopupDialogScreen( STRINGS.UI.CUSTOMIZATIONSCREEN.BACKTITLE, STRINGS.UI.CUSTOMIZATIONSCREEN.BACKBODY,
        {
            {
                text = STRINGS.UI.CUSTOMIZATIONSCREEN.YES,
                cb = function()
                    if self.slotoptions[self.slot] and self.slotoptions[self.slot][self.currentmultilevel] then
                        self.slotoptions[self.slot][self.currentmultilevel].tweak = {}
                    else
                        if self.slotoptions[self.slot] == nil then
                            self.slotoptions[self.slot] = {}
                        end
                        self.slotoptions[self.slot][self.currentmultilevel] = {
                            tweak = {},
                        }
                    end
                    self:UpdateOptions(self.currentmultilevel)
                    TheFrontEnd:PopScreen()
                end,
            },
            {
                text = STRINGS.UI.CUSTOMIZATIONSCREEN.NO,
                cb = function()
                    TheFrontEnd:PopScreen()
                end,
            },
          }
        )
    )
end

function CustomizationTab:HookupFocusMoves()
    local tosaveslots = self.servercreationscreen ~= nil and self.servercreationscreen.getfocussaveslot or nil

    local function tocustomizationlist()
        return self.customizationlist
    end

    local function toleveltab()
        return self.multileveltabs.tabs[self.currentmultilevel < #self.multileveltabs.tabs and self.currentmultilevel + 1 or self.currentmultilevel - 1]
    end

    for i, v in ipairs(self.multileveltabs.tabs) do
        v:SetFocusChangeDir(MOVE_DOWN, self.presetspinner)
        v:SetFocusChangeDir(MOVE_RIGHT, i < #self.multileveltabs.tabs and self.multileveltabs.tabs[i + 1] or tocustomizationlist)
        v:SetFocusChangeDir(MOVE_LEFT, i > 1 and self.multileveltabs.tabs[i - 1] or tosaveslots)
    end
    self.presetspinner:SetFocusChangeDir(MOVE_UP, toleveltab)
    self.presetspinner:SetFocusChangeDir(MOVE_RIGHT, tocustomizationlist)
    self.presetspinner:SetFocusChangeDir(MOVE_DOWN, self.revertbutton)
    self.revertbutton:SetFocusChangeDir(MOVE_RIGHT, self.savepresetbutton)
    self.revertbutton:SetFocusChangeDir(MOVE_UP, self.presetspinner)
    self.revertbutton:SetFocusChangeDir(MOVE_DOWN, self.removemultilevel)
    self.savepresetbutton:SetFocusChangeDir(MOVE_LEFT, self.revertbutton)
    self.savepresetbutton:SetFocusChangeDir(MOVE_UP, self.presetspinner)
    self.savepresetbutton:SetFocusChangeDir(MOVE_RIGHT, tocustomizationlist)
    self.savepresetbutton:SetFocusChangeDir(MOVE_DOWN, self.removemultilevel)
    self.removemultilevel:SetFocusChangeDir(MOVE_UP, self.savepresetbutton)
    self.removemultilevel:SetFocusChangeDir(MOVE_LEFT, tosaveslots)
    self.removemultilevel:SetFocusChangeDir(MOVE_RIGHT, tocustomizationlist)

    self.presetspinner:SetFocusChangeDir(MOVE_LEFT, tosaveslots)
    self.revertbutton:SetFocusChangeDir(MOVE_LEFT, tosaveslots)
end

return CustomizationTab
