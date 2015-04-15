require("constants")
local Screen = require "widgets/screen"
local AnimButton = require "widgets/animbutton"
local ImageButton = require "widgets/imagebutton"
local Spinner = require "widgets/spinner"
local NumericSpinner = require "widgets/numericspinner"
local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"


local PopupDialogScreen = require "screens/popupdialog"

local OnlineStatus = require "widgets/onlinestatus"

local ScrollableList = require "widgets/scrollablelist"

local controls_per_screen = 10
local controls_per_scroll = 5 -- why not == controls_per_screen you ask? some logical pairs (prev/next, up/down) get split accross screens, and this way you can scroll half a screen to see them both at the same time

local screen_fade_time = .25

local kbcontrols = {    
	--clicking
    CONTROL_PRIMARY,
    CONTROL_SECONDARY,
        
    --click modifiers
    CONTROL_FORCE_INSPECT,
    CONTROL_FORCE_ATTACK,
    
    --actions	
	CONTROL_ATTACK,
    CONTROL_ACTION,
    
    --walking
    CONTROL_MOVE_UP,
    CONTROL_MOVE_DOWN,
    CONTROL_MOVE_LEFT,
    CONTROL_MOVE_RIGHT,

    -- view controls
    CONTROL_ROTATE_LEFT,
    CONTROL_ROTATE_RIGHT,
    CONTROL_ZOOM_IN,
    CONTROL_ZOOM_OUT,
    CONTROL_MAP_ZOOM_IN,
    CONTROL_MAP_ZOOM_OUT,

    -- player movement controls
    CONTROL_PAUSE,
    CONTROL_MAP,

    --moals
    CONTROL_OPEN_CRAFTING,
    
    --inventory actions and modifiers
    CONTROL_INV_1,
    CONTROL_INV_2,
    CONTROL_INV_3,
    CONTROL_INV_4,
    CONTROL_INV_5,
    CONTROL_INV_6,
    CONTROL_INV_7,
    CONTROL_INV_8,
    CONTROL_INV_9,
    CONTROL_INV_10,

	CONTROL_INSPECT,
    CONTROL_SPLITSTACK,
    CONTROL_TRADEITEM,
    CONTROL_TRADESTACK,
    CONTROL_FORCE_TRADE,
    CONTROL_FORCE_STACK,

	--menu controls
    CONTROL_ACCEPT,
    CONTROL_CANCEL,

    CONTROL_SCROLLBACK,
    CONTROL_SCROLLFWD,

    CONTROL_PREVVALUE,
    CONTROL_NEXTVALUE,
    
	CONTROL_FOCUS_UP,
	CONTROL_FOCUS_DOWN,
	CONTROL_FOCUS_LEFT,
	CONTROL_FOCUS_RIGHT,

	--debugging
    CONTROL_OPEN_DEBUG_CONSOLE,
    CONTROL_TOGGLE_LOG,
    CONTROL_TOGGLE_DEBUGRENDER,
    
	--networking
	CONTROL_TOGGLE_SAY,
	CONTROL_TOGGLE_WHISPER,
    CONTROL_SHOW_PLAYER_STATUS,
}

