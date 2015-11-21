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

local CustomizationList = Class(Widget, function(self, location, options, spinnerCB)
    Widget._ctor(self, "CustomizationList")

    self.location = location
    self.options = options
    self.allowEdit = true
    self.spinnerCB = spinnerCB
    self.presetvalues = {}

    self.spinners = {}

    self.focused_column = 1

    self:MakeOptionSpinners()

    self.default_focus = self.scroll_list
    self.focus_forward = self.scroll_list
end)

function CustomizationList:MakeOptionSpinners()

    self.optionwidgets = {}

    local function AddSpinnerToRow(self, v, index, row, side)
        local spin_options = {}
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

        local spinner_width = 170
        local spinner_height = nil -- default height
        local spinner = opt:AddChild(Spinner( spin_options, spinner_width, spinner_height, {font=NEWFONT, size=22}, nil, nil, nil, true))
        spinner.background:SetPosition(0,1)
        spinner.bg = bg
        spinner:SetTextColour(0,0,0,1)
        opt.focus_forward = spinner

        spinner.optionName = v.name -- stash this in here so we know which option a spinner belongs to
        spinner:SetSelected(v.default)

        spinner.OnChanged =
            function( _, data )
                if self.spinnerCB then
                    self.spinnerCB(spinner.optionName, data)
                end
                self:SetBGForSpinner(spinner)
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
    end

    local i = 1
    local lastgroup = nil
    while i <= #self.options do
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

        local v = self.options[i]

        if v.group ~= lastgroup then
            local labelParent = Widget("label")
            local labelWidget = labelParent:AddChild(Text(BUTTONFONT,37))
            labelWidget:SetHAlign(ANCHOR_MIDDLE)
            labelWidget:SetPosition(136, 0)
            labelWidget:SetString(string.format("%s %s",
                    STRINGS.UI.SANDBOXMENU.LOCATION[string.upper(self.location)] or STRINGS.UI.SANDBOXMENU.LOCATION.UNKNOWN,
                    v.grouplabel))
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


        if self.options[i+1] and self.options[i+1].group == lastgroup then
            local v = self.options[i+1]
            AddSpinnerToRow(self, v, i+1, rowWidget, "right")
            i = i + 2
        else
            i = i + 1
        end

        table.insert(self.optionwidgets, rowWidget)
    end

    self.scroll_list = self:AddChild(ScrollableList(self.optionwidgets, 550, 400, 50, 20, nil, nil, 155))
end

function CustomizationList:SetEditable(editable)
    self.allowEdit = editable


    for i,spinner in ipairs(self.spinners) do
        if self.allowEdit == false then
            spinner:Disable()
            spinner:SetTextColour(0,0,0,1)
        else
            spinner:Enable()
        end
    end
end

function CustomizationList:SetPresetValues(values)
    self.presetvalues = values
end

function CustomizationList:SetValueForOption(option, value)
    for idx,v in ipairs(self.options) do
        if (self.options[idx].name == option) then
            local spinner = self.spinners[idx]
            spinner:SetSelected(value)
            self:SetBGForSpinner(spinner)
        end
    end
end

function CustomizationList:SetBGForSpinner(spinner)
    local option = spinner.optionName
    local value = spinner:GetSelectedData()

    for idx,v in ipairs(self.options) do
        if (self.options[idx].name == option) then

            if value == v.default and self.presetvalues[v.name] == nil then
                spinner.bg:SetTint(1,1,1,1)
            elseif value == self.presetvalues[v.name] then
                spinner.bg:SetTint(.6,.6,.6,1)
            else
                spinner.bg:SetTint(.15,.15,.15,1)
            end
        end
    end
end

return CustomizationList
