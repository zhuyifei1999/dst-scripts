local Screen = require "widgets/screen"
local AnimButton = require "widgets/animbutton"
local ImageButton = require "widgets/imagebutton"
local Spinner = require "widgets/spinner"
local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local HoverText = require "widgets/hoverer"
local Grid = require "widgets/grid"
local TEMPLATES = require "widgets/templates"


local NumericSpinner = require "widgets/numericspinner"

local PopupDialogScreen = require "screens/popupdialog"

local ScrollableList = require "widgets/scrollablelist"
local OnlineStatus = require "widgets/onlinestatus"

local levels = require "map/levels"
local customise = nil
local options = {}

local FORCE_SHOW_BG_IN_VIEW_MODE = true

local per_side = 7

local ViewCustomizationModalScreen = Class(Screen, function(self, profile, defaults, RoGEnabled, allowEdit)
    Widget._ctor(self, "ViewCustomizationModalScreen")
	self.spinners = {}

    self.profile = profile
    self.defaults = defaults

    -- Disable all spinners and hide all backgrounds if we're in no-edit mode (but still update spinners to show what the world looks like)
    self.allowEdit = allowEdit

    self.focused_column = 1

	-- Build the options menu so that the spinners are shown in an order that makes sense/in order of how impactful the changes are
	if #options == 0 or self.RoGEnabled ~= RoGEnabled then
		self.RoGEnabled = RoGEnabled
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
	
	if defaults and self.RoGEnabled == RoGEnabled then
		self.options = deepcopy(defaults)
		self.options.tweak = self.options.tweak or {}
		self.options.preset = self.options.preset or {}
	else
		self.options = 
		{ 
			preset = {},
			tweak = {}
		}
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
    
    local left_col =-RESOLUTION_X*.25 - 50
    local right_col = RESOLUTION_X*.25 - 75

    	--set up the preset spinner

	self.max_num_presets = 5

	self.presets = {}

	for i, level in pairs(levels.sandbox_levels) do
		table.insert(self.presets, {text=level.name, data=level.id, desc = level.desc, overrides = level.overrides})
	end

    if self.defaults and self.defaults.presetdata then
    	print(dumptable(self.defaults.presetdata))
        table.insert(self.presets, 1, self.defaults.presetdata)
    end

    --menu buttons
    self.optionspanel = self.clickroot:AddChild(Widget("optionspanel"))
    self.optionspanel:SetPosition(0,20,0)

    self.optionspanelbg = self.root:AddChild(TEMPLATES.CurlyWindow(40, 365, 1, 1, 67, -41))
    self.optionspanelbg.fill = self.root:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tall.tex"))
	self.optionspanelbg.fill:SetScale(.64, -.57)
	self.optionspanelbg.fill:SetPosition(8, 12)
    self.optionspanelbg:SetPosition(0,0,0)
    
    if not TheInput:ControllerAttached() then
    	self.button = self.optionspanel:AddChild(ImageButton())
		self.button:SetText(STRINGS.UI.SERVERLISTINGSCREEN.OK)
    	self.button:SetOnClick(function() self:Cancel() end)
    	self.button:SetPosition(0,-257)
	end

	--add the custom options panel	
	local preset = (self.defaults and (self.defaults.actualpreset or self.defaults.preset)) or self.presets[1].data

	self:LoadPreset(preset)

	local clean = true
	if self.options and self.options.tweak then
		for i,v in pairs(self.options.tweak) do
			for m,n in pairs(v) do
				if #self.options.tweak[i][m] > 0 then
					clean = false
					break
				end
			end
		end
	end

	self.title = self.optionspanel:AddChild(Text(BUTTONFONT, 45, clean and self.preset.text or self.preset.text.." ".. STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOM, {0,0,0,1}))
	self.title:SetPosition(0,175)

	self.default_focus = self.options_scroll_list
end)

