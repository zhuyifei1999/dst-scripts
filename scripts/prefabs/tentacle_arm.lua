local assets =
{
    Asset("ANIM", "anim/tentacle_arm.zip"),
    Asset("ANIM", "anim/tentacle_arm_build.zip"),

    Asset("SOUND", "sound/tentacle.fsb"),
}

local prefabs =
{
    "monstermeat",
}

local function retargetfn(inst)
    return FindEntity(inst, TUNING.TENTACLE_PILLAR_ARM_ATTACK_DIST, function(guy) 
        if not guy.components.health:IsDead() then
            return (not (guy.prefab == inst.prefab))
        end
    end,
    {"_combat","_health"},-- see entityscript.lua
    {"prey"},
    {"character","monster","animal"}
    )
end

local function Emerge(inst)
    if inst.retracted == true then
        inst.retracted = false
        inst:PushEvent("emerge")
    end
end

local function Retract(inst)
    if inst.retracted == false then
        inst.retracted = true
        inst:PushEvent("retract")
    end
end

local function onfar(inst)
    Retract(inst)
end

local function onnear(inst)
    Emerge(inst)
end

local function shouldKeepTarget(inst, target)
    if target and target:IsValid() and target.components.health and not target.components.health:IsDead() then
        local distsq = target:GetDistanceSqToInst(inst)
        
        return distsq < TUNING.TENTACLE_PILLAR_ARM_STOPATTACK_DIST*TUNING.TENTACLE_PILLAR_ARM_STOPATTACK_DIST
    else
        return false
    end
end

local function OnHit(inst, attacker, damage) 
    if attacker.components.combat and not attacker:HasTag("player") and math.random() > 0.5 then
        -- Followers should stop hitting the pillar
        attacker.components.combat:SetTarget(nil)
        if inst.components.health.currenthealth and inst.components.health.currenthealth < 0 then
            inst.components.health:DoDelta(damage*.6, false, attacker)
        end
    end
end

local function CustomOnHaunt(inst, haunter)
    if math.random() < TUNING.HAUNT_CHANCE_HALF then
        inst.components.health:SetPercent(0)
        return true
    end
    return false
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddPhysics()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Physics:SetCylinder(0.6,2)

    local ARM_SCALE = 0.95
    inst.Transform:SetScale(ARM_SCALE, ARM_SCALE, ARM_SCALE)

    inst.AnimState:SetBank("tentacle_arm")
    inst.AnimState:SetScale(ARM_SCALE,ARM_SCALE)
    inst.AnimState:SetBuild("tentacle_arm_build")
    inst.AnimState:PlayAnimation("breach_pre")
    -- inst.AnimState:SetMultColour(.2, 1, .2, 1.0)

    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("wet")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false -- don't need to save these

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.TENTACLE_PILLAR_ARM_HEALTH)

    inst:AddComponent("combat")
    inst.components.combat:SetRange(TUNING.TENTACLE_PILLAR_ARM_ATTACK_DIST)
    inst.components.combat:SetDefaultDamage(TUNING.TENTACLE_PILLAR_ARM_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.TENTACLE_PILLAR_ARM_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(GetRandomWithVariance(1, 0.5), retargetfn)
    inst.components.combat:SetKeepTargetFunction(shouldKeepTarget)
    inst.components.combat:SetOnHit(OnHit)
    inst.components.combat:SetPlayerStunlock(PLAYERSTUNLOCK.OFTEN)

    MakeLargeFreezableCharacter(inst)

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(6, 15)
    inst.components.playerprox:SetOnPlayerNear(onnear)
    inst.components.playerprox:SetOnPlayerFar(onfar)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")
    -- inst.components.lootdropper:SetLoot({"monstermeat", "monstermeat"})
    -- inst.components.lootdropper:AddChanceLoot("tentaclespike", 0.5)
    -- inst.components.lootdropper:AddChanceLoot("tentaclespots", 0.2)

    AddHauntableCustomReaction(inst, CustomOnHaunt)

    inst.retracted = true
    inst.Emerge = Emerge
    inst.Retract = Retract

    inst:SetStateGraph("SGtentacle_arm")

    return inst
end

return Prefab("tentacle_pillar_arm", fn, assets, prefabs)
