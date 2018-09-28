local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TEMPLATES = require("widgets/redux/templates")

local CHAT_QUEUE_SIZE = 7
local CHAT_EXPIRE_TIME = 10.0
local CHAT_FADE_TIME = 2.0
local CHAT_LINGER_TIME = 1.0

local ChatQueue = Class(Widget, function(self, owner)
    Widget._ctor(self, "ChatQueue")

    self.owner = owner

    self.messages = {}
    self.users = {}
    self.flair = {}
    self.whispers = {}
    self.timestamp = {}
    self.colours = {}
    self.nolabel = {}

    self.chat_font = TALKINGFONT--DEFAULTFONT --UIFONT
    self.chat_size = 30 --22
    self.chat_height = 50
    self.user_width = 140
    self.user_max_chars = 25
    self.message_width = 850
    self.message_max_chars = 150

    for i = 1, CHAT_QUEUE_SIZE do
        local y = -400 - i * (self.chat_size + 2)

        local message_widget = self:AddChild(Text(self.chat_font, self.chat_size))
        message_widget:SetHAlign(ANCHOR_LEFT)
        message_widget:SetString("")
        self.messages[i] = message_widget   

        local user_widget = self:AddChild(Text(self.chat_font, self.chat_size))
        user_widget:SetHAlign(ANCHOR_RIGHT)
        user_widget:SetString("")
        user_widget:SetColour(0.3, 0.3, 1, 1)
        self.users[i] = user_widget

        local flair_widget = self:AddChild(TEMPLATES.ChatFlairBadge())
        flair_widget:SetPosition(-315, y-12.5)
        self.flair[i] = flair_widget

        local whisper_widget = self:AddChild(Text(self.chat_font, self.chat_size))
        whisper_widget:SetHAlign(ANCHOR_RIGHT)
        whisper_widget:SetString(STRINGS.UI.CHATINPUTSCREEN.WHISPER_DESIGNATOR)
        whisper_widget:SetRegionSize(whisper_widget:GetRegionSize())
        whisper_widget:SetColour(0.3, 0.3, 1, 1)
        whisper_widget:Hide()
        self.whispers[i] = whisper_widget

        self.timestamp[i] = 0.0

        self.colours[i] = {1,1,1,1}
    end

    self:StartUpdating()
end)

function ChatQueue:GetChatAlpha( current_time, chat_time )
    if ThePlayer ~= nil and ThePlayer.HUD ~= nil and ThePlayer.HUD:IsChatInputScreenOpen() then
        return 1.0
    else
        local time_past_expiring = current_time - ( chat_time + CHAT_EXPIRE_TIME ) 
        if time_past_expiring > 0.0 then
            if time_past_expiring < CHAT_FADE_TIME then
                local alpha_fade = ( CHAT_FADE_TIME - time_past_expiring ) / CHAT_FADE_TIME
                return alpha_fade
            end
            return 0.0
        end
        return 1.0
    end
end

function ChatQueue:OnUpdate()
    local current_time = GetTime()
    local is_chat_open = ThePlayer ~= nil and ThePlayer.HUD ~= nil and ThePlayer.HUD:IsChatInputScreenOpen() -- If the chat input screen is open, reset the timer to fade out soon

    for i = 1, CHAT_QUEUE_SIZE do 
        if is_chat_open then
            self.timestamp[i] = current_time - CHAT_EXPIRE_TIME - CHAT_LINGER_TIME
        end

        local chat_time = self.timestamp[i]
        if chat_time > 0 then
            local time_past_expiring = current_time - (chat_time + CHAT_EXPIRE_TIME)
            if time_past_expiring > 0 then
                local alpha_fade = self:GetChatAlpha(current_time, chat_time)
                local clr = self.colours[i]
                local msgclr = (self.nolabel[i] and clr) or (self.whispers[i].shown and WHISPER_COLOR) or SAY_COLOR
                self.messages[i]:SetColour(msgclr[1], msgclr[2], msgclr[3], alpha_fade)
                self.users[i]:SetColour(clr[1], clr[2], clr[3], alpha_fade)
                self.flair[i]:SetAlpha(alpha_fade)
                self.whispers[i]:SetColour(clr[1], clr[2], clr[3], alpha_fade)
                if alpha_fade <= 0 then
                    --Stop fading
                    self.timestamp[i] = 0
                end
            end
        end
    end
end

--For ease of overriding in mods
function ChatQueue:GetDisplayName(name, prefab)
    return name ~= "" and name or STRINGS.UI.SERVERADMINSCREEN.UNKNOWN_USER_NAME
end

function ChatQueue:DisplaySystemMessage(message)
    if type(message) == "string" then
        message = {message}
    end

    for i,line in ipairs(message) do
        -- HACK HACK HACK! Since the chat window is single-line only, we break this into multiple lines... by using
        -- an invisible text box that wraps the text for us!
        local textbox = require("widgets/text")(self.chat_font, self.chat_size)
        textbox:SetMultilineTruncatedString(line, 100, self.message_width, self.message_max_chars, false)
        local splitlines = string.split(textbox:GetString(), "\n")
        textbox:Kill()

        for i,splitline in ipairs(splitlines) do
            self:PushMessage("", splitline, WHITE, false, false, nil) --nil for profileflair
        end
    end
end

