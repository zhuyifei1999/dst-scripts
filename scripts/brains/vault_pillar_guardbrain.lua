require("behaviours/chaseandattack")
require("behaviours/faceentity")
require("behaviours/wander")

local Vault_Pillar_GuardBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

local function GetHomePos(inst)
	return inst.components.knownlocations:GetLocation("spawnpoint")
end

local function GetFaceTargetFn(inst)
	return inst.components.combat.target
end

local function KeepFaceTargetFn(inst, target)
	return inst.components.combat:TargetIs(target) and not inst:IsNear(target, 4)
end

local function GetHomeBetweenTargetPos(inst)
	local home = GetHomePos(inst)
	if home then
		local target = inst.components.combat.target
		if target then
			local physrad = target:GetPhysicsRadius(0)
			local x, y, z = inst.Transform:GetWorldPosition()
			local x1, y1, z1 = target.Transform:GetWorldPosition()
			local dx = x1 - x
			local dz = z1 - z
			local dsq = dx * dx + dz * dz
			if dsq >= 64 then
				local dx2 = home.x - x
				local dz2 = home.z - z
				local dsq2 = dx2 * dx2 + dz2 * dz2
				if dsq2 < dsq and dsq2 > 0 and DiffAngleRad(math.atan2(-dz, dx), math.atan2(-dz2, dx2)) < HALFPI then
					return home
				end
			end
		end
	end
end

local function ShouldChase(inst)
	local home = GetHomePos(inst)
	if home and inst.trial then
		local target = inst.components.combat.target
		if target then
			local x, y, z = inst.Transform:GetWorldPosition()
			local x1, y1, z1 = target.Transform:GetWorldPosition()
			local mindsq = math2d.DistSq(x, z, x1, z1)
			local range = TUNING.VAULT_PILLAR_GUARD_ATTACK_RANGE + target:GetPhysicsRadius(0)
			if mindsq < range * range and not inst.components.combat:InCooldown() then
				return true --within melee range, attack
			elseif math2d.DistSq(x, z, home.x, home.z) < mindsq then
				return true --closer to home than to target, chase
			end

			local closest = inst
			for i = 1, 4 do
				local guard = inst.trial.components.entitytracker:GetEntity("guard"..tostring(i))
				if guard and guard ~= inst and guard.components.combat:TargetIs(target) then
					local dsq = guard:GetDistanceSqToPoint(x1, y1, z1)
					if dsq < mindsq then
						mindsq = dsq
						closest = guard
					end
				end
			end
			return closest == inst
		end
	end
	return true
end

function Vault_Pillar_GuardBrain:OnStart()
	local root = PriorityNode({
		WhileNode(
			function() return not self.inst.sg:HasStateTag("jumping") end,
			"<busy state guard>",
			PriorityNode({
				Leash(self.inst, GetHomeBetweenTargetPos, 1, 1),
				WhileNode(function() return ShouldChase(self.inst) end, "chase and attack",
					ParallelNodeAny{
						ChaseAndAttack(self.inst),
						SequenceNode{
							WaitNode(4),
							ConditionWaitNode(function()
								local target = self.inst.components.combat.target
								if target and self.inst.canquickjump and self.inst:IsNear(target, 8) then
									self.inst:PushEvent("ms_pillarguard_quickjump", { target = target })
									return true
								end
								return false
							end, "quickjump"),
						},
					}),
				FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
				Wander(self.inst, GetHomePos, 4, {
					minwalktime = 2.5,
					randwalktime = 1.5,
					minwaittime = 4,
					randwaittime = 2,
				}),
			}, 0.25)),
		}, 0.25)

	self.bt = BT(self.inst, root)
end

function Vault_Pillar_GuardBrain:OnInitializationComplete()
	self.inst.components.knownlocations:RememberLocation("spawnpoint", self.inst:GetPosition(), true)
end

return Vault_Pillar_GuardBrain
