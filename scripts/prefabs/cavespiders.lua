local hiderassets =
{
	Asset("ANIM", "anim/ds_spider_basic.zip"),
	Asset("ANIM", "anim/ds_spider_caves.zip"),
	Asset("SOUND", "sound/spider.fsb"),
}

local spitterassets =
{
	Asset("ANIM", "anim/ds_spider_basic.zip"),
	Asset("ANIM", "anim/ds_spider2_caves.zip"),
	Asset("SOUND", "sound/spider.fsb"),
}

local dropperassets = 
{
    Asset("ANIM", "anim/ds_spider_basic.zip"),
    Asset("ANIM", "anim/ds_spider_warrior.zip"),
    Asset("ANIM", "anim/spider_white.zip"),
    Asset("SOUND", "sound/spider.fsb"),
}

local prefabs =
{
	"spidergland",
	"monstermeat",
	"silk",
	"spider_web_spit",
}

local function ShouldAcceptItem(inst, item, giver)

    if not giver:HasTag("spiderwhisperer") then
        return false
    end
    
    if inst.components.eater:CanEat(item) then
        return true
    end
end

function GetOtherSpiders(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, 15,  {"spider"}, {"FX", "NOCLICK", "DECOR","INLIMBO"})
    return ents
end

local function OnGetItemFromPlayer(inst, giver, item)
    if inst.components.eater:CanEat(item) then  

        if inst.components.combat.target and inst.components.combat.target == giver then
            inst.components.combat:SetTarget(nil)
        elseif giver.components.leader then
            inst.SoundEmitter:PlaySound("dontstarve/common/makeFriend")
            giver.components.leader:AddFollower(inst)
            local loyaltyTime = item.components.edible:GetHunger() * TUNING.SPIDER_LOYALTY_PER_HUNGER
            inst.components.follower:AddLoyaltyTime(loyaltyTime)
        end

        local spiders = GetOtherSpiders(inst)
        local maxSpiders = 3

        for k,v in pairs(spiders) do
            if maxSpiders < 0 then
                break
            end

            if v.components.combat.target and v.components.combat.target == giver then
                v.components.combat:SetTarget(nil)
            elseif giver.components.leader then
                v.SoundEmitter:PlaySound("dontstarve/common/makeFriend")
                giver.components.leader:AddFollower(v)
                local loyaltyTime = item.components.edible:GetHunger() * TUNING.SPIDER_LOYALTY_PER_HUNGER
                v.components.follower:AddLoyaltyTime(loyaltyTime)
            end
            maxSpiders = maxSpiders - 1

            if v.components.sleeper:IsAsleep() then
                v.components.sleeper:WakeUp()
            end
        end
        item:Remove()
    end
end

local function OnRefuseItem(inst, item)
    inst.sg:GoToState("taunt")
    if inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end


local function Retarget(inst)
    return FindEntity(inst, SpringCombatMod(TUNING.SPIDER_WARRIOR_TARGET_DIST), function(guy)
		return inst.components.combat:CanTarget(guy)
			and not (inst.components.follower and inst.components.follower.leader == guy)
	end,
	nil,
	nil,
	{"character","pig"}
	)
end

local function FindTargets(guy)
    return (guy:HasTag("character") or guy:HasTag("pig"))
       and inst.components.combat:CanTarget(guy)
       and not (inst.components.follower and inst.components.follower.leader == guy)
end

local function keeptargetfn(inst, target)
   return target
          and target.components.combat
          and target.components.health
          and not target.components.health:IsDead()
          and not (inst.components.follower and inst.components.follower.leader == target)
          and not (inst.components.follower and inst.components.follower:IsLeaderSame(target))
end

local function ShouldSleep(inst)
    return TheWorld.state.isday
           and not (inst.components.combat and inst.components.combat.target)
           and not (inst.components.homeseeker and inst.components.homeseeker:HasHome() )
           and not (inst.components.burnable and inst.components.burnable:IsBurning() )
           and not (inst.components.follower and inst.components.follower.leader)