function ViewCustomizationModalScreen:SetValueForOption(option, value)
 	for idx,v in ipairs(options) do
		if (options[idx].name == option) then
			local spinner = self.spinners[idx]
			spinner:SetSelected(value)
		end
	end
	

	-- local overrides = {}
	-- for k,v in pairs(self.presets) do
	-- 	if self.preset == v.data then
	-- 		for k,v in pairs(v.overrides) do
	-- 			overrides[v[1]] = v[2]
	-- 		end
	-- 	end
	-- end

 	for idx,v in ipairs(options) do
		if (options[idx].name == option) then
			local default_value = self.overrides[options[idx].name] or options[idx].default
			if value ~= default_value then 
				if not self.options.tweak[options[idx].group] then
					self.options.tweak[options[idx].group] = {}
				end
				self.options.tweak[options[idx].group][options[idx].name] = value
				local bg = self.spinners[idx].bg
				if (self.allowEdit ~= false or FORCE_SHOW_BG_IN_VIEW_MODE) and value ~= options[idx].default then
					bg:SetTint(.15,.15,.15,1)
				else
					bg:SetTint(1,1,1,1)
				end
			else
				if not self.options.tweak[options[idx].group] then
					self.options.tweak[options[idx].group] = {}
				end
				self.options.tweak[options[idx].group][options[idx].name] = nil
				if not next(self.options.tweak[options[idx].group]) then
					self.options.tweak[options[idx].group] = nil
				end
				local bg = self.spinners[idx].bg
				if value ~= options[idx].default then
					bg:SetTint(.15,.15,.15,1)
				else
					bg:SetTint(1,1,1,1)
				end				
			end
		end
	end
end

function ViewCustomizationModalScreen:MakeOptionSpinners()

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
            image_parent:SetHoverText(STRINGS.UI.CUSTOMIZATIONSCREEN[string.upper(v.name)], { font = NEWFONT_OUTLINE, size = 22, offset_x = -85, offset_y = 47, colour = {1,1,1,1}})
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
						bg:SetTint(.15,.15,.15,1)
					else
						bg:SetTint(1,1,1,1)
					end
					if not self.options.tweak[v.group] then
						self.options.tweak[v.group] = {}
					end
					self.options.tweak[v.group][v.name] = data
				else
					if data ~= v.default then
						bg:SetTint(.15,.15,.15,1)
					else
						bg:SetTint(1,1,1,1)
					end
					if not self.options.tweak[v.group] then
						self.options.tweak[v.group] = {}
					end
					self.options.tweak[v.group][v.name] = nil
					if not next(self.options.tweak[v.group]) then
						self.options.tweak[v.group] = nil
					end
				end
				self:MakePresetDirty()
			end
			
		if self.overrides[v.name] and self.overrides[v.name] ~= v.default then
			spinner:SetSelected(self.overrides[v.name])
			if self.allowEdit ~= false or FORCE_SHOW_BG_IN_VIEW_MODE then
				bg:SetTint(.15,.15,.15,1)
			end
		else
			spinner:SetSelected(default_value)
			bg:SetTint(1,1,1,1)
		end
		
		
		spinner:SetPosition(35,0,0 )
		image:SetPosition(-85,0,0)
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

	self.options_scroll_list = self.optionspanel:AddChild(ScrollableList(self.optionwidgets, 540, 400, 50, 20, nil, nil, 135))
	self.options_scroll_list:SetPosition(-3,-40)
	self.options_scroll_list:SetScale(.85)
end

function ViewCustomizationModalScreen:RefreshOptions()

	local focus = self:GetDeepestFocus()
	local old_column = focus and focus.column
	local old_idx = focus and focus.idx
	
	
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

	for i,v in ipairs(options) do
		if self.overrides[v.name] then
			self:SetValueForOption(v.name, self.overrides[v.name])
		else
			self:SetValueForOption(v.name, v.default)
		end
	end	
end

function ViewCustomizationModalScreen:LoadPreset(preset)
	print(preset)
	for k,v in pairs(self.presets) do
		if preset == v.data then
			self.presetdirty = false
			self.preset = v
			self.options.preset = v.data
			if not self.optionwidgets then
				self:MakeOptionSpinners()
			else
				self:RefreshOptions()
			end
			return
		end
	end
	print("uunknown")

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

function ViewCustomizationModalScreen:LoadUnknownPreset()
    -- Populate a "fake" empty preset so that the screen still functions in case the loaded preset is missing.
    -- This is super gross, I know. I apologize. ~gjans
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
