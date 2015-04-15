local assets =
{
	Asset("ANIM", "anim/spat_basic.zip"),
	Asset("ANIM", "anim/spat_actions.zip"),
	Asset("ANIM", "anim/spat_build.zip"),
    Asset("ANIM", "anim/spat_phlegm.zip"),
	Asset("SOUND", "sound/beefalo.fsb"),
}

local prefabs =
{
    "meat",
    "poop",
    "steelwool",
    "phlegm",
    "spat_bomb",
}

local projectile_assets =
{
    Asset("ANIM", "anim/spat_bomb.zip"),
}

local projectile_prefabs =
{
    "spat_splat_fx",
    "spat_splash_fx_full",
    "spat_splash_fx_med",
    "spat_splash_fx_low",
    "spat_splash_fx_melted",
}

local brain = require("brains/spatbrain")

SetSharedLootTable( 'spat',
{
    {'meat',            1.00},
    {'meat',            1.00},
    {'meat',            1.00},
    {'meat',            1.00},
    {'steelwool',       1.00},
    {'steelwool',       1.00},
    {'steelwool',       0.50},
    {'phlegm',          1.00},
    {'phlegm',          0.50},
})

local sounds = 
{
    walk = "dontstarve/creatures/spat/walk",
    grunt = "dontstarve/creatures/spat/grunt",
    yell = "dontstarve/creatures/spat/yell",
    hit = "dontstarve/creatures/spat/hurt",
    death = "dontstarve/creatures/spat/death",
    curious = "dontstarve/creatures/spat/curious",
    sleep = "dontstarve/creatures/spat/sleep",
    angry = "dontstarve/creatures/spat/angry",
    spit = "dontstarve/creatures/spat/spit",
    spit_hit = "dontstarve/creatures/spat/spit_hit",
}

local function Retarget(inst)
    return FindEntity(inst, TUNING.SPAT_TARGET_DIST, function(guy)
        return inst.components.combat:CanTarget(guy)
    end,
    nil,
    nil,
    {"player","monster"})
end

local function KeepTarget(inst, target)
    return distsq(Vector3(target.Transform:GetWorldPosition()), Vector3(inst.Transform:GetWorldPosition())) < TUNING.SPAT_CHASE_DIST * TUNING.SPAT_CHASE_DIST
end

local function OnNewTarget(inst, data)

end

local function OnAttacked(inst, data)
    local target = inst.components.combat.target
    if target and target.components.pinnable and target.components.pinnable:IsStuck() then
        -- if we've goo'd someone, stay attacking them!
        return
    end
    
    inst.components.combat:SetTarget(data.attacker)
end

local function GetStatus(inst)
    if inst.components.beard and inst.components.beard.bits == 0 then
        return "NAKED"
    end
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

local function EquipWeapons(inst)
    if inst.components.inventory and not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
        local snotbomb = CreateEntity()
        snotbomb.name = "Snotbomb"
        --[[Non-networked entity]]
        snotbomb.entity:AddTransform()
        snotbomb:AddComponent("weapon")
        snotbomb.components.weapon:SetDamage(TUNING.SPAT_PHLEGM_DAMAGE)
        snotbomb.components.weapon:SetRange(TUNING.SPAT_PHLEGM_ATTACKRANGE)
        snotbomb.components.weapon:SetProjectile("spat_bomb")
        snotbomb:AddComponent("inventoryitem")
        snotbomb.persists = false
        snotbomb.components.inventoryitem:SetOnDroppedFn(inst.Remove)
        snotbomb:AddComponent("equippable")
        snotbomb:AddTag("snotbomb")
        
        inst.components.inventory:GiveItem(snotbomb)
        inst.weaponitems.snotbomb = snotbomb

        local meleeweapon = CreateEntity()
        meleeweapon.name = "Snaut Bash"
        --[[Non-networked entity]]
        meleeweapon.entity:AddTransform()
        meleeweapon:AddComponent("weapon")
        meleeweapon.components.weapon:SetDamage(TUNING.SPAT_MELEE_DAMAGE)
        meleeweapon.components.weapon:SetRange(TUNING.SPAT_MELEE_ATTACKRANGE)
        meleeweapon:AddComponent("inventoryitem")
        meleeweapon.persists = false
        meleeweapon.components.inventoryitem:SetOnDroppedFn(inst.Remove)
        meleeweapon:AddComponent("equippable")
        snotbomb:AddTag("meleeweapon")
        
        inst.components.inventory:GiveItem(meleeweapon)
        inst.weaponitems.meleeweapon = meleeweapon
    end
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
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("spat")
    inst.AnimState:SetBuild("spat_build")
    inst.AnimState:PlayAnimation("idle_loop", true)
    
    inst:AddTag("spat")
    inst:AddTag("animal")
    inst:AddTag("largecreature")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()
    
    inst.sounds = sounds

    local hair_growth_days = 3

