local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Spinner = require "widgets/spinner"
local NumericSpinner = require "widgets/numericspinner"
local ScrollableList = require "widgets/scrollablelist"
local Grid = require "widgets/grid"
local PopupDialogScreen = require "screens/popupdialog"
local TEMPLATES = require "widgets/templates"

local levels = require "map/levels"
local customise = nil
local options = {}

local FORCE_SHOW_BG_IN_VIEW_MODE = true

local per_side = 7

local CustomizationTab = Class(Widget, function(self, profile, customoptions, allowEdit, slot, servercreationscreen)
    Widget._ctor(self, "CustomizationTab")
  
    self.customization_page = self:AddChild(Widget("customization_page"))

    self.left_line = self.customization_page:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
    self.left_line:SetScale(1, .6)
    self.left_line:SetPosition(-530, 5, 0)

    self.middle_line = self.customization_page:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
    self.middle_line:SetScale(1, .59)
    self.middle_line:SetPosition(-210, 2, 0)

    self.slotoptions = {}
    self.slot = slot

    self.spinners = {}

    self.profile = profile
    self.defaults = customoptions

    self.allowEdit = allowEdit

    self.servercreationscreen = servercreationscreen

    self.focused_column = 1

    -- Build the options menu so that the spinners are shown in an order that makes sense/in order of how impactful the changes are
    if #options == 0 then
        customise = require("map/customise")

        options = {}

        local groups = {}
        for k,v in pairs(customise.GROUP) do
            table.insert(groups,k)
        end

        table.sort(groups, function(a,b) return customise.GROUP[a].order < customise.GROUP[b].order end)

        for i,groupname in ipairs(groups) do
            local items = {}
            local group = customise.GROUP[groupname]
            for k,v in pairs(group.items) do
                table.insert(items, k)
            end

            table.sort(items, function(a,b) return group.items[a].order < group.items[b].order end)

            for ii,itemname in ipairs(items) do
                local item = group.items[itemname]
                table.insert(options, {name = itemname, image = item.image, options = item.desc or group.desc, default = item.value, group = groupname, grouplabel = group.text})
            end
        end
    end
    
    if customoptions then
        self.current_option_settings = deepcopy(customoptions)
        self.current_option_settings.tweak = self.current_option_settings.tweak or {}
        self.current_option_settings.preset = self.current_option_settings.preset or {}
    else
        self.current_option_settings = 
        { 
            preset = {},
            tweak = {}
        }
    end
    


    local left_col =-RESOLUTION_X*.25 - 50
    local right_col = RESOLUTION_X*.25 - 75

        --set up the preset spinner

    self.max_num_presets = 5

    self.presets = {}

    for i, level in pairs(levels.sandbox_levels) do
        table.insert(self.presets, {text=level.name, data=level.id, desc = level.desc, overrides = level.overrides})
    end

    local profilepresets = Profile:GetWorldCustomizationPresets()
    if profilepresets then
        for i, level in pairs(profilepresets) do
            table.insert(self.presets, {text=level.text, data=level.data, desc = level.desc, overrides = level.overrides, basepreset=level.basepreset})
        end
    end

    -- This was causing weirdness with adding a duplicate entry into the presetspinner, so I commented it out and now it's fixed... *shrug*
    -- if self.defaults and self.defaults.presetdata then
    --     table.insert(self.presets, 1, self.defaults.presetdata)
    -- end
    
    self.presetpanel = self.customization_page:AddChild(Widget("presetpanel"))
    self.presetpanel:SetPosition(left_col,15,0)
    
    self.presettitle = self.presetpanel:AddChild(Text(BUTTONFONT, 40))
    self.presettitle:SetColour(0,0,0,1)
    self.presettitle:SetHAlign(ANCHOR_MIDDLE)
    self.presettitle:SetPosition(5, 105, 0)
    self.presettitle:SetRegionSize( 400, 70 )
    self.presettitle:SetString(STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETTITLE)

    self.presetdesc = self.presetpanel:AddChild(Text(NEWFONT, 25))
    self.presetdesc:SetColour(0,0,0,1)
    self.presetdesc:SetHAlign(ANCHOR_MIDDLE)
    self.presetdesc:SetPosition(0, -60, 0)
    self.presetdesc:SetRegionSize( 300, 130 )
    self.presetdesc:SetString(self.presets[1].desc)
    self.presetdesc:EnableWordWrap(true)

    local w = 300
    self.presetspinner = self.presetpanel:AddChild(Widget("presetspinner"))
    self.presetspinner.spinner = self.presetspinner:AddChild(Spinner( self.presets, w, 50, {font=NEWFONT, size=22}, nil, nil, nil, true, w - 30)) 
    self.presetspinner.focus_forward = self.presetspinner.spinner
    self.presetspinner:SetPosition(0, 30, 0)
    self.presetspinner.spinner:SetTextColour(0,0,0,1)
    self.presetspinner.bg = self.presetspinner:AddChild(Image("images/ui.xml", "single_option_bg_large.tex"))
    self.presetspinner.bg:SetScale(.57,.46)
    self.presetspinner.bg:SetPosition(-1,1)
    self.presetspinner.bg:MoveToBack()
    self.presetspinner.bg:SetClickable(false)
    self.presetspinner.spinner.OnChanged =
        function( _, data )
            if self.presetdirty then
                if self.servercreationscreen then self.servercreationscreen.last_focus = TheFrontEnd:GetFocusWidget() end
                TheFrontEnd:PushScreen(PopupDialogScreen(STRINGS.UI.CUSTOMIZATIONSCREEN.LOSECHANGESTITLE, STRINGS.UI.CUSTOMIZATIONSCREEN.LOSECHANGESBODY, 
                    {{text=STRINGS.UI.CUSTOMIZATIONSCREEN.YES, cb = function() 
                        if self.current_option_settings then
                            self.current_option_settings.tweak = {}
                        end
                        if self.slotoptions[self.slot] then
                            self.slotoptions[self.slot].tweak = {}
                        else
                            self.slotoptions[self.slot] = {}
                        end

                        self:MakePresetClean() 
                        TheFrontEnd:PopScreen()
                    end},
                    {text=STRINGS.UI.CUSTOMIZATIONSCREEN.NO, cb = function() self:MakePresetDirty() TheFrontEnd:PopScreen() end}  }))
            else
                self:LoadPreset(data)
                self.current_option_settings.tweak = {}             
            end
            self.servercreationscreen:UpdateButtons(self.slot)
            self.servercreationscreen:MakeDirty()
        end
    
    if self.allowEdit == false then
        self.presetspinner.spinner:Disable()
        self.presetspinner.spinner:SetTextColour(0,0,0,1)
    end
    
    --menu buttons
    self.current_option_settingspanel = self.customization_page:AddChild(Widget("optionspanel"))
    self.current_option_settingspanel:SetScale(.9)
    self.current_option_settingspanel:SetPosition(right_col,20,0)
    
    self.revertbutton = self.presetpanel:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "undo.tex", STRINGS.UI.CUSTOMIZATIONSCREEN.REVERTCHANGES, false, false, function() self:RevertChanges() end))
    self.revertbutton:SetPosition(-35, -160, 0)
    self.revertbutton:Select()

    self.savepresetbutton = self.presetpanel:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "save.tex", STRINGS.UI.CUSTOMIZATIONSCREEN.SAVEPRESET, false, false, function() self:SavePreset() end))
    self.savepresetbutton:SetPosition(40, -160, 0)

    --add the custom options panel
    
    local preset = (self.defaults and (self.defaults.actualpreset or self.defaults.preset)) or self.presets[1].data

    self:LoadPreset(preset)

    if self.defaults and self.defaults.tweak and next(self.defaults.tweak) then
        self:MakePresetDirty()
    end

    local clean = true
    if self.current_option_settings and self.current_option_settings.tweak then
        for i,v in pairs(self.current_option_settings.tweak) do
            for m,n in pairs(v) do
                if #self.current_option_settings.tweak[i][m] > 0 then
                    clean = false
                    break
                end
            end
        end
        if clean then
            self:MakePresetClean()
        end
    end

    if self.allowEdit == false then
        -- Since we can't actually edit, act like the preset is clean but append "(Custom)" if it's not actually clean
        self:MakePresetClean()
        if not clean then
            for k,v in pairs(self.presets) do
                if self.preset.data == v.data then
                    self.presetdesc:SetString(STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOMDESC)
                    self.presetspinner.spinner:UpdateText(v.text .. " " .. STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOM)
                end
            end
        end
    end

    self:HookupFocusMoves()

    self.default_focus = self.presetspinner
    self.focus_forward = self.presetspinner
