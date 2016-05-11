--[[
    PlayerProx component can run in four possible ways
    - Any player within distance, all players outside distance (PlayerProx.AnyPlayer)
    - a specific player within and outside distance (PlayerProx.SpecificPlayer)
    - as soon as a player comes within range, start tracking that one for going out of distance and then relinquish tracking (PlayerProx.LockOnPlayer)
    - as soon as a player comes within range, start tracking that player and keep tracking that player (PlayerProx.LockAndKeepPlayer)
--]]

local function AnyPlayer(inst, self)
    local x, y, z = inst.Transform:GetWorldPosition()
    if not self.isclose then
        local player = FindClosestPlayerInRange(x, y, z, self.near)
        if player ~= nil then
            self.isclose = true
            if self.onnear ~= nil then
                self.onnear(inst, player)
            end
        end
    elseif not IsAnyPlayerInRange(x, y, z, self.far) then
        self.isclose = false
        if self.onfar ~= nil then
            self.onfar(inst)
        end
    end
end

local function SpecificPlayer(inst, self)
    if not self.isclose then
        if self.target:IsNear(inst, self.near) then
            self.isclose = true
            if self.onnear ~= nil then
                self.onnear(inst, self.target)
            end
        end
    elseif not self.target:IsNear(inst, self.far) then
        self.isclose = false
        if self.onfar ~= nil then
            self.onfar(inst)
        end
    end
end

local function LockOnPlayer(inst, self)
    if not self.isclose then
        local x, y, z = inst.Transform:GetWorldPosition()
        local player = FindClosestPlayerInRange(x, y, z, self.near)
        if player ~= nil then
            self.isclose = true
            self:SetTarget(player)
            if self.onnear ~= nil then
                self.onnear(inst, player)
            end
        end
    elseif not self.target:IsNear(inst, self.far) then
        self.isclose = false
        self:SetTarget(nil)
        if self.onfar ~= nil then
            self.onfar(inst)
        end
    end
end

local function LockAndKeepPlayer(inst, self)
    if not self.isclose then
        local x, y, z = inst.Transform:GetWorldPosition()
        local player = FindClosestPlayerInRange(x, y, z, self.near)
        if player ~= nil then
            self.isclose = true
            self:SetTargetMode(SpecificPlayer, player, true)
            if self.onnear ~= nil then
                self.onnear(inst, player)
            end
        end
    else
        -- we should never get here
        assert(false)
    end
end

local function OnTargetLeft(self)
    self:Stop()
    self.target = nil
    if self.initialtargetmode == LockAndKeepPlayer or
        self.initialtargetmode == LockOnPlayer then
        self:SetTargetMode(self.initialtargetmode)
    end 
    if self.losttargetfn ~= nil then
        self.losttargetfn()
    end
end

local PlayerProx = Class(function(self, inst, targetmode, target)
    self.inst = inst
    self.near = 2
    self.far = 3
    self.isclose = false
    self.period = 10 * FRAMES
    self.onnear = nil
    self.onfar = nil
    self.task = nil
    self.target = nil
    self.losttargetfn = nil
    self._ontargetleft = function() OnTargetLeft(self) end

    self:SetTargetMode(targetmode or AnyPlayer, target)
end)

PlayerProx.TargetModes =
{
    AnyPlayer =         AnyPlayer,
    SpecificPlayer =    SpecificPlayer,
    LockOnPlayer =      LockOnPlayer,
    LockAndKeepPlayer = LockAndKeepPlayer,
}

function PlayerProx:GetDebugString()
    return self.isclose and "NEAR" or "FAR"
end

function PlayerProx:SetOnPlayerNear(fn)
    self.onnear = fn
end

function PlayerProx:SetOnPlayerFar(fn)
    self.onfar = fn
end

function PlayerProx:IsPlayerClose()
    return self.isclose
end

function PlayerProx:SetDist(near, far)
    self.near = near
    self.far = far
end

function PlayerProx:SetLostTargetFn(func)
    self.losttargetfn = func
end

function PlayerProx:Schedule()
    self:Stop()
    self.task = self.inst:DoPeriodicTask(self.period, self.targetmode, nil, self)
end

function PlayerProx:ForceUpdate()
    if self.task ~= nil and self.targetmode ~= nil then
        self.targetmode(self.inst, self)
    end
end

function PlayerProx:Stop()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
end

PlayerProx.OnEntityWake = PlayerProx.Schedule
PlayerProx.OnEntitySleep = PlayerProx.Stop
PlayerProx.OnRemoveEntity = PlayerProx.Stop
PlayerProx.OnRemoveFromEntity = PlayerProx.Stop

function PlayerProx:SetTargetMode(mode, target, override)
    if not override then
        self.originaltargetmode = mode
    end
    self.targetmode = mode
    self:SetTarget(target)
    assert(self.targetmode ~= SpecificPlayer or self.target ~= nil)
    self:Schedule()
end

function PlayerProx:SetTarget(target)
    --listen for playerexited instead of ms_playerleft because
    --this component may be used for client side prefabs
    if self.target ~= nil then
        self.inst:RemoveEventCallback("onremove", self._ontargetleft, self.target)
    end
    self.target = target
    if target ~= nil then
        self.inst:ListenForEvent("onremove", self._ontargetleft, target)
    end
end

return PlayerProx
