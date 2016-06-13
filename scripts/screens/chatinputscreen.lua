require "util"
local Screen = require "widgets/screen"
local TextEdit = require "widgets/textedit"
local Widget = require "widgets/widget"
local Text = require "widgets/text"

local UserCommands = require("usercommands")

local CHAT_INPUT_MAX_LENGTH = 150
local CHAT_INPUT_HISTORY = {}

local ChatInputScreen = Class(Screen, function(self, whisper)
    Screen._ctor(self, "ChatInputScreen")
    self.whisper = whisper
    self.runtask = nil
    self:DoInit()
end)

function ChatInputScreen:OnBecomeActive()
    ChatInputScreen._base.OnBecomeActive(self)

    self.chat_edit:SetFocus()
    self.chat_edit:SetEditing(true)
    TheFrontEnd:LockFocus(true)
end

function ChatInputScreen:OnBecomeInactive()
    ChatInputScreen._base.OnBecomeInactive(self)

    if self.runtask ~= nil then
        self.runtask:Cancel()
        self.runtask = nil
    end
end

function ChatInputScreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}

    table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)
    
    if self.whisper then
        table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_MENU_MISC_2) .. " " .. STRINGS.UI.CHATINPUTSCREEN.HELP_SAY)
        table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. STRINGS.UI.CHATINPUTSCREEN.HELP_WHISPER)
    else
        table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_MENU_MISC_2) .. " " .. STRINGS.UI.CHATINPUTSCREEN.HELP_WHISPER)
        table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. STRINGS.UI.CHATINPUTSCREEN.HELP_SAY)
    end

    return table.concat(t, "  ")
end

function ChatInputScreen:OnControl(control, down)
    if self.runtask ~= nil or ChatInputScreen._base.OnControl(self, control, down) then return true end

    --jcheng: don't allow debug menu stuff going on right now
    if control == CONTROL_OPEN_DEBUG_CONSOLE then
        return true
    end

    -- For controllers, the misc_2 button will whisper if in say mode or say if in whisper mode. This is to allow the player to only bind one key to initiate chat mode.
    if not down and control == CONTROL_MENU_MISC_2 then
        self.whisper = not self.whisper
        self:OnTextEntered()
        return true
    end

    if not down and (control == CONTROL_CANCEL or control == CONTROL_TOGGLE_SAY or control == CONTROL_TOGGLE_WHISPER) then 
        self:Close()
        return true
    end
end

function ChatInputScreen:OnRawKey(key, down)
    if self.runtask ~= nil or ChatInputScreen._base.OnRawKey(self, key, down) then return true end

    if down then return end

    if key == KEY_UP then
        local len = #CHAT_INPUT_HISTORY
        if len > 0 then
            if self.history_idx ~= nil then
                self.history_idx = math.max( 1, self.history_idx - 1 )
            else
                self.history_idx = len
            end
            self.chat_edit:SetString( CHAT_INPUT_HISTORY[ self.history_idx ] )
        end
    elseif key == KEY_DOWN then
        local len = #CHAT_INPUT_HISTORY
        if len > 0 then
            if self.history_idx ~= nil then
                if self.history_idx == len then
                    self.chat_edit:SetString( "" )
                else
                    self.history_idx = math.min( len, self.history_idx + 1 )
                    self.chat_edit:SetString( CHAT_INPUT_HISTORY[ self.history_idx ] )
                end
            end
        end
    else
        self.autocompletePrefix = nil
        self.autocompleteObjName = ""
        self.autocompleteObj = nil
        self.autocompleteOffset = -1
        return false
    end

    return true
end

function ChatInputScreen:Run()
    local chat_string = self.chat_edit:GetString()
    chat_string = chat_string ~= nil and chat_string:match("^%s*(.-%S)%s*$") or ""
    if chat_string == "" then
        return
    elseif string.sub(chat_string, 1, 1) == "/" then
        --Process slash commands:
        UserCommands.RunTextUserCommand(string.sub(chat_string, 2), ThePlayer, false)
    else
        --Default to sending regular chat
        TheNet:Say(chat_string, self.whisper)
    end
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function ChatInputScreen:Close()
    --SetPause(false)
    TheInput:EnableDebugToggle(true)
    TheFrontEnd:PopScreen(self)
end

local function DoRun(inst, self)
    self.runtask = nil
    self:Run()
    self:Close()
end

function ChatInputScreen:OnTextEntered()
    if self.runtask ~= nil then
        self.runtask:Cancel()
    end
    self.runtask = self.inst:DoTaskInTime(0, DoRun, self)
end

function ChatInputScreen:DoInit()
    --SetPause(true,"console")
    TheInput:EnableDebugToggle(false)

    local label_width = 200
    local label_height = 50
    local label_offset = 450

    local space_between = 30
    local height_offset = -270

    local fontsize = 30

    local edit_width = 850
    local chat_type_width = 150
    local edit_bg_padding = 100

    self.autocompleteOffset = -1    
    self.autocompletePrefix = nil
    self.autocompleteObj = nil
    self.autocompleteObjName = ""

    self.root = self:AddChild(Widget("chat_input_root"))
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetVAnchor(ANCHOR_BOTTOM)
    self.root = self.root:AddChild(Widget(""))

    self.root:SetPosition(10,100,0)

    self.chat_type = self.root:AddChild( Text( TALKINGFONT, fontsize ) )--DEFAULTFONT, fontsize ) )
    self.chat_type:SetPosition(-505, 0, 0)
    self.chat_type:SetRegionSize( chat_type_width, label_height )
    self.chat_type:SetHAlign(ANCHOR_RIGHT)
    if self.whisper then
        self.chat_type:SetString(STRINGS.UI.CHATINPUTSCREEN.WHISPER)
    else
        self.chat_type:SetString(STRINGS.UI.CHATINPUTSCREEN.SAY)
    end
    self.chat_type:SetColour(0.6,0.6,0.6,1)

    self.chat_edit = self.root:AddChild( TextEdit( TALKINGFONT, fontsize, "" ) )--DEFAULTFONT, fontsize, "" ) )
    self.chat_edit.edit_text_color = {1,1,1,1}
    self.chat_edit.idle_text_color = {1,1,1,1}
    self.chat_edit:SetEditCursorColour(1,1,1,1) 
    self.chat_edit:SetPosition(0, 0, 0)
    self.chat_edit:SetRegionSize( edit_width, label_height )
    self.chat_edit:SetHAlign(ANCHOR_LEFT)

    -- the screen will handle the help text
    self.chat_edit:SetHelpTextApply("")
    self.chat_edit:SetHelpTextCancel("")
    self.chat_edit:SetHelpTextEdit("")
    self.chat_edit.HasExclusiveHelpText = function() return false end

    self.chat_edit.OnTextEntered = function() self:OnTextEntered() end
    self.chat_edit:SetPassControlToScreen(CONTROL_CANCEL, true)
    self.chat_edit:SetPassControlToScreen(CONTROL_MENU_MISC_2, true) -- toggle between say and whisper
    self.chat_edit:SetTextLengthLimit(CHAT_INPUT_MAX_LENGTH)

    self.chat_edit:SetString("")
    self.history_idx = nil

    self.chat_edit.validrawkeys[KEY_UP] = true
    self.chat_edit.validrawkeys[KEY_DOWN] = true

end

return ChatInputScreen
