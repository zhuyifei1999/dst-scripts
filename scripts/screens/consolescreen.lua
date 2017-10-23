require "util"
local TextCompleter = require "util/textcompleter"
local Screen = require "widgets/screen"
local Image = require "widgets/image"
local TextEdit = require "widgets/textedit"
local Text = require "widgets/text"
local Widget = require "widgets/widget"

-- fix syntax highlighting due to above list: "'

-- To start your game with a prepopulated history, add to your customcommands.lua:
--      require "screens/consolescreen"
--      table.insert(GetConsoleHistory(), 'c_give("batbat")')

local DEBUG_MODE = BRANCH == "dev"
local CONSOLE_HISTORY = {}

local ConsoleScreen = Class(Screen, function(self)
	Screen._ctor(self, "ConsoleScreen")
    self.runtask = nil
	self:DoInit()
end)

function ConsoleScreen:OnBecomeActive()
	ConsoleScreen._base.OnBecomeActive(self)
	TheFrontEnd:ShowConsoleLog()

	--setup prefab keys
    local prefab_names = {}
	for name,_ in pairs(Prefabs) do
		table.insert(prefab_names, name)
	end

	local suggestion_data = {
		-- functions for prefab suggest: not yet comprehensive
		prefixes = {"c_spawn", "c_gonext", "c_give", "c_list", "c_find", "c_findnext", "c_countprefabs", "c_selectnear", "c_removeall"},
		words = prefab_names,
		delimiters = { "\"", "\'" },
	}
	self.completer:SetSuggestionData(suggestion_data)

	self.completer:ClearState()

	self.console_edit:SetFocus()
	self.console_edit:SetEditing(true)

    self:ToggleRemoteExecute(true) -- if we are admin, start in remote mode

	TheFrontEnd:LockFocus(true)
end

function ConsoleScreen:OnBecomeInactive()
    ConsoleScreen._base.OnBecomeInactive(self)

    if self.runtask ~= nil then
        self.runtask:Cancel()
        self.runtask = nil
    end
end

function ConsoleScreen:OnControl(control, down)
	if self.runtask ~= nil or ConsoleScreen._base.OnControl(self, control, down) then return true end

	if not down and (control == CONTROL_CANCEL or control == CONTROL_OPEN_DEBUG_CONSOLE) then 
		self:Close()
		return true
	end
end

function ConsoleScreen:ToggleRemoteExecute(force)
    local is_valid_time_to_use_remote = TheNet:GetIsClient() and TheNet:GetIsServerAdmin()
    if is_valid_time_to_use_remote then
        if force == nil then
            if self.toggle_remote_execute then
                self.console_remote_execute:Hide()
            else
                self.console_remote_execute:Show()
            end
            self.toggle_remote_execute = not self.toggle_remote_execute
        elseif force == true then
            self.console_remote_execute:Show()
            self.toggle_remote_execute = true
        elseif force == false then
            self.console_remote_execute:Hide()
            self.toggle_remote_execute = false
        end
    elseif self.toggle_remote_execute then
        self.console_remote_execute:Hide()
        self.toggle_remote_execute = false
    end
end

function ConsoleScreen:OnRawKey(key, down)
	if self.runtask ~= nil then return true end
	if ConsoleScreen._base.OnRawKey(self, key, down) then 
		if DEBUG_MODE then
			self.completer:UpdateSuggestions(down, key)
		end
		return true 
	end

	if down then return end
	
	if key == KEY_LCTRL or key == KEY_RCTRL then
        self:ToggleRemoteExecute()
	else
		return self.completer:OnRawKey(key, down)
	end

	return true
end

function ConsoleScreen:Run()
	local fnstr = self.console_edit:GetString()

    SuUsedAdd("console_used")
	
	if fnstr ~= "" then
		table.insert( CONSOLE_HISTORY, fnstr )
	end
	
	if self.toggle_remote_execute then
        local x, y, z = TheSim:ProjectScreenPos(TheSim:GetPosition())
		TheNet:SendRemoteExecute(fnstr, x, z)
	else
		ExecuteConsoleCommand(fnstr)
	end
end

