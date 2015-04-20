require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/eyeball_turret.zip"),
    Asset("ANIM", "anim/eyeball_turret_object.zip"),
}

local prefabs =
{
    "eye_charge",
    "eyeturret_base",
}

local brain = require "brains/eyeturretbrain"

local function retargetfn(inst)
    local player = ThePlayer
    local newtarget = FindEntity(inst, 20, function(guy)
            return  inst.components.combat:CanTarget(guy) and
                    (guy.components.combat.target == player or player.components.combat.target == guy)
    end,
    {"_combat"} -- see entityreplica.lua
    )

    return newtarget
end

local function shouldKeepTarget(inst, target)
    if target and target:IsValid() and
        (target.components.health and not target.components.health:IsDead()) then
        local distsq = target:GetDistanceSqToInst(inst)
        return distsq < 20*20
    else
        return false
    end
end

local function ShareTargetFn(dude)
    return dude:HasTag("eyeturret")
end

local function OnAttacked(inst, data)
    local attacker = data ~= nil and data.attacker
    if attacker == ThePlayer then
        return
    end
    inst.components.combat:SetTarget(attacker)
    inst.components.combat:ShareTarget(attacker, 15, ShareTargetFn, 10)
end

local function EquipWeapon(inst)
    if inst.components.inventory and not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
        local weapon = CreateEntity()
        --[[Non-networked entity]]
        weapon.entity:AddTransform()
        weapon:AddComponent("weapon")
        weapon.components.weapon:SetDamage(inst.components.combat.defaultdamage)
        weapon.components.weapon:SetRange(inst.components.combat.attackrange, inst.components.combat.attackrange+4)
        weapon.components.weapon:SetProjectile("eye_charge")
        weapon:AddComponent("inventoryitem")
        weapon.persists = false
        weapon.components.inventoryitem:SetOnDroppedFn(weapon.Remove)
        weapon:AddComponent("equippable")
        
        inst.components.inventory:Equip(weapon)
    end
end

local function ondeploy(inst, pt, deployer)
    local turret = SpawnPrefab("eyeturret")
    if turret ~= nil then
        turret.Physics:SetCollides(false)
        turret.Physics:Teleport(pt.x, 0, pt.z)
        turret.Physics:SetCollides(true)
        turret:syncanim("place")
        turret:syncanimpush("idle_loop", true)
        turret.SoundEmitter:PlaySound("dontstarve/common/place_structure_stone")
        inst:Remove()
    end
end

local function lighttweencb(inst, light)
    if light ~= nil then
        light:Enable(false)
    end
end

local function dotweenin(inst, l)
    inst.components.lighttweener:StartTween(nil, 0, .65, .7, nil, 0.15, lighttweencb)
end

local function syncanim(inst, animname, loop)
    inst.AnimState:PlayAnimation(animname, loop)
    inst.base.AnimState:PlayAnimation(animname, loop)
end

local function syncanimpush(inst, animname, loop)
    inst.AnimState:PushAnimation(animname, loop)
    inst.base.AnimState:PushAnimation(animname, loop)
end

local function itemfn()
    local inst = CreateEntity()
   
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("eyeball_turret_object")
    inst.AnimState:SetBuild("eyeball_turret_object")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("eyeturret")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    MakeHauntableLaunch(inst)

    --Tag to make proper sound effects play on hit.
    inst:AddTag("largecreature")

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy
    inst.components.deployable:SetDeployMode(DEPLOYMODE.ANYWHERE)
    inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.NONE)
    
    return inst
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.Transform:SetFourFaced()

    inst.MiniMapEntity:SetIcon("eyeball_turret.png")

    inst:AddTag("eyeturret")
    inst:AddTag("companion")

    inst.AnimState:SetBank("eyeball_turret")
    inst.AnimState:SetBuild("eyeball_turret")
    inst.AnimState:PlayAnimation("idle_loop")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.base = SpawnPrefab("eyeturret_base")
    inst.base.entity:SetParent(inst.entity)

    inst.syncanim = syncanim
    inst.syncanimpush = syncanimpush

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.EYETURRET_HEALTH)
    inst.components.health:StartRegen(TUNING.EYETURRET_REGEN, 1)

    inst:AddComponent("combat")
    inst.components.combat:SetRange(TUNING.EYETURRET_RANGE)
    inst.components.combat:SetDefaultDamage(TUNING.EYETURRET_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.EYETURRET_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(1, retargetfn)
    inst.components.combat:SetKeepTargetFunction(shouldKeepTarget)

    inst:AddComponent("lighttweener")
    inst.components.lighttweener:StartTween(inst.Light, 0, .65, .7, {251/255, 234/255, 234/255}, 0, lighttweencb)

    inst.dotweenin = dotweenin

    MakeLargeFreezableCharacter(inst)

    MakeHauntableFreeze(inst)

    inst:AddComponent("inventory")
    inst:DoTaskInTime(1, EquipWeapon)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_TINY    

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")

    inst:ListenForEvent("attacked", OnAttacked)

    inst:SetStateGraph("SGeyeturret")
    inst:SetBrain(brain)

    return inst
end

local baseassets =
{
    Asset("ANIM", "anim/eyeball_turret_base.zip"),
}

local function basefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("eyeball_turret_base")
    inst.AnimState:SetBuild("eyeball_turret_base")
    inst.AnimState:PlayAnimation("idle_loop")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return Prefab("common/eyeturret", fn, assets, prefabs),
    Prefab("common/eyeturret_item", itemfn, assets, prefabs),
    MakePlacer("common/eyeturret_item_placer", "eyeball_turret", "eyeball_turret", "idle_place"),
    Prefab("common/eyeturret_base", basefn, baseassets)