local controllercontrols = {    
    --actions
    CONTROL_CONTROLLER_ACTION,
    CONTROL_CONTROLLER_ALTACTION,
    CONTROL_CONTROLLER_ATTACK,
    CONTROL_INSPECT,
    
    --walking
    CONTROL_MOVE_UP,
    CONTROL_MOVE_DOWN,
    CONTROL_MOVE_LEFT,
    CONTROL_MOVE_RIGHT,

    -- view controls
    CONTROL_ROTATE_LEFT,
    CONTROL_ROTATE_RIGHT,
    CONTROL_ZOOM_IN,
    CONTROL_ZOOM_OUT,
    CONTROL_MAP_ZOOM_IN,
    CONTROL_MAP_ZOOM_OUT,

    CONTROL_PAUSE,
    CONTROL_MAP,

	--in-game menu popups
	CONTROL_OPEN_CRAFTING,
	CONTROL_OPEN_INVENTORY,
	
    CONTROL_INVENTORY_UP,
    CONTROL_INVENTORY_DOWN,
	CONTROL_INVENTORY_LEFT,
	CONTROL_INVENTORY_RIGHT,
	
    CONTROL_INVENTORY_EXAMINE,
    CONTROL_INVENTORY_USEONSELF,
	CONTROL_INVENTORY_USEONSCENE,
	CONTROL_INVENTORY_DROP,
    CONTROL_PUTSTACK,
    CONTROL_USE_ITEM_ON_ITEM,

	--menu controls
    CONTROL_ACCEPT,
    CONTROL_CANCEL,

    CONTROL_SCROLLBACK,
    CONTROL_SCROLLFWD,
    CONTROL_PREVVALUE,
    CONTROL_NEXTVALUE,

	CONTROL_FOCUS_UP,
	CONTROL_FOCUS_DOWN,
	CONTROL_FOCUS_LEFT,
	CONTROL_FOCUS_RIGHT,

    CONTROL_MENU_MISC_1,
    CONTROL_MENU_MISC_2,
    CONTROL_MENU_MISC_3,
    CONTROL_MENU_MISC_4,
    CONTROL_TOGGLE_PLAYER_STATUS,
}

