require "behaviours/runaway"

local ItemMimic_RevealedBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local UPDATE_RATE = 0.5
local AVOID_PLAYER_DIST = 4.0
local AVOID_PLAYER_STOP = 6.0
local LEASH_RANGE = TUNING.SKILLS.WX78.MIMICHEART_SPAWN_DENSITY_RANGE * 0.5 -- FIXME(JBK): WX: Move this to data stored on the inst somewhere.

local itemmimic_data = require("prefabs/itemmimic_data")

local function GetClosestPlayer(inst)
    local ix, iy, iz = inst.Transform:GetWorldPosition()
    return FindClosestPlayerInRangeSq(ix, iy, iz, AVOID_PLAYER_DIST * AVOID_PLAYER_DIST, true)
end

local function initiate_mimicry(inst, mimicable_entity)
    if mimicable_entity and mimicable_entity:IsValid()
            and mimicable_entity:HasAllTags(itemmimic_data.MUST_TAGS)
            and not mimicable_entity:HasAnyTag(itemmimic_data.CANT_TAGS) then
        local action = BufferedAction(inst, mimicable_entity, ACTIONS.NUZZLE, nil, nil, nil, 3.0)
        inst._mimicry_queued = true
        local clear_mimicry_queued = function() inst._mimicry_queued = false end
        action:AddSuccessAction(clear_mimicry_queued)
        inst:DoTaskInTime(20, clear_mimicry_queued)
        action:AddFailAction(function()
            clear_mimicry_queued(inst)
            inst:PushEvent("eye_down")
        end)
        inst.components.locomotor:PushAction(action)
    end

    inst.components.timer:StartTimer("mimic_blocker", 0.5 * TUNING.SEG_TIME)

    inst._try_mimic_task:Cancel()
    inst._try_mimic_task = nil
end

local function GetLeashPos(inst)
    return inst.components.knownlocations and inst.components.knownlocations:GetLocation("leash") or nil
end

local function IsInLeashRange(inst, ent)
    local leashpos = GetLeashPos(inst)
    if not leashpos then
        -- No leashpos means there is no leash so it is always in range.
        return true
    end

    return ent:GetDistanceSqToPoint(leashpos) < LEASH_RANGE * LEASH_RANGE
end

local function LookForMimicAction(inst)
    if inst._try_mimic_task or inst.components.timer:TimerExists("mimic_blocker") then return nil end

    local ix, iy, iz = inst.Transform:GetWorldPosition()
    local mimicables_nearby = shuffleArray(TheSim:FindEntities(
        ix, iy, iz, 15,
        itemmimic_data.MUST_TAGS, itemmimic_data.CANT_TAGS
    ))
    local found_mimicable = nil
    for _, mimicable_entity in pairs(mimicables_nearby) do
        if not mimicable_entity.components.itemmimic and IsInLeashRange(inst, mimicable_entity) then
            found_mimicable = mimicable_entity
        end
    end

    if not found_mimicable then return end

    inst._try_mimic_task = inst:DoTaskInTime(7, initiate_mimicry, found_mimicable)
    inst:PushEvent("eye_up")
end

function ItemMimic_RevealedBrain:OnStart()
    local root = PriorityNode({
        WhileNode(function() return not self.inst.sg:HasStateTag("jumping") end, "Isn't Jumping",
            PriorityNode({
                Leash(self.inst, GetLeashPos, LEASH_RANGE, LEASH_RANGE),
                WhileNode(function() return self.inst.components.timer:TimerExists("recently_spawned") end, "Just Spawned",
                    PanicAndAvoid(self.inst, GetClosestPlayer, AVOID_PLAYER_STOP)
                ),
                RunAway(self.inst, "player", AVOID_PLAYER_DIST, AVOID_PLAYER_STOP),

                FailIfSuccessDecorator(ActionNode(function() LookForMimicAction(self.inst) end, "Spy For Mimicables")),
                FailIfSuccessDecorator(ConditionWaitNode(function() return not self.inst._mimicry_queued end, "Block While Doing Mimic Action")),

                Wander(self.inst, GetLeashPos, LEASH_RANGE),
            }, UPDATE_RATE)
        ),
    }, UPDATE_RATE)

    self.bt = BT(self.inst, root)
end

return ItemMimic_RevealedBrain