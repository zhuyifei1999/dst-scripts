local assets = 
{
    Asset("ANIM", "anim/waxwell_shadow_mod.zip"),
	Asset("SOUND", "sound/maxwell.fsb"),
	Asset("ANIM", "anim/swap_pickaxe.zip"),
	Asset("ANIM", "anim/swap_axe.zip"),
	Asset("ANIM", "anim/swap_nightmaresword.zip"),
}

local prefabs = 
{

}

local brain = require"brains/shadowwaxwellbrain"

local items =
{
	AXE = "swap_axe",
	PICK = "swap_pickaxe",
    SWORD = "swap_nightmaresword"
}

local function ondeath(inst)
	inst.components.sanityaura.penalty = 0
	local player = GetPlayer()
	if player then
		player.components.sanity:RecalculatePenalty()
	end
end

local function EquipItem(inst, item)
	if item then
	    inst.AnimState:OverrideSymbol("swap_object", item, item)
	    inst.AnimState:Show("ARM_carry") 
	    inst.AnimState:Hide("ARM_normal")
	end
end

local function die(inst)
	inst.components.health:Kill()
end

local function resume(inst, time)
    if inst.death then
        inst.death:Cancel()
        inst.death = nil
    end
    inst.death = inst:DoTaskInTime(time, die)
end

local function onsave(inst, data)
    data.timeleft = (inst.lifetime - inst:GetTimeAlive())
end

local function KeepTarget(isnt, target)
    return target and target:IsValid()
end

local function onload(inst, data)
    if data.timeleft then
        inst.lifetime = data.timeleft
        if inst.lifetime > 0 then
            resume(inst, inst.lifetime)
        else
            die(inst)
        end
    end
end

local function entitydeathfn(inst, data)
    if data.inst:HasTag("player") then
        inst:DoTaskInTime(math.random(), function() inst.components.health:Kill() end)
    end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeGhostPhysics(inst, 1, .5)

    inst.Transform:SetFourFaced(inst)

    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("waxwell_shadow_mod")
    inst.AnimState:PlayAnimation("idle")

    inst.AnimState:Hide("ARM_carry")
    inst.AnimState:Hide("hat")
    inst.AnimState:Hide("hat_hair")

    inst:AddTag("scarytoprey")
    inst:AddTag("NOCLICK")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

	inst:AddComponent("colourtweener")
	inst.components.colourtweener:StartTween({0,0,0,.5}, 0)

	inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier( 0.6 )
    inst.components.locomotor.pathcaps = { ignorecreep = true }
    inst.components.locomotor.runspeed = TUNING.SHADOWWAXWELL_SPEED

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "torso"
    -- inst.components.combat:SetRetargetFunction(1, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetAttackPeriod(TUNING.SHADOWWAXWELL_ATTACK_PERIOD)
    inst.components.combat:SetRange(2, 3)
    inst.components.combat:SetDefaultDamage(TUNING.SHADOWWAXWELL_DAMAGE)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.SHADOWWAXWELL_LIFE)
    inst.components.health.nofadeout = true
    inst:ListenForEvent("death", ondeath)

	inst:AddComponent("inventory")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.penalty = TUNING.SHADOWWAXWELL_SANITY_PENALTY

    MakeHauntablePanic(inst)

    inst.items = items
    inst.equipfn = EquipItem

    inst.lifetime = TUNING.SHADOWWAXWELL_LIFETIME
    inst.death = inst:DoTaskInTime(inst.lifetime, die)

    inst.OnSave = onsave
    inst.OnLoad = onload

    EquipItem(inst)

    inst:ListenForEvent("entity_death", function(world, data) entitydeathfn(inst, data) end, TheWorld)

    inst:AddComponent("follower")

	inst:SetBrain(brain)
	inst:SetStateGraph("SGshadowwaxwell")

	return inst
end

return Prefab("common/shadowwaxwell", fn, assets, prefabs)