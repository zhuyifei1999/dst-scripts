require "behaviours/chaseandattack"
require "behaviours/wander"

local StalkerBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    self.snaretargets = nil
end)

local function ShouldSnare(self)
    if self.inst.components.combat:HasTarget() and not self.inst.components.timer:TimerExists("snare_cd") then
        self.snaretargets = self.inst:FindSnareTargets()
        if self.snaretargets ~= nil then
            return true
        end
        self.inst.components.timer:StartTimer("snare_cd", TUNING.STALKER_FIRST_SNARE_CD)
    end
    self.snaretargets = nil
    return false
end

function StalkerBrain:OnStart()
    local root = PriorityNode({
        WhileNode(function() return ShouldSnare(self) end, "FossilSnare",
            ActionNode(function() self.inst:PushEvent("fossilsnare", { targets = self.snaretargets }) end)),
        ChaseAndAttack(self.inst),
        Wander(self.inst),
    }, .5)

    self.bt = BT(self.inst, root)
end

return StalkerBrain
