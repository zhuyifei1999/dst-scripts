require "behaviours/standstill"
require "behaviours/follow"
require "behaviours/doaction"

local MIN_FOLLOW = 1
local MAX_FOLLOW = 2
local TARGET_FOLLOW = 1
local WAYPOINT_RANGE = 34

local MIN_FOLLOW_LEADER_DIST = 1
local TARGET_FOLLOW_LEADER_DIST = 2
local MAX_FOLLOW_LEADER_DIST = 4

local Archive_SecurityPulseBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetLeader(inst)
    return inst.components.follower and inst.components.follower:GetLeader()
end

local function testbetweenpoints(pt1,pt2)
    local x1,y1,z1 = pt1.Transform:GetWorldPosition()
    local x2,y2,z2 = pt2.Transform:GetWorldPosition()

    local xdiff = (x2 - x1)/2
    local zdiff = (z2 - z1)/2

    local x = x1 + xdiff
    local z = z1 + zdiff

    return TheWorld.Map:IsVisualGroundAtPoint(x,0,z)
end

local WAYPOINT_MUST_TAGS = {"archive_waypoint"}
local function findwaypoint(inst)

    local target = nil
    local x,y,z = 0,0,0
    local wp = inst.lastwaypointGUID and Ents[inst.lastwaypointGUID] or nil
    if not wp then
        -- find nearest instead.. using the inst doesnt work well.
        x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,y,z, WAYPOINT_RANGE,WAYPOINT_MUST_TAGS)
        local dist = 9999*9999
        for i,ent in ipairs(ents) do
            local testdist = inst:GetDistanceSqToInst(ent)
            if testdist < dist then
                dist = testdist
                wp = ent
            end
        end
    end
    if wp then
        x,y,z = wp.Transform:GetWorldPosition()

        local ents = TheSim:FindEntities(x,y,z, WAYPOINT_RANGE,WAYPOINT_MUST_TAGS)
        for i=#ents,1,-1 do
            if ents[i] == wp or not testbetweenpoints(wp,ents[i]) then
                table.remove(ents,i)
            end
        end

        if #ents == 1 then
            target = ents[1]
        elseif #ents > 1 then
            for i=#ents,1,-1 do
                if inst.secondlastwaypointGUID and ents[i] == Ents[inst.secondlastwaypointGUID] then
                    table.remove(ents,i)
                end
            end
            if #ents > 0 then
                target = ents[math.random(1,#ents)]
            end
        end
    end

    if target then
        inst.secondlastwaypointGUID = inst.lastwaypointGUID
        inst.lastwaypointGUID = target.GUID
    end
    return target
end

---------------------------------------------------------------------------------------------------------

local POWERPOINT_MUST_TAGS = { "security_powerpoint" }
local POWERPOINT_CANT_TAGS =  { "INLIMBO", "FX" }

local function FindPowerPoint(inst)
    local hasleader = GetLeader(inst) ~= nil

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 20, POWERPOINT_MUST_TAGS, POWERPOINT_CANT_TAGS)
    for _, ent in ipairs(ents) do
        local skip = false
        if ent.components.health then
            if hasleader or (ent.components.health:GetPercent() < (ent.MED_THRESHOLD_DOWN or 1)) then
                skip = true
            end
        end
        if not skip then
            return ent
        end
    end

    return nil
end

function Archive_SecurityPulseBrain:OnStart()
    local possession_range = self.inst.possession_range

    local MIN_FOLLOW_POWERPOINT    = possession_range
    local TARGET_FOLLOW_POWERPOINT = possession_range

    local root = PriorityNode(
    {
        Follow(self.inst, FindPowerPoint, MIN_FOLLOW_POWERPOINT, TARGET_FOLLOW_POWERPOINT, MAX_FOLLOW, false, nil, true),
        Follow(self.inst, GetLeader, MIN_FOLLOW_LEADER_DIST, TARGET_FOLLOW_LEADER_DIST, MAX_FOLLOW_LEADER_DIST, false),
        WhileNode(function() return self.inst.patrol == true end, "find waypoints",
            Follow(self.inst, findwaypoint, MIN_FOLLOW, TARGET_FOLLOW, MAX_FOLLOW, false)),
        StandStill(self.inst),
    }, .25)
    self.bt = BT(self.inst, root)
end

return Archive_SecurityPulseBrain
