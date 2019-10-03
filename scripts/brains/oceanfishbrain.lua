require "behaviours/wander"
require "behaviours/leash"
require "behaviours/doaction"
require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/standstill"

local SPLASH_AVOID_DIST = 6
local SPLASH_AVOID_STOP = 10

local MAX_WANDER_DIST = 16
local WANDER_TIMES = {minwalktime=0.25, randwalktime=0.5, minwaittime=0.0, randwaittime=0.0}

local function WanderTarget(inst)
	return inst.components.knownlocations:GetLocation("home")
end

local OceanFishBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function getdirectionFn(inst)
	local r = math.random() * 2 - 1
	return (inst.Transform:GetRotation() + r*r*r * 60) * DEGREES
end

function OceanFishBrain:OnStart()
    local root = PriorityNode(
    {
        RunAway(self.inst, "scarytooceanprey", SPLASH_AVOID_DIST, SPLASH_AVOID_STOP),
		Wander(self.inst, WanderTarget, MAX_WANDER_DIST, WANDER_TIMES, getdirectionFn)
    }, .5)
    
    self.bt = BT(self.inst, root)
end

function OceanFishBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("home", Point(self.inst.Transform:GetWorldPosition()), true)
end

return OceanFishBrain
