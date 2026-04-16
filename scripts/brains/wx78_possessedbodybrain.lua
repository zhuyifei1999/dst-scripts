require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/doaction"
require "behaviours/leash"
require "behaviours/standstill"
require "behaviours/runawaytodist"

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
        if inst.components.trader:IsTryingToTradeWithMe(player) or inst.components.eater:IsTryingToFeedMe(player) then
            return player
        end
    end
end

local function KeepTraderFn(inst, target)
    return inst.components.trader:IsTryingToTradeWithMe(target) or inst.components.eater:IsTryingToFeedMe(target)
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

local function CanToolDoAction(tool, action)
    -- tool:CanDoAction is for till
    return ((tool.components.tool ~= nil and tool.components.tool:CanDoAction(action)) or tool:CanDoAction(action)) 
end

local function HasToolForAction(inst, action, tryequip)
    local tool = GetTool(inst)
    if tool ~= nil and CanToolDoAction(tool, action) then
        return true
    end

    -- Equip next available tool
    local nexttool = inst.components.inventory:FindItem(function(item)
        return item.components.equippable ~= nil and not item.components.equippable:IsRestricted(inst)
            and CanToolDoAction(item, action)
    end)

    if nexttool ~= nil then
        if tryequip then
            inst.components.inventory:Equip(nexttool)
        end
        return true
    end
end

local function GetLeaderAction(inst)
	local target
    local act = inst:GetBufferedAction() or inst.sg.statemem.action
	if act then
		target = act.target
		act = act.action
    elseif inst.sg:HasStateTag("spinning") and inst._lastspintime and GetTime() - inst._lastspintime < 1 then
        act, target = inst._lastspinaction, inst._lastspintarget
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

local function IsLeaderMoving(inst)
    local leader = GetLeader(inst)
    if leader ~= nil then
        return leader.components.locomotor ~= nil and leader.components.locomotor:WantsToMoveForward()
    end
end

local function Create_Starter(action)
    return function(inst, leaderdist, finddist)
        local leader = GetLeader(inst)
        if leader ~= nil then
            local leaderact, leadertarget = GetLeaderAction(leader)
            if leaderact == action and HasToolForAction(inst, action, true) then
                return true
            end
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
    shouldrun = true,
}
local NODE_ASSIST_MINE_ACTION =
{
    action = "MINE",
    starter = Create_Starter(ACTIONS.MINE),
    keepgoing = Create_KeepGoing(ACTIONS.MINE),
    finder = Create_FindNew(ACTIONS.MINE),
    shouldrun = true,
}
local NODE_ASSIST_HAMMER_ACTION =
{
    action = "HAMMER",
    starter = Create_Starter(ACTIONS.HAMMER),
    keepgoing = Create_KeepGoing(ACTIONS.HAMMER),
    finder = Create_FindNew(ACTIONS.HAMMER),
    shouldrun = true,
}
local NODE_ASSIST_DIG_ACTION =
{
    action = "DIG",
    starter = Create_Starter(ACTIONS.DIG),
    keepgoing = Create_KeepGoing(ACTIONS.DIG),
    -- We don't want to dig the same thing
    shouldrun = true,
}
local NODE_ASSIST_TILL_ACTION =
{
    action = "TILL",
    starter = Create_Starter(ACTIONS.TILL),
    keepgoing = Create_KeepGoing(ACTIONS.TILL),
    -- Use regular till finding logic
    shouldrun = true,
}

local function EquipBestWeapon(inst, target)
    -- Find highest damage weapon to use
    -- Not the best since it doesnt take into account damage multipliers, can be improved.
    local bestweapon
    inst.components.inventory:ForEachItem(function(item)
        if (bestweapon == nil and item.components.weapon ~= nil) or
            (bestweapon ~= nil and bestweapon.components.weapon ~= nil and item.components.weapon ~= nil
            and item.components.weapon:GetDamage(inst, target) > bestweapon.components.weapon:GetDamage(inst, target)) then
            bestweapon = item
        end
    end)
    local heldweapon = GetTool(inst)
    if bestweapon and bestweapon ~= heldweapon
        and (heldweapon == nil or heldweapon.components.weapon == nil or (
            bestweapon.components.weapon:GetDamage(inst, target) ~= heldweapon.components.weapon:GetDamage(inst, target)
        )) then
        inst.components.inventory:Equip(bestweapon)
    end
end

local function SetTargetOnLeaderTarget(inst)
    local leader = GetLeader(inst)
    if leader ~= nil then
        local leaderact, leadertarget = GetLeaderAction(leader)
        if leaderact == ACTIONS.ATTACK then
            inst.components.combat:SetTarget(leadertarget)
            EquipBestWeapon(inst, leadertarget)
        elseif leader.components.combat.target ~= nil then
            inst.components.combat:SetTarget(leader.components.combat.target)
            EquipBestWeapon(inst, leader.components.combat.target)
        end
    end
end

