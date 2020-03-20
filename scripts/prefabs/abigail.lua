local assets =
{
    Asset("ANIM", "anim/player_ghost_withhat.zip"),
    Asset("ANIM", "anim/ghost_abigail_build.zip"),
    Asset("ANIM", "anim/ghost_abigail.zip"),
    Asset("SOUND", "sound/ghost.fsb"),
}

local prefabs = 
{
    "abigail_attack_fx",
    "abigail_attack_fx_ground",
	"abigail_retaliation",
	"abigailforcefield",
	"abigaillevelupfx",
}

local brain = require("brains/abigailbrain")

local function UpdateGhostlyBondLevel(inst, level)
	local max_health = level == 3 and TUNING.ABIGAIL_HEALTH_LEVEL3
					or level == 2 and TUNING.ABIGAIL_HEALTH_LEVEL2
					or TUNING.ABIGAIL_HEALTH_LEVEL1

	local health_comp = inst.components.health
	if health_comp ~= nil then
		if health_comp:IsDead() then
			health_comp.maxhealth = max_health
		else
			local health_percent = health_comp:GetPercent()
			health_comp:SetMaxHealth(max_health)
			health_comp:SetPercent(health_percent, true)
		end

	    if inst._playerlink ~= nil and inst._playerlink.components.pethealthbar ~= nil then
	        inst._playerlink.components.pethealthbar:SetMaxHealth(max_health)
		end
	end

	local light_vals = TUNING.ABIGAIL_LIGHTING[level] or TUNING.ABIGAIL_LIGHTING[1]
	if light_vals.r ~= 0 then
		inst.Light:Enable(not inst.inlimbo)
		inst.Light:SetRadius(light_vals.r)
		inst.Light:SetIntensity(light_vals.i)
		inst.Light:SetFalloff(light_vals.f)
	else
		inst.Light:Enable(false)
	end
    inst.AnimState:SetLightOverride(light_vals.l)
end

local ABIGAIL_DEFENSIVE_MAX_FOLLOW_DSQ = TUNING.ABIGAIL_DEFENSIVE_MAX_FOLLOW * TUNING.ABIGAIL_DEFENSIVE_MAX_FOLLOW
local function IsWithinDefensiveRange(inst)
    return inst._playerlink and inst:GetDistanceSqToInst(inst._playerlink) < ABIGAIL_DEFENSIVE_MAX_FOLLOW_DSQ
end

local COMBAT_MUSHAVE_TAGS = { "_combat", "_health" }
local COMBAT_CANTHAVE_TAGS = { "INLIMBO", "noauradamage" }
local COMBAT_MUSTONEOF_TAGS = { "monster", "prey" }

local COMBAT_TARGET_DSQ = TUNING.ABIGAIL_COMBAT_TARGET_DISTANCE * TUNING.ABIGAIL_COMBAT_TARGET_DISTANCE

local function HasFriendlyLeader(inst, target)

    local leader = inst.components.follower.leader
    if leader ~= nil then
        local target_leader = (target.components.follower ~= nil) and target.components.follower.leader or nil

        if target_leader and target_leader.components.inventoryitem then
            target_leader = target_leader.components.inventoryitem:GetGrandOwner()
            -- Don't attack followers if their follow object has no owner
            if target_leader == nil then
                return true
            end
        end

        return leader == target or (target_leader ~= nil 
                and (target_leader == leader or (target_leader:HasTag("player") 
                and not TheNet:GetPVPEnabled()))) or
                (target.components.domesticatable and target.components.domesticatable:IsDomesticated() 
                and not TheNet:GetPVPEnabled())
    end

    return false    
end

local function CommonRetarget(inst, v)
    return v ~= inst and v ~= inst._playerlink and v.entity:IsVisible()
            and v:GetDistanceSqToInst(inst._playerlink) < COMBAT_TARGET_DSQ
            and inst.components.combat:CanTarget(v)
            and v.components.minigame_participator == nil
            and not HasFriendlyLeader(inst, v)

end

