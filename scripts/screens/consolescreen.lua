require "util"
local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local TextEdit = require "widgets/textedit"
local Text = require "widgets/text"
local Widget = require "widgets/widget"

-- fix syntax highlighting due to above list: "'

local DEBUG_MODE = BRANCH == "dev"
local CONSOLE_HISTORY = {}
local SUGGESTIONS_MAX = 5
local PREFAB_KEYS = {}

local ConsoleScreen = Class(Screen, function(self)
	Screen._ctor(self, "ConsoleScreen")
    self.runtask = nil
	self:DoInit()
end)

function ConsoleScreen:OnBecomeActive()
	ConsoleScreen._base.OnBecomeActive(self)
	TheFrontEnd:ShowConsoleLog()

	--setup prefab keys 
	PREFAB_KEYS = {}
	for k,v in pairs(Prefabs) do 
		table.insert(PREFAB_KEYS, k)
	end 

	self.autocompletePrefix = nil
	self.autocompleteObjName = ""
	self.autocompleteObj = nil
	self.autocompleteOffset = -1

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
            self:PrefabSuggest(down, key)
        end
		return true 
	end

	if down then return end
	
	if key == KEY_TAB then
		if self.suggesting then 
			self:SuggestComplete()
		else
			self:AutoComplete()
		end
	elseif key == KEY_UP then
		if self.suggesting then 
			self:DeltaSuggest(1)
		else 
			local len = #CONSOLE_HISTORY
			if len > 0 then
				if self.history_idx ~= nil then
					self.history_idx = math.max( 1, self.history_idx - 1 )
				else
					self.history_idx = len
				end
				self.console_edit:SetString( CONSOLE_HISTORY[ self.history_idx ] )
			end
		end 
	elseif key == KEY_DOWN then
		if self.suggesting then 
			self:DeltaSuggest(-1)
		else
			local len = #CONSOLE_HISTORY
			if len > 0 then
				if self.history_idx ~= nil then
					if self.history_idx == len then
						self.console_edit:SetString( "" )
					else
						self.history_idx = math.min( len, self.history_idx + 1 )
						self.console_edit:SetString( CONSOLE_HISTORY[ self.history_idx ] )
					end
				end
			end
		end
	elseif key == KEY_LCTRL or key == KEY_RCTRL then
        self:ToggleRemoteExecute()
	else
		self.autocompletePrefix = nil
		self.autocompleteObjName = ""
		self.autocompleteObj = nil
		self.autocompleteOffset = -1
		return false
	end
	
	return true
end

function ConsoleScreen:DeltaSuggest(dt)
	local newnum = self.highlight + dt
	if newnum <= 0 then 
		newnum = #self.suggest_text + dt + 1
	elseif newnum > #self.suggest_text then 
		newnum = 1 + dt - 1 
	end

	self:Highlight(newnum)
end 

function ConsoleScreen:SuggestComplete()
	assert(self.suggest_text[self.highlight] ~= nil)
	assert(self.suggest_idx > 0)
	local idx = self.suggest_idx - 1
	local str = self.console_edit:GetString()
	if string.find(str, "(", nil, true) ~= nil then 
		--We removed these earlier 
		idx = idx + 1
	end 
	str = str:sub(1, idx)
	str = str .. self.suggest_text[self.highlight]:GetString()
	--close quotes and parens, get us ready to submit text
	if str:find("\'") ~= nil then 
		str = str .. "\'"
	elseif str:find("\"") ~= nil then 
		str = str .. "\"" 
	end 

	if string.find(str, "(", nil, true) then 
		str = str .. ")"
	end 

	for _,v in ipairs(self.suggest_text) do 
		v:SetString("")
	end 

	self.console_edit:SetString(str)

	self.suggesting = false 
	self.highlight = nil
end 

local function CountQuotes(str)
	local found_quote = true 
	local numquotes = 0
	local lastpos = 1

	while found_quote do 
		local start, fin = string.find(str, "\"", lastpos)
		if start == nil then 
			found_quote = false 
		else
			numquotes = numquotes + 1 
			if str:len() == fin then 
				found_quote = false 
			else
				lastpos = fin + 1
			end 
		end 
	end  

	return numquotes 
end 

function ConsoleScreen:PrefabSuggest(down, key)
	 -- not yet comprehensive 
	local TESTS = {"c_spawn\"", "c_gonext\"", "c_give\"", "c_list\"", "c_find\"", "c_findnext\"", "c_countprefabs\"", "c_selectnear\"", "c_removeall\""}
	if key == KEY_TAB or key == KEY_UP or key == KEY_DOWN then return end  
	if down then 
		for _,v in ipairs(self.suggest_text) do 
			v:SetString("")
		end 
		local str_test = self.console_edit:GetString()
		str_test = string.lower(str_test) -- lowercase for comparison 
		str_test = string.gsub(str_test, "%(", "") --remove parens for comparison
		str_test = string.gsub(str_test, "\'", "\"")
		local numquotes = CountQuotes(str_test)

		if (numquotes % 2 == 0) then -- even # of quotes, don't autofill 
			return 
		end 

		for _,test in ipairs(TESTS) do 
			local start, fin = str_test:find(test) 
			if start ~= nil and fin ~= nil then 
				-- make sure it's not no text and doesn't have a closing quote/parens 
				if str_test:len() > fin and str_test:find("\"", fin + 1) == nil and str_test:find("%)", fin + 1) == nil then 
					self:ShowSuggestions(str_test, test, start, fin)
					break
				else
					self.suggesting = false 
				end 
			end 
		end 
	end
end 

