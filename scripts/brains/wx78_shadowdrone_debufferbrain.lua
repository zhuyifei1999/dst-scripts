require("behaviours/leash")
local WX78_ShadowDrone_BrainCommon = require("brains/wx78_shadowdrone_braincommon")

local DEBUFF_RANGE_FROM_LEADER = 16
local DEBUFF_RANGE_FROM_LEADER_SQ = DEBUFF_RANGE_FROM_LEADER * DEBUFF_RANGE_FROM_LEADER
local STOP_DEBUFF_DELAY = 3

local WX78_ShadowDrone_DebufferBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetLeader(inst)
	return inst.components.follower:GetLeader()
end

local function GetLeaderAction(inst)
    local target
    local act = inst:GetBufferedAction() or inst.sg and inst.sg.statemem.action
    if act then
        return act.action, act.target
    end

    if inst._lastspintime then
        if inst.sg:HasStateTag("spinning") then
            if GetTime() - inst._lastspintime < 1 then
                return inst._lastspinaction, inst._lastspintarget
            end
        elseif inst:HasTag("using_drone_remote") then
            return inst._lastspinaction, inst._lastspintarget
        end
    end

    if inst.components.playercontroller then
        return inst.components.playercontroller:GetRemoteInteraction()
    end
end

local function IsLeaderAttacking(inst)
    local leader = GetLeader(inst)
    if not leader then
        return false
    end

    if leader.components.rider and leader.components.rider:IsRiding() then
        return false
    end

    local leaderact, leadertarget = GetLeaderAction(leader)
    if leaderact == ACTIONS.ATTACK then
        return true
    end

    if leader.components.combat and leader.components.combat.target then
        return true
    end

    return false
end

local function ShouldMoveAnyways(inst)
    local leader = GetLeader(inst)
    if not leader then
        return false
    end

    local target = inst.target:value()
    if not target then
        return false
    end

    local distsq_leader_to_target = leader:GetDistanceSqToInst(target)
    if distsq_leader_to_target > DEBUFF_RANGE_FROM_LEADER_SQ then
        return true -- Out of range, go back to formation.
    end

    return false
end

local function SetTargetOnLeaderTarget(inst)
    local leader = GetLeader(inst)
    if not leader then
        return
    end

    local leaderact, leadertarget = GetLeaderAction(leader)
    local debufftarget
    if leaderact == ACTIONS.ATTACK then
        debufftarget = leadertarget
    else
        debufftarget = leader.components.combat and leader.components.combat.target
    end

    if debufftarget then
        inst:SetTarget(debufftarget)
    end
end

local function GetScanTarget(inst)
	local target = inst.target:value()
	if target and not (target.components.health and target.components.health:IsDead()) then
		return target
	end
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
                WhileNode(
                    function()
                        if IsLeaderAttacking(self.inst) and not ShouldMoveAnyways(self.inst) then
                            SetTargetOnLeaderTarget(self.inst)
                            if GetScanTarget(self.inst) then
                                self._last_debuff_time = GetTime()
                                return true
                            end
                        end
                        if self._last_debuff_time then
                            -- Do not immediately stop debuffing when the player stops attacking or moves out of range.
                            if GetScanTarget(self.inst) and GetTime() - self._last_debuff_time < STOP_DEBUFF_DELAY then
                                return true
                            end
                            self._last_debuff_time = nil
                        end
                        self.inst:ClearTarget()
                        return false
                    end,
                    "is leader attacking",
                    PriorityNode({
                        FailIfSuccessDecorator(Leash(self.inst, GetScanPos, MinMaxLeashDist, MinMaxLeashDist, true)),
                        ActionNode(function()
                            self.inst:PushEventImmediate("ms_wx_shadowdrone_scan")
                        end),
                    })),
                WX78_ShadowDrone_BrainCommon.FollowFormationNode(self.inst),
                WX78_ShadowDrone_BrainCommon.WanderNode(self.inst),
            }, .25)
        )
    }, .25)

    self.bt = BT(self.inst, root)
end

return WX78_ShadowDrone_DebufferBrain