local function DefensiveRetarget(inst)

    if inst._playerlink == nil then
        return nil
    elseif not IsWithinDefensiveRange(inst) then
        return nil
    else
        local ix, iy, iz = inst.Transform:GetWorldPosition()
        local entities_near_me = TheSim:FindEntities(
            ix, iy, iz, TUNING.ABIGAIL_DEFENSIVE_MAX_FOLLOW,
            COMBAT_MUSHAVE_TAGS, COMBAT_CANTHAVE_TAGS, COMBAT_MUSTONEOF_TAGS
        )

        local leader = inst.components.follower.leader
        
        for _, v in ipairs(entities_near_me) do
            if CommonRetarget(inst, v)
                    and (v.components.combat.target == inst._playerlink or
                        inst._playerlink.components.combat.target == v or
                        v.components.combat.target == inst) then

                return v
            end
        end

        return nil
    end
end

local function AggressiveRetarget(inst)

    if inst._playerlink == nil then
        return nil
    else
        local ix, iy, iz = inst.Transform:GetWorldPosition()
        local entities_near_me = TheSim:FindEntities(
            ix, iy, iz, TUNING.ABIGAIL_COMBAT_TARGET_DISTANCE,
            COMBAT_MUSHAVE_TAGS, COMBAT_CANTHAVE_TAGS, COMBAT_MUSTONEOF_TAGS
        )

        local leader = inst.components.follower.leader

        for _, v in ipairs(entities_near_me) do
            if CommonRetarget(inst, v) then
                return v
            end
        end

        return nil
    end
end

local function StartForceField(inst)
	if not inst.sg:HasStateTag("dissipate") and not inst.components.debuffable:HasDebuff("forcefield") and (inst.components.health == nil or not inst.components.health:IsDead()) then
		local elixir_buff = inst.components.debuffable:GetDebuff("elixir_buff")
		inst.components.debuffable:AddDebuff("forcefield", elixir_buff ~= nil and elixir_buff.potion_tunings.shield_prefab or "abigailforcefield")
	end
end

local function OnAttacked(inst, data)
--    print("onattack", data.attacker, data.damage, data.damageresolved)

    if data.attacker == nil then
        inst.components.combat:SetTarget(nil)
    elseif data.attacker == inst._playerlink then
        inst.components.health:Kill()
    elseif not data.attacker:HasTag("noauradamage") then
        if not inst.is_defensive then
            inst.components.combat:SetTarget(data.attacker)
        elseif inst:IsWithinDefensiveRange() and
                inst._playerlink:GetDistanceSqToInst(data.attacker) < ABIGAIL_DEFENSIVE_MAX_FOLLOW_DSQ then
            -- Basically, we avoid targetting the attacker if they're far enough away that we wouldn't reach them anyway.
            inst.components.combat:SetTarget(data.attacker)
        end
    end

	if inst.components.debuffable:HasDebuff("forcefield") then
		if data.attacker ~= nil and data.attacker ~= inst._playerlink and data.attacker.components.combat ~= nil then
			local elixir_buff = inst.components.debuffable:GetDebuff("elixir_buff")
			if elixir_buff ~= nil and elixir_buff.prefab == "ghostlyelixir_retaliation_buff" then
				local retaliation = SpawnPrefab("abigail_retaliation")
				retaliation:SetRetaliationTarget(data.attacker)
				inst.SoundEmitter:PlaySound("dontstarve/characters/wendy/abigail/shield/on")
			else
				inst.SoundEmitter:PlaySound("dontstarve/characters/wendy/abigail/shield/on")
			end
		end
    end

    StartForceField(inst)
end

local function OnDeath(inst)
    inst.components.aura:Enable(false)
	inst.components.debuffable:RemoveDebuff("ghostlyelixir")
	inst.components.debuffable:RemoveDebuff("forcefield")
end

local function OnRemoved(inst)
    inst:BecomeDefensive()
end

