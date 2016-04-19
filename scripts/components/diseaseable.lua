--Disease: -delay till you become "diseased", usually a build swap
--         -another dealy till you die from disease, usually removed
--         -rebirth triggers when spawned in for a species becoming active again

local function ondiseased(self, diseased)
    if diseased then
        self.inst:AddTag("diseased")
    else
        self.inst:RemoveTag("diseased")
    end
end

local Diseaseable = Class(function(self, inst)
    self.inst = inst

    self.task = nil
    self.fxtask = nil
    self.lastfx = 0
    self.diseased = false
    self.defaultDelayMin = TUNING.SEG_TIME
    self.defaultDelayMax = TUNING.TOTAL_DAY_TIME
    self.defaultDeathTimeMin = TUNING.SEG_TIME
    self.defaultDeathTimeMax = TUNING.TOTAL_DAY_TIME
    self.onDiseasedFn = nil
    self.onDiseasedDeathFn = nil
    self.onRebirthedFn = nil

    TheWorld:PushEvent("ms_registerdiseaseable", inst)
end,
nil,
{
    diseased = ondiseased,
})

function Diseaseable:OnRemoveFromEntity()
    if not self.diseased then
        TheWorld:PushEvent("ms_unregisterdiseaseable", self.inst)
    end
    if self.fxtask ~= nil then
        self.fxtask:Cancel()
        self.fxtask = nil
    end
    self:Stop()
    self.inst:RemoveTag("diseased")
end

function Diseaseable:IsDiseased()
    return self.diseased
end

local function DoFX(inst, self)
    local loops = 0
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 8, { "diseased" })
    local num = 1
    local time = GetTime()
    for i, v in ipairs(ents) do
        if v ~= inst and
            v.components.diseaseable ~= nil and
            v.components.diseaseable.lastfx < time then
            num = num + 1
        end
    end
    if math.random(num) == 1 then
        loops = math.random(3, 7) --limit to net_tinybyte!
        self.lastfx = GetTime() + (loops * 100 + 35) * FRAMES
        local fx = SpawnPrefab("diseaseflies")
        fx.entity:SetParent(inst.entity)
        fx:SetLoops(loops)
    end
    self.fxtask = inst:DoTaskInTime(loops * 100 * FRAMES + 5 + math.random() * 3, DoFX, self)
end

function Diseaseable:ForceDiseased(deathTimeMin, deathTimeMax)
    if not self.diseased then
        self.diseased = true
        self:Stop()
        self:StartDeathTime(deathTimeMin, deathTimeMax)
        if self.fxtask == nil then
            self.fxtask = self.inst:DoTaskInTime(math.random(), DoFX, self)
        end
        if self.onDiseasedFn ~= nil then
            self.onDiseasedFn(self.inst)
        end
    end
end

function Diseaseable:ForceDeath()
    self:ForceDiseased()
    self:Stop()
    if self.onDiseasedDeathFn ~= nil then
        self.onDiseasedDeathFn(self.inst)
    else
        self.inst:Remove()
    end
end

--Should only be called by prefabswapmanager for notification
--of things newly spawned in after prefab swap just occurred.
function Diseaseable:OnRebirth()
    if self.onRebirthedFn ~= nil then
        self.onRebirthedFn(self.inst)
    end
end

function Diseaseable:Start()
    if self.task == nil then
        if self.diseased then
            self:StartDeathTime()
        else
            self:StartDiseaseTime()
        end
    end
end

function Diseaseable:Stop()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
end

local function OnDiseaseTime(inst, self)
    self.task = nil
    self:ForceDiseased()
end

function Diseaseable:StartDiseaseTime(min, max)
    if not self.diseased and self.task == nil then
        local delay = GetRandomMinMax(min or self.defaultDelayMin, max or min or self.defaultDelayMax)
        self.task = self.inst:DoTaskInTime(delay, OnDiseaseTime, self)
    end
end

local function OnDeathTime(inst, self)
    self.task = nil
    self:ForceDeath()
end

function Diseaseable:StartDeathTime(min, max)
    if self.diseased and self.task == nil then
        local delay = GetRandomMinMax(min or self.defaultDeathTimeMin, max or min or self.defaultDeathTimeMax)
        self.task = self.inst:DoTaskInTime(delay, OnDeathTime, self)
    end
end

function Diseaseable:SetDefaultDelayRange(min, max)
    self.defaultDelayMin = math.max(0, min)
    self.defaultDelayMax = max ~= nil and math.max(max, self.defaultDelayMin) or self.defaultDelayMin
end

function Diseaseable:SetDefaultDeathTimeRange(min, max)
    self.defaultDeathTimeMin = math.max(0, min)
    self.defaultDeathTimeMax = max ~= nil and math.max(max, self.defaultDeathTimeMin) or self.defaultDeathTimeMin
end

function Diseaseable:SetDiseasedFn(fn)
    self.onDiseasedFn = fn
end

function Diseaseable:SetDiseasedDeathFn(fn)
    self.onDiseasedDeathFn = fn
end

function Diseaseable:SetRebirthedFn(fn)
    self.onRebirthedFn = fn
end

function Diseaseable:OnSave()
    local data =
    {
        diseased = self.diseased or nil,
        remainingtime = self.task ~= nil and GetTaskRemaining(self.task) or nil,
    }
    return next(data) ~= nil and data or nil
end

function Diseaseable:OnLoad(data)
    if data ~= nil then
        if data.diseased then
            if not self.diseased then
                self:ForceDiseased(data.remainingtime)
            elseif data.remainingtime ~= nil then
                self:Stop()
                self:StartDeathTime(data.remainingtime)
            end
        elseif data.remainingtime ~= nil and not self.diseased then
            self:Stop()
            self:StartDiseaseTime(data.remainingtime)
        end
    end
end

function Diseaseable:LongUpdate(dt)
    if self.task ~= nil and dt > 0 then
        local remaining = GetTaskRemaining(self.task)
        self:Stop()
        if remaining > dt then
            if self.diseased then
                self:StartDeathTime(remaining - dt)
            else
                self:StartDiseaseTime(remaining - dt)
            end
        elseif self.diseased then
            OnDeathTime(self.inst, self)
        else
            self:ForceDiseased()
            self:LongUpdate(dt - remaining)
        end
    end
end

function Diseaseable:GetDebugString()
    local s = "diseased: "..tostring(self.diseased)
    if self.task ~= nil then
        s = s..string.format(", time to %s: %2.2f", self.diseased and "death" or "disease", GetTaskRemaining(self.task))
    end
    return s
end

return Diseaseable
