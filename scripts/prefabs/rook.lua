local assets =
{
    Asset("ANIM", "anim/rook.zip"),
    Asset("ANIM", "anim/rook_build.zip"),
    Asset("ANIM", "anim/rook_nightmare.zip"),
    Asset("SOUND", "sound/chess.fsb"),
}

local prefabs =
{
    "gears",
    "thulecite_pieces",
    "nightmarefuel",
    "collapse_small",
}

local brain = require "brains/rookbrain"

SetSharedLootTable( 'rook',
{
    {'gears',  1.0},
    {'gears',  1.0},
})

SetSharedLootTable( 'rook_nightmare',
{
    {'gears',            1.0},
    {'nightmarefuel',    0.6},
    {'thulecite_pieces', 0.5},
})

local SLEEP_DIST_FROMHOME_SQ = 1 * 1
local SLEEP_DIST_FROMTHREAT = 20
local MAX_CHASEAWAY_DIST_SQ = 40 * 40
local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 40

local function ShouldSleep(inst)
    local homePos = inst.components.knownlocations:GetLocation("home")
    return homePos ~= nil
        and inst:GetDistanceSqToPoint(homePos:Get()) <= SLEEP_DIST_FROMHOME_SQ
        and (inst.components.combat == nil or inst.components.combat.target == nil)
        and (inst.components.burnable == nil or not inst.components.burnable:IsBurning())
        and (inst.components.freezable == nil or not inst.components.freezable:IsFrozen())
        and GetClosestInstWithTag("character", inst, SLEEP_DIST_FROMTHREAT) == nil
end

local function ShouldWake(inst)
    local homePos = inst.components.knownlocations:GetLocation("home")
    return (homePos ~= nil and
            inst:GetDistanceSqToPoint(homePos:Get()) > SLEEP_DIST_FROMHOME_SQ)
        or (inst.components.combat ~= nil and inst.components.combat.target ~= nil)
        or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning())
        or (inst.components.freezable ~= nil and inst.components.freezable:IsFrozen())
        or GetClosestInstWithTag("character", inst, SLEEP_DIST_FROMTHREAT) ~= nil
end

local function Retarget(inst)
    local homePos = inst.components.knownlocations:GetLocation("home")
    if (homePos ~= nil and inst:GetDistanceSqToPoint(homePos:Get()) > MAX_CHASEAWAY_DIST_SQ)
        and (inst.components.follower == nil or inst.components.follower.leader == nil) then
        --no leader, and i'm far from home
        return
    end
    local myLeader = inst.components.follower ~= nil and inst.components.follower.leader or nil
    return FindEntity(inst, TUNING.ROOK_TARGET_DIST,
        function(guy)
            if myLeader == guy then
                return
            end
            local theirLeader = guy.components.follower ~= nil and guy.components.follower.leader or nil
            return (myLeader == nil or myLeader ~= theirLeader) --check same leader
                and (theirLeader ~= nil or not guy:HasTag("chess")) --can't hit other chess pieces unless they are following someone else
                and inst.components.combat:CanTarget(guy)
        end,
        { "_combat", "_health" }, --see entityreplica.lua
        { "INLIMBO" },
        { "character", "monster" }
    )
end

local function KeepTarget(inst, target)
    if (inst.components.follower ~= nil and inst.components.follower.leader ~= nil) or
        (inst.sg ~= nil and inst.sg:HasStateTag("running")) then
        return true
    end
    local homePos = inst.components.knownlocations:GetLocation("home")
    return homePos ~= nil and inst:GetDistanceSqToPoint(homePos:Get()) <= MAX_CHASEAWAY_DIST_SQ
end

local function IsChess(dude)
    return dude:HasTag("chess")
end

local function OnAttacked(inst, data)
    if data ~= nil and data.attacker ~= nil and not data.attacker:HasTag("chess") then
        inst.components.combat:SetTarget(data.attacker)
        inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST, IsChess, MAX_TARGET_SHARES)
    end
end

local function ClearRecentlyCharged(inst, other)
    inst.recentlycharged[other] = nil
end

