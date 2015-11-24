local assets =
{
    Asset("ANIM", "anim/beefalo_basic.zip"),
    Asset("ANIM", "anim/beefalo_actions.zip"),
    Asset("ANIM", "anim/beefalo_build.zip"),
    Asset("ANIM", "anim/beefalo_heat_build.zip"),
    Asset("ANIM", "anim/beefalo_shaved_build.zip"),
    Asset("SOUND", "sound/beefalo.fsb"),
}

local prefabs =
{
    "meat",
    "poop",
    "beefalowool",
    "horn",
}

local brain = require("brains/beefalobrain")

SetSharedLootTable( 'beefalo',
{
    {'meat',            1.00},
    {'meat',            1.00},
    {'meat',            1.00},
    {'meat',            1.00},
    {'beefalowool',     1.00},
    {'beefalowool',     1.00},
    {'beefalowool',     1.00},
    {'horn',            0.33},
})

local sounds = 
{
    walk = "dontstarve/beefalo/walk",
    grunt = "dontstarve/beefalo/grunt",
    yell = "dontstarve/beefalo/yell",
    swish = "dontstarve/beefalo/tail_swish",
    curious = "dontstarve/beefalo/curious",
    angry = "dontstarve/beefalo/angry",
}

local function OnEnterMood(inst)
    if inst.components.beard ~= nil and inst.components.beard.bits > 0 then
        inst.AnimState:SetBuild("beefalo_heat_build")
        inst:AddTag("scarytoprey")
    end
end

local function OnLeaveMood(inst)
    if inst.components.beard ~= nil and inst.components.beard.bits > 0 then
        inst.AnimState:SetBuild("beefalo_build")
        inst:RemoveTag("scarytoprey")
    end
end

local function Retarget(inst)
    local herd = inst.components.herdmember ~= nil and inst.components.herdmember:GetHerd() or nil
    return herd ~= nil
        and herd.components.mood ~= nil
        and herd.components.mood:IsInMood()
        and FindEntity(
                inst,
                TUNING.BEEFALO_TARGET_DIST,
                function(guy)
                    return inst.components.combat:CanTarget(guy)
                end,
                { "_combat" }, --See entityreplica.lua (re: "_combat" tag)
                { "beefalo", "wall", "INLIMBO" }
            )
        or nil
end

local function KeepTarget(inst, target)
    local herd = inst.components.herdmember ~= nil and inst.components.herdmember:GetHerd() or nil
    return herd == nil
        or herd.components.mood == nil
        or not herd.components.mood:IsInMood()
        or inst:IsNear(herd, TUNING.BEEFALO_CHASE_DIST)
end

local function OnNewTarget(inst, data)
    if data ~= nil and data.target ~= nil and inst.components.follower ~= nil and data.target == inst.components.follower.leader then
        inst.components.follower:SetLeader(nil)
    end
end

local function CanShareTarget(dude)
    return dude:HasTag("beefalo") and not (dude.components.health:IsDead() or dude:HasTag("player"))
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, 30, CanShareTarget, 5)
end

local function GetStatus(inst)
    return (inst.components.follower.leader ~= nil and "FOLLOWER")
        or (inst.components.beard ~= nil and inst.components.beard.bits == 0 and "NAKED")
        or nil
end

local function OnResetBeard(inst)
    inst.sg:GoToState("shaved")
end

local function CanShaveTest(inst)
    if inst.components.sleeper:IsAsleep() then
        return true
    else
        return false, "AWAKEBEEFALO"
    end
end

local function OnShaved(inst)
    if inst.components.beard.bits == 0 then
        inst.AnimState:SetBuild("beefalo_shaved_build")
    end
end

local function OnHairGrowth(inst)
    if inst.components.beard.bits == 0 then
        inst.hairGrowthPending = true
    end
end

local function CustomOnHaunt(inst)
    inst.components.periodicspawner:TrySpawn()
    return true
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 100, .5)

    inst.DynamicShadow:SetSize(6, 2)
    inst.Transform:SetSixFaced()

    inst.AnimState:SetBank("beefalo")
    inst.AnimState:SetBuild("beefalo_build")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst:AddTag("beefalo")
    inst:AddTag("animal")
    inst:AddTag("largecreature")

    --bearded (from beard component) added to pristine state for optimization
    inst:AddTag("bearded")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.sounds = sounds

    local hair_growth_days = 3

    inst:AddComponent("beard")
    -- assume the beefalo has already grown its hair
    inst.components.beard.bits = 3
    inst.components.beard.daysgrowth = hair_growth_days + 1
    inst.components.beard.onreset = OnResetBeard
    inst.components.beard.canshavetest = CanShaveTest
    inst.components.beard.prize = "beefalowool"
    inst.components.beard:AddCallback(0, OnShaved)
    inst.components.beard:AddCallback(hair_growth_days, OnHairGrowth)

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.VEGGIE }, { FOODTYPE.VEGGIE })

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "beefalo_body"
    inst.components.combat:SetDefaultDamage(TUNING.BEEFALO_DAMAGE)
    inst.components.combat:SetRetargetFunction(1, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.BEEFALO_HEALTH)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('beefalo')

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("knownlocations")
    inst:AddComponent("herdmember")
    inst:ListenForEvent("entermood", OnEnterMood)
    inst:ListenForEvent("leavemood", OnLeaveMood)

    inst:AddComponent("leader")
    inst:AddComponent("follower")
    inst.components.follower.maxfollowtime = TUNING.BEEFALO_FOLLOW_TIME
    inst.components.follower.canaccepttarget = false
    inst:ListenForEvent("newcombattarget", OnNewTarget)
    inst:ListenForEvent("attacked", OnAttacked)

    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetPrefab("poop")
    inst.components.periodicspawner:SetRandomTimes(40, 60)
    inst.components.periodicspawner:SetDensityInRange(20, 2)
    inst.components.periodicspawner:SetMinimumSpacing(8)
    inst.components.periodicspawner:Start()

    MakeLargeBurnableCharacter(inst, "beefalo_body")
    MakeLargeFreezableCharacter(inst, "beefalo_body")

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = 1.5
    inst.components.locomotor.runspeed = 7

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)

    MakeHauntablePanic(inst)
    AddHauntableCustomReaction(inst, CustomOnHaunt, true, false, true)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGBeefalo")
    return inst
end

return Prefab("beefalo", fn, assets, prefabs)
