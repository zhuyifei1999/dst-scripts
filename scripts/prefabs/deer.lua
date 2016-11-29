local assets =
{
    Asset("ANIM", "anim/deer_build.zip"),
    Asset("ANIM", "anim/deer_basic.zip"),
    Asset("ANIM", "anim/deer_action.zip"),
}

local prefabs =
{
    "meat",
    "deerherd",
}

local brain = require("brains/deerbrain")

SetSharedLootTable( 'deer',
{
    {'meat',              1.00},
})

SetSharedLootTable( 'deerantler',
{
    {'meat',              1.00},
    {'meat',              1.00},
})

local function keeptargetfn(inst, target)
    --Don't keep target if we chased too far from our herd
    local herd = inst.components.herdmember ~= nil and inst.components.herdmember:GetHerd() or nil
    return herd == nil or inst:IsNear(herd, TUNING.DEER_CHASE_DIST)
end

local function ShareTargetFn(dude)
    return dude:HasTag("deer")
        and not dude:IsInLimbo()
        and not dude.components.health:IsDead()
end

local function onattacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, 20, ShareTargetFn, 3)
end

local function ShowAntler(inst)
    inst.AnimState:Show("swap_antler")
    inst.AnimState:OverrideSymbol("swap_antler_red", "deer_build", "swap_antler"..tostring(inst.hasantler))
end

local function setantlered(inst, antler, animate)
    inst.hasantler = antler

    if animate then
        inst:PushEvent("growantler")
    else
        inst:ShowAntler()
    end
end

local function ontimerdone(inst, data)
    if data ~= nil then
        if data.name == "growantler" then
            setantlered(inst, math.random(3), true)
        end
    end
end

local function onqueuegrowantler(inst)
    inst.components.timer:StartTimer("growantler", (1 + math.random()) * TUNING.TOTAL_DAY_TIME)
end

-------------------------------------------------------------------
local function OnMigrate(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local buildings = TheSim:FindEntities(x, y, z, 30, nil, nil, { "wall", "structure" })
    if #buildings < 10 then
        inst:Remove()
    end
end

local function StartMigrationTask(inst)
    if inst.migrationtask == nil then
        inst.migrationtask = inst:DoTaskInTime(TUNING.TOTAL_DAY_TIME * .5 + math.random() * TUNING.SEG_TIME, OnMigrate)
    end
end

local function StopMigrationTask(inst)
    if inst.migrationtask ~= nil then
        inst.migrationtask:Cancel()
        inst.migrationtask = nil
    end
end

local function SetMigrating(inst, migrating)
    if migrating then
        if not inst.migrating then
            inst.migrating = true
            inst.OnEntitySleep = StartMigrationTask
            inst.OnEntityWake = StopMigrationTask
            if inst:IsAsleep() then
                StartMigrationTask(inst)
            end
        end
    elseif inst.migrating then
        inst.migrating = nil
        inst.OnEntitySleep = nil
        inst.OnEntityWake = nil
        StopMigrationTask(inst)
    end
end

local function ondeerherdmigration(inst)
    SetMigrating(inst, true)
end
-------------------------------------------------------------------

local function onsave(inst, data)
    data.hasantler = inst.hasantler
    data.migrating = inst.migrating or nil
end

local function onload(inst, data)
    if data ~= nil then
        if data.hasantler ~= nil then
            setantlered(inst, data.hasantler)
        end
        SetMigrating(inst, data.migrating)
    end
end

local function getstatus(inst)
    return inst.charged and "ANTLER" or nil
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(1.75, .75)

    inst.Transform:SetSixFaced()

    MakeCharacterPhysics(inst, 100, 1)

    inst.AnimState:SetBank("deer")
    inst.AnimState:SetBuild("deer_build")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:Hide("fx")
    inst.AnimState:Hide("swap_antler")
    inst.AnimState:Hide("CHAIN")
    inst.AnimState:OverrideSymbol("swap_neck_collar", "deer_build", "swap_neck")

    ------------------------------------------

    inst:AddTag("deer")
    inst:AddTag("animal")

    --herdmember (from herdmember component) added to pristine state for optimization
    inst:AddTag("herdmember")

    --saltlicker (from saltlicker component) added to pristine state for optimization
    inst:AddTag("saltlicker")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    ------------------------------------------

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.DEER_HEALTH)

    ------------------

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.DEER_DAMAGE)
    inst.components.combat:SetRange(TUNING.DEER_ATTACK_RANGE)
    inst.components.combat.hiteffectsymbol = "deer_torso"
    inst.components.combat:SetAttackPeriod(TUNING.DEER_ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)
    inst.components.combat:SetHurtSound("dontstarve_DLC001/creatures/lightninggoat/hurt")
    ------------------------------------------

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(4)

    ------------------------------------------

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('deer') 

    ------------------------------------------

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("knownlocations")
    inst:AddComponent("herdmember")
    inst.components.herdmember:SetHerdPrefab("deerherd")

    inst:AddComponent("timer")

    inst:AddComponent("saltlicker")
    inst.components.saltlicker:SetUp(TUNING.SALTLICK_DEER_USES)

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.DEER_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.DEER_RUN_SPEED

    ------------------------------------------

    MakeMediumBurnableCharacter(inst, "deer_torso")
    MakeMediumFreezableCharacter(inst, "deer_torso")
    MakeHauntablePanic(inst)

    inst.OnSave = onsave
    inst.OnLoad = onload

    inst:ListenForEvent("attacked", onattacked)
    inst:ListenForEvent("queuegrowantler", onqueuegrowantler)
    inst:ListenForEvent("timerdone", ontimerdone)
    inst:ListenForEvent("deerherdmigration", ondeerherdmigration)

    inst.ShowAntler = ShowAntler

    inst:SetStateGraph("SGdeer")
    inst:SetBrain(brain)

    return inst
end

return Prefab("deer", fn, assets, prefabs)
