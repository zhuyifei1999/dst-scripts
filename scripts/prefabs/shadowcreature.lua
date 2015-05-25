local prefabs =
{
    "nightmarefuel",
}

local brain = require("brains/shadowcreaturebrain")

local function NotifyBrainOfTarget(inst, target)
    if inst.brain and inst.brain.SetTarget then
        inst.brain:SetTarget(target)
    end
end

local function retargetfn(inst)
    return FindEntity(inst, TUNING.SHADOWCREATURE_TARGET_DIST, function(guy)
        return guy.components.sanity:IsCrazy() and inst.components.combat:CanTarget(guy)
    end, { "player" }, { "playerghost" })
end

local function onkilledbyother(inst, attacker)
    if attacker and attacker.components.sanity then
        attacker.components.sanity:DoDelta(inst.sanityreward or TUNING.SANITY_SMALL)
    end
end

SetSharedLootTable("shadow_creature",
{
    { "nightmarefuel",  1.0 },
    { "nightmarefuel",  0.5 },
})

local function CalcSanityAura(inst, observer)
    return (inst.components.combat.target ~= nil 
    and observer.components.sanity:IsCrazy()
    and -TUNING.SANITYAURA_LARGE) or 0
end

local function ShareTargetFn(dude)
    return dude:HasTag("shadowcreature") and not dude.components.health:IsDead()
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, 30, ShareTargetFn, 1)
end

local function OnNewCombatTarget(inst, data)
    NotifyBrainOfTarget(inst, data.target)
end

local function MakeShadowCreature(data)

    local assets =
    {
        Asset("ANIM", "anim/"..data.build..".zip"),
    }

    local sounds =
    {
        attack = "dontstarve/sanity/creature"..data.num.."/attack",
        attack_grunt = "dontstarve/sanity/creature"..data.num.."/attack_grunt",
        death = "dontstarve/sanity/creature"..data.num.."/die",
        idle = "dontstarve/sanity/creature"..data.num.."/idle",
        taunt = "dontstarve/sanity/creature"..data.num.."/taunt",
        appear = "dontstarve/sanity/creature"..data.num.."/appear",
        disappear = "dontstarve/sanity/creature"..data.num.."/dissappear",
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddPhysics()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeCharacterPhysics(inst, 10, 1.5)
        RemovePhysicsColliders(inst)
        inst.Physics:SetCollisionGroup(COLLISION.SANITY)
        inst.Physics:CollidesWith(COLLISION.SANITY)
        --inst.Physics:CollidesWith(COLLISION.WORLD)

        inst.Transform:SetFourFaced()

        inst:AddTag("shadowcreature")
        inst:AddTag("monster")
        inst:AddTag("hostile")
        inst:AddTag("shadow")
        inst:AddTag("notraptrigger")

        inst.AnimState:SetBank(data.bank)
        inst.AnimState:SetBuild(data.build)
        inst.AnimState:PlayAnimation("idle_loop")
        inst.AnimState:SetMultColour(1, 1, 1, 0.5)

        -- this is purely view related
        inst:AddComponent("transparentonsanity")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
        inst.components.locomotor.walkspeed = data.speed
        inst.sounds = sounds
        inst:SetStateGraph("SGshadowcreature")

        inst:SetBrain(brain)

        inst:AddComponent("sanityaura")
        inst.components.sanityaura.aurafn = CalcSanityAura

        inst:AddComponent("health")
        inst.components.health:SetMaxHealth(data.health)

        inst.sanityreward = data.sanityreward

        inst:AddComponent("combat")
        inst.components.combat:SetDefaultDamage(data.damage)
        inst.components.combat:SetAttackPeriod(data.attackperiod)
        inst.components.combat:SetRetargetFunction(3, retargetfn)
        inst.components.combat.onkilledbyother = onkilledbyother

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetChanceLootTable('shadow_creature')

        inst:ListenForEvent("attacked", OnAttacked)
        inst:ListenForEvent("newcombattarget", OnNewCombatTarget)

        inst.persists = false

        return inst
    end

    return Prefab("monsters/"..data.name, fn, assets, prefabs)
end

local data =
{
    {
        name = "crawlinghorror",
        build = "shadow_insanity1_basic",
        bank = "shadowcreature1",
        num = 1,
        speed = TUNING.CRAWLINGHORROR_SPEED,
        health = TUNING.CRAWLINGHORROR_HEALTH,
        damage = TUNING.CRAWLINGHORROR_DAMAGE,
        attackperiod = TUNING.CRAWLINGHORROR_ATTACK_PERIOD,
        sanityreward = TUNING.SANITY_MED,
    },
    {
        name = "terrorbeak",
        build = "shadow_insanity2_basic",
        bank = "shadowcreature2",
        num = 2,
        speed = TUNING.TERRORBEAK_SPEED,
        health = TUNING.TERRORBEAK_HEALTH,
        damage = TUNING.TERRORBEAK_DAMAGE,
        attackperiod = TUNING.TERRORBEAK_ATTACK_PERIOD,
        sanityreward = TUNING.SANITY_LARGE,
    },
}
local ret = {}
for i, v in ipairs(data) do
    table.insert(ret, MakeShadowCreature(v))
end
return unpack(ret)