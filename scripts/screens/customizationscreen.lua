local Screen = require "widgets/screen"
local AnimButton = require "widgets/animbutton"
local ImageButton = require "widgets/imagebutton"
local Spinner = require "widgets/spinner"
local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local HoverText = require "widgets/hoverer"


local NumericSpinner = require "widgets/numericspinner"

local PopupDialogScreen = require "screens/popupdialog"
local BigPopupDialogScreen = require "screens/bigpopupdialog"

local ScrollableList = require "widgets/scrollablelist"
local OnlineStatus = require "widgets/onlinestatus"

local levels = require "map/levels"
local customise = nil
local options = {}

local FORCE_SHOW_BG_IN_VIEW_MODE = true

local per_side = 7

local screen_fade_time = .25

local CustomizationScreen = Class(Screen, function(self, profile, cb, defaults, RoGEnabled, allowEdit)
    Widget._ctor(self, "CustomizationScreen")
	self.spinners = {}

    self.profile = profile
    self.defaults = defaults

    -- Disable all spinners and hide all backgrounds if we're in no-edit mode (but still update spinners to show what the world looks like)
    self.allowEdit = allowEdit

	self.cb = cb

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
	
    self.bg = self:AddChild(Image("images/bg_plain.xml", "bg.tex"))
    TintBackground(self.bg)

    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg:SetVAnchor(ANCHOR_MIDDLE)
    self.bg:SetHAnchor(ANCHOR_MIDDLE)
    self.bg:SetScaleMode(SCALEMODE_FILLSCREEN)
    
    self.root = self:AddChild(Widget("root"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.fg = self:AddChild(Image("images/fg_trees.xml", "trees.tex"))
    self.fg:SetVRegPoint(ANCHOR_MIDDLE)
    self.fg:SetHRegPoint(ANCHOR_MIDDLE)
    self.fg:SetVAnchor(ANCHOR_MIDDLE)
    self.fg:SetHAnchor(ANCHOR_MIDDLE)
    self.fg:SetScaleMode(SCALEMODE_FILLSCREEN)

    self.onlinestatus = self.fg:AddChild(OnlineStatus())
    self.onlinestatus:SetHAnchor(ANCHOR_RIGHT)
    self.onlinestatus:SetVAnchor(ANCHOR_BOTTOM)

    self.clickroot = self:AddChild(Widget("clickroot"))
    self.clickroot:SetVAnchor(ANCHOR_MIDDLE)
    self.clickroot:SetHAnchor(ANCHOR_MIDDLE)
    self.clickroot:SetScaleMode(SCALEMODE_PROPORTIONAL)
    
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
    
    self.presetpanel = self.clickroot:AddChild(Widget("presetpanel"))
    self.presetpanel:SetScale(.9)
    self.presetpanel:SetPosition(left_col+30,15,0)
    self.presetpanelbg = self.root:AddChild(Image("images/fepanels_dst.xml", "small_panel.tex"))
    self.presetpanelbg:SetScale(.9)
    self.presetpanelbg:SetPosition(left_col+30,15+18,0)
    self.presetpanelbg:SetScale(1, 1.2, 1)

    self.presettitle = self.presetpanel:AddChild(Text(BUTTONFONT, 50))
    self.presettitle:SetColour(0,0,0,1)
    self.presettitle:SetHAlign(ANCHOR_MIDDLE)
    self.presettitle:SetPosition(5, 105, 0)
	self.presettitle:SetRegionSize( 400, 70 )
    self.presettitle:SetString(STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETTITLE)

    self.presetdesc = self.presetpanel:AddChild(Text(BUTTONFONT, 35))
    self.presetdesc:SetColour(0,0,0,1)
    self.presetdesc:SetHAlign(ANCHOR_MIDDLE)
    self.presetdesc:SetPosition(0, -60, 0)
	self.presetdesc:SetRegionSize( 300, 130 )
    self.presetdesc:SetString(self.presets[1].desc)
    self.presetdesc:EnableWordWrap(true)

	local w = 300
	self.presetspinner = self.presetpanel:AddChild(Spinner( self.presets, w, 50, nil, nil, nil, nil, true, w - 30))
	self.presetspinner:SetPosition(0, 30, 0)
	self.presetspinner:SetTextColour(0,0,0,1)
	self.presetspinner.OnChanged =
		function( _, data )
		
			if self.presetdirty then
				TheFrontEnd:PushScreen(PopupDialogScreen(STRINGS.UI.CUSTOMIZATIONSCREEN.LOSECHANGESTITLE, STRINGS.UI.CUSTOMIZATIONSCREEN.LOSECHANGESBODY, 
					{{text=STRINGS.UI.CUSTOMIZATIONSCREEN.YES, cb = function() self.options.tweak = {} self:MakePresetClean() TheFrontEnd:PopScreen() end},
					{text=STRINGS.UI.CUSTOMIZATIONSCREEN.NO, cb = function() self:MakePresetDirty() TheFrontEnd:PopScreen() end}  }))
			else
				self:LoadPreset(data)
				self.options.tweak = {}				
			end
		end
	
	if self.allowEdit == false then
		self.presetspinner:Disable()
		self.presetspinner:SetTextColour(0,0,0,1)
	end
    
    --menu buttons
    self.optionspanel = self.clickroot:AddChild(Widget("optionspanel"))
    self.optionspanel:SetScale(.9)
    self.optionspanel:SetPosition(right_col,20,0)
    self.optionspanelbg = self.root:AddChild(Image("images/fepanels_dst.xml", "tall_panel.tex"))
    self.optionspanelbg:SetScale(1.3,.9)
    self.optionspanelbg:SetPosition(right_col,20,0)
    
    if not TheInput:ControllerAttached() then
    	self.savepresetbutton = self.optionspanel:AddChild(ImageButton())
	    self.savepresetbutton:SetPosition(10, -310, 0)
	    self.savepresetbutton:SetText(STRINGS.UI.CUSTOMIZATIONSCREEN.SAVEPRESET)
	    self.savepresetbutton:SetOnClick( function() self:SavePreset() end )
	    
	    self.cancelbutton = nil
	    if not self.allowEdit then
	    	self.cancelbutton = self.presetpanel:AddChild(ImageButton("images/ui.xml", "button_large.tex", "button_large_over.tex", "button_large_disabled.tex", "button_large_onclick.tex"))
		    self.cancelbutton:SetPosition(15, -263, 0)
		    self.cancelbutton.text:SetPosition(-3,0)
	    else
			self.cancelbutton = self.presetpanel:AddChild(ImageButton())
			self.cancelbutton:SetPosition(5, -260, 0)
		end
	    self.cancelbutton:SetText(STRINGS.UI.CUSTOMIZATIONSCREEN.BACK)
	    self.cancelbutton:SetOnClick( function() 
				if self:PendingChanges() then
					self:ConfirmRevert()
	    		else
	    			self:Cancel()
	    		end
	    	end )

    	if self.allowEdit then
			self.applybutton = self.presetpanel:AddChild(ImageButton("images/ui.xml", "button_large.tex", "button_large_over.tex", "button_large_disabled.tex", "button_large_onclick.tex"))
		    self.applybutton:SetPosition(120, -262, 0)
		    self.applybutton.text:SetPosition(-3,0)
		    self.applybutton:SetText(STRINGS.UI.CUSTOMIZATIONSCREEN.APPLY)
		    self.applybutton:SetOnClick( function() self:Apply() end )

		    self.cancelbutton:SetPosition(-85, -260)
		end
	end


	--add the custom options panel
	
	local preset = (self.defaults and self.defaults.preset) or self.presets[1].data

	self:LoadPreset(preset)

	if self.defaults and self.defaults.tweak and next(self.defaults.tweak) then
		self:MakePresetDirty()
	end

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
					self.presetspinner:UpdateText(v.text .. " " .. STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOM)
				end
			end
		end
	end

	self.hover = self:AddChild(HoverText(self))
	self.hover:SetScaleMode(SCALEMODE_PROPORTIONAL)
	self.hover.isFE = true


	self.default_focus = self.presetspinner
end)

function CustomizationScreen:SetValueForOption(option, value)
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
					bg:Show()
				else
					bg:Hide()
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
					bg:Show()
				else
					bg:Hide()
				end				
			end
		end
	end
end


function CustomizationScreen:GetValueForOption(option)
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
			local value = self.overrides[options[idx].name] or options[idx].default
			if self.options.tweak[options[idx].group] then
				local possiblevalue = self.options.tweak[options[idx].group][options[idx].name]
				value = possiblevalue or value
			end
			return value
		end
	end
	return nil
end


function CustomizationScreen:SetOptionEnabled(option, enabled,blacktext)
	local newEnabled = false
	local oldEnabled = false
	-- do we have a spinner for this guy?
 	for idx,v in ipairs(options) do
		if (options[idx].name == option) then
			local spinner = self.spinners[idx]
			oldEnabled = spinner.enabled
			if enabled then
				spinner:Enable()		
			else
				spinner:Disable()
				if blacktext then
					spinner:SetTextColour(0,0,0,1)
				end
			end
			newEnabled = spinner.enabled
		end
	end
	return newEnabled ~= oldEnabled
end

function CustomizationScreen:HookupFocusMoves()
	-- local GetFirstEnabledSpinnerAbove = function(k, tbl)
	-- 	for i=k-1,1,-1 do
	-- 		if tbl[i].enabled then
	-- 			return tbl[i]
	-- 		end
	-- 	end
	-- 	return nil
	-- end
	-- local GetFirstEnabledSpinnerBelow = function(k, tbl)
	-- 	for i=k+1,#tbl do
	-- 		if tbl[i].enabled then
	-- 			return tbl[i]
	-- 		end
	-- 	end
	-- 	return nil
	-- end

	-- for k = 1, #self.left_spinners do
	-- 	local abovespinner = GetFirstEnabledSpinnerAbove(k, self.left_spinners)
	-- 	if abovespinner then
	-- 		self.left_spinners[k]:SetFocusChangeDir(MOVE_UP, abovespinner)
	-- 	end
		
	-- 	self.left_spinners[k]:SetFocusChangeDir(MOVE_LEFT, self.presetspinner)

	-- 	local belowspinner = GetFirstEnabledSpinnerBelow(k, self.left_spinners)
	-- 	if belowspinner	then
	-- 		self.left_spinners[k]:SetFocusChangeDir(MOVE_DOWN, belowspinner)
	-- 	end

	-- 	if self.right_spinners[k] then
	-- 		self.left_spinners[k]:SetFocusChangeDir(MOVE_RIGHT, self.right_spinners[k])
	-- 	end

	-- end

	-- self.presetspinner:SetFocusChangeDir(MOVE_RIGHT, self.left_spinners[math.floor(#self.left_spinners/2)])


	-- for k = 1, #self.right_spinners do
	-- 	local abovespinner = GetFirstEnabledSpinnerAbove(k, self.right_spinners)
	-- 	if abovespinner then
	-- 		self.right_spinners[k]:SetFocusChangeDir(MOVE_UP, abovespinner)
	-- 	end

	-- 	local belowspinner = GetFirstEnabledSpinnerBelow(k, self.right_spinners)
	-- 	if belowspinner	then
	-- 		self.right_spinners[k]:SetFocusChangeDir(MOVE_DOWN,belowspinner)
	-- 	end

	-- 	if self.left_spinners[k] then
	-- 		self.right_spinners[k]:SetFocusChangeDir(MOVE_LEFT, self.left_spinners[k])
	-- 	end

	-- end
end

function CustomizationScreen:MakeOptionSpinners()

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
		
		local bg = opt:AddChild(Image("images/ui.xml", "nondefault_customization.tex"))
		bg:SetTint(.3,.3,.3,1)
		bg:SetScale(.85,1)
		bg:SetPosition(0,0)
		bg:Hide()
		local image = opt:AddChild(Image(v.atlas or "images/customisation.xml", v.image))
		
		local imscale = .5
		image:SetScale(imscale,imscale,imscale)
	    image:SetTooltip(v.name)

		
		
		local spin_height = 50
		local w = 220
		local spinner = opt:AddChild(Spinner( spin_options, w, spin_height, nil, nil, nil, nil, true, nil, nil, .78, .95))
		spinner.bg = bg
		spinner:SetTextColour(0,0,0,1)
		local default_value = self.overrides[v.name] or v.default
		
		spinner.OnChanged =
			function( _, data )
				local default_value = self.overrides[v.name] or v.default
				if data ~= default_value then 
					if (self.allowEdit ~= false or FORCE_SHOW_BG_IN_VIEW_MODE) and data ~= v.default then
						bg:Show()
					else
						bg:Hide()
					end
					if not self.options.tweak[v.group] then
						self.options.tweak[v.group] = {}
					end
					self.options.tweak[v.group][v.name] = data
				else
					if data ~= v.default then
						bg:Show()
					else
						bg:Hide()
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
				bg:Show()
			end
		else
			spinner:SetSelected(default_value)
			bg:Hide()
		end
		
		
		spinner:SetPosition(35,0,0 )
		image:SetPosition(-85,0,0)
		local spacing = 75
		
		if side == "left" then
			opt:SetPosition(-125, 0, 0)
			table.insert(self.spinners, spinner)
			spinner.column = "left"
			spinner.idx = #self.spinners
		elseif side == "right" then
			opt:SetPosition(135, 0, 0)
			table.insert(self.spinners, spinner)
			spinner.column = "right"
			spinner.idx = #self.spinners
		end

		if self.allowEdit == false then
			spinner:Disable()
			spinner:SetTextColour(0,0,0,1)
		end
	end

	local i = 1
    local lastgroup = nil
	while i <= #options do
		local rowWidget = Widget("row")

		local v = options[i]

        if v.group ~= lastgroup then
            local labelWidget = Text(BUTTONFONT,37)
            labelWidget:SetString(v.grouplabel)
            labelWidget:SetColour(0,0,0,1)
            table.insert(self.optionwidgets, labelWidget)
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

	self.options_scroll_list = self.optionspanel:AddChild(ScrollableList(self.optionwidgets, 270, 450, 50, 20))
	self.options_scroll_list:SetPosition(110,0)
end

function CustomizationScreen:RefreshOptions()

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
		if self.defaults and self.defaults.tweak then
			for k,v in pairs(self.defaults.tweak) do
				for m,n in pairs(v) do
					self.overrides[m] = n
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
	
	--hook up all of the focus moves
	self:HookupFocusMoves()

	-- if old_column and old_idx then
	-- 	local list = old_column == "right" and self.right_spinners or self.left_spinners
	-- 	if #list == 0 then
	-- 		if self.allowEdit ~= false then
	-- 			self.presetspinner:SetFocus()
	-- 		end
	-- 	else
	-- 		list[math.min(#list, old_idx)]:SetFocus()	
	-- 	end
		
	-- else
	-- 	if self.allowEdit ~= false then
	-- 		self.presetspinner:SetFocus()
	-- 	end
	-- end
	
end

function CustomizationScreen:MakePresetDirty()
	self.presetdirty = true
	
	for k,v in pairs(self.presets) do
		if self.preset.data == v.data then
			self.presetdesc:SetString(STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOMDESC)
			self.presetspinner:UpdateText(v.text .. " " .. STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOM)
		end
	end
end

function CustomizationScreen:MakePresetClean()
	self:LoadPreset(self.presetspinner:GetSelectedData())
end

function CustomizationScreen:LoadPreset(preset)
	for k,v in pairs(self.presets) do
		if preset == v.data then
			self.presetdesc:SetString(v.desc)
			self.presetspinner:SetSelectedIndex(k)
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
end

function CustomizationScreen:Cancel()
	self:Disable()
    TheFrontEnd:Fade(false, screen_fade_time, function()
    	self.cb()
        TheFrontEnd:PopScreen()
        TheFrontEnd:Fade(true, screen_fade_time)
    end)
end

function CustomizationScreen:OnControl(control, down)
    
    if CustomizationScreen._base.OnControl(self, control, down) then return true end
    if not down then
    	if control == CONTROL_CANCEL then 	
			if self:PendingChanges() then
				self:ConfirmRevert()
    		else
    			self:Cancel()
    		end
		elseif control == CONTROL_ACCEPT and (TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse) then
    		if self:PendingChanges() then
    			self:Apply()
    		end
    	elseif control == CONTROL_INSPECT then
    		self:SavePreset()
    		return false
    	end 

    	return true
    end

end

function CustomizationScreen:VerifyValidSeasonSettings()
	local autumn = self:GetValueForOption("autumn")
	local winter = self:GetValueForOption("winter")
	local spring = self:GetValueForOption("spring")
	local summer = self:GetValueForOption("summer")
	if autumn == "noseason" and winter == "noseason" and spring == "noseason" and summer == "noseason" then
		return false
	end
	return true
end

function CustomizationScreen:SavePreset()

	local function AddPreset(index, presetdata)
		local presetid = "CUSTOM_PRESET_"..index
		local presetname = STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOM_PRESET.." "..index
		local presetdesc = STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOM_PRESET_DESC.." "..index..". "..STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOMDESC

		-- Add the preset to the preset spinner and make the preset the selected one
		local base = self.presetspinner:GetSelectedIndex() <= #levels.sandbox_levels and self.presetspinner:GetSelected().data or self.presetspinner:GetSelected().basepreset
		local preset = {text=presetname, data=presetid, desc=presetdesc, overrides=presetdata, basepreset=base}
		self.presets[index + #levels.sandbox_levels] = preset
		self.presetspinner:SetOptions(self.presets)
		self.presetspinner:SetSelectedIndex(index + #levels.sandbox_levels)

		-- And save it to the profile
		Profile:AddWorldCustomizationPreset(preset, index)
		Profile:Save()

		-- We just created a new preset, so it can't be dirty
		self.options.tweak = {}	
		self:MakePresetClean()
	end

	-- Grab the data (values from current preset + tweaks)
	local presetoverrides = {}
	local overrides = {}
	for k,v in pairs(self.presets) do
		if self.preset.data == v.data then
			for m,n in pairs(v.overrides) do
				overrides[n[1]] = n[2]
				table.insert(presetoverrides, n)
			end
		end
	end
	for i,v in ipairs(options) do
		local value = overrides[options[i].name] or options[i].default
		value = (self.options.tweak[options[i].group] and self.options.tweak[options[i].group][options[i].name]) and self.options.tweak[options[i].group][options[i].name] or value

		local pos = nil
		for m,n in ipairs(presetoverrides) do
			if n[1] == options[i].name then
				pos = m
				break
			end
		end
		if not pos then
			table.insert(presetoverrides, {options[i].name, value})
		else
			presetoverrides[pos] = {options[i].name, value}
		end
	end

	if #presetoverrides <= 0 then return end

	-- Figure out what the id, name and description should be
	local presetnum = (Profile:GetWorldCustomizationPresets() and #Profile:GetWorldCustomizationPresets() or 0) + 1

	-- If we're at max num of presets, show a modal dialog asking which one to replace
	if presetnum > self.max_num_presets then
		local spinner_options = {}
		for i=1,self.max_num_presets do
			table.insert(spinner_options, {text=tostring(i), data=i})
		end
		local overwrite_spinner = Spinner(spinner_options, 150, nil, nil, nil, nil, nil, true)
		overwrite_spinner:SetTextColour(0,0,0,1)
		overwrite_spinner:SetSelected("1")
		local size = JapaneseOnPS4() and 28 or 30
		local label = overwrite_spinner:AddChild( Text( BUTTONFONT, size, STRINGS.UI.CUSTOMIZATIONSCREEN.CUSTOM_PRESET ))
		label:SetPosition( -180/2 - 10, 0, 0 )
		label:SetRegionSize( 180, 50 )
		label:SetColour(0,0,0,1)
		label:SetHAlign( ANCHOR_MIDDLE )
		local menuitems = 
	    {
			{widget=overwrite_spinner, offset=Vector3(280,120,0)},
			{text=STRINGS.UI.CUSTOMIZATIONSCREEN.OVERWRITE, 
				cb = function() 
					TheFrontEnd:PopScreen()
					AddPreset(overwrite_spinner:GetSelectedIndex(), presetoverrides)
				end, offset=Vector3(-90,0,0)},
			{text=STRINGS.UI.CUSTOMIZATIONSCREEN.CANCEL, 
				cb = function() 
					TheFrontEnd:PopScreen() 
				end, offset=Vector3(-90,0,0)}  
	    }
	    local modal = BigPopupDialogScreen(STRINGS.UI.CUSTOMIZATIONSCREEN.MAX_PRESETS_EXCEEDED_TITLE, STRINGS.UI.CUSTOMIZATIONSCREEN.MAX_PRESETS_EXCEEDED_BODY..STRINGS.UI.CUSTOMIZATIONSCREEN.MAX_PRESETS_EXCEEDED_BODYSPACING, menuitems)
	    modal.menu.items[1]:SetFocusChangeDir(MOVE_DOWN, modal.menu.items[2])
	    modal.menu.items[1]:SetFocusChangeDir(MOVE_RIGHT, nil)
	    modal.menu.items[2]:SetFocusChangeDir(MOVE_LEFT, nil)
	    modal.menu.items[2]:SetFocusChangeDir(MOVE_RIGHT, modal.menu.items[3])
	    modal.menu.items[2]:SetFocusChangeDir(MOVE_UP, modal.menu.items[1])
	    modal.menu.items[3]:SetFocusChangeDir(MOVE_LEFT, modal.menu.items[2])
	    modal.menu.items[3]:SetFocusChangeDir(MOVE_UP, modal.menu.items[1])
		TheFrontEnd:PushScreen(modal)
	else -- Otherwise, just save it
		AddPreset(presetnum, presetoverrides)
	end
end

function CustomizationScreen:Apply()

	local function collectCustomPresetOptions()
		-- Dump custom preset info into the tweak table because it's easier than rewriting the presets world gen code
		if self.presetspinner:GetSelectedIndex() > #levels.sandbox_levels then
			self.options.faketweak = {}
			local tweaked = false
			for i,v in pairs(self.presetspinner:GetSelected().overrides) do
				for k,j in pairs(self.options.tweak) do
					for m,n in pairs(j) do
						if v[1] == m then
							tweaked = true
							break
						end
					end
				end
				if not tweaked then
					local group = nil
					local name = nil
					for b,c in ipairs(options) do
						for d,f in pairs(c) do
							if c.name == v[1] then
								group = c.group
								name = c.name
								break
							end
						end
					end

					if group and name then
						if not self.options.tweak[group] then
							self.options.tweak[group] = {}
						end
						self.options.tweak[group][name] = v[2]
						table.insert(self.options.faketweak, v[1])
					end					
				end
				tweaked = false
			end

			self.options.actualpreset = self.presetspinner:GetSelected().data
			self.options.preset = self.presetspinner:GetSelected().basepreset
		end
	end

	if self:VerifyValidSeasonSettings() then
		collectCustomPresetOptions()
		self:Disable()
		TheFrontEnd:Fade(false, screen_fade_time, function()
			self.cb(self.options)
			TheFrontEnd:PopScreen()
			TheFrontEnd:Fade(true, screen_fade_time)
		end)
	else
		TheFrontEnd:PushScreen(PopupDialogScreen(STRINGS.UI.CUSTOMIZATIONSCREEN.INVALIDSEASONCOMBO_TITLE, STRINGS.UI.CUSTOMIZATIONSCREEN.INVALIDSEASONCOMBO_BODY, 
					{{text=STRINGS.UI.CUSTOMIZATIONSCREEN.OKAY, cb = function() TheFrontEnd:PopScreen() end}}))
	end
end

function CustomizationScreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}
    
	if self:PendingChanges() then
		table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. STRINGS.UI.HELP.ACCEPT)
	end

	if self.presetdirty then
		table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_INSPECT) .. " " .. STRINGS.UI.HELP.SAVEPRESET)
	end

	table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)
    

    return table.concat(t, "  ")
end


function CustomizationScreen:ConfirmRevert()

	TheFrontEnd:PushScreen(
		PopupDialogScreen( STRINGS.UI.CUSTOMIZATIONSCREEN.BACKTITLE, STRINGS.UI.CUSTOMIZATIONSCREEN.BACKBODY,
		  { 
		  	{ 
		  		text = STRINGS.UI.CUSTOMIZATIONSCREEN.YES, 
		  		cb = function()
					self:Disable()
				    TheFrontEnd:Fade(false, screen_fade_time, function()
				    	self.cb()
				        TheFrontEnd:PopScreen()
				        TheFrontEnd:PopScreen()
				        TheFrontEnd:Fade(true, screen_fade_time)
				    end)
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

function CustomizationScreen:PendingChanges()
	if self.allowEdit == false then
		return false
	end

	if not self.defaults then
		return self.presetdirty or self.presetspinner:GetSelectedIndex() ~= 1
	end
	
	if self.defaults.preset ~= self.options.preset then return true end

	local tables_to_compare = {}
	for k,v in pairs(self.options.tweak) do
		tables_to_compare[k] = true
	end

	for k,v in pairs(self.defaults.tweak) do
		tables_to_compare[k] = true
	end

	for k,v in pairs(tables_to_compare) do
		local t1 = self.options.tweak[k]
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

return CustomizationScreen
