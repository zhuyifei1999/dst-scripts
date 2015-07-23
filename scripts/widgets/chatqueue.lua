local Widget = require "widgets/widget"
local Text = require "widgets/text"
local CHAT_QUEUE_SIZE = 7
local CHAT_EXPIRE_TIME = 10.0
local CHAT_FADE_TIME = 2.0
local CHAT_LINGER_TIME = 1.0
	
local ChatQueue = Class(Widget, function(self, owner)
	Widget._ctor(self, "ChatQueue")

	self.owner = owner

	self.messages = {}
	self.users = {}
	self.whispers = {}
	self.timestamp = {}
	self.colours = {}
	
	self.chat_font = TALKINGFONT--DEFAULTFONT --UIFONT
	self.chat_size = 30 --22
	
	for i = 1,CHAT_QUEUE_SIZE do
		
		local message_widget = self:AddChild(Text(self.chat_font, self.chat_size))
		message_widget:SetPosition(-125+ 25 + 200, -400 - i * (self.chat_size+2))
		message_widget:SetRegionSize( 850, (self.chat_size+2) )
		message_widget:SetHAlign(ANCHOR_LEFT)
		message_widget:SetVAlign(ANCHOR_MIDDLE)
		message_widget:SetString("")
		self.messages[i] = message_widget	
		
		local user_widget = self:AddChild(Text(self.chat_font, self.chat_size))
		user_widget:SetPosition(-330, -400 - i * (self.chat_size+2))
		user_widget:SetHAlign(ANCHOR_RIGHT)
		user_widget:SetVAlign(ANCHOR_MIDDLE)
		user_widget:SetString("")
		user_widget:SetColour(0.3,0.3,1,1)
		self.users[i] = user_widget

		local whisper_widget = self:AddChild(Text(self.chat_font, self.chat_size))
		whisper_widget:SetPosition(-515, -400 - i * (self.chat_size+2))
		whisper_widget:SetHAlign(ANCHOR_RIGHT)
		whisper_widget:SetVAlign(ANCHOR_MIDDLE)
		whisper_widget:SetString(STRINGS.UI.CHATINPUTSCREEN.WHISPER_DESIGNATOR)
		whisper_widget:SetColour(0.3,0.3,1,1)
		whisper_widget:Hide()
		self.whispers[i] = whisper_widget
		
		self.timestamp[i] = 0.0
	end	
	
	self:StartUpdating()
end)

function ChatQueue:GetChatAlpha( current_time, chat_time )
	if ThePlayer and ThePlayer.HUD and ThePlayer.HUD:IsChatInputScreenOpen() then
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
	
	for i = 1,CHAT_QUEUE_SIZE do
		local chat_time = self.timestamp[i]
			
		if chat_time > 0.0 or chat_time == -1 then
			local time_past_expiring = current_time - ( chat_time + CHAT_EXPIRE_TIME ) 
			if time_past_expiring > 0.0 then
				local alpha_fade = self:GetChatAlpha( current_time, chat_time )
				if self.whispers[i]:IsVisible() then
					self.messages[i]:SetColour(WHISPER_COLOR[1],WHISPER_COLOR[2],WHISPER_COLOR[3],alpha_fade)
				else
					self.messages[i]:SetColour(SAY_COLOR[1],SAY_COLOR[2],SAY_COLOR[3],alpha_fade)
				end
				local clr = self.colours[i]
				self.users[i]:SetColour(clr[1],clr[2],clr[3],alpha_fade)
				self.whispers[i]:SetColour(clr[1],clr[2],clr[3],alpha_fade)
				if alpha_fade <= 0.0 then
					-- Get out of here!
					self.timestamp[i] = -1
				end
			else
				-- No need to keep processing, nothing else past this point will be expired or fading
				return
			end
			-- If the chat input screen is open, reset the timer to fade out soon
			if ThePlayer and ThePlayer.HUD and ThePlayer.HUD:IsChatInputScreenOpen() then
				self.timestamp[i] = current_time - CHAT_EXPIRE_TIME - CHAT_LINGER_TIME
			end
		end
	end
end

--For ease of overriding in mods
function ChatQueue:GetDisplayName(name, prefab)
    return name ~= "" and name or STRINGS.UI.SERVERADMINSCREEN.UNKNOWN_USER_NAME
end

function ChatQueue:OnMessageReceived(userid, name, prefab, message, colour, whisper)
	-- Early out if this player is muted
	if TheFrontEnd.mutedPlayers ~= nil and TheFrontEnd.mutedPlayers[userid] then
		return
	end

	-- Process Chat username
	local username = self:GetDisplayName(name, prefab)

	-- Shuffle upwards
	local x,y
	for i = 1,CHAT_QUEUE_SIZE-1 do
		local older_message = self.messages[i]
		local newer_message = self.messages[i+1]
		older_message:SetString( newer_message:GetString() )
		local older_user = self.users[i]
		local newer_user = self.users[i+1]
		local older_whisper = self.whispers[i]
		local newer_whisper = self.whispers[i+1]
		older_user:SetString( newer_user:GetString() )
		x,y = older_user:GetRegionSize()
		older_user:SetPosition(-330 - x/2, -400 - i * (self.chat_size+2))
		if newer_whisper:IsVisible() then
			older_whisper:Show()
			local x,y = older_user:GetRegionSize()
			older_whisper:SetPosition(-330 - x - 15, -400 - i * (self.chat_size+2))
			older_message:SetColour(WHISPER_COLOR)
		else
			older_whisper:Hide()
			older_message:SetColour(SAY_COLOR)
		end
		self.timestamp[i] = self.timestamp[i+1]
		self.colours[i] = self.colours[i+1]
		local clr = self.colours[i]
		
		local current_time = GetTime()
		local alpha_fade = self:GetChatAlpha( current_time, self.timestamp[i] )
		if clr then
			older_user:SetColour(clr[1],clr[2],clr[3],alpha_fade)
			older_whisper:SetColour(clr[1],clr[2],clr[3],alpha_fade)
		else
			older_user:SetColour(DEFAULT_PLAYER_COLOUR[1],DEFAULT_PLAYER_COLOUR[2],DEFAULT_PLAYER_COLOUR[3],alpha_fade)
			older_whisper:SetColour(DEFAULT_PLAYER_COLOUR[1],DEFAULT_PLAYER_COLOUR[2],DEFAULT_PLAYER_COLOUR[3],alpha_fade)
		end
	end
	-- Add our new entry
	self.messages[CHAT_QUEUE_SIZE]:SetString(message)
    self.users[CHAT_QUEUE_SIZE]:SetTruncatedString(username..":", 140, 25, "..:")
	x,y = self.users[CHAT_QUEUE_SIZE]:GetRegionSize()
	self.users[CHAT_QUEUE_SIZE]:SetPosition(-330 - x/2, -400 - CHAT_QUEUE_SIZE * (self.chat_size+2))
	if whisper then
		self.whispers[CHAT_QUEUE_SIZE]:Show()
		x,y = self.users[CHAT_QUEUE_SIZE]:GetRegionSize()
		self.whispers[CHAT_QUEUE_SIZE]:SetPosition(-330 - x - 15, -400 - CHAT_QUEUE_SIZE * (self.chat_size+2))
		self.messages[CHAT_QUEUE_SIZE]:SetColour(WHISPER_COLOR)
	else
		self.whispers[CHAT_QUEUE_SIZE]:Hide()
		self.messages[CHAT_QUEUE_SIZE]:SetColour(SAY_COLOR)
	end
	self.timestamp[CHAT_QUEUE_SIZE] = GetTime()
    local clr = colour or DEFAULT_PLAYER_COLOUR
	self.colours[CHAT_QUEUE_SIZE] = clr
	self.users[CHAT_QUEUE_SIZE]:SetColour(clr[1],clr[2],clr[3],1)
	self.whispers[CHAT_QUEUE_SIZE]:SetColour(clr[1],clr[2],clr[3],1)
end 

return ChatQueue