function ConsoleScreen:ShowSuggestions(fullstr, command, start, fin)

	local str = fullstr:sub(fin+1)
	local suggestions = {}
	for _,v in ipairs(PREFAB_KEYS) do
		if #suggestions >= SUGGESTIONS_MAX then break end 
		if v:match(str) ~= nil then 
			table.insert(suggestions, v)
		end 
	end 

	if #suggestions > 0 then 
		self.suggesting = true
		self.suggest_replace = str
		self.suggest_idx = fin+1
	else
		self.suggesting = false 
	end 

	for k,v in ipairs(suggestions) do 
		if k == 1 then 
			self:Highlight(k)
		end
		self.suggest_text[k]:SetString(v)
	end
end 

function ConsoleScreen:Highlight(key)
	for k,v in ipairs(self.suggest_text) do 
		if k ~= key then 
			v:SetColour(1, 1, 1, 1)
		end
	end 

	self.highlight = key 
	self.suggest_text[key]:SetColour(1, 1, 0, 1)
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

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

-- For this to be improved, you really need to start knowing about the language that's
-- being autocompleted and the string must be tokenized and fed into a lexer.
--
-- For instance, what should you autocomplete here:
--		print(TheSim:Get<tab>
--
-- Given understanding of the language, we know that the object to get is TheSim and
-- it's the metatable from that to autocomplete from. However, you need to know that
-- "print(" is not part of that object.
--
-- Conversely, if I have "SomeFunction().GetTheSim():Get<tab>" then I need to include
-- "SomeFunction()." as opposed to stripping it off. Again, we're back to understanding
-- the language.
--
-- Something that might work is to cheat by starting from the last token, then iterating
-- backwards evaluating pcalls until you don't get an error or you reach the front of the
-- string.
function ConsoleScreen:AutoComplete()
	local str = self.console_edit:GetString()

	if self.autocompletePrefix == nil and self.autocompleteObj == nil then
		local autocomplete_obj_name = nil
		local autocomplete_prefix = str
		
		local rev_str = string.reverse( str )
		local idx = string.find( rev_str, ".", 1, true )
		if idx == nil then
			idx = string.find( rev_str, ":", 1, true )
		end
		if idx ~= nil then
			autocomplete_obj_name = string.sub( str, 1, string.len( str ) - idx )
			autocomplete_prefix = string.sub( str, string.len( str ) - idx + 2, string.len( str ) - 1 )
		end
		
		self.autocompletePrefix = autocomplete_prefix

		if autocomplete_obj_name ~= nil then
			local status, r = pcall( loadstring( "__KLEI_AUTOCOMPLETE=" .. autocomplete_obj_name ) )
			if status then
				self.autocompleteObjName = string.sub( str, 1, string.len( str ) - idx + 1 ) -- must include that last character!
				self.autocompleteObj = getmetatable( __KLEI_AUTOCOMPLETE )
				if self.autocompleteObj == nil then
					self.autocompleteObj = __KLEI_AUTOCOMPLETE
				end
			end
		end
	end
	
	local autocomplete_obj = self.autocompleteObj or _G
	local len = string.len( self.autocompletePrefix )
	
	local found = false
	local counter = 0
	for k, v in pairs( autocomplete_obj ) do
		if string.starts( k, self.autocompletePrefix ) then
			if self.autocompleteOffset == -1 or self.autocompleteOffset < counter then
				self.console_edit:SetString( self.autocompleteObjName .. k )
				self.autocompleteOffset = counter
				found = true
				break
			end	
			counter = counter + 1
		end
	end

	if not found then
		self.autocompleteOffset = -1
		for k, v in pairs( autocomplete_obj ) do
			if string.starts( k, self.autocompletePrefix ) then
				self.console_edit:SetString( self.autocompleteObjName .. k )
				self.autocompleteOffset = 0
			end
		end		
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

	local label_width = 200
	local label_height = 50
	local label_offset = 450

	local space_between = 30
	local height_offset = -270

	local fontsize = 30
	
	local edit_width = 900
	local edit_bg_padding = 100
	
	self.edit_width   = edit_width
	self.label_height = label_height
	
	self.autocompleteOffset = -1	
	self.autocompletePrefix = nil
	self.autocompleteObj = nil
	self.autocompleteObjName = ""
	
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
	
	self.suggest_text = {}
	for i = 1, SUGGESTIONS_MAX do 
		local v = self.root:AddChild(Text(DEFAULTFONT, 27, ""))
		v:SetPosition(290, 32*i + 18, 0)
		v:SetHAlign(ANCHOR_RIGHT)
		v:SetRegionSize(300, label_height)
		--v.bg_image = v:AddChild(Image("images/global.xml", "square.tex"))
		table.insert(self.suggest_text, v)
	end 

	self.suggesting = false 
	self.highlight = nil 
	self.suggest_replace = ""

	self.console_edit.OnTextEntered = function() self:OnTextEntered() end
	--self.console_edit:SetLeftMouseDown( function() self:SetFocus( self.console_edit ) end )
	self.console_edit:SetFocusedImage(self.edit_bg, "images/textboxes.xml", "textbox_long_over.tex", "textbox_long.tex")
	self.console_edit:SetInvalidCharacterFilter( [[`	]] )
    self.console_edit:SetPassControlToScreen(CONTROL_CANCEL, true)

	self.console_edit:SetString("")
	self.history_idx = nil

	self.console_edit.validrawkeys[KEY_TAB] = true
	self.console_edit.validrawkeys[KEY_UP] = true
	self.console_edit.validrawkeys[KEY_DOWN] = true
	self.console_edit.validrawkeys[KEY_LCTRL] = true
	self.console_edit.validrawkeys[KEY_RCTRL] = true
	self.toggle_remote_execute = false
	
end

return ConsoleScreen