end

local function ShouldWake(inst)
    return TheWorld.state.isnight
           or (inst.components.combat and inst.components.combat.target)
           or (inst.components.homeseeker and inst.components.homeseeker:HasHome() )
           or (inst.components.burnable and inst.components.burnable:IsBurning() )
           or (inst.components.follower and inst.components.follower.leader)
           or (inst:HasTag("spider_warrior") and FindEntity(inst, TUNING.SPIDER_WARRIOR_WAKE_RADIUS, function(...) return FindTargets(inst, ...) end ))
end

local function DoReturn(inst)
	if inst.components.homeseeker and inst.components.homeseeker.home and inst.components.homeseeker.home.components.childspawner then
		inst.components.homeseeker.home.components.childspawner:GoHome(inst)
	end
end

local function OnIsDay(inst, isday)
	if not isday then
        inst.components.sleeper:WakeUp()
    elseif inst:IsAsleep() then
        DoReturn(inst)
    end
end

local function OnEntitySleep(inst)
	if TheWorld.state.isday then
		DoReturn(inst)
	end
end

local function SummonFriends(inst, attacker)
	local den = GetClosestInstWithTag("spiderden",inst, TUNING.SPIDER_SUMMON_WARRIORS_RADIUS)
	if den and den.components.combat and den.components.combat.onhitfn then
		den.components.combat.onhitfn(den, attacker)
	end
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, 30, function(dude)
        return dude:HasTag("spider")
               and not dude.components.health:IsDead()
               and dude.components.follower
               and dude.components.follower.leader == inst.components.follower.leader
    end, 10)
end

local function WeaponDropped(inst)
    inst:Remove()
end

local function SanityAura(inst, observer)
    return observer:HasTag("spiderwhisperer") and 0 or -TUNING.SANITYAURA_SMALL
end

local function MakeWeapon(inst)
    if inst.components.inventory then
        local weapon = CreateEntity()
        weapon.entity:AddTransform()
        MakeInventoryPhysics(weapon)
        weapon:AddComponent("weapon")
        weapon.components.weapon:SetDamage(TUNING.SPIDER_SPITTER_DAMAGE_RANGED)
        weapon.components.weapon:SetRange(inst.components.combat.attackrange, inst.components.combat.attackrange+4)
        weapon.components.weapon:SetProjectile("spider_web_spit")
        weapon:AddComponent("inventoryitem")
        weapon.persists = false
        weapon.components.inventoryitem:SetOnDroppedFn(function() WeaponDropped(weapon) end)
        weapon:AddComponent("equippable")
        inst.weapon = weapon
        inst.components.inventory:Equip(inst.weapon)
        inst.components.inventory:Unequip(EQUIPSLOTS.HANDS)
    end
end

local function create_common(bank, build, tag)
	local inst = CreateEntity()
	
    inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddLightWatcher()
	inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()
    
    MakeCharacterPhysics(inst, 10, .5)

    inst.DynamicShadow:SetSize(1.5, .5)
    inst.Transform:SetFourFaced()
    
    ----------
    
    inst:AddTag("monster")
    inst:AddTag("hostile")
	inst:AddTag("scarytoprey")    
    inst:AddTag("canbetrapped")    
    inst:AddTag("smallcreature")
    inst:AddTag("spider")
    if tag ~= nil then
        inst:AddTag(tag)
    end
    
    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle")
    
    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then
        return inst
    end

    ----------
    inst.OnEntitySleep = OnEntitySleep


