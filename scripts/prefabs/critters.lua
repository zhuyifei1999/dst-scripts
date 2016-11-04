local brain = require("brains/crittersbrain")

local WAKE_TO_FOLLOW_DISTANCE = 6
local SLEEP_NEAR_LEADER_DISTANCE = 5

local function IsLeaderSleeping(inst)
    return inst.components.follower.leader and inst.components.follower.leader:HasTag("sleeping")
end

local function ShouldWakeUp(inst)
    return (DefaultWakeTest(inst) and not IsLeaderSleeping(inst)) or not inst.components.follower:IsNearLeader(WAKE_TO_FOLLOW_DISTANCE)
end

local function ShouldSleep(inst)
    return (DefaultSleepTest(inst) 
			or IsLeaderSleeping(inst))
			and inst.components.follower:IsNearLeader(SLEEP_NEAR_LEADER_DISTANCE)
end

local function oneat(inst, food)
    if food ~= nil then
        if food.components.edible.foodtype == FOODTYPE.GOODIES then
			inst.sg.mem.queuethankyou = true
        end
    end

    inst.components.perishable:SetPercent(1)
    inst.components.perishable:StartPerishing()
end

-------------------------------------------------------------------------------
local function GetPeepChance(inst)
    local hunger_percent = inst.components.perishable:GetPercent()
    if hunger_percent <= 0 then
        return 0.8
    elseif hunger_percent < 0.2 then -- matches spoiled tag
        return (0.2 - inst.components.perishable:GetPercent()) * 2
    elseif hunger_percent < 0.5 then -- matches stale tag
        return 0.025
    end

    return 0
end

local CRITTER_AVOID_COMBAT_CHECK_RADIUS = 10
local CRITTER_AVOID_COMBAT_TIME = 10

local function onfinishedavoidingcombat(inst)
    inst._avoidcombattask = nil
end

local function AvoidCombatCheck(inst)
    if inst._avoidcombattask ~= nil then
        return true
    end

    -- if any object around the player has a combat target then return true
    local owner = inst.components.follower.leader
    if owner then
        local x,_,z = owner.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, 0, z, CRITTER_AVOID_COMBAT_CHECK_RADIUS, {"_combat"}, {"wall"} )
        for _,ent in pairs(ents) do
            local combat = ent.components.combat
            if combat and combat:HasTarget() then
                inst._avoidcombattask = inst:DoTaskInTime(CRITTER_AVOID_COMBAT_TIME, onfinishedavoidingcombat) 
                return true
            end
        end
    end

    return false
end

-------------------------------------------------------------------------------

local function MakeCritter(name, animdata, face, diet, flying)
    local assets =
    {
        Asset("ANIM", "anim/"..animdata..".zip"),
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddDynamicShadow()
        inst.entity:AddNetwork()

        inst.DynamicShadow:SetSize(2, .75)

		if face == 2 then
	        inst.Transform:SetTwoFaced()
	    elseif face == 4 then
	        inst.Transform:SetFourFaced()
	    elseif face == 6 then
	        inst.Transform:SetSixFaced()
	    elseif face == 8 then
	        inst.Transform:SetEightFaced()
		end
		
        inst.AnimState:SetBank(animdata)
        inst.AnimState:SetBuild(animdata)
        inst.AnimState:PlayAnimation("idle_loop")

        if flying then
            MakeFlyingCharacterPhysics(inst, 1, .5)
			inst.Physics:CollidesWith(COLLISION.CHARACTERS)
            inst:AddTag("flying")
        else
            MakeCharacterPhysics(inst, 1, .5)
        end

        inst:AddTag("critter")
        inst:AddTag("companion")
        inst:AddTag("notraptrigger")
        inst:AddTag("noauradamage")
        inst:AddTag("small_livestock")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.GetPeepChance = GetPeepChance
        inst.AvoidCombatCheck = AvoidCombatCheck

        inst:AddComponent("inspectable")

        inst:AddComponent("follower")
        inst.components.follower:KeepLeaderOnAttacked()
        inst.components.follower.keepdeadleader = true

        inst:AddComponent("knownlocations")

        inst:AddComponent("sleeper")
        inst.components.sleeper:SetResistance(3)
        inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
        inst.components.sleeper:SetSleepTest(ShouldSleep)
        inst.components.sleeper:SetWakeTest(ShouldWakeUp)

        inst:AddComponent("eater")
        inst.components.eater:SetDiet(diet, diet)
        inst.components.eater:SetOnEatFn(oneat)

        inst:AddComponent("perishable")
        inst.components.perishable:SetPerishTime(TUNING.CRITTER_HUNGERTIME)
        inst.components.perishable:StartPerishing()

        inst:AddComponent("locomotor")
        inst.components.locomotor.walkspeed = TUNING.CRITTER_WALK_SPEED

        inst:AddComponent("crittertraits")

        inst:SetBrain(brain)
        inst:SetStateGraph("SG"..name)

        --MakeMediumFreezableCharacter(inst, "critters_body")
        --MakeHauntablePanic(inst)

        return inst
    end

    return Prefab(name, fn, assets)
end

-------------------------------------------------------------------------------
local function builder_onbuilt(inst, builder)
    local theta = math.random() * 2 * PI
    local pt = builder:GetPosition()
    local radius = 1
    local offset = FindWalkableOffset(pt, theta, radius, 6, true)
    if offset ~= nil then
        pt.x = pt.x + offset.x
        pt.z = pt.z + offset.z
    end
    builder.components.petleash:SpawnPetAt(pt.x, 0, pt.z, inst.pettype)
    inst:Remove()
end

local function MakeBuilder(prefab)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()

        inst:AddTag("CLASSIFIED")

        --[[Non-networked entity]]
        inst.persists = false

        --Auto-remove if not spawned by builder
        inst:DoTaskInTime(0, inst.Remove)

        if not TheWorld.ismastersim then
            return inst
        end

        inst.pettype = prefab
        inst.OnBuiltFn = builder_onbuilt

        return inst
    end

    return Prefab(prefab.."_builder", fn, nil, { prefab })
end
-------------------------------------------------------------------------------

local standard_diet = { FOODGROUP.OMNI }

return MakeCritter("critter_lamb", "sheepington", 6, standard_diet, false),
       MakeBuilder("critter_lamb"),
       MakeCritter("critter_puppy", "pupington", 4, standard_diet, false),
       MakeBuilder("critter_puppy"),
       MakeCritter("critter_kitten", "kittington", 6, standard_diet, false),
       MakeBuilder("critter_kitten"),
       MakeCritter("critter_dragonling", "dragonling", 6, standard_diet, true),
       MakeBuilder("critter_dragonling"),
       MakeCritter("critter_glomling", "glomling", 6, standard_diet, true),
       MakeBuilder("critter_glomling")