local function auratest(inst, target)
    if target == inst._playerlink then
        return false
    end

	if target.components.minigame_participator ~= nil then
		return false
	end

    if (target:HasTag("player") and not TheNet:GetPVPEnabled()) or target:HasTag("ghost") or target:HasTag("noauradamage") then
        return false
    end

    local leader = inst.components.follower.leader
    if leader ~= nil
        and (leader == target
            or (target.components.follower ~= nil and
                target.components.follower.leader == leader)) then
        return false
    end

    if inst.is_defensive and not IsWithinDefensiveRange(inst) then
        return false
    end

    if inst.components.combat.target == target then
        return true
    end

    if target.components.combat.target ~= nil
        and (target.components.combat.target == inst or
            target.components.combat.target == leader) then
        return true
    end

    return target:HasTag("monster") or target:HasTag("prey")
end

local function RecalculateDamage(inst)
    local enemy_count = 0
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, inst.components.aura.radius, { "_combat" }, inst.components.aura.auraexcludetags)
    for i, ent in ipairs(ents) do
        if ent ~= inst and auratest(inst, ent) then
            enemy_count = enemy_count + 1
            if enemy_count >= #TUNING.ABIGAIL_DAMAGE_PER_CREATURE then
                break
            end
        end
    end

    local damage = TUNING.ABIGAIL_DAMAGE_PER_CREATURE[math.clamp(enemy_count, 1, #TUNING.ABIGAIL_DAMAGE_PER_CREATURE)]
    local bonus_percent = (inst._playerlink ~= nil and inst._playerlink.components.health ~= nil) and (1 - inst._playerlink.components.health:GetPercentWithPenalty()) or 0
	bonus_percent = bonus_percent * bonus_percent

	damage = damage + (TUNING.ABIGAIL_DAMAGE_WENDY_HEALTH_BASE * bonus_percent)
    local buff = inst.components.debuffable:GetDebuff("elixir_buff")
    if buff ~= nil and buff.prefab == "ghostlyelixir_attack" then
        damage = damage * TUNING.GHOSTLYELIXIR_DAMAGE_MULT
    end
    inst.components.combat.defaultdamage = damage

    if inst.SoundEmitter:PlayingSound("angry") then
        inst.SoundEmitter:SetParameter("angry", "intensity", bonus_percent)
    end

    -- Changes the animation FX
    inst.attack_level = bonus_percent > 0.8 and 3
                        or bonus_percent > 0.5 and 2
                        or 1

    -- If the animation fx was already playing we update its animation
    local level_str = tostring(inst.attack_level)
    if inst.attack_fx and not inst.attack_fx.AnimState:IsCurrentAnimation("attack" .. level_str .. "_loop") then
        inst.attack_fx.AnimState:PlayAnimation("attack" .. level_str .. "_loop", true)
    end

    if inst.attack_fx_ground and not inst.attack_fx_ground.AnimState:IsCurrentAnimation("attack" .. level_str .. "_ground_loop") then
        inst.attack_fx_ground.AnimState:PlayAnimation("attack" .. level_str .. "_ground_loop", true)
    end
end

local function AbigailHealthDelta(inst, data)
	if inst._playerlink ~= nil then
		if data.oldpercent > data.newpercent and data.newpercent <= 0.25 and not inst.issued_health_warning then
			inst._playerlink.components.talker:Say(GetString(inst._playerlink, "ANNOUNCE_ABIGAIL_LOW_HEALTH"))
			inst.issued_health_warning = true
		elseif data.oldpercent < data.newpercent and data.newpercent > 0.33 then
			inst.issued_health_warning = false
		end
	end
end

local function DoAppear(sg)
	sg:GoToState("appear")
end

local function AbleToAcceptTest(inst, item)
    return false, item.prefab == "reviver" and "ABIGAILHEART" or nil
end

local function OnDebuffAdded(inst, name, debuff)
    if inst._playerlink ~= nil and inst._playerlink.components.pethealthbar ~= nil and name == "elixir_buff" then
        inst._playerlink.components.pethealthbar:SetSymbol(debuff.prefab)
    end
end

local function OnDebuffRemoved(inst, name, debuff)
    if inst._playerlink ~= nil and inst._playerlink.components.pethealthbar ~= nil and name == "elixir_buff" then
		inst._playerlink.components.pethealthbar:SetSymbol(0)
	end
end

local function on_ghostlybond_level_change(inst, player, data)
	if not inst.inlimbo and data.level > 1 and not inst.sg:HasStateTag("busy") and (inst.components.health == nil or not inst.components.health:IsDead()) then
		inst.sg:GoToState("ghostlybond_levelup", {level = data.level})
	end

	UpdateGhostlyBondLevel(inst, data.level)
end

local function BecomeAggressive(inst)
    inst.AnimState:OverrideSymbol("ghost_eyes", "ghost_abigail_build", "angry_ghost_eyes")
    inst.is_defensive = false
    inst._playerlink:AddTag("has_aggressive_follower")
    inst.components.combat:SetRetargetFunction(0.5, AggressiveRetarget)
end

local function BecomeDefensive(inst)
    inst.AnimState:ClearOverrideSymbol("ghost_eyes")
    inst.is_defensive = true
    inst._playerlink:RemoveTag("has_aggressive_follower")
    inst.components.combat:SetRetargetFunction(0.5, DefensiveRetarget)
end

local function onlostplayerlink(inst)
	inst._playerlink = nil
end

local function linktoplayer(inst, player)
    inst.persists = false
    inst._playerlink = player

    BecomeDefensive(inst)

    inst:ListenForEvent("healthdelta", AbigailHealthDelta)

    player.components.leader:AddFollower(inst)
    if player.components.pethealthbar ~= nil then
        player.components.pethealthbar:SetPet(inst, "", TUNING.ABIGAIL_HEALTH_LEVEL1)

        local elixir_buff = inst.components.debuffable ~= nil and inst.components.debuffable:GetDebuff("elixir_buff") or nil
        if elixir_buff then
            player.components.pethealthbar:SetSymbol(elixir_buff.prefab)
        end
    end

    UpdateGhostlyBondLevel(inst, player.components.ghostlybond.bondlevel)
    inst:ListenForEvent("ghostlybond_level_change", inst._on_ghostlybond_level_change, player)
    inst:ListenForEvent("onremove", inst._onlostplayerlink, player)

    player.components.sanity:DoDelta(TUNING.SANITY_MED)
end

local function OnExitLimbo(inst)
	local level = (inst._playerlink ~= nil and inst._playerlink.components.ghostlybond ~= nil) and inst._playerlink.components.ghostlybond.bondlevel or 1
	local light_vals = TUNING.ABIGAIL_LIGHTING[level] or TUNING.ABIGAIL_LIGHTING[1]
	inst.Light:Enable(light_vals.r ~= 0)
end

local function getstatus(inst)
	local bondlevel = (inst._playerlink ~= nil and inst._playerlink.components.ghostlybond ~= nil) and inst._playerlink.components.ghostlybond.bondlevel or 0
	return bondlevel == 3 and "LEVEL3"
		or bondlevel == 2 and "LEVEL2"
		or "LEVEL1"
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("ghost")
    inst.AnimState:SetBuild("ghost_abigail_build")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim_bloom_ghost.ksh")

    inst:AddTag("character")
    inst:AddTag("scarytoprey")
    inst:AddTag("girl")
    inst:AddTag("ghost")
    inst:AddTag("noauradamage")
    inst:AddTag("notraptrigger")
    inst:AddTag("abigail")
    inst:AddTag("NOBLOCK")

    inst:AddTag("trader") --trader (from trader component) added to pristine state for optimization
	inst:AddTag("ghostlyelixirable") -- for ghostlyelixirable component

    MakeGhostPhysics(inst, 1, .5)

    inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(.5)
    inst.Light:SetFalloff(.6)
    inst.Light:Enable(false)
    inst.Light:SetColour(180 / 255, 195 / 255, 225 / 255)

    --It's a loop that's always on, so we can start this in our pristine state
    -- inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_girl_howl_LP", "howl")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst._playerlink = nil

    inst:SetBrain(brain)

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = TUNING.ABIGAIL_SPEED*.5
    inst.components.locomotor.runspeed = TUNING.ABIGAIL_SPEED
    inst.components.locomotor.pathcaps = { allowocean = true }

    inst:SetStateGraph("SGabigail")
	inst.sg.OnStart = DoAppear

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

	inst:AddComponent("debuffable")
	inst.components.debuffable.ondebuffadded = OnDebuffAdded
	inst.components.debuffable.ondebuffremoved = OnDebuffRemoved

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.ABIGAIL_HEALTH_LEVEL1)
    inst.components.health:StartRegen(1, 1)
	inst.components.health.nofadeout = true
	inst.components.health.save_maxhealth = true

    inst:AddComponent("combat")
    inst.components.combat.defaultdamage = TUNING.ABIGAIL_DAMAGE_PER_CREATURE[1]
    inst.components.combat.playerdamagepercent = TUNING.ABIGAIL_DMG_PLAYER_PERCENT
	inst.components.combat:SetKeepTargetFunction(auratest)

    inst:AddComponent("aura")
    inst.components.aura.pretickfn = RecalculateDamage
    inst.components.aura.radius = 4
    inst.components.aura.tickperiod = 1
    inst.components.aura.ignoreallies = true
    inst.components.aura.auratestfn = auratest

    inst.auratest = auratest

    MakeHauntableGoToState(inst, "haunted", nil, 64 * FRAMES * 1.2)

    ------------------
    --Added so you can attempt to give hearts to trigger flavour text when the action fails
    inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(AbleToAcceptTest)

	inst:AddComponent("ghostlyelixirable")

    inst:AddComponent("follower")
    inst.components.follower:KeepLeaderOnAttacked()
    inst.components.follower.keepdeadleader = true
	inst.components.follower.keepleaderduringminigame = true

	inst:AddComponent("timer")

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("onremoved", OnRemoved)
	inst:ListenForEvent("exitlimbo", OnExitLimbo)

    inst.BecomeDefensive = BecomeDefensive
    inst.BecomeAggressive = BecomeAggressive

    inst.IsWithinDefensiveRange = IsWithinDefensiveRange

    inst.LinkToPlayer = linktoplayer
    
    inst.attack_level = 1
    inst.is_defensive = true
    inst.issued_health_warning = false

	inst._on_ghostlybond_level_change = function(player, data) on_ghostlybond_level_change(inst, player, data) end
	inst._onlostplayerlink = function(player) onlostplayerlink(inst, player) end

    return inst
end

local function SetRetaliationTarget(inst, target)
	inst._RetaliationTarget = target
	inst.entity:SetParent(target.entity)

	inst.detachretaliationattack = function(t)
		if inst._RetaliationTarget ~= nil and inst._RetaliationTarget == t then
			inst.entity:SetParent(nil)
			inst.Transform:SetPosition(t.Transform:GetWorldPosition())
		end
	end

	inst:ListenForEvent("onremove", inst.detachretaliationattack, target)
	inst:ListenForEvent("death", inst.detachretaliationattack, target)
end

local function DoRetaliationDamage(inst)
	local target = inst._RetaliationTarget
	if target ~= nil and target:IsValid() and not target.inlimbo and target.components.combat ~= nil then
		target.components.combat:GetAttacked(inst, TUNING.GHOSTLYELIXIR_RETALIATION_DAMAGE)
		inst:detachretaliationattack(target)
        inst.SoundEmitter:PlaySound("dontstarve/characters/wendy/abigail/shield/retaliation_fx")

	end
end

local function retaliationattack_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("abigail_shield")
    inst.AnimState:SetBuild("abigail_shield")
    inst.AnimState:PlayAnimation("retaliation_fx")
    inst.AnimState:SetBloomEffectHandle("shaders/anim_bloom_ghost.ksh")
    inst.AnimState:SetLightOverride(.1)
	inst.AnimState:SetFinalOffset(3)

    --It's a loop that's always on, so we can start this in our pristine state
    -- inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_girl_howl_LP", "howl")

	inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst._RetaliationTarget = nil
	inst.SetRetaliationTarget = SetRetaliationTarget
	inst:DoTaskInTime(12*FRAMES, DoRetaliationDamage)
	inst:DoTaskInTime(30*FRAMES, inst.Remove)

	return inst
end

return Prefab("abigail", fn, assets, prefabs),
	   Prefab("abigail_retaliation", retaliationattack_fn, {Asset("ANIM", "anim/abigail_shield.zip")} )