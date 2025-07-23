local LunarHailBuildup = Class(function(self, inst)
    self.inst = inst

    self.buildupmax = 1
    self.buildupcurrent = 0
    self.workleft = 0
    self.totalworkamount = TUNING.LUNARHAIL_BUILDUP_TOTAL_WORK_AMOUNT_DEFAULT
    self.moonglassamount = TUNING.LUNARHAIL_BUILDUP_MOONGLASS_AMOUNT_DEFAULT
    --self.ignorelunarhailticks = nil

    self:WatchWorldState("islunarhailing", self.OnIsLunarHailing)
    self.inst:DoTaskInTime(0, function() -- NOTES(JBK): LoadPostPass without regard to save data.
        self:OnIsLunarHailing(TheWorld.state.islunarhailing)
    end)
end)


function LunarHailBuildup:OnRemoveFromEntity()
    if self.lunarhailbuildup_task ~= nil then
        self.lunarhailbuildup_task:Cancel()
        self.lunarhailbuildup_task = nil
    end
    self.inst:RemoveTag("LunarBuildup")
end


function LunarHailBuildup:SetOnStartIsLunarHailingFn(fn)
    self.onstartislunarhailingfn = fn
end

function LunarHailBuildup:SetOnStopIsLunarHailingFn(fn)
    self.onstopislunarhailingfn = fn
end

function LunarHailBuildup:IsBuildupWorkable()
    return self.workleft > 0
end

function LunarHailBuildup:SetTotalWorkAmount(totalworkamount)
    self.totalworkamount = totalworkamount
end

function LunarHailBuildup:SetMoonGlassAmount(moonglassamount)
    self.moonglassamount = moonglassamount
end

function LunarHailBuildup:GetBuildupPercent()
    return self.buildupcurrent / self.buildupmax
end

function LunarHailBuildup:SetBuildupPercent(percent)
    self:DoBuildupDelta(self.buildupmax * percent - self.buildupcurrent)
end

function LunarHailBuildup:SetIgnoreLunarHailTicks(ignorelunarhailticks)
    if self.ignorelunarhailticks == ignorelunarhailticks then
        return
    end
    
    if self.lunarhailbuildup_task ~= nil then
        if ignorelunarhailticks then
            if self.onstopislunarhailingfn then
                self.onstopislunarhailingfn(self.inst)
            end
        else
            if self.onstartislunarhailingfn then
                self.onstartislunarhailingfn(self.inst)
            end
        end
    end
    self.ignorelunarhailticks = ignorelunarhailticks
end



local function DoLunarHailTick(inst, self)
    if inst.components.rainimmunity ~= nil or self.ignorelunarhailticks then
        return
    end

    local rate = TUNING.LUNARHAIL_BUILDUP_RATE -- This could take into account the lunar hail precipitation rate CalculateLunarHailRate for more accuracy.
    local amount = TUNING.LUNARHAIL_BUILDUP_TICK_TIME * rate

    self:DoBuildupDelta(amount)
end



function LunarHailBuildup:OnIsLunarHailing(islunarhailing)
    if islunarhailing then
        if self.lunarhailbuildup_task == nil then
            self.lunarhailbuildup_task = self.inst:DoPeriodicTask(TUNING.LUNARHAIL_BUILDUP_TICK_TIME, DoLunarHailTick, math.random() * TUNING.LUNARHAIL_BUILDUP_TICK_TIME, self)
        end
        if self.onstartislunarhailingfn then
            self.onstartislunarhailingfn(self.inst)
        end
    elseif self.lunarhailbuildup_task ~= nil then
        self.lunarhailbuildup_task:Cancel()
        self.lunarhailbuildup_task = nil
        if self.onstopislunarhailingfn then
            self.onstopislunarhailingfn(self.inst)
        end
    end
end



function LunarHailBuildup:DoWorkToRemoveBuildup(workcount)
    self.workleft = math.clamp(self.workleft - workcount, 0, self.totalworkamount)
    if self.workleft == 0 then
        self:DropRewards()
        self:OnWorkFinished()
    end
end



function LunarHailBuildup:DropRewards(mult)
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local launchspeed = math.max(self.inst:GetPhysicsRadius(0), 2)
    local todropcount = math.floor(self.moonglassamount * (mult or 1))
    for i = 1, todropcount do
        local moonglass = SpawnPrefab("moonglass")
        moonglass.Transform:SetPosition(x, y, z)
        Launch(moonglass, self.inst, launchspeed)
    end
end


LunarHailBuildup.OnWorked_Bridge = function(inst, data)
    if data and data.workleft and data.workleft == 0 then
        local lunarhailbuildup = inst.components.lunarhailbuildup
        if lunarhailbuildup then
            lunarhailbuildup:DropRewards(TUNING.LUNARHAIL_BUILDUP_MOONGLASS_REWARDS_DESTRUCTION_MULT)
            lunarhailbuildup:OnWorkFinished()
        end
    end
end


function LunarHailBuildup:OnWorkFinished()
    self.inst:RemoveEventCallback("worked", self.OnWorked_Bridge)
    self.workleft = 0
    self.inst:RemoveTag("LunarBuildup")
    if self.inst:IsValid() then
        self:DoBuildupDelta(-self.buildupcurrent)
    end
end


function LunarHailBuildup:WorkInit()
    self.workleft = self.totalworkamount
    self.inst:AddTag("LunarBuildup")
    self.inst:ListenForEvent("worked", self.OnWorked_Bridge)
end


function LunarHailBuildup:DoBuildupDelta(delta)
    local oldbuildup = self.buildupcurrent
    local buildupcurrent = math.clamp(self.buildupcurrent + delta, 0, self.buildupmax)

    if oldbuildup ~= buildupcurrent then
        self.buildupcurrent = buildupcurrent
        if buildupcurrent > oldbuildup then
            if buildupcurrent == self.buildupmax and self.workleft == 0 then
                self:WorkInit()
            end
        else
            if buildupcurrent == 0 and self.workleft > 0 then
                -- No rewards for passive buildup removal.
                self:OnWorkFinished()
            end
        end
        if self.inst:IsValid() then
            self.inst:PushEvent("lunarhailbuildupdelta", { oldpercent = oldbuildup / self.buildupmax, newpercent = self.buildupcurrent / self.buildupmax, })
        end
    end
end



function LunarHailBuildup:OnSave()
    local data = {}
    if self.workleft > 0 then
        data.workleft = self.workleft
    end
    if self.buildupcurrent > 0 then
        data.buildupcurrent = self.buildupcurrent
    end
    return data
end

function LunarHailBuildup:OnLoad(data)
    if data ~= nil then
        if data.workleft ~= nil then
            self:WorkInit()
            self.workleft = data.workleft
        end
        if data.buildupcurrent ~= nil and data.buildupcurrent ~= self.buildupcurrent then
            self:DoBuildupDelta(data.buildupcurrent - self.buildupcurrent)
        end
    end
end



function LunarHailBuildup:GetDebugString()
    return string.format("Buildup: %2.2f / %2.2f, Workleft: %d", self.buildupcurrent, self.buildupmax, self.workleft)
end

return LunarHailBuildup
