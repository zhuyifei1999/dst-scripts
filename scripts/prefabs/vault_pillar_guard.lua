local assets =
{
	Asset("ANIM", "anim/vault_pillar_guard.zip"),
	Asset("ANIM", "anim/vault_pillar_guard_actions.zip"),
	Asset("ANIM", "anim/vault_pillar_guard_actions2.zip"),
	Asset("ANIM", "anim/vault_pillar_guard_basic.zip"),
}

local assets_dormant =
{
	Asset("ANIM", "anim/vault_pillar_guard.zip"),
}

local prefabs =
{
	"vault_pillar_guard_swipe_fx",
	"vault_pillar_guard_smash_fx",

	--loot
	"thulecite",
	"thulecite_pieces",
	"rocks",
	"moonrocknugget",
    "vault_orb_fragment", -- FIXME(JBK): rifts7: vault_orb_fragment
	"vault_orb_refined_blueprint",
	"temp_beta_msg", --#TEMP_BETA
}

local prefabs_dormant =
{
	"vault_pillar_guard",
}

local brain = require("brains/vault_pillar_guardbrain")

SetSharedLootTable("vault_pillar_guard",
{
	{ "thulecite",			1 },
	{ "thulecite",			1 },
	{ "thulecite",			0.5 },
	{ "thulecite_pieces",	1 },
	{ "thulecite_pieces",	0.6667 },
	{ "thulecite_pieces",	0.3333 },
	--
	{ "rocks",				1 },
	{ "rocks",				1 },
	{ "rocks",				0.75 },
	{ "rocks",				0.5 },
	--
	{ "moonrocknugget",		1 },
	{ "moonrocknugget",		1 },
	{ "moonrocknugget",		0.5 },
    --
    { "vault_orb_fragment", 1 }, -- FIXME(JBK): rifts7: vault_orb_fragment
    { "vault_orb_fragment", 1 },
    { "vault_orb_fragment", 0.5 },
})

local VAULT_LOOT =
{
	"vault_orb_refined_blueprint",
	"temp_beta_msg", --#TEMP_BETA
}

--------------------------------------------------------------------------

local function RecycleDebris(fx)
	local inst = fx.owner
	if inst and inst:IsValid() then
		if inst.debrisfx == fx then
			inst.debrisfx = nil
		end
		table.removearrayvalue(inst.highlightchildren, fx)
		table.insert(inst.debrisfxpool, fx)
		fx:RemoveFromScene()
		fx.entity:SetParent(inst.entity)
		fx.Transform:SetPosition(0, 0, 0)
		fx.Transform:SetRotation(0)
	else
		fx:Remove()
	end
end

local function CreateDebris()
	local fx = CreateEntity()

	fx:AddTag("NOCLICK")
	fx:AddTag("decor")
	--[[Non-networked entity]]
	fx.entity:SetCanSleep(TheWorld.ismastersim)
	fx.persists = false

	fx.entity:AddTransform()
	fx.entity:AddAnimState()

	fx.AnimState:SetBank("vault_pillar_guard")
	fx.AnimState:SetBuild("vault_pillar_guard_basic") --this build only has debris symbols
	fx.AnimState:SetFinalOffset(1)

	fx:ListenForEvent("animover", RecycleDebris)

	return fx
end

local function DetachDebris(inst, recycle) --recycle nil when triggered via parent "onremove"
	if inst.debrisfx then
		if inst.debrisfx:IsValid() then
			inst.debrisfx:RemoveEventCallback("onremove", DetachDebris, inst)

			local t = inst.debrisfx.AnimState:GetCurrentAnimationTime()
			local len = inst.debrisfx.AnimState:GetCurrentAnimationLength()
			if t == 0 or --state changed b4 even started?
				len - t > 1 or --too much time remaining, long state (activate?) interrupted?
				t + FRAMES * 1.5 >= len --close enough to end
			then
				--just stop the fx immediately
				if recycle then
					RecycleDebris(inst.debrisfx)
				else
					table.removearrayvalue(inst.highlightchildren, inst.debrisfx)
					inst.debrisfx:Remove()
					inst.debrisfx = nil
				end
				return
			end
			--detach finish playing the fx
			inst.debrisfx.entity:SetParent(nil)
			inst.debrisfx.Transform:SetPosition(inst.Transform:GetWorldPosition())
			inst.debrisfx.Transform:SetRotation(inst.Transform:GetRotation())
		end
		inst.debrisfx = nil
	end
end

