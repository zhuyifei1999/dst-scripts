require "behaviours/chaseandattack"
require "behaviours/wander"

local SKULLACHE_CD = 18
local FALLAPART_CD = 11

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
    local root

    if self.inst.canfight then
        root = PriorityNode({
            WhileNode(function() return ShouldSnare(self) end, "FossilSnare",
                ActionNode(function() self.inst:PushEvent("fossilsnare", { targets = self.snaretargets }) end)),
            ChaseAndAttack(self.inst),
            Wander(self.inst),
        }, .5)
    else
        local t = GetTime()
        self.skullachetime = t + 8 + math.random() * SKULLACHE_CD
        self.fallaparttime = t + 8 + math.random() * FALLAPART_CD

        root = PriorityNode({
            WhileNode(function() return not TheWorld.state.isnight end, "Daytime",
                ActionNode(function() self.inst:PushEvent("flinch") end)),
            WhileNode(
                function()
                    local t = GetTime()
                    if t > self.skullachetime then
                        self.skullachetime = t + SKULLACHE_CD
                        return true
                    end
                    return false
                end,
                "SkullAche",
                ActionNode(function() self.inst:PushEvent("skullache") end)),
            WhileNode(
                function()
                    local t = GetTime()
                    if t > self.fallaparttime then
                        self.fallaparttime = t + FALLAPART_CD
                        return true
                    end
                    return false
                end,
                "FallApart",
                ActionNode(function() self.inst:PushEvent("fallapart") end)),
            Wander(self.inst),
        }, .5)
    end

    self.bt = BT(self.inst, root)
end

return StalkerBrain
