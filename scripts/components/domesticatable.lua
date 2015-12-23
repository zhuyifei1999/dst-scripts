local easing = require("easing")

local DECAY_TASK_PERIOD = 10
-- TODO: Make these configurable from the prefab
local OBEDIENCE_DECAY_RATE = -1/(TUNING.TOTAL_DAY_TIME * 2)
local FEEDBACK_DECAY_RATE = -1/(TUNING.TOTAL_DAY_TIME * 45)

local Domesticatable = Class(function(self, inst)
    self.inst = inst

    -- I feel like it would be much cleaner to break domestication and obedience into two components, but they
    -- use a lot of the same hooks so I'm keeping them together for now.
    self.domesticated = false

    --V2C: Recommended to explicitly add tag to prefab pristine state
    inst:AddTag("domesticatable")

    self.domestication = 0
    self.domestication_latch = false

    self.obedience = 0
    self.minobedience = 0
    self.maxobedience = 1

    self.tendencies = {}

    self.decaytask = nil
end
)

function Domesticatable:GetObedience()
    return self.obedience
end

function Domesticatable:Validate()
    if not self.domesticated and self.domestication >= 1.0 then
        self.domestication_latch = true
        self.domestication = 1.0
    elseif self.domestication < 0.95 then
        self.domestication_latch = false
    end

    if self.inst.components.hunger:GetPercent() <= 0 and self.domestication <= 0 then
        self.tendencies = {}
        if self.domesticated then
            self:SetDomesticated(false)
            self.inst:PushEvent("goneferal")
        end
    end

    if self.obedience <= self.minobedience
        and self.inst.components.hunger:GetPercent() <= 0 and self.domestication <= 0 then
        self:CancelTask()
        return false
    end

    return true
end

function Domesticatable:BecomeDomesticated()
    self.domestication_latch = false
    self:SetDomesticated(true)
    self.inst:PushEvent("domesticated", {tendencies=self.tendencies})
end

local function DoDecay(inst)
    local self = inst.components.domesticatable
    for k,v in pairs(self.tendencies) do
        self.tendencies[k] = math.max(v + FEEDBACK_DECAY_RATE * DECAY_TASK_PERIOD, 0)
    end

    self:DeltaObedience(OBEDIENCE_DECAY_RATE * DECAY_TASK_PERIOD)

    self:Validate()
end

function Domesticatable:DeltaObedience(delta)
    local old = self.obedience
    self.obedience = math.max(math.min(self.obedience + delta, self.maxobedience), self.minobedience)
    if old ~= self.obedience then
        self.inst:PushEvent("obediencedelta", {old=old, new=self.obedience})
    end
    self:CheckAndStartTask()
end

function Domesticatable:DeltaDomestication(delta)
    local old = self.domestication
    self.domestication = math.max(math.min(self.domestication + delta, 1), 0)

    self.maxobedience = Lerp(0.49, 1.0, self.domestication)

    if old ~= self.domestication then
        self.inst:PushEvent("domesticationdelta", {old=old, new=self.domestication})
        self:CheckAndStartTask()
    end
end

function Domesticatable:DeltaTendency(tendency, delta)
    if self.tendencies[tendency] == nil then
        self.tendencies[tendency] = delta
    else
        self.tendencies[tendency] = self.tendencies[tendency] + delta
    end
end

function Domesticatable:TryBecomeDomesticated()
    if self.domestication_latch then
        self:BecomeDomesticated()
    end
end

function Domesticatable:CancelTask()
    if self.decaytask ~= nil then
        self.decaytask:Cancel()
        self.decaytask = nil
    end
end

function Domesticatable:CheckAndStartTask()
    if not self:Validate() then
        return
    end
    if self.decaytask ~= nil then
        return
    end
    self.decaytask = self.inst:DoPeriodicTask(DECAY_TASK_PERIOD, DoDecay)
end

function Domesticatable:SetDomesticated(domesticated)
    self.domesticated = domesticated
    self:Validate()
end

function Domesticatable:IsDomesticated()
    return self.domesticated
end

function Domesticatable:SetMinObedience(min)
    self.minobedience = min
    if self.obedience < min then
        self:DeltaObedience(min - self.obedience)
    end
    self:CheckAndStartTask()
end

function Domesticatable:OnSave()
    return {
        domestication = self.domestication,
        tendencies = self.tendencies,
        domestication_latch = self.domestication_latch,
        domesticated = self.domesticated,
        obedience = self.obedience,
        minobedience = self.minobedience,
        --V2C: domesticatable MUST load b4 rideable, and we
        --     aren't using the usual OnLoadPostPass method
        --     so... we did this! lol...
        rideable = self.inst.components.rideable ~= nil and self.inst.components.rideable:OnSaveDomesticatable() or nil,
    }
end

function Domesticatable:OnLoad(data)
    if data ~= nil then
        self.domestication = data.domestication or self.domestication
        self.tendencies = data.tendencies or self.tendencies
        self.domestication_latch = data.domestication_latch or false
        self:SetDomesticated(data.domesticated or false)
        self.obedience = 0
        self:DeltaObedience(data.obedience or 0)
        self:SetMinObedience(data.minobedience or 0)
        --V2C: see above comment in OnSave
        if self.inst.components.rideable ~= nil then
            self.inst.components.rideable:OnLoadDomesticatable(data.rideable)
        end
    end
    self:CheckAndStartTask()
end

function Domesticatable:GetDebugString()
    local s = string.format("%s %.3f%% %s obedience: %.2f/%.3f/%.2f ",
        self.domesticated and "DOMO" or "FERAL",
        self.domestication * 100, self.decaytask ~= nil and (GetTime() % 2 < 1 and " ." or ". ") or "..",
        self.minobedience, self.obedience, self.maxobedience
        )
    for k,v in pairs(self.tendencies) do
        s = s .. string.format(" %s:%.2f", k, v)
    end
    s = s .. string.format(" latch: %s", self.domestication_latch and "true" or "false")
    return s
end

return Domesticatable
