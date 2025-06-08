local assets =
{
	Asset("ANIM", "anim/wagboss_lunar.zip"),
	Asset("ANIM", "anim/wagboss_lunar_actions.zip"),
	Asset("ANIM", "anim/wagboss_lunar_spawn.zip"),
	Asset("SCRIPT", "scripts/prefabs/wagboss_util.lua"),
}

local assets_slamfx =
{
	Asset("ANIM", "anim/bomb_lunarplant.zip"),
	Asset("ANIM", "anim/sleepcloud.zip"),
	Asset("ANIM", "anim/wagboss_robot.zip"),
}

local assets_erruptfx =
{
	Asset("ANIM", "anim/wagboss_lunar_blast.zip"),
}

local prefabs =
{
	"alterguardian_phase4_lunarrift_slam_fx",
	"alterguardian_phase4_lunarrift_erupt_fx",
	"alterguardian_lunar_fissures",
	"alterguardian_lunar_supernova_burn_fx",

	"wagstaff_item_1",
	"wagstaff_item_2",

	--loot
	"lunar_seed",
	"purebrilliance",
	"gears",
	"temp_beta_msg", --#TEMP_BETA
}

SetSharedLootTable("alterguardian_phase4_lunarrift",
{
	{ "lunar_seed",			1.0 },
	{ "lunar_seed",			1.0 },
	{ "lunar_seed",			1.0 },
	{ "lunar_seed",			1.0 },
	{ "lunar_seed",			1.0 },

	{ "purebrilliance",		1.0 },
	{ "purebrilliance",		1.0 },
	{ "purebrilliance",		1.0 },
	{ "purebrilliance",		1.0 },
	{ "purebrilliance",		1.0 },
	{ "purebrilliance",		0.7 },
	{ "purebrilliance",		0.3 },

	{ "trinket_6",			1.0 },
	{ "trinket_6",			1.0 },
	{ "trinket_6",			0.7 },
	{ "gears",				1.0 },
	{ "gears",				0.5 },
})

local brain = require("brains/alterguardian_phase4_lunarriftbrain")

local TRANSPARENCY = 0.2
local LIGHTOVERRIDE = 0.5

--------------------------------------------------------------------------

local function CreateDashFx()
	local fx = CreateEntity()

	fx:AddTag("DECOR")
	fx:AddTag("NOCLICK")
	--[[Non-networked entity]]
	--fx.entity:SetCanSleep(false)
	fx.persists = false

	fx.entity:AddTransform()
	fx.entity:AddAnimState()

	fx.AnimState:SetBank("wagboss_lunar_blast")
	fx.AnimState:SetBuild("wagboss_lunar_blast")
	fx.AnimState:PlayAnimation("dash_wave", true)
	fx.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	fx.AnimState:SetLayer(LAYER_BACKGROUND)
	fx.AnimState:SetSortOrder(3)
	fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	fx.AnimState:SetMultColour(1, 1, 1, TRANSPARENCY * 2)
	fx.AnimState:SetLightOverride(LIGHTOVERRIDE)

	return fx
end

local function OnShowDashFx(inst)
	if inst.showdashfx:value() then
		if inst.dashfx == nil then
			inst.dashfx = CreateDashFx()
			inst.dashfx.entity:SetParent(inst.entity)
		end
	elseif inst.dashfx then
		inst.dashfx:Remove()
		inst.dashfx = nil
	end
end

local function StartDashFx(inst)
	if not inst.showdashfx:value() then
		inst.showdashfx:set(true)
		if not TheNet:IsDedicated() then
			OnShowDashFx(inst)
		end
	end
end

local function StopDashFx(inst)
	if inst.showdashfx:value() then
		inst.showdashfx:set(false)
		if not TheNet:IsDedicated() then
			OnShowDashFx(inst)
		end
	end
end

--------------------------------------------------------------------------

