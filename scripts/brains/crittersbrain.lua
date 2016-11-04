require "behaviours/follow"
require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/panic"


local MIN_FOLLOW_DIST = 0
local TARGET_FOLLOW_DIST = 3
local MAX_FOLLOW_DIST = 4

local COMBAT_MIN_FOLLOW_DIST = 8
local COMBAT_TARGET_FOLLOW_DIST = 12
local COMBAT_MAX_FOLLOW_DIST = 15

local MAX_WANDER_DIST = 3

local function GetOwner(inst)
    return inst.components.follower.leader
end

local function OwnerIsClose(inst)
    local owner = GetOwner(inst)
    return owner ~= nil and owner:IsNear(inst, TARGET_FOLLOW_DIST)
end

local function KeepFaceTargetFn(inst, target)
    return inst.components.follower.leader == target
end

local function LoveOwner(inst)
    if inst.sg:HasStateTag("busy") then
        return nil
    end

    local owner = GetOwner(inst)
    return owner ~= nil
		and not owner:HasTag("playerghost")
        and math.random() < 0.1
        and BufferedAction(inst, owner, ACTIONS.NUZZLE)
        or nil
end

local function IsNearCombat(inst)
	return inst.AvoidCombatCheck and inst:AvoidCombatCheck()
end


local CritterBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)


function CritterBrain:OnStart()
    local root = 
    PriorityNode({
        --WhileNode( function() return self.inst.components.hauntable and self.inst.components.hauntable.panic end, "PanicHaunted", Panic(self.inst)),

        WhileNode( function() return self.inst.components.follower.leader end, "Has Owner",
			PriorityNode{			
				WhileNode( function() return IsNearCombat(self.inst) end, "Is Near Combat",
					PriorityNode{
						Follow(self.inst, function() return self.inst.components.follower.leader end, COMBAT_MIN_FOLLOW_DIST, COMBAT_TARGET_FOLLOW_DIST, COMBAT_MAX_FOLLOW_DIST),
						FaceEntity(self.inst, GetOwner, KeepFaceTargetFn),
					}),
				
				Follow(self.inst, function() return self.inst.components.follower.leader end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
		        FailIfRunningDecorator(FaceEntity(self.inst, GetOwner, KeepFaceTargetFn)),
				WhileNode(function() return OwnerIsClose(self.inst) end, "Owner Is Close",
					SequenceNode{
						WaitNode(4),
						DoAction(self.inst, LoveOwner),
					}),
				StandStill(self.inst),
			}),

        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST),
    }, .25)
    self.bt = BT(self.inst, root)
end

return CritterBrain