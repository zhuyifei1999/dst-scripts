local assets =
{
	Asset("ANIM", "anim/charlie_boss_basic.zip"),
	Asset("ANIM", "anim/charlie_boss_actions.zip"),
}

local prefabs =
{
	"charlie_boss_minion1",
	"charlie_boss_minion2",
	"charlie_boss_aoe_flame_fx",
	"charlie_boss_projectile",
	"charlie_boss_reflect_projectile_fx",
	"charlie_boss_vines",

	--loot
	"temp_beta_msg", --#TEMP_BETA
	"horrorfuel",
	"nightmarefuel",
}

SetSharedLootTable("charlie_boss",
{
	{ "horrorfuel",			1.00 },
	{ "horrorfuel",			1.00 },
	{ "horrorfuel",			1.00 },
	{ "horrorfuel",			1.00 },
	{ "horrorfuel",			1.00 },
	{ "horrorfuel",			0.75 },
	{ "nightmarefuel",		1.00 },
	{ "nightmarefuel",		1.00 },
	{ "nightmarefuel",		0.75 },
})

local brain = require("brains/charlie_bossbrain")
local AOEUtil = require("aoeutil")

local AOE_TAGSET
local function GetAOEAttackTagSet(inst)
	if AOE_TAGSET == nil then
		AOE_TAGSET = AOEUtil.AttackTagSet()
		AOE_TAGSET:AppendCantTags("shadowthrall", "shadow", "shadowcreature", "shadowchesspiece", "charlie_npc")
		AOE_TAGSET:Register()
	end
	return AOE_TAGSET
end

local function IsPointInArena(x, y, z)
	return TheWorld.Map:IsPointInCharlieBossArena(x, y, z)
end

local function IsEntInArena(ent)
	return TheWorld.Map:IsPointInCharlieBossArena(ent.Transform:GetWorldPosition())
end

local function UpdatePlayerTargets(inst)
	assert(next(inst._temptbl1) == nil and next(inst._temptbl2) == nil)
	local toadd = inst._temptbl1
	local toremove = inst._temptbl2
	local x, _, z = inst.Transform:GetWorldPosition()

	for k in pairs(inst.components.grouptargeter:GetTargets()) do
		toremove[k] = true
	end

	local map = TheWorld.Map
	if inst:IsInArena() then
		for _, v in ipairs(AllPlayers) do
			if not (v.components.health:IsDead() or v:HasTag("playerghost")) and
				v.entity:IsVisible() and
				IsEntInArena(v)
			then
				if toremove[v] then
					toremove[v] = nil
				else
					table.insert(toadd, v)
				end
			end
		end
	else
		for _, v in ipairs(FindPlayersInRange(x, 0, z, TUNING.CHARLIE_BOSS_DEAGGRO_DIST, true)) do
			if toremove[v] then
				toremove[v] = nil
			else
				table.insert(toadd, v)
			end
		end
	end

	for k in pairs(toremove) do
		inst.components.grouptargeter:RemoveTarget(k)
		toremove[k] = nil
	end
	for i = 1, #toadd do
		inst.components.grouptargeter:AddTarget(toadd[i])
		toadd[i] = nil
	end
	--assert(next(toadd) == nil and next(toremove) == nil)
end

