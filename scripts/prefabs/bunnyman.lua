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
}

local brain = require "brains/bunnymanbrain"

local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 30

local function ontalk(inst, script)
	inst.SoundEmitter:PlaySound("dontstarve/creatures/bunnyman/idle_med")
	--inst.SoundEmitter:PlaySound("dontstarve/pig/grunt")
end

local function CalcSanityAura(inst, observer)

	if inst.beardlord then
        return -TUNING.SANITYAURA_MED
    end
    
    if inst.components.follower and inst.components.follower.leader == observer then
		return TUNING.SANITYAURA_SMALL
	end
	
	return 0
end

local function ShouldAcceptItem(inst, item)
    if item.components.equippable and item.components.equippable.equipslot == EQUIPSLOTS.HEAD then
        return true
    end
    if item.components.edible then
        
        if (item.prefab == "carrot" or item.prefab == "carrot_cooked")
           and inst.components.follower.leader
           and inst.components.follower:GetLoyaltyPercent() > 0.9 then
            return false
        end
        
        return true
    end
end

local function OnGetItemFromPlayer(inst, giver, item)
    
    --I eat food
    if item.components.edible then
        if (item.prefab == "carrot" or item.prefab == "carrot_cooked") then
            if inst.components.combat.target and inst.components.combat.target == giver then
                inst.components.combat:SetTarget(nil)
            elseif giver.components.leader then
				inst.SoundEmitter:PlaySound("dontstarve/common/makeFriend")
				giver.components.leader:AddFollower(inst)
                inst.components.follower:AddLoyaltyTime(TUNING.RABBIT_CARROT_LOYALTY)
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

local function OnAttacked(inst, data)
    --print(inst, "OnAttacked")
    local attacker = data.attacker
    inst.components.combat:SetTarget(attacker)
    inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(dude) return dude.prefab == inst.prefab end, MAX_TARGET_SHARES)
end

local function OnNewTarget(inst, data)
    inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(dude) return dude.prefab == inst.prefab end, MAX_TARGET_SHARES)
end

local function is_meat(item)
	return item.components.edible and item.components.edible.foodtype == FOODTYPE.MEAT
end

local function NormalRetargetFn(inst)
    
    return FindEntity(inst, TUNING.PIG_TARGET_DIST,
        function(guy)
            if not guy.components.health:IsDead() and inst.components.combat:CanTarget(guy) then
                if guy:HasTag("monster") then return guy end
                if guy:HasTag("player") and guy.components.inventory and guy:GetDistanceSqToInst(inst) < TUNING.BUNNYMAN_SEE_MEAT_DIST*TUNING.BUNNYMAN_SEE_MEAT_DIST and guy.components.inventory:FindItem(is_meat ) then return guy end
            end
        end,
        {"_health"}, -- see entityreplica.lua
        nil,
        {"monster","player"}
        )
end

local function NormalKeepTargetFn(inst, target)
    
    return inst.components.combat:CanTarget(target) and not (target.sg and target.sg:HasStateTag("hiding")) 
end