local ControlsScreen = Class(Screen, function(self, in_game)
    Widget._ctor(self, "ControlsScreen")
    self.in_game = in_game
    self.is_mapping = false
    
    TheInputProxy:StartMappingControls()
    
	self.options = 
	{ 
		preset = {},
		tweak = {}
	}
	
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
    self.scaleroot:SetPosition(0,0,0)
    self.scaleroot:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.root = self.scaleroot:AddChild(Widget("root"))
    self.root:SetScale(.9)


    local left_col =-RESOLUTION_X*.25 - 30
    local right_col = RESOLUTION_X*.25 - 30
    local btn_height = -280

	--set up the device spinner

    self.devices = TheInput:GetInputDevices()
        
    self.devicepanel = self.root:AddChild(Widget("devicepanel"))
    self.devicepanel:SetPosition(left_col,50,0)
    self.devicepanelbg = self.devicepanel:AddChild(Image("images/fepanels_dst.xml", "small_panel.tex"))

    self.control_offset = 0
    self.controlspanel = self.root:AddChild(Widget("controlspanel"))
    self.controlspanel:SetPosition(right_col,30,0)
    self.controlspanelbg = self.controlspanel:AddChild(Image("images/fepanels_dst.xml", "tall_panel.tex"))

    self.fg = self.root:AddChild(Image("images/fg_trees.xml", "trees.tex"))
    self.fg:SetVRegPoint(ANCHOR_MIDDLE)
    self.fg:SetHRegPoint(ANCHOR_MIDDLE)
    self.fg:SetVAnchor(ANCHOR_MIDDLE)
    self.fg:SetHAnchor(ANCHOR_MIDDLE)
    self.fg:SetScaleMode(SCALEMODE_FILLSCREEN)

    self.onlinestatus = self.root:AddChild(OnlineStatus())
    self.onlinestatus:SetHAnchor(ANCHOR_RIGHT)
    self.onlinestatus:SetVAnchor(ANCHOR_BOTTOM)

    self.applybutton = self.root:AddChild(ImageButton("images/ui.xml", "button_large.tex", "button_large_over.tex", "button_large_disabled.tex", "button_large_onclick.tex"))
    self.applybutton:SetPosition(left_col+110, btn_height-2, 0)
    self.applybutton:SetText(STRINGS.UI.CONTROLSSCREEN.APPLY)
    self.applybutton.text:SetColour(0,0,0,1)
    self.applybutton.text:SetPosition(-3,0)
    self.applybutton:SetOnClick( function() self:Apply() end )
    self.applybutton:SetFont(BUTTONFONT)
    self.applybutton:SetTextSize(40)    
    self.applybutton:Disable()
    
    self.cancelbutton = self.root:AddChild(ImageButton())
    self.cancelbutton:SetPosition(left_col-100, btn_height, 0)
    self.cancelbutton:SetText(STRINGS.UI.CONTROLSSCREEN.BACK)
    self.cancelbutton.text:SetColour(0,0,0,1)
    self.cancelbutton:SetOnClick( function() self:Cancel() end )
    self.cancelbutton:SetFont(BUTTONFONT)
    self.cancelbutton:SetTextSize(40)

    self.deviceroot = self.root:AddChild(Widget("deviceroot"))
    self.controlroot = self.root:AddChild(Widget("controlroot"))
    self.deviceroot:SetPosition(left_col,50,0)
    self.controlroot:SetPosition(right_col,30,0)

    self.devicetitle = self.deviceroot:AddChild(Text(BUTTONFONT, 50))
    self.devicetitle:SetHAlign(ANCHOR_MIDDLE)
    self.devicetitle:SetPosition(0, 65, 0)
	self.devicetitle:SetRegionSize( 400, 70 )
	self.devicetitle:SetColour(0,0,0,1)
    self.devicetitle:SetString(STRINGS.UI.CONTROLSSCREEN.DEVICE_TITLE)

	self.devicespinner = self.deviceroot:AddChild(Spinner(self.devices, 300, nil, nil, nil, nil, nil, true, 250))
	self.devicespinner:SetPosition(-5, 10, 0)
	self.devicespinner:SetTextColour(0,0,0,1)
	self.devicespinner.OnChanged =
		function( _, data )
            self:RefreshControls()
		end

    local enableDisableOptions = { { text = STRINGS.UI.OPTIONS.DISABLED, data = false }, { text = STRINGS.UI.OPTIONS.ENABLED, data = true } }
    self.enablespinner = self.deviceroot:AddChild( Spinner( enableDisableOptions, nil, nil, nil, nil, nil, nil, true ))
    self.enablespinner:SetPosition(0,-60,0)
    self.enablespinner:SetTextColour(0,0,0,1)
    self.enablespinner.OnChanged =
        function( _, data )
            TheInputProxy:EnableInputDevice(self.devicespinner:GetSelectedData(), data)
            self:RefreshControls()
            self:MakeDirty()
            self.enablespinner:SetFocus()
        end   
    self.enablespinner:Hide()     
	
	--add the controls panel	
	
    self.inputhandlers = {}
    table.insert(self.inputhandlers, TheInput:AddControlMappingHandler(
        function(deviceId, controlId, inputId, hasChanged)  
            self:OnControlMapped(deviceId, controlId, inputId, hasChanged)
        end
    ))

    self.resetbutton = self.root:AddChild(ImageButton())
    self.resetbutton:SetPosition(right_col + 10, btn_height, 0)
    self.resetbutton:SetText(STRINGS.UI.CONTROLSSCREEN.RESET)
    self.resetbutton.text:SetColour(0,0,0,1)
    self.resetbutton:SetOnClick( function()         	TheFrontEnd:PushScreen(PopupDialogScreen( STRINGS.UI.CONTROLSSCREEN.RESETTITLE, STRINGS.UI.CONTROLSSCREEN.RESETBODY,
		{ 
		  	{ 
		  		text = STRINGS.UI.CONTROLSSCREEN.YES, 
		  		cb = function()
		  			self:LoadDefaultControls() 
					TheFrontEnd:PopScreen()
				end
			},
			{ 
				text = STRINGS.UI.CONTROLSSCREEN.NO, 
				cb = function()
					TheFrontEnd:PopScreen()					
				end
			}
		}))
    end )
    self.resetbutton:SetFont(BUTTONFONT)
    self.resetbutton:SetTextSize(40)

    if TheInput:ControllerAttached() then
        self.applybutton:Hide()
        self.cancelbutton:Hide()
        self.resetbutton:Hide()
    end

    local deviceId = self.devicespinner:GetSelectedData()
    local enabled = true
    if deviceId ~= 0 then
        enabled = TheInputProxy:IsInputDeviceEnabled(deviceId)
        self.enablespinner:Show()
        self.enablespinner:SetSelectedIndex( enabled and 2 or 1)
    else
        self.enablespinner:Hide()
    end

	self.kbcontrolwidgets = {}
	for i,v in ipairs(kbcontrols) do
		local group = Widget("kbcontrol"..i)
		group:SetScale(0.75,0.75,0.75)

		group.controlId = kbcontrols[i]
		
		group.bg = group:AddChild(Image("images/ui.xml", "nondefault_customization.tex"))
		group.bg:SetTint(unpack(BGCOLOURS.GREY))
		group.bg:SetPosition(180,0,0)
		group.bg:SetScale(1, 0.95, 1)
		local hasChanged = TheInputProxy:HasMappingChanged(self.devicespinner:GetSelectedData(), group.controlId)
		if hasChanged then
		    group.bg:Show()
		else
		    group.bg:Hide()
		end
		
		group.button = group:AddChild(ImageButton("images/ui.xml", "button_long.tex", "button_long_over.tex", "button_long_disabled.tex"))
        group.button:SetText(STRINGS.UI.CONTROLSSCREEN.CONTROLS[group.controlId+1])
        group.button.text:SetColour(0,0,0,1)
        group.button:SetFont(BUTTONFONT)
        group.button:SetTextSize(30)  
		group.button:SetPosition(-25,0,0)
		group.button.idx = i
		--button:SetScale(1.25, 1, 1)
        group.button:SetOnClick( 
            function() 
                self:MapControl(self.devicespinner:GetSelectedData(), group.controlId)
            end 
        )
        if enabled then
            group.button:Enable()
        else
            group.button:Disable()
        end    
        group.button:SetHelpTextMessage(STRINGS.UI.CONTROLSSCREEN.CHANGEBIND)
        
        group.text = group:AddChild(Text(BUTTONFONT, 40))
        local ctrlString = TheInput:GetLocalizedControl(self.devicespinner:GetSelectedData(), group.controlId)
        group.text:SetString(ctrlString)
        if TheInput:GetStringIsButtonImage(ctrlString) then
            group.text:SetColour(1,1,1,1)
            group.text:SetFont(UIFONT)
        else
            group.text:SetColour(0,0,0,1)
            group.text:SetFont(BUTTONFONT)
        end
        group.text:SetHAlign(ANCHOR_LEFT)
        group.text:SetRegionSize( 500, 50 )
		group.text:SetPosition(355,0,0)
        group.text:SetClickable(false)

        group.focus_forward = group.button

		table.insert(self.kbcontrolwidgets, group)
	end

	self.controllercontrolwidgets = {}
    for i,v in ipairs(controllercontrols) do
        local group = Widget("control"..i)
        group:SetScale(0.75,0.75,0.75)

        group.controlId = controllercontrols[i]
        
        group.bg = group:AddChild(Image("images/ui.xml", "nondefault_customization.tex"))
        group.bg:SetTint(unpack(BGCOLOURS.GREY))
        group.bg:SetPosition(180,0,0)
        group.bg:SetScale(1, 0.95, 1)
        local hasChanged = TheInputProxy:HasMappingChanged(self.devicespinner:GetSelectedData(), group.controlId)
        if hasChanged then
            group.bg:Show()
        else
            group.bg:Hide()
        end
        
        group.button = group:AddChild(ImageButton("images/ui.xml", "button_long.tex", "button_long_over.tex", "button_long_disabled.tex"))
        group.button:SetText(STRINGS.UI.CONTROLSSCREEN.CONTROLS[group.controlId+1])
        group.button.text:SetColour(0,0,0,1)
        group.button:SetFont(BUTTONFONT)
        group.button:SetTextSize(30)  
        group.button:SetPosition(-25,0,0)
        group.button.idx = i
        --button:SetScale(1.25, 1, 1)
        group.button:SetOnClick( 
            function() 
                self:MapControl(self.devicespinner:GetSelectedData(), group.controlId)
            end 
        )
        if enabled then
            group.button:Enable()
        else
            group.button:Disable()
        end
        group.button:SetHelpTextMessage(STRINGS.UI.CONTROLSSCREEN.CHANGEBIND)
        
        group.text = group:AddChild(Text(UIFONT, 40))
        local ctrlString = TheInput:GetLocalizedControl(self.devicespinner:GetSelectedData(), group.controlId)
        group.text:SetString(ctrlString)
        if TheInput:GetStringIsButtonImage(ctrlString) then
            group.text:SetColour(1,1,1,1)
            group.text:SetFont(UIFONT)
        else
            group.text:SetColour(0,0,0,1)
            group.text:SetFont(BUTTONFONT)
        end
        group.text:SetHAlign(ANCHOR_LEFT)
        group.text:SetRegionSize( 500, 50 )
        group.text:SetPosition(355,0,0)
        group.text:SetClickable(false)

        group.focus_forward = group.button

        table.insert(self.controllercontrolwidgets, group)
    end

	self.kbcontrollist = self.controlroot:AddChild(ScrollableList(self.kbcontrolwidgets, 250, 500))
	self.kbcontrollist:SetPosition(40, 2)

    self.controllercontrollist = self.controlroot:AddChild(ScrollableList(self.controllercontrolwidgets, 250, 500))
    self.controllercontrollist:SetPosition(40, 2)

	self:LoadCurrentControls()
	self.devicespinner:SetFocus()
	self.default_focus = self.devicespinner
end)