local function teleport_override_fn(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	if TheWorld.Map:IsPointInWagPunkArena(x, y, z) then
		return Vector3(x, y, z)
	end
end

--------------------------------------------------------------------------
--Client follow symbol functions

local function AddFollowFx(inst, anim, symbol, frame, alpha, usefacings)
	local fx = CreateEntity()

	fx:AddTag("FX")
	--[[Non-networked entity]]
	fx.entity:SetCanSleep(TheWorld.ismastersim)
	fx.persists = false

	fx.entity:AddTransform()
	fx.entity:AddAnimState()
	fx.entity:AddFollower()

	if usefacings then
		fx.Transform:SetFourFaced()
	end

	fx.AnimState:SetBank("wagboss_lunar")
	fx.AnimState:SetBuild("wagboss_lunar")

	if frame then
		--V2C: -not bothering with AnimState:SetPercent's weird math under the hood.
		--     -it's safe enough to use Pause(), just be mindful of that conflicting with RemoveFromScene/ReturnToScene.
		fx.AnimState:PlayAnimation(anim)
		fx.AnimState:SetFrame(frame - 1)
		fx.AnimState:Pause()
		fx.Follower:FollowSymbol(inst.GUID, symbol, nil, nil, nil, true, nil, frame - 1)
	else
		fx.AnimState:PlayAnimation(anim, true)
		fx.AnimState:SetFrame(math.random(fx.AnimState:GetCurrentAnimationNumFrames()) - 1)
		fx.Follower:FollowSymbol(inst.GUID, symbol, nil, nil, nil, true)
	end

	if alpha then
		fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
		fx.AnimState:SetMultColour(1, 1, 1, alpha)
		fx.AnimState:SetLightOverride(LIGHTOVERRIDE)
	else
		fx.AnimState:SetLightOverride(0.06)
	end

	fx.entity:SetParent(inst.entity)

	table.insert(inst.followfx, fx)
	table.insert(inst.highlightchildren, fx)

	return fx
end

local function OnAddColourChanged(inst, r, g, b, a)
	for i, v in ipairs(inst.followfx) do
		v.AnimState:SetAddColour(r, g, b, a)
	end
end

local function SwapAnim(fx, from, to)
	if fx.AnimState:IsCurrentAnimation(from) then
		local t = fx.AnimState:GetCurrentAnimationTime()
		fx.AnimState:PlayAnimation(to)
		fx.AnimState:SetTime(t)
	end
end

local function OnFacings(inst)
	local facings = inst.facings:value()
	local fxfr = inst.followfx[2]
	local fxbk = inst.followfx[3]
	if facings == 1 then
		fxfr.Transform:SetEightFaced()
		fxbk.Transform:SetEightFaced()
	else
		fxfr.Transform:SetFourFaced()
		fxbk.Transform:SetFourFaced()
	end
	if facings == 2 then
		SwapAnim(fxfr, "float_fr_loop", "float_fr_loop_nofaced")
		SwapAnim(fxbk, "float_bk_loop", "float_bk_loop_nofaced")
	else
		SwapAnim(fxfr, "float_fr_loop_nofaced", "float_fr_loop")
		SwapAnim(fxbk, "float_bk_loop_nofaced", "float_bk_loop")
	end
end

local function SwitchToEightFaced(inst)
	if inst.facings:value() ~= 1 then
		inst.facings:set(1)
		if inst.followfx then
			OnFacings(inst)
		end
		inst.Transform:SetEightFaced()
	end
end

local function SwitchToFourFaced(inst)
	local old = inst.facings:value()
	if old ~= 0 then
		inst.facings:set(0)
		if inst.followfx then
			OnFacings(inst)
		end
		if old == 1 then
			inst.Transform:SetFourFaced()
		end
	end
end

local function SwitchToNoFaced(inst)
	local old = inst.facings:value()
	if old ~= 2 then
		inst.facings:set(2)
		if inst.followfx then
			OnFacings(inst)
		end
		if old == 1 then
			inst.Transform:SetFourFaced()
		end
	end
end

local function InitCheckSpawnBuild(inst)
	inst.inittask = nil
	if inst.sg.mem.hasspawnbuild and inst.sg.currentstate.name ~= "spawn" then
		inst.sg.mem.hasspawnbuild = nil
		--More optimal to clear this config if we're not using "spawn" state again.
		inst.AnimState:Show("robot_front")
		inst.AnimState:Show("robot_back")
		inst.AnimState:ClearOverrideSymbol("splat_liquid")
		inst.AnimState:SetFinalOffset(-1)

		inst.SoundEmitter:PlaySound("rifts5/lunar_boss/idle_a_LP", "idlea")
		inst.SoundEmitter:PlaySound("rifts5/lunar_boss/idle_b_LP", "idleb")

		TheWorld:PushEvent("ms_register_wagpunk_arena_lunacycreator", inst)
	end
end

local function OnDeath(inst)
    TheWorld:PushEvent("ms_wagboss_alter_defeated", inst)
end

--------------------------------------------------------------------------

local PHASES =
{
	{
		hp = 1,
		fn = function(inst)
			inst.dashcombo = 1
			inst.dashcount = inst.dashcount or 0
			inst.dashrnd = false
			inst.slamcombo = nil
			inst.slamrnd = false
			inst.cansupernova = false
		end,
	},
	{
		hp = 0.9,
		fn = function(inst)
			inst.dashcombo = 2
			inst.dashcount = inst.dashcount or 0
			inst.dashrnd = false
			inst.slamcombo = 1
			inst.slamcount = inst.slamcount or 0
			inst.slamrnd = false
			inst.cansupernova = false
		end,
	},
	{
		hp = 0.7,
		fn = function(inst)
			inst.dashcombo = 2
			inst.dashcount = inst.dashcount or 0
			inst.dashrnd = true
			inst.slamcombo = 1
			inst.slamcount = inst.slamcount or 0
			inst.slamrnd = false
			inst.cansupernova = false
		end,
	},
	{
		hp = 0.5,
		fn = function(inst)
			inst.dashcombo = 2
			inst.dashcount = inst.dashcount or 0
			inst.dashrnd = true
			inst.slamcombo = 2
			inst.slamcount = inst.slamcount or 0
			inst.slamrnd = true
			inst.cansupernova = true
		end,
	},
}

--------------------------------------------------------------------------

local function UpdatePlayerTargets(inst)
	assert(next(inst._temptbl1) == nil and next(inst._temptbl2) == nil)
	local toadd = inst._temptbl1
	local toremove = inst._temptbl2
	local x, y, z = inst.Transform:GetWorldPosition()

	for k in pairs(inst.components.grouptargeter:GetTargets()) do
		toremove[k] = true
	end

	local map = TheWorld.Map
	if map:IsPointInWagPunkArena(x, y, z) then
		for i, v in ipairs(AllPlayers) do
			if not (v.components.health:IsDead() or v:HasTag("playerghost")) and
				v.entity:IsVisible() and
				map:IsPointInWagPunkArena(v.Transform:GetWorldPosition())
			then
				if toremove[v] then
					toremove[v] = nil
				else
					table.insert(toadd, v)
				end
			end
		end
	else
		for i, v in ipairs(FindPlayersInRange(x, y, z, TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_DEAGGRO_DIST, true)) do
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
	UpdatePlayerTargets(inst)

	local x, y, z = inst.Transform:GetWorldPosition()
	local target = inst.components.combat.target
	local inrange
	if target then
		local range = TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_ATTACK_RANGE + target:GetPhysicsRadius(0)
		local dsq = target:GetDistanceSqToPoint(x, y, z)
		inrange = dsq < range * range

		if target.isplayer then
			if inst:IsSlamNext() and (inrange or dsq < TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_KEEP_AGGRO_DIST * TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_KEEP_AGGRO_DIST) then
				return --don't switch player targets when we're about to slam
			end
			local newplayer = inst.components.grouptargeter:TryGetNewTarget()
			if newplayer then
				range = inrange and TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_ATTACK_RANGE + newplayer:GetPhysicsRadius(0) or TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_KEEP_AGGRO_DIST
				if newplayer:GetDistanceSqToPoint(x, y, z) < range * range then
					return newplayer, true
				end
			end
			return
		end
	end

	assert(next(inst._temptbl1) == nil)
	local nearplayers = inst._temptbl1
	for k in pairs(inst.components.grouptargeter:GetTargets()) do
		local range = inrange and TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_ATTACK_RANGE + k:GetPhysicsRadius(0) or TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_AGGRO_DIST
		if k:GetDistanceSqToPoint(x, y, z) < range * range then
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
	end
	local x, y, z = inst.Transform:GetWorldPosition()
	local x1, y1, z1 = target.Transform:GetWorldPosition()
	local map = TheWorld.Map
	if map:IsPointInWagPunkArena(x, y, z) then
		return map:IsPointInWagPunkArena(x1, y1, z1)
	end
	return distsq(x, z, x1, z1) < TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_DEAGGRO_DIST * TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_DEAGGRO_DIST
end

local function OnAttacked(inst, data)
	if data and data.attacker then
		local target = inst.components.combat.target
		if not (target and
				target.isplayer and
				target:IsNear(inst,
					inst:IsSlamNext() and
					TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_KEEP_AGGRO_DIST or
					TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_ATTACK_RANGE + target:GetPhysicsRadius(0))
				)
		then
			inst.components.combat:SetTarget(data.attacker)
		end
	end
end

local function ResetCombo(inst)
	inst.dashcount = inst.dashcount and 0 or nil
	inst.slamcount = inst.slamcount and 0 or nil
end

local function IsSlamNext(inst)
	return inst.dashcombo and inst.dashcount >= inst.dashcombo
		and inst.slamcombo and inst.slamcount < inst.slamcombo
end

local function SetEngaged(inst, engaged, delay)
	if delay then
		if inst._engagetask == nil or inst._engagetask ~= engaged then
			if inst._engagetask then
				inst._engagetask:Cancel()
			end
			inst._engagetask = inst:DoTaskInTime(delay, SetEngaged, engaged)
			inst._engagetask.engaged = engaged
		end
	else
		if inst._engagetask then
			inst._engagetask:Cancel()
			inst._engagetask = nil
		end
		if inst.engaged ~= engaged then
			inst.engaged = engaged
			ResetCombo(inst)

			if not engaged then
				inst:PushEvent("resetboss")
				inst.components.health:SetPercent(1)
			end

			--#TEMP_BETA
			if engaged and not POPULATING and TheWorld.Map:IsPointInWagPunkArenaAndBarrierIsUp(inst.Transform:GetWorldPosition()) then
				inst.battlestarttime = GetTime()
			else
				inst.battlestarttime = nil
			end
		end
	end
end

local function OnNewTarget(inst, data)
	if data and data.target then
		SetEngaged(inst, true)
	end
end

local function OnDroppedTarget(inst)--, data)
	SetEngaged(inst, false, 10)
