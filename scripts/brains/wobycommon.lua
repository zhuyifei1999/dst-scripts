require "behaviours/doaction"
require "behaviours/faceentity"
require "behaviours/follow"
require "behaviours/runaway"

-----------------------------------------------------------------------------------------------------------------------------------

local COMBAT_TOO_CLOSE_DIST = 10 -- From wobybigbrain.lua

---------------------------------------------------------------------------------------------------------------------------------------------

local function OwnerIsClose(inst, distance)
    local owner = inst._playerlink

    return owner ~= nil and owner:IsNear(inst, distance)
end

---------------------------------------------------------------------------------------------------------------------------------------------

local function FindPickupableItem_ExtraFilter(inst, item, owner)
    if not item:IsOnPassablePoint() or item:GetCurrentPlatform() ~= inst:GetCurrentPlatform() then
        return false
    end

    -- Priorize running away, don't try to pick up items where we can't go.
    if inst.brain.runawayfrom ~= nil and inst.brain.runawayfrom:IsValid() and item:IsNear(inst.brain.runawayfrom, COMBAT_TOO_CLOSE_DIST) then
        return false
    end

    return true
end

local function DoPickUpAction(inst)
    local priorityprefabs = {}

    local items = inst.components.container:GetAllItems()

    for i, item in ipairs(items) do
        priorityprefabs[item.prefab] = true
    end

    local item =
           FindPickupableItem(inst._playerlink, TUNING.SKILLS.WALTER.FETCH_PRIORITY_MAX_DISTANCE, true, nil,                nil, priorityprefabs, false, inst, FindPickupableItem_ExtraFilter, inst.components.container)
        or FindPickupableItem(inst._playerlink, TUNING.SKILLS.WALTER.FETCH_DEFAULT_MAX_DISTANCE,  true, nil,                nil, nil,             false, inst, FindPickupableItem_ExtraFilter, inst.components.container)
        or FindPickupableItem(inst._playerlink, TUNING.SKILLS.WALTER.FETCH_DEFAULT_MAX_DISTANCE,  true, inst:GetPosition(), nil, nil,             false, inst, FindPickupableItem_ExtraFilter, inst.components.container)

    if item ~= nil then
        local action = BufferedAction(inst, item, ACTIONS.WOBY_PICKUP)

        action:AddSuccessAction(inst._onsuccessfulpraisableaction)

        return action
    end
end

local function HasPickUpBehavior(inst)
    local skilltreeupdater = inst._playerlink ~= nil and inst._playerlink.components.skilltreeupdater or nil

    return skilltreeupdater ~= nil and skilltreeupdater:IsActivated("walter_woby_itemfetcher")
end

local function IsAllowedToPickUp(inst)
    return inst.woby_commands_classified ~= nil and inst.woby_commands_classified:ShouldPickup()
end

local function FetchingActionNode(inst)
    return WhileNode(function() return IsAllowedToPickUp(inst) and HasPickUpBehavior(inst) end, "HasFetchSkill", DoAction(inst, DoPickUpAction, "DoPickUpAction", true))
end

---------------------------------------------------------------------------------------------------------------------------------------------

local function IsAllowedToRetriaveAmmo(inst)
    local equip = inst._playerlink.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

    return equip ~= nil and
        equip:HasTag("slingshot") and
        equip.components.container ~= nil and
        equip.components.container:HasItemWithTag("recoverableammo", 1)
end

local function GetRecoverableAmmoPickUpAction(inst)
    local onlytheseprefabs = {}

    local equip = inst._playerlink.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    local items = equip.components.container:GetItemsWithTag("recoverableammo")

    for i, item in ipairs(items) do
        onlytheseprefabs[item.prefab] = true
    end

    local item = FindPickupableItem(inst._playerlink, TUNING.SKILLS.WALTER.FETCH_PRIORITY_MAX_DISTANCE, true, nil, nil, onlytheseprefabs, false, inst, FindPickupableItem_ExtraFilter, inst.components.container)

    if item == nil then
        item = FindPickupableItem(inst._playerlink, TUNING.SKILLS.WALTER.FETCH_PRIORITY_MAX_DISTANCE/2, true, inst:GetPosition(), nil, onlytheseprefabs, false, inst, FindPickupableItem_ExtraFilter, inst.components.container)
    end

    if item ~= nil then
        local action = BufferedAction(inst, item, ACTIONS.WOBY_PICKUP)

        action:AddSuccessAction(inst._onsuccessfulpraisableaction)

        return action
    end
