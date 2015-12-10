local brain = require("brains/dragonflybrain")

local assets = 
{
    Asset("ANIM", "anim/dragonfly_build.zip"),
    Asset("ANIM", "anim/dragonfly_fire_build.zip"),
    Asset("ANIM", "anim/dragonfly_basic.zip"),
    Asset("ANIM", "anim/dragonfly_actions.zip"),
}

local prefabs =
{
    "firesplash_fx",
    "tauntfire_fx",
    "attackfire_fx",
    "vomitfire_fx",
    "firering_fx",

    --loot:
    "dragon_scales",
    "lavae_egg",
    "meat",
    "goldnugget",
    "redgem",
    "bluegem",
    "purplegem",
    "orangegem",
    "yellowgem",
    "greengem",
}

SetSharedLootTable('dragonfly',
{
    {'dragon_scales',    1.00},
    {'lavae_egg',        0.33},
    
    {'meat',             1.00},
    {'meat',             1.00},
    {'meat',             1.00},
    {'meat',             1.00},
    {'meat',             1.00},
    {'meat',             1.00},
    
    {'goldnugget',       1.00},
    {'goldnugget',       1.00},
    {'goldnugget',       1.00},
    {'goldnugget',       1.00},
    
    {'goldnugget',       0.50},
    {'goldnugget',       0.50},
    {'goldnugget',       0.50},
    {'goldnugget',       0.50},
    
    {'redgem',           1.00},
    {'bluegem',          1.00},
    {'purplegem',        1.00},
    {'orangegem',        1.00},
    {'yellowgem',        1.00},
    {'greengem',         1.00},

    {'redgem',           1.00},
    {'bluegem',          1.00},
    {'purplegem',        0.50},
    {'orangegem',        0.50},
    {'yellowgem',        0.50},
    {'greengem',         0.50},
})

local function UpdateFreezeThreshold(inst)
    inst.components.freezable:SetResistance(
        TUNING.DRAGONFLY_FREEZE_THRESHOLD +
        inst.freezable_extra_resist +
        (inst.enraged and TUNING.DRAGONFLY_ENRAGED_FREEZE_BONUS or 0)
    )
end

local function TransformNormal(inst)
    inst.AnimState:SetBuild("dragonfly_build")
    inst.enraged = false
    --Set normal stats
    inst.components.locomotor.walkspeed = TUNING.DRAGONFLY_SPEED
    inst.components.combat:SetDefaultDamage(TUNING.DRAGONFLY_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.DRAGONFLY_ATTACK_PERIOD)
    inst.components.combat:SetRange(TUNING.DRAGONFLY_ATTACK_RANGE, TUNING.DRAGONFLY_HIT_RANGE)

    UpdateFreezeThreshold(inst)

    inst.components.propagator:StopSpreading()
    inst.Light:Enable(false)
end

local function _OnRevert(inst)
    inst.reverttask = nil
    if inst.enraged then 
        inst:PushEvent("transform", { transformstate = "normal" })
    end
end

local function TransformFire(inst)
    inst.AnimState:SetBuild("dragonfly_fire_build")
    inst.enraged = true
    inst.can_ground_pound = true
    --Set fire stats
    inst.components.locomotor.walkspeed = TUNING.DRAGONFLY_FIRE_SPEED
    inst.components.combat:SetDefaultDamage(TUNING.DRAGONFLY_FIRE_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.DRAGONFLY_FIRE_ATTACK_PERIOD)
    inst.components.combat:SetRange(TUNING.DRAGONFLY_ATTACK_RANGE, TUNING.DRAGONFLY_FIRE_HIT_RANGE)

    inst.Light:Enable(true)
    inst.components.propagator:StartSpreading()

    inst.components.moisture:DoDelta(-inst.components.moisture:GetMoisture())

    UpdateFreezeThreshold(inst)

    if inst.reverttask ~= nil then
        inst.reverttask:Cancel()
    end
    inst.reverttask = inst:DoTaskInTime(TUNING.DRAGONFLY_ENRAGE_DURATION, _OnRevert)
end

local function IsFightingPlayers(inst)
    return inst.components.combat.target ~= nil and inst.components.combat.target:HasTag("player")
