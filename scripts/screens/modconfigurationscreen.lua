require "util"
require "strings"
local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local ImageButton = require "widgets/imagebutton"
local Menu = require "widgets/menu"
local Grid = require "widgets/grid"
local Text = require "widgets/text"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Spinner = require "widgets/spinner"
local NumericSpinner = require "widgets/numericspinner"
local Widget = require "widgets/widget"

local PopupDialogScreen = require "screens/popupdialog"

local ScrollableList = require "widgets/scrollablelist"

local text_font = UIFONT

local enableDisableOptions = { { text = STRINGS.UI.OPTIONS.DISABLED, data = false }, { text = STRINGS.UI.OPTIONS.ENABLED, data = true } }
local spinnerFont = { font = BUTTONFONT, size = 30 }

local COLS = 2
local ROWS_PER_COL = 7

local options = {}

local screen_fade_time = .25

local ModConfigurationScreen = Class(Screen, function(self, modname)
	Screen._ctor(self, "ModConfigurationScreen")
	self.modname = modname
	self.config = KnownModIndex:LoadModConfigurationOptions(modname)

	self.left_spinners = {}
	self.right_spinners = {}
	options = {}
	
	if self.config and type(self.config) == "table" then
		for i,v in ipairs(self.config) do
			-- Only show the option if it matches our format exactly
			if v.name and v.options and (v.saved ~= nil or v.default ~= nil) then
				local _value = v.saved
				if _value == nil then _value = v.default end
				table.insert(options, {name = v.name, label = v.label, options = v.options, default = v.default, value = _value, hover = v.hover})
			end
		end
	end
	print(#options)

	self.started_default = self:IsDefaultSettings()
	
	self.bg = self:AddChild(Image("images/bg_plain.xml", "bg.tex"))
    TintBackground(self.bg)
    
    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg:SetVAnchor(ANCHOR_MIDDLE)
    self.bg:SetHAnchor(ANCHOR_MIDDLE)
    self.bg:SetScaleMode(SCALEMODE_FILLSCREEN)

    self.shieldroot = self:AddChild(Widget("ROOT"))
    self.shieldroot:SetVAnchor(ANCHOR_MIDDLE)
    self.shieldroot:SetHAnchor(ANCHOR_MIDDLE)
    self.shieldroot:SetPosition(0,0,0)
    self.shieldroot:SetScaleMode(SCALEMODE_PROPORTIONAL)
    	
    local shield = self.shieldroot:AddChild( Image( "images/fepanels_dst.xml", "large_panel.tex" ) )
	shield:SetPosition( 0,0,0 )
	shield:SetSize( 1000, 700 )

	self.fg = self:AddChild(Image("images/fg_trees.xml", "trees.tex"))
	self.fg:SetVRegPoint(ANCHOR_MIDDLE)
    self.fg:SetHRegPoint(ANCHOR_MIDDLE)
    self.fg:SetVAnchor(ANCHOR_MIDDLE)
    self.fg:SetHAnchor(ANCHOR_MIDDLE)
    self.fg:SetScaleMode(SCALEMODE_FILLSCREEN)	

    self.root = self:AddChild(Widget("ROOT"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetPosition(0,0,0)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)	

	local titlestr = KnownModIndex:GetModFancyName(modname)
	local maxtitlelength = 26
	if titlestr:len() > maxtitlelength then
		titlestr = titlestr:sub(1, maxtitlelength)
	end
	titlestr = titlestr.." "..STRINGS.UI.MODSSCREEN.CONFIGSCREENTITLESUFFIX
	local title = self.root:AddChild( Text(BUTTONFONT, 50, titlestr) )
	title:SetPosition(0,210)
	title:SetColour(0,0,0,1)

	self.option_offset = 0
    self.optionspanel = self.root:AddChild(Widget("optionspanel"))	
    self.optionspanel:SetPosition(0,-20)

    if not TheInput:ControllerAttached() then
		self.menu = self.root:AddChild(Menu(nil, 0, false))
		self.cancelbutton = self.menu:AddItem(STRINGS.UI.MODSSCREEN.BACK, function() self:Cancel() end,  Vector3(-330, -290, 0))
		self.applybutton = self.menu:AddItem(STRINGS.UI.MODSSCREEN.APPLY, function() self:Apply() end, Vector3(-150, -293, 0), "large")
		self.resetbutton = self.menu:AddItem(STRINGS.UI.MODSSCREEN.RESETDEFAULT, function() self:ResetToDefaultValues() end,  Vector3(250, -290, 0))
		self.applybutton:SetScale(.9)
		self.cancelbutton:SetScale(.9)
		self.resetbutton:SetScale(.9)
		self.applybutton:SetFocusChangeDir(MOVE_LEFT, self.cancelbutton)
		self.cancelbutton:SetFocusChangeDir(MOVE_RIGHT, self.applybutton)
		self.applybutton:SetFocusChangeDir(MOVE_RIGHT, self.resetbutton)
		self.resetbutton:SetFocusChangeDir(MOVE_LEFT, self.applybutton)
		self.default_focus = self.applybutton
	end

	self.dirty = false

    self.optionwidgets = {}

	local i = 1
	local label_width = 180
	while i <= #options do
		if options[i] then
			local index = i
			local rowWidget = Widget("rowwidget")

			local spin_options = {} --{{text="default"..tostring(idx), data="default"},{text="2", data="2"}, }
			local spin_options_hover = {}
			for _,v in ipairs(options[index].options) do
				table.insert(spin_options, {text=v.description, data=v.data})
				spin_options_hover[v.data] = v.hover
			end
			
			rowWidget.opt = rowWidget:AddChild(Widget("option"))
			
			local spin_height = 50
			local w = 220
			rowWidget.spinner = rowWidget.opt:AddChild(Spinner( spin_options, w, spin_height, nil, nil, nil, nil, true))
			rowWidget.spinner:SetTextColour(0,0,0,1)
			local default_value = options[index].value
			if default_value == nil then default_value = options[index].default end
			
			rowWidget.spinner.OnChanged =
				function( _, data )
					options[index].value = data
					rowWidget.spinner:SetHoverText( spin_options_hover[data] or "" )
					self:MakeDirty()
				end
			rowWidget.spinner:SetSelected(default_value)
			rowWidget.spinner:SetHoverText( spin_options_hover[default_value] or "" )
			rowWidget.spinner:SetPosition( 35, 0, 0 )

			local label = rowWidget.spinner:AddChild( Text( BUTTONFONT, 30, (options[index].label or options[index].name) or STRINGS.UI.MODSSCREEN.UNKNOWN_MOD_CONFIG_SETTING ) )
			label:SetColour( 0, 0, 0, 1 )
			label:SetPosition( -label_width/2 - 105, 0, 0 )
			label:SetRegionSize( label_width, 50 )
			label:SetHAlign( ANCHOR_MIDDLE )
			label:SetHoverText( options[index].hover or "" )

			rowWidget.id = index

			rowWidget.opt:SetPosition( -155, 0, 0 )

			if options[i+1] then
				local index2 = i+1
				local spin_options = {} --{{text="default"..tostring(idx), data="default"},{text="2", data="2"}, }
				local spin_options_hover = {}
				for _,v in ipairs(options[index2].options) do
					table.insert(spin_options, {text=v.description, data=v.data})
					spin_options_hover[v.data] = v.hover
				end
				
				rowWidget.opt2 = rowWidget:AddChild(Widget("option"))
				
				local spin_height = 50
				local w = 220
				rowWidget.spinner2 = rowWidget.opt2:AddChild(Spinner( spin_options, w, spin_height, nil, nil, nil, nil, true))
				rowWidget.spinner2:SetTextColour( 0, 0, 0, 1 )
				local default_value = options[index2].value
				if default_value == nil then default_value = options[index2].default end
				
				rowWidget.spinner2.OnChanged =
					function( _, data )
						options[index2].value = data
						rowWidget.spinner2:SetHoverText( spin_options_hover[data] or "" )
						self:MakeDirty()
					end
				rowWidget.spinner2:SetSelected(default_value)
				rowWidget.spinner2:SetHoverText( spin_options_hover[default_value] or "" )
				rowWidget.spinner2:SetPosition( 35, 0, 0 )
				
				local label = rowWidget.spinner2:AddChild( Text( BUTTONFONT, 30, (options[index2].label or options[index2].name) or STRINGS.UI.MODSSCREEN.UNKNOWN_MOD_CONFIG_SETTING ) )
				label:SetColour(0,0,0,1)
				label:SetPosition( -label_width/2 - 105, 0, 0 )
				label:SetRegionSize( label_width, 50 )
				label:SetHAlign( ANCHOR_MIDDLE )
				label:SetHoverText( options[index2].hover or "" )

				rowWidget.id2 = index2

				rowWidget.opt2:SetPosition(265, 0, 0)
			end
			
			table.insert(self.optionwidgets, rowWidget)
			i = i + 2
		end
	end

	if TheInput:ControllerAttached() then
		self.default_focus = self.optionwidgets[1].spinner
	end

	self.options_scroll_list = self.optionspanel:AddChild(ScrollableList(self.optionwidgets, 415, 400, 40, 10))
	self.options_scroll_list:SetPosition(200, -15)
end)

function ModConfigurationScreen:CollectSettings()
	local settings = nil
	for i,v in pairs(options) do
		if not settings then settings = {} end
		table.insert(settings, {name=v.name, label = v.label, options=v.options, default=v.default, saved=v.value})
	end
	return settings
end

function ModConfigurationScreen:ResetToDefaultValues()
	local function reset()
		for i,v in pairs(self.optionwidgets) do
			if v.id then
				options[v.id].value = options[v.id].default
				v.spinner:SetSelected(options[v.id].value)
			end
			if v.id2 then
				options[v.id2].value = options[v.id2].default
				v.spinner2:SetSelected(options[v.id2].value)
			end
		end
	end

	if not self:IsDefaultSettings() then
		self:ConfirmRevert(function() 
			TheFrontEnd:PopScreen()
			self:MakeDirty()
			reset()
		end)
	end
end

function ModConfigurationScreen:Apply()
	if self:IsDirty() then
		local settings = self:CollectSettings()
		KnownModIndex:SaveConfigurationOptions(function() 
			self:MakeDirty(false)
			TheFrontEnd:Fade(false, screen_fade_time, function()
		        TheFrontEnd:PopScreen()
		        TheFrontEnd:Fade(true, screen_fade_time)
		    end)
		end, self.modname, settings)
	else
		self:MakeDirty(false)
		TheFrontEnd:Fade(false, screen_fade_time, function()
	        TheFrontEnd:PopScreen()
	        TheFrontEnd:Fade(true, screen_fade_time)
	    end)
	end
end

function ModConfigurationScreen:ConfirmRevert(callback)
	TheFrontEnd:PushScreen(
		PopupDialogScreen( STRINGS.UI.MODSSCREEN.BACKTITLE, STRINGS.UI.MODSSCREEN.BACKBODY,
		  { 
		  	{ 
		  		text = STRINGS.UI.MODSSCREEN.YES, 
		  		cb = callback or function() TheFrontEnd:PopScreen() end
			},
			{ 
				text = STRINGS.UI.MODSSCREEN.NO, 
				cb = function()
					TheFrontEnd:PopScreen()					
				end
			}
		  }
		)
	)		
end

function ModConfigurationScreen:Cancel()
	if self:IsDirty() and not (self.started_default and self:IsDefaultSettings()) then
		self:ConfirmRevert(function()
			self:MakeDirty(false)
			TheFrontEnd:Fade(false, screen_fade_time, function()
		        TheFrontEnd:PopScreen()
		        TheFrontEnd:PopScreen()
		        TheFrontEnd:Fade(true, screen_fade_time)
		    end)
		end)
	else
		self:MakeDirty(false)
		TheFrontEnd:Fade(false, screen_fade_time, function()
	        TheFrontEnd:PopScreen()
	        TheFrontEnd:Fade(true, screen_fade_time)
	    end)
	end
end

function ModConfigurationScreen:MakeDirty(dirty)
	if dirty ~= nil then
		self.dirty = dirty
	else
		self.dirty = true
	end
end

function ModConfigurationScreen:IsDefaultSettings()
	local alldefault = true
	for i,v in pairs(options) do
		-- print(options[i].value, options[i].default)
		if options[i].value ~= options[i].default then
			alldefault = false
			break
		end
	end
	return alldefault
end

function ModConfigurationScreen:IsDirty()
	return self.dirty
end

function ModConfigurationScreen:OnControl(control, down)
    if ModConfigurationScreen._base.OnControl(self, control, down) then return true end
    
    if not down then
	    if control == CONTROL_CANCEL then
			self:Cancel()
	    elseif control == CONTROL_ACCEPT and TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse then
	    	self:Apply() --apply changes and go back, or stay
    	elseif control == CONTROL_MAP and TheInput:ControllerAttached() then
			self:ResetToDefaultValues()
			return true
		else
    		return false
    	end 

    	return true
	end
end

function ModConfigurationScreen:HookupFocusMoves()
	local GetFirstEnabledSpinnerAbove = function(k, tbl)
		for i=k-1,1,-1 do
			if tbl[i] and tbl[i].enabled then
				return tbl[i]
			end
		end
		return nil
	end
	local GetFirstEnabledSpinnerBelow = function(k, tbl)
		for i=k+1,#tbl do
			if tbl[i] and tbl[i].enabled then
				return tbl[i]
			end
		end
		return nil
	end

	for k = 1, #self.left_spinners do
		local abovespinner = GetFirstEnabledSpinnerAbove(k, self.left_spinners)
		if abovespinner then
			self.left_spinners[k]:SetFocusChangeDir(MOVE_UP, abovespinner)
		end

		local belowspinner = GetFirstEnabledSpinnerBelow(k, self.left_spinners)
		if belowspinner	then
			self.left_spinners[k]:SetFocusChangeDir(MOVE_DOWN, belowspinner)
		else
			self.left_spinners[k]:SetFocusChangeDir(MOVE_DOWN, self.applybutton)
		end

		if self.right_spinners[k] then
			self.left_spinners[k]:SetFocusChangeDir(MOVE_RIGHT, self.right_spinners[k])
		end
	end

	for k = 1, #self.right_spinners do
		local abovespinner = GetFirstEnabledSpinnerAbove(k, self.right_spinners)
		if abovespinner then
			self.right_spinners[k]:SetFocusChangeDir(MOVE_UP, abovespinner)
		end

		local belowspinner = GetFirstEnabledSpinnerBelow(k, self.right_spinners)
		if belowspinner	then
			self.right_spinners[k]:SetFocusChangeDir(MOVE_DOWN,belowspinner)
		else
			self.right_spinners[k]:SetFocusChangeDir(MOVE_DOWN, self.resetbutton)
		end

		if self.left_spinners[k] then
			self.right_spinners[k]:SetFocusChangeDir(MOVE_LEFT, self.left_spinners[k])
		end
	end

	self.applybutton:SetFocusChangeDir(MOVE_UP, self.left_spinners[#self.left_spinners])
	self.cancelbutton:SetFocusChangeDir(MOVE_UP, self.left_spinners[#self.left_spinners])
	self.resetbutton:SetFocusChangeDir(MOVE_UP, self.right_spinners[#self.right_spinners])
end

function ModConfigurationScreen:GetHelpText()
	local t = {}
	local controller_id = TheInput:GetControllerID()

	table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MAP) .. " " .. STRINGS.UI.MODSSCREEN.RESETDEFAULT)
	if self:IsDirty() then
		table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. STRINGS.UI.HELP.APPLY)
	end
	table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)

	return table.concat(t, "  ")
end

return ModConfigurationScreen