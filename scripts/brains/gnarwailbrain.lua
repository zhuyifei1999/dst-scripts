require "behaviours/follow"
require "behaviours/panicandavoid"
require "behaviours/wander"

local MAX_BOAT_FOLLOW_DIST = TUNING.MAX_WALKABLE_PLATFORM_RADIUS + 18
local MIN_BOAT_FOLLOW_DIST = TUNING.MAX_WALKABLE_PLATFORM_RADIUS + 2
local BOAT_TARGET_DISTANCE = TUNING.MAX_WALKABLE_PLATFORM_RADIUS + 4
local FORGET_TARGET_DIST = MAX_BOAT_FOLLOW_DIST + 3
local FORGET_TARGET_DISTSQ = FORGET_TARGET_DIST * FORGET_TARGET_DIST
local MAX_CHASE_TIME = 10

local BOAT_TAGS = {"walkableplatform"}

local function FindBoatToFollow(inst)
    if not inst.followobj or not inst.followobj:IsValid() or inst.followobj:GetPosition():DistSq(inst:GetPosition()) > FORGET_TARGET_DISTSQ then
        inst.followobj = FindEntity(inst, MAX_BOAT_FOLLOW_DIST, nil, BOAT_TAGS)
    end

    return inst.followobj
end

local BOAT_CLOSE_ENOUGH_TO_WANDER_AWAY_DISTANCE = TUNING.GNARWAIL.WANDER_DIST + TUNING.MAX_WALKABLE_PLATFORM_RADIUS
local function GetWanderDirection(inst)
    local closest_boat = FindEntity(inst, BOAT_CLOSE_ENOUGH_TO_WANDER_AWAY_DISTANCE, nil, BOAT_TAGS)
    return (closest_boat ~= nil and (inst:GetAngleToPoint(closest_boat.Transform:GetWorldPosition()) + math.random(110, 250)) % 360)
            or math.random() * 2 * PI
end

local function HasValidWaterTarget(inst)
    -- We pass if we have a target, it's not on valid ground (it's on a boat or the water), and we're not in cooldown.
    local combat = inst.components.combat
    return combat.target ~= nil and not combat.target:IsOnValidGround() and not combat:InCooldown()
end

local function IsValidTurfAtPoint(position)
    local turf_at_position = TheWorld.Map:GetTileAtPoint(position:Get())
    return (turf_at_position == GROUND.OCEAN_ROUGH) or (turf_at_position == GROUND.OCEAN_SWELL)
end

local GnarwailBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function GnarwailBrain:OnStart()
    local root = PriorityNode(
    {
        --Follow(self.inst, FindBoatToFollow, MIN_BOAT_FOLLOW_DIST, BOAT_TARGET_DISTANCE, MAX_BOAT_FOLLOW_DIST, true),
        WhileNode( function() return not inst:IsHornBroken() and HasValidWaterTarget(self.inst) end, "AttackMomentarily",
            ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME), SpringCombatMod(FORGET_TARGET_DIST), 2)
        ),
        WhileNode( function()
                return self.inst:IsHornBroken() and
                    (self.inst.components.combat.target and self.inst.components.combat.target:GetDistanceSqToInst(self.inst) < (FORGET_TARGET_DISTSQ - 100))
                end, "HornBrokenPanicAndAvoid",
            PanicAndAvoid(self.inst, function(i) return i.components.combat.target end, MAX_BOAT_FOLLOW_DIST - 10)
        ),
        WhileNode( function() return HasValidWaterTarget(self.inst) end, "AttackMomentarily",
            ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME), SpringCombatMod(FORGET_TARGET_DISTSQ), 1, nil, true)
        ),
        RunAway(self.inst, {tags=BOAT_TAGS}, MIN_BOAT_FOLLOW_DIST, BOAT_TARGET_DISTANCE, nil, nil, nil, true),
        Wander(self.inst, nil, TUNING.GNARWAIL.WANDER_DIST, nil, GetWanderDirection, nil, IsValidTurfAtPoint),
    },
    0.30)

    self.bt = BT(self.inst, root)
end

return GnarwailBrain
