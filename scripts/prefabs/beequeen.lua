local assets =
{
    Asset("ANIM", "anim/bee_queen_basic.zip"),
    Asset("ANIM", "anim/bee_queen_actions.zip"),
    Asset("ANIM", "anim/bee_queen_build.zip"),
}

local prefabs =
{
    "beeguard",
    "royal_jelly",
    "honeycomb",
    "honey",
    "stinger",
}

SetSharedLootTable( 'beequeen',
{
    {'royal_jelly',      1.00},
    {'royal_jelly',      1.00},
    {'royal_jelly',      1.00},
    {'royal_jelly',      1.00},
    {'royal_jelly',      0.50},
    {'honeycomb',        1.00},
    {'honeycomb',        0.50},
    {'honey',            1.00},
    {'honey',            1.00},
    {'honey',            1.00},
    {'honey',            0.50},
    {'stinger',          1.00},
})

--------------------------------------------------------------------------

local brain = require("brains/beequeenbrain")

--------------------------------------------------------------------------

local PHYS_RAD = 1.4

local function UpdatePlayerTargets(inst)
    local toadd = {}
    local toremove = {}
    local pos = inst.components.knownlocations:GetLocation("spawnpoint")

    for k, v in pairs(inst.components.grouptargeter:GetTargets()) do
        toremove[k] = true
    end
    for i, v in ipairs(FindPlayersInRange(pos.x, pos.y, pos.z, TUNING.BEEQUEEN_DEAGGRO_DIST, true)) do
        if toremove[v] then
            toremove[v] = nil
        else
            table.insert(toadd, v)
        end
    end

    for k, v in pairs(toremove) do
        inst.components.grouptargeter:RemoveTarget(k)
    end
    for i, v in ipairs(toadd) do
        inst.components.grouptargeter:AddTarget(v)
    end
end

local function RetargetFn(inst)
    UpdatePlayerTargets(inst)

    local target = inst.components.combat.target
    local range = TUNING.BEEQUEEN_AGGRO_DIST

    if target ~= nil then
        local meleerange = TUNING.BEEQUEEN_ATTACK_RANGE + PHYS_RAD
        if inst:IsNear(target, meleerange) then
            range = meleerange
        end
        if target:HasTag("player") then
            local newplayer = inst.components.grouptargeter:TryGetNewTarget()
            return newplayer ~= nil and newplayer:IsNear(inst, range) and newplayer or nil, true
        end
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local nearplayers = FindPlayersInRange(x, y, z, range, true)
    return #nearplayers > 0 and nearplayers[math.random(#nearplayers)] or nil, true
end

local function KeepTargetFn(inst, target)
    return inst.components.combat:CanTarget(target)
        and target:GetDistanceSqToPoint(inst.components.knownlocations:GetLocation("spawnpoint")) < TUNING.BEEQUEEN_DEAGGRO_DIST * TUNING.BEEQUEEN_DEAGGRO_DIST
end

local function OnAttacked(inst, data)
    if not (inst.components.combat:HasTarget() and
            inst.components.combat.target:HasTag("player") and
            inst.components.combat.target:IsNear(inst, TUNING.BEEQUEEN_AGGRO_DIST)) then
        inst.components.combat:SetTarget(data.attacker)
    end
    inst.components.commander:ShareTargetToAllSoldiers(data.attacker)
end

--------------------------------------------------------------------------

local PHASE2_HEALTH = .75
local PHASE3_HEALTH = .5
local PHASE4_HEALTH = .25

local function SetPhaseLevel(inst, phase)
    inst.focustarget_cd = TUNING.BEEQUEEN_FOCUSTARGET_CD[phase]
    inst.spawnguards_cd = TUNING.BEEQUEEN_SPAWNGUARDS_CD[phase]
    inst.spawnguards_maxchain = TUNING.BEEQUEEN_SPAWNGUARDS_CHAIN[phase]
    inst.spawnguards_threshold = phase > 1 and TUNING.BEEQUEEN_TOTAL_GUARDS or 1
end

local function EnterPhase2Trigger(inst)
    SetPhaseLevel(inst, 2)
    inst:PushEvent("screech")
end

local function EnterPhase3Trigger(inst)
    SetPhaseLevel(inst, 3)
    inst:PushEvent("screech")
