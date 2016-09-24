require "behaviours/chaseandattack"
require "behaviours/leash"
require "behaviours/wander"

local ToadstoolBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetHomePos(inst)
    return inst.components.knownlocations:GetLocation("spawnpoint")
end

local function ShouldFlee(inst)
    return not inst.components.timer:TimerExists("flee")
end

local function ShouldChannel(inst)
    return inst.components.timer:TimerExists("channel")
        or (inst.level < 3 and
            not inst.components.timer:TimerExists("mushroomsprout_cd") and
            not inst.components.timer:IsPaused("flee"))
end

function ToadstoolBrain:OnStart()
    local root = PriorityNode(
    {
        WhileNode(function() return ShouldFlee(self.inst) end, "Flee",
            ActionNode(function()
                self.inst:PushEvent("roar")
                self.inst:PushEvent("flee")
            end)),
        WhileNode(function() return ShouldChannel(self.inst) end, "Channel",
            PriorityNode{
                Leash(self.inst, GetHomePos, 8, 6),
                ActionNode(function() self.inst:PushEvent("startchanneling") end),
            }, 1),
        Leash(self.inst, GetHomePos, 30, 25),
        ChaseAndAttack(self.inst),
        ParallelNode{
            Wander(self.inst, GetHomePos, 5),
            SequenceNode{
                WaitNode(10),
                ActionNode(function() self.inst:PushEvent("flee") end),
            },
        },
    }, 1)

    self.bt = BT(self.inst, root)
end

function ToadstoolBrain:OnInitializationComplete()
    local pos = self.inst:GetPosition()
    pos.y = 0
    self.inst.components.knownlocations:RememberLocation("spawnpoint", pos, true)
end

return ToadstoolBrain
