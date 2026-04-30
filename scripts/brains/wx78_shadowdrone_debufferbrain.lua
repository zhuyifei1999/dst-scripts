require("behaviours/leash")
local WX78_ShadowDrone_BrainCommon = require("brains/wx78_shadowdrone_braincommon")

local DEBUFF_RANGE_FROM_LEADER = 16
local STOP_DEBUFF_DELAY = 3

local WX78_ShadowDrone_DebufferBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetLeader(inst)
	return inst.components.follower:GetLeader()
end

local function GetLeaderAction(leader) --NOTE: not inst!
    local target
	local act = leader:GetBufferedAction() or leader.sg and leader.sg.statemem.action
    if act then
        return act.action, act.target
    end

	if leader._lastspintime then
		if leader.sg:HasStateTag("spinning") then
			if GetTime() - leader._lastspintime < 1 then
				return leader._lastspinaction, leader._lastspintarget
            end
		elseif leader:HasTag("using_drone_remote") then
			return leader._lastspinaction, leader._lastspintarget
        end
    end

	if leader.components.playercontroller then
		return leader.components.playercontroller:GetRemoteInteraction()
    end
end

local function GetLeaderTarget(leader) --NOTE: not inst!
	if leader.components.rider and leader.components.rider:IsRiding() then
		return
	end

    local leaderact, leadertarget = GetLeaderAction(leader)
    if leaderact == ACTIONS.ATTACK then
		return leadertarget
	end

	return leader.components.combat and leader.components.combat.target
end

local function GetScanTarget(inst)
	local target = inst:GetScanTarget()
	if target and not (target.components.health and target.components.health:IsDead()) then
		return target
	end
end

local function ShouldScan(self)
	local leader = GetLeader(self.inst)
	if leader == nil then
		self._last_debuff_time = nil
		self.inst:ClearScanTarget()
		return false
	end

	--check leader has current target
	local leadertarget = GetLeaderTarget(leader)
	if leadertarget then
		self.inst:SetScanTarget(leadertarget)
		local target = GetScanTarget(self.inst)
		if target and leader:IsNear(target, DEBUFF_RANGE_FROM_LEADER) then
			self._last_debuff_time = GetTime()
			return true
		end
		self._last_debuff_time = nil
		self.inst:ClearScanTarget()
		return false
	end

	--check for keeping our last target
	local target = GetScanTarget(self.inst)
	if target and leader:IsNear(target, DEBUFF_RANGE_FROM_LEADER) then
		if self._last_debuff_time then
			-- Do not immediately stop debuffing when the player stops attacking or moves out of range.
			if GetTime() - self._last_debuff_time < STOP_DEBUFF_DELAY then
				return true
			end
			self._last_debuff_time = nil
		end

		if target.components.combat and
			target.components.combat:HasTarget() and
			leader.components.combat and
			leader.components.combat:IsAlly(target.components.combat.target)
		then
			-- Keep target if they are still in combat with us.
			return true
		end
	end

	self._last_debuff_time = nil
	self.inst:ClearScanTarget()
	return false
end

--scan position is [scandist] away from target
local DEG_45 = 45 * DEGREES
local function GetScanPos(inst)
	local target = GetScanTarget(inst)
	if target then
		local scandist--[[, maxdist]] = inst:CalcScanRange()
		local x1, y1, z1 = target.Transform:GetWorldPosition()
		local theta
		local offs = WX78_ShadowDrone_BrainCommon.GetFormationOffset(inst)
		if offs then
			theta = math.atan2(-offs.z, offs.x)
		else
			local x, y, z = inst.Transform:GetWorldPosition()
			if x == x1 and z == z1 then
				theta = (inst.Transform:GetRotation() + 180) * DEGREES
			else
				theta = math.atan2(z1 - z1, x - x1)
			end
		end
		--Snap to nearest 45 degrees, better matches 8-faced beams
		theta = math.floor(theta / DEG_45 + 0.5) * DEG_45
		return Vector3(x1 + scandist * math.cos(theta), 0, z1 - scandist * math.sin(theta))
	end
end

--Min/Max leash dist is relative to GetScanPos, not target pos
--Wider threshold when already in scanning mode.
local function MinMaxLeashDist(inst)
	local range, maxrange = inst:CalcScanRange()
	return inst.sg:HasStateTag("scanning")
		and math.max(0.65, maxrange - range - 0.1)
		or 0.65
end

function WX78_ShadowDrone_DebufferBrain:OnStart()
    local root = PriorityNode({
        WhileNode(
            function()
                return not self.inst.sg:HasStateTag("despawn")
            end,
            "<busy state guard>",
            PriorityNode({
				WhileNode(function() return ShouldScan(self) end, "scanning",
                    PriorityNode({
                        FailIfSuccessDecorator(Leash(self.inst, GetScanPos, MinMaxLeashDist, MinMaxLeashDist, true)),
                        ActionNode(function()
                            self.inst:PushEventImmediate("ms_wx_shadowdrone_scan")
                        end),
					}, 0.1)),
                WX78_ShadowDrone_BrainCommon.FollowFormationNode(self.inst),
                WX78_ShadowDrone_BrainCommon.WanderNode(self.inst),
			}, 0.1)
        )
	}, 0.1)

    self.bt = BT(self.inst, root)
end

return WX78_ShadowDrone_DebufferBrain
