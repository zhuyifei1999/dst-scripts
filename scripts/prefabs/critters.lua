local brain = require("brains/crittersbrain")

local WAKE_TO_FOLLOW_DISTANCE = 6
local SLEEP_NEAR_LEADER_DISTANCE = 5

local HUNGRY_PERIESH_PERCENT = 0.5 -- matches stale tag
local STARVING_PERIESH_PERCENT = 0.2 -- matches spoiked tag

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

	-- temp minigame around feeding, if fed at the right time, its max hunger goes up, if left too long, its max hunger goes down
	local perish = inst.components.perishable:GetPercent()
	if perish <= STARVING_PERIESH_PERCENT then
		inst.components.perishable.perishtime = math.max(inst.components.perishable.perishtime - TUNING.CRITTER_HUNGERTIME_DELTA, TUNING.CRITTER_HUNGERTIME_MIN)
	elseif perish <= HUNGRY_PERIESH_PERCENT then
		inst.components.perishable.perishtime = math.min(inst.components.perishable.perishtime + TUNING.CRITTER_HUNGERTIME_DELTA, TUNING.CRITTER_HUNGERTIME_MAX)
	end

    inst.components.perishable:SetPercent(1)
    inst.components.perishable:StartPerishing()
end

-------------------------------------------------------------------------------
local function GetPeepChance(inst)
    local hunger_percent = inst.components.perishable:GetPercent()
    if hunger_percent <= 0 then
        return 0.8
    elseif hunger_percent < STARVING_PERIESH_PERCENT then -- matches spoiled tag
        return (0.2 - inst.components.perishable:GetPercent()) * 2
    elseif hunger_percent < HUNGRY_PERIESH_PERCENT then
        return 0.025
    end

    return 0
end

local function IsAffectionate(inst)
    return (inst.components.perishable == nil or inst.components.perishable:GetPercent() > HUNGRY_PERIESH_PERCENT) -- no affection if hungry
            or false
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

local function OnSave(inst, data)
    if inst.wormlight ~= nil then
        data.wormlight = inst.wormlight:GetSaveRecord()
    end
end

local function OnLoad(inst, data)
    if data ~= nil and data.wormlight ~= nil and inst.wormlight == nil then
        local wormlight = SpawnSaveRecord(data.wormlight)
        if wormlight ~= nil and wormlight.components.spell ~= nil then
            wormlight.components.spell:SetTarget(inst)
            if wormlight:IsValid() then
                if wormlight.components.spell.target == nil then
                    wormlight:Remove()
                else
                    wormlight.components.spell:ResumeSpell()
                end
            end
        end
    end
end

-------------------------------------------------------------------------------

local function OnClientFadeUpdate(inst)
    inst._fadeval = math.max(0, inst._fadeval - 2 * FRAMES)
    local k = inst._fadeval >= .6 and 0 or 1 - inst._fadeval * inst._fadeval / .36
    inst.AnimState:OverrideMultColour(k, k, k, k)
    if inst._fadeval <= 0 then
        inst._fadetask:Cancel()
        inst._fadetask = nil
    end
end

local function OnMasterFadeUpdate(inst)
    OnClientFadeUpdate(inst)
    inst.DynamicShadow:Enable(inst._fadeval <= .8)
    inst._fade:set_local(math.floor(7 * inst._fadeval + .5))
    if inst._fadetask == nil then
        inst:RemoveTag("NOCLICK")
    end
end

local function OnFadeDirty(inst)
    if inst._fadetask == nil then
        inst._fadeval = inst._fade:value() / 7
        inst._fadetask = inst:DoPeriodicTask(FRAMES, OnClientFadeUpdate)
        OnClientFadeUpdate(inst)
    end
end

local function FadeIn(inst)
    inst._fadeval = 1
    if inst._fadetask == nil then
        inst._fadetask = inst:DoPeriodicTask(FRAMES, OnMasterFadeUpdate)
        inst:AddTag("NOCLICK")
    end
    OnMasterFadeUpdate(inst)
end

-------------------------------------------------------------------------------

local function MakeCritter(name, animdata, face, diet, flying, data)
    local assets = {}
    for _,v in pairs(animdata.assets) do
        table.insert(assets, Asset("ANIM", "anim/"..v..".zip"))
    end

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

        inst.AnimState:SetBank(animdata.bank)
        inst.AnimState:SetBuild(animdata.build)
        inst.AnimState:PlayAnimation("idle_loop")

        if flying then
            --We want to collide with players
            --MakeFlyingCharacterPhysics(inst, 1, .5)
            inst.entity:AddPhysics()
            inst.Physics:SetMass(1)
            inst.Physics:SetCapsule(.5, 1)
            inst.Physics:SetFriction(0)
            inst.Physics:SetDamping(5)
            inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
            inst.Physics:ClearCollisionMask()
            inst.Physics:CollidesWith(COLLISION.WORLD)
            inst.Physics:CollidesWith(COLLISION.FLYERS)
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

        inst._fade = net_tinybyte(inst.GUID, "critters._fade", "fadedirty")

        if data ~= nil and data.flyingsoundloop ~= nil then
            inst.SoundEmitter:PlaySound(data.flyingsoundloop, "flying")
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            inst:ListenForEvent("fadedirty", OnFadeDirty)

            return inst
        end

        inst.GetPeepChance = GetPeepChance
        inst.AvoidCombatCheck = AvoidCombatCheck
        inst.IsAffectionate = IsAffectionate

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
        inst.components.locomotor:EnableGroundSpeedMultiplier(not flying)
        inst.components.locomotor:SetTriggersCreep(false)
        inst.components.locomotor.softstop = true
        inst.components.locomotor.walkspeed = TUNING.CRITTER_WALK_SPEED

        inst:AddComponent("crittertraits")

        inst:SetBrain(brain)
        inst:SetStateGraph("SG"..name)

        --MakeMediumFreezableCharacter(inst, "critters_body")
        --MakeHauntablePanic(inst)

        inst.FadeIn = FadeIn
        inst.OnSave = OnSave
        inst.OnLoad = OnLoad

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
    builder.components.petleash:SpawnPetAt(pt.x, 0, pt.z, inst.pettype, inst.skin_name)
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

return MakeCritter("critter_lamb", {bank="sheepington", build="sheepington_build", assets={"sheepington_build", "sheepington_basic", "sheepington_emotes"}}, 6, standard_diet, false),
       MakeBuilder("critter_lamb"),
       MakeCritter("critter_puppy", {bank="pupington", build="pupington_build", assets={"pupington_build", "pupington_basic", "pupington_emotes"}}, 4, standard_diet, false),
       MakeBuilder("critter_puppy"),
       MakeCritter("critter_kitten", {bank="kittington", build="kittington_build", assets={"kittington_build", "kittington_basic", "kittington_emotes"}}, 6, standard_diet, false),
       MakeBuilder("critter_kitten"),
       MakeCritter("critter_dragonling", {bank="dragonling", build="dragonling_build", assets={"dragonling_build", "dragonling_basic", "dragonling_emotes"}}, 6, standard_diet, true, { flyingsoundloop = "dontstarve_DLC001/creatures/together/dragonling/fly_LP" }),
       MakeBuilder("critter_dragonling"),
       MakeCritter("critter_glomling", {bank="glomling", build="glomling_build", assets={"glomling_build", "glomling_basic", "glomling_emotes"}}, 6, standard_diet, true, { flyingsoundloop = "dontstarve_DLC001/creatures/together/glomling/flap_LP" }),
       MakeBuilder("critter_glomling")
