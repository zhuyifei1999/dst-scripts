require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/follow"
require "behaviours/panic"

local BernieBrain = Class(Brain, function(self, inst)
    Brain._ctor(self,inst)

    self.listenerfunc = function() self.mytarget = nil end
end)

local MIN_FOLLOW_DIST = 0
local MAX_FOLLOW_DIST = 20
local TARGET_FOLLOW_DIST = 8
local MAX_WANDER_DIST = 18

local wander_times = 
{
    minwalktime = 1,
    minwaittime = 1,
}

local function TauntCreatures(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local shadowcreatures = TheSim:FindEntities(x, y, z, 30, { "shadowcreature", "_combat" })
    for _, creature in ipairs(shadowcreatures) do
        --Taunt the first creature that isn't targeting you & is valid
        if creature.components.combat ~= nil and
            not creature.components.combat:TargetIs(inst) and
            creature.components.combat:CanTarget(inst) then
            return BufferedAction(inst, creature, ACTIONS.TAUNT)
        end
    end
end

function BernieBrain:SetTarget(target)
    if target ~= self.target then
        if self.mytarget ~= nil then
            self.inst:RemoveEventCallback("onremove", self.listenerfunc, self.mytarget)
        end
        if target ~= nil then
            self.inst:ListenForEvent("onremove", self.listenerfunc, target)
        end
        self.mytarget = target
    end
end

function BernieBrain:OnStart()
    local root = 
    PriorityNode({
        --Get the attention of nearby sanity monsters.
        WhileNode(
            function()
                return not (self.inst.sg:HasStateTag("taunt") or self.inst.components.timer:TimerExists("taunt_cd"))
            end,
            "Can Taunt", 
            DoAction(self.inst, TauntCreatures, "Taunt")),

        Follow(self.inst, function() return self.inst.components.follower.leader end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
        Wander(self.inst, function() return self.mytarget ~= nil and self.mytarget:GetPosition() or nil end, MAX_WANDER_DIST, wander_times),
        --Panic(self.inst),
    }, 1)
    self.bt = BT(self.inst, root)
end

return BernieBrain