end

local function UpdatePlayerTargets(inst)
    local toadd = {}
    local toremove = {}
    local pos = inst.components.knownlocations:GetLocation("spawnpoint")

    for k, v in pairs(inst.components.grouptargeter:GetTargets()) do
        toremove[k] = true
    end
    for i, v in ipairs(FindPlayersInRange(pos.x, pos.y, pos.z, TUNING.DRAGONFLY_RESET_DIST, true)) do
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

local function TryGetNewTarget(inst)
    UpdatePlayerTargets(inst)

    local new_target = inst.components.grouptargeter:SelectTarget()
    if new_target ~= nil then
        inst.components.combat:SetTarget(new_target)
    end
end

local function ResetLavae(inst)
    --Despawn all lavae
    local lavae = inst.components.rampingspawner.spawns
    for k, v in pairs(lavae) do
        k.components.combat:SetTarget(nil)
        k.components.locomotor:Clear()
        k.reset = true
    end
end

local function SoftReset(inst)
    inst.SoftResetTask = nil
    --Double check for nearby players & combat targets before reseting.
    TryGetNewTarget(inst)
    if inst.components.combat:HasTarget() then
        return
    end

    print(string.format("Dragonfly - Execute soft reset @ %2.2f", GetTime()))

    ResetLavae(inst)
    inst.playercombat = false
    inst.freezable_extra_resist = 0
    inst.components.health:SetCurrentHealth(inst.components.health.maxhealth)
    inst.components.rampingspawner:Stop()
    inst.components.rampingspawner:Reset()
    TransformNormal(inst)
    inst.components.stunnable.stun_threshold = TUNING.DRAGONFLY_STUN
    inst.components.stunnable.stun_period = TUNING.DRAGONFLY_STUN_PERIOD
end

local function Reset(inst)
    ResetLavae(inst)
    --Fly off
    inst.reset = true

    --No longer start the respawn task here - was possible to duplicate this if the exiting failed.
end

local function DoDespawn(inst)
    --Schedule new spawn time
    --Called at the time the dragonfly actually leaves the world.
    local home = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
    if home ~= nil then
        home.components.childspawner:GoHome(inst)
        home.components.childspawner:StartSpawning()
    else
        inst:Remove() --Dragonfly was probably debug spawned in?
    end
end

local function TrySoftReset(inst)
    if inst.SoftResetTask == nil then
        print(string.format("Dragonfly - Start soft reset task @ %2.2f", GetTime()))
        inst.SoftResetTask = inst:DoTaskInTime(10, SoftReset)
    end 
end


local function OnTargetDeathTask(inst)
    inst._ontargetdeathtask = nil
    TryGetNewTarget(inst)
    if inst.components.combat.target == nil and inst.components.grouptargeter.num_targets <= 0 then
        TrySoftReset(inst)
    end
end

local function OnNewTarget(inst, data)
    if inst.SoftResetTask ~= nil then
        print(string.format("Dragonfly - Cancel soft reset task @ %2.2f", GetTime()))
        inst.SoftResetTask:Cancel()
        inst.SoftResetTask = nil
    end
    if data.oldtarget ~= nil then 
        inst:RemoveEventCallback("death", inst._ontargetdeath, data.oldtarget) 
    end
    if data.target ~= nil  then
        inst:ListenForEvent("death", inst._ontargetdeath, data.target)
    end
end

local function RetargetFn(inst)
    UpdatePlayerTargets(inst)

    if IsFightingPlayers(inst) then
        inst.playercombat = true
        return inst.components.grouptargeter:TryGetNewTarget(), true
    else
        --Also needs to deal with other creatures in the world
        return FindEntity(
            inst,
            TUNING.DRAGONFLY_AGGRO_DIST,
            function(guy)
                return inst.components.combat:CanTarget(guy)
            end,
            { "_combat" }, --see entityreplica.lua
            { "prey", "smallcreature", "lavae" }
        )
    end
end

local function GetLavaePos(inst)
    local pos = inst:GetPosition()
    local facingangle = inst.Transform:GetRotation() * DEGREES
    pos.x = pos.x + 1.7 * math.cos(-facingangle)
    pos.y = pos.y - .3
    pos.z = pos.z + 1.7 * math.sin(-facingangle)
    return pos
