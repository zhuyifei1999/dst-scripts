require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/doaction"
require "behaviours/leash"
require "behaviours/standstill"

local BrainCommon = require("brains/braincommon")

local MAX_CHASE_TIME = 10
local MAX_CHASE_DIST = 50

local TRADE_DIST = 20

local FOLLOW_MIN_DIST = 1
local FOLLOW_TARGET_DIST = 6
local FOLLOW_MAX_DIST = 9

--------------------------------------------------------------------------------------------------------------------------------

local Wx78_PossessedBodyBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetTraderFn(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, TRADE_DIST, true)
    for _, player in ipairs(players) do
        if inst.components.trader:IsTryingToTradeWithMe(player) then
            return player
        end
    end
end

local function KeepTraderFn(inst, target)
    return inst.components.trader:IsTryingToTradeWithMe(target)
end

local function GetLeader(inst)
	return inst.components.follower and inst.components.follower:GetLeader()
end

local function GetFaceLeaderFn(inst)
    return GetLeader(inst)
end

local function KeepFaceLeaderFn(inst, target)
    return GetLeader(inst) == target
end

--------------------------------------------------------------------------------------------------------------------------------

local function GetTool(inst)
    return inst.components.inventory ~= nil and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
end

local function HasToolForAction(inst, action)
    local tool = GetTool(inst)
    return tool ~= nil and
        (
            (tool.components.tool ~= nil and tool.components.tool:CanDoAction(action)) or
            tool:CanDoAction(action) -- for till
        )
        or nil
end

local function GetLeaderAction(inst)
	local target
    local act = inst:GetBufferedAction() or inst.sg.statemem.action
	if act then
		target = act.target
		act = act.action
	elseif inst.components.playercontroller then
		act, target = inst.components.playercontroller:GetRemoteInteraction()
	end

    return act, target
end

local function IsLeaderAttacking(inst)
    local leader = GetLeader(inst)
    if leader ~= nil then
        local leaderact, leadertarget = GetLeaderAction(leader)
        if leaderact == ACTIONS.ATTACK then
            return true
        end

        if leader.components.combat.target ~= nil then
            return true
        end
    end
end

local function Create_Starter(action)
    return function(inst, leaderdist, finddist)
        local leader = GetLeader(inst)
        if leader ~= nil then
            local leaderact, leadertarget = GetLeaderAction(leader)
            return leaderact == action
        end
    end
end

local function Create_KeepGoing(action)
    return function(inst, leaderdist, finddist)
        local leader = GetLeader(inst)
        if leader ~= nil then
            local leaderact, leadertarget = GetLeaderAction(leader)
            return leaderact == action
        end
    end
end

local function Create_FindNew(action)
    return function(inst, leaderdist, finddist)
        local leader = GetLeader(inst)
        if leader ~= nil then
            local leaderact, leadertarget = GetLeaderAction(leader)
            if leaderact == action then
                return BufferedAction(inst, leadertarget, action, GetTool(inst))
            end
        end
    end
end

-- action field is Required.
local NODE_ASSIST_CHOP_ACTION =
{
    action = "CHOP",
    starter = Create_Starter(ACTIONS.CHOP),
    keepgoing = Create_KeepGoing(ACTIONS.CHOP),
    finder = Create_FindNew(ACTIONS.CHOP),
}
local NODE_ASSIST_MINE_ACTION =
{
    action = "MINE",
    starter = Create_Starter(ACTIONS.MINE),
    keepgoing = Create_KeepGoing(ACTIONS.MINE),
    finder = Create_FindNew(ACTIONS.MINE),
}
local NODE_ASSIST_HAMMER_ACTION =
{
    action = "HAMMER",
    starter = Create_Starter(ACTIONS.HAMMER),
    keepgoing = Create_KeepGoing(ACTIONS.HAMMER),
    finder = Create_FindNew(ACTIONS.HAMMER),
}
local NODE_ASSIST_DIG_ACTION =
{
    action = "DIG",
    starter = Create_Starter(ACTIONS.DIG),
    keepgoing = Create_KeepGoing(ACTIONS.DIG),
    -- We don't want to dig the same thing
}
local NODE_ASSIST_TILL_ACTION =
{
    action = "TILL",
    starter = Create_Starter(ACTIONS.TILL),
    keepgoing = Create_KeepGoing(ACTIONS.TILL),
    -- Use regular till finding logic
}