end

local function EnterPhase4Trigger(inst)
    SetPhaseLevel(inst, 4)
    inst:PushEvent("screech")
end

local function OnLoad(inst, data)
    local healthpct = inst.components.health:GetPercent()
    SetPhaseLevel(
        inst,
        (healthpct > PHASE2_HEALTH and 1) or
        (healthpct > PHASE3_HEALTH and 2) or
        (healthpct > PHASE4_HEALTH and 3) or
        4
    )
end

--------------------------------------------------------------------------

local function ShouldSleep(inst)
    return false
end

local function ShouldWake(inst)
    return true
end

--------------------------------------------------------------------------

local function OnEntitySleep(inst)
    if inst._sleeptask ~= nil then
        inst._sleeptask:Cancel()
    end
    inst._sleeptask = not inst.components.health:IsDead() and inst:DoTaskInTime(10, inst.Remove) or nil
end

local function OnEntityWake(inst)
    if inst._sleeptask ~= nil then
        inst._sleeptask:Cancel()
        inst._sleeptask = nil
    end
end

--------------------------------------------------------------------------

local function PushMusic(inst)
    if ThePlayer == nil then
        inst._playingmusic = false
    elseif ThePlayer:IsNear(inst, inst._playingmusic and 30 or 20) then
        inst._playingmusic = true
        ThePlayer:PushEvent("triggeredevent", { name = "beequeen" })
    elseif inst._playingmusic and not ThePlayer:IsNear(inst, 40) then
        inst._playingmusic = false
    end
end

--------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddDynamicShadow()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetSixFaced()
    inst.Transform:SetScale(1.4, 1.4, 1.4)

    inst.DynamicShadow:SetSize(4, 2)

    MakeFlyingGiantCharacterPhysics(inst, 500, PHYS_RAD)

    inst.AnimState:SetBank("bee_queen")
    inst.AnimState:SetBuild("bee_queen_build")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst:AddTag("epic")
    inst:AddTag("bee")
    inst:AddTag("insect")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")
    inst:AddTag("flying")

    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bee_queen/wings_LP", "flying")

    inst._playingmusic = false
    inst:DoPeriodicTask(1, PushMusic, 0)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable:RecordViews()

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('beequeen') 

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(4)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWake)
    inst.components.sleeper.diminishingreturns = true

    inst:AddComponent("locomotor")
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorewalls = true }
    inst.components.locomotor.walkspeed = TUNING.BEEQUEEN_SPEED

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.BEEQUEEN_HEALTH)
    inst.components.health.nofadeout = true

    inst:AddComponent("healthtrigger")
    inst.components.healthtrigger:AddTrigger(PHASE2_HEALTH, EnterPhase2Trigger)
    inst.components.healthtrigger:AddTrigger(PHASE3_HEALTH, EnterPhase3Trigger)
    inst.components.healthtrigger:AddTrigger(PHASE4_HEALTH, EnterPhase4Trigger)

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.BEEQUEEN_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.BEEQUEEN_ATTACK_PERIOD)
    inst.components.combat.playerdamagepercent = .5
    inst.components.combat:SetRange(TUNING.BEEQUEEN_ATTACK_RANGE, TUNING.BEEQUEEN_HIT_RANGE)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat.battlecryenabled = false
    inst.components.combat.hiteffectsymbol = "hive_body"

    inst:AddComponent("grouptargeter")
    inst:AddComponent("commander")
    inst.components.commander:SetTrackingDistance(40)

    inst:AddComponent("timer")

    inst:AddComponent("epicscare")
    inst.components.epicscare:SetRange(TUNING.BEEQUEEN_EPICSCARE_RANGE)

    inst:AddComponent("knownlocations")

    MakeLargeBurnableCharacter(inst, "swap_fire")
    MakeHugeFreezableCharacter(inst, "hive_body")
    inst.components.freezable.diminishingreturns = true

    inst:SetStateGraph("SGbeequeen")
    inst:SetBrain(brain)

    inst.hit_recovery = 2
    inst.spawnguards_chain = 0
    SetPhaseLevel(inst, 1)

    inst.OnLoad = OnLoad
    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake

    inst:ListenForEvent("attacked", OnAttacked)

    return inst
end

return Prefab("beequeen", fn, assets, prefabs)