local function onothercollide(inst, other)
    if not other:IsValid() then
        return
    elseif other:HasTag("smashable") then
        --other.Physics:SetCollides(false)
        other.components.health:Kill()
    elseif other.components.workable ~= nil and other.components.workable:CanBeWorked() then
        SpawnPrefab("collapse_small").Transform:SetPosition(other.Transform:GetWorldPosition())
        other.components.workable:Destroy(inst)
    elseif not inst.recentlycharged[other] and other.components.health ~= nil and not other.components.health:IsDead() then
        inst.recentlycharged[other] = true
        inst:DoTaskInTime(3, ClearRecentlyCharged, other)
        inst.components.combat:DoAttack(other, inst.weapon)
        inst.SoundEmitter:PlaySound("dontstarve/creatures/rook/explo")
    end
end

local function oncollide(inst, other)
    if not (other ~= nil and other:IsValid() and inst:IsValid())
        or other:HasTag("player")
        or Vector3(inst.Physics:GetVelocity()):LengthSq() < 42 then
        return
    end

    for i, v in ipairs(AllPlayers) do
        v:ShakeCamera(CAMERASHAKE.SIDE, .5, .05, .1, inst, 40)
    end

    inst:DoTaskInTime(2 * FRAMES, onothercollide, other)
end

local function CreateWeapon(inst)
    local weapon = CreateEntity()
    --[[Non-networked entity]]
    weapon.entity:AddTransform()
    weapon:AddComponent("weapon")
    weapon.components.weapon:SetDamage(200)
    weapon.components.weapon:SetRange(0)
    weapon:AddComponent("inventoryitem")
    weapon.persists = false
    weapon.components.inventoryitem:SetOnDroppedFn(weapon.Remove)
    weapon:AddComponent("equippable")
    inst.components.inventory:GiveItem(weapon)
    inst.weapon = weapon
end

local function RememberKnownLocation(inst)
    inst.components.knownlocations:RememberLocation("home", inst:GetPosition())
end

local function common_fn(build)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 50, 1.5)

    inst.DynamicShadow:SetSize(3, 1.25)
    inst.Transform:SetFourFaced()
    inst.Transform:SetScale(0.66, 0.66, 0.66)

    inst.AnimState:SetBank("rook")
    inst.AnimState:SetBuild(build)

    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("chess")
    inst:AddTag("rook")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.recentlycharged = {}
    inst.Physics:SetCollisionCallback(oncollide)

    inst:AddComponent("lootdropper")

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.ROOK_WALK_SPEED
    inst.components.locomotor.runspeed =  TUNING.ROOK_RUN_SPEED

    inst:SetStateGraph("SGrook")
    inst:SetBrain(brain)

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetWakeTest(ShouldWake)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetResistance(3)

    inst:AddComponent("health")
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "spring"
    inst.components.combat:SetAttackPeriod(2)
    inst.components.combat:SetRetargetFunction(3, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)

    inst.components.health:SetMaxHealth(TUNING.ROOK_HEALTH)
    inst.components.combat:SetDefaultDamage(TUNING.ROOK_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.ROOK_ATTACK_PERIOD)
    --inst.components.combat.playerdamagepercent = 2

    inst:AddComponent("follower")

    inst:AddComponent("inventory")

    inst:AddComponent("inspectable")
    inst:AddComponent("knownlocations")

    MakeHauntablePanic(inst)

    inst:DoTaskInTime(2*FRAMES, RememberKnownLocation)

    MakeMediumBurnableCharacter(inst, "spring")
    MakeMediumFreezableCharacter(inst, "spring")

    inst:ListenForEvent("attacked", OnAttacked)

    CreateWeapon(inst)

    --inst:AddComponent("debugger")

    return inst
end

local function rook_fn()
    local inst = common_fn("rook_build")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.lootdropper:SetChanceLootTable('rook')

    inst.kind = ""
    inst.soundpath = "dontstarve/creatures/rook/"
    inst.effortsound = "dontstarve/creatures/rook/steam"

    return inst
end

local function rook_nightmare_fn()
    local inst = common_fn("rook_nightmare")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.lootdropper:SetChanceLootTable('rook_nightmare')

    inst.kind = "_nightmare"
    inst.soundpath = "dontstarve/creatures/rook_nightmare/"
    inst.effortsound = "dontstarve/creatures/rook_nightmare/rattle"
    --TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.soundpath .. "steam") end ),

    return inst
end

return Prefab("chessboard/rook", rook_fn, assets, prefabs),
    Prefab("cave/monsters/rook_nightmare", rook_nightmare_fn, assets, prefabs)