local function giveupstring(combatcmp, target)
    return STRINGS.RABBIT_GIVEUP[math.random(#STRINGS.RABBIT_GIVEUP)]
end

local function battlecry(combatcmp, target)
    
    if target and target.components.inventory then
    

        local item = target.components.inventory:FindItem(function(item) return item.components.edible and item.components.edible.foodtype == FOODTYPE.MEAT end )
        if item then
            return STRINGS.RABBIT_MEAT_BATTLECRY[math.random(#STRINGS.RABBIT_MEAT_BATTLECRY)]
        end
    end
    return STRINGS.RABBIT_BATTLECRY[math.random(#STRINGS.RABBIT_BATTLECRY)]
end

local function SetBeardlord(inst)
	if not inst.beardlord then
		inst.beardlord = true

		-- KAJ: DISABLED, this is different behaviour on client and server
		--[[
        inst.components.combat:SetDefaultDamage(TUNING.BEARDLORD_DAMAGE)
        inst.components.combat:SetAttackPeriod(TUNING.BEARDLORD_ATTACK_PERIOD)
        inst.components.combat.panic_thresh = TUNING.BEARDLORD_PANIC_THRESH
		]]

		-- KAJ: DISABLED, this is different behaviour on client and server
		--[[
        inst.components.sleeper:SetSleepTest(function() return false end)
        inst.components.sleeper:SetWakeTest(function() return true end)
		]]
	end
end

local function SetNormalRabbit(inst)
	if inst.beardlord or inst.beardlord == nil then
		inst.beardlord = false
        if inst.components.hauntable then 
            inst.components.hauntable.haunted = false 
        end
        
  
		-- TODO: Not sure what to do with this. It`s different depending on who sees it
		-- KAJ: DISABLED, this is different behaviour on client and server
		--[[
        inst.components.combat:SetDefaultDamage(TUNING.BUNNYMAN_DAMAGE)
        inst.components.combat:SetAttackPeriod(TUNING.BUNNYMAN_ATTACK_PERIOD)
        inst.components.combat.panic_thresh = TUNING.BUNNYMAN_PANIC_THRESH
		]]
		-- KAJ: DISABLED, this is different behaviour on client and server
		--[[
        inst.components.sleeper:SetDefaultTests()
		]]
	end
	
end

local function GetStatus(inst)
    if inst.components.follower.leader ~= nil then
        return "FOLLOWER"
    end
end

local function LootSetupFunction(self)
	local sane = true
	-- were we killed by an insane player?
	if self.inst.causeofdeath and self.inst.causeofdeath:HasTag("player") then
		if self.inst.causeofdeath.components.sanity ~= nil and self.inst.causeofdeath.components.sanity:IsCrazy() then
			sane = false
		end
	end
	if not sane then
		-- beard lord
        self.inst.components.lootdropper:SetLoot({"beardhair", "beardhair", "monstermeat"})
	else
		-- regular loot
        self.inst.components.lootdropper:SetLoot({"carrot","carrot"})
        self.inst.components.lootdropper:AddRandomLoot("meat",3)
        self.inst.components.lootdropper:AddRandomLoot("manrabbit_tail",1)
        self.inst.components.lootdropper.numrandomloot = 1
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
    inst.Transform:SetScale(s,s,s)

    inst:AddTag("character")
    inst:AddTag("pig")
    inst:AddTag("manrabbit")
    inst:AddTag("scarytoprey")

    inst.AnimState:SetBank("manrabbit")
    inst.AnimState:PlayAnimation("idle_loop")
    inst.AnimState:Hide("hat")

    inst.AnimState:SetClientsideBuildOverride("insane", "manrabbit_build", "manrabbit_beard_build")

    --Sneak these into pristine state for optimization
    inst:AddTag("_named")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --Remove these tags so that they can be added properly when replicating components below
    inst:RemoveTag("_named")

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = TUNING.PIG_RUN_SPEED --5
    inst.components.locomotor.walkspeed = TUNING.PIG_WALK_SPEED --3

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

    ------------------------------------------

    inst:AddComponent("knownlocations")
    inst:AddComponent("talker")
    inst.components.talker.ontalk = ontalk
    inst.components.talker.fontsize = 24
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.offset = Vector3(0,-500,0)

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
    
    inst:ListenForEvent("attacked", OnAttacked)    
    inst:ListenForEvent("newcombattarget", OnNewTarget)

    --inst.components.werebeast:SetOnWereFn(SetBeardlord)
    --inst.components.werebeast:SetOnNormaleFn(SetNormalRabbit)

    inst.components.sleeper:SetResistance(2)
    inst.components.sleeper.nocturnal = true

    inst.components.combat:SetDefaultDamage(TUNING.BUNNYMAN_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.BUNNYMAN_ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(NormalKeepTargetFn)
    inst.components.combat:SetRetargetFunction(3, NormalRetargetFn)

    inst.components.locomotor.runspeed = TUNING.BUNNYMAN_RUN_SPEED
    inst.components.locomotor.walkspeed = TUNING.BUNNYMAN_WALK_SPEED

    inst.components.lootdropper:SetLoot({"carrot","carrot"})
    inst.components.lootdropper:AddRandomLoot("meat",3)
    inst.components.lootdropper:AddRandomLoot("manrabbit_tail",1)
    inst.components.lootdropper.numrandomloot = 1

    inst.components.health:SetMaxHealth(TUNING.BUNNYMAN_HEALTH)

    inst.components.trader:Enable()
    --inst.Label:Enable(true)
    --inst.components.talker:StopIgnoringAll()

    MakeHauntablePanic(inst, 5, nil, 5)
    -- AddHauntableCustomReaction(inst, function(inst, haunter)
    --     if math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
    --         SetBeardlord(inst)
    --         inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
    --         if inst.checktask then
    --             inst.checktask:Cancel()
    --             inst.checktask = nil
    --         end
    --     end
    -- end, true, nil, true)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGbunnyman")

    return inst
end

return Prefab("common/characters/bunnyman", fn, assets, prefabs)