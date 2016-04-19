require "behaviours/wander"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/panic"

local STOP_RUN_DIST = 10
local SEE_PLAYER_DIST = 5
local SEE_FOOD_DIST = 20
local SEE_BUSH_DIST = 40
local MAX_WANDER_DIST = 80

local PerdBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function FindNearestBush(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, SEE_BUSH_DIST, { "bush" })
    local emptybush = nil
    for i, v in ipairs(ents) do
        if v ~= inst and v.entity:IsVisible() and v.components.pickable ~= nil then
            if v.components.pickable:CanBePicked() then
                return v
            elseif emptybush == nil then
                emptybush = v
            end
        end
    end
    return emptybush
        or (inst.components.homeseeker ~= nil and inst.components.homeseeker.home)
        or nil
end

local function HomePos(inst)
    local bush = FindNearestBush(inst)
    return bush ~= nil and bush:GetPosition() or nil
end

local function GoHomeAction(inst)
    local bush = FindNearestBush(inst)
    return bush ~= nil and BufferedAction(inst, bush, ACTIONS.GOHOME, nil, bush:GetPosition()) or nil
end

local function EatFoodAction(inst)
    local target =
        inst.components.inventory ~= nil and
        inst.components.eater ~= nil and
        inst.components.inventory:FindItem(
            function(item)
                return inst.components.eater:CanEat(item)
            end)
        or nil

    if target == nil then
        target = FindEntity(inst, SEE_FOOD_DIST, nil, { "edible_"..FOODTYPE.VEGGIE }, { "INLIMBO" })
        --check for scary things near the food
        if target ~= nil and
            GetClosestInstWithTag("scarytoprey", target, SEE_PLAYER_DIST) ~= nil then
            target = nil
        end
    end

    if target ~= nil then
        local act = BufferedAction(inst, target, ACTIONS.EAT)
        act.validfn = function()
            return target.components.inventoryitem == nil
                or target.components.inventoryitem.owner == nil
                or target.components.inventoryitem.owner == inst
        end
        return act
    end
end

local function HasBerry(item)
    return item.components.pickable ~= nil and (item.components.pickable.product == "berries" or item.components.pickable.product == "berries_juicy")
end

local function PickBerriesAction(inst)
    local target = FindEntity(inst, SEE_FOOD_DIST, HasBerry, { "pickable" })
    --check for scary things near the bush
    return target ~= nil
        and GetClosestInstWithTag("scarytoprey", target, SEE_PLAYER_DIST) == nil
        and BufferedAction(inst, target, ACTIONS.PICK)
        or nil
end

function PerdBrain:OnStart()
    local root = PriorityNode(
    {
        WhileNode(function() return self.inst.components.hauntable ~= nil and self.inst.components.hauntable.panic end, "PanicHaunted", Panic(self.inst)),
        WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),
        WhileNode(function() return not TheWorld.state.isday end, "IsNight", DoAction(self.inst, GoHomeAction, "Go Home", true)),
        DoAction(self.inst, EatFoodAction, "Eat Food"),
        RunAway(self.inst, "scarytoprey", SEE_PLAYER_DIST, STOP_RUN_DIST),
        DoAction(self.inst, PickBerriesAction, "Pick Berries", true),
        Wander(self.inst, HomePos, MAX_WANDER_DIST),
    }, .25)
    self.bt = BT(self.inst, root)
end

return PerdBrain
