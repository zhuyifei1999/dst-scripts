local _StopSeeking --forward declare

local function _checkforsaltlick(inst, self)
    local ent = FindEntity(inst, TUNING.SALTLICK_CHECK_DIST, nil, { "saltlick" }, { "INLIMBO", "fire", "burnt" })
    if ent ~= nil then
        if ent.components.finiteuses ~= nil then
            ent.components.finiteuses:Use(1)
        end
        inst.components.timer:StartTimer("salt", self.saltedduration)
        _StopSeeking(self)
        self:SetSalted(true)
        return true
    end
    return false
end

local function _onsaltlickplaced(inst, data)
    if not inst.components.timer:TimerExists("salt") then
        local self = inst.components.saltlicker
        inst.components.timer:StartTimer("salt", self.saltedduration)
        _StopSeeking(self)
        self:SetSalted(true)
    end
end

_StopSeeking = function(self)
    if self._task ~= nil then
        self._task:Cancel()
        self._task = nil
        self.inst:RemoveEventCallback("saltlick_placed", _onsaltlickplaced)
    end
end

local function _StartSeeking(self)
    if self._task ~= nil then
        self._task:Cancel()
    else
        self.inst:ListenForEvent("saltlick_placed", _onsaltlickplaced)
    end
    local period = self.saltedduration * .125 -- = duration / 8
    self._task = self.inst:DoPeriodicTask(period, _checkforsaltlick, math.random() * period, self)
end

local function _ontimerdone(inst, data)
    if data.name == "salt" then
        local self = inst.components.saltlicker
        if inst:IsInLimbo() then
            self:SetSalted(false)
        elseif not _checkforsaltlick(inst, self) then
            _StartSeeking(self)
            self:SetSalted(false)
        end
    end
end

local SaltLicker = Class(function(self, inst)
    self.inst = inst

    assert(inst.components.timer ~= nil, "SaltLicker requires a timer component!")

    --V2C: Recommended to explicitly add tag to prefab pristine state
    inst:AddTag("saltlicker")

    self.salted = false
    self.saltedduration = nil
    self._task = nil
end)

local function OnEnterLimbo(inst)
    _StopSeeking(inst.components.saltlicker)
end

local function OnExitLimbo(inst)
    if not inst.components.timer:TimerExists("salt") then
        _StartSeeking(inst.components.saltlicker)
    end
end

function SaltLicker:SetUp(duration)
    self:Stop()
    self.saltedduration = duration
    if duration ~= nil then
        self.inst:ListenForEvent("timerdone", _ontimerdone)
        self.inst:ListenForEvent("enterlimbo", OnEnterLimbo)
        self.inst:ListenForEvent("exitlimbo", OnExitLimbo)
        if not self.inst:IsInLimbo() then
            OnExitLimbo(self.inst)
        end
    end
end

function SaltLicker:Stop()
    if self.saltedduration ~= nil then
        self.inst:RemoveEventCallback("timerdone", _ontimerdone)
        self.inst:RemoveEventCallback("enterlimbo", OnEnterLimbo)
        self.inst:RemoveEventCallback("exitlimbo", OnExitLimbo)
        _StopSeeking(self)
        self.saltedduration = nil
    end
end

function SaltLicker:OnRemoveFromEntity()
    self:Stop()
    self.inst:RemoveTag("saltlicker")
end

function SaltLicker:SetSalted(salted)
    if self.salted ~= salted then
        self.salted = salted
        self.inst:PushEvent("saltchange", { salted = salted })
    end
end

function SaltLicker:OnLoadPostPass()
    -- the timer's save/load has all the data we need...
    if self.inst.components.timer:TimerExists("salt") then
        _StopSeeking(self)
        self:SetSalted(true)
    end
end

function SaltLicker:GetDebugString()
    return "salted: "..(self.salted and string.format("%2.2f", self.inst.components.timer:GetTimeLeft("salt")) or "--")
        ..", seeking: "..(self._task ~= nil and string.format("%2.2f", self._task:NextTime() - GetTime()) or "--")
        ..", duration: "..tostring(self.saltedduration)
end

return SaltLicker