end)

function CustomizationTab:GetValueForOption(option)
    -- local overrides = {}
    -- for k,v in pairs(self.presets) do
    --  if self.preset == v.data then
    --      for k,v in pairs(v.overrides) do
    --          overrides[v[1]] = v[2]
    --      end
    --  end
    -- end

    for idx,v in ipairs(options) do
        if (options[idx].name == option) then
            local value = self.overrides[options[idx].name] or options[idx].default
            if self.current_option_settings.tweak[options[idx].group] then
                local possiblevalue = self.current_option_settings.tweak[options[idx].group][options[idx].name]
                value = possiblevalue or value
            end
            return value
        end
    end
    return nil
end

function CustomizationTab:SetValueForOption(option, value) 
    for idx,v in ipairs(options) do
        if (options[idx].name == option) then
            local spinner = self.spinners[idx]
            spinner:SetSelected(value)
        end
    end
    
    -- local overrides = {}
    -- for k,v in pairs(self.presets) do
    --  if self.preset == v.data then
    --      for k,v in pairs(v.overrides) do
    --          overrides[v[1]] = v[2]
    --      end
    --  end
    -- end

    for idx,v in ipairs(options) do
        if (options[idx].name == option) then
            local default_value = self.overrides[options[idx].name] or options[idx].default
            if value ~= default_value then 
                if not self.current_option_settings.tweak[options[idx].group] then
                    self.current_option_settings.tweak[options[idx].group] = {}
                end
                self.current_option_settings.tweak[options[idx].group][options[idx].name] = value
                local bg = self.spinners[idx].bg
                if (self.allowEdit ~= false or FORCE_SHOW_BG_IN_VIEW_MODE) and value ~= options[idx].default then
                    bg:SetTint(.15,.15,.15,1) --bg:SetTint(.3,.3,.3,1)
                else
                    bg:SetTint(1,1,1,1)
                end
            else
                if not self.current_option_settings.tweak[options[idx].group] then
                    self.current_option_settings.tweak[options[idx].group] = {}
                end
                self.current_option_settings.tweak[options[idx].group][options[idx].name] = nil
                if not next(self.current_option_settings.tweak[options[idx].group]) then
                    self.current_option_settings.tweak[options[idx].group] = nil
                end
                local bg = self.spinners[idx].bg
                if value ~= options[idx].default then
                    bg:SetTint(.15,.15,.15,1) --bg:SetTint(.3,.3,.3,1)
                else
                    bg:SetTint(1,1,1,1)
                end             
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

