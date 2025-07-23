require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/bird_lunar.zip"),
    Asset("ANIM", "anim/bird_lunar_build.zip"),
}

local prefabs =
{
	"lunar_egg",
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
}

local brain = require "brains/birdbrain" --Can we just use birdbrain? Let's find out!

----------------------------------------------------------

local function OnTrapped(inst, data)
    if data and data.trapper and data.trapper.settrapsymbols then
        data.trapper.settrapsymbols(inst.trappedbuild)
    end
end

local function OnDropped(inst)
    inst.sg:GoToState("stunned")
end

local DIET = { FOODTYPE.SEEDS }
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
    inst.Physics:SetSphere(1)

	inst:AddTag("soulless") -- no wortox souls
    inst:AddTag("scarytoprey")
    inst:AddTag("canbetrapped")
    inst:AddTag("bird")
    inst:AddTag("lunar_aligned")
    inst:AddTag("smallcreature")

    inst.Transform:SetFourFaced()

    inst.DynamicShadow:SetSize(1, .75)
    inst.DynamicShadow:Enable(false)

    inst.AnimState:SetBank("bird_lunar")
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

    inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL

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

    inst:SetStateGraph("SGbird") --Can we just use SGbird? let's find out!
    inst:SetBrain(brain)

	return inst
end

local function crowfn()
	local inst = commonfn()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.trappedbuild = "bird_lunar"

	return inst
end

--Has to be mutated{bird}
return Prefab("mutatedcrow", crowfn, assets, prefabs)