function ChatQueue:DisplayEmoteMessage(name, prefab, message, colour, whisper)
    message = self:GetDisplayName(name, prefab).." "..message
    self:PushMessage("", message, colour, whisper, true, nil) --nil for profileflair
end

function ChatQueue:OnMessageReceived(name, prefab, message, colour, whisper, profileflair)
    --Make sure that we use the default profile flair is the user hasn't set one.
    if profileflair == nil then
        profileflair = "default"
    end

    -- Process Chat username
    self:PushMessage(self:GetDisplayName(name, prefab), message, colour, whisper, false, profileflair)
end

function ChatQueue:PushMessage(username, message, colour, whisper, nolabel, profileflair)
    -- Shuffle upwards
    for i = 1, CHAT_QUEUE_SIZE - 1 do
        local y = -400 - i * (self.chat_size + 2)
        local older_message = self.messages[i]
        local newer_message = self.messages[i + 1]
        older_message:SetString(newer_message:GetString())
        older_message:SetPosition(newer_message:GetPosition().x, y)
        local older_user = self.users[i]
        local newer_user = self.users[i + 1]
        local older_flair = self.flair[i]
        local newer_flair = self.flair[i + 1]
        local older_whisper = self.whispers[i]
        local newer_whisper = self.whispers[i + 1]
        local clr = self.colours[i + 1]
        local nolabel = self.nolabel[i + 1]
        self.timestamp[i] = self.timestamp[i + 1]
        self.colours[i] = clr
        self.nolabel[i] = nolabel
        local alpha_fade = self:GetChatAlpha(GetTime(), self.timestamp[i])
        older_user:SetString(newer_user:GetString())
        older_user:SetPosition(newer_user:GetPosition().x, y)
        if newer_whisper.shown then
            older_whisper:Show()
            older_whisper:SetPosition(newer_whisper:GetPosition().x, y)
            if not nolabel then
                older_message:SetColour(WHISPER_COLOR)
            end
        else
            older_whisper:Hide()
            if not nolabel then
                older_message:SetColour(SAY_COLOR)
            end
        end
        older_flair:SetFlair(newer_flair:GetFlair())
        older_flair:SetAlpha(alpha_fade)
        if clr ~= nil then
            older_user:SetColour(clr[1], clr[2], clr[3], alpha_fade)
            older_whisper:SetColour(clr[1], clr[2], clr[3], alpha_fade)
            if nolabel then
                older_message:SetColour(clr[1], clr[2], clr[3], alpha_fade)
            end
        else
            older_user:SetColour(DEFAULT_PLAYER_COLOUR[1], DEFAULT_PLAYER_COLOUR[2], DEFAULT_PLAYER_COLOUR[3], alpha_fade)
            older_whisper:SetColour(DEFAULT_PLAYER_COLOUR[1], DEFAULT_PLAYER_COLOUR[2], DEFAULT_PLAYER_COLOUR[3], alpha_fade)
            if nolabel then
                older_message:SetColour(DEFAULT_PLAYER_COLOUR[1], DEFAULT_PLAYER_COLOUR[2], DEFAULT_PLAYER_COLOUR[3], alpha_fade)
            end
        end
    end
    -- Add our new entry
    local y = -400 - CHAT_QUEUE_SIZE * (self.chat_size + 2)
    self.messages[CHAT_QUEUE_SIZE]:SetTruncatedString(message, self.message_width, self.message_max_chars, true)
    local w = self.messages[CHAT_QUEUE_SIZE]:GetRegionSize()
    self.messages[CHAT_QUEUE_SIZE]:SetPosition(w * .5 - 290, y)
    self.users[CHAT_QUEUE_SIZE]:SetTruncatedString(nolabel and "" or username, self.user_width, self.user_max_chars, "..:")
    w = self.users[CHAT_QUEUE_SIZE]:GetRegionSize()
    self.users[CHAT_QUEUE_SIZE]:SetPosition(w * -.5 - 330, y)
    self.flair[CHAT_QUEUE_SIZE]:SetFlair(profileflair)
    local clr = colour or DEFAULT_PLAYER_COLOUR
    if nolabel then
        self.whispers[CHAT_QUEUE_SIZE]:Hide()
        self.messages[CHAT_QUEUE_SIZE]:SetColour(clr[1], clr[2], clr[3], 1)
    elseif whisper then
        self.whispers[CHAT_QUEUE_SIZE]:Show()
        local w2 = self.whispers[CHAT_QUEUE_SIZE]:GetRegionSize()
        self.whispers[CHAT_QUEUE_SIZE]:SetPosition(w2 * -.5 - w - 332, y)
        self.messages[CHAT_QUEUE_SIZE]:SetColour(WHISPER_COLOR)
    else
        self.whispers[CHAT_QUEUE_SIZE]:Hide()
        self.messages[CHAT_QUEUE_SIZE]:SetColour(SAY_COLOR)
    end
    self.timestamp[CHAT_QUEUE_SIZE] = GetTime()
    self.colours[CHAT_QUEUE_SIZE] = clr
    self.nolabel[CHAT_QUEUE_SIZE] = nolabel
    self.users[CHAT_QUEUE_SIZE]:SetColour(clr[1], clr[2], clr[3], 1)
    self.flair[CHAT_QUEUE_SIZE]:SetAlpha(1)
    self.whispers[CHAT_QUEUE_SIZE]:SetColour(clr[1], clr[2], clr[3], 1)
end

return ChatQueue