end

local function OnSave(inst, data)
	data.engaged = inst.engaged or nil
end

local function OnLoad(inst, data)--, ents)
	if inst.inittask then
		inst.inittask:Cancel()
		InitCheckSpawnBuild(inst)
	end
	local healthpct = inst.components.health:GetPercent()
	for i = #PHASES, 2, -1 do
		local v = PHASES[i]
		if healthpct <= v.hp then
			v.fn(inst)
			break
		end
	end
	if data and data.engaged and not inst.engaged then
		SetEngaged(inst, true)
		SetEngaged(inst, false, 10)
	end
end

--------------------------------------------------------------------------

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.Transform:SetFourFaced()

	inst.AnimState:SetBank("wagboss_lunar")
	inst.AnimState:SetBuild("wagboss_lunar")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetMultColour(1, 1, 1, TRANSPARENCY)
	inst.AnimState:UsePointFiltering(true)
	inst.AnimState:Hide("robot_front")
	inst.AnimState:Hide("robot_back")
	inst.AnimState:OverrideSymbol("splat_liquid", "wagboss_lunar_spawn", "splat_liquid")
	inst.AnimState:SetFinalOffset(-2)
	inst.AnimState:SetLightOverride(LIGHTOVERRIDE)

	MakeGiantCharacterPhysics(inst, 1000, 2)
	inst.Physics:SetCollisionMask(COLLISION.WORLD)

	inst:AddTag("brightmareboss")
	inst:AddTag("epic")
	inst:AddTag("hostile")
	inst:AddTag("largecreature")
	inst:AddTag("mech")
	inst:AddTag("monster")
	inst:AddTag("noepicmusic")
	inst:AddTag("scarytoprey")
	inst:AddTag("soulless")
	inst:AddTag("lunar_aligned")

	--rainimmunity (from rainimmunity component) added to pristine state for optimization
	inst:AddTag("rainimmunity")

	inst:AddComponent("colouraddersync")

	inst.showdashfx = net_bool(inst.GUID, "alterguardian_phase4_lunarrift.showdashfx", "showdashfxdirty")
	inst.facings = net_tinybyte(inst.GUID, "alterguardian_phase4_lunarrift.facings", "facingsdirty")

	--Dedicated server does not need to spawn the local fx
	if not TheNet:IsDedicated() then
		inst.followfx = {}
		inst.highlightchildren = {}

		--body wires and floating bits (solid)
		AddFollowFx(inst, "wire_loop", "lb_wire_follow", nil, nil, false)
		AddFollowFx(inst, "float_fr_loop", "lb_float_fr_follow", nil, nil, true)
		AddFollowFx(inst, "float_bk_loop", "lb_float_bk_follow", nil, nil, true)

		--leg wires (solid)
		for i = 1, 2 do
			AddFollowFx(inst, "leg_wire", "lb_leg_wire_follow", i, nil, false)
		end
		AddFollowFx(inst, "leg_wire", "lb_leg_wire_follow", 22, nil, false)
		local tail = AddFollowFx(inst, "tail_wire", "lb_tail_wire_follow", nil, nil, false)
		tail.AnimState:SetSymbolBloom("lb_leg_alpha_ol")
		tail.AnimState:SetSymbolMultColour("lb_leg_alpha_ol", 1, 1, 1, TRANSPARENCY)
		tail.AnimState:SetSymbolLightOverride("lb_leg_alpha_ol", LIGHTOVERRIDE)
		for i = 1, 2 do
			AddFollowFx(inst, "feet_wire", "lb_feet_wire_follow", i, nil, false)
		end

		--body transparent parts
		for i = 1, 4 do
			AddFollowFx(inst, "body_loop", "lb_head_loop_follow_"..tostring(i), nil, TRANSPARENCY, false)
		end
		for i = 1, 3 do
			AddFollowFx(inst, "flame_loop", "lb_flame_loop_follow_"..tostring(i), nil, TRANSPARENCY, false)
		end

		inst.components.colouraddersync:SetColourChangedFn(OnAddColourChanged)
	end

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:ListenForEvent("facingsdirty", OnFacings)
		inst:ListenForEvent("showdashfxdirty", OnShowDashFx)

		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("rainimmunity")
	inst.components.rainimmunity:AddSource(inst)

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_HEALTH)
	inst.components.health.nofadeout = true

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_DAMAGE)
	inst.components.combat:SetAttackPeriod(TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_ATTACK_PERIOD)
	inst.components.combat:SetRange(TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_ATTACK_RANGE)
	inst.components.combat:SetRetargetFunction(1, RetargetFn)
	inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
	inst.components.combat.playerdamagepercent = TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_PLAYERDAMAGEPERCENT
	inst.components.combat.hiteffectsymbol = "lb_head_loop_follow_4"
	inst.components.combat.battlecryenabled = false

	inst:AddComponent("healthtrigger")
	for i, v in ipairs(PHASES) do
		inst.components.healthtrigger:AddTrigger(v.hp, v.fn)
	end
	PHASES[1].fn(inst)

	inst:AddComponent("planarentity")
	inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_PLANAR_DAMAGE)

	inst:AddComponent("timer")
	inst:AddComponent("grouptargeter")

	inst:AddComponent("locomotor")
	inst.components.locomotor.walkspeed = TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_WALKSPEED

	inst:AddComponent("colouradder")

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("alterguardian_phase4_lunarrift")
	inst.components.lootdropper.min_speed = 1
	inst.components.lootdropper.max_speed = 3
	inst.components.lootdropper.y_speed = 14
	inst.components.lootdropper.y_speed_variance = 4
	inst.components.lootdropper.spawn_loot_inside_prefab = true

	inst:AddComponent("teleportedoverride")
	inst.components.teleportedoverride:SetDestPositionFn(teleport_override_fn)

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("newcombattarget", OnNewTarget)
	inst:ListenForEvent("droppedtarget", OnDroppedTarget)

	inst._engagetask = nil
	inst.engaged = false

	inst:SetStateGraph("SGalterguardian_phase4_lunarrift")
	inst:SetBrain(brain)

	inst._temptbl1 = {}
	inst._temptbl2 = {}

	inst.sg.mem.hasspawnbuild = true
	inst.inittask = inst:DoTaskInTime(0, InitCheckSpawnBuild)

	inst.SwitchToEightFaced = SwitchToEightFaced
	inst.SwitchToFourFaced = SwitchToFourFaced
	inst.SwitchToNoFaced = SwitchToNoFaced
	inst.StartDashFx = StartDashFx
	inst.StopDashFx = StopDashFx
	inst.ResetCombo = ResetCombo
	inst.IsSlamNext = IsSlamNext
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

    inst:ListenForEvent("death", OnDeath)

	return inst