local function RetargetFn(inst)
	if inst.components.health:IsDead() or inst.sg:HasStateTag("temp_invincible") then
		return
	end

	UpdatePlayerTargets(inst)

	local x, y, z = inst.Transform:GetWorldPosition()
	local map = TheWorld.Map
	local inarena = map:IsPointInWagPunkArenaAndBarrierIsUp(x, y, z)
	local target = inst.components.combat.target
	local inrange
	if target then
		local range = TUNING.CHARLIE_BOSS_ATTACK_RANGE + target:GetPhysicsRadius(0)
		local x1, _, z1 = target.Transform:GetWorldPosition()
		inrange = math2d.DistSq(x1, z1, x, z) < range * range and inst:IsInArena() == IsPointInArena(x1, 0, z1)

		if target.isplayer then
			--NOTE: grouptargets aleady have checked for inarena conditions during UpdatePlayerTargets
			local newplayer = inst.components.grouptargeter:TryGetNewTarget()
			if newplayer then
				range = inrange and TUNING.CHARLIE_BOSS_ATTACK_RANGE + newplayer:GetPhysicsRadius(0) or TUNING.CHARLIE_BOSS_KEEP_AGGRO_DIST
				if newplayer:GetDistanceSqToPoint(x, 0, z) < range * range then
					return newplayer, true
				end
			end
			return
		end
	end

	--NOTE: grouptargets aleady have checked for inarena conditions during UpdatePlayerTargets
	assert(next(inst._temptbl1) == nil)
	local nearplayers = inst._temptbl1
	for k in pairs(inst.components.grouptargeter:GetTargets()) do
		local range = inrange and TUNING.CHARLIE_BOSS_ATTACK_RANGE + k:GetPhysicsRadius(0) or TUNING.CHARLIE_BOSS_AGGRO_DIST
		if k:GetDistanceSqToPoint(x, 0, z) < range * range then
			table.insert(nearplayers, k)
		end
	end
	if #nearplayers > 0 then
		local newplayer = nearplayers[math.random(#nearplayers)]
		for k in pairs(nearplayers) do
			nearplayers[k] = nil
		end
		--assert(next(nearplayers) == nil)
		return newplayer, true
	end
	--assert(next(nearplayers) == nil)
end

local function KeepTargetFn(inst, target)
	if not inst.components.combat:CanTarget(target) then
		return false
	elseif inst:IsInArena() then
		return IsEntInArena(target)
	end
	return inst:IsNear(target, TUNING.CHARLIE_BOSS_DEAGGRO_DIST)
end

local function TryAggro(inst, attacker)
	local x, y, z = inst.Transform:GetWorldPosition()
	local target = inst.components.combat.target
	if target and target.isplayer then
		local range = TUNING.CHARLIE_BOSS_ATTACK_RANGE + target:GetPhysicsRadius(0)
		if target:GetDistanceSqToPoint(x, y, z) < range * range then
			return false
		end
	end
	inst.components.combat:SetTarget(attacker)
	return true
end

local function OnAttacked(inst, data)
	if data and data.attacker and data.attacker:IsValid() then
		TryAggro(inst, data.attacker)
	end
end

local function SpawnReflectProjectileAtXYZ(inst, x, y, z, rot, targetorpos)
	local fx = SpawnPrefab("charlie_boss_reflect_projectile_fx")
	fx.Transform:SetPosition(x, y, z)
	fx.Transform:SetRotation(rot)
	fx:ListenForEvent("animover", function(fx)
		fx:Remove()

		local proj = SpawnPrefab("charlie_boss_projectile")
		if not (Vector3.is_instance(targetorpos) or (targetorpos and targetorpos:IsValid())) then
			local theta = rot * DEGREES
			local len = 6 + math.random() * 2
			targetorpos = Vector3(x + len * math.cos(theta), 0, z - len * math.sin(theta))
		end
		proj:Launch(inst, targetorpos, x, y, z, rot - 60 + math.random() * 120)
	end)
end

local REFLECT_RADIUS = 2

local function OnBlocked(inst, data)
	if data then
		if data.attacker and data.attacker:IsValid() then
			TryAggro(inst, data.attacker)
		end

		if IsRangedWeapon(data.weapon) then
			local function onweapononattack(weaponinst, data)
				inst:RemoveEventCallback("weapononattack", onweapononattack, weaponinst)

				if data and data.projectile and data.projectile:IsValid() then
					local x1, y1, z1 = data.projectile.Transform:GetWorldPosition()
					if y1 < 0.2 then
						y1 = 1.25
					else
						if data.projectile.prefab == "boomerang" then
							y1 = y1 + 1.25
						end
						y1 = math.max(1, y1)
					end
					local rot = data.projectile.Transform:GetRotation() + 180

					if data.projectile.components.projectile then
						data.projectile.components.projectile:Deflect(inst)
					end

					local x, y, z = inst.Transform:GetWorldPosition()
					local theta = rot * DEGREES
					x1 = x + REFLECT_RADIUS * math.cos(theta)
					z1 = z - REFLECT_RADIUS * math.sin(theta)
					SpawnReflectProjectileAtXYZ(inst, x1, y1, z1, rot, data.attacker)
				end
			end
			inst:ListenForEvent("weapononattack", onweapononattack, data.weapon)
		end
	end
end

local REFLECT_COMPLEX_PROJECTILE_TAGS = { "complexprojectile", "activeprojectile" }
local REFLECT_COMPLEX_PROJECTILE_NOTAGS = { "INLIMBO" }
local REFLECT_RADIUS_SQ = REFLECT_RADIUS * REFLECT_RADIUS
local REFLECT_HEIGHT = 5
local REFLECT_COMPLEX_PROJECTILE_SEARCH_RADIUS = math.sqrt(REFLECT_RADIUS_SQ + REFLECT_HEIGHT * REFLECT_HEIGHT)
local _reflect_ignores = {}
local function OnUpdateReflectComplexProjectiles(inst, dt)
	for k in pairs(_reflect_ignores) do
		if not (k:IsValid() and k:HasTag("activeprojectile")) then
			_reflect_ignores[k] = nil
		end
	end

	local x, _, z = inst.Transform:GetWorldPosition()
	for _, v in ipairs(TheSim:FindEntities(x, 0, z, REFLECT_COMPLEX_PROJECTILE_SEARCH_RADIUS, REFLECT_COMPLEX_PROJECTILE_TAGS, REFLECT_COMPLEX_PROJECTILE_NOTAGS)) do
		if not _reflect_ignores[v] then
			local x1, y1, z1 = v.Transform:GetWorldPosition()
			if y1 < REFLECT_HEIGHT and math2d.DistSq(x, z, x1, z1) < REFLECT_RADIUS_SQ then
				local attacker = v.components.complexprojectile.attacker
				if attacker and attacker:IsValid() then
					TryAggro(inst, attacker)
				end

				local rot = v.Transform:GetRotation() + 180

				v.components.complexprojectile:Deflect(inst)

				if v:IsValid() and v:HasTag("activeprojectile") then
					_reflect_ignores[v] = true
				end

				local theta = rot * DEGREES
				x1 = x + REFLECT_RADIUS * math.cos(theta)
				z1 = z - REFLECT_RADIUS * math.sin(theta)
				SpawnReflectProjectileAtXYZ(inst, x1, y1, z1, rot, attacker)
			end
		end
	end
end

local function SetReflectingProjectiles(inst, enable)
	if enable then
		if not inst.isreflectingprojectiles then
			inst.isreflectingprojectiles = true
			inst.components.damagetyperesist:AddResist("projectile", inst, 0, "rangedcounter")
			inst.components.damagetyperesist:AddResist("rangedweapon", inst, 0, "rangedcounter")
			inst.components.updatelooper:AddOnUpdateFn(OnUpdateReflectComplexProjectiles)
			inst:ListenForEvent("blocked", OnBlocked)
		end
	elseif inst.isreflectingprojectiles then
		inst.isreflectingprojectiles = false
		inst.components.damagetyperesist:RemoveResist("projectile", inst, "rangedcounter")
		inst.components.damagetyperesist:RemoveResist("rangedweapon", inst, "rangedcounter")
		inst.components.updatelooper:RemoveOnUpdateFn(OnUpdateReflectComplexProjectiles)
		inst:RemoveEventCallback("blocked", OnBlocked)
	end
end

local function WantsToReflectProjectiles(inst) --called from sg
	return inst.canreflectprojectiles and (inst.components.combat:HasTarget() or inst._disengagetask ~= nil)
end

local function ToggleReflectingProjectiles(inst) --called from sg
	if inst.components.combat:HasTarget() or inst._disengagetask then
		SetReflectingProjectiles(inst, inst.canreflectprojectiles)
	end
end

local function SwitchMode(inst)
	inst.canvinecounter = not inst.canvinecounter
	inst.canreflectprojectiles = not inst.canreflectprojectiles
	inst.sg.mem.forcetaunt = true
	inst.components.combat.battlecryenabled = true
	inst.components.combat:SetAttackPeriod(inst.canvinecounter and TUNING.CHARLIE_BOSS_ATTACK_PERIOD or TUNING.CHARLIE_BOSS_ATTACK_PERIOD2)
end

local function CalcMinModeTime()
	return GetRandomMinMax(unpack(TUNING.CHARLIE_BOSS_MODE_SWITCH_MINTIME))
end

local function OnModeTask(inst)
	inst._modetask = nil
	local hp = inst.components.health:GetPercent()
	if hp + TUNING.CHARLIE_BOSS_MODE_SWITCH_HP < inst._modehp then
		SwitchMode(inst)
		inst._modehp = hp
		inst._modetask = inst:DoTaskInTime(CalcMinModeTime(), OnModeTask)
	end
end

local function OnHealthDelta(inst, data)
	if inst._modetask == nil and data and data.newpercent and data.newpercent + TUNING.CHARLIE_BOSS_MODE_SWITCH_HP < inst._modehp then
		SwitchMode(inst)
		inst._modehp = data.newpercent
		inst._modetask = inst:DoTaskInTime(CalcMinModeTime(), OnModeTask)
	end
end

local function SetModeSwitching(inst, enable)
	if enable then
		if not inst.ismodeswitching then
			inst.ismodeswitching = true
			inst._modetask = inst:DoTaskInTime(CalcMinModeTime(), OnModeTask)
			inst._modehp = inst.components.health:GetPercent()
			inst:ListenForEvent("healthdelta", OnHealthDelta)
		end
	elseif inst.ismodeswitching then
		inst.ismodeswitching = false
		if inst._modetask then
			inst._modetask:Cancel()
			inst._modetask = nil
		end
		inst._modehp = nil
		inst:RemoveEventCallback("healthdelta", OnHealthDelta)
	end
end

local function SetShadowHandsEnabled(inst, enable)
	if enable then
		if inst:IsInArena() then
			inst.isshadowhandsenabled = true
			inst:PushEvent("ms_charliearena_shadowhands_setenabled", true)
		end
	elseif inst.isshadowhandsenabled then
		inst.isshadowhandsenabled = false
		inst:PushEvent("ms_charliearena_shadowhands_setenabled", false)
	end
end

local function SetRunnerSpawnsEnabled(inst, enable)
	if enable then
		if inst:IsInArena() then
			inst.isrunnerspawnsenabled = true
			inst:PushEvent("ms_charliearena_shadowrunners_setenabled", true)
		end
	elseif inst.isrunnerspawnsenabled then
		inst.isrunnerspawnsenabled = false
		inst:PushEvent("ms_charliearena_shadowrunners_setenabled", false)
	end
end

local function OnNewCombatTarget(inst, data)
	if inst._disengagetask then
		inst._disengagetask:Cancel()
		inst._disengagetask = nil
	end
	SetModeSwitching(inst, inst.canmodeswitch)
	SetShadowHandsEnabled(inst, inst.canshadowhands)
	SetRunnerSpawnsEnabled(inst, inst.canspawnrunners)

	--#TEMP_BETA
	if inst.sg.mem.killstarttime == nil and inst:IsInArena() then
		inst.sg.mem.killstarttime = GetTime()
	end
end

local function Disengage(inst)
	inst._disengagetask = nil
	SetModeSwitching(inst, false)
	SetReflectingProjectiles(inst, false)
	SetShadowHandsEnabled(inst, false)
	SetRunnerSpawnsEnabled(inst, false)
	inst.components.combat.battlecryenabled = true
	inst.sg.mem.forcetaunt = nil

	--#TEMP_BETA
	if inst.sg.mem.killstarttime and not inst.components.health:IsHurt() then
		inst.sg.mem.killstarttime = nil
	end
end

local function OnDroppedTarget(inst)
	if inst._disengagetask == nil then
		inst._disengagetask = inst:DoTaskInTime(10, Disengage)
	end
end

local function OnDeath(inst)
	inst.components.combat:DropTarget()
	if inst._disengagetask then
		inst._disengagetask:Cancel()
		Disengage(inst)
	end
end

local function teleport_override_fn(inst)
	return inst:GetPosition()
end

local function IsInArena(inst)
	if inst._inarena == nil then
		inst._inarena = TheWorld.Map:IsPointInCharlieBossArena(inst.Transform:GetWorldPosition())
	end
	return inst._inarena
end

local PHASES =
{
	{
		hp = 1,
		fn = function(inst)
			inst.canmodeswitch = false
			inst.canshadowhands = false
			inst.canvinecounter = false
			inst.canreflectprojectiles = false
			inst.canspawnrunners = false
			SetModeSwitching(inst, false)
			SetShadowHandsEnabled(inst, false)
			SetRunnerSpawnsEnabled(inst, false)
			inst.sg.mem.forcetaunt = true
			inst.components.combat.battlecryenabled = true
			inst.components.combat:SetAttackPeriod(TUNING.CHARLIE_BOSS_ATTACK_PERIOD2)
		end,
	},
	{
		hp = 0.9,
		fn = function(inst)
			inst.canmodeswitch = false
			inst.canshadowhands = true
			inst.canvinecounter = true
			inst.canreflectprojectiles = false
			inst.canspawnrunners = false
			SetModeSwitching(inst, false)
			SetShadowHandsEnabled(inst, inst.components.combat:HasTarget())
			SetRunnerSpawnsEnabled(inst, false)
			inst.sg.mem.forcetaunt = true
			inst.components.combat.battlecryenabled = true
			inst.components.combat:SetAttackPeriod(TUNING.CHARLIE_BOSS_ATTACK_PERIOD)			
		end,
	},
	{
		hp = 0.75,
		fn = function(inst)
			inst.canmodeswitch = true
			inst.canshadowhands = true
			if not POPULATING or math.random() < 0.5 then
				inst.canvinecounter = false
				inst.canreflectprojectiles = true
			else
				inst.canvinecounter = true
				inst.canreflectprojectiles = false
			end
			inst.canspawnrunners = false
			SetModeSwitching(inst, inst.components.combat:HasTarget())
			SetShadowHandsEnabled(inst, inst.components.combat:HasTarget())
			SetRunnerSpawnsEnabled(inst, false)
			inst.sg.mem.forcetaunt = true
			inst.components.combat.battlecryenabled = true
			inst.components.combat:SetAttackPeriod(inst.canvinecounter and TUNING.CHARLIE_BOSS_ATTACK_PERIOD or TUNING.CHARLIE_BOSS_ATTACK_PERIOD2)
		end,
	},
	{
		hp = 0.2,
		fn = function(inst)
			inst.canshadowhands = true
			if not inst.canmodeswitch then
				inst.canmodeswitch = true
				if math.random() < 0.5 then
					inst.canvinecounter = false
					inst.canreflectprojectiles = true
				else
					inst.canvinecounter = true
					inst.canreflectprojectiles = false
				end
				SetModeSwitching(inst, inst.components.combat:HasTarget())
				inst.sg.mem.forcetaunt = true
			end
			inst.canspawnrunners = true
			SetShadowHandsEnabled(inst, inst.components.combat:HasTarget())
			SetRunnerSpawnsEnabled(inst, inst.components.combat:HasTarget())
			inst.components.combat.battlecryenabled = true
			inst.components.combat:SetAttackPeriod(inst.canvinecounter and TUNING.CHARLIE_BOSS_ATTACK_PERIOD or TUNING.CHARLIE_BOSS_ATTACK_PERIOD2)

		end,
	},
}

local function OnSave(inst, data)
	if inst.sg.mem.killstarttime then
		data.killtime = math.floor(GetTime() - inst.sg.mem.killstarttime)
	end
end

local function OnLoad(inst, data)--, ents)
	local healthpct = inst.components.health:GetPercent()
	for i = #PHASES, 2, -1 do
		local v = PHASES[i]
		if healthpct <= v.hp then
			v.fn(inst)
			break
		end
	end
	if data and data.killtime then
		inst.sg.mem.killstarttime = GetTime() - data.killtime
	end
end

local function OnRemoveEntity(inst)
	SetShadowHandsEnabled(inst, false)
	SetRunnerSpawnsEnabled(inst, false)
end

local LIGHT_OVERRIDE = 1

local function AddFollowSymbol(inst, sym, anim)
	local fx = CreateEntity()

	fx:AddTag("FX")
	--[[Non-networked entity]]
	--fx.entity:SetCanSleep(false) --commented out; follow parent sleep instead
	fx.persists = false

	fx.entity:AddTransform()
	fx.entity:AddAnimState()
	fx.entity:AddFollower()

	fx.AnimState:SetBank("charlie_boss")
	fx.AnimState:SetBuild("charlie_boss_basic")
	fx.AnimState:PlayAnimation(anim, true)
	fx.AnimState:SetLightOverride(LIGHT_OVERRIDE)

	fx.entity:SetParent(inst.entity)
	fx.Follower:FollowSymbol(inst.GUID, sym, 0, 0, 0, true)

	return fx
end

local function OnColourChanged(inst, r, g, b, a)
	for _, v in ipairs(inst.highlightchildren) do
		v.AnimState:SetAddColour(r, g, b, a)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddLight()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.Light:SetIntensity(0.3)
	inst.Light:SetRadius(0.4)
	inst.Light:SetFalloff(0.9)
	inst.Light:SetColour(0.5, 0, 0)

	MakeGiantCharacterPhysics(inst, 1000, 0.9)

	inst.Transform:SetSixFaced()

	inst.AnimState:SetBank("charlie_boss")
	inst.AnimState:SetBuild("charlie_boss_basic")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetLightOverride(LIGHT_OVERRIDE)
	if LIGHT_OVERRIDE < 1 then
		inst.AnimState:SetSymbolLightOverride("cb_hand_red", 1)
		inst.AnimState:SetSymbolLightOverride("cb_torso_red", 1)
	end

	inst:AddTag("character")
	inst:AddTag("charlie_npc")
	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("scarytoprey")
	inst:AddTag("shadow_aligned")
	inst:AddTag("epic")

	inst:AddComponent("colouraddersync")

	if not TheNet:IsDedicated() then
		inst.highlightchildren =
		{
			AddFollowSymbol(inst, "cb_hair_follow", "hair_loop"),
			AddFollowSymbol(inst, "cb_arm_a_follow", "arm_a_loop"),
			AddFollowSymbol(inst, "cb_arm_b_follow", "arm_b_loop"),
			AddFollowSymbol(inst, "cb_base_follow", "base_loop"),
		}

		inst.components.colouraddersync:SetColourChangedFn(OnColourChanged)
	end

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("updatelooper")
	inst:AddComponent("colouradder")
	inst:AddComponent("inspectable")
	inst:AddComponent("knownlocations")
	inst:AddComponent("damagetyperesist")
	inst:AddComponent("grouptargeter")

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.CHARLIE_BOSS_HEALTH)
	inst.components.health.nofadeout = true

	inst:AddComponent("combat")
	inst.components.combat.battlecryinterval = TUNING.CHARLIE_BOSS_TAUNT_INTERVAL
	inst.components.combat.playerdamagepercent = TUNING.CHARLIE_BOSS_PLAYERDAMAGEPERCENT
	inst.components.combat:SetAttackPeriod(TUNING.CHARLIE_BOSS_ATTACK_PERIOD)
	inst.components.combat:SetRange(TUNING.CHARLIE_BOSS_ATTACK_RANGE)
	inst.components.combat:SetDefaultDamage(TUNING.CHARLIE_BOSS_DAMAGE)
	inst.components.combat:SetRetargetFunction(1, RetargetFn)
	inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

	inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(TUNING.CHARLIE_BOSS_PLANAR_DAMAGE)

	inst:AddComponent("locomotor")
	inst.components.locomotor.walkspeed = TUNING.CHARLIE_BOSS_WALKSPEED
	inst.components.locomotor.runspeed = TUNING.CHARLIE_BOSS_WALKSPEED

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = -TUNING.SANITYAURA_HUGE

	inst:AddComponent("teleportedoverride")
	inst.components.teleportedoverride:SetDestPositionFn(teleport_override_fn)

	inst:AddComponent("explosiveresist")

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("charlie_boss")

	inst:SetStateGraph("SGcharlie_boss")
	inst:SetBrain(brain)

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("newcombattarget", OnNewCombatTarget)
	inst:ListenForEvent("droppedtarget", OnDroppedTarget)
	inst:ListenForEvent("death", OnDeath)

	inst._temptbl1 = {}
	inst._temptbl2 = {}
	inst.isreflectingprojectiles = false
	inst.ismodeswitching = false
	inst.isshadowhandsenabled = false
	inst.isrunnerspawnsenabled = false

	inst.IsInArena = IsInArena
	inst.GetAOEAttackTagSet = GetAOEAttackTagSet
	inst.SpawnReflectProjectileAtXYZ = SpawnReflectProjectileAtXYZ
	inst.WantsToReflectProjectiles = WantsToReflectProjectiles
	inst.ToggleReflectingProjectiles = ToggleReflectingProjectiles
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad
	inst.OnRemoveEntity = OnRemoveEntity

	inst:AddComponent("healthtrigger")
	for _, v in ipairs(PHASES) do
		inst.components.healthtrigger:AddTrigger(v.hp, v.fn)
	end
	PHASES[1].fn(inst)

	return inst
end

local function fxfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("charlie_boss")
	inst.AnimState:SetBuild("charlie_boss_basic")
	inst.AnimState:PlayAnimation("aoe_flame_fx")
	inst.AnimState:SetFinalOffset(-1)

	inst.AnimState:SetSymbolLightOverride("fx_red_particle", 1)

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:ListenForEvent("animover", inst.Remove)
	inst.persists = false

	return inst
end

return Prefab("charlie_boss", fn, assets, prefabs),
	Prefab("charlie_boss_aoe_flame_fx", fxfn, assets)
