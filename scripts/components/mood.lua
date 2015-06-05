local function OnDayComplete(self)
    if self.daystomoodchange and self.daystomoodchange > 0 then
        self.daystomoodchange = self.daystomoodchange - 1
        self:CheckForMoodChange()
    end
end

local Mood = Class(function(self, inst)
    self.inst = inst
    self.moodtimeindays = {length = nil, wait = nil}
    self.isinmood = false
    self.daystomoodchange = nil
    self.onentermood = nil
    self.onleavemood = nil
    self.moodseasons = {}
    self.firstseasonadded = false

    self:WatchWorldState("cycles", OnDayComplete)
end)

function Mood:GetDebugString()
    return string.format("inmood:%s, days till change:%s", tostring(self.isinmood), tostring(self.daystomoodchange) )
end

function Mood:SetMoodTimeInDays(length, wait)
    self.moodtimeindays.length = length
    self.moodtimeindays.wait = wait
    self.daystomoodchange = wait
    self.isinmood = false
end

local function OnSeasonChange(inst, season)
	local active = false
	if inst.components.mood.moodseasons then 
	    for i, s in pairs(inst.components.mood.moodseasons) do
	        if s == season then
	            active = true
	            break
	        end
	    end
	end
    if active then
        inst.components.mood:SetIsInMood(true, true)
    else
        inst.components.mood:ResetMood()
    end        
end

-- Use this to set the mood correctly (used for making sure the beefalo are mating when the start season is spring)
function Mood:ValidateMood()
	local active = false
	if self.moodseasons then 
	    for i, s in pairs(self.moodseasons) do
	        if s == TheWorld.state.season then
	            active = true
	            break
	        end
	    end
	end
    if active then
        self:SetIsInMood(true, true)
    else
        self:ResetMood()
    end      
end

function Mood:SetMoodSeason(activeseason)
    if not self.moodtimeindays.wait or self.moodtimeindays.wait >= 0 then
        table.insert(self.moodseasons, activeseason)
        if not self.firstseasonadded then
        	self.inst:WatchWorldState("season", OnSeasonChange)
            self.firstseasonadded = true
        end
    end
end

function Mood:CheckForMoodChange()
    if self.daystomoodchange == 0 then
        self:SetIsInMood(not self:IsInMood() )
    end
end

function Mood:SetInMoodFn(fn)
    self.onentermood = fn
end

function Mood:SetLeaveMoodFn(fn)
    self.onleavemood = fn
end

function Mood:ResetMood()
    if self.seasonmood then
        self.seasonmood = false
        self.isinmood = false
        self.daystomoodchange = self.moodtimeindays.wait
        if self.onleavemood then
            self.onleavemood(self.inst)
        end
    end
end

local function GetSeasonLength()
    return TheWorld.state[TheWorld.state.season.."length"]
end

function Mood:SetIsInMood(inmood, entireseason)
    if self.isinmood ~= inmood or entireseason then
    
        self.isinmood = inmood
        if self.isinmood then
            if entireseason then
                self.seasonmood = true
                self.daystomoodchange = GetSeasonLength() or self.moodtimeindays.length
            else
                self.seasonmood = false
                self.daystomoodchange = self.moodtimeindays.length
            end
            if self.onentermood then
                self.onentermood(self.inst)
            end
        else
            if not entireseason then
                self.seasonmood = false
                self.daystomoodchange = self.moodtimeindays.wait
            end
            if self.onleavemood then
                self.onleavemood(self.inst)
            end
        end
    end
end

function Mood:IsInMood()
    return self.isinmood
end

function Mood:OnSave()
    return {inmood = self.isinmood, daysleft = self.daystomoodchange, moodseasons = self.moodseasons }
end

function Mood:OnLoad(data)
	self.moodseasons = data.moodseasons or self.moodseasons
    self.isinmood = not data.inmood
    local active = false
    local season = TheWorld.state.season
    if self.moodseasons then 
	    for i, s in pairs(self.moodseasons) do
	        if season and s == season then
	            active = true
	            break
	        end
	    end
	end
    self:SetIsInMood(data.inmood, active)
    self.daystomoodchange = data.daysleft
end

return Mood