--[[ SHAVING
    inst:AddComponent("beard")
    -- assume the beefalo has already grown its hair
    inst.components.beard.bits = 3
    inst.components.beard.daysgrowth = hair_growth_days + 1 
    inst.components.beard.onreset = OnResetBeard
    inst.components.beard.canshavetest = CanShaveTest
    inst.components.beard.prize = "beefalowool"
    inst.components.beard:AddCallback(0, OnShaved)
    inst.components.beard:AddCallback(hair_growth_days, OnHairGrowth)
]]
    
    inst:AddComponent("eater")
    inst.components.eater:SetVegetarian()
    
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "spat_body"
    inst.components.combat:SetRetargetFunction(1, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetAttackPeriod(3)
    inst.components.combat:SetHurtSound(sounds.hit)
     
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.SPAT_HEALTH)

    inst:AddComponent("inventory")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('spat')    
    
    inst:AddComponent("inspectable")
    -- SHAVING
    -- inst.components.inspectable.getstatus = GetStatus
    
    inst:ListenForEvent("newcombattarget", OnNewTarget)
    inst:ListenForEvent("attacked", OnAttacked)

    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetPrefab("poop")
    inst.components.periodicspawner:SetRandomTimes(40, 60)
    inst.components.periodicspawner:SetDensityInRange(20, 2)
    inst.components.periodicspawner:SetMinimumSpacing(8)
    inst.components.periodicspawner:Start()

    MakeLargeBurnableCharacter(inst, "spat_body")
    MakeLargeFreezableCharacter(inst, "spat_body")
    
    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = 1.5
    inst.components.locomotor.runspeed = 7
    
    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)

    MakeHauntablePanic(inst)
    AddHauntableCustomReaction(inst, function(inst, haunter)
        inst.components.periodicspawner:TrySpawn()
        return true
    end, true, false, true)
    
    inst:SetBrain(brain)
    inst:SetStateGraph("SGspat")
    
    inst.weaponitems = {}
    EquipWeapons(inst)

    return inst
end

local function OnProjectileHit(inst, other)
    inst.SoundEmitter:PlaySound(sounds.spit_hit)
    local x,y,z = inst:GetPosition():Get()
    SpawnPrefab("spat_splat_fx").Transform:SetPosition(x,0,z)

    local attacker = inst.components.complexprojectile.attacker
    local owningweapon = inst.components.complexprojectile.owningweapon

    if other then
        -- stick whatever got actually hit by the projectile
        attacker.components.combat:DoAttack(other, owningweapon, inst)
        if other.components.pinnable then
            other.components.pinnable:Stick()
        end

    else
        -- otherwise stick our target, if he was in splash radius
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,y,z, TUNING.SPAT_PHLEGM_RADIUS)
        for i,ent in ipairs(ents) do
            if ent == attacker.components.combat.target then
                attacker.components.combat:DoAttack(ent, owningweapon, inst)
                if ent.components.pinnable then
                    ent.components.pinnable:Stick()
                end
            end
        end

    end
    inst:Remove()
end

local function oncollide(inst, other)
    OnProjectileHit(inst)
end

local function projectilefn()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local sound = inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    
    local physics = inst.entity:AddPhysics()
    physics:SetMass(1)
    physics:SetCapsule(0.02, 0.02)
    inst.Physics:SetFriction(10)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)

    anim:SetBank("spat_bomb")
    anim:SetBuild("spat_bomb")
    anim:PlayAnimation("spin_loop", true)

    if not TheWorld.ismastersim then
        return inst
    end
    inst.entity:SetPristine()

    inst.Physics:SetCollisionCallback(oncollide)

    inst.persists = false

    inst:AddComponent("locomotor")
    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetOnHit(OnProjectileHit)
    inst.components.complexprojectile:SetHorizontalSpeed(30)
    inst.components.complexprojectile:SetLaunchOffset({x=3,y=2,z=0})

    return inst
end

return Prefab("forest/animals/spat", fn, assets, prefabs),
       Prefab("common/projectiles/spat_bomb", projectilefn, projectile_assets, projectile_prefabs)