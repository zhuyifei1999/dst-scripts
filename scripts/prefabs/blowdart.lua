local assets =
{
    Asset("ANIM", "anim/blow_dart.zip"),
    Asset("ANIM", "anim/swap_blowdart.zip"),
    Asset("ANIM", "anim/swap_blowdart_pipe.zip"),
}

local prefabs =
{
    "impact",
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_blowdart", "swap_blowdart")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_object")
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function onhit(inst, attacker, target)
    local impactfx = SpawnPrefab("impact")
    if impactfx ~= nil then
        local follower = impactfx.entity:AddFollower()
        follower:FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol, 0, 0, 0)
        if attacker ~= nil then
            impactfx:FacePoint(attacker.Transform:GetWorldPosition())
        end
    end
    inst:Remove()
end

local function onthrown(inst, data)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
end

local function common(anim, tags, removephysicscolliders)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("blow_dart")
    inst.AnimState:SetBuild("blow_dart")
    inst.AnimState:PlayAnimation(anim)

    inst:AddTag("blowdart")
    inst:AddTag("sharp")
    inst:AddTag("projectile")
    if tags ~= nil then
        for i, v in ipairs(tags) do
            inst:AddTag(v)
        end
    end

    if removephysicscolliders then
        RemovePhysicsColliders(inst)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(0)
    inst.components.weapon:SetRange(8, 10)

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(60)
    inst.components.projectile:SetOnHitFn(onhit)
    inst:ListenForEvent("onthrown", onthrown)
    -------

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst:AddComponent("stackable")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.equipstack = true

    MakeHauntableLaunch(inst)

    return inst
end

local function sleepthrown(inst)
    inst.AnimState:PlayAnimation("dart_purple")
    inst:AddTag("NOCLICK")
    inst.persists = false
end

local function sleepattack(inst, attacker, target)
    if not target:IsValid() then
        --target killed or removed in combat damage phase
        return
    end

    target.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_impact_sleep")

    if target.components.sleeper ~= nil then
        target.components.sleeper:AddSleepiness(1, 15, inst)
    elseif target.components.grogginess ~= nil then
        target.components.grogginess:AddGrogginess(1, 15)
    end

    if target.components.combat ~= nil and not target:HasTag("player") then
        target.components.combat:SuggestTarget(attacker)
    end
    target:PushEvent("attacked", { attacker = attacker, damage = 0, weapon = inst })
end

local function sleep()
    local inst = common("idle_purple", { "tranquilizer" })

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.weapon:SetOnAttack(sleepattack)
    inst.components.projectile:SetOnThrownFn(sleepthrown)

    return inst
end

local function firethrown(inst)
    inst.AnimState:PlayAnimation("dart_red")
    inst:AddTag("NOCLICK")
    inst.persists = false
end

local function fireattack(inst, attacker, target)
    if not target:IsValid() then
        --target killed or removed in combat damage phase
        return
    end

    target.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_impact_fire")
    target:PushEvent("attacked", {attacker = attacker, damage = 0})
    if target.components.burnable then
        target.components.burnable:Ignite(nil, attacker)
    end
    if target.components.freezable then
        target.components.freezable:Unfreeze()
    end
    if target.components.health then
        target.components.health:DoFireDamage(0, attacker)
    end
    if target.components.combat then
        target.components.combat:SuggestTarget(attacker)
    end
end

local function fire()
    local inst = common("idle_red", { "firedart" })

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.weapon:SetOnAttack(fireattack)
    inst.components.projectile:SetOnThrownFn(firethrown)

    return inst
end

local function pipeequip(inst, owner) 
    owner.AnimState:OverrideSymbol("swap_object", "swap_blowdart_pipe", "swap_blowdart_pipe")
    owner.AnimState:Show("ARM_carry") 
    owner.AnimState:Hide("ARM_normal") 
end

local function pipethrown(inst)
    inst.AnimState:PlayAnimation("dart_pipe")
    inst:AddTag("NOCLICK")
    inst.persists = false
end

local function pipe()
    local inst = common("idle_pipe")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.equippable:SetOnEquip(pipeequip)
    inst.components.weapon:SetDamage(TUNING.PIPE_DART_DAMAGE)
    inst.components.projectile:SetOnThrownFn(pipethrown)

    return inst
end

-- walrus blowdart is for use by walrus creature, not player
local function walrus()
    local inst = common("idle_pipe", { "NOCLICK" }, true)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst.components.projectile:SetOnThrownFn(pipethrown)
    inst.components.projectile:SetRange(TUNING.WALRUS_DART_RANGE)
    inst.components.projectile:SetHoming(false)
    inst.components.projectile:SetOnMissFn(inst.Remove)
    inst.components.projectile:SetLaunchOffset(Vector3(3, 2, 0))

    return inst
end

return Prefab("blowdart_sleep", sleep, assets, prefabs),
       Prefab("blowdart_fire", fire, assets, prefabs),
       Prefab("blowdart_pipe", pipe, assets, prefabs),
       Prefab("blowdart_walrus", walrus, assets, prefabs)