local function SetTargetOnLeaderTarget(inst)
    local leader = GetLeader(inst)
    if leader ~= nil then
        local leaderact, leadertarget = GetLeaderAction(leader)
        if leaderact == ACTIONS.ATTACK then
            inst.components.combat:SetTarget(leadertarget)
        end
    end
end

local function DoUpgradeModuleAction(inst)
    if inst.sg:HasStateTag("busy") or (inst.last_upgrade_module_action and GetTime() - inst.last_upgrade_module_action < 5)then
        return
    end

    local actions = {}
    inst:CollectUpgradeModuleActions(actions)
    for i, v in ipairs(actions) do
        inst.last_upgrade_module_action = GetTime()
        return BufferedAction(inst, nil, v)
    end
end

local function GetRunAwayTarget(inst)
    local target = inst.components.combat.target or Ents[inst.components.combat.lasttargetGUID]
    if target ~= nil and not IsEntityDead(target) then
        return target
    end
end
local RUNAWAY_PARAM = { getfn = GetRunAwayTarget }
local RUN_AWAY_DIST = 5
local STOP_RUN_AWAY_DIST = 8

--------------------------------------------------------------------------------------------------------------------------------

local UPDATE_RATE = 0.2
function Wx78_PossessedBodyBrain:OnStart()
    -- self.kite_run_node = RunAway(self.inst, RUNAWAY_PARAM, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST)
    local root = PriorityNode(
    {
        WhileNode(function() return true end, --not self.inst.sg:HasStateTag("busy") end,
        "<busy state guard",
        PriorityNode({
            -- No panic behaviours. We're controlled by gestalts.
            FaceEntity(self.inst, GetTraderFn, KeepTraderFn),

            WhileNode(function() return IsLeaderAttacking(self.inst) end, "is leader attacking",
                PriorityNode({
                    FailIfSuccessDecorator(ActionNode(function() SetTargetOnLeaderTarget(self.inst) end)),
                    ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),
                }, UPDATE_RATE)
            ),

            DoAction(self.inst, DoUpgradeModuleAction),

            WhileNode(function() return not IsLeaderAttacking(self.inst) end, "is leader not attacking",
                RunAway(self.inst, RUNAWAY_PARAM, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST)),

            -- Actions
            WhileNode(function() return HasToolForAction(self.inst, ACTIONS.CHOP) end, "chop with tool",
                BrainCommon.NodeAssistLeaderDoAction(self, NODE_ASSIST_CHOP_ACTION)),

            WhileNode(function() return HasToolForAction(self.inst, ACTIONS.MINE) end, "mine with tool",
                BrainCommon.NodeAssistLeaderDoAction(self, NODE_ASSIST_MINE_ACTION)),

            WhileNode(function() return HasToolForAction(self.inst, ACTIONS.HAMMER) end, "hammer with tool",
                BrainCommon.NodeAssistLeaderDoAction(self, NODE_ASSIST_HAMMER_ACTION)),

            WhileNode(function() return HasToolForAction(self.inst, ACTIONS.DIG) end, "dig with tool",
                BrainCommon.NodeAssistLeaderDoAction(self, NODE_ASSIST_DIG_ACTION)),

            WhileNode(function() return HasToolForAction(self.inst, ACTIONS.TILL) end, "till with tool",
                BrainCommon.NodeAssistLeaderDoAction(self, NODE_ASSIST_TILL_ACTION)),

            Follow(self.inst, GetLeader, FOLLOW_MIN_DIST, FOLLOW_TARGET_DIST, FOLLOW_MAX_DIST, true),
            FaceEntity(self.inst, GetFaceLeaderFn, KeepFaceLeaderFn),
            StandStill(self.inst),
        }, UPDATE_RATE))
    }, UPDATE_RATE)

    self.bt = BT(self.inst, root)
end

-- function Wx78_PossessedBodyBrain:DoUpdate()
--     if self.kite_run_node ~= nil then
--         local leader = GetLeader(self.inst)
--         local target = GetRunAwayTarget(self.inst)
--         if leader and target then
--             local dist = math.sqrt(leader:GetDistanceSqToInst(target))
--             self.kite_run_node.see_dist = dist
--             self.kite_run_node.safe_dist = dist
--         end
--     end
-- end

function Wx78_PossessedBodyBrain:OnStop()

end

return Wx78_PossessedBodyBrain