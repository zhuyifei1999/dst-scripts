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

function Mood:SetIsInMood(inmood)
    if self.isinmood ~= inmood then
    
        self.isinmood = inmood
        if self.isinmood then
            self.daystomoodchange = self.moodtimeindays.length
            if self.onentermood then
                self.onentermood(self.inst)
            end
        else
            self.daystomoodchange = self.moodtimeindays.wait
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
    return {inmood = self.isinmood, daysleft = self.daystomoodchange }
end

function Mood:OnLoad(data)
    self.isinmood = not data.inmood
    self:SetIsInMood(data.inmood)
    self.daystomoodchange = data.daysleft
end

return Mood