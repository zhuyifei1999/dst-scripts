require "behaviours/chaseandattack"
require "behaviours/faceentity"
require "behaviours/wander"

local PHYS_RAD = 1.4
local FLEE_DELAY = 15

local BeeQueenBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    self._act = nil
    self._lastengaged = 0
    self._lastdisengaged = 0
    self._engaged = false
    self._shouldchase = false
end)

local function GetHomePos(inst)
    return inst.components.knownlocations:GetLocation("spawnpoint")
end

local function GetFaceTargetFn(inst)
    return inst.components.combat.target
end

local function KeepFaceTargetFn(inst, target)
    return inst.components.combat:TargetIs(target)
end

local function TryScreech(self)
    if self.inst.components.combat:HasTarget() then
        self._lastengaged = GetTime()
        if not self._engaged and self._lastengaged - self._lastdisengaged > 2 then
            self._engaged = true
            return "screech"
        end
    else
        self._lastdisengaged = GetTime()
        if self._engaged and self._lastdisengaged - self._lastengaged > 5 then
            self._engaged = false
        end
    end
end

local function TrySpawnGuards(inst)
    return not inst.components.timer:TimerExists("spawnguards_cd")
        and inst.components.commander:GetNumSoldiers() < (inst.components.combat:HasTarget() and inst.spawnguards_threshold or 1)
        and "spawnguards"
        or nil
end

local function TryFocusTarget(inst)
    return inst.focustarget_cd > 0
        and inst.components.combat:HasTarget()
        and inst.components.commander:GetNumSoldiers() > 0
        and not inst.components.timer:TimerExists("focustarget_cd")
        and "focustarget"
        or nil
end

local function ShouldUseSpecialMove(self)
    self._act = TryScreech(self) or TrySpawnGuards(self.inst) or TryFocusTarget(self.inst)
    if self._act ~= nil then
        self._shouldchase = false
        return true
    end
    return false
end

local function ShouldChase(self)
    if self.inst.focustarget_cd <= 0 then
        return true
    elseif self.inst.components.combat.target == nil or not self.inst.components.combat.target:IsValid() then
        self._shouldchase = false
        return false
    end
    local distsq = self.inst:GetDistanceSqToInst(self.inst.components.combat.target)
    local range = TUNING.BEEQUEEN_CHASE_TO_RANGE + (self._shouldchase and 0 or 3)
    self._shouldchase = distsq >= range * range
    if self._shouldchase then
        return true
    elseif self.inst.components.combat:InCooldown() then
        return false
    end
    range = TUNING.BEEQUEEN_ATTACK_RANGE + PHYS_RAD
    return distsq <= range * range
end

function BeeQueenBrain:OnStart()
    local root = PriorityNode(
    {
        WhileNode(function() return ShouldUseSpecialMove(self) end, "SpecialMoves",
            ActionNode(function() self.inst:PushEvent(self._act) end)),
        WhileNode(function() return ShouldChase(self) end, "Chase",
            ChaseAndAttack(self.inst)),
        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
        ParallelNode{
            SequenceNode{
                WaitNode(FLEE_DELAY),
                ActionNode(function() self.inst:PushEvent("flee") end),
            },
            Wander(self.inst, GetHomePos, 5),
        },
    }, 1)

    self.bt = BT(self.inst, root)
end

function BeeQueenBrain:OnInitializationComplete()
    local pos = self.inst:GetPosition()
    pos.y = 0
    self.inst.components.knownlocations:RememberLocation("spawnpoint", pos, true)
end

return BeeQueenBrain