function CustomizationTab:MakePresetDirty()
    if not self.presets then return end

    self.presetdirty = true

    if self.revertbutton then self.revertbutton:Unselect() end
    
    for k,v in pairs(self.presets) do
        if self.preset.data == v.data then
            self.presetdesc:SetString(STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOMDESC)
            self.presetspinner.spinner:UpdateText(v.text .. " " .. STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOM)
        end
    end
end

function CustomizationTab:MakePresetClean()
    if self.revertbutton then self.revertbutton:Select() end
    self:LoadPreset(self.presetspinner.spinner:GetSelectedData())
end

function CustomizationTab:LoadPreset(preset)
    for k,v in pairs(self.presets) do
        if preset == v.data then
            self.presetdesc:SetString(v.desc)
            self.presetspinner.spinner:SetSelectedIndex(k)
            self.presetdirty = false
            self.preset = v
            self.current_option_settings.preset = v.data
            if not self.optionwidgets then
                self:MakeOptionSpinners()
            else
                self:RefreshOptions()
            end
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
    print(self.defaults and "Have default: "..(self.defaults.preset or "<nil>")..", "..(self.defaults.actualpreset or "<nil>")..", saved preset data: "..(self.defaults.presetdata and self.defaults.presetdata.data or "<nil>") or "No defaults found.")

    self:LoadUnknownPreset()
end

function CustomizationTab:LoadUnknownPreset()
    -- Populate a "fake" empty preset so that the screen still functions in case the loaded preset is missing.
    -- This is super gross, I know. I apologize. ~gjans
    self.presetspinner.spinner:UpdateText(STRINGS.UI.CUSTOMIZATIONSCREEN.UNKNOWN_PRESET)
    self.presetdesc:SetString(STRINGS.UI.CUSTOMIZATIONSCREEN.UNKNOWN_PRESET_DESC)
    self.presetdirty = false
    self.preset = {
        basepreset = "UNKNOWN_PRESET",
        data = "UNKNOWN_PRESET",
        overrides = {},
        text = STRINGS.UI.CUSTOMIZATIONSCREEN.UNKNOWN_PRESET,
        desc = STRINGS.UI.CUSTOMIZATIONSCREEN.UNKNOWN_PRESET_DESC,
    }
    table.insert(self.presets, 1, self.preset)
    if not self.optionwidgets then
        self:MakeOptionSpinners()
    else
        self:RefreshOptions()
    end
