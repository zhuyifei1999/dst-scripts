require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/bird_lunar.zip"),
    Asset("ANIM", "anim/bird_lunar_build.zip"),
}

local prefabs =
{

}

SetSharedLootTable('bird_mutant_rift',
{
    {'spoiled_food',       1.00},
})

local sounds =
{
    --TODO sounds
    flyin = "dontstarve/birds/flyin",
    chirp = "moonstorm/creatures/mutated_crow/chirp",
    takeoff = "moonstorm/creatures/mutated_crow/take_off",
    attack = "moonstorm/creatures/mutated_crow/attack",
    eat = "",
}

local brain = require "brains/bird_mutant_rift_brain"

----------------------------------------------------------

local function OnTrapped(inst, data)
    if data and data.trapper and data.trapper.settrapsymbols then
        data.trapper.settrapsymbols(inst.trappedbuild)
    end
end

local function OnDropped(inst)
    inst.sg:GoToState("stunned")
end

local SPHERE_RADIUS = 0.25 --4x as small as other birds. We want it to not get stuck on objects when hopping around...
local DIET = { FOODTYPE.LUNAR_SHARDS }
local function commonfn()
    local inst = CreateEntity()
    --Core components
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    --Initialize physics
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
	inst.Physics:SetCollisionMask(
		COLLISION.WORLD,
		COLLISION.OBSTACLES,
		COLLISION.SMALLOBSTACLES
	)
    inst.Physics:SetMass(1)
    inst.Physics:SetSphere(SPHERE_RADIUS)

	inst:AddTag("soulless") -- no wortox souls
    inst:AddTag("canbetrapped")
    inst:AddTag("bird")
    inst:AddTag("lunar_aligned")
    inst:AddTag("smallcreature")
    inst:AddTag("bird_mutant_rift")

    inst.Transform:SetTwoFaced()

    inst.DynamicShadow:SetSize(1, .75)
    inst.DynamicShadow:Enable(false)

    inst.AnimState:SetBank("crow")
    inst.AnimState:SetBuild("bird_lunar_build")
    inst.AnimState:PlayAnimation("idle", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.sounds = sounds
    inst.flyawaydistance = TUNING.BIRD_SEE_THREAT_DISTANCE

    inst:AddComponent("inspectable")

    inst:AddComponent("occupier")

    inst:AddComponent("eater")
    inst.components.eater:SetDiet(DIET, DIET)

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = TUNING.RIFT_BIRD_WALKSPEED
    inst.components.locomotor.runspeed = TUNING.RIFT_BIRD_WALKSPEED
    inst.components.locomotor:EnableGroundSpeedMultiplier(true)
    inst.components.locomotor:SetTriggersCreep(true)

	inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.RIFT_BIRD_HEALTH)
    inst.components.health.murdersound = "dontstarve/wilson/hit_animal"

    inst:AddComponent("entitytracker")

    inst:AddComponent("timer")

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.RIFT_BIRD_DAMAGE)
	inst.components.combat:SetAttackPeriod(TUNING.RIFT_BIRD_ATTACK_RANGE)
	inst.components.combat:SetRange(TUNING.RIFT_BIRD_ATTACK_RANGE)
    --inst.components.combat:SetRetargetFunction(1, Retarget)

    inst:AddComponent("planarentity")

    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(TUNING.RIFT_BIRD_DAMAGE)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.nobounce = true
    inst.components.inventoryitem.canbepickedup = false
    inst.components.inventoryitem.canbepickedupalive = true
    inst.components.inventoryitem:SetSinks(true)

    inst:ListenForEvent("ontrapped", OnTrapped)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('bird_mutant_rift')

	inst:AddComponent("knownlocations")
    MakeHauntablePanic(inst)
    MakeFeedableSmallLivestock(inst, TUNING.BIRD_PERISH_TIME, nil, OnDropped)
    MakeSmallBurnableCharacter(inst, "crow_body")
    MakeTinyFreezableCharacter(inst, "crow_body")

    local birdspawner = TheWorld.components.birdspawner
    if birdspawner ~= nil then
        inst:ListenForEvent("onremove", birdspawner.StopTrackingFn)
        inst:ListenForEvent("enterlimbo", birdspawner.StopTrackingFn)
        birdspawner:StartTracking(inst)
    end

    inst:SetStateGraph("SGbird")
    inst:SetBrain(brain)

	return inst
end

local function crowfn()
	local inst = commonfn()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.trappedbuild = "bird_lunar_build"

	return inst
end

-- All birds currently mutate into this one
return Prefab("mutatedbird", crowfn, assets, prefabs)