end

local function IsRecoverableAmmo(item)
    return item:HasTag("recoverableammo")
end

local function ReturnRecoverableAmmoAction(inst)
    local leader = inst._playerlink
    local leaderinv    = leader ~= nil and leader.components.inventory or nil
    local leadertrader = leader ~= nil and leader.components.trader or nil

    local item = inst.components.container:FindItem(IsRecoverableAmmo)

    if leaderinv == nil or leadertrader == nil or item == nil then
        return nil
    end

    if not leaderinv:IsOpenedBy(leader) or leaderinv:CanAcceptCount(item) <= 0 or not leadertrader:AbleToAccept(item, inst) then
        return nil
    end

    local act = BufferedAction(inst, leader, ACTIONS.GIVEALLTOPLAYER, item)

    act.distance = leader:GetPhysicsRadius(0) + .5 + (inst:HasTag("largecreature") and 1 or 0)
    act:AddSuccessAction(inst._onsuccessfulpraisableaction)

    return act
end

local function RetriaveAmmoNode(inst)
    return WhileNode(function() return HasPickUpBehavior(inst) and IsAllowedToRetriaveAmmo(inst) end, "HasPickUpBehavior",
        PriorityNode({
            WhileNode(function() return OwnerIsClose(inst, TUNING.SKILLS.WALTER.PRIORIZE_AMMO_RETURN_ACTION_DIST) end, "PriorizeReturningAmmo", DoAction(inst, ReturnRecoverableAmmoAction, "ReturnRecoverableAmmoAction", true)),
            WhileNode(function() return IsAllowedToPickUp(inst) end, "IsAllowedToPickUp", DoAction(inst, GetRecoverableAmmoPickUpAction, "RetriaveAmmoNode", true)),
            DoAction(inst, ReturnRecoverableAmmoAction, "ReturnRecoverableAmmoAction", true),
        },.25)
    )
end

-- Same as RetriaveAmmoNode, but won't give the ammo back.
local function PickUpAmmoNode(inst)
    return WhileNode(function() return HasPickUpBehavior(inst) and IsAllowedToPickUp(inst) and IsAllowedToRetriaveAmmo(inst) end, "HasFetchSkill",
       DoAction(inst, GetRecoverableAmmoPickUpAction, "PickUpAmmoNode", true)
    )
end

---------------------------------------------------------------------------------------------------------------------------------------------

local function DoForagerAction(inst)
    local target = inst:GetForagerTarget()

    if target ~= nil and target:IsValid() then
        local action = BufferedAction(inst, target, ACTIONS.WOBY_PICK)

        local _onaction = function () inst:RemoveCurrentForagerTarget() end

        action:AddSuccessAction(_onaction)
        action:AddFailAction(_onaction)

        return action
    end
end

local function HasForagingBehavior(inst)
    local skilltreeupdater = inst._playerlink ~= nil and inst._playerlink.components.skilltreeupdater or nil

    return skilltreeupdater ~= nil and skilltreeupdater:IsActivated("walter_woby_foraging")
end

local function IsAllowedToForager(inst)
    return inst.woby_commands_classified ~= nil and inst.woby_commands_classified:ShouldForage()
end

local function ForagerNode(inst)
    return WhileNode(function() return IsAllowedToForager(inst) and HasForagingBehavior(inst) end, "HasForagerSkill", DoAction(inst, DoForagerAction, "DoForagerAction", true))
end

---------------------------------------------------------------------------------------------------------------------------------------------

