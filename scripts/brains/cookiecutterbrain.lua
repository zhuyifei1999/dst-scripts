require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/leash"
require "behaviours/wander"
require "behaviours/standstill"

local CookieCutterBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local SCATTER_DIST = 5
local SCATTER_STOP = 7

local FLEE_DIST = 15.5
local FLEE_STOP = 14.5 -- Should for now be larger than the longest range weapon

local WANDER_DIST = TUNING.COOKIECUTTER.WANDER_DIST
local WANDER_TIMES = {minwalktime=2.0, randwalktime=4.0, minwaittime=3.0, randwaittime=6.0}

local function EatFoodAction(inst)
	local target = FindEntity(inst, TUNING.COOKIECUTTER.FOOD_DETECTION_DIST, function(item) return inst.components.eater:CanEat(item) end)
	return (target ~= nil and not target:IsOnPassablePoint()
		and (target.components.burnable == nil or not target.components.burnable:IsBurning()))
		and BufferedAction(inst, target, ACTIONS.EAT)
		or nil
end

local function GetTargetBoatPosition(inst)
	return inst.target_boat ~= nil and inst.target_boat:IsValid() and inst.target_boat:GetPosition() or nil
end

local function GetWanderPoint(inst)
	return inst.components.knownlocations:GetLocation("home")
end

local function getdirectionFn(inst)
	local r = math.random()
	return (inst.Transform:GetRotation() + r*r*r * 60 * (math.random() > 0.5 and 1 or -1)) * DEGREES
end

local function getshouldgohomeFn(inst)
	if not inst.sg:HasStateTag("busy")
		and inst:HasTag("swimming") then
			local x, y, z = inst.Transform:GetWorldPosition()
			local homepos = inst.components.knownlocations:GetLocation("home")
			return VecUtil_LengthSq(homepos.x - x, homepos.z - z) >= TUNING.COOKIECUTTER.RETURN_HOME_DISTSQ
	else
		return false
	end
end

function CookieCutterBrain:OnStart()
    local root = PriorityNode(
        {
			WhileNode(function() return self.inst.sg:HasStateTag("drilling") or (self.inst.sg:HasStateTag("hit") and not self.inst:HasTag("swimming")) end, "StandStill", StandStill(self.inst)),

			RunAway(self.inst, "scarytocookiecutters", SCATTER_DIST, SCATTER_STOP),
			WhileNode(function() return self.inst.is_fleeing end, "Fleeing", RunAway(self.inst, "scarytoprey", FLEE_DIST, FLEE_STOP)),

			WhileNode(function() return self.inst.sg.currentstate.name == "run" or self.inst.sg.currentstate.name == "run_end" end, "StandStill", StandStill(self.inst)),

			WhileNode(function() return getshouldgohomeFn(self.inst) end, "GoHome",
				ActionNode(function() self.inst:PushEvent("gohome") end)),

			WhileNode(function() return self.inst.components.eater:HasBeen(TUNING.COOKIECUTTER.EAT_DELAY) end, "Wants To Eat Floating", DoAction(self.inst, EatFoodAction, "Eat Floating", false)),
			
			Leash(self.inst, GetTargetBoatPosition, 0.1, 0.1, false),

			Wander(self.inst, function() return GetWanderPoint(self.inst) end, WANDER_DIST, WANDER_TIMES, getdirectionFn),
        }, .25)

    self.bt = BT(self.inst, root)
end

function CookieCutterBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("home", Point(self.inst.Transform:GetWorldPosition()), true)
end

return CookieCutterBrain
