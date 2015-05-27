require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/panic"
require "behaviours/follow"
require "behaviours/attackwall"
--require "behaviours/runaway"
--require "behaviours/doaction"

local STOP_RUN_DIST = 10
local SEE_PLAYER_DIST = 5
local WANDER_DIST_DAY = 20
local WANDER_DIST_NIGHT = 5
local START_FACE_DIST = 4
local KEEP_FACE_DIST = 6

local MAX_CHASE_TIME = 6

local MIN_FOLLOW_DIST = 1
local TARGET_FOLLOW_DIST = 5
local MAX_FOLLOW_DIST = 5

local function GetFaceTargetFn(inst)
    local target = FindClosestPlayerToInst(inst, START_FACE_DIST, true)
    return target ~= nil and not target:HasTag("notarget") and target or nil
end

local function KeepFaceTargetFn(inst, target)
    return inst ~= nil
        and target ~= nil
        and inst:IsValid()
        and target:IsValid()
        and not (target:HasTag("notarget") or
                target:HasTag("playerghost"))
        and inst:IsNear(target, KEEP_FACE_DIST)
end

local function GetWanderDistFn(inst)
    return TheWorld.state.isday and WANDER_DIST_DAY or WANDER_DIST_NIGHT
end

local BeefaloBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function BeefaloBrain:OnStart()
    local root = PriorityNode(
    {
        WhileNode(function() return self.inst.components.hauntable ~= nil and self.inst.components.hauntable.panic end, "PanicHaunted", Panic(self.inst)),
        WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),
        IfNode(function() return self.inst.components.combat.target ~= nil end, "hastarget", AttackWall(self.inst)),
        ChaseAndAttack(self.inst, MAX_CHASE_TIME),
        Follow(self.inst, function() return self.inst.components.follower ~= nil and self.inst.components.follower.leader or nil end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST, false),
        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("herd") end, GetWanderDistFn)
    }, .25)

    self.bt = BT(self.inst, root)
end

return BeefaloBrain
