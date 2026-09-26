require("stategraphs/commonstates")
local AOEUtil = require("aoeutil")
local HitBox = require("util/hitbox")
local easing = require("easing")

local _dbg_draw = BRANCH == "dev"

local function ChooseAttack(inst, target)
	target = target or inst.components.combat.target
	if target and target:IsValid() then
		local shouldopticblast = inst.canopticblast and not inst.components.timer:TimerExists("opticblastcd")

		if inst.canteleport and inst:IsInArena() then
			local x, _, z = inst.Transform:GetWorldPosition()
			local theta = inst.Transform:GetRotation() * DEGREES
			if not TheWorld.Map:IsValidTileAtPoint(x + 10 * math.cos(theta), 0, z - 10 * math.sin(theta)) then
				--too close to edge

				if shouldopticblast then
					inst.sg:GoToState("optic_blast_pre", target)
					return true
				end

				local home = inst.components.knownlocations:GetLocation("spawnpoint")
				if home and (x ~= home.x or z ~= home.z) then
					theta = math.atan2(z - home.z, home.x - x)
					theta = theta - PI / 12 + math.random() * PI / 6
					local dist = 8 + 2 * math.random()
					inst.sg:GoToState("teleport_pre", Vector3(x + dist * math.cos(theta), 0, z - dist * math.sin(theta)))
					return true
				end
			end
		end

		if inst.sg.mem.forcetaunt then
			inst.sg.statemem.keepnofaced = true
			inst.sg:GoToState("taunt")
			return true
		end

		if inst.sg.mem.horns_stocked then
			if inst.cansummonhorns then
				inst.sg:GoToState("attack", target)
				return true
			end
			inst.sg.mem.horns_stocked = nil
		end

		if inst.cansummonhorns and
			GetTime() > (inst.components.combat.nextbattlecrytime or 0) and
			math.random() < 0.667
		then
			inst.components.combat:ResetBattleCryCooldown()
			inst.sg.statemem.keepnofaced = true
			inst.sg:GoToState("taunt")
			return true
		end

		if shouldopticblast then
			inst.sg.statemem.keepnofaced = true
			inst.sg:GoToState("optic_blast_pre", target)
			return true
		end

		if inst.canteleport and not inst.components.timer:TimerExists("teleportcd") then
			inst.sg:GoToState("teleport_pre", target)
			return true
		end

		inst.sg:GoToState("attack", target)
		return true
	end
	return false
end

local events =
{
	CommonHandlers.OnLocomote(false, true),
	CommonHandlers.OnAttacked(nil, math.huge), --hit delay only for projectiles
	EventHandler("death", function(inst)
		if not inst.sg:HasStateTag("nointerrupt") then
			inst.sg:GoToState("death")
		end
	end),
	EventHandler("doattack", function(inst, data)
		if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy")) then
			ChooseAttack(inst, data and data.target)
		end
	end),
}

local function DoRoarShake(inst)
	ShakeAllCameras(CAMERASHAKE.FULL, 2, 0.035, 0.1, inst, 40)
end

--Keep 6-faced in Transform component; anim with no facings will behave like 2-faced.
local function SwitchToNoFaced(inst)
	if inst.sg.mem.facings == 8 then
		inst.Transform:SetSixFaced()
	end
	inst.sg.mem.facings = 0
end

local function SwitchToEightFaced(inst)
	if inst.sg.mem.facings ~= 8 then
		inst.sg.mem.facings = 8
		inst.Transform:SetEightFaced()
	end
end

local function TryRestoreSixFaced(inst)
	if inst.sg.mem.facings == 0 then
		if not inst.sg.statemem.keepnofaced then
			inst.sg.mem.facings = 6
		end
	elseif inst.sg.mem.facings == 8 then
		if not inst.sg.statemem.keepeightfaced then
			inst.Transform:SetSixFaced()
			inst.sg.mem.facings = 6
		end
	end
end

local function SetClickable(inst, clickable)
	if clickable then
		inst:RemoveTag("NOCLICK")
		inst.Light:Enable(true)
	else
		inst:AddTag("NOCLICK")
		inst.Light:Enable(false)
	end
end

local _temp_aoe_params =
{
	attack_filterfn = function(target, inst)
		return inst:IsInArena() == TheWorld.Map:IsPointInCharlieBossArena(target.Transform:GetWorldPosition())
	end,
}
local function GetAOEParams(dist, radius, arc, knockback_str, knockback_heavystr, knockback_forcelanded, hitbox)
	_temp_aoe_params.dist = dist
	_temp_aoe_params.radius = radius
	_temp_aoe_params.arc = arc
	_temp_aoe_params.hitbox = hitbox
	_temp_aoe_params.knockback_str = knockback_str
	_temp_aoe_params.knockback_heavystr = knockback_heavystr
	_temp_aoe_params.knockback_forcelanded = knockback_forcelanded
	return _temp_aoe_params
end

local _temp_toss_params = { startheight = 0.5 }
local function GetTossParams(radius, strmult)
	_temp_toss_params.radius = radius
	_temp_toss_params.basespeed = radius * 0.4 * (strmult or 1)
	_temp_toss_params.verticalspeed = (_temp_toss_params.basespeed + 0.5) * 2.5
	--_temp_toss_params.startradius = radius
	return _temp_toss_params
end

local function SnapTo45s(angle)
	return math.floor(angle / 45 + 0.5) * 45
end

local PORTAL_DIST = 5.7
local PORTAL_RADIUS = 3.5

