local assets =
{
    Asset("ANIM", "anim/ds_pig_basic.zip"),
    Asset("ANIM", "anim/ds_pig_actions.zip"),
    Asset("ANIM", "anim/ds_pig_attacks.zip"),
    Asset("ANIM", "anim/pig_build.zip"),
    Asset("ANIM", "anim/pigspotted_build.zip"),
    Asset("ANIM", "anim/pig_guard_build.zip"),
    Asset("ANIM", "anim/werepig_build.zip"),
    Asset("ANIM", "anim/werepig_basic.zip"),
    Asset("ANIM", "anim/werepig_actions.zip"),
    Asset("SOUND", "sound/pig.fsb"),
}

local prefabs =
{
    "meat",
    "monstermeat",
    "poop",
    "tophat",
    "strawhat",
    "pigskin",
}

local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 30

local function ontalk(inst, script)
    inst.SoundEmitter:PlaySound("dontstarve/pig/grunt")
end

local function CalcSanityAura(inst, observer)
    if inst.components.werebeast
       and inst.components.werebeast:IsInWereState() then
        return -TUNING.SANITYAURA_LARGE
    end

    if inst.components.follower and inst.components.follower.leader == observer then
        return TUNING.SANITYAURA_SMALL
    end

    return 0
end

local function ShouldAcceptItem(inst, item)
    if inst.components.sleeper:IsAsleep() then
        return false
    end

    if item.components.equippable and item.components.equippable.equipslot == EQUIPSLOTS.HEAD then
        return true
    end
    if item.components.edible then
        
        if (item.components.edible.foodtype == FOODTYPE.MEAT or item.components.edible.foodtype == FOODTYPE.HORRIBLE)
           and inst.components.follower.leader
           and inst.components.follower:GetLoyaltyPercent() > 0.9 then
            return false
        end

        if item.components.edible.foodtype == FOODTYPE.VEGGIE or item.components.edible.foodtype == FOODTYPE.RAW then
            local last_eat_time = inst.components.eater:TimeSinceLastEating()
            if last_eat_time and last_eat_time < TUNING.PIG_MIN_POOP_PERIOD then        
                return false
            end

            if inst.components.inventory:Has(item.prefab, 1) then
                return false
            end
        end

        return true
    end
end

