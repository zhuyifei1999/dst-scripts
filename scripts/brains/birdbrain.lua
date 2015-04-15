local SEE_PLAYER_DIST = 5


local BirdBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)



local function ShouldFlyAway(inst)
    local busy = inst.sg:HasStateTag("sleeping") or inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("flying")
    if not busy then
        local threat = FindEntity(inst, 5, nil, nil, {'notarget'}, {'player', 'monster', 'scarytoprey'})
        return threat ~= nil or TheWorld.state.isnight
    end
end

local function FlyAway(inst)
    inst:PushEvent("flyaway")
end

function BirdBrain:OnStart()
    local root = PriorityNode(
    {
        WhileNode( function() return self.inst.components.hauntable and self.inst.components.hauntable.panic end, "PanicHaunted", Panic(self.inst)),
        IfNode(function() return ShouldFlyAway(self.inst) end, "Threat Near",
            ActionNode(function() return FlyAway(self.inst) end)),
        EventNode(self.inst, "gohome", 
            ActionNode(function() return FlyAway(self.inst) end)),
    }, .25)
    
    self.bt = BT(self.inst, root)
end

return BirdBrain