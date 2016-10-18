
require "behaviours/findclosest"
require "behaviours/panic"
require "behaviours/standstill"

local SEE_LIGHT_DIST = 50

local StagehandBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function SafeLightDist(inst, target)
    return (target:HasTag("player") or target:HasTag("playerlight")
            or (target.inventoryitem and target.inventoryitem:GetGrandOwner() and target.inventoryitem:GetGrandOwner():HasTag("player")))
        and 4
        or target.Light and target.Light:GetCalculatedRadius()
        or 4
end

function StagehandBrain:OnStart()
    local root =
        PriorityNode(
        {
            WhileNode( function() return self.inst.components.hauntable and self.inst.components.hauntable.panic end, "PanicHaunted", Panic(self.inst)),
            WhileNode( function() return (self.inst:CanStandUp()) and TheWorld.state.isnight end, "IsNight",
				FindClosest(self.inst, SEE_LIGHT_DIST, SafeLightDist, {"fire"}, nil, {"campfire", "lighter"})
				),
            StandStill(self.inst)
        },1)
    
    
    self.bt = BT(self.inst, root)
    
end


return StagehandBrain
