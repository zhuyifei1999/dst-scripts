require "behaviours/standstill"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/panic"
require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/useshield"

local START_FACE_DIST = 4
local KEEP_FACE_DIST = 6
local MAX_CHASE_TIME = 20
local MAX_CHASE_DIST = 16
local WANDER_DIST = 16

local MIN_FOLLOW_DIST = 4
local TARGET_FOLLOW_DIST = 6
local MAX_FOLLOW_DIST = 10

local DAMAGE_UNTIL_SHIELD = 200
local AVOID_PROJECTILE_ATTACKS = true
local SHIELD_TIME = 5

local function GetFaceTargetFn(inst)
    local target = FindClosestPlayerToInst(inst, START_FACE_DIST, true)
    return target ~= nil and not target:HasTag("notarget") and target or nil
end

local function KeepFaceTargetFn(inst, target)
    return not target:HasTarget("notarget") and inst:IsNear(target, KEEP_FACE_DIST)
end

local function CanPickup(inst)
    return item.components.inventoryitem.canbepickedup and item:GetTimeAlive() >= 8 and item:IsOnValidGround()
end

local function EatFoodAction(inst)
    if inst.sg:HasStateTag("busy") then
        return
    end

    if inst.components.inventory ~= nil and inst.components.eater ~= nil then
        local target = inst.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end)
        if target ~= nil then
            return BufferedAction(inst, target, ACTIONS.EAT)
        end
    end

    local target = FindEntity(inst, 15, CanPickup, { "edible_ELEMENTAL", "_inventoryitem" }, { "INLIMBO", "fire", "catchable" })
    if target ~= nil then
        local ba = BufferedAction(inst, target, ACTIONS.PICKUP)
        ba.distance = 1.5
        return ba
    end
end

local RockyBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function RockyBrain:OnStart()
    local root = PriorityNode(
    {
        UseShield(self.inst, DAMAGE_UNTIL_SHIELD, SHIELD_TIME, AVOID_PROJECTILE_ATTACKS),
        WhileNode( function() return self.inst.components.hauntable ~= nil and self.inst.components.hauntable.panic end, "PanicHaunted", Panic(self.inst)),
        ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME), SpringCombatMod(MAX_CHASE_DIST)),
        DoAction(self.inst, EatFoodAction),
        Follow(self.inst, function(inst) return inst.components.follower.leader end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("herd") end, WANDER_DIST)
    }, .25)

    self.bt = BT(self.inst, root)
end

return RockyBrain
