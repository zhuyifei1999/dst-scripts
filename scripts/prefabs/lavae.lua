local brain = require("brains/lavaebrain")

local assets =
{
    Asset("ANIM", "anim/lavae.zip"),
    Asset("SOUND", "sound/together.fsb"),
}

local prefabs =
{
    "lavae_move_fx",
}

SetSharedLootTable( 'lavae_lava',
{
    {'houndfire',   1.0},
    {'houndfire',   1.0},
    {'houndfire',   1.0},
    {'houndfire',   1.0},
    {'houndfire',   1.0},
})

SetSharedLootTable( 'lavae_frozen',
{
    {'houndfire',   1.0},
    {'houndfire',   1.0},
    {'rocks',       1.0},
    {'rocks',       1.0},
    {'rocks',       1.0},
})

local function OnCollide(inst, other)
    if other ~= nil and other:IsValid() and other.components.burnable ~= nil 
    and not other.components.fueled then
        other.components.burnable:Ignite(true, inst)
    end
end

local function RetargetFn(inst)
    local mother = inst.components.entitytracker:GetEntity("mother")
    if mother and not inst.components.combat:HasTarget() then
        local group_targets = inst.components.grouptargeter:GetTargets()
        local targets = {}
        for k,v in pairs(group_targets) do
            table.insert(targets, k)
        end

        local target = GetClosest(mother, targets)
        if target then
            return target
        end
    elseif not inst.components.combat:HasTarget() or not mother then
        --Shouldn't be in the world. Leave.
        inst.reset = true
    end
end

local function KeepTargetFn(inst, target)
    local mother = inst.components.entitytracker:GetEntity("mother")

    if mother then
        local distance = mother:GetPosition():Dist(target:GetPosition())
        return distance <= 75
    end
end

local function LockTarget(inst, target)
    inst.components.combat:SetTarget(target)
end

local function OnTargetDeath(inst, data)
    local new_target = inst.components.grouptargeter:SelectTarget()
    if new_target then
        inst.components.combat:SetTarget(new_target)
    end
end

local function OnNewTarget(inst, data)
    local old = data.oldtarget
    if old and old.lavae_ontargetdeathfn then 
        inst:RemoveEventCallback("death", old.lavae_ontargetdeathfn, old)
    end

    local new = data.target
    if new then
        new.lavae_ontargetdeathfn = function() OnTargetDeath(inst) end
        if new:HasTag("player") then
            inst:ListenForEvent("death", new.lavae_ontargetdeathfn, new)
        end
    end
end

local function OnEntitySleep(inst)
    if inst.reset then
        inst:Remove()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(2, 1)
    inst.Transform:SetSixFaced()
    MakeCharacterPhysics(inst, 50, 0.5)

    inst.AnimState:SetBank("lavae")
    inst.AnimState:SetBuild("lavae")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("lavae")
    inst:AddTag("monster")
    inst:AddTag("hostile")

    inst.Light:SetRadius(2)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetIntensity(0.75)
    inst.Light:SetColour(235/255, 121/255, 12/255)
    inst.Light:Enable(true)

    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then
        return inst
    end

    inst.Physics:SetCollisionCallback(OnCollide)

    inst:AddComponent("health")
    inst:AddComponent("combat")
    inst:AddComponent("lootdropper")
    inst:AddComponent("inspectable")
    inst:AddComponent("locomotor")
    inst:AddComponent("grouptargeter")
    inst:AddComponent("homeseeker")
    inst:AddComponent("entitytracker")
    inst:SetStateGraph("SGlavae")
    inst:SetBrain(brain)

    inst.components.health:SetMaxHealth(TUNING.LAVAE_HEALTH)
    inst.components.health.fire_damage_scale = 0

    inst.components.combat:SetDefaultDamage(TUNING.LAVAE_DAMAGE)
    inst.components.combat:SetRange(TUNING.LAVAE_ATTACK_RANGE, TUNING.LAVAE_HIT_RANGE)
    inst.components.combat:SetAttackPeriod(TUNING.LAVAE_ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)

    inst.components.locomotor.walkspeed = 5.5

    inst.LockTargetFn = LockTarget

    inst:ListenForEvent("newcombattarget", OnNewTarget)
    inst:ListenForEvent("entitysleep", OnEntitySleep)

    MakeHauntablePanic(inst)

    MakeLargeFreezableCharacter(inst)

    return inst
end

return Prefab("lavae", fn, assets, prefabs)