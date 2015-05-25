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
    "lavaspit",
    "dragon_scales",
    "firesplash_fx",
    "tauntfire_fx",
    "attackfire_fx",
    "vomitfire_fx",
    "firering_fx",
    "collapse_small",
    "scorchedground",
    "lava_pond",
    "scorched_skeleton",
}

SetSharedLootTable( 'dragonfly',
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
    local total = TUNING.DRAGONFLY_FREEZE_THRESHOLD + inst.freezable_extra_resist

    if inst.enraged then
        total = total + TUNING.DRAGONFLY_ENRAGED_FREEZE_BONUS
    end

    inst.components.freezable:SetResistance(total)
end

local function TransformNormal(inst)
    inst.AnimState:SetBuild("dragonfly_build")
    inst.enraged = false
    --Set normal stats
    inst.components.locomotor.walkspeed = TUNING.DRAGONFLY_SPEED
    inst.components.combat:SetDefaultDamage(TUNING.DRAGONFLY_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.DRAGONFLY_ATTACK_PERIOD)
    inst.components.combat:SetRange(TUNING.DRAGONFLY_ATTACK_RANGE, TUNING.DRAGONFLY_FIRE_HIT_RANGE)

    UpdateFreezeThreshold(inst)

    inst.components.propagator:StopSpreading()
    inst.Light:Enable(false)
end

local function TransformFire(inst)

    inst.AnimState:SetBuild("dragonfly_fire_build")
    inst.enraged = true
    inst.can_ground_pound = true
    --Set fire stats
    inst.components.locomotor.walkspeed = TUNING.DRAGONFLY_FIRE_SPEED
    inst.components.combat:SetDefaultDamage(TUNING.DRAGONFLY_FIRE_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.DRAGONFLY_FIRE_ATTACK_PERIOD)
    inst.components.combat:SetRange(TUNING.DRAGONFLY_ATTACK_RANGE, TUNING.DRAGONFLY_HIT_RANGE)

    inst.Light:Enable(true)
    inst.components.propagator:StartSpreading()

    inst.components.moisture:DoDelta(-inst.components.moisture:GetMoisture())

    UpdateFreezeThreshold(inst)

    if inst.reverttask then
        inst.reverttask:Cancel()
        inst.reverttask = nil
    end

    inst.reverttask = inst:DoTaskInTime(TUNING.DRAGONFLY_ENRAGE_DURATION, 
        function() if inst.enraged then 
            inst:PushEvent("transform", {transformstate = "normal"})
        end end)
end

local function CalcSanityAura(inst, observer)
    --Maybe we don't want this if players are supposed to seek out and fight the creature
    return 0
end

local function IsFightingPlayers(inst)
    return inst.components.combat.target and inst.components.combat.target:HasTag("player")
end

local function UpdatePlayerTargets(inst)
    local pos = inst.components.knownlocations:GetLocation("spawnpoint")
    local player_targets = FindPlayersInRange(pos.x, pos.y, pos.z, TUNING.DRAGONFLY_RESET_DIST, true)
    local current_targets = inst.components.grouptargeter:GetTargets()

    for k,v in pairs(current_targets) do
        if not table.contains(player_targets, k) then
            inst.components.grouptargeter:RemoveTarget(k)
        end
    end

    for k,v in pairs(player_targets) do
        if current_targets[v] == nil then
            inst.components.grouptargeter:AddTarget(v)
        end
    end
end

local function TryGetNewTarget(inst)
    UpdatePlayerTargets(inst)

    local new_target = inst.components.grouptargeter:SelectTarget()
    if new_target then
        inst.components.combat:SetTarget(new_target)
    end
end

local function ResetLavae(inst)
    --Despawn all lavae
    local lavae = inst.components.rampingspawner.spawns
    for k,v in pairs(lavae) do
        k.components.combat:SetTarget(nil)
        k.components.locomotor:Clear()
        k.reset = true
    end
end

local function SoftReset(inst)
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
    local home = inst.components.homeseeker.home
    if home then
        home.components.childspawner:GoHome(inst)
        home.components.childspawner:StartSpawning()
    else
        inst:Remove() --Dragonfly was probably debug spawned in?
    end
end

local function TrySoftReset(inst)
    if not inst.SoftResetTask then
        print(string.format("Dragonfly - Start soft reset task @ %2.2f", GetTime()))
        inst.SoftResetTask = inst:DoTaskInTime(10, SoftReset)
    end 
end


local function OnTargetDeath(inst)
    inst:DoTaskInTime(2, function()
        TryGetNewTarget(inst)
        if not inst.components.combat.target and inst.components.grouptargeter.num_targets <= 0 then
            TrySoftReset(inst)
        end
    end)
end

local function OnNewTarget(inst, data)

    if inst.SoftResetTask then
        print(string.format("Dragonfly - Cancel soft reset task @ %2.2f", GetTime()))
        inst.SoftResetTask:Cancel()
        inst.SoftResetTask = nil
    end

    local old = data.oldtarget
    if old and old.dragonfly_ondeathfn then 
        inst:RemoveEventCallback("death", old.dragonfly_ondeathfn, old) 
    end

    local new = data.target
    if new then
        new.dragonfly_ondeathfn = function() OnTargetDeath(inst) end
        inst:ListenForEvent("death", new.dragonfly_ondeathfn, new)
    end
end

local function RetargetFn(inst)
    UpdatePlayerTargets(inst)

    if IsFightingPlayers(inst) then
        inst.playercombat = true
        return inst.components.grouptargeter:TryGetNewTarget(), true
    else
        --Also needs to deal with other creatures in the world
        return FindEntity(inst, TUNING.DRAGONFLY_AGGRO_DIST, function(guy)
            return inst.components.combat:CanTarget(guy)
        end, nil, { "prey", "smallcreature", "lavae" })
    end
end


local function GetLavaePos(inst)
    local pos = inst:GetPosition()
    local facingangle = inst.Transform:GetRotation() * DEGREES
    local offsetvec = Vector3(1.7 * math.cos(-facingangle), -0.3, 1.7 * math.sin(-facingangle))

    return pos + offsetvec
end

local function OnLavaeDeath(inst, data)
    --If that was my last lavae & I'm out of lavaes to spawn then enrage.
    if inst.components.rampingspawner:GetCurrentWave() <= 0 and data.remaining_spawns <= 0 then
        --Blargh!
        inst.components.rampingspawner:Stop()
        inst.components.rampingspawner:Reset()
        inst:PushEvent("transform", {transformstate = "fire"})
    end
end

local function OnLavaeSpawn(inst, data)
    --Lavae should pick the closest player and imprint on them.
    --This allows players to pick a person to kite lavaes.
    local lavae = data.newent
    local targets = {}
    local dragonfly_targets = inst.components.grouptargeter:GetTargets()
    for k,v in pairs(dragonfly_targets) do
        table.insert(targets, k)
        lavae.components.grouptargeter.targets = dragonfly_targets --Use the exact target list that the dragonfly does.
    end
    local target = GetClosest(lavae, targets)
    if not target then
        target = inst.components.grouptargeter:SelectTarget()
    end
    lavae.components.entitytracker:TrackEntity("mother", inst)
    lavae.LockTargetFn(lavae, target)
end

function OnMoistureDelta(inst, data)
    local moisture = inst.components.moisture
    if inst.enraged then
        local break_threshold = moisture.maxmoisture * 0.9
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
    data.playercombat = inst.playercombat
end

local function OnLoad(inst, data)
    --If the dragonfly was in combat when the game saved then we're going to reset the fight.
    if data.playercombat then
        inst:DoTaskInTime(1, Reset)
    end
end

local function OnFreeze(inst)
    TransformNormal(inst)
end

local function OnSleep(inst)
    TransformNormal(inst)
end

local function OnTimerDone(inst, data)
    if data.name == "groundpound_cd" then
        inst.can_ground_pound = true
    end
end

local function OnSpawnStart(inst)
    inst.components.locomotor.bonusspeed = 2
end

local function OnSpawnStop(inst)
    inst.components.locomotor.bonusspeed = 0
end

local function OnAttacked(inst, data)
    if data.attacker then
        inst.components.combat:SuggestTarget(data.attacker)
    end
end

local function OnDeath(inst, data)
    ResetLavae(inst)
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
    inst.Transform:SetScale(1.3,1.3,1.3)
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

    inst:AddComponent("sanityaura")
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
    inst:AddComponent("homeseeker") --V2C: #TODO: this is incorrect, homeseeker should be added/removed by childspawner, solve dragonfly specific problem with a LoadPostPass instead
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

    local start_spawning = function()
        inst:PushEvent("transform", {transformstate = "normal"})
        inst.components.rampingspawner:Start() 
    end

    inst.components.healthtrigger:AddTrigger(0.8, start_spawning)
    inst.components.healthtrigger:AddTrigger(0.5, start_spawning)
    inst.components.healthtrigger:AddTrigger(0.2, start_spawning)

    inst.components.sanityaura.aurafn = CalcSanityAura

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

    inst:ListenForEvent("freeze", OnFreeze)
    inst:ListenForEvent("newcombattarget", OnNewTarget)
    inst:ListenForEvent("rampingspawner_spawn", OnLavaeSpawn)
    inst:ListenForEvent("rampingspawner_death", OnLavaeDeath)
    inst:ListenForEvent("moisturedelta", OnMoistureDelta)
    inst:ListenForEvent("timerdone", OnTimerDone)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("death", OnDeath) --Get rid of lavaes.

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
    inst.components.freezable.onfreezefn = function()
        inst.freezable_extra_resist = inst.freezable_extra_resist + 2
        UpdateFreezeThreshold(inst)
    end

    MakeLargePropagator(inst)
    inst.components.propagator.decayrate = 0

    return inst
end

return Prefab("common/monsters/dragonfly", fn, assets, prefabs)