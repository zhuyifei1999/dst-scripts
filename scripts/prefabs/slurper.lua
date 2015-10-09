local brain = require "brains/slurperbrain"

local assets =
{
    Asset("ANIM", "anim/slurper_basic.zip"),
    Asset("ANIM", "anim/hat_slurper.zip"),
    Asset("SOUND", "sound/slurper.fsb"),
}

local prefabs =
{
    "slurper_pelt",
}

SetSharedLootTable('slurper',
{
    {'lightbulb',    1.0},
    {'lightbulb',    1.0},
    {'slurper_pelt', 0.5},
})

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
end

local function CanHatTarget(inst, target)
    if target == nil or
        target.components.inventory == nil or
        not (target:HasTag("player") or
            target:HasTag("manrabbit") or
            target:HasTag("pig")) then
        return false
    end
    local hat = target.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    return hat == nil or hat.prefab ~= inst.prefab
end

local function Retarget(inst)
    --Find us a tasty target with a hunger component and the ability to equip hats.
    --Otherwise just find a target that can equip hats.

    --Too far, don't find a target
    local homePos = inst.components.knownlocations:GetLocation("home")
    if homePos ~= nil and inst:GetDistanceSqToPoint(homePos) > 30 * 30 then
        return
    end

    return
        FindEntity(inst, 15, function(guy)
            return inst.components.combat:CanTarget(guy)
        end,
        { "_combat" },
        { "INLIMBO" },
        { "character", "monster" })
end

local function KeepTarget(inst, target)
    --If you've chased too far, go home.
    local homePos = inst.components.knownlocations:GetLocation("home")
    return homePos == nil or inst:GetDistanceSqToPoint(homePos) < 30 * 30
end

local function slurphunger(inst, owner)
    if owner.components.hunger ~= nil then
        if owner.components.hunger.current > 0 then
            owner.components.hunger:DoDelta(-3)
        end
    elseif owner.components.health ~= nil then
        owner.components.health:DoDelta(-5, false, "slurper")
    end
end

local function setcansleep(inst)
    inst.cansleep = true
end

local function OnEquip(inst, owner)
    --Start feeding!

    if not CanHatTarget(inst, owner) then
        owner.components.inventory:Unequip(EQUIPSLOTS.HEAD)
        return
    end

    inst.Light:Enable(true)
    inst.components.lighttweener:StartTween(nil, 3, 0.8, 0.4, nil, 2)

    inst.SoundEmitter:PlaySound("dontstarve/creatures/slurper/attach")

    owner.AnimState:OverrideSymbol("swap_hat", "hat_slurper", "swap_hat")
    owner.AnimState:Show("HAT")
    owner.AnimState:Show("HAT_HAIR")
    owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Hide("HEAD")
        owner.AnimState:Show("HEAD_HAT")

        inst.SoundEmitter:PlaySound("dontstarve/creatures/slurper/headslurp", "player_slurp_loop")
    else
        inst.SoundEmitter:PlaySound("dontstarve/creatures/slurper/headslurp_creatures", "creature_slurp_loop")
    end

    inst.shouldburp = true
    inst.cansleep = false

    if inst.task ~= nil then
        inst.task:Cancel()
    end
    inst.task = inst:DoPeriodicTask(2, slurphunger, nil, owner)
end

local function OnUnequip(inst, owner)
    inst.Light:Enable(true) 
    inst.components.lighttweener:StartTween(nil, 1, 0.5, 0.7, nil, 2)

    inst.SoundEmitter:PlaySound("dontstarve/creatures/slurper/dettach")

    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAT_HAIR")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")

        inst.SoundEmitter:KillSound("player_slurp_loop")
    else
        inst.SoundEmitter:KillSound("creature_slurp_loop")
    end

    inst.components.knownlocations:RememberLocation("home", inst:GetPosition())

    if inst.task ~= nil then
        inst.task:Cancel()
    end
    inst.task = inst:DoTaskInTime(10, setcansleep)
end

local function BasicAwakeCheck(inst)
    return not inst.cansleep
        or (inst.components.combat ~= nil and inst.components.combat.target ~= nil)
        or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning())
        or (inst.components.freezable ~= nil and inst.components.freezable:IsFrozen())
        or (inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner ~= nil)
end

local function SleepTest(inst)
    if BasicAwakeCheck(inst) then
        return false
    end
    local homePos = inst.components.knownlocations:GetLocation("home")
    return homePos ~= nil and inst:GetDistanceSqToPoint(homePos) < 5 * 5
end

local function WakeTest(inst)
    if BasicAwakeCheck(inst) then
        return true
    end
    local homePos = inst.components.knownlocations:GetLocation("home")
    return homePos ~= nil and inst:GetDistanceSqToPoint(homePos) >= 5 * 5
end

local function OnInit(inst)
    inst.components.knownlocations:RememberLocation("home", inst:GetPosition())
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(2, 1.25)

    inst.Transform:SetFourFaced()

    MakeCharacterPhysics(inst, 10, 0.5)

    inst.AnimState:SetBank("slurper")
    inst.AnimState:SetBuild("slurper_basic")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst:AddTag("cavedweller")
    inst:AddTag("mufflehat")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.canbepickedup = false
    inst.components.inventoryitem.cangoincontainer = false
    inst.components.inventoryitem.nobounce = true

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnUnequip(OnUnequip)
    inst.components.equippable:SetOnEquip(OnEquip)

    inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier(1)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = false }
    inst.components.locomotor.walkspeed = 9

    inst:AddComponent("combat")
    inst.components.combat:SetAttackPeriod(5)
    inst.components.combat:SetRange(8)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetDefaultDamage(30)
    inst.components.combat:SetRetargetFunction(3, Retarget)
    inst:ListenForEvent("attacked", OnAttacked)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(200)
    inst.components.health.canmurder = false

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('slurper')
    -- inst:AddComponent("eater")
    -- inst.components.eater:SetDiet({ FOODTYPE.VEGGIE }, { FOODTYPE.VEGGIE })
    -- inst.components.eater:SetOnEatFn(oneat)

    inst:AddComponent("lighttweener")
    inst.components.lighttweener:StartTween(inst.Light, 1, 0.5, 0.7, { 237/255, 237/255, 209/255 }, 0)
    inst.Light:Enable(true)

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetSleepTest(SleepTest)
    inst.components.sleeper:SetWakeTest(WakeTest)
    --inst.components.sleeper:SetNocturnal(true)

    inst:AddComponent("knownlocations")    

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL

    MakeMediumBurnableCharacter(inst)
    MakeMediumFreezableCharacter(inst)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGslurper")

    inst.HatTest = CanHatTarget

    inst.cansleep = true

    inst:DoTaskInTime(0, OnInit)

    return inst
end

return Prefab("slurper", fn, assets, prefabs)