local function DoDebris(inst)
	if inst.debrisanim:value() == inst.AnimState:GetCurrentAnimationHash() and not inst.AnimState:AnimDone() then
		if inst.debrisfxpool and #inst.debrisfxpool > 0 then
			inst.debrisfx = table.remove(inst.debrisfxpool)
			inst.debrisfx:ReturnToScene()
		else
			inst.debrisfx = CreateDebris()
			inst.debrisfx.owner = inst
			inst.debrisfx.entity:SetParent(inst.entity)
		end

		table.insert(inst.highlightchildren, inst.debrisfx)

		if inst.debrisnofaced:value() then
			inst.debrisfx.Transform:SetNoFaced()
		end
		inst.debrisfx.AnimState:PlayAnimation(inst.debrisanim:value())
		inst.debrisfx.AnimState:SetTime(inst.AnimState:GetCurrentAnimationTime())
		inst.debrisfx:ListenForEvent("onremove", DetachDebris, inst)
	end
end

local function PostUpdateDebris_Client(inst)
	inst._deferreddebris = false
	inst.components.updatelooper:RemovePostUpdateFn(PostUpdateDebris_Client)

	DoDebris(inst)
end

local function OnDebrisDirty_Client(inst)
	DetachDebris(inst, true)

	if not inst._deferreddebris then
		inst._deferreddebris = true
		inst.components.updatelooper:AddPostUpdateFn(PostUpdateDebris_Client)
	end
end

local function TriggerDebris(inst, show)
	if show then
		inst.debrisanim:set_local(0)
		inst.debrisanim:set(inst.AnimState:GetCurrentAnimationHash())
		inst.debrisnofaced:set(inst.sg.mem.nofaced or false)
	else
		inst.debrisanim:set(0)
	end

	if not TheNet:IsDedicated() then
		DetachDebris(inst, true)
		DoDebris(inst)
	end
end

--------------------------------------------------------------------------

