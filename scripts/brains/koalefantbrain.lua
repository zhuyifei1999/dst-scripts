require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/panic"
require "behaviours/runaway"

local MAX_CHASE_TIME = 6
local WANDER_DIST_DAY = 20
local WANDER_DIST_NIGHT = 5

local RUN_AWAY_DIST = 6
local STOP_RUN_AWAY_DIST = 12
local START_FACE_DIST = 14
local KEEP_FACE_DIST = 20

local function GetFaceTargetFn(inst)
    local target = FindClosestPlayerToInst(inst, START_FACE_DIST, true)
    return target ~= nil and not target:HasTag("notarget") and target or nil
end

local function KeepFaceTargetFn(inst, target)
    return not target:HasTag("notarget") and inst:IsNear(target, KEEP_FACE_DIST)
end

local function ShouldRunAway(guy)
    return guy:HasTag("character") and not guy:HasTag("notarget")
end

local function CheckForSaltlick(inst)
    local lick = FindEntity(inst, TUNING.SALTLICK_CHECK_DIST, nil, { "saltlick" }, { "INLIMBO", "fire", "burnt" })
    if lick ~= nil then
        inst.components.knownlocations:RememberLocation("saltlick", lick:GetPosition())
        return true
    else
        inst.components.knownlocations:ForgetLocation("saltlick")
        return false
    end
end

local KoalefantBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function KoalefantBrain:OnStart()
    local root = PriorityNode(
    {
        WhileNode(function() return self.inst.components.hauntable ~= nil and self.inst.components.hauntable.panic end, "PanicHaunted", Panic(self.inst)),
        WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),
        ChaseAndAttack(self.inst, MAX_CHASE_TIME),
        SequenceNode{
            FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn, 0.5),
            RunAway(self.inst, ShouldRunAway, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST)
        },
        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
        IfNode(function() return CheckForSaltlick(self.inst) end, "Stay Near Salt",
            Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("saltlick") end, WANDER_DIST_DAY)),
        Wander(self.inst)
    }, .25)

    self.bt = BT(self.inst, root)
end

return KoalefantBrain
