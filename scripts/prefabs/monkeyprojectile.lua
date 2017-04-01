local assets =
{
    Asset("ANIM", "anim/monkey_projectile.zip"),
}

local prefabs =
{
    "poop",
}

local function OnHit(inst, owner, target)
    if target.components.sanity ~= nil then
        target.components.sanity:DoDelta(-TUNING.SANITY_SMALL)
    end
    SpawnPrefab("poop").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey/poopsplat")
    target:PushEvent("attacked", {attacker = owner, damage = 0})
    inst:Remove()
end

local function OnMiss(inst, owner, target)
    SpawnPrefab("poop").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey/poopsplat")
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("monkey_projectile")
    inst.AnimState:SetBuild("monkey_projectile")
    inst.AnimState:PlayAnimation("idle")

    --projectile (from projectile component) added to pristine state for optimization
    inst:AddTag("projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(25)
    inst.components.projectile:SetHoming(false)
    inst.components.projectile:SetHitDist(1.5)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(OnMiss)
    inst.components.projectile.range = 30

    return inst
end

return Prefab("monkeyprojectile", fn, assets, prefabs)