local function OnGetItemFromPlayer(inst, giver, item)
    --I eat food
    if item.components.edible then
        --meat makes us friends (unless I'm a guard)
        if item.components.edible.foodtype == FOODTYPE.MEAT or item.components.edible.foodtype == FOODTYPE.HORRIBLE then
            if inst.components.combat.target and inst.components.combat.target == giver then
                inst.components.combat:SetTarget(nil)
            elseif giver.components.leader and not inst:HasTag("guard") then
                inst.SoundEmitter:PlaySound("dontstarve/common/makeFriend")
                giver.components.leader:AddFollower(inst)
                inst.components.follower:AddLoyaltyTime(item.components.edible:GetHunger() * TUNING.PIG_LOYALTY_PER_HUNGER)
            end
        end
        if inst.components.sleeper:IsAsleep() then
            inst.components.sleeper:WakeUp()
        end
    end

    --I wear hats
    if item.components.equippable and item.components.equippable.equipslot == EQUIPSLOTS.HEAD then
        local current = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if current then
            inst.components.inventory:DropItem(current)
        end
        
        inst.components.inventory:Equip(item)
        inst.AnimState:Show("hat")
    end
end

local function OnRefuseItem(inst, item)
    inst.sg:GoToState("refuse")
    if inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end

local function OnEat(inst, food)
    if food.components.edible ~= nil then
        if food.components.edible.foodtype == FOODTYPE.VEGGIE then
            SpawnPrefab("poop").Transform:SetPosition(inst.Transform:GetWorldPosition())
        elseif food.components.edible.foodtype == FOODTYPE.MEAT and
            inst.components.werebeast ~= nil and
            not inst.components.werebeast:IsInWereState() and
            food.components.edible:GetHealth(inst) < 0 then
            inst.components.werebeast:TriggerDelta(1)
        end
    end
end

local function OnAttackedByDecidRoot(inst, attacker)
    local fn = function(dude) return dude:HasTag("pig") and not dude:HasTag("werepig") and not dude:HasTag("guard") end

    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = nil
    if TheWorld.state.isspring then
        ents = TheSim:FindEntities(x,y,z, (SHARE_TARGET_DIST * TUNING.SPRING_COMBAT_MOD) / 2)
    else
        ents = TheSim:FindEntities(x,y,z, SHARE_TARGET_DIST / 2)
    end

    if ents then
        local num_helpers = 0
        for k,v in pairs(ents) do
            if v ~= inst and v.components.combat and not (v.components.health and v.components.health:IsDead()) and fn(v) then
                if v:PushEvent("suggest_tree_target", {tree=attacker}) then
                    num_helpers = num_helpers + 1
                end
            end
            if num_helpers >= MAX_TARGET_SHARES then
                break
            end
        end
    end
end

local function OnAttacked(inst, data)
    --print(inst, "OnAttacked")
    local attacker = data.attacker
    inst:ClearBufferedAction()

    if attacker.prefab == "deciduous_root" and attacker.owner then 
        OnAttackedByDecidRoot(inst, attacker.owner)
    elseif attacker.prefab ~= "deciduous_root" then
        inst.components.combat:SetTarget(attacker)

        if inst:HasTag("werepig") then
            inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(dude) return dude:HasTag("werepig") end, MAX_TARGET_SHARES)
        elseif inst:HasTag("guard") then
                inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(dude) return dude:HasTag("pig") and (dude:HasTag("guard") or not attacker:HasTag("pig")) end, MAX_TARGET_SHARES)
        else
            if not (attacker:HasTag("pig") and attacker:HasTag("guard") ) then
                inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(dude) return dude:HasTag("pig") and not dude:HasTag("werepig") end, MAX_TARGET_SHARES)
            end
        end
    end
end

local function OnNewTarget(inst, data)
    if inst:HasTag("werepig") then
        --print(inst, "OnNewTarget", data.target)
        inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(dude) return dude:HasTag("werepig") end, MAX_TARGET_SHARES)
    end
end

local builds = {"pig_build", "pigspotted_build"}
local guardbuilds = {"pig_guard_build"}

local function NormalRetargetFn(inst)
    return FindEntity(inst, TUNING.PIG_TARGET_DIST,
        function(guy)
            if not guy.LightWatcher or guy.LightWatcher:IsInLight() then
                return not guy.components.health:IsDead() and inst.components.combat:CanTarget(guy) and not 
                (inst.components.follower.leader ~= nil and guy:HasTag("abigail"))
            end
        end,
        {"monster", "_health"} -- see entityreplica.lua
        )
end

local function NormalKeepTargetFn(inst, target)
    --give up on dead guys, or guys in the dark, or werepigs
    return inst.components.combat:CanTarget(target)
           and (not target.LightWatcher or target.LightWatcher:IsInLight())
           and not (target.sg and target.sg:HasStateTag("transform") )
end

local function NormalShouldSleep(inst)
    if inst.components.follower and inst.components.follower.leader then
        local fire = FindEntity(inst, 6, function(ent)
            return ent.components.burnable
                   and ent.components.burnable:IsBurning()
        end, {"campfire"})
        return DefaultSleepTest(inst) and fire and (not inst.LightWatcher or inst.LightWatcher:IsInLight())
    else
        return DefaultSleepTest(inst)
    end
end

local normalbrain = require "brains/pigbrain"

local function SuggestTreeTarget(inst, data)
    if data and data.tree and inst:GetBufferedAction() ~= ACTIONS.CHOP then
        inst.tree_target = data.tree
    end
end

local function SetNormalPig(inst)
    inst:RemoveTag("werepig")
    inst:RemoveTag("guard")
    inst:SetBrain(normalbrain)
    inst:SetStateGraph("SGpig")
    inst.AnimState:SetBuild(inst.build)

    if inst.components.hauntable then 
        inst.components.hauntable.haunted = false 
        inst.components.hauntable.cooldown_on_successful_haunt = true
    end
    inst.components.werebeast:SetOnNormalFn(SetNormalPig)
    inst.components.sleeper:SetResistance(2)

    inst.components.combat:SetDefaultDamage(TUNING.PIG_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.PIG_ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(NormalKeepTargetFn)
    inst.components.locomotor.runspeed = TUNING.PIG_RUN_SPEED
    inst.components.locomotor.walkspeed = TUNING.PIG_WALK_SPEED

    inst.components.sleeper:SetSleepTest(NormalShouldSleep)
    inst.components.sleeper:SetWakeTest(DefaultWakeTest)

    inst.components.lootdropper:SetLoot({})
    inst.components.lootdropper:AddRandomLoot("meat",3)
    inst.components.lootdropper:AddRandomLoot("pigskin",1)
    inst.components.lootdropper.numrandomloot = 1

    inst.components.health:SetMaxHealth(TUNING.PIG_HEALTH)
    inst.components.combat:SetRetargetFunction(3, NormalRetargetFn)
    inst.components.combat:SetTarget(nil)
    inst:ListenForEvent("suggest_tree_target", SuggestTreeTarget)

    inst.components.trader:Enable()
    inst.components.talker:StopIgnoringAll()
end

local function GuardRetargetFn(inst)
    local home = inst.components.homeseeker and inst.components.homeseeker.home
    --defend the king, then the torch, then myself

    local defendDist = SpringCombatMod(TUNING.PIG_GUARD_DEFEND_DIST)

    local defenseTarget = FindEntity(inst, defendDist, nil,
    {"king"}
    )
    if not defenseTarget and home and inst:GetDistanceSqToInst(home) < defendDist*defendDist then
        defenseTarget = home
    end
    if not defenseTarget then
        defenseTarget = inst
    end
    local invader = FindEntity(defenseTarget or inst, SpringCombatMod(TUNING.PIG_GUARD_TARGET_DIST), nil,
    {"character"},
    {"guard"}
    )
    if not defenseTarget.happy then
        if invader
           and not (defenseTarget.components.trader and defenseTarget.components.trader:IsTryingToTradeWithMe(invader) )
           and not (inst.components.trader and inst.components.trader:IsTryingToTradeWithMe(invader) ) then
            return invader
        end
        if not TheWorld.state.isday and home and home.components.burnable and home.components.burnable:IsBurning() then
            local lightThief = FindEntity(home, home.components.burnable:GetLargestLightRadius(), function(guy)
                return guy.LightWatcher:IsInLight()
                       and not (defenseTarget.components.trader and defenseTarget.components.trader:IsTryingToTradeWithMe(guy) ) 
                       and not (inst.components.trader and inst.components.trader:IsTryingToTradeWithMe(guy) ) 
            end,
            {"player"}
            )
            if lightThief then
                return lightThief
            end
        end
    end
    return FindEntity(defenseTarget, defendDist, nil,
    {"monster"}
    )
end

local function GuardKeepTargetFn(inst, target)
    local home = inst.components.homeseeker and inst.components.homeseeker.home
    if home then
        local defendDist = SpringCombatMod(TUNING.PIG_GUARD_DEFEND_DIST)
        if not TheWorld.state.isday and home.components.burnable and home.components.burnable:IsBurning() then
            defendDist = home.components.burnable:GetLargestLightRadius()
        end
        return home:GetDistanceSqToInst(target) < defendDist*defendDist
               and home:GetDistanceSqToInst(inst) < defendDist*defendDist
    end
    return inst.components.combat:CanTarget(target)
           and not (target.sg and target.sg:HasStateTag("transform"))
end

local function GuardShouldSleep(inst)
    return false
end

local function GuardShouldWake(inst)
    return true
end

local guardbrain = require "brains/pigguardbrain"

local function SetGuardPig(inst)
    inst:RemoveTag("werepig")
    inst:AddTag("guard")
    inst:SetBrain(guardbrain)
    inst:SetStateGraph("SGpig")
    inst.AnimState:SetBuild(inst.build)

    if inst.components.hauntable then 
        inst.components.hauntable.haunted = false 
        inst.components.hauntable.cooldown_on_successful_haunt = true
    end
    inst.components.werebeast:SetOnNormalFn(SetGuardPig)
    inst.components.sleeper:SetResistance(3)

    inst.components.health:SetMaxHealth(TUNING.PIG_GUARD_HEALTH)
    inst.components.combat:SetDefaultDamage(TUNING.PIG_GUARD_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.PIG_GUARD_ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(GuardKeepTargetFn)
    inst.components.combat:SetRetargetFunction(1, GuardRetargetFn)
    inst.components.combat:SetTarget(nil)
    inst.components.locomotor.runspeed = TUNING.PIG_RUN_SPEED
    inst.components.locomotor.walkspeed = TUNING.PIG_WALK_SPEED

    inst.components.sleeper:SetSleepTest(GuardShouldSleep)
    inst.components.sleeper:SetWakeTest(GuardShouldWake)

    inst.components.lootdropper:SetLoot({})
    inst.components.lootdropper:AddRandomLoot("meat",3)
    inst.components.lootdropper:AddRandomLoot("pigskin",1)
    inst.components.lootdropper.numrandomloot = 1

    inst.components.trader:Enable()
    inst.components.talker:StopIgnoringAll()
    inst.components.follower:SetLeader(nil)
end

local function WerepigRetargetFn(inst)
    return FindEntity(inst, SpringCombatMod(TUNING.PIG_TARGET_DIST), function(guy)
        return inst.components.combat:CanTarget(guy)
               and not (guy.sg and guy.sg:HasStateTag("transform"))
    end,
    nil,
    {"werepig","alwaysblock"}
    )
end

local function WerepigKeepTargetFn(inst, target)
    return inst.components.combat:CanTarget(target)
           and not target:HasTag("werepig")
           and not (target.sg and target.sg:HasStateTag("transform") )
end

local function WerepigSleepTest(inst)
    return false
end

local function WerepigWakeTest(inst)
    return true
end

local werepigbrain = require "brains/werepigbrain"

local function SetWerePig(inst)
    inst:AddTag("werepig")
    inst:RemoveTag("guard")
    inst:SetBrain(werepigbrain)
    inst:SetStateGraph("SGwerepig")
    inst.AnimState:SetBuild("werepig_build")

    inst.components.sleeper:SetResistance(3)

    inst.components.combat:SetDefaultDamage(TUNING.WEREPIG_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.WEREPIG_ATTACK_PERIOD)
    inst.components.locomotor.runspeed = TUNING.WEREPIG_RUN_SPEED 
    inst.components.locomotor.walkspeed = TUNING.WEREPIG_WALK_SPEED 

    inst.components.sleeper:SetSleepTest(WerepigSleepTest)
    inst.components.sleeper:SetWakeTest(WerepigWakeTest)

    inst.components.lootdropper:SetLoot({"meat","meat", "pigskin"})
    inst.components.lootdropper.numrandomloot = 0

    inst.components.health:SetMaxHealth(TUNING.WEREPIG_HEALTH)
    inst.components.combat:SetTarget(nil)
    inst.components.combat:SetRetargetFunction(3, WerepigRetargetFn)
    inst.components.combat:SetKeepTargetFunction(WerepigKeepTargetFn)

    inst.components.trader:Disable()
    inst.components.follower:SetLeader(nil)
    inst.components.talker:IgnoreAll()
end

local function GetStatus(inst)
    if inst:HasTag("werepig") then
        return "WEREPIG"
    elseif inst:HasTag("guard") then
        return "GUARD"
    elseif inst.components.follower.leader ~= nil then
        return "FOLLOWER"
    end
end

local function OnSave(inst, data)
    data.build = inst.build
end

local function OnLoad(inst, data)    
    if data ~= nil then
        inst.build = data.build or builds[1]
        if not inst.components.werebeast:IsInWereState() then
            inst.AnimState:SetBuild(inst.build)
        end
    end
end

local function common()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLightWatcher()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 50, .5)

    inst.DynamicShadow:SetSize(1.5, .75)
    inst.Transform:SetFourFaced()

    inst:AddTag("character")
    inst:AddTag("pig")
    inst:AddTag("scarytoprey")
    inst.AnimState:SetBank("pigman")
    inst.AnimState:PlayAnimation("idle_loop")
    inst.AnimState:Hide("hat")

    --Sneak these into pristine state for optimization
    inst:AddTag("_named")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --Remove these tags so that they can be added properly when replicating components below
    inst:RemoveTag("_named")

    inst:AddComponent("talker")
    inst.components.talker.ontalk = ontalk
    inst.components.talker.fontsize = 35
    inst.components.talker.font = TALKINGFONT
    --inst.components.talker.colour = Vector3(133/255, 140/255, 167/255)
    inst.components.talker.offset = Vector3(0,-400,0)

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = TUNING.PIG_RUN_SPEED --5
    inst.components.locomotor.walkspeed = TUNING.PIG_WALK_SPEED --3

    ------------------------------------------
    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODGROUP.OMNI })
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater:SetCanEatRaw()
    inst.components.eater.strongstomach = true -- can eat monster meat!
    inst.components.eater:SetOnEatFn(OnEat)
    ------------------------------------------
    inst:AddComponent("health")
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "pig_torso"

    MakeMediumBurnableCharacter(inst, "pig_torso")

    inst:AddComponent("named")
    inst.components.named.possiblenames = STRINGS.PIGNAMES
    inst.components.named:PickNewName()

    ------------------------------------------
    inst:AddComponent("werebeast")
    inst.components.werebeast:SetOnWereFn(SetWerePig)
    inst.components.werebeast:SetTriggerLimit(4)

    MakeHauntablePanic(inst)
    AddHauntableCustomReaction(inst, function(inst, haunter)
        if math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
            SetWerePig(inst)
            inst:PushEvent("transformwere")
            inst.components.hauntable.cooldown_on_successful_haunt = false -- Set this to false here because we need werepigs to handle own un-haunting (will also need to unset this flag)
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_LARGE
        end
    end, true, nil, true)

    ------------------------------------------
    inst:AddComponent("follower")
    inst.components.follower.maxfollowtime = TUNING.PIG_LOYALTY_MAXTIME
    ------------------------------------------

    inst:AddComponent("inventory")

    ------------------------------------------

    inst:AddComponent("lootdropper")

    ------------------------------------------

    inst:AddComponent("knownlocations")

    ------------------------------------------

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem

    ------------------------------------------

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    ------------------------------------------

    inst:AddComponent("sleeper")

    ------------------------------------------
    MakeMediumFreezableCharacter(inst, "pig_torso")

    ------------------------------------------

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus
    ------------------------------------------

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:ListenForEvent("attacked", OnAttacked)    
    inst:ListenForEvent("newcombattarget", OnNewTarget)

    return inst
end

local function normal()
    local inst = common()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.build = builds[math.random(#builds)]
    inst.AnimState:SetBuild(inst.build)
    SetNormalPig(inst)
    return inst
end

local function guard()
    local inst = common()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.build = guardbuilds[math.random(#guardbuilds)]
    inst.AnimState:SetBuild(inst.build)
    SetGuardPig(inst)
    return inst
end

return Prefab("common/characters/pigman", normal, assets, prefabs),
    Prefab("common/character/pigguard", guard, assets, prefabs)