end

local function OnLavaeDeath(inst, data)
    --If that was my last lavae & I'm out of lavaes to spawn then enrage.
    if inst.components.rampingspawner:GetCurrentWave() <= 0 and data.remaining_spawns <= 0 then
        --Blargh!
        inst.components.rampingspawner:Stop()
        inst.components.rampingspawner:Reset()
        inst:PushEvent("transform", { transformstate = "fire" })
    end
end

local function OnLavaeSpawn(inst, data)
    --Lavae should pick the closest player and imprint on them.
    --This allows players to pick a person to kite lavaes.
    local lavae = data.newent
    local targets = {}
    for k, v in pairs(inst.components.grouptargeter:GetTargets()) do
        table.insert(targets, k)
    end
    local target = GetClosest(lavae, targets) or inst.components.grouptargeter:SelectTarget()
    lavae.components.entitytracker:TrackEntity("mother", inst)
    lavae.LockTargetFn(lavae, target)
end

function OnMoistureDelta(inst, data)
    if inst.enraged then
        local break_threshold = inst.components.moisture.maxmoisture * 0.9
        if (data.old < break_threshold and data.new >= break_threshold) then
            TransformNormal(inst)
        end
    end
end

local function KeepTargetFn(inst, target)
    return inst.components.combat:CanTarget(target)
end

local function DoBreakOff(inst)
    inst.components.lootdropper:SpawnLootPrefab("dragon_scales")
end

local function OnSave(inst, data)
    --Check if the dragonfly is in combat with players so we can reset.
    data.playercombat = inst.playercombat or nil
end

local function OnLoad(inst, data)
    --If the dragonfly was in combat when the game saved then we're going to reset the fight.
    if data.playercombat then
        inst:DoTaskInTime(1, Reset)
    end
end

local function OnTimerDone(inst, data)
    if data.name == "groundpound_cd" then
        inst.can_ground_pound = true
    end
end

local function OnSpawnStart(inst)
    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "spawning", 1.4)
end

local function OnSpawnStop(inst)
    inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "spawning")
end

local function OnAttacked(inst, data)
    if data.attacker ~= nil then
        inst.components.combat:SuggestTarget(data.attacker)
    end
end

local function OnFreeze(inst)
    inst.freezable_extra_resist = inst.freezable_extra_resist + 2
    UpdateFreezeThreshold(inst)
end

