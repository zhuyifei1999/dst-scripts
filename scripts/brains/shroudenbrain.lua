require("behaviours/chaseandattack")
require("behaviours/faceentity")
require("behaviours/wander")

local ShroudenBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

local function GetHome(inst)
	return inst.components.knownlocations:GetLocation("spawnpoint")
end

local function GetFaceTargetFn(inst)
	local target = Ents[inst.components.combat.lasttargetGUID]
	if not (target and target.sg and target.sg:HasStateTag("devoured")) then
		target = nil
		local x, _, z = inst.Transform:GetWorldPosition()
		local mindsq = math.huge
		for k in pairs(inst.components.grouptargeter:GetTargets()) do
			if k.sg:HasStateTag("devoured") then
				local dsq = k:GetDistanceSqToPoint(x, 0, z)
				if dsq < mindsq then
					mindsq = dsq
					target = k
				end
			end
		end
	end
	return target
end

local function KeepFaceTargetFn(inst, target)
	if not inst.components.combat:HasTarget() then
		if target.sg and target.sg:HasStateTag("devoured") then
			inst.components.combat:OverrideCooldown(math.max(inst.components.combat:GetCooldown(), TUNING.SHROUDEN_ATTACK_PERIOD * 0.667))
			return true
		elseif not IsEntityDeadOrGhost(target) then
			local inarena = inst:IsInArena()
			local x1, _, z1 = target.Transform:GetWorldPosition()
			if (inarena and TheWorld.Map:IsPointInCharlieBossArena(x1, 0, z1)) or
				(not inarena and inst:GetDistanceSqToPoint(x1, 0, z1) < TUNING.SHROUDEN_DEAGGRO_DIST * TUNING.SHROUDEN_DEAGGRO_DIST)
			then
				inst.components.combat:SetTarget(target)
			end
		end
	end
	return false
end

function ShroudenBrain:OnStart()
	local root = PriorityNode({
		ChaseAndAttack(self.inst),
		ParallelNode{
			FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
			ActionNode(function()
				self.inst:PushEvent("quicktaunt")
			end),
		},
		Wander(self.inst, GetHome, 8),
	}, 0.25)

	self.bt = BT(self.inst, root)
end

function ShroudenBrain:OnInitializationComplete()
	self.inst.components.knownlocations:RememberLocation("spawnpoint", self.inst:GetPosition(), true)
end

return ShroudenBrain
