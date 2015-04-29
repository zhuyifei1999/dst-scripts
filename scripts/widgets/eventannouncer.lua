local Text = require "widgets/text"
local Widget = require "widgets/widget"

ANNOUNCEMENT_LIFETIME = 7
ANNOUNCEMENT_FADE_TIME = 2
ANNOUNCEMENT_QUEUE_SIZE = 10

local EventAnnouncer = Class(Widget, function(self, owner)
    Widget._ctor(self, "EventAnnouncer")
    self.messages = {}
    self.timestamp = {}
    self.colours = {}
    
    self.message_font = UIFONT
    self.message_size = 30

    for i = 1,ANNOUNCEMENT_QUEUE_SIZE do
        local message_widget = self:AddChild(Text(self.message_font, self.message_size))
        message_widget:SetVAlign(ANCHOR_TOP)
        message_widget:SetHAlign(ANCHOR_MIDDLE)
        message_widget:SetPosition(0, -15 - (i * (self.message_size+1)))
        message_widget:SetRegionSize(1100, (self.message_size+2) )
        message_widget:SetString("")
        self.messages[i] = message_widget   
        
        self.timestamp[i] = 0
        self.colours[i] = {1,1,1}
    end 
end)

function EventAnnouncer:GetEventAlpha( current_time, announce_time )
    local time_past_expiring = current_time - ( announce_time + ANNOUNCEMENT_LIFETIME ) 
    if time_past_expiring > 0.0 then
        if time_past_expiring < ANNOUNCEMENT_FADE_TIME then
            local alpha_fade = ( ANNOUNCEMENT_FADE_TIME - time_past_expiring ) / ANNOUNCEMENT_FADE_TIME
            return alpha_fade
        end
        return 0.0
    end
    return 1.0          
end

function EventAnnouncer:DoShuffleUp(i)
    if not self.timestamp[i+1] or self.timestamp[i+1] <= 0 then
        self.timestamp[i] = 0
        self.messages[i]:SetString("")
        self.messages[i]:SetColour(1,1,1,1)
        self.colours[i] = {1,1,1}
        return
    else
        self.timestamp[i] = self.timestamp[i+1]
        self.messages[i]:SetString(self.messages[i+1]:GetString())
        local alpha_fade = self:GetEventAlpha( GetTime(), self.timestamp[i] )
        local clr = self.colours[i+1]
        self.colours[i] = {clr[1], clr[2], clr[3]}
        self.messages[i]:SetColour(clr[1], clr[2], clr[3], alpha_fade)

        self:DoShuffleUp(i+1)
    end
end

function EventAnnouncer:OnUpdate() 

    local current_time = GetTime()
    
    for i = 1,ANNOUNCEMENT_QUEUE_SIZE do
        local announce_time = self.timestamp[i]
            
        if announce_time > 0.0 then
            local time_past_expiring = current_time - ( announce_time + ANNOUNCEMENT_LIFETIME ) 
            if time_past_expiring > 0.0 then
                local alpha_fade = self:GetEventAlpha( current_time, announce_time )
                local clr = self.colours[i]
                self.messages[i]:SetColour(clr[1],clr[2],clr[3],alpha_fade)
                if alpha_fade <= 0.0 then
                    -- Get out of here!
                    self.timestamp[i] = 0.0
                    self:DoShuffleUp(i)
                end
            else
                -- No need to keep processing, nothing else past this point will be expired or fading
                return
            end
        end
    end
end

function EventAnnouncer:ShowNewAnnouncement(announcement, colour)
    if not announcement then return end

    -- Shuffle upwards
    if self.timestamp[1] <= 0 then
        self:DoShuffleUp(1)
    end

    --Guarantee that we're fully shuffled
    for i,v in ipairs(self.timestamp) do
        if v <= 0 then
            self:DoShuffleUp(i)
        end
    end

    -- Find the next spot
    local index = -1
    while index == -1 do
		for i = 1,ANNOUNCEMENT_QUEUE_SIZE-1 do
			if self.timestamp[i] <= 0 then
				index = i
				break
			end
		end
		if index == -1 then
			self:DoShuffleUp(1)
		end
	end
    
    -- Add our new entry
    self.messages[index]:SetString(announcement)
    self.timestamp[index] = GetTime()
    if not colour then
        colour = {1,1,1}
    end
    self.messages[index]:SetColour(colour[1],colour[2],colour[3],1)
    self.colours[index] = colour

    self:StartUpdating()
end

-- If source param is provided, then death announcement will be for living > ghost. If not, it will be for ghost/final death.
function GetNewDeathAnnouncementString(theDead, source, pkname)
    if not theDead or not source then return "" end

    local message = ""
    if source and not theDead:HasTag("playerghost") then
        if pkname ~= nil then
            message = theDead:GetDisplayName().." "..STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1.." "..pkname
        elseif table.contains(GetActiveCharacterList(), source) then
            message = theDead:GetDisplayName().." "..STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1.." "..FirstToUpper(source)
        else
            source = string.upper(source)
            if source == "NIL" then
                if theDead == "WAXWELL" then
                    source = "CHARLIE"
                else
                    source = "DARKNESS"
                end
            elseif source == "UNKNOWN" then
                source = "SHENANIGANS"
            elseif source == "MOOSE" then
                if math.random() < .5 then
                    source = "MOOSE1"
                else
                    source = "MOOSE2"
                end
            end
            source = STRINGS.NAMES[source] or STRINGS.NAMES.SHENANIGANS
            message = theDead:GetDisplayName().." "..STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1.." "..source
        end

        if not theDead.ghostenabled then
			message = message.."."
		else
			local gender = GetGenderStrings(theDead.prefab)
			if STRINGS.UI.HUD["DEATH_ANNOUNCEMENT_2_"..gender] then
				message = message..STRINGS.UI.HUD["DEATH_ANNOUNCEMENT_2_"..gender]
			else
				message = message..STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_DEFAULT
			end
		end
    else
        local gender = GetGenderStrings(theDead.prefab)
		if STRINGS.UI.HUD["GHOST_DEATH_ANNOUNCEMENT_"..gender] then
			message = theDead:GetDisplayName().." "..STRINGS.UI.HUD["GHOST_DEATH_ANNOUNCEMENT_"..gender]
		else
			message = theDead:GetDisplayName().." "..STRINGS.UI.HUD.GHOST_DEATH_ANNOUNCEMENT_DEFAULT
		end
    end

	return message
end

function GetNewRezAnnouncementString(theRezzed, source)
    if not theRezzed or not source then return "" end
    local message = theRezzed:GetDisplayName().." "..STRINGS.UI.HUD.REZ_ANNOUNCEMENT.." "..source.."."
	return message
end

return EventAnnouncer