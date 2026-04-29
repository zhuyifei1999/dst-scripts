require("behaviours/wander")
require("behaviours/leash")

local WX78_ShadowDrone_BrainCommon = {}

---------------------------------------------------------------------------------------------------

local function GetLeader(inst)
    return inst.components.follower and inst.components.follower:GetLeader() or nil
end

local function GetLeaderPos(inst)
    local leader = GetLeader(inst)
    return leader and leader:GetPosition() or nil
end

local function GetFormationOffset(inst)
    return inst.components.knownlocations:GetLocation("formationoffset")
end

local function GetShadowDronePos(inst)
    local pos = GetLeaderPos(inst)
    if pos then
        local offset = GetFormationOffset(inst)
        return offset and (pos + offset) or pos
    end
end

WX78_ShadowDrone_BrainCommon.GetLeader = GetLeader
WX78_ShadowDrone_BrainCommon.GetLeaderPos = GetLeaderPos
WX78_ShadowDrone_BrainCommon.GetFormationOffset = GetFormationOffset
WX78_ShadowDrone_BrainCommon.GetShadowDronePos = GetShadowDronePos

---------------------------------------------------------------------------------------------------

local function ShouldHoldFormation(inst)
    return WX78_ShadowDrone_BrainCommon.GetFormationOffset(inst) ~= nil and WX78_ShadowDrone_BrainCommon.GetLeader(inst) ~= nil
end

WX78_ShadowDrone_BrainCommon.ShouldHoldFormation = ShouldHoldFormation

WX78_ShadowDrone_BrainCommon.FollowFormationNode = function(inst)
    return WhileNode(function() return WX78_ShadowDrone_BrainCommon.ShouldHoldFormation(inst) end, "HoldFormation",
    PriorityNode({
		NotDecorator(FailIfSuccessDecorator(Leash(inst, GetShadowDronePos, 0.5, 0.5))),
    }, .5))
end

---------------------------------------------------------------------------------------------------

local MAX_WANDER_DIST = 8

WX78_ShadowDrone_BrainCommon.WanderNode = function(inst)
	return Wander(inst, WX78_ShadowDrone_BrainCommon.GetLeaderPos, MAX_WANDER_DIST)
end

---------------------------------------------------------------------------------------------------

return WX78_ShadowDrone_BrainCommon
