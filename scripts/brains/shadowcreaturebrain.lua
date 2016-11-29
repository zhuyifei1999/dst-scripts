require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/minperiod"
require "behaviours/follow"

local MIN_FOLLOW = 5
local MED_FOLLOW = 15
local MAX_FOLLOW = 30

local ShadowCreatureBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    self.mytarget = nil
end)

function ShadowCreatureBrain:SetTarget(target)
    if target ~= nil then
        if not target:IsValid() then
            target = nil
        elseif self.listenerfunc == nil then
            self.listenerfunc = function() self.mytarget = nil end
        end
    end
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

function ShadowCreatureBrain:OnStop()
    self:SetTarget(nil)
end

function ShadowCreatureBrain:OnStart()
    -- The brain is restarted when we wake up. The player may be gone by then
    self:SetTarget(self.inst.spawnedforplayer)

    local root = PriorityNode(
    {
        ChaseAndAttack(self.inst, 100),
        Follow(self.inst, function() return self.mytarget end, MIN_FOLLOW, MED_FOLLOW, MAX_FOLLOW),
        Wander(self.inst, function() return self.mytarget ~= nil and self.mytarget:GetPosition() or nil end, 20),
    }, .25)

    self.bt = BT(self.inst, root)
end

return ShadowCreatureBrain