end

function CustomizationTab:SavePreset()

    local function AddPreset(index, presetdata)
        local presetid = "CUSTOM_PRESET_"..index
        local presetname = STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOM_PRESET.." "..index
        local presetdesc = STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOM_PRESET_DESC.." "..index..". "..STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOMDESC

        -- Add the preset to the preset spinner and make the preset the selected one
        local base = self.presetspinner.spinner:GetSelectedIndex() <= #levels.sandbox_levels and self.presetspinner.spinner:GetSelected().data or self.presetspinner.spinner:GetSelected().basepreset
        local preset = {text=presetname, data=presetid, desc=presetdesc, overrides=presetdata, basepreset=base}
        self.presets[index + #levels.sandbox_levels] = preset
        self.presetspinner.spinner:SetOptions(self.presets)
        self.presetspinner.spinner:SetSelectedIndex(index + #levels.sandbox_levels)

        -- And save it to the profile
        Profile:AddWorldCustomizationPreset(preset, index)
        Profile:Save()

        -- We just created a new preset, so it can't be dirty
        self.current_option_settings.tweak = {} 
        self:MakePresetClean()
        if self.servercreationscreen then self.servercreationscreen:UpdateButtons(self.slot) end
    end

    -- Grab the current data
    -- First, the current preset's values
    local newoverrides = {}
    for i,override in ipairs(self.preset.overrides) do
        table.insert(newoverrides, {override[1], override[2]})
    end

    -- Then, the current tweaks
    for group,tweaks in pairs(self.current_option_settings.tweak) do
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
    if presetnum > self.max_num_presets then
        local spinner_options = {}
        for i=1,self.max_num_presets do
            table.insert(spinner_options, {text=tostring(i), data=i})
        end
        local overwrite_spinner = Spinner(spinner_options, 150, 64, nil, nil, nil, nil, true, nil, nil, .6, .7)
        overwrite_spinner:SetTextColour(0,0,0,1)
        overwrite_spinner:SetSelected("1")
        local size = JapaneseOnPS4() and 28 or 30
        local label = overwrite_spinner:AddChild( Text( NEWFONT, size, STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOM_PRESET ))
        local bg = overwrite_spinner:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
        bg:MoveToBack()
        bg:SetClickable(false)
        bg:SetScale(.75,.95)
        bg:SetPosition(-75,2)
        label:SetPosition( -180/2 - 25, 0, 0 )
        label:SetRegionSize( 180, 50 )
        label:SetColour(0,0,0,1)
        label:SetHAlign( ANCHOR_MIDDLE )
        local menuitems = 
        {
            {widget=overwrite_spinner, offset=Vector3(250,70,0)},
            {text=STRINGS.UI.CUSTOMIZATIONSCREEN.OVERWRITE, 
                cb = function() 
                    TheFrontEnd:PopScreen()
                    AddPreset(overwrite_spinner:GetSelectedIndex(), newoverrides)
                end, offset=Vector3(-90,0,0)},
            {text=STRINGS.UI.CUSTOMIZATIONSCREEN.CANCEL, 
                cb = function() 
                    TheFrontEnd:PopScreen() 
                end, offset=Vector3(-90,0,0)}  
        }
        local modal = PopupDialogScreen(STRINGS.UI.CUSTOMIZATIONSCREEN.MAX_PRESETS_EXCEEDED_TITLE, STRINGS.UI.CUSTOMIZATIONSCREEN.MAX_PRESETS_EXCEEDED_BODY..STRINGS.UI.CUSTOMIZATIONSCREEN.MAX_PRESETS_EXCEEDED_BODYSPACING, menuitems)
        modal.menu.items[1]:SetFocusChangeDir(MOVE_DOWN, modal.menu.items[2])
        modal.menu.items[1]:SetFocusChangeDir(MOVE_RIGHT, nil)
        modal.menu.items[2]:SetFocusChangeDir(MOVE_LEFT, nil)
        modal.menu.items[2]:SetFocusChangeDir(MOVE_RIGHT, modal.menu.items[3])
        modal.menu.items[2]:SetFocusChangeDir(MOVE_UP, modal.menu.items[1])
        modal.menu.items[3]:SetFocusChangeDir(MOVE_LEFT, modal.menu.items[2])
        modal.menu.items[3]:SetFocusChangeDir(MOVE_UP, modal.menu.items[1])

        modal.menu.items[2]:SetScale(.7)
        modal.menu.items[3]:SetScale(.7)
        modal.text:SetPosition(5, 10, 0)
        if self.servercreationscreen then self.servercreationscreen.last_focus = TheFrontEnd:GetFocusWidget() end
        TheFrontEnd:PushScreen(modal)
    else -- Otherwise, just save it
        AddPreset(presetnum, newoverrides)
    end
end

function CustomizationTab:MakeOptionSpinners()

    --these are in kind of a weird format, so convert it to something useful...
    self.overrides = {}
    for k,v in pairs(self.presets) do
        if self.preset.data == v.data then
            for k,v in pairs(v.overrides) do
                self.overrides[v[1]] = v[2]
            end
        end
    end

    if self.defaults and self.defaults.tweak then
        for k,v in pairs(self.defaults.tweak) do
            for m,n in pairs(v) do
                self.overrides[m] = n
            end
        end
    end

    self.optionwidgets = {}

    local function AddSpinnerToRow(self, v, index, row, side)
        local spin_options = {} --{{text="default"..tostring(idx), data="default"},{text="2", data="2"}, }
        for m,n in ipairs(v.options) do
            table.insert(spin_options, {text=n.text, data=n.data})
        end
        
        local opt = row:AddChild(Widget("option"))
        
        local bg = opt:AddChild(Image("images/ui.xml", "single_option_bg_large.tex"))
        bg:SetScale(.4,.65)
        bg:SetPosition(19,1)

        local image_parent = opt:AddChild(Widget("imageparent"))
        local image = image_parent:AddChild(Image(v.atlas or "images/customisation.xml", v.image))
        
        local imscale = .5
        image:SetScale(imscale,imscale,imscale)
        if TheInput:ControllerAttached() then
            opt:SetHoverText(STRINGS.UI.CUSTOMIZATIONSCREEN[string.upper(v.name)], { font = NEWFONT_OUTLINE, size = 22, offset_x = -85, offset_y = 47, colour = {1,1,1,1}})
        else
            image_parent:SetHoverText(STRINGS.UI.CUSTOMIZATIONSCREEN[string.upper(v.name)], { font = NEWFONT_OUTLINE, size = 22, offset_x = 0, offset_y = 47, colour = {1,1,1,1}})
        end

        local spin_height = 50
        local w = 235
        local spinner = opt:AddChild(Spinner( spin_options, w, spin_height, {font=NEWFONT, size=22}, nil, nil, nil, true, 200, nil, .765, 1.35))
        spinner.background:SetPosition(0,1)
        spinner.bg = bg
        spinner:SetTextColour(0,0,0,1)
        local default_value = self.overrides[v.name] or v.default
        opt.focus_forward = spinner
        
        spinner.OnChanged =
            function( _, data )
                local default_value = self.overrides[v.name] or v.default
                if data ~= default_value then 
                    if (self.allowEdit ~= false or FORCE_SHOW_BG_IN_VIEW_MODE) and data ~= v.default then
                        bg:SetTint(.15,.15,.15,1) --bg:SetTint(.3,.3,.3,1)
                    else
                        bg:SetTint(1,1,1,1)
                    end
                    if not self.current_option_settings.tweak[v.group] then
                        self.current_option_settings.tweak[v.group] = {}
                    end
                    self.current_option_settings.tweak[v.group][v.name] = data
                else
                    if data ~= v.default then
                        bg:SetTint(.15,.15,.15,1) --bg:SetTint(.3,.3,.3,1)
                    else
                        bg:SetTint(1,1,1,1)
                    end
                    if not self.current_option_settings.tweak[v.group] then
                        self.current_option_settings.tweak[v.group] = {}
                    end
                    self.current_option_settings.tweak[v.group][v.name] = nil
                    if not next(self.current_option_settings.tweak[v.group]) then
                        self.current_option_settings.tweak[v.group] = nil
                    end
                end
                self:MakePresetDirty()
                if self.servercreationscreen and self.servercreationscreen.UpdateButtons then 
                    self.servercreationscreen:UpdateButtons() 
                end
                self.servercreationscreen:MakeDirty()
            end
            
        if self.overrides[v.name] and self.overrides[v.name] ~= v.default then
            spinner:SetSelected(self.overrides[v.name])
            if self.allowEdit ~= false or FORCE_SHOW_BG_IN_VIEW_MODE then
                bg:SetTint(.15,.15,.15,1) --bg:SetTint(.3,.3,.3,1)
            end
        else
            spinner:SetSelected(default_value)
            bg:SetTint(1,1,1,1)
        end
        
        
        spinner:SetPosition(35,0,0 )
        image_parent:SetPosition(-85,0,0)
        local spacing = 75
        
        table.insert(self.spinners, spinner)
        if side == "left" then
            spinner.column = "left"
            spinner.OnGainFocus = function()
                Spinner._base.OnGainFocus(self)
                spinner:UpdateBG()
                self.focused_column = 1
            end
            row:AddItem(opt, 1, 1)
        elseif side == "right" then
            spinner.column = "right"
            spinner.OnGainFocus = function()
                Spinner._base.OnGainFocus(self)
                spinner:UpdateBG()
                self.focused_column = 2
            end
            row:AddItem(opt, 2, 1)
        end
        spinner.idx = #self.spinners

        if self.allowEdit == false then
            spinner:Disable()
            spinner:SetTextColour(0,0,0,1)
        end
    end

    local i = 1
    local lastgroup = nil
    while i <= #options do
        local rowWidget = Grid()
        rowWidget:SetLooping(false, false)
        rowWidget:InitSize(2, 1, 250, 0)
        rowWidget.SetFocus = function()
            local item = rowWidget:GetItemInSlot(self.focused_column, 1)
            if item then
                item:SetFocus()
            else
                item = rowWidget:GetItemInSlot(1, 1)
                if item then
                    item:SetFocus()
                end
            end
        end

        local v = options[i]

        if v.group ~= lastgroup then
            local labelParent = Widget("label")
            local labelWidget = labelParent:AddChild(Text(BUTTONFONT,37))
            labelWidget:SetHAlign(ANCHOR_MIDDLE)
            labelWidget:SetPosition(136, 0)
            labelWidget:SetString(v.grouplabel)
            labelWidget:SetColour(0,0,0,1)
            labelParent.focus_image = labelParent:AddChild(Image("images/ui.xml", "spinner_focus.tex"))
            labelParent.focus_image:SetPosition(133, 3)
            local w,h = labelWidget:GetRegionSize()
            labelParent.focus_image:SetSize(w+50, h+15)
            labelParent.OnGainFocus = function()
                labelParent.focus_image:Show()
            end
            labelParent.OnLoseFocus = function()
                labelParent.focus_image:Hide()
            end
            labelParent.focus_image:Hide()

            table.insert(self.optionwidgets, labelParent)
            lastgroup = v.group
        end

        AddSpinnerToRow(self, v, i, rowWidget, "left")


        if options[i+1] and options[i+1].group == lastgroup then
            local v = options[i+1]
            AddSpinnerToRow(self, v, i+1, rowWidget, "right")
            i = i + 2
        else
            i = i + 1
        end

        table.insert(self.optionwidgets, rowWidget)
    end

    self.current_option_settings_scroll_list = self.current_option_settingspanel:AddChild(ScrollableList(self.optionwidgets, 550, 400, 50, 20, nil, nil, 155))
    self.current_option_settings_scroll_list:SetPosition(-245,-24)
end

function CustomizationTab:RefreshOptions()
    --these are in kind of a weird format, so convert it to something useful...
    self.overrides = {}
    for k,v in pairs(self.presets) do
        if self.preset.data == v.data then
            for k,v in pairs(v.overrides) do
                self.overrides[v[1]] = v[2]
            end
        end
    end

    if not self.allowEdit then
        if self.defaults then
            if self.defaults.presetdata and self.defaults.presetdata.overrides then
                for i,override in ipairs(self.defaults.presetdata.overrides) do
                    self.overrides[override[1]] = override[2]
                end
            end
            if self.defaults.tweak then
                for k,v in pairs(self.defaults.tweak) do
                    for m,n in pairs(v) do
                        self.overrides[m] = n
                    end
                end
            end
        end
    end

    if SaveGameIndex:IsSlotEmpty(self.slot) then
        for i,v in ipairs(options) do 
            self:SetValueForOption(v.name, self:GetValueForOption(v.name)) 
        end
    else
        for i,v in ipairs(options) do 
            if self.overrides[v.name] then
                self:SetValueForOption(v.name, self.overrides[v.name])
            else
                self:SetValueForOption(v.name, v.default)
            end
        end
    end
end

function CustomizationTab:UpdateOptions(options, allowEdit)
    self.allowEdit = allowEdit

    self.defaults = options

    if options then
        self.current_option_settings = deepcopy(options)
        self.current_option_settings.tweak = self.current_option_settings.tweak or {}
        self.current_option_settings.preset = self.current_option_settings.preset or {}
    else
        self.current_option_settings = 
        { 
            preset = {},
            tweak = {}
        }
    end

    local preset = (self.defaults and (self.defaults.actualpreset or self.defaults.preset)) or self.presets[1].data

    self:LoadPreset(preset)

    if self.defaults and self.defaults.tweak and next(self.defaults.tweak) then
        self:MakePresetDirty()
    end

    local clean = true
    if self.current_option_settings and self.current_option_settings.tweak then
        for i,v in pairs(self.current_option_settings.tweak) do
            for m,n in pairs(v) do
                if #self.current_option_settings.tweak[i][m] > 0 then
                    clean = false
                    break
                end
            end
        end
        if clean then
            self:MakePresetClean()
        end
    end

    if self.allowEdit == false then
        -- Since we can't actually edit, act like the preset is clean but append "(Custom)" if it's not actually clean
        self:MakePresetClean()
        if not clean then
            for k,v in pairs(self.presets) do
                if self.preset.data == v.data then
                    self.presetdesc:SetString(STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOMDESC)
                    self.presetspinner.spinner:UpdateText(v.text .. " " .. STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOM)
                end
            end
        end
    end

    -- Enable or disable based on allowEdit
    if self.allowEdit then
        self.presetspinner.spinner:Enable()
    else
        self.presetspinner.spinner:Disable()
        self.presetspinner.spinner:SetTextColour(0,0,0,1)
    end

    for i,v in pairs(self.spinners) do
        if self.allowEdit then
            v:Enable()
        else
            v:Disable()
            v:SetTextColour(0,0,0,1)
        end
    end

    self:RefreshOptions()
end

function CustomizationTab:CollectOptions()
    -- Dump custom preset info into the tweak table because it's easier than rewriting the presets world gen code
    self.current_option_settings.presetdata = deepcopy(self.preset)
    self.current_option_settings.actualpreset = self.presetspinner.spinner:GetSelected().data
    self.current_option_settings.preset = self.presetspinner.spinner:GetSelected().basepreset

    return self.current_option_settings
end

function CustomizationTab:UpdateSlot(slotnum, prevslot, delete)
    if not delete and (slotnum == prevslot or not slotnum or not prevslot) then return end

    local editable = true   

    -- No save data
    if slotnum < 0 or SaveGameIndex:IsSlotEmpty(slotnum) then
        -- no slot, so hide all the details and set all the text boxes back to their defaults
        if prevslot and prevslot > 0 then
            -- Remember what was typed/set
            self.slotoptions[prevslot] = deepcopy(self.current_option_settings)
            -- Duplicate prevslot's data into our new slot if it was also a blank slot
            if SaveGameIndex:IsSlotEmpty(prevslot) then
                self.slotoptions[slotnum] = deepcopy(self.current_option_settings)
            end
        end
    else -- Save data
        if prevslot and prevslot > 0 then
            -- remember what was typed/set
            self.slotoptions[prevslot] = deepcopy(self.current_option_settings)
        end
        
            if slotnum > 0 and not SaveGameIndex:IsSlotEmpty(slotnum) then
            self.slotoptions[slotnum] = SaveGameIndex:GetSlotGenOptions(slotnum)
            editable = false
        end
    end

    self.slot = slotnum
    self:UpdateOptions(self.slotoptions[slotnum], editable)
end

function CustomizationTab:GetNumberOfTweaks()
    local numTweaks = 0
    if SaveGameIndex:IsSlotEmpty(self.slot) then
        if self.current_option_settings and self.current_option_settings.tweak then
            for i,v in pairs(self.current_option_settings.tweak) do
                if v then
                    for j,k in pairs(v) do
                        numTweaks = numTweaks + 1
                    end
                end
            end
            return numTweaks
        else
            return 0
        end
    else
        local function IsPresetOverride(name, value)
            local found  = false
            if self.defaults and self.defaults.presetdata and self.defaults.presetdata.overrides then
                for i,override in ipairs(self.defaults.presetdata.overrides) do
                    if (name == override[1] and value == override[2]) then
                        found = true
                        break
                    end
                end
            end
            return found
        end

        for i,v in pairs(self.overrides) do
            --#srosen HACK to prevent counting no-caves as a tweak until it's back in the customization options
            if i ~= "cave_entrance" then
                if not IsPresetOverride(i, v) then
                    numTweaks = numTweaks + 1
                end
            end
        end

        return numTweaks
    end
end

function CustomizationTab:GetPresetName()
    return self.presetspinner.spinner:GetSelectedText()
end

function CustomizationTab:RevertChanges()
    if self.servercreationscreen then self.servercreationscreen.last_focus = TheFrontEnd:GetFocusWidget() end
    TheFrontEnd:PushScreen(
        PopupDialogScreen( STRINGS.UI.CUSTOMIZATIONSCREEN.BACKTITLE, STRINGS.UI.CUSTOMIZATIONSCREEN.BACKBODY,
          { 
            { 
                text = STRINGS.UI.CUSTOMIZATIONSCREEN.YES, 
                cb = function()
                    if self.current_option_settings then
                        self.current_option_settings.tweak = {}
                    end
                    if self.slotoptions[self.slot] then
                        self.slotoptions[self.slot].tweak = {}
                    else
                        self.slotoptions[self.slot] = {}
                    end
                    self:UpdateOptions(self.current_option_settings, self.allowEdit)
                    if self.servercreationscreen and self.servercreationscreen.UpdateButtons then 
                        self.servercreationscreen:UpdateButtons() 
                    end
                    TheFrontEnd:PopScreen()
                end
            },
            
            { 
                text = STRINGS.UI.CUSTOMIZATIONSCREEN.NO, 
                cb = function()
                    TheFrontEnd:PopScreen()                 
                end
            }
          }
        )
    )       
end

function CustomizationTab:PendingChanges()
    if self.allowEdit == false then
        return false
    end

    if not self.defaults then
        return self.presetdirty or self.presetspinner.spinner:GetSelectedIndex() ~= 1
    end
    
    if self.defaults.preset ~= self.current_option_settings.preset then return true end

    local tables_to_compare = {}
    for k,v in pairs(self.current_option_settings.tweak) do
        tables_to_compare[k] = true
    end

    for k,v in pairs(self.defaults.tweak) do
        tables_to_compare[k] = true
    end

    for k,v in pairs(tables_to_compare) do
        local t1 = self.current_option_settings.tweak[k]
        local t2 = self.defaults.tweak[k]

        if not t1 or not t2 or not type(t1) == "table" or not type(t2) == "table" then return true end

        for k,v in pairs(t1) do
            if t2[k] ~= v then return true end
        end
        for k,v in pairs(t2) do
            if t1[k] ~= v then return true end
        end
    end
end 

function CustomizationTab:HookupFocusMoves()
    self.presetspinner:SetFocusChangeDir(MOVE_RIGHT, self.current_option_settings_scroll_list)
    self.current_option_settings_scroll_list:SetFocusChangeDir(MOVE_LEFT, self.presetspinner)
    self.presetspinner:SetFocusChangeDir(MOVE_DOWN, self.revertbutton)
    self.revertbutton:SetFocusChangeDir(MOVE_RIGHT, self.savepresetbutton)
    self.revertbutton:SetFocusChangeDir(MOVE_UP, self.presetspinner)
    self.savepresetbutton:SetFocusChangeDir(MOVE_LEFT, self.revertbutton)
    self.savepresetbutton:SetFocusChangeDir(MOVE_UP, self.presetspinner)
    self.savepresetbutton:SetFocusChangeDir(MOVE_RIGHT, self.current_option_settings_scroll_list)
    if self.servercreationscreen then 
        self.presetspinner:SetFocusChangeDir(MOVE_LEFT, self.servercreationscreen.save_slots[1]) 
        self.revertbutton:SetFocusChangeDir(MOVE_LEFT, self.servercreationscreen.save_slots[1])
    end
end

return CustomizationTab