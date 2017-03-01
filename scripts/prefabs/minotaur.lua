local RuinsRespawner = require "prefabs/ruinsrespawner"

local assets =
{
    Asset("ANIM", "anim/rook.zip"),
    Asset("ANIM", "anim/rook_build.zip"),
    Asset("ANIM", "anim/rook_rhino.zip"),
    Asset("SOUND", "sound/chess.fsb"),
    Asset("SCRIPT", "scripts/prefabs/ruinsrespawner.lua"),
}

local prefabs =
{
    "meat",
    "minotaurhorn",
    "collapse_small",
    "minotaur_ruinsrespawner_inst",
}

local brain = require "brains/minotaurbrain"

SetSharedLootTable('minotaur',
{
    {"meat",        1.00},
    {"meat",        1.00},
    {"meat",        1.00},
    {"meat",        1.00},
    {"meat",        1.00},
    {"meat",        1.00},
    {"meat",        1.00},
    {"meat",        1.00},
    {"minotaurhorn",1.00},
})

local SLEEP_DIST_FROMHOME_SQ = 20 * 20
local SLEEP_DIST_FROMTHREAT = 40
local MAX_CHASEAWAY_DIST_SQ = 40 * 40
local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 40

local function BasicWakeCheck(inst)
    return (inst.components.combat ~= nil and inst.components.combat.target ~= nil)
        or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning() ~= nil)
        or (inst.components.freezable ~= nil and inst.components.freezable:IsFrozen() ~= nil)
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
                inst:GetDistanceSqToPoint(homePos:Get()) >= MAX_CHASEAWAY_DIST_SQ)
        and FindEntity(
            inst,
            TUNING.MINOTAUR_TARGET_DIST,
            function(guy)
                return not (inst.components.follower ~= nil and inst.components.follower.leader == guy)
                       and inst.components.combat:CanTarget(guy)
            end,
            { "_combat" },
            { "chess", "INLIMBO" },
            { "character", "monster" }
        )
        or nil
end

local function KeepTarget(inst, target)
    if inst.sg ~= nil and inst.sg:HasStateTag("running") then
        return true
    end
    local homePos = inst.components.knownlocations:GetLocation("home")
    return homePos ~= nil and inst:GetDistanceSqToPoint(homePos:Get()) < MAX_CHASEAWAY_DIST_SQ
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

local function ClearRecentlyCharged(inst, other)
    inst.recentlycharged[other] = nil
end

local function onothercollide(inst, other)
    if not other:IsValid() or inst.recentlycharged[other] then
        return
    elseif other:HasTag("smashable") and other.components.health ~= nil then
        --other.Physics:SetCollides(false)
        other.components.health:Kill()
    elseif other.components.workable ~= nil
        and other.components.workable:CanBeWorked()
        and other.components.workable.action ~= ACTIONS.NET then
        SpawnPrefab("collapse_small").Transform:SetPosition(other.Transform:GetWorldPosition())
        other.components.workable:Destroy(inst)
        if other:IsValid() and other.components.workable ~= nil and other.components.workable:CanBeWorked() then
            inst.recentlycharged[other] = true
            inst:DoTaskInTime(3, ClearRecentlyCharged, other)
        end
    elseif other.components.health ~= nil and not other.components.health:IsDead() then
        inst.recentlycharged[other] = true
        inst:DoTaskInTime(3, ClearRecentlyCharged, other)
        SpawnPrefab("collapse_small").Transform:SetPosition(other.Transform:GetWorldPosition())
        inst.SoundEmitter:PlaySound("dontstarve/creatures/rook/explo")
        inst.components.combat:DoAttack(other)
    end
end

local function oncollide(inst, other)
    if not (other ~= nil and other:IsValid() and inst:IsValid())
        or inst.recentlycharged[other]
        or other:HasTag("player")
        or Vector3(inst.Physics:GetVelocity()):LengthSq() < 42 then
        return
    end
    ShakeAllCameras(CAMERASHAKE.SIDE, .5, .05, .1, inst, 40)
    inst:DoTaskInTime(2 * FRAMES, onothercollide, other)
end

local function dospawnchest(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/ghost_spawn")

    local chest = SpawnPrefab("minotaurchest")
    local x, y, z = inst.Transform:GetWorldPosition()
    chest.Transform:SetPosition(x, 0, z)

    local fx = SpawnPrefab("statue_transition_2")
    if fx ~= nil then
        fx.Transform:SetPosition(x, y, z)
        fx.Transform:SetScale(1, 2, 1)
    end

    fx = SpawnPrefab("statue_transition")
    if fx ~= nil then
        fx.Transform:SetPosition(x, y, z)
        fx.Transform:SetScale(1, 1.5, 1)
    end

    chest:AddComponent("scenariorunner")
    chest.components.scenariorunner:SetScript("chest_minotaur")
    chest.components.scenariorunner:Run()
end

local function spawnchest(inst)
    inst:DoTaskInTime(3, dospawnchest)
end

local function rememberhome(inst)
    inst.components.knownlocations:RememberLocation("home", inst:GetPosition())
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(5, 3)
    inst.Transform:SetFourFaced()

    MakeCharacterPhysics(inst, 100, 2.2)
    inst.Physics:SetCylinder(2.2, 4)

    inst.AnimState:SetBank("rook")
    inst.AnimState:SetBuild("rook_rhino")

    inst:AddTag("cavedweller")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("minotaur")
    inst:AddTag("epic")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.recentlycharged = {}
    inst.Physics:SetCollisionCallback(oncollide)

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.MINOTAUR_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.MINOTAUR_RUN_SPEED

    inst:SetStateGraph("SGminotaur")

    inst:SetBrain(brain)

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetWakeTest(ShouldWake)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetResistance(3)

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "spring"
    inst.components.combat:SetAttackPeriod(TUNING.MINOTAUR_ATTACK_PERIOD)
    inst.components.combat:SetDefaultDamage(TUNING.MINOTAUR_DAMAGE)
    inst.components.combat:SetRetargetFunction(3, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetRange(3, 4)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.MINOTAUR_HEALTH)

    inst:ListenForEvent("death", spawnchest)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('minotaur')

    inst:AddComponent("inspectable")
    inst:AddComponent("knownlocations")

    inst:DoTaskInTime(0, rememberhome)

    MakeMediumBurnableCharacter(inst, "spring")
    MakeMediumFreezableCharacter(inst, "spring")

    inst:ListenForEvent("attacked", OnAttacked)

    return inst
end

local function onruinsrespawn(inst)

end

return Prefab("minotaur", fn, assets, prefabs),
    RuinsRespawner.Inst("minotaur", onruinsrespawn), RuinsRespawner.WorldGen("minotaur", onruinsrespawn)