local function StartSitting(inst)
    local shouldsit = inst.woby_commands_classified ~= nil and inst.woby_commands_classified:ShouldSit()

    if shouldsit then
        inst:PushEvent("start_sitting")
    end

    return shouldsit
end

local function KeepSitting(inst)
    local keepsitting = inst.woby_commands_classified ~= nil and inst.woby_commands_classified:ShouldSit()

    if not keepsitting then
        inst:PushEvent("stop_sitting")

    elseif not inst.sg:HasStateTag("sitting") then
        -- We left the sitting state somehow! Go back to it...
        inst:PushEvent("start_sitting")

    elseif inst._playerlink ~= nil and inst.sg:HasStateTag("canrotate") then
        inst:ForceFacePoint(inst._playerlink.Transform:GetWorldPosition())
    end

    return keepsitting
end

local function SitStillNode(inst)
    return StandStill(inst, StartSitting, KeepSitting)
end

---------------------------------------------------------------------------------------------------------------------------------------------

local function IsTryingToPerformAction(inst, performer, action)
    local act = performer:GetBufferedAction()

    return act ~= nil and act.target == inst and act.action == action
end

local function TryingToInteractWithWoby(inst, performer)
    local interactions = { ACTIONS.FEED, ACTIONS.RUMMAGE, ACTIONS.STORE }
    for _, action in ipairs(interactions) do
        if IsTryingToPerformAction(inst, performer, action) then
            return true
        end
    end

    if inst.components.container:IsOpenedBy(performer) then
        return true
    end

    return false
end

local function GetWalterInteractionFn(inst)
   local leader = inst.components.follower ~= nil and inst.components.follower.leader
    if leader ~= nil and TryingToInteractWithWoby(inst, leader) then
        return leader
    end

    return nil
end

local function KeepGenericInteractionFn(inst, target)
    return TryingToInteractWithWoby(inst, target)
end

---------------------------------------------------------------------------------------------------------------------------------------------

local function WatchingMinigame(inst)
    return (inst.components.follower.leader ~= nil and inst.components.follower.leader.components.minigame_participator ~= nil) and inst.components.follower.leader.components.minigame_participator:GetMinigame() or nil
end
local function WatchingMinigame_MinDist(inst)
    local minigame = WatchingMinigame(inst)

    return minigame ~= nil and minigame.components.minigame.watchdist_min or 0
end

local function WatchingMinigame_TargetDist(inst)
    local minigame = WatchingMinigame(inst)

    return minigame ~= nil and minigame.components.minigame.watchdist_target or 0
end

local function WatchingMinigame_MaxDist(inst)
    local minigame = WatchingMinigame(inst)

    return minigame ~= nil and minigame.components.minigame.watchdist_max or 0
end

local function WatchingMinigameNode(inst)
    return WhileNode(function() return WatchingMinigame(inst) end, "Watching Game",
        PriorityNode{
                Follow(inst, WatchingMinigame, WatchingMinigame_MinDist, WatchingMinigame_TargetDist, WatchingMinigame_MaxDist),
                RunAway(inst, "minigame_participator", 5, 7),
                FaceEntity(inst, WatchingMinigame, WatchingMinigame ),
        }, 0.1)
end

---------------------------------------------------------------------------------------------------------------------------------------------

return {
    HasPickUpBehavior = HasPickUpBehavior,
    DoPickUpAction = DoPickUpAction,

    RetriaveAmmoNode = RetriaveAmmoNode,
    PickUpAmmoNode = PickUpAmmoNode,
    FetchingActionNode = FetchingActionNode,
    ForagerNode = ForagerNode,
    SitStillNode = SitStillNode,

    IsTryingToPerformAction  = IsTryingToPerformAction,
    TryingToInteractWithWoby = TryingToInteractWithWoby,
    GetWalterInteractionFn   = GetWalterInteractionFn,
    KeepGenericInteractionFn = KeepGenericInteractionFn,

    WatchingMinigameNode = WatchingMinigameNode,
}