end

--------------------------------------------------------------------------

local function slamfx_CreateGroundFx()
	local fx = CreateEntity()

	fx:AddTag("FX")
	fx:AddTag("NOCLICK")
	--[[Non-networked entity]]
	--fx.entity:SetCanSleep(false)
	fx.persists = false

	fx.entity:AddTransform()
	fx.entity:AddAnimState()

	fx.AnimState:SetBank("wagboss_robot")
	fx.AnimState:SetBuild("wagboss_robot")
	fx.AnimState:PlayAnimation("atk_ground_projection")
	fx.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	fx.AnimState:SetLayer(LAYER_BACKGROUND)
	fx.AnimState:SetSortOrder(3)
	fx.AnimState:SetMultColour(1, 1, 1, TRANSPARENCY)
	fx.AnimState:SetLightOverride(LIGHTOVERRIDE)

	--robot stomp radius 3.3
	--our slam radius 5
	local scale = 5 / 3.3
	fx.AnimState:SetScale(scale, scale)

	return fx
end

local function slamfx_CancelPostUpdate_Client(inst, slamfx_PostUpdate_Client)
	inst._cancelpostupdatetask = nil
	inst.components.updatelooper:RemovePostUpdateFn(slamfx_PostUpdate_Client)
end

local function slamfx_PostUpdate_Client(inst)
	if inst._cancelpostupdatetask == nil then
		inst._cancelpostupdatetask = inst:DoStaticTaskInTime(0, slamfx_CancelPostUpdate_Client, slamfx_PostUpdate_Client)
		inst.ring.AnimState:SetTime(inst.AnimState:GetCurrentAnimationTime())
	end