function ControlsScreen:RefreshControls()
	
	local focus = self:GetDeepestFocus()
	local old_idx = focus and focus.idx

	local deviceId = self.devicespinner:GetSelectedData()
    --print("Current device is [" .. deviceId .. "]")

    local enabled = true
    if deviceId ~= 0 then
        enabled = TheInputProxy:IsInputDeviceEnabled(deviceId)
        self.enablespinner:Show()
        self.enablespinner:SetSelectedIndex( enabled and 2 or 1)
    else
        self.enablespinner:Hide()
    end

    if TheInput:ControllerAttached() then
        self.applybutton:Hide()
        self.cancelbutton:Hide()
        self.resetbutton:Hide()
    else
        self.applybutton:Show()
        self.cancelbutton:Show()
        self.resetbutton:Show()
    end

	if self.controltype ~= self.devicespinner:GetSelectedData() then
		self.controltype = self.devicespinner:GetSelectedData()
		if self.controltype == 0 then
			self.kbcontrollist:Show()
            self.controllercontrollist:Hide()
			self.activecontrollist = self.kbcontrollist
		else
            self.controllercontrollist:Show()
            self.kbcontrollist:Hide()
			self.activecontrollist = self.controllercontrollist
		end
	end

	for i,v in pairs(self.activecontrollist.items) do
		local hasChanged = TheInputProxy:HasMappingChanged(deviceId, v.controlId)
		if hasChanged then
		    v.bg:Show()
		else
		    v.bg:Hide()
		end
		if enabled then
            v.button:Enable()
        else
            v.button:Disable()
        end
        local ctrlString = TheInput:GetLocalizedControl(deviceId, v.controlId)
        v.text:SetString(ctrlString)
        if TheInput:GetStringIsButtonImage(ctrlString) then
            v.text:SetColour(1,1,1,1)
            v.text:SetFont(UIFONT)
        else
            v.text:SetColour(0,0,0,1)
            v.text:SetFont(BUTTONFONT)
        end
	end

	self:RefreshNav()

	if old_idx then
		self.activecontrollist.items[math.min(#self.activecontrollist.items, old_idx)].button:SetFocus()
	end
end

function ControlsScreen:OnDestroy()
	--print("whatsthis")
    --itsgoodstuff

    TheInputProxy:StopMappingControls()
    
    for k,v in pairs(self.inputhandlers) do
        v:Remove()
    end
	self._base.OnDestroy(self)
end

function ControlsScreen:MakeDirty()
	if self.applybutton.shown then self.applybutton:Enable() end
    if self.cancelbutton.shown then self.cancelbutton:SetText(STRINGS.UI.CONTROLSSCREEN.BACK) end
    self.dirty = true
    self:RefreshNav()
end

function ControlsScreen:MakeClean()
	if self.applybutton.shown then self.applybutton:Disable()	end
    if self.cancelbutton.shown then self.cancelbutton:SetText(STRINGS.UI.CONTROLSSCREEN.BACK) end
    self.dirty = false
    self:RefreshNav()
end

function ControlsScreen:IsDirty()
    return self.dirty
end

function ControlsScreen:OnUpdate()
    if (TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse) then
        for i,v in pairs(self.controllercontrolwidgets) do
            if v and v.button then
                v.button:SetControl(CONTROL_MENU_MISC_1)
            end
        end
        for i,v in pairs(self.kbcontrolwidgets) do
            if v and v.button then
                v.button:SetControl(CONTROL_MENU_MISC_1)
            end
        end
    else
        for i,v in pairs(self.controllercontrolwidgets) do
            if v and v.button then
                v.button:SetControl(CONTROL_ACCEPT)
            end
        end
        for i,v in pairs(self.kbcontrolwidgets) do
            if v and v.button then
                v.button:SetControl(CONTROL_ACCEPT)
            end
        end
    end
end

function ControlsScreen:RefreshNav()
	
	self.enablespinner:SetFocusChangeDir(MOVE_UP, self.devicespinner)
    if self.enablespinner.shown then
        self.devicespinner:SetFocusChangeDir(MOVE_DOWN, self.enablespinner)
        if self.applybutton.shown and self.applybutton.enabled then 
            self.applybutton:SetFocusChangeDir(MOVE_UP, self.enablespinner) 
            self.applybutton:SetFocusChangeDir(MOVE_LEFT, self.cancelbutton) 
            self.enablespinner:SetFocusChangeDir(MOVE_DOWN, self.applybutton)
        else
            self.enablespinner:SetFocusChangeDir(MOVE_DOWN, self.cancelbutton)
        end
        if self.cancelbutton.shown then self.cancelbutton:SetFocusChangeDir(MOVE_UP, self.enablespinner) end
    elseif self.applybutton.shown and self.applybutton.enabled then
        self.devicespinner:SetFocusChangeDir(MOVE_DOWN, self.applybutton)
        self.applybutton:SetFocusChangeDir(MOVE_RIGHT, self.activecontrollist)
    elseif self.cancelbutton.shown then
        self.devicespinner:SetFocusChangeDir(MOVE_DOWN, self.cancelbutton)
        if self.applybutton.shown and self.applybutton.enabled then
            self.cancelbutton:SetFocusChangeDir(MOVE_RIGHT, self.applybutton)
        else
            self.cancelbutton:SetFocusChangeDir(MOVE_RIGHT, self.activecontrollist)
        end
    else
        self.devicespinner:SetFocusChangeDir(MOVE_DOWN, nil)
    end

    if not self.enablespinner.shown then
        if self.cancelbutton.shown then self.cancelbutton:SetFocusChangeDir(MOVE_UP, self.devicespinner) end
        if self.applybutton.shown then self.applybutton:SetFocusChangeDir(MOVE_UP, self.devicespinner) end
    end

    if self.applybutton.shown and self.applybutton.enabled then
        if self.cancelbutton.shown then self.cancelbutton:SetFocusChangeDir(MOVE_RIGHT, self.applybutton) end
        self.applybutton:SetFocusChangeDir(MOVE_LEFT, self.cancelbutton)
    end

    
    local targets = {self.devicespinner}--{self.cancelbutton, self.resetbutton, self.devicespinner}
    if self.enablespinner and self.enablespinner.shown then
        table.insert(targets, self.enablespinner)
    end

    
    local function toleftcol()
        -- local current = TheFrontEnd:GetFocusWidget()
        -- if not current then return self.cancelbutton end
        
        -- local pt = current:GetWorldPosition()
        -- local closest = nil
        -- local closest_dist = nil
        -- for k,v in pairs(targets) do
        --  local dist = v:GetWorldPosition():DistSq(pt)
        --  if not closest or dist < closest_dist then
        --      closest = v
        --      closest_dist = dist
        --  end
        -- end
        
        -- return closest
        return targets[1]
    end

	local function torightcol()
		-- local current = TheFrontEnd:GetFocusWidget()
		-- if not current then return self.activecontrollist.items[1].button end
		
		-- local pt = current:GetWorldPosition()
		-- local top = nil
		-- for k,v in ipairs(self.activecontrollist.items) do
		-- 	if not top and v.shown then
		-- 		top = v
  --               break
		-- 	end
		-- end
		-- return top
        return self.activecontrollist
	end
	
	for k,v in pairs(targets) do
		v:SetFocusChangeDir(MOVE_RIGHT, torightcol)
	end

    if self.activecontrollist and self.activecontrollist.items then
    	for k,v in pairs(self.activecontrollist.items) do
    		v.button:SetFocusChangeDir(MOVE_LEFT, toleftcol)
    	end
    end
	
end

function ControlsScreen:LoadDefaultControls()
	TheInputProxy:LoadDefaultControlMapping()
	self:MakeDirty()
	self:RefreshControls()	
end

function ControlsScreen:LoadCurrentControls()
	TheInputProxy:LoadCurrentControlMapping()
	self:MakeClean()
    self:RefreshControls()	
end

function ControlsScreen:MapControl(deviceId, controlId)
    --print("Mapping control [" .. controlIndex .. "] on device [" .. deviceId .. "]")
    local controlIndex = controlId + 1      -- C++ control id is zero-based, we were passed a 1-based (lua) array index
    local loc_text = TheInput:GetLocalizedControl(deviceId, controlId, true)
    local default_text = string.format(STRINGS.UI.CONTROLSSCREEN.DEFAULT_CONTROL_TEXT, loc_text)
    local body_text = STRINGS.UI.CONTROLSSCREEN.CONTROL_SELECT .. "\n\n" .. default_text
    local popup = PopupDialogScreen(STRINGS.UI.CONTROLSSCREEN.CONTROLS[controlIndex], body_text, {})
    popup.text:SetRegionSize(480, 150)
    popup.text:SetPosition(0, -25, 0)    
    if TheInput:GetStringIsButtonImage(loc_text) then
        popup.text:SetColour(1,1,1,1)
        popup.text:SetFont(UIFONT)
    else
        popup.text:SetColour(0,0,0,1)
        popup.text:SetFont(BUTTONFONT)
    end
        
    popup.OnControl = function(_, control, down) self:MapControlInputHandler(control, down) end
	TheFrontEnd:PushScreen(popup)
	
    TheInputProxy:MapControl(deviceId, controlId)
    self.is_mapping = true
end

function ControlsScreen:OnControlMapped(deviceId, controlId, inputId, hasChanged)
    if self.is_mapping then 
        --print("Control [" .. controlId .. "] is now [" .. inputId .. "]")
        TheFrontEnd:PopScreen()
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        for k, v in pairs(self.activecontrollist.items) do
            if controlId == v.controlId then
                if hasChanged then
                    local ctrlString = TheInput:GetLocalizedControl(deviceId, controlId)
                    v.text:SetString(ctrlString)
                    if TheInput:GetStringIsButtonImage(ctrlString) then
                        v.text:SetColour(1,1,1,1)
                        v.text:SetFont(UIFONT)
                    else
                        v.text:SetColour(0,0,0,1)
                        v.text:SetFont(BUTTONFONT)
                    end
                    -- hasChanged only refers to the immediate change, but if a control is modified
                    -- and then modified again to the original we shouldn't highlight it 
                    local changedFromOriginal = TheInputProxy:HasMappingChanged(deviceId, controlId)    
                    if changedFromOriginal then
                        v.bg:Show()
                    else
                        v.bg:Hide()
                    end
                end
            end
        end
        
        -- set the dirty flag (if something changed) if it hasn't yet been set
        if not self:IsDirty() and hasChanged then
            self:MakeDirty()
        end
        
	    self.is_mapping = false
    end 
end

function ControlsScreen:MapControlInputHandler(control, down)
    --[[if not down and control == CONTROL_CANCEL then
        TheInputProxy:CancelMapping()
        self.is_mapping = false
        TheFrontEnd:PopScreen()
    end--]]

end

function ControlsScreen:OnControl(control, down)
    if ControlsScreen._base.OnControl(self, control, down) then return true end
    
    if not down then
        if control == CONTROL_CANCEL then
            self:Cancel()
            return true
        elseif control == CONTROL_ACCEPT then
            self:Apply()
            return true
        elseif control == CONTROL_MAP and TheInput:ControllerAttached() then
            TheFrontEnd:PushScreen(PopupDialogScreen( STRINGS.UI.CONTROLSSCREEN.RESETTITLE, STRINGS.UI.CONTROLSSCREEN.RESETBODY,
            { 
                { 
                    text = STRINGS.UI.CONTROLSSCREEN.YES, 
                    cb = function()
                        self:LoadDefaultControls() 
                        TheFrontEnd:PopScreen()
                    end
                },
                { 
                    text = STRINGS.UI.CONTROLSSCREEN.NO, 
                    cb = function()
                        TheFrontEnd:PopScreen()                 
                    end
                }
            }))
            return true
        end
    end
end

function ControlsScreen:Cancel()
    if not self.dirty then
    	if self.cancelbutton.shown then self.cancelbutton:Disable() end
    	TheFrontEnd:Fade(false, screen_fade_time, function()
			TheFrontEnd:PopScreen()
			TheFrontEnd:Fade(true, screen_fade_time)
		end)
	else
	    local popup = PopupDialogScreen(STRINGS.UI.CONTROLSSCREEN.LOSE_CHANGES_TITLE, STRINGS.UI.CONTROLSSCREEN.LOSE_CHANGES_BODY, 
			{{text=STRINGS.UI.CONTROLSSCREEN.YES, cb = function() 
				self.dirty = false  
				if self.cancelbutton.shown then self.cancelbutton:Disable() end
				TheFrontEnd:Fade(false, screen_fade_time, function()
					TheFrontEnd:PopScreen()
					TheFrontEnd:PopScreen()
					TheFrontEnd:Fade(true, screen_fade_time)
				end)
			end},
			{text=STRINGS.UI.CONTROLSSCREEN.NO, cb = function() TheFrontEnd:PopScreen() end}  })
		TheFrontEnd:PushScreen(popup)
	end
end

function ControlsScreen:Apply()
	if self.dirty then
		TheFrontEnd:PushScreen(PopupDialogScreen( STRINGS.UI.CONTROLSSCREEN.APPLYTITLE, STRINGS.UI.CONTROLSSCREEN.APPLYBODY,
		{ 
		  	{ 
		  		text = STRINGS.UI.CONTROLSSCREEN.YES, 
		  		cb = function()
		  			TheInputProxy:ApplyControlMapping()
				    for index = 1, #self.devices do
				        local guid, data, enabled = TheInputProxy:SaveControls(self.devices[index].data)
				        if not(nil == guid) and not(nil == data) then
				            Profile:SetControls(guid, data, enabled)
				        end
				    end
				    Profile:Save()
				    self:MakeClean()
					if self.cancelbutton.shown then self.cancelbutton:Disable() end
					if self.applybutton.shown then self.applybutton:Disable() end
					TheFrontEnd:Fade(false, screen_fade_time, function()
						TheFrontEnd:PopScreen()
						TheFrontEnd:PopScreen()
						TheFrontEnd:Fade(true, screen_fade_time)
					end)
				end
			},
			{ 
				text = STRINGS.UI.CONTROLSSCREEN.NO, 
				cb = function()
					TheFrontEnd:PopScreen()					
				end
			}
		}))
	end
end

function ControlsScreen:GetHelpText()
	local t = {}
	local controller_id = TheInput:GetControllerID()

	-- if self.leftbutton.shown then
	-- 	table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_SCROLLBACK) .. " " .. STRINGS.UI.HELP.SCROLLBACK)
	-- end
	-- if self.rightbutton.shown then
	-- 	table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_SCROLLFWD) .. " " .. STRINGS.UI.HELP.SCROLLFWD)
	-- end

    table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MAP, false, false) .. " " .. STRINGS.UI.CONTROLSSCREEN.RESET)

    if self.dirty then
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT, false, false) .. " " .. STRINGS.UI.HELP.APPLY)          
    end

	table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL, false, false) .. " " .. STRINGS.UI.HELP.BACK)
	return table.concat(t, "  ")
end

return ControlsScreen