local function DoPortalSummon(inst, prefab, dir, targets)
	local x, _, z = inst.Transform:GetWorldPosition()
	local minangle = 45
	local target
	for k in pairs(inst.components.grouptargeter:GetTargets()) do
		if not targets[k] and k:IsValid() and not IsEntityDeadOrGhost(k) then
			local x1, _, z1 = k.Transform:GetWorldPosition()
			local dx = x1 - x
			local dz = z1 - z
			if inst:IsInArena() == TheWorld.Map:IsPointInCharlieBossArena(x1, 0, z1) then
				local range = PORTAL_DIST + 12
				if dx * dx + dz * dz < range * range then
					local diff = DiffAngle(dir, math.atan2(-dz, dx) * RADIANS)
					if diff < minangle then
						minangle = diff
						target = k
					end
				end
			end
		end
	end

	if target then
		targets[target] = true
	end

	local theta = dir * DEGREES
	local cos_theta = math.cos(theta)
	local sin_theta = math.sin(theta)
	local minion = SpawnPrefab(prefab)
	minion.Transform:SetPosition(x + PORTAL_DIST * cos_theta, 0, z - PORTAL_DIST * sin_theta)
	minion.Transform:SetRotation(dir)
	minion:OnShroudenSummon(inst, target)
end

local states =
{
	State{
		name = "idle",
		tags = { "idle", "canrotate" },

		onenter = function(inst, pushanim)
			if inst.sg.mem.forcetaunt then
				inst.sg.statemem.keepnofaced = true
				inst.sg:GoToState("taunt")
				return
			end

			inst.components.locomotor:Stop()

			if pushanim and not inst.AnimState:AnimDone() then
				inst.sg.statemem.pushanim = true
			else
				local anim = inst.sg.mem.facings == 0 and "idle_nofaced" or "idle"
				if not inst.AnimState:IsCurrentAnimation(anim) or inst.AnimState:AnimDone() then
					inst.AnimState:PlayAnimation(anim, true)
				end
				inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
			end
		end,

		events =
		{
			--NOTE: we may be have several anims still queued
			EventHandler("animqueueover", function(inst)
				if inst.sg.statemem.pushanim and inst.AnimState:AnimDone() then
					inst.sg.statemem.keepnofaced = true
					inst.sg.statemem.keepeightfaced = true
					inst.sg:GoToState("idle")
				end
			end),
		},

		ontimeout = function(inst)
			inst.sg:GoToState("idle")
		end,

		onexit = TryRestoreSixFaced,
	},

	State{
		name = "spawn",
		tags = { "busy", "noattack", "invisible", "temp_invincible", "nointerrupt" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.Physics:SetActive(false)
			inst:Hide()
			SetClickable(inst, false)
			inst.sg.statemem.changearena = true -- for save/load
		end,

		timeline =
		{
			--#SFX
			TimeEvent(3, function(inst) inst.SoundEmitter:PlaySound("rifts8/shrouden/spawn") end),

			--#TEMP #TODO
			TimeEvent(3, function(inst)
				inst:SetCameraFocusEnabled(true)
				inst.sg.statemem.changearena = false
				inst:PushEvent("ms_charliearena_becomeunstable")
			end),
			TimeEvent(5, function(inst)
				inst.sg.statemem.spawning = true
				inst.sg:GoToState("teleport_pst")
			end),
		},

		onexit = function(inst)
			inst.Physics:SetActive(true)
			inst:Show()
			inst:SetMusicEnabled(inst.components.health:IsDead() or inst.components.combat:HasTarget())
			if not inst.sg.statemem.spawning then
				SetClickable(inst, true)
				inst:SetCameraFocusEnabled(false)
			end
		end,
	},

	State{
		name = "taunt",
		tags = { "busy" },

		onenter = function(inst, quick)
			inst.components.locomotor:Stop()
			SwitchToNoFaced(inst)
			local target = inst.components.combat.target
			if target then
				inst:ForceFacePoint(target.Transform:GetWorldPosition())
			end
			inst.AnimState:PlayAnimation("taunt_pre")

			if inst.sg.mem.forcetaunt then
				inst.sg.mem.forcetaunt = nil
				inst.components.combat:ResetBattleCryCooldown()
			elseif quick then
				inst.sg.statemem.quick = true
			end

			if not inst.cansummonhorns then
				inst.components.combat.battlecryenabled = false
			end
		end,

		timeline =
		{
			--#SFX
			--FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("rifts8/charlie/hit") end),

			FrameEvent(29, function(inst)
				inst.sg.mem.forcetaunt = nil
				DoRoarShake(inst)
				inst.components.epicscare:Scare(10)
				if inst.cansummonhorns and not inst.sg.statemem.quick then
					inst.sg.mem.horns_stocked = true
				end
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg.statemem.keepnofaced = true
					inst.sg:GoToState(inst.sg.statemem.quick and "taunt_pst" or "taunt_loop")
				end
			end),
		},

		onexit = TryRestoreSixFaced,
	},

	State{
		name = "taunt_loop",
		tags = { "busy" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			SwitchToNoFaced(inst)
			inst.AnimState:PlayAnimation("taunt_loop")
		end,

		timeline =
		{
			--#SFX
			--FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("rifts8/charlie/hit") end),

			FrameEvent(27, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg.statemem.keepnofaced = true
					inst.sg:GoToState("taunt_pst")
				end
			end),
		},

		onexit = TryRestoreSixFaced,
	},

	State{
		name = "taunt_pst",
		tags = { "busy" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			SwitchToNoFaced(inst)
			inst.AnimState:PlayAnimation("taunt_pst")

			if inst.sg.lasttags["caninterrupt"] then
				inst.sg:AddStateTag("caninterrupt")
			end
		end,

		timeline =
		{
			--#SFX
			--FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("rifts8/charlie/hit") end),

			FrameEvent(12, function(inst)
				if inst.sg.mem.horns_stocked and
					not inst.components.combat:InCooldown() and
					ChooseAttack(inst)
				then
					return
				end
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(16, function(inst)
				inst.sg:AddStateTag("canrotate")
			end),
			FrameEvent(19, function(inst)
				inst.sg.statemem.keepnofaced = true
				inst.sg:GoToState("idle", true)
			end),
		},

		onexit = TryRestoreSixFaced,
	},

	State{
		name = "hit",
		tags = { "hit", "busy" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("hit")
			CommonHandlers.UpdateHitRecoveryDelay(inst)
		end,

		timeline =
		{
			--#SFX
			--FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("rifts8/charlie/hit") end),

			FrameEvent(8, function(inst)
				if inst.sg.statemem.doattack then
					if inst.sg.statemem.doattack:IsValid() then
						return
					end
					inst.sg.statemem.doattack = nil
				end
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(10, function(inst)
				if inst.sg.mem.forcetaunt then
					inst.sg:GoToState("taunt")
					return
				elseif inst.sg.statemem.doattack and ChooseAttack(inst, inst.sg.statemem.doattack) then
					return
				end
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events =
		{
			EventHandler("doattack", function(inst, data)
				if inst.sg:HasStateTag("busy") and data and data.target and data.target:IsValid() then
					inst.sg.statemem.doattack = data.target
					inst.sg:RemoveStateTag("caninterrupt")
					return true
				end
			end),
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},
	},

	State{
		name = "death",
		tags = { "dead", "busy", "nointerrupt" },

		onenter = function(inst)
			if inst.looted then
				inst.sg.statemem.keepnofaced = true
				inst.sg:GoToState("death_after_loot")
				return
			end
			inst.components.locomotor:Stop()
			SwitchToNoFaced(inst)
			inst.AnimState:PlayAnimation("death")
			inst:SetCameraFocusEnabled(true)
		end,

		timeline =
		{
			--#SFX
			--FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("rifts8/charlie/hit") end),

			FrameEvent(71, function(inst)
				inst:DropDeathLoot()
				inst.looted = true
			end),
			FrameEvent(91, function(inst)
				inst.sg:AddStateTag("noattack")
				ToggleOffAllObjectCollisions(inst)
				inst:SetGelEnabled(true)
			end),
			FrameEvent(94, function(inst)
				inst.AnimState:SetSortOrder(-1)
				SetClickable(inst, false)
			end),
			FrameEvent(99, function(inst)
				inst.sg.statemem.keepnofaced = true
				inst.sg.statemem.death = true
				inst.sg:GoToState("death_after_loot")
			end),
		},

		onexit = function(inst)
			TryRestoreSixFaced(inst)
			if not inst.sg.statemem.death then
				inst.AnimState:SetSortOrder(0)
				inst:SetCameraFocusEnabled(false)
				SetClickable(inst, true)
				inst:SetGelEnabled(false)
				if inst.sg.mem.isobstaclepassthrough then
					local x, _, z = inst.Transform:GetWorldPosition()
					ToggleOnAllObjectCollisionsAt(inst, x, z)
				end
			end
		end,
	},

	State{
		name = "death_after_loot",
		tags = { "death", "busy", "nointerrupt", "noattack" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			SwitchToNoFaced(inst)
			if not inst.AnimState:IsCurrentAnimation("death") and inst.sg.lasttags["dead"] then
				inst.AnimState:PlayAnimation("death")
				inst.AnimState:SetFrame(99)
			end
			inst.AnimState:SetSortOrder(-1)
			inst:SetCameraFocusEnabled(true)
			SetClickable(inst, false)
			inst:SetGelEnabled(true)
			ToggleOffAllObjectCollisions(inst)
			inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() - inst.AnimState:GetCurrentAnimationTime() + 0.6)
		end,

		timeline =
		{
			--#SFX
			--FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("rifts8/charlie/hit") end),

			FrameEvent(126 - 99, function(inst)
				inst:SetGelEnabled(false)
				inst.Physics:SetActive(false)
			end),
		},

		ontimeout = function(inst)
			if inst:IsInArena() then
				inst:PushEvent("ms_charlie_boss_defeated")
			end
			inst:Remove()
		end,

		onexit = function(inst)
			TryRestoreSixFaced(inst)
			inst.AnimState:SetSortOrder(0)
			inst:SetCameraFocusEnabled(false)
			SetClickable(inst, true)
			inst:SetGelEnabled(false)
			if inst.sg.mem.isobstaclepassthrough then
				local x, _, z = inst.Transform:GetWorldPosition()
				ToggleOnAllObjectCollisionsAt(inst, x, z)
			end
		end,
	},

	State{
		name = "attack",
		tags = { "attack", "busy" },

		onenter = function(inst, target)
			inst.components.locomotor:Stop()
			inst.components.combat:StartAttack()
			SwitchToEightFaced(inst)

			if target and target:IsValid() then
				inst.sg.statemem.target = target
				inst.sg.statemem.rot = inst:GetAngleToPoint(target.Transform:GetWorldPosition())
				inst.Transform:SetRotation(SnapTo45s(inst.sg.statemem.rot))
			else
				inst.Transform:SetRotation(SnapTo45s(inst.Transform:GetRotation()))
			end
			inst.AnimState:PlayAnimation("punch_pre")
		end,

		onupdate = function(inst, dt)
			if dt > 0 then
				local target = inst.sg.statemem.target
				if target then
					if target:IsValid() then
						local lastdrot = inst.sg.statemem.drot
						if lastdrot ~= 0 then
							local rot = inst.sg.statemem.rot
							local rot1 = inst:GetAngleToPoint(target.Transform:GetWorldPosition())
							local drot = ReduceAngle(rot1 - rot) * 0.5
							local maxdrot = 10

							drot = math.clamp(drot, -maxdrot, maxdrot)
							if lastdrot then
								drot = math.clamp(drot, math.min(0, lastdrot), math.max(0, lastdrot))
							end

							inst.sg.statemem.rot = rot + drot
							inst.sg.statemem.lastdrot = drot

							inst.Transform:SetRotation(SnapTo45s(inst.sg.statemem.rot))
						end
					else
						inst.sg.statemem.target = nil
					end
				end
			end
		end,

		timeline =
		{
			--#SFX
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("rifts8/shrouden/portal_punch_pre") end),

			FrameEvent(4, function(inst)
				inst.sg.statemem.target = nil --stop tracking
				inst:SetPortalOpen(true)
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg.statemem.keepeightfaced = true
					inst.sg.statemem.attacking = true
					inst.sg:GoToState("attack_loop")
				end
			end),
		},

		onexit = function(inst)
			TryRestoreSixFaced(inst)
			if not inst.sg.statemem.attacking then
				inst:SetPortalOpen(false)
			end
		end,
	},

	State{
		name = "attack_loop",
		tags = { "attack", "busy" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.components.combat:RestartCooldown()
			SwitchToEightFaced(inst)

			if not inst.AnimState:IsCurrentAnimation("punch_loop") then
				inst.AnimState:PlayAnimation("punch_loop", true)
			end
			inst:SetPortalOpen(true)

			inst.SoundEmitter:PlaySound("rifts8/shrouden/portal_punch_LP", "portal_loop")

			inst.sg:SetTimeout(1)

			local len = PORTAL_DIST + 0.3
			local hitbox = inst.sg.mem.attack_hitbox
			if hitbox == nil then
				hitbox = HitBox(inst)
				inst.sg.mem.attack_hitbox = hitbox

				hitbox:AddRectangle(0, -PORTAL_RADIUS, len, PORTAL_RADIUS)
			end

			len = len / 2
			inst.sg.statemem.aoeparams = GetAOEParams(len, math.sqrt(len * len + PORTAL_RADIUS * PORTAL_RADIUS), nil, 1.5, 1.25, true, hitbox)
			inst.sg.statemem.targets = {}

			if _dbg_draw then
				hitbox:DebugDraw()
			end
		end,

		onupdate = function(inst, dt)
			if dt > 0 then
				AOEUtil.Attack(inst, inst.sg.statemem.aoeparams, inst:GetAOEAttackTagSet(), inst.sg.statemem.targets, 0.35)
			end
		end,

		timeline =
		{
			FrameEvent(0, function(inst)
				inst.sg.statemem.summontargets = {}
				if inst.sg.mem.horns_stocked then
					inst.sg.mem.horns_stocked = false
					inst.sg.statemem.summonprefab = "shadowthrall_horns"
				else
					local summons = inst.sg.mem.summons
					if summons == nil then
						summons = {}
						table.insert(summons, math.random(#summons + 1), "shadowthrall_wings")
						--table.insert(summons, math.random(#summons + 1), "shadowthrall_hands")
						--table.insert(summons, math.random(#summons + 1), "shadowthrall_mouth")
						inst.sg.mem.summons = summons
					end
					local rnd = math.random(#summons)
					if rnd == #summons then
						rnd = 1 --exclude last picked, double chance for oldest
					end
					inst.sg.statemem.summonprefab = table.remove(summons, rnd)
					table.insert(summons, inst.sg.statemem.summonprefab)
				end
				DoPortalSummon(inst, inst.sg.statemem.summonprefab, inst.Transform:GetRotation(), inst.sg.statemem.summontargets)
			end),
			FrameEvent(5, function(inst)
				local offs = 25 + 10 * math.random()
				inst.sg.statemem.offsgn = math.random() < 0.5 and -1 or 1
				DoPortalSummon(inst, inst.sg.statemem.summonprefab, inst.Transform:GetRotation() + inst.sg.statemem.offsgn * offs, inst.sg.statemem.summontargets)
			end),
			FrameEvent(8, function(inst)
				local offs = 25 + 10 * math.random()
				DoPortalSummon(inst, inst.sg.statemem.summonprefab, inst.Transform:GetRotation() - inst.sg.statemem.offsgn * offs, inst.sg.statemem.summontargets)
			end),
		},

		ontimeout = function(inst)
			inst.sg.statemem.keepeightfaced = true
			inst.sg.statemem.attacking = true
			inst.sg:GoToState("attack_pst", inst.sg.statemem.quicktaunt)
		end,

		events =
		{
			EventHandler("quicktaunt", function(inst)
				inst.sg.statemem.quicktaunt = true
			end),
		},

		onexit = function(inst)
			inst.SoundEmitter:KillSound("portal_loop")
			TryRestoreSixFaced(inst)
			if not inst.sg.statemem.attacking then
				inst:SetPortalOpen(false)
			end
		end,
	},

	State{
		name = "attack_pst",
		tags = { "attack", "busy" },

		onenter = function(inst, quicktaunt)
			inst.components.locomotor:Stop()
			SwitchToEightFaced(inst)
			inst.AnimState:PlayAnimation("punch_pst")
			inst:SetPortalOpen(true)
			inst.sg.statemem.quicktaunt = quicktaunt
		end,

		timeline =
		{
			--#SFX
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("rifts8/shrouden/portal_punch_pst") end),

			FrameEvent(10, function(inst)
				if inst.sg.statemem.quicktaunt then
					inst.sg:GoToState("taunt", true)
					return
				end
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(21, function(inst)
				inst.sg:RemoveStateTag("busy")
				inst.sg:AddStateTag("canrotate")
			end),
		},

		events =
		{
			EventHandler("quicktaunt", function(inst)
				if inst.sg:HasStateTag("caninterrupt") then
					inst.sg:GoToState("taunt", true)
				else
					inst.sg.statemem.quicktaunt = true
				end
			end),
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg.statemem.keepeightfaced = true
					inst.sg:GoToState("idle")
				end
			end),
		},

		onexit = function(inst)
			inst:SetPortalOpen(false)
		end,
	},

	State{
		name = "teleport_pre",
		tags = { "attack", "busy" },

		onenter = function(inst, target_or_pos)
			inst.components.locomotor:Stop()
			inst.components.combat:StartAttack()

			if EntityScript.is_instance(target_or_pos) then
				if target_or_pos:IsValid() then
					inst.sg.statemem.target_or_pos = target_or_pos
					inst:ForceFacePoint(target_or_pos.Transform:GetWorldPosition())
				end
			elseif target_or_pos then
				inst.sg.statemem.target_or_pos = target_or_pos
				inst:ForceFacePoint(target_or_pos)
				inst.components.combat:ResetCooldown()
			end
			inst.AnimState:PlayAnimation("teleport_pre")
		end,

		timeline =
		{
			--#SFX
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("rifts2/shrouden/teleport_in") end),

			FrameEvent(4, function(inst)
				inst.sg:AddStateTag("nointerrupt")
			end),
			FrameEvent(10, function(inst)
				inst.sg:AddStateTag("noattack")
				SetClickable(inst, false)
			end),
			FrameEvent(12, function(inst)
				inst.sg:AddStateTag("invisible")
			end),
			FrameEvent(13, function(inst)
				ToggleOffAllObjectCollisions(inst)
				inst:SetGelEnabled(true)
			end),
			FrameEvent(16, function(inst)
				--cut to loop and start movement early
				inst.sg.statemem.teleporting = true
				inst.sg:GoToState("teleport_loop", inst.sg.statemem.target_or_pos)
			end),
		},

		onexit = function(inst)
			if not inst.sg.statemem.teleporting then
				SetClickable(inst, true)
				inst:SetGelEnabled(false)
				if inst.sg.mem.isobstaclepassthrough then
					local x, _, z = inst.Transform:GetWorldPosition()
					ToggleOnAllObjectCollisionsAt(inst, x, z)
				end
			end
		end,
	},

	State{
		name = "teleport_loop",
		tags = { "attack", "busy", "nointerrupt", "noattack", "invisible", "jumping" },

		onenter = function(inst, target_or_pos)
			--PUSH anim since we cutting early from teleport_pre
			inst.AnimState:PushAnimation("teleport_loop")
			if inst.AnimState:IsCurrentAnimation("teleport_loop") then
				inst.AnimState:SetSortOrder(-1)
			end

			SetClickable(inst, false)
			ToggleOffAllObjectCollisions(inst)
			inst:SetGelEnabled(true)

			if not EntityScript.is_instance(target_or_pos) then
				inst.sg.statemem.targetpos = target_or_pos
			elseif target_or_pos:IsValid() then
				inst.sg.statemem.target = target_or_pos
			end

			inst.components.timer:StopTimer("teleportcd")
			inst.components.timer:StartTimer("teleportcd", TUNING.SHROUDEN_TELEPORT_CD)
		end,

		onupdate = function(inst, dt)
			if dt > 0 then
				local acceltime = 1
				local deceltime = 0.3
				local arrivedist = 1
				local min_t = 1
				local max_t = 4
				local t2 = max_t - deceltime
				local t = (inst.sg.statemem.t or 0) + dt

				local dist = 0
				local physrad1 = 0
				local x1, _, z1
				if inst.sg.statemem.targetpos then
					acceltime = 0.3
					arrivedist = 2
					min_t = 0.6
					x1, _, z1 = inst.sg.statemem.targetpos:Get()
				elseif inst.sg.statemem.target then
					if inst.sg.statemem.target:IsValid() then
						x1, _, z1 = inst.sg.statemem.target.Transform:GetWorldPosition()
						physrad1 = inst.sg.statemem.target:GetPhysicsRadius(0)
					else
						inst.sg.statemem.target = nil
					end
				end
				if x1 then
					local rot = inst.Transform:GetRotation()
					local x, _, z = inst.Transform:GetWorldPosition()
					local dx = x1 - x
					local dz = z1 - z
					if dx ~= 0 or dz ~= 0 then
						local rot1 = math.atan2(-dz, dx) * RADIANS
						local drot = ReduceAngle(rot1 - rot)
						drot = math.clamp(drot / 2, -10, 10)
						inst.Transform:SetRotation(rot + drot)

						dist = math.sqrt(dx * dx + dz * dz)
						if t > min_t and dist < arrivedist + physrad1 then
							t = math.max(t, t2)
						end
					end
				else
					t = math.max(t, t2 - min_t)
				end

				inst.sg.statemem.t = t

				local speed = inst.sg.statemem.targetpos and 12 or math.min(8, dist * 10)
				if inst.sg.statemem.speed then
					speed = speed * 0.2 + inst.sg.statemem.speed * 0.8
				end
				inst.sg.statemem.speed = speed

				local mult =
					(t < acceltime and easing.inQuad(t, 0, 1, acceltime)) or
					(t <= t2 and 1) or
					(t < max_t and easing.outQuad(t - t2, 1, -1, deceltime)) or
					0
				speed = speed * mult

				if speed ~= 0 then
					inst.Physics:SetMotorVelOverride(speed, 0, 0)
				else
					inst.Physics:ClearMotorVelOverride()
					inst.Physics:Stop()
				end

				if t >= max_t - 4 * FRAMES then
					inst.sg.statemem.teleporting = true
					inst.sg:GoToState("teleport_pst", {
						t = t - t2,
						speed = inst.sg.statemem.speed,
						deceltime = deceltime,
						quickattack = inst.sg.statemem.targetpos ~= nil,
					})
				end
			end
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:IsCurrentAnimation("teleport_loop") then
					inst.AnimState:SetSortOrder(-1)
				end
			end),
		},

		onexit = function(inst)
			if not inst.sg.statemem.teleporting then
				inst.AnimState:SetSortOrder(0)
				SetClickable(inst, true)
				inst:SetGelEnabled(false)
				inst.Physics:ClearMotorVelOverride()
				inst.Physics:Stop()
				if inst.sg.mem.isobstaclepassthrough then
					local x, _, z = inst.Transform:GetWorldPosition()
					ToggleOnAllObjectCollisionsAt(inst, x, z)
				end
			end
		end,
	},

	State{
		name = "teleport_pst",
		tags = { "attack", "busy", "nointerrupt", "noattack", "invisible", "jumping" },

		onenter = function(inst, data)
			inst.components.locomotor:Stop()
			inst.components.combat:RestartCooldown()
			inst.AnimState:PlayAnimation("teleport_pst")

			SetClickable(inst, false)
			ToggleOffAllObjectCollisions(inst)

			if data and data.t and data.speed and data.deceltime then
				inst.sg.statemem.data = data
			else
				inst.sg:RemoveStateTag("jumping")
			end
			inst.sg.statemem.quickattack = data and data.quickattack

			if inst.sg.lasttags["temp_invincible"] then
				inst.sg.statemem.spawning = true
				inst.components.combat:SetDefaultDamage(0)
				inst.components.planardamage:SetBaseDamage(0)
			end
		end,

		onupdate = function(inst, dt)
			if dt > 0 then
				local data = inst.sg.statemem.data
				if data then
					data.t = data.t + dt
					local speed = data.t < data.deceltime and data.speed * easing.outQuad(data.t, 1, -1, data.deceltime) or 0
					if speed ~= 0 then
						inst.Physics:SetMotorVelOverride(speed, 0, 0)
					else
						inst.sg.statemem.data = nil
						inst.Physics:ClearMotorVelOverride()
						inst.Physics:Stop()
						inst.sg:RemoveStateTag("jumping")
					end
				end
				if inst.sg.statemem.targets then
					AOEUtil.AttackAndDig(inst, inst.sg.statemem.aoeparams, inst:GetAOEAttackTagSet(), inst.sg.statemem.targets)
				end
			end
		end,

		timeline =
		{
			--#SFX
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("rifts2/shrouden/teleport_out") end),

			FrameEvent(3, function(inst)
				inst.AnimState:SetSortOrder(0)
			end),
			FrameEvent(5, function(inst)
				inst.sg:RemoveStateTag("invisible")
			end),
			FrameEvent(6, function(inst)
				if inst.sg:HasStateTag("jumping") then
					inst.sg.statemem.data = nil
					inst.Physics:ClearMotorVelOverride()
					inst.Physics:Stop()
					inst.sg:RemoveStateTag("jumping")
				end
				inst.sg:RemoveStateTag("noattack")
				SetClickable(inst, true)

				inst.sg.statemem.targets = {}
				inst.sg.statemem.aoeparams = GetAOEParams(0, 2.4, nil, 1, nil, inst.sg.statemem.spawning)
				AOEUtil.WorkAndDig(inst, 2.4)--, inst.sg.statemem.targets)
				AOEUtil.TossItems(inst, GetTossParams(2.4))
			end),
			FrameEvent(26, function(inst)
				local x, _, z = inst.Transform:GetWorldPosition()
				ToggleOnAllObjectCollisionsAt(inst, x, z)

				inst.sg.statemem.aoeparams.radius = 3.25
			end),
			FrameEvent(27, function(inst)
				inst.sg.statemem.aoeparams.radius = 3.9
			end),
			FrameEvent(28, function(inst)
				if inst.canautoquickattack and next(inst.sg.statemem.targets) == nil then
					inst.sg.statemem.quickattack = true
				end
				inst.sg.statemem.targets = nil
				inst.sg.statemem.aoeparams = nil
				inst:SetGelEnabled(false)
			end),
			FrameEvent(33, function(inst)
				if inst.components.health:IsDead() then
					inst.sg:GoToState("death")
					return
				elseif inst.sg.statemem.quickattack and ChooseAttack(inst) then
					return
				end
				inst.sg:RemoveStateTag("nointerrupt")
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(43, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},

		onexit = function(inst)
			if inst.sg.statemem.spawning then
				inst.components.combat:SetDefaultDamage(TUNING.SHROUDEN_DAMAGE)
				inst.components.planardamage:SetBaseDamage(TUNING.SHROUDEN_PLANAR_DAMAGE)
			end
			inst:SetCameraFocusEnabled(false) --#TEMP #TODO used as temp spawn state
			inst.AnimState:SetSortOrder(0)
			inst:SetGelEnabled(false)
			if inst.sg:HasStateTag("jumping") then
				inst.Physics:ClearMotorVelOverride()
				inst.Physics:Stop()
			end
			if inst.sg.mem.isobstaclepassthrough then
				local x, _, z = inst.Transform:GetWorldPosition()
				ToggleOnAllObjectCollisionsAt(inst, x, z)
			end
		end,
	},

	State{
		name = "optic_blast_pre",
		tags = { "attack", "busy" },

		onenter = function(inst, target)
			inst.components.locomotor:Stop()
			inst.components.combat:StartAttack()
			SwitchToNoFaced(inst)

			if target and target:IsValid() then
				inst.sg.statemem.target = target
				inst:ForceFacePoint(target.Transform:GetWorldPosition())
			end
			inst.AnimState:PlayAnimation("optic_blast_pre1")
		end,

		timeline =
		{
			--#SFX
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("rifts2/shrouden/teleport_in") end),

			FrameEvent(8, function(inst)
				inst.sg:AddStateTag("nointerrupt")
			end),
			FrameEvent(11, function(inst)
				inst.sg:AddStateTag("noattack")
				SetClickable(inst, false)
				ToggleOffAllObjectCollisions(inst)
			end),
			FrameEvent(15, function(inst)
				inst.sg:AddStateTag("invisible")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg.statemem.keepnofaced = true
					inst.sg.statemem.opticblasting = true
					inst.sg:GoToState("optic_blast_appear", inst.sg.statemem.target)
				end
			end),
		},

		onexit = function(inst)
			TryRestoreSixFaced(inst)
			if not inst.sg.statemem.opticblasting then
				SetClickable(inst, true)
				if inst.sg.mem.isobstaclepassthrough then
					local x, _, z = inst.Transform:GetWorldPosition()
					ToggleOnAllObjectCollisionsAt(inst, x, z)
				end
			end
		end,
	},

	State{
		name = "optic_blast_appear",
		tags = { "attack", "busy", "nointerrupt", "noattack", "invisible" },

		onenter = function(inst, target)
			inst.components.locomotor:Stop()
			SwitchToNoFaced(inst)

			if target and target:IsValid() then
				inst.sg.statemem.target = target
				inst.Physics:Teleport(target.Transform:GetWorldPosition())
				inst.Transform:SetRotation(target.Transform:GetRotation())
			end
			inst.AnimState:PlayAnimation("optic_blast_pre2")

			SetClickable(inst, false)
			ToggleOffAllObjectCollisions(inst)

			local fx = SpawnPrefab("shrouden_optic_blast_fx")
			fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
			fx:InitBlast(inst)
			inst.sg.statemem.fx = fx
		end,

		timeline =
		{
			--#SFX
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("rifts2/shrouden/teleport_out") end),
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("rifts8/shrouden/shrouden_blast_teleport_in") end),

			FrameEvent(5, function(inst)
				inst.sg:RemoveStateTag("invisible")
			end),
			FrameEvent(10, function(inst)
				inst.sg:RemoveStateTag("noattack")
				SetClickable(inst, true)
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg.statemem.keepnofaced = true
					inst.sg.statemem.opticblasting = true
					inst.sg:GoToState("optic_blast_loop", {
						target = inst.sg.statemem.target,
						fx = inst.sg.statemem.fx,
					})
				end
			end),
		},

		onexit = function(inst)
			TryRestoreSixFaced(inst)
			SetClickable(inst, true)
			if not inst.sg.statemem.opticblasting then
				if inst.sg.mem.isobstaclepassthrough then
					local x, _, z = inst.Transform:GetWorldPosition()
					ToggleOnAllObjectCollisionsAt(inst, x, z)
				end
				if inst.sg.statemem.fx then
					inst.sg.statemem.fx:Remove()
				end
			end
		end,
	},

	State{
		name = "optic_blast_loop",
		tags = { "attack", "busy", "nointerrupt", "jumping" },

		onenter = function(inst, data)
			inst.components.locomotor:Stop()
			inst.components.combat:RestartCooldown()
			SwitchToNoFaced(inst)
			inst.AnimState:PlayAnimation("optic_blast_loop", true)

			ToggleOffAllObjectCollisions(inst)

			if data and data.target and data.target:IsValid() then
				inst.sg.statemem.target = data.target
				inst.sg.statemem.speedmult = 1
			else
				inst.sg.statemem.speedmult = 0
			end

			local fx = data and data.fx
			if not (fx and fx:IsValid()) then
				fx = SpawnPrefab("shrouden_optic_blast_fx")
				fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
				fx:InitBlast(inst)
			end
			inst.sg.statemem.fx = fx

			inst.components.timer:StopTimer("opticblastcd")
			inst.components.timer:StartTimer("opticblastcd", TUNING.SHROUDEN_OPTIC_BLAST_CD)
		end,

		onupdate = function(inst, dt)
			if dt > 0 then
				local dist = 0
				local target = inst.sg.statemem.target
				if target then
					if target:IsValid() then
						local rot = inst.Transform:GetRotation()
						local x, _, z = inst.Transform:GetWorldPosition()
						local x1, _, z1 = target.Transform:GetWorldPosition()
						local dx = x1 - x
						local dz = z1 - z
						if dx ~= 0 or dz ~= 0 then
							local rot1 = math.atan2(-dz, dx) * RADIANS
							local drot = ReduceAngle(rot1 - rot)
							drot = math.clamp(drot / 2, -10, 10)
							inst.Transform:SetRotation(rot + drot)

							dist = math.sqrt(dx * dx + dz * dz)
						end
					else
						inst.sg.statemem.target = nil
					end
				end

				if inst.sg.statemem.speedmult > 0 then
					inst.sg.statemem.speedmult = math.max(0, inst.sg.statemem.speedmult - dt / 6)
					local speed = math.min(8, dist * 10)
					if inst.sg.statemem.speed then
						speed = speed * 0.2 + inst.sg.statemem.speed * 0.8
					end
					inst.sg.statemem.speed = speed
					if speed ~= 0 then
						inst.Physics:SetMotorVelOverride(speed * inst.sg.statemem.speedmult, 0, 0)
					else
						inst.Physics:ClearMotorVelOverride()
						inst.Physics:Stop()
					end
				end
			end
		end,

		timeline =
		{
			TimeEvent(2.5, function(inst)
				inst.components.combat:RestartCooldown()
				if not inst.canwideblast then
					local success = inst.sg.statemem.fx.targets ~= nil and inst.sg.statemem.fx.targets[inst.sg.statemem.target] ~= nil
					inst.sg.statemem.fx:KillFx()
					inst.sg.statemem.keepnofaced = true
					inst.sg.statemem.opticblasting = true
					inst.sg:GoToState("optic_blast_pst", success)
					return
				end
				inst.sg.statemem.fx:MakeWide()
				inst.sg.statemem.speedmult = inst.sg.statemem.speedmult / 2
				inst.sg.statemem.wide = true
				inst.AnimState:PlayAnimation("optic_blast_pre3")
				inst.AnimState:PushAnimation("optic_blast_loop")
			end),
			TimeEvent(4, function(inst)
				inst.components.combat:RestartCooldown()
				local success = inst.sg.statemem.fx.targets ~= nil and inst.sg.statemem.fx.targets[inst.sg.statemem.target] ~= nil
				inst.sg.statemem.fx:KillFx()
				inst.sg.statemem.keepnofaced = true
				inst.sg.statemem.opticblasting = true
				inst.sg:GoToState("optic_blast_pst", success)
			end),
		},

		onexit = function(inst)
			TryRestoreSixFaced(inst)
			inst.Physics:ClearMotorVelOverride()
			inst.Physics:Stop()
			if not inst.sg.statemem.opticblasting then
				if inst.sg.mem.isobstaclepassthrough then
					local x, _, z = inst.Transform:GetWorldPosition()
					ToggleOnAllObjectCollisionsAt(inst, x, z)
				end
				if inst.sg.statemem.fx then
					inst.sg.statemem.fx:Remove()
				end
			end
		end,
	},

	State{
		name = "optic_blast_pst",
		tags = { "busy", "nointerrupt" },

		onenter = function(inst, success)
			inst.components.locomotor:Stop()
			SwitchToNoFaced(inst)
			inst.AnimState:PlayAnimation("optic_blast_pst")

			ToggleOffAllObjectCollisions(inst)

			inst.sg.statemem.success = success
		end,

		timeline =
		{
			--#SFX
			--FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("rifts8/shrouden/opticblast_pst") end),

			FrameEvent(17, function(inst)
				local x, _, z = inst.Transform:GetWorldPosition()
				ToggleOnAllObjectCollisionsAt(inst, x, z)

				inst.sg.statemem.targets = {}
				AOEUtil.Work(inst, 2.6, inst.sg.statemem.targets)
				AOEUtil.Attack(inst, GetAOEParams(0, 2.6, nil, 1), inst:GetAOEAttackTagSet(), inst.sg.statemem.targets)
				AOEUtil.TossItems(inst, GetTossParams(2.6))
			end),
			FrameEvent(18, function(inst)
				AOEUtil.Work(inst, 3.6, inst.sg.statemem.targets)
				AOEUtil.Attack(inst, GetAOEParams(0, 3.6, nil, 1), inst:GetAOEAttackTagSet(), inst.sg.statemem.targets)
				AOEUtil.TossItems(inst, GetTossParams(3.6))
			end),
			FrameEvent(20, function(inst)
				if inst.components.health:IsDead() then
					inst.sg:GoToState("death")
					return
				end
				inst.sg:RemoveStateTag("nointerrupt")
			end),
			FrameEvent(24, function(inst)
				if inst.sg.statemem.success then
					inst.sg.statemem.keepnofaced = true
					inst.sg:GoToState("taunt", true)
					return
				end
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(31, function(inst)
				inst.sg:RemoveStateTag("busy")
				inst.sg:AddStateTag("canrotate")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg.statemem.keepnofaced = true
					inst.sg:GoToState("idle")
				end
			end),
		},

		onexit = function(inst)
			TryRestoreSixFaced(inst)
			if inst.sg.mem.isobstaclepassthrough then
				local x, _, z = inst.Transform:GetWorldPosition()
				ToggleOnAllObjectCollisionsAt(inst, x, z)
			end
		end,
	},
}

CommonStates.AddWalkStates(states)

return StateGraph("shrouden", states, events, "idle")
