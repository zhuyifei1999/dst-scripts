local assets =
{
    Asset("ANIM", "anim/knight.zip"),
    Asset("ANIM", "anim/knight_build.zip"),
    Asset("ANIM", "anim/knight_nightmare.zip"),
    Asset("SOUND", "sound/chess.fsb"),
}

local prefabs =
{
    "gears",
}

local prefabs_nightmare =
{
    "gears",
    "thulecite_pieces",
    "nightmarefuel",
}

local brain = require "brains/knightbrain"

SetSharedLootTable('knight',
{
    {'gears',  1.0},
    {'gears',  1.0},
})

SetSharedLootTable('knight_nightmare',
{
    {'gears',             1.0},
    {'nightmarefuel',     0.6},
    {'thulecite_pieces',  0.5},
})

local SLEEP_DIST_FROMHOME_SQ = 1 * 1
local SLEEP_DIST_FROMTHREAT = 20
local MAX_CHASEAWAY_DIST = 40
local MAX_CHASEAWAY_DIST_SQ = MAX_CHASEAWAY_DIST * MAX_CHASEAWAY_DIST
local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 40

local function BasicWakeCheck(inst)
    return (inst.components.combat ~= nil and inst.components.combat.target ~= nil)
        or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning())
        or (inst.components.freezable ~= nil and inst.components.freezable:IsFrozen())
        or GetClosestInstWithTag("character", inst, SLEEP_DIST_FROMTHREAT) ~= nil
end

local function ShouldSleep(inst)
    local homePos = inst.components.knownlocations:GetLocation("home")
    return homePos ~= nil
        and inst:GetDistanceSqToPoint(homePos:Get()) < SLEEP_DIST_FROMHOME_SQ
        and not BasicWakeCheck(inst)
end

local function ShouldWake(inst)
    local homePos = inst.components.knownlocations:GetLocation("home")
    return (homePos ~= nil and
            inst:GetDistanceSqToPoint(homePos:Get()) >= SLEEP_DIST_FROMHOME_SQ)
        or BasicWakeCheck(inst)
end

local function Retarget(inst)
    local homePos = inst.components.knownlocations:GetLocation("home")
    return not (homePos ~= nil and
                inst:GetDistanceSqToPoint(homePos:Get()) >= TUNING.KNIGHT_TARGET_DIST * TUNING.KNIGHT_TARGET_DIST and
                (inst.components.follower == nil or inst.components.follower.leader == nil))
        and FindEntity(
            inst,
            TUNING.KNIGHT_TARGET_DIST,
            function(guy)
                local myLeader = inst.components.follower ~= nil and inst.components.follower.leader or nil
                if myLeader == guy then
                    return false
                end
                local theirLeader = guy.components.follower ~= nil and guy.components.follower.leader or nil
                local bothFollowingSamePlayer = myLeader ~= nil and myLeader == theirLeader and myLeader:HasTag("player")
                return not bothFollowingSamePlayer
                    and not (guy:HasTag("chess") and theirLeader == nil)
                    and inst.components.combat:CanTarget(guy)
            end,
            { "_combat" },
            { "INLIMBO" },
            { "character", "monster" }
        )
        or nil
end

local function KeepTarget(inst, target)
    if inst.components.follower ~= nil and inst.components.follower.leader ~= nil then
        return true
    end
    local homePos = inst.components.knownlocations:GetLocation("home")
    return homePos ~= nil and target:GetDistanceSqToPoint(homePos:Get()) < MAX_CHASEAWAY_DIST_SQ
end

local function IsChess(dude)
    return dude:HasTag("chess")
end

local function OnAttacked(inst, data)
    local attacker = data ~= nil and data.attacker or nil
    if attacker ~= nil and attacker:HasTag("chess") then
        return
    end
    inst.components.combat:SetTarget(attacker)
    inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, IsChess, MAX_TARGET_SHARES)
end
 
local function RememberKnownLocation(inst)
    inst.components.knownlocations:RememberLocation("home", inst:GetPosition())
end

local function fn_common(build, tag)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 50, .5)

    inst.DynamicShadow:SetSize(1.5, .75)
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("knight")
    inst.AnimState:SetBuild(build)

    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("chess")
    inst:AddTag("knight")

    if tag ~= nil then
        inst:AddTag(tag)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.kind = ""

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.KNIGHT_WALK_SPEED

    inst:SetStateGraph("SGknight")

    inst:SetBrain(brain)

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetWakeTest(ShouldWake)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetResistance(3)

    inst:AddComponent("health")
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "spring"
    inst.components.combat:SetAttackPeriod(TUNING.KNIGHT_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(3, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)

    inst.components.health:SetMaxHealth(TUNING.KNIGHT_HEALTH)
    inst.components.combat:SetDefaultDamage(TUNING.KNIGHT_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.KNIGHT_ATTACK_PERIOD)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('knight')

    inst:AddComponent("inspectable")
    inst:AddComponent("knownlocations")

    inst:DoTaskInTime(0, RememberKnownLocation)

    inst:AddComponent("follower")

    MakeMediumBurnableCharacter(inst, "spring")
    MakeMediumFreezableCharacter(inst, "spring")

    MakeHauntablePanic(inst)

    inst:ListenForEvent("attacked", OnAttacked)

    return inst
end

local function fn()
    local inst = fn_common("knight_build")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.kind = ""

    return inst
end

local function nightmarefn()
    local inst = fn_common("knight_nightmare", "cavedweller")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.kind = "_nightmare"
    inst.components.lootdropper:SetChanceLootTable("knight_nightmare")
    return inst
end

return Prefab("chessboard/knight", fn, assets, prefabs),
    Prefab("cave/monsters/knight_nightmare", nightmarefn, assets, prefabs_nightmare)
