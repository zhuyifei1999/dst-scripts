local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local LobbyChatQueue = require "widgets/redux/lobbychatqueue"
local PlayerList = require "widgets/redux/playerlist"
local Emoji = require("util/emoji")

local TEMPLATES = require "widgets/redux/templates"

require("util")
require("networking")
require("stringutil")

local CHAT_INPUT_HISTORY = {}
local lcol = -RESOLUTION_X/2

local ChatSidebar = Class(Widget, function(self)
    Widget._ctor(self, "ChatSidebar")
    self.active_tab = "players"

    -- Chat is always aligned to the left of the screen.
    self:SetPosition(lcol-5, -375)

    self:BuildSidebar()

    self.default_focus = self.chatbox

    self:DoFocusHookups()
end)

function ChatSidebar:BuildSidebar()
    self.playerList = self:AddChild(PlayerList(self, {right = nil, down = self.chatbox}))
    self:BuildChatWindow()
end

-- Don't use OnControl because we still need the standard Widget version of the
-- function to call OnControl on the children.
function ChatSidebar:_BlockScroll(widget, control, down)
    local mouseX = TheInput:GetScreenPosition().x
    local w,h = TheSim:GetScreenSize()

    if mouseX and mouseX < (w*.2) then 
        if down then
            -- Eat scroll commands so the character list doesn't scroll when the mouse is over the sidebar
            if control == CONTROL_SCROLLBACK or control == CONTROL_SCROLLFWD then 
                return true
            end
        end
    end
    return false
end

--[[function ChatSidebar:UpdateMessageIndicator()
    if self.active_tab ~= "chat" then
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/chat_receive")
        --self.message_indicator:Show()
        --self.message_indicator.count:SetString(self.unread_count)
    else
        --self.unread_count = 0
        --self.message_indicator:Hide()
    end
end]]

function ChatSidebar:MakeTextEntryBox(parent)
    local chatbox = parent:AddChild(Widget("chatbox"))
    local box_size = 240
    local nudgex = 60
    local nudgey = -37
    chatbox.textbox_root = chatbox:AddChild(TEMPLATES.StandardSingleLineTextEntry(nil, box_size - 5))
    chatbox.textbox_root:SetPosition((box_size * .5) - 100 + 26 + nudgex, nudgey, 0)

    chatbox.textbox = chatbox.textbox_root.textbox
    chatbox.textbox:SetTextLengthLimit(MAX_CHAT_INPUT_LENGTH)
    chatbox.textbox:EnableWordWrap(false)
    chatbox.textbox:EnableScrollEditWindow(true)
    chatbox.textbox:SetHelpTextEdit("")
    chatbox.textbox:SetHelpTextApply(STRINGS.UI.LOBBYSCREEN.CHAT)
    chatbox.textbox.OnTextEntered = function()
        local chat_string = self.chatbox.textbox:GetString()
        chat_string = chat_string ~= nil and chat_string:match("^%s*(.-%S)%s*$") or ""
        if chat_string ~= "" and chat_string:utf8len() <= MAX_CHAT_INPUT_LENGTH then
            TheNet:Say(chat_string)
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/chat_send")
        end
        self.chatbox.textbox:SetString("")
        self.chatbox.textbox:SetEditing(true)
    end
    chatbox.textbox:EnableWordPrediction({width = 1100}, Emoji.GetWordPredictionDictionary())

    chatbox.gobutton = chatbox:AddChild(ImageButton("images/lobbyscreen.xml", "button_send.tex", "button_send_over.tex", "button_send_down.tex", "button_send_down.tex", "button_send_down.tex", {1,1}, {0,0}))
    chatbox.gobutton:SetPosition(box_size - 59 + nudgex, nudgey)
    chatbox.gobutton:SetScale(.13)
    chatbox.gobutton.image:SetTint(.6,.6,.6,1)
    chatbox.gobutton:SetOnClick( function() self.chatbox.textbox:OnTextEntered() end )

     -- If chatbox ends up focused, highlight the textbox so we can tell something is focused.
    chatbox:SetOnGainFocus( function() chatbox.textbox:OnGainFocus() end )
    chatbox:SetOnLoseFocus( function() chatbox.textbox:OnLoseFocus() end )

    chatbox.GetHelpText = function()
        local t = {}
        local controller_id = TheInput:GetControllerID()

        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT, false, false ) .. " " .. STRINGS.UI.LOBBYSCREEN.CHAT)
        return table.concat(t, "  ")
    end

    chatbox:SetPosition(-10, -210)

    self.chatbox = chatbox
end

function ChatSidebar:BuildChatWindow()
    self.chat_pane = self:AddChild(Widget("chat_pane"))

    self:MakeTextEntryBox(self.chat_pane)

    self.chatqueue = self.chat_pane:AddChild(LobbyChatQueue(TheNet:GetUserID(), self.chatbox.textbox, function() --[[TODO: put sounds back in!]] end))
    self.chatqueue:SetPosition(42,-20) 

    self.chat_pane:SetPosition(70,RESOLUTION_Y-410)
    
    self.chatbox:MoveToFront()
end

function ChatSidebar:ReceiveChatMessage(...)
    self.chatqueue:OnMessageReceived(...)
end

function ChatSidebar:IsChatting()
    return self.chatbox.textbox.editing
end

function ChatSidebar:OnControl(control, down)
    if ChatSidebar._base.OnControl(self, control, down) then return true end

    -- print("ChatSidebar got control", control, down)

    local will_start_editing = self.chatbox.focus and control == CONTROL_ACCEPT
    if will_start_editing or self.chatbox.textbox.editing then
        self.chatbox.textbox:OnControl(control, down)
        return true
    end

    if self:_BlockScroll(control, down) then
        return true
    end

    return false
end

function ChatSidebar:DoFocusHookups()
    self.playerList:SetFocusChangeDir(MOVE_DOWN, self.chatbox)
    self.chatbox:SetFocusChangeDir(MOVE_UP, self.playerList)
    self.chatbox.textbox:SetFocusChangeDir(MOVE_UP, self.playerList)

    local players = self.playerList:GetPlayerTable()
    self.playerList:BuildPlayerList(players, { right = self.focus_flow[MOVE_RIGHT], down = self.chatbox })
end

function ChatSidebar:Refresh()
    self.playerList:Refresh({right = self.focus_flow[MOVE_RIGHT], down = self.chatbox})
end

return ChatSidebar
