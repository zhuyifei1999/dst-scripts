require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/follow"

local BernieBrain = Class(Brain, function(self, inst)
    Brain._ctor(self,inst)
    self.targets = nil
end)

local MIN_FOLLOW_DIST = 0
local MAX_FOLLOW_DIST = 20
local TARGET_FOLLOW_DIST = 8
local TAUNT_DIST = 16

local wander_times =
{
    minwalktime = 1,
    minwaittime = 1,
}

local function IsTauntable(inst, target)
    return target.components.combat ~= nil
        and not target.components.combat:TargetIs(inst)
        and target.components.combat:CanTarget(inst)
end

local function FindShadowCreatures(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TAUNT_DIST, { "shadowcreature", "_combat" })
    for i = #ents, 1, -1 do
        if not IsTauntable(inst, ents[i]) then
            table.remove(ents, i)
        end
    end
    return #ents > 0 and ents or nil
end

local function TauntCreatures(self)
    local taunted = false
    if self.targets ~= nil then
        for i, v in ipairs(self.targets) do
            if IsTauntable(self.inst, v) then
                v.components.combat:SetTarget(self.inst)
                taunted = true
            end
        end
    end
    if taunted then
        self.inst.sg:GoToState("taunt")
    end
end

function BernieBrain:OnStart()
    local root =
    PriorityNode({
        --Get the attention of nearby sanity monsters.
        WhileNode(
            function()
                self.targets =
                    not (self.inst.sg:HasStateTag("busy") or self.inst.components.timer:TimerExists("taunt_cd"))
                    and FindShadowCreatures(self.inst)
                    or nil
                return self.targets ~= nil
            end,
            "Can Taunt",
            ActionNode(function() TauntCreatures(self) end)),

        Follow(self.inst, function() return self.inst.components.follower.leader end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
        Wander(self.inst, nil, nil, wander_times),
    }, 1)
    self.bt = BT(self.inst, root)
end

return BernieBrain