function ConsoleScreen:Close()
	--SetPause(false)
	TheInput:EnableDebugToggle(true)
	TheFrontEnd:PopScreen(self)	
	TheFrontEnd:HideConsoleLog()
end

local function DoRun(inst, self)
    self.runtask = nil
    self:Run()
    self:Close()
    if TheFrontEnd.consoletext.closeonrun then
        TheFrontEnd:HideConsoleLog()
    end
end

function ConsoleScreen:OnTextEntered()
    -- Do completion on hitting Enter.
    self.completer:PerformCompletion()

    if self.runtask ~= nil then
        self.runtask:Cancel()
    end
    self.runtask = self.inst:DoTaskInTime(0, DoRun, self)
end

function GetConsoleHistory()
    return CONSOLE_HISTORY
end

function SetConsoleHistory(history)
    if type(history) == "table" and type(history[1]) == "string" then
        CONSOLE_HISTORY = history
    end
end

function ConsoleScreen:DoInit()
	--SetPause(true,"console")
	TheInput:EnableDebugToggle(false)

	local label_height = 50
	local fontsize = 30
	local edit_width = 900
	local edit_bg_padding = 100
	
	self.edit_width   = edit_width
	self.label_height = label_height
	
	self.root = self:AddChild(Widget(""))
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetVAnchor(ANCHOR_BOTTOM)
    --self.root:SetMaxPropUpscale(MAX_HUD_SCALE)
	self.root = self.root:AddChild(Widget(""))
	self.root:SetPosition(0,120,0)
	
    self.edit_bg = self.root:AddChild( Image() )
	self.edit_bg:SetTexture( "images/textboxes.xml", "textbox_long.tex" )
	self.edit_bg:SetPosition( 0,0,0)
	self.edit_bg:ScaleToSize( edit_width + edit_bg_padding, label_height )

	self.console_remote_execute = self.root:AddChild( Text( DEFAULTFONT, fontsize ) )
	self.console_remote_execute:SetString( STRINGS.UI.CONSOLESCREEN.REMOTEEXECUTE)
	local w,h = self.console_remote_execute:GetRegionSize()
	self.console_remote_execute:SetPosition( -w - 35,0,0 )
	self.console_remote_execute:SetHAlign(ANCHOR_LEFT)
	self.console_remote_execute:SetColour(0.7,0.7,1,1)
	self.console_remote_execute:Hide()
	local text_height
	self.console_remote_execute_region_width, text_height = self.console_remote_execute:GetRegionSize()
	self.console_remote_execute:SetRegionSize( edit_width, label_height )
	self.console_edit = self.root:AddChild( TextEdit( DEFAULTFONT, fontsize, "" ) )
	self.console_edit.edit_text_color = {1,1,1,1}
	self.console_edit.idle_text_color = {1,1,1,1}
	self.console_edit:SetEditCursorColour(1,1,1,1) 
	self.console_edit:SetPosition( -4,0,0)
	self.console_edit:SetRegionSize( edit_width, label_height )
	self.console_edit:SetHAlign(ANCHOR_LEFT)
	self.console_edit:SetHelpTextEdit("")

	local max_suggestions = 5
	local suggest_text_widgets = TextCompleter.CreateDefaultSuggestionWidgets(self.root, label_height, max_suggestions)
	self.completer = TextCompleter(suggest_text_widgets, self.console_edit, CONSOLE_HISTORY, true)

	self.console_edit.OnTextEntered = function() self:OnTextEntered() end
	--self.console_edit:SetLeftMouseDown( function() self:SetFocus( self.console_edit ) end )
	self.console_edit:SetFocusedImage(self.edit_bg, "images/textboxes.xml", "textbox_long_over.tex", "textbox_long.tex")
	self.console_edit:SetInvalidCharacterFilter( [[`	]] )
    self.console_edit:SetPassControlToScreen(CONTROL_CANCEL, true)

	self.console_edit:SetString("")

	self.console_edit.validrawkeys[KEY_LCTRL] = true
	self.console_edit.validrawkeys[KEY_RCTRL] = true
	self.toggle_remote_execute = false
	
end

return ConsoleScreen