local function teleport_override_fn(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	if TheWorld.Map:IsPointInVaultRoom(x, y, z) then
		return Vector3(x, y, z)
	end
end

--------------------------------------------------------------------------

local function IsClosestToTarget(inst, target, x1, z1, mindsq)
	for i = 1, 4 do
		local guard = inst.trial.components.entitytracker:GetEntity("guard"..tostring(i))
		if guard and guard ~= inst and
			guard.components.combat:TargetIs(target) and
			guard:GetDistanceSqToPoint(x1, 0, z1) < mindsq
		then
			return false --someone else closer to me has same target
		end
	end
	return true
end

local function RetargetFn(inst)
	--NOTE: additional shared targeting logic in vault_key_trial

	local target = inst.components.combat.target
	if target and inst.trial then
		--for vault room, and only if already engaged in combat
		--try to switch target if someone else closer than me has the same target

		local x, y, z = inst.Transform:GetWorldPosition()
		local x1, y1, z1 = target.Transform:GetWorldPosition()
		local mindsq = math2d.DistSq(x, z, x1, z1)
		local range = TUNING.VAULT_PILLAR_GUARD_ATTACK_RANGE + target:GetPhysicsRadius(0)
		if mindsq < range * range and not inst.components.combat:InCooldown() then
			return --within melee range, don't change target
		end

		if IsClosestToTarget(inst, target, x1, z1, mindsq) then
			return --i'm closest, don't change target
		end

		mindsq = math.huge
		local mindsq2 = math.huge
		local closest, closest2
		for _, v in ipairs(AllPlayers) do
			if not IsEntityDeadOrGhost(v) and v.entity:IsVisible() then
				local x1, y1, z1 = v.Transform:GetWorldPosition()
				if TheWorld.Map:IsPointInVaultRoom(x1, y1, z1) then
					local dsq = math2d.DistSq(x, z, x1, z1)
					if dsq < mindsq then
						mindsq = dsq
						closest = v
					end
					if dsq < mindsq2 and IsClosestToTarget(inst, v, x1, z1, dsq) then
						mindsq2 = dsq
						closest2 = v
					end
				end
			end
		end
		return closest2 or closest, true
	end
end

local function KeepTargetFn(inst, target)
	if not inst.components.combat:CanTarget(target) then
		return false
	end
	return TheWorld.Map:IsPointInVaultRoom(inst.Transform:GetWorldPosition()) == TheWorld.Map:IsPointInVaultRoom(target.Transform:GetWorldPosition())
end

local function OnAttacked(inst, data)
	if data and data.attacker and data.attacker:IsValid() then
		if data.attacker:HasAnyTag("vault_pillar_guard", "vault_crawler") and not data.attacker.components.combat:TargetIs(inst) then
			--ignore stray hits from pillar guard and crawler AOE
			return
		end

		if inst.trial and data.attacker:HasTag("shadowcreature") then
			for _, v in ipairs(AllPlayers) do
				if not IsEntityDeadOrGhost(v) and v.entity:IsVisible() then
					local x1, y1, z1 = v.Transform:GetWorldPosition()
					if data.attacker:GetDistanceSqToPoint(x1, y1, z1) < 100 and TheWorld.Map:IsPointInVaultRoom(x1, y1, z1) then
						v:PushEvent("ms_vaultshadowassist")
					end
				end
			end
		end

		local x, y, z = inst.Transform:GetWorldPosition()
		local target = inst.components.combat.target
		if target and target.isplayer then
			local range = TUNING.VAULT_PILLAR_GUARD_ATTACK_RANGE + target:GetPhysicsRadius(0)
			if target:GetDistanceSqToPoint(x, y, z) < range * range then
				return --don't switch targets
			end
		end
		if TheWorld.Map:IsPointInVaultRoom(x, y, z) == TheWorld.Map:IsPointInVaultRoom(data.attacker.Transform:GetWorldPosition()) then
			inst.components.combat:SetTarget(data.attacker)
		end
	end
	--share target for the room is done in vault_key_trial
end

local function LootSetupFn(lootdropper)
	if lootdropper.inst._vault_death_loot then
		lootdropper:SetLoot(VAULT_LOOT)
	end
	lootdropper:SetChanceLootTable("vault_pillar_guard")
end

local PHASES =
{
	{
		hp = 1,
		fn = function(inst)
			inst.canspin = false
			inst.canquickjump = false
		end,
	},
	{
		hp = 0.75,
		fn = function(inst)
			inst.canspin = true
			inst.canquickjump = false
		end,
	},
	{
		hp = 0.5,
		fn = function(inst)
			inst.canspin = true
			inst.canquickjump = true

			if not (POPULATING or inst.components.timer:TimerExists("stunned")) then
				inst.components.timer:StartTimer("stunned", TUNING.VAULT_PILLAR_GUARD_MAX_STAGGER_TIME, true)
			end
		end,
	},
	{
		hp = 1 / 3,
		fn = function(inst)
			inst.canspin = true
			inst.canquickjump = true

			if not POPULATING then
				local elapsed = inst.components.timer:GetTimeElapsed("stunned")
				if elapsed then
					if elapsed >= TUNING.VAULT_PILLAR_GUARD_MIN_STAGGER_TIME or inst.components.timer:IsPaused("stunned") then
						inst.components.timer:StopTimer("stunned")
					else
						inst.components.timer:SetTimeLeft("stunned", TUNING.VAULT_PILLAR_GUARD_MIN_STAGGER_TIME - elapsed)
					end
				end
			end
		end,
	},
}

local function OnLoad(inst, data)--, ents)
	local healthpct = inst.components.health:GetPercent()
	for i = #PHASES, 2, -1 do
		local v = PHASES[i]
		if healthpct <= v.hp then
			v.fn(inst)
			break
		end
	end
	if inst.components.timer:TimerExists("stunned") and not inst.components.timer:IsPaused("stunned") then
		inst.sg:GoToState("stun_idle")
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()

	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("soulless")
	inst:AddTag("mech")
	inst:AddTag("electricdamageimmune")
	inst:AddTag("epic")
	inst:AddTag("crazy") -- so they can attack shadow creatures
	inst:AddTag("vault_pillar_guard")

	inst.DynamicShadow:SetSize(6, 3.5)

	inst.Transform:SetFourFaced()

	inst.AnimState:SetBank("vault_pillar_guard")
	inst.AnimState:SetBuild("vault_pillar_guard")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetSymbolLightOverride("fx_blue_part", 0.5)
	inst.AnimState:SetSymbolLightOverride("pg_eye_parts", 0.14)
	inst.AnimState:SetSymbolLightOverride("pg_top", 0.12)
	inst.AnimState:SetSymbolLightOverride("pg_shoulder", 0.09)
	inst.AnimState:SetSymbolLightOverride("pg_chest", 0.08)
	inst.AnimState:SetSymbolLightOverride("pg_pelvis", 0.05)

	inst:SetPhysicsRadiusOverride(1.6)
	MakeGiantCharacterPhysics(inst, 1000, inst.physicsradiusoverride)

	inst.debrisanim = net_hash(inst.GUID, "vault_pillar_guard.debrisanim", "debrisdirty")
	inst.debrisnofaced = net_bool(inst.GUID, "vault_pillar_guard.debrisnofaced")

	if not TheNet:IsDedicated() then
		inst.debrisfxpool = {}
		inst.highlightchildren = {}
	end

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:AddComponent("updatelooper")
		inst:ListenForEvent("debrisdirty", OnDebrisDirty_Client)

		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("locomotor")
	inst.components.locomotor.walkspeed = TUNING.VAULT_PILLAR_GUARD_SPEED
	inst.components.locomotor.runspeed = TUNING.VAULT_PILLAR_GUARD_SPEED

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.VAULT_PILLAR_GUARD_HEALTH)
	inst.components.health.nofadeout = true

	inst:AddComponent("damagetypebonus")
	inst:AddComponent("damagetyperesist")

	inst:AddComponent("combat")
	inst.components.combat.playerdamagepercent = 0.5
	inst.components.combat.hiteffectsymbol = "pg_pelvis"
	inst.components.combat.forcefacing = false
	inst.components.combat:SetDefaultDamage(TUNING.VAULT_PILLAR_GUARD_DAMAGE)
	inst.components.combat:SetRange(TUNING.VAULT_PILLAR_GUARD_ATTACK_RANGE)
	inst.components.combat:SetAttackPeriod(TUNING.VAULT_PILLAR_GUARD_ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(3, RetargetFn)
	inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

	inst:AddComponent("healthtrigger")
	for i, v in ipairs(PHASES) do
		inst.components.healthtrigger:AddTrigger(v.hp, v.fn)
	end
	PHASES[1].fn(inst)

	inst:AddComponent("timer")

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("vault_pillar_guard")
	inst.components.lootdropper:SetLootSetupFn(LootSetupFn)
	inst.components.lootdropper.min_speed = 2
	inst.components.lootdropper.max_speed = 4
	inst.components.lootdropper.y_speed = 4
	inst.components.lootdropper.y_speed_variance = 3
	inst.components.lootdropper.spawn_loot_inside_prefab = true

	inst:AddComponent("teleportedoverride")
	inst.components.teleportedoverride:SetDestPositionFn(teleport_override_fn)

	inst:AddComponent("explosiveresist")

	inst:AddComponent("knownlocations")

	--MakeHugeFreezableCharacter(inst, "pg_pelvis")
	MakeHauntable(inst)

	inst:ListenForEvent("attacked", OnAttacked)

	inst.TriggerDebris = TriggerDebris

	inst:SetStateGraph("SGvault_pillar_guard")
	inst:SetBrain(brain)

	inst.OnLoad = OnLoad

	return inst
end

local function ActivatePillarGuard(inst, trial)
	inst = ReplacePrefab(inst, "vault_pillar_guard")
	if trial then
		local x, y, z = inst.Transform:GetWorldPosition()
		local x1, y1, z1 = trial.Transform:GetWorldPosition()
		if x ~= x1 or z ~= z1 then
			local dx = x1 - x
			local dz = z1 - z
			local len = math.sqrt(dx * dx + dz * dz)
			local home = Vector3(x + dx * 3 / len, 0, z + dz * 3 / len)
			inst.Transform:SetRotation(math.atan2(-dz, dx) * RADIANS)
			inst.components.knownlocations:RememberLocation("spawnpoint", home)
		end
	end
	inst.sg:GoToState("activate")
	return inst
end

local function dormantfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("vault_pillar_guard")
	inst.AnimState:SetBuild("vault_pillar_guard")
	inst.AnimState:PlayAnimation("pillar_idle")

	inst:SetDeploySmartRadius(1.5)
	MakeObstaclePhysics(inst, 1.3)

	--Not using NOCLICK because we do want to block mouse
	--Not using decor/FX because we do want to block placement
	--Some actions will highlight targets even if not a valid action:
	--  "nomagic" blocks SPELLCAST (e.g. reskin_tool)
	--  "nohighlight" blocks complexprojectile (e.g. bombs)
	inst:AddTag("nomagic")
	inst:AddTag("nohighlight")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst.ActivatePillarGuard = ActivatePillarGuard

	return inst
end

return Prefab("vault_pillar_guard", fn, assets, prefabs),
	Prefab("vault_pillar_guard_dormant", dormantfn, assets_dormant, prefabs_dormant)
