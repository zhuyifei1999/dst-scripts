local brain = require "brains/leifbrain"

local assets =
{
	Asset("ANIM", "anim/leif_walking.zip"),
	Asset("ANIM", "anim/leif_actions.zip"),
	Asset("ANIM", "anim/leif_attacks.zip"),
	Asset("ANIM", "anim/leif_idles.zip"),
	Asset("ANIM", "anim/leif_build.zip"),
	Asset("ANIM", "anim/leif_lumpy_build.zip"),
	Asset("SOUND", "sound/leif.fsb"),
}

local prefabs =
{
	"meat",
	"log", 
	"character_fire",
    "livinglog",
}

local onloadfn = function(inst, data)
    if data and data.hibernate then
        inst.components.sleeper.hibernate = true
    end
    if data and data.sleep_time then
         inst.components.sleeper.testtime = data.sleep_time
    end
    if data and data.sleeping then     
         inst.components.sleeper:GoToSleep()
    end
end

local onsavefn = function(inst, data)
    if inst.components.sleeper:IsAsleep() then
        data.sleeping = true
        data.sleep_time = inst.components.sleeper.testtime
    end

    if inst.components.sleeper:IsHibernating() then
        data.hibernate = true
    end
end

local function CalcSanityAura(inst, observer)
	
	if inst.components.combat.target then
		return -TUNING.SANITYAURA_LARGE
	else
		return -TUNING.SANITYAURA_MED
	end
	
	return 0
end

local function OnBurnt(inst)
    if inst.components.propagator and inst.components.health and not inst.components.health:IsDead() then
        inst.components.propagator.acceptsheat = true
    end
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
end

local function common_fn(build)
    
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 1000, .5)

    inst.DynamicShadow:SetSize(4, 1.5)
    inst.Transform:SetFourFaced()

    inst:AddTag("epic")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("leif")
    inst:AddTag("tree")
    inst:AddTag("largecreature")

    inst.AnimState:SetBank("leif")
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle_loop", true)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

	inst.OnLoad = onloadfn
	inst.OnSave = onsavefn

    ------------------------------------------

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = 1.5    

    ------------------------------------------
    inst:SetStateGraph("SGLeif")

    ------------------------------------------

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    MakeLargeBurnableCharacter(inst, "marker")
    inst.components.burnable.flammability = TUNING.LEIF_FLAMMABILITY
    inst.components.burnable:SetOnBurntFn(OnBurnt)
    inst.components.propagator.acceptsheat = true

    MakeHugeFreezableCharacter(inst, "marker")
    ------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.LEIF_HEALTH)

    ------------------

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.LEIF_DAMAGE)
    inst.components.combat.playerdamagepercent = TUNING.LEIF_DAMAGE_PLAYER_PERCENT
    inst.components.combat.hiteffectsymbol = "marker"
    inst.components.combat:SetAttackPeriod(TUNING.LEIF_ATTACK_PERIOD)

    ------------------------------------------
    MakeHauntableIgnite(inst)
    ------------------------------------------

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)

    ------------------------------------------

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"livinglog", "livinglog", "livinglog", "livinglog", "livinglog", "livinglog", "monstermeat"})

    ------------------------------------------

    inst:AddComponent("inspectable")
	inst.components.inspectable:RecordViews()
    ------------------------------------------

    inst:SetBrain(brain)

    inst:ListenForEvent("attacked", OnAttacked)

    return inst
end

local function normal_fn()
    return common_fn("leif_build")
end

local function sparse_fn()
	return common_fn("leif_lumpy_build")
end

return Prefab("common/leif", normal_fn, assets, prefabs),
	   Prefab("common/leif_sparse", sparse_fn, assets, prefabs)