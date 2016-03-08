local function OnUsedTouchStoneID(self, id)
    if id > 0 then
        self.used[id] = true
        if self.inst.player_classified ~= nil then
            local used = {}
            for k, v in pairs(self.used) do
                table.insert(used, k)
            end
            self.inst.player_classified:SetUsedTouchStones(used)
        end
    end
end

local function OnUsedTouchStone(inst, touchstone)
    OnUsedTouchStoneID(inst.components.touchstonetracker, touchstone:GetTouchStoneID())
end

local TouchStoneTracker = Class(function(self, inst)
    self.inst = inst
    self.used = {}
    inst:ListenForEvent("usedtouchstone", OnUsedTouchStone)
end)

function TouchStoneTracker:OnRemoveFromEntity()
    self.inst.player_classified:SetUsedTouchStones({})
    self.inst:RemoveEventCallback("usedtouchstone", OnUsedTouchStone)
end

function TouchStoneTracker:GetDebugString()
    local str = ""
    for k, v in pairs(self.used) do
        str = (#str <= 0 and "Used: " or (str..", "))..tostring(k)
    end
    return str
end

function TouchStoneTracker:IsUsed(touchstone)
    return self.used[touchstone:GetTouchStoneID()] == true
end

function TouchStoneTracker:OnSave()
    if next(self.used) == nil then
        return
    end

    local used = {}
    for k, v in pairs(self.used) do
        table.insert(used, k)
    end

    return { used = used }
end

function TouchStoneTracker:OnLoad(data)
    if data ~= nil and data.used ~= nil then
        for i, v in ipairs(data.used) do
            OnUsedTouchStoneID(self, v)
        end
    end
end

return TouchStoneTracker
