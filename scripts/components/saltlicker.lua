local function _checkforsaltlick(inst)
    if inst.components.timer:TimerExists("salt") then
        return true
    end

    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, TUNING.SALTLICK_CHECK_DIST, {"saltlick"})
    if #ents > 0 then
        if ents[1].components.finiteuses ~= nil then
            ents[1].components.finiteuses:Use(1)
        end
        inst.components.timer:StartTimer("salt", inst.components.saltlicker.saltedduration)
        inst.components.saltlicker:SetSalted(true)
        return true
    end
    return false
end

local function _ontimerdone(inst, data)
    if data.name == "salt" then
        if not _checkforsaltlick(inst) then
            inst.components.saltlicker:SetSalted(false)
        end
    end
end

local function _onsaltlickplaced(inst, saltlick)
    if not inst.components.timer:TimerExists("salt") then
        inst.components.timer:StartTimer("salt", inst.components.saltlicker.saltedduration)
        inst.components.saltlicker:SetSalted(true)
    end
end

local function _checksalttimer(inst)
    if inst.components.timer:TimerExists("salt") then
        inst.components.saltlicker:SetSalted(true)
    end
end

local SaltLicker = Class(function(self, inst)
    self.inst = inst

    assert(self.inst.components.timer ~= nil, "SaltLicker requires a timer component!")

    self.salted = false
    self.saltedduration = 60

    inst:DoTaskInTime(0, _checksalttimer) -- the timer's save/load has all the data we need...
end)

function SaltLicker:SetUp(duration)
    self.inst:ListenForEvent("saltlick_placed", _onsaltlickplaced)
    self.inst:ListenForEvent("timerdone", _ontimerdone)
    self.saltedduration = duration
    self.inst:DoPeriodicTask(duration/8, _checkforsaltlick, math.random()*duration/8)
end

function SaltLicker:SetSalted(salted)
    local old = self.salted
    self.salted = salted
    if old ~= salted then
        self.inst:PushEvent("saltchange", salted)
    end
end

return SaltLicker
