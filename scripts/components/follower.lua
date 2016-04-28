local function onattacked(inst, data)
    if inst.components.follower.leader == data.attacker then
        inst.components.follower:SetLeader(nil)
    end
end

local function onleader(self, leader)
    self.inst.replica.follower:SetLeader(leader)
end

local Follower = Class(function(self, inst)
    self.inst = inst

    self.leader = nil
    self.targettime = nil
    self.maxfollowtime = nil
    self.canaccepttarget = true
    self.keepdeadleader = nil

    self.inst:ListenForEvent("attacked", onattacked)
    self.OnLeaderRemoved = function()
        self:SetLeader(nil)
    end
end,
nil,
{
    leader = onleader,
})

function Follower:GetDebugString()
    local str = "Following "..tostring(self.leader)
    if self.targettime ~= nil then
        str = str..string.format(" Stop in %2.2fs, %2.2f%%", self.targettime - GetTime(), 100 * self:GetLoyaltyPercent())
    end
    return str
end

function Follower:GetLeader()
    return self.leader
end

local function DoPortNearLeader(inst, self, pos)
    self.porttask = nil
    if inst.Physics ~= nil then
        inst.Physics:Teleport(pos:Get())
    else
        inst.Transform:SetPosition(pos:Get())
    end
end

local function OnEntitySleep(inst)
    local self = inst.components.follower

    if self.porttask ~= nil then
        self.porttask:Cancel()
        self.porttask = nil
    end

    if self.leader == nil or self.leader:IsAsleep() or not inst:IsAsleep() then
        return
    end

    local init_pos = inst:GetPosition()
    local leader_pos = self.leader:GetPosition()

    if distsq(leader_pos, init_pos) > 1600 then
        if inst.components.combat ~= nil then
            inst.components.combat:SetTarget(nil)
        end

        local angle = self.leader:GetAngleToPoint(init_pos)
        local offset = FindWalkableOffset(leader_pos, angle * DEGREES, 30, 10) or Vector3(0, 0, 0)

        --There's a crash if you teleport without the delay
        --V2C: ORLY
        self.porttask = inst:DoTaskInTime(0, DoPortNearLeader, self, leader_pos + offset)
    else
        --Retry later
        self.porttask = inst:DoTaskInTime(3, OnEntitySleep)
    end
end

function Follower:StartLeashing()
    if not self.leashing then
        self.leashing = true
        self.inst:ListenForEvent("entitysleep", OnEntitySleep)
    end
end

function Follower:StopLeashing()
    if self.leashing then
        self.leashing = nil
        self.inst:RemoveEventCallback("entitysleep", OnEntitySleep)
        if self.porttask ~= nil then
            self.porttask:Cancel()
            self.porttask = nil
        end
    end
end

function Follower:SetLeader(inst)
    if self.leader ~= nil and self.leader.components.leader ~= nil then
        self.leader.components.leader:RemoveFollower(self.inst)
    end
    if inst ~= nil and inst.components.leader ~= nil then
        inst.components.leader:AddFollower(self.inst)
    end

    if self.leader ~= nil then
        self.inst:RemoveEventCallback("onremove", self.OnLeaderRemoved, self.leader)
    end
    if inst ~= nil then
        self.inst:ListenForEvent("onremove", self.OnLeaderRemoved, inst)
    end

    self.leader = inst

    if self.leader ~= nil and
        (   self.leader:HasTag("player") or
            --Special case for pets leashed to inventory items
            (   self.leader.components.inventoryitem ~= nil and
                self.leader.components.inventoryitem.owner ~= nil and
                self.leader.components.inventoryitem.owner:HasTag("player")
            )
        ) then
        self:StartLeashing()
    end

    if inst == nil and self.task ~= nil then
        self.task:Cancel()
        self.task = nil
        self:StopLeashing()
    end
end

function Follower:GetLoyaltyPercent()
    if self.targettime ~= nil and self.maxfollowtime ~= nil then
        local timeLeft = math.max(0, self.targettime - GetTime())
        return timeLeft / self.maxfollowtime
    end
    return 0
end

local function stopfollow(inst)
    if inst:IsValid() and inst.components.follower ~= nil then
        inst:PushEvent("loseloyalty", { leader = inst.components.follower.leader })
        inst.components.follower:SetLeader(nil)
    end
end

function Follower:AddLoyaltyTime(time)
    local currentTime = GetTime()
    local timeLeft = self.targettime or 0
    timeLeft = math.max(0, timeLeft - currentTime)
    timeLeft = math.min(self.maxfollowtime or 0, timeLeft + time)

    self.targettime = currentTime + timeLeft

    if self.task ~= nil then
        self.task:Cancel()
    end
    self.task = self.inst:DoTaskInTime(timeLeft, stopfollow)
end

function Follower:StopFollowing()
    if self.inst:IsValid() then
        self.inst:PushEvent("loseloyalty", {leader=self.inst.components.follower.leader})
        self.inst.components.follower:SetLeader(nil)
        self:StopLeashing()
    end
end

function Follower:IsNearLeader(dist)
    return self.leader ~= nil and self.inst:IsNear(self.leader, dist)
end

function Follower:OnSave()
    local time = GetTime()
    return self.targettime ~= nil
        and self.targettime > time
        and { time = math.floor(self.targettime - time) }
        or nil
end

function Follower:OnLoad(data)
    if data.time ~= nil then
        self:AddLoyaltyTime(data.time)
    end
end

function Follower:IsLeaderSame(otherfollower)
    local othercmp = otherfollower.components.follower
    if othercmp == nil or othercmp.leader == nil then
        return false
    elseif othercmp.leader == self.leader then
        return true
    --Special case for pets leashed to inventory items
    elseif othercmp.leader.components.inventoryitem ~= nil and
        othercmp.leader.components.inventoryitem.owner ~= nil and
        othercmp.leader.components.inventoryitem.owner == self.leader then
        return true
    end
    return false
end

function Follower:KeepLeaderOnAttacked()
    self.inst:RemoveEventCallback("attacked", onattacked)
end

function Follower:LongUpdate(dt)
    if self.leader ~= nil and self.task ~= nil and self.targettime ~= nil then
        self.task:Cancel()
        self.task = nil

        local time = GetTime()
        local time_left = self.targettime - GetTime() - dt
        if time_left < 0 then
            self:SetLeader(nil) 
        else
            self.targettime = GetTime() + time_left
            self.task = self.inst:DoTaskInTime(time_left, stopfollow)
        end
    end
end

function Follower:OnRemoveFromEntity()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
    if self.porttask ~= nil then
        self.porttask:Cancel()
        self.porttask = nil
    end
    self.inst:RemoveEventCallback("attacked", onattacked)
    self.inst:RemoveEventCallback("entitysleep", OnEntitySleep)
    if self.leader ~= nil then
        self.inst:RemoveEventCallback("onremove", self.OnLeaderRemoved, self.leader)
    end
end

return Follower