-- locomotor must be constructed before the stategraph!
    inst:AddComponent("locomotor")
	inst.components.locomotor:SetSlowMultiplier( 1 )
	inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = true }
  
    inst:SetStateGraph("SGspider")
    
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddRandomLoot("monstermeat", 1)
    inst.components.lootdropper:AddRandomLoot("silk", .5)
    inst.components.lootdropper:AddRandomLoot("spidergland", .5)
    inst.components.lootdropper.numrandomloot = 1
   
    ---------------------        
    MakeMediumBurnableCharacter(inst, "body")
    MakeMediumFreezableCharacter(inst, "body")
    inst.components.burnable.flammability = TUNING.SPIDER_FLAMMABILITY
    ---------------------       
    
    
    ------------------
    inst:AddComponent("health")

    ------------------
    
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)
	inst.components.combat:SetOnHit(SummonFriends)
    inst.components.combat:SetHurtSound("dontstarve/creatures/cavespider/hit_response")
     
    inst:AddComponent("follower")
    inst.components.follower.maxfollowtime = TUNING.TOTAL_DAY_TIME
    
    
    ------------------
    
    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWake)
    ------------------
    
    inst:AddComponent("knownlocations")

    ------------------
    
    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.MEAT }, { FOODTYPE.MEAT })
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater.strongstomach = true -- can eat monster meat!
    
    ------------------
    
    inst:AddComponent("inspectable")
    
    ------------------

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem

    ------------------

    
    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = SanityAura
    
    
    local brain = require "brains/spiderbrain"
    inst:SetBrain(brain)

    inst:ListenForEvent("attacked", OnAttacked)
    
    inst:WatchWorldState("isday", OnIsDay)

    return inst
end

local function create_hider()
    local inst = create_common("spider_hider","DS_spider_caves","spider_hider")
    
    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.health:SetMaxHealth(TUNING.SPIDER_HIDER_HEALTH)


    inst.components.combat:SetDefaultDamage(TUNING.SPIDER_HIDER_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.SPIDER_HIDER_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(1, Retarget)

    inst.components.locomotor.walkspeed = TUNING.SPIDER_HIDER_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.SPIDER_HIDER_RUN_SPEED
	
	inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED
    return inst
end

local function create_spitter()
    local inst = create_common("spider_spitter", "DS_spider2_caves", "spider_spitter")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventory")
    inst.components.trader.deleteitemonaccept = false

    inst.components.health:SetMaxHealth(TUNING.SPIDER_SPITTER_HEALTH)

    inst.components.combat:SetDefaultDamage(TUNING.SPIDER_SPITTER_DAMAGE_MELEE)
    inst.components.combat:SetAttackPeriod(TUNING.SPIDER_SPITTER_ATTACK_PERIOD + math.random()*2)
    inst.components.combat:SetRange(TUNING.SPIDER_SPITTER_ATTACK_RANGE, TUNING.SPIDER_SPITTER_HIT_RANGE)
    inst.components.combat:SetRetargetFunction(2, Retarget)

    inst.components.locomotor.walkspeed = TUNING.SPIDER_SPITTER_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.SPIDER_SPITTER_RUN_SPEED

    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED
    MakeWeapon(inst)

    return inst
end

local function create_dropper()
    local inst = create_common("spider", "spider_white","spider_warrior")
    
    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.health:SetMaxHealth(TUNING.SPIDER_WARRIOR_HEALTH)

    inst.components.combat:SetDefaultDamage(TUNING.SPIDER_WARRIOR_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.SPIDER_WARRIOR_ATTACK_PERIOD + math.random()*2)
    inst.components.combat:SetRange(TUNING.SPIDER_WARRIOR_ATTACK_RANGE, TUNING.SPIDER_WARRIOR_HIT_RANGE)
    inst.components.combat:SetRetargetFunction(2, Retarget)
    
    inst.components.locomotor.walkspeed = TUNING.SPIDER_WARRIOR_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.SPIDER_WARRIOR_RUN_SPEED

    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    return inst
end

return Prefab("cave/monsters/spider_hider", create_hider, hiderassets, prefabs),
Prefab("cave/monsters/spider_spitter", create_spitter, spitterassets, prefabs),
Prefab("cave/monsters/spider_dropper", create_dropper, dropperassets, prefabs)