end

local function slamfxfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("bomb_lunarplant")
	inst.AnimState:SetBuild("bomb_lunarplant")
	inst.AnimState:PlayAnimation("used")
	inst.AnimState:Hide("bomb")
	inst.AnimState:OverrideSymbol("sleepcloud_pre", "sleepcloud", "sleepcloud_pre")
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetMultColour(1, 1, 1, TRANSPARENCY)
	inst.AnimState:SetAddColour(1, 1, 1, 0)
	inst.AnimState:UsePointFiltering(true)
	inst.AnimState:SetScale(2, 2)
	inst.AnimState:SetLightOverride(LIGHTOVERRIDE)

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	if not TheNet:IsDedicated() then
		inst.ring = slamfx_CreateGroundFx()
		inst.ring.entity:SetParent(inst.entity)
	end

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:AddComponent("updatelooper")
		inst.components.updatelooper:AddPostUpdateFn(slamfx_PostUpdate_Client)

		return inst
	end

	inst:ListenForEvent("animover", inst.Remove)
	inst.persists = false

	return inst
end

--------------------------------------------------------------------------

local function eruptfxfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("wagboss_lunar_blast")
	inst.AnimState:SetBuild("wagboss_lunar_blast")
	inst.AnimState:PlayAnimation("blast_01")
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetMultColour(1, 1, 1, TRANSPARENCY * 2)
	inst.AnimState:SetLightOverride(LIGHTOVERRIDE)

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	if math.random() < 0.5 then
		inst.AnimState:PlayAnimation("blast_02")
	end

	inst:ListenForEvent("animover", inst.Remove)
	inst.persists = false

	return inst
end

--------------------------------------------------------------------------

return Prefab("alterguardian_phase4_lunarrift", fn, assets, prefabs),
	Prefab("alterguardian_phase4_lunarrift_slam_fx", slamfxfn, assets_slamfx),
	Prefab("alterguardian_phase4_lunarrift_erupt_fx", eruptfxfn, assets_erruptfx)