local function OnHealthTrigger(inst)
    inst:PushEvent("transform", { transformstate = "normal" })
    inst.components.rampingspawner:Start() 
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(6, 3.5)
    inst.Transform:SetSixFaced()
    inst.Transform:SetScale(1.3, 1.3, 1.3)
    MakeFlyingGiantCharacterPhysics(inst, 500, 1.4)

    inst.AnimState:SetBank("dragonfly")
    inst.AnimState:SetBuild("dragonfly_build")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("epic")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("dragonfly")
    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")
    inst:AddTag("flying")

    inst.Light:Enable(false)
    inst.Light:SetRadius(2)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetIntensity(0.75)
    inst.Light:SetColour(235/255, 121/255, 12/255)

    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/fly", "flying")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- Component Definitions

    inst:AddComponent("health")
    inst:AddComponent("groundpounder")
    inst:AddComponent("combat")
    inst:AddComponent("sleeper")
    inst:AddComponent("lootdropper")
    inst:AddComponent("inspectable")
    inst:AddComponent("locomotor")
    inst:AddComponent("knownlocations")
    inst:AddComponent("inventory")
    inst:AddComponent("timer")
    inst:AddComponent("grouptargeter")
    inst:AddComponent("damagetracker")
    inst:AddComponent("stunnable")
    inst:AddComponent("healthtrigger")
    inst:AddComponent("rampingspawner")
    inst:AddComponent("moisture")
    inst:SetStateGraph("SGdragonfly")
    inst:SetBrain(brain)

    -- Component Init

    inst.components.damagetracker.damage_threshold = TUNING.DRAGONFLY_BREAKOFF_DAMAGE
    inst.components.damagetracker.damage_threshold_fn = DoBreakOff

    inst.components.stunnable.stun_threshold = TUNING.DRAGONFLY_STUN
    inst.components.stunnable.stun_period = TUNING.DRAGONFLY_STUN_PERIOD
    inst.components.stunnable.stun_duration = TUNING.DRAGONFLY_STUN_DURATION
    inst.components.stunnable.stun_resist = TUNING.DRAGONFLY_STUN_RESIST
    inst.components.stunnable.stun_cooldown = TUNING.DRAGONFLY_STUN_COOLDOWN

    inst.components.healthtrigger:AddTrigger(0.8, OnHealthTrigger)
    inst.components.healthtrigger:AddTrigger(0.5, OnHealthTrigger)
    inst.components.healthtrigger:AddTrigger(0.2, OnHealthTrigger)

    inst.components.health:SetMaxHealth(TUNING.DRAGONFLY_HEALTH)
    inst.components.health.destroytime = 5 --Take 5 seconds to be removed when killed
    inst.components.health.fire_damage_scale = 0 -- Take no damage from fire

    inst.components.groundpounder.numRings = 2
    inst.components.groundpounder.burner = true
    inst.components.groundpounder.groundpoundfx = "firesplash_fx"
    inst.components.groundpounder.groundpounddamagemult = 0.5
    inst.components.groundpounder.groundpoundringfx = "firering_fx"

    inst.components.combat:SetDefaultDamage(TUNING.DRAGONFLY_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.DRAGONFLY_ATTACK_PERIOD)
    inst.components.combat.playerdamagepercent = 0.5
    --inst.components.combat:SetAreaDamage(6, 0.8)
    inst.components.combat:SetRange(TUNING.DRAGONFLY_ATTACK_RANGE, TUNING.DRAGONFLY_HIT_RANGE)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat.battlecryenabled = false
    inst.components.combat.hiteffectsymbol = "dragonfly_body"
    inst.components.combat:SetHurtSound("dontstarve_DLC001/creatures/dragonfly/hurt")

    inst.components.sleeper:SetResistance(4)

    inst.components.lootdropper:SetChanceLootTable("dragonfly")

    inst.components.inspectable:RecordViews()

    inst.components.locomotor.walkspeed = TUNING.DRAGONFLY_SPEED

    inst.components.rampingspawner.getspawnposfn = GetLavaePos
    inst.components.rampingspawner.onstartfn = OnSpawnStart
    inst.components.rampingspawner.onstopfn = OnSpawnStop

    -- Event Watching

    inst._ontargetdeathtask = nil
    inst._ontargetdeath = function()
        if inst._ontargetdeathtask == nil then
            inst._ontargetdeathtask = inst:DoTaskInTime(2, OnTargetDeathTask)
        end
    end

    inst:ListenForEvent("freeze", OnFreeze)
    inst:ListenForEvent("newcombattarget", OnNewTarget)
    inst:ListenForEvent("rampingspawner_spawn", OnLavaeSpawn)
    inst:ListenForEvent("rampingspawner_death", OnLavaeDeath)
    inst:ListenForEvent("moisturedelta", OnMoistureDelta)
    inst:ListenForEvent("timerdone", OnTimerDone)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("death", ResetLavae) --Get rid of lavaes.

    -- Variables

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad -- Reset fight if in combat with players.
    inst.Reset = Reset
    inst.DoDespawn = DoDespawn
    inst.TransformFire = TransformFire
    inst.TransformNormal = TransformNormal
    inst.can_ground_pound = false
    inst.last_hit_time = 0
    inst.freezable_extra_resist = 0

    MakeHugeFreezableCharacter(inst)
    inst.components.freezable:SetResistance(TUNING.DRAGONFLY_FREEZE_THRESHOLD)
    inst.components.freezable.damagetobreak = TUNING.DRAGONFLY_FREEZE_RESIST
    inst.components.freezable.onfreezefn = OnFreeze

    MakeLargePropagator(inst)
    inst.components.propagator.decayrate = 0

    return inst
end

return Prefab("dragonfly", fn, assets, prefabs)
