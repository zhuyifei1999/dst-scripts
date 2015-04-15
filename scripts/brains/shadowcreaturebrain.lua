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
	self.listenerfunc = function() self.mytarget = nil end
	if target ~= self.target then
		if self.mytarget then
			self.inst:RemoveEventCallback("onremove", self.listenerfunc, self.mytarget)
		end
		if target then
			self.inst:ListenForEvent("onremove", self.listenerfunc, target)
		end
	end
	self.mytarget = target
end

function ShadowCreatureBrain:OnStart()
	-- The brain is restarted when we wake up. The player may be gone by then
	if self.inst.spawnedforplayer and not self.inst.spawnedforplayer:IsValid() then
		self.inst.spawnedforplayer = nil
	end
	self:SetTarget(self.inst.spawnedforplayer)
		
    local root = PriorityNode(
    {
        ChaseAndAttack(self.inst, 100),
        Follow(self.inst, function() 
							return self.mytarget 
						end, MIN_FOLLOW, MED_FOLLOW, MAX_FOLLOW),
        Wander(self.inst, function() 
							local player = self.mytarget 
							if player then 
								return Vector3(player.Transform:GetWorldPosition()) 
							end 
						end, 20)
    }, .25)
    
    self.bt = BT(self.inst, root)
end

return ShadowCreatureBrain