local function EatFoodAction(inst)
    if not inst.sg:HasStateTag("busy") then
        -- We're well topped off, just return for optimization sake.
        if inst.components.health:GetPercent() <= 0.9 or inst.components.hunger:GetPercent() <= 0.9 or inst.components.sanity:GetPercent() <= 0.9 then
            local health = inst.components.health.currenthealth
            local hunger = inst.components.hunger.current
            local sanity = inst.components.sanity.current

            local maxhealth = inst.components.health:GetMaxWithPenalty() * 1.5 -- Some leniency for healing.
            local maxhunger = inst.components.hunger.max
            local maxsanity = inst.components.sanity:GetMaxWithPenalty()

            local besthealth
            local besthunger
            local bestsanity

            inst.components.inventory:ForEachItem(function(item)
                local edible = item.components.edible
                if edible ~= nil and inst.components.eater:CanEat(item) then
                    local itemhealth = edible:GetHealth(inst)
                    local itemhunger = edible:GetHunger(inst)
                    local itemsanity = edible:GetSanity(inst)

                    if itemhealth >= TUNING.HEALING_MEDSMALL and (health + itemhealth) <= maxhealth then
                        if besthealth == nil or (itemhealth > besthealth.components.edible:GetHealth(inst)) then
                            besthealth = item
                        end
                    elseif itemhunger > 0 and (hunger + itemhunger) <= maxhunger then
                        if besthunger == nil or (itemhunger > besthunger.components.edible:GetHunger(inst)) then
                            besthunger = item
                        end
                    elseif itemsanity >= TUNING.SANITY_SMALL and (sanity + itemsanity) <= maxsanity then
                        if bestsanity == nil or (itemsanity > bestsanity.components.edible:GetSanity(inst)) then
                            bestsanity = item
                        end
                    end
                end
            end)

            local foodtoeat = besthealth or besthunger or bestsanity
            if foodtoeat ~= nil then
                return BufferedAction(inst, foodtoeat, ACTIONS.EAT)
            end
        end

        if inst.components.eater:IsSpoiledProcessor() then
            local spoiledtoeat = inst.components.inventory:FindItem(function(item)
                local edible = item.components.edible
                return edible ~= nil
                    and inst.components.eater:CanEat(item)
                    and inst.components.eater:CanProcessSpoiledItem(item)
            end)

            if spoiledtoeat ~= nil then
                return BufferedAction(inst, spoiledtoeat, ACTIONS.EAT)
            end
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

local DROP_TARGET_KITE_DIST_SQ = 14 * 14
local function LeaderInRangeOfTarget(inst)
    local leader = GetLeader(inst)
    local target = GetRunAwayTarget(inst)
    if leader ~= nil and target ~= nil then
        if leader:GetDistanceSqToInst(target) > DROP_TARGET_KITE_DIST_SQ then
            inst.components.combat:SetTarget(nil)
            return false
        end
    end
    return true
end
local RUNAWAY_PARAM = { getfn = GetRunAwayTarget }
local MAX_KITE_DIST = 10
local TOLERANCE_DIST = .5

local function GetRunDist(inst, hunter)
    local attack_range = inst.components.combat:GetAttackRange()
    local leader = GetLeader(inst)
    if leader ~= nil then
        local dist = math.max(attack_range, math.min(math.sqrt(leader:GetDistanceSqToInst(hunter)), MAX_KITE_DIST))
        if inst._lastdist == nil or (math.abs(inst._lastdist - dist) >= TOLERANCE_DIST) then
            inst._lastdist = dist
            inst._lastruntime = GetTime()
            return dist
        else
            return inst._lastdist
        end
    end

    return 1 -- Shrug?
end

local RUN_AFTER_KITE_DELAY = 1
--------------------------------------------------------------------------------------------------------------------------------

local UPDATE_RATE = 0.1
function Wx78_PossessedBodyBrain:OnStart()
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

            DoAction(self.inst, DoUpgradeModuleAction, nil, true),

            WhileNode(function() return not IsLeaderAttacking(self.inst) and IsLeaderMoving(self.inst) and LeaderInRangeOfTarget(self.inst) end, "is leader not attacking",
                RunAwayToDist(self.inst, RUNAWAY_PARAM, GetRunDist, nil, nil, nil, true)),

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

            SequenceNode{
                ConditionWaitNode(function()
                    return self.inst._lastruntime == nil or (GetTime() - self.inst._lastruntime > RUN_AFTER_KITE_DELAY)
                end, "Wait after kiting"),
                Follow(self.inst, GetLeader, FOLLOW_MIN_DIST, FOLLOW_TARGET_DIST, FOLLOW_MAX_DIST, true),
            },

            DoAction(self.inst, EatFoodAction, nil, true),
            FaceEntity(self.inst, GetFaceLeaderFn, KeepFaceLeaderFn),
            StandStill(self.inst),
        }, UPDATE_RATE))
    }, UPDATE_RATE)

    self.bt = BT(self.inst, root)
end

function Wx78_PossessedBodyBrain:OnStop()

end

return Wx78_PossessedBodyBrain