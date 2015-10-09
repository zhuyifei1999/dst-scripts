local assets =
{
    Asset("ANIM", "anim/manrabbit_basic.zip"),
    Asset("ANIM", "anim/manrabbit_actions.zip"),
    Asset("ANIM", "anim/manrabbit_attacks.zip"),
    Asset("ANIM", "anim/manrabbit_build.zip"),

    Asset("ANIM", "anim/manrabbit_beard_build.zip"),
    Asset("ANIM", "anim/manrabbit_beard_basic.zip"),
    Asset("ANIM", "anim/manrabbit_beard_actions.zip"),
    Asset("SOUND", "sound/bunnyman.fsb"),
}

local prefabs =
{
    "meat",
    "monstermeat",
    "manrabbit_tail",
    "beardhair",
    "carrot",
}


local beardlordloot = { "beardhair", "beardhair", "monstermeat" }
local regularloot = { "carrot", "carrot" }

local brain = require("brains/bunnymanbrain")

local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 30

local function IsCrazyGuy(guy)
    return guy ~= nil and guy.components.sanity ~= nil and guy.components.sanity:IsCrazy() and guy:HasTag("player")
end

local function ontalk(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/bunnyman/idle_med")
end

local function ClearBeardlord(inst)
    inst.clearbeardlordtask = nil
    inst.beardlord = nil
end

local function SetBeardLord(inst)
    inst.beardlord = true
    if inst.clearbeardlordtask ~= nil then
        inst.clearbeardlordtask:Cancel()
    end
    inst:DoTaskInTime(5.0, ClearBeardlord)
end

local function CalcSanityAura(inst, observer)
    if IsCrazyGuy(observer) then
        SetBeardLord(inst)
    end
    return (IsCrazyGuy(observer) and -TUNING.SANITYAURA_MED)
        or (inst.components.follower ~= nil and
            inst.components.follower.leader == observer and
            TUNING.SANITYAURA_SMALL)
        or 0
end

local function ShouldAcceptItem(inst, item)
    return
        (   --accept all hats!
            item.components.equippable ~= nil and
            item.components.equippable.equipslot == EQUIPSLOTS.HEAD
        ) or
        (   --accept food, but not too many carrots for loyalty!
            item.components.edible ~= nil and
            (   (item.prefab ~= "carrot" and item.prefab ~= "carrot_cooked") or
                inst.components.follower.leader == nil or
                inst.components.follower:GetLoyaltyPercent() <= .9
            )
        )
end

local function OnGetItemFromPlayer(inst, giver, item)
    --I eat food
    if item.components.edible ~= nil then
        if item.prefab == "carrot" or item.prefab == "carrot_cooked" then
            if inst.components.combat:TargetIs(giver) then
                inst.components.combat:SetTarget(nil)
            elseif giver.components.leader ~= nil then
                inst.SoundEmitter:PlaySound("dontstarve/common/makeFriend")
                giver.components.leader:AddFollower(inst)
                inst.components.follower:AddLoyaltyTime(
                    giver:HasTag("polite")
                    and TUNING.RABBIT_CARROT_LOYALTY + TUNING.RABBIT_POLITENESS_LOYALTY_BONUS
                    or TUNING.RABBIT_CARROT_LOYALTY
                )
            end
        end
        if inst.components.sleeper:IsAsleep() then
            inst.components.sleeper:WakeUp()
        end
    end

    --I wear hats
    if item.components.equippable ~= nil and item.components.equippable.equipslot == EQUIPSLOTS.HEAD then
        local current = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if current ~= nil then
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

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST, function(dude) return dude.prefab == inst.prefab end, MAX_TARGET_SHARES)
end

local function OnNewTarget(inst, data)
    inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(dude) return dude.prefab == inst.prefab end, MAX_TARGET_SHARES)
end

local function is_meat(item)
    return item.components.edible ~= nil  and item.components.edible.foodtype == FOODTYPE.MEAT
end

local function NormalRetargetFn(inst)
    return FindEntity(inst, TUNING.PIG_TARGET_DIST,
        function(guy)
            return inst.components.combat:CanTarget(guy)
                and (guy:HasTag("monster")
                    or (guy.components.inventory ~= nil and
                        guy:IsNear(inst, TUNING.BUNNYMAN_SEE_MEAT_DIST) and
                        guy.components.inventory:FindItem(is_meat) ~= nil))
        end,
        { "_combat", "_health" }, -- see entityreplica.lua
        nil,
        { "monster", "player" })
end

local function NormalKeepTargetFn(inst, target)
    return not (target.sg ~= nil and target.sg:HasStateTag("hiding")) and inst.components.combat:CanTarget(target)
end

local function giveupstring()
    return STRINGS.RABBIT_GIVEUP[math.random(#STRINGS.RABBIT_GIVEUP)]
end

local function battlecry(combatcmp, target)
    return target ~= nil
        and target.components.inventory ~= nil
        and target.components.inventory:FindItem(is_meat) ~= nil
        and STRINGS.RABBIT_MEAT_BATTLECRY[math.random(#STRINGS.RABBIT_MEAT_BATTLECRY)]
        or STRINGS.RABBIT_BATTLECRY[math.random(#STRINGS.RABBIT_BATTLECRY)]
end

local function GetStatus(inst)
    return inst.components.follower.leader ~= nil and "FOLLOWER" or nil
end

local function LootSetupFunction(lootdropper)
    local guy = lootdropper.inst.causeofdeath
    if IsCrazyGuy(guy ~= nil and guy.components.follower ~= nil and guy.components.follower.leader or guy) then
        -- beard lord
        lootdropper:SetLoot(beardlordloot)
    else
        -- regular loot
        lootdropper:SetLoot(regularloot)
        lootdropper:AddRandomLoot("meat", 3)
        lootdropper:AddRandomLoot("manrabbit_tail", 1)
        lootdropper.numrandomloot = 1
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLightWatcher()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("manrabbit_build")

    MakeCharacterPhysics(inst, 50, .5)

    inst.DynamicShadow:SetSize(1.5, .75)
    inst.Transform:SetFourFaced()
    local s = 1.25
    inst.Transform:SetScale(s, s, s)

    inst:AddTag("cavedweller")
    inst:AddTag("character")
    inst:AddTag("pig")
    inst:AddTag("manrabbit")
    inst:AddTag("scarytoprey")

    inst.AnimState:SetBank("manrabbit")
    inst.AnimState:PlayAnimation("idle_loop")
    inst.AnimState:Hide("hat")

    inst.AnimState:SetClientsideBuildOverride("insane", "manrabbit_build", "manrabbit_beard_build")

    --trader (from trader component) added to pristine state for optimization
    inst:AddTag("trader")

    --Sneak these into pristine state for optimization
    inst:AddTag("_named")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --Remove these tags so that they can be added properly when replicating components below
    inst:RemoveTag("_named")

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = TUNING.PIG_RUN_SPEED * 2.2 -- account for them being stopped for part of their anim
    inst.components.locomotor.walkspeed = TUNING.PIG_WALK_SPEED * 1.9 -- account for them being stopped for part of their anim

    ------------------------------------------
    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.VEGGIE }, { FOODTYPE.VEGGIE })
    inst.components.eater:SetCanEatRaw()

    ------------------------------------------
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "manrabbit_torso"
    inst.components.combat.panic_thresh = TUNING.BUNNYMAN_PANIC_THRESH

    inst.components.combat.GetBattleCryString = battlecry
    inst.components.combat.GetGiveUpString = giveupstring

    MakeMediumBurnableCharacter(inst, "manrabbit_torso")

    inst:AddComponent("named")
    inst.components.named.possiblenames = STRINGS.BUNNYMANNAMES
    inst.components.named:PickNewName()

    ------------------------------------------
    inst:AddComponent("follower")
    inst.components.follower.maxfollowtime = TUNING.PIG_LOYALTY_MAXTIME
    ------------------------------------------
    inst:AddComponent("health")
    inst.components.health:StartRegen(TUNING.BUNNYMAN_HEALTH_REGEN_AMOUNT, TUNING.BUNNYMAN_HEALTH_REGEN_PERIOD)

    ------------------------------------------

    inst:AddComponent("inventory")

    ------------------------------------------

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLootSetupFn(LootSetupFunction)
    LootSetupFunction(inst.components.lootdropper)

    ------------------------------------------

    inst:AddComponent("knownlocations")
    inst:AddComponent("talker")
    inst.components.talker.ontalk = ontalk
    inst.components.talker.fontsize = 24
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.offset = Vector3(0, -500, 0)

    ------------------------------------------

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem
    inst.components.trader.deleteitemonaccept = false

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

    inst:ListenForEvent("attacked", OnAttacked)    
    inst:ListenForEvent("newcombattarget", OnNewTarget)

    inst.components.sleeper:SetResistance(2)
    inst.components.sleeper.sleeptestfn = NocturnalSleepTest
    inst.components.sleeper.waketestfn = NocturnalWakeTest

    inst.components.combat:SetDefaultDamage(TUNING.BUNNYMAN_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.BUNNYMAN_ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(NormalKeepTargetFn)
    inst.components.combat:SetRetargetFunction(3, NormalRetargetFn)

    inst.components.locomotor.runspeed = TUNING.BUNNYMAN_RUN_SPEED
    inst.components.locomotor.walkspeed = TUNING.BUNNYMAN_WALK_SPEED

    inst.components.health:SetMaxHealth(TUNING.BUNNYMAN_HEALTH)

    inst.components.trader:Enable()

    MakeHauntablePanic(inst, 5, nil, 5)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGbunnyman")

    return inst
end

return Prefab("bunnyman", fn, assets, prefabs)
