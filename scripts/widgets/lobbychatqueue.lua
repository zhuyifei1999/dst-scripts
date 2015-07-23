local Widget = require "widgets/widget"
local Text = require "widgets/text"
local ScrollableList = require "widgets/scrollablelist"

local MAX_MESSAGES = 20

local function message_constructor(data)
	local list = {}

	local group = Widget("item-lobbychat")

	local bg_size_x = 200
	local bg_size_y = data.chat_size+4

	local username_width = 120

	group.bg = group:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
	group.bg:SetSize(bg_size_x, bg_size_y)
	group.bg:SetPosition(8, 0)

	local user_widget = group:AddChild(Text(data.chat_font, data.chat_size-3))
    user_widget:SetTruncatedString(data.username..":", username_width, 25, "..:")
    local user_name_width, h = user_widget:GetRegionSize()
    user_widget:SetPosition(user_name_width * .5 - 85, -3) 
	user_widget:SetColour(unpack(data.colour))
	group.user_widget = user_widget

	--print("user is ", data.username, unpack(data.colour))

	local shortwidth = 190-user_name_width
	local longwidth = 190

	group.messages = {}
	local text = data.message
	local lines = TheFrontEnd:SplitTextStringIntoLines(text, data.chat_font, data.chat_size, shortwidth, longwidth)

	for i = 1,#lines do 
		local line = lines[i]

		if not group.bg then 
			group.bg = group:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
			group.bg:SetSize(bg_size_x, bg_size_y)
			group.bg:SetPosition(8, 0)
		end

		local width = longwidth
		local xpos = 10
		if group.user_widget then 
			width = shortwidth
			xpos = 10+user_name_width-(user_name_width/2)
		end

		local message_widget = group:AddChild(Text(NEWFONT, data.chat_size))
		message_widget:SetPosition(xpos, 0 )--- (15*(i-1)))
		message_widget:SetRegionSize( width, (data.chat_size) )
		message_widget:SetHAlign(ANCHOR_LEFT)
		message_widget:SetString(line)
		message_widget:SetColour(unpack(BLACK))
		group.message = message_widget	
		
		group.OnGainFocus = function(item) 
			-- item.message:SetSize(data.chat_size + 1)
		end

		group.OnLoseFocus = function(item)  
			-- item.message:SetSize(data.chat_size)
		end

		table.insert(list, group)
		group = Widget("item-lobbychat")
	end

	return list
end

	
local LobbyChatQueue = Class(Widget, function(self, owner, chatbox, onReceiveNewMessage)
	Widget._ctor(self, "LobbyChatQueue")

	self.owner = owner

	self.list_items = {}
	
	self.chat_font = TALKINGFONT
	self.chat_size = 28

	self.chatbox = chatbox

	self.new_message_fn = onReceiveNewMessage
	
	self:StartUpdating()
end)

function LobbyChatQueue:GetChatAlpha( current_time, chat_time )
	return 1.0			
end

function LobbyChatQueue:OnUpdate()
end

--For ease of overriding in mods
function LobbyChatQueue:GetDisplayName(name, prefab)
    return name ~= "" and name or STRINGS.UI.SERVERADMINSCREEN.UNKNOWN_USER_NAME
end

function LobbyChatQueue:OnMessageReceived(userid, name, prefab, message, colour)
	-- Early out if this player is muted
	if TheFrontEnd.mutedPlayers ~= nil and TheFrontEnd.mutedPlayers[userid] then
		return
	end

	if message == "" then
		return
	end

	self.list_items[#self.list_items + 1] =
    {
        message = message,
        chat_font = self.chat_font,
        chat_size = self.chat_size,
        colour = colour,
        username = self:GetDisplayName(name, prefab),
    }

	local startidx = math.max(1, (#self.list_items - MAX_MESSAGES) + 1) -- older messages are dropped
	local list_widgets = {}
	for k,v in pairs(self.list_items) do 
		if k >= startidx then 
			local list = message_constructor(v)
			for k2,v2 in pairs(list) do 
				table.insert(list_widgets, v2)
			end
		end
	end

	if not self.scroll_list then
		self.scroll_list = self:AddChild(ScrollableList(list_widgets, 130, 305, 20, 12, nil, nil, nil, nil, nil, 15))
    	self.scroll_list:SetPosition(52, -32)
	else
		self.scroll_list:SetList(list_widgets)
		self.scroll_list:ScrollToEnd()
	end

	if self.new_message_fn then
		self.new_message_fn()
	end
end 

function LobbyChatQueue:ScrollToEnd()
	if self.scroll_list then
		self.scroll_list:ScrollToEnd()
	end
end

function LobbyChatQueue:OnControl(control, down)
	if not self:IsEnabled() or not self.focus then return false end

    if self.chatbox and control == CONTROL_ACCEPT and TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse then
        return self.chatbox:OnControl(control, down)
    end

    if self.scroll_list and (control == CONTROL_SCROLLBACK or control == CONTROL_SCROLLFWD) then
        return self.scroll_list:OnControl(control, down, true)
    elseif self.scroll_list and self.scroll_list.focus then
    	return self.scroll_list:OnControl(control, down)
    end

    return false
end

function LobbyChatQueue:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}

    if self.scroll_list and self.scroll_list.scroll_bar and self.scroll_list.scroll_bar:IsVisible() then
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_SCROLLBACK, false, false).."/"..TheInput:GetLocalizedControl(controller_id, CONTROL_SCROLLFWD, false, false).. " " .. STRINGS.UI.HELP.SCROLL)   
    end

    if self.chatbox then
    	table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT, false, false ) .. " " .. STRINGS.UI.LOBBYSCREEN.CHAT)   
    end

    return table.concat(t, "  ")
end

return LobbyChatQueue
