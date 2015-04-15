local function onmax(self, max)
    self.inst.replica.humanity:SetMax(max)
end

local function oncurrent(self, current)
    self.inst.replica.humanity:SetCurrent(current)
end

local function onhealthpenalty(self, healthpenalty)
    self.inst.replica.humanity:SetHealthPenalty(healthpenalty)
end

local function onhealthpenaltymax(self, healthpenaltymax)
    self.inst.replica.humanity:SetHealthPenaltyMax(healthpenaltymax)
end

local function onpausetime(self, pausetime)
    self.inst.replica.humanity:SetIsPaused(pausetime > 0)
end

local Humanity = Class(function(self, inst)
    self.inst = inst

    self.max = 100
    self.current = 100

    self.health_penalty = 0
    self.health_penalty_max = 100

    self.humanityrate = 1
    self.penaltyrate = 1
    
    self.burnrate = 0--TUNING.GHOST_DECAY_RATE
    
    self.pausetime = 0
    
    self.inst:StartUpdatingComponent(self)
end,
nil,
{
    max = onmax,
    current = oncurrent,
    health_penalty = onhealthpenalty,
    health_penalty_max = onhealthpenaltymax,
    pausetime = onpausetime,
})

function Humanity:OnSave()
    if self.current ~= self.max then
        return {humanity = self.current, penalty = self.health_penalty}
    end
end

function Humanity:OnLoad(data)
    if data.humanity then
        self.current = data.humanity
        self.health_penalty = data.penalty
        self:DoDelta(0, nil, true)
    end
end

function Humanity:IsPaused()
    return self.pausetime > 0
end

function Humanity:GetDebugString()
    return string.format("%2.2f / %2.2f", self.current, self.max)
end

function Humanity:SetMax(amount)
    self.max = amount
    -- self.current = amount
end

function Humanity:IsDeteriorating() 
    return self.current <= 0 and self.health_penalty < self.health_penalty_max
end

function Humanity:DoPause(time, source)
    self.pausetime = time
end

function Humanity:DoDelta(delta, source, overtime, ignore_invincible)

    -- if not ignore_invincible and self.inst.components.health.invincible == true or self.inst.is_teleporting == true then
    --     return
    -- end

	local old = self.current
    local oldhealthpenaltypercent = self:GetHealthPenaltyPercent()

    -- If we're at 0 and the delta is negative, ping off of humanity instead of current
    if old <= 0 and delta < 0 then
        -- subtract 'cause delta is neg and we want the penalty to increase
    	self.health_penalty = math.min(self.health_penalty - delta * self.penaltyrate, self.health_penalty_max)
    	if self.health_penalty >= self.health_penalty_max then 
            self.inst:PushEvent("death")
            self.inst:StopUpdatingComponent(self)
        end
    else
	    self.current = math.min(math.max(0, self.current + delta * self.humanityrate), self.max)
	    if self.current >= self.max then
	        self.inst:PushEvent("respawnfromghost", { source = source })
            self.inst:StopUpdatingComponent(self)
	    end
	end
    
    self.inst:PushEvent("ghostdelta",
    {
        oldpercent = old / self.max,
        newpercent = self:GetPercent(),
        oldhealthpenaltypercent = oldhealthpenaltypercent,
        newhealthpenaltypercent = self:GetHealthPenaltyPercent(),
        overtime = overtime,
    })

    if old > 0 and self.current <= 0 then
        self.inst:PushEvent("startdeteriorating")
        ProfileStatsSet("started_deteriorating", true)
    elseif old <= 0 and self.current > 0 then
        self.inst:PushEvent("stopdeteriorating")
        ProfileStatsSet("stopped_deteriorating", true)
    end
end

--This is not the same as what "penalty" means in health/hunger/sanity
--Humanity itself never has a "penalty"
--Instead, humanity has two values, a humanity value and a health penalty value that
--gets applied back to health upon respawn
function Humanity:GetHealthPenaltyPercent()
    return self.health_penalty / self.health_penalty_max
end

function Humanity:GetPercent()
    return self.current / self.max
end

function Humanity:SetPercent(p)
    local old = self.current
    self.current  = p * self.max
    local healthpenaltypercent = self:GetHealthPenaltyPercent()
    self.inst:PushEvent("ghostdelta",
    {
        oldpercent = old / self.max,
        newpercent = p,
        oldhealthpenaltypercent = healthpenaltypercent,
        newhealthpenaltypercent = healthpenaltypercent,
    })

    if old > 0 and self.current <= 0 then
        self.inst:PushEvent("startdeteriorating")
        ProfileStatsSet("started_deteriorating", true)
    elseif old <= 0 and self.current > 0 then
        self.inst:PushEvent("stopdeteriorating")
        ProfileStatsSet("stopped_deteriorating", true)
    end
end

function Humanity:OnUpdate(dt)
    if self.pausetime > 0 then
        self.pausetime = self.pausetime - dt
        local percent = self:GetPercent()
        local healthpenaltypercent = self:GetHealthPenaltyPercent()
        self.inst:PushEvent("ghostdelta",
        {
            oldpercent = percent,
            newpercent = percent,
            oldhealthpenaltypercent = healthpenaltypercent,
            newhealthpenaltypercent = healthpenaltypercent,
            overtime = true,
        })
    else
        self:DoDelta(-dt * self.burnrate, nil, true)
    end
end

return Humanity