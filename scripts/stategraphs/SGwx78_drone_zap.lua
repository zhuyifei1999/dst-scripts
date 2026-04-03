local function CanMoveInDir2(inst, costheta, sintheta)
	local owner = inst.owner:value()
	if owner == nil then
		return true
	end

	local cx, _, cz = owner.Transform:GetWorldPosition()

	local x, _, z = inst.Transform:GetWorldPosition()
	local x1 = x + 10 * costheta
	local z1 = z - 10 * sintheta

	if not math2d.LineIntersectsCircle(x, z, x1, z1, cx, cz, inst.range) then
		return false
	end

	x1 = x + 1.5 * costheta
	z1 = z - 1.5 * sintheta
	if not IsFlyingPermittedFromPointToPoint(cx, 0, cz, x1, 0, z1) then
		if IsFlyingPermittedFromPointToPoint(cx, 0, cz, x, 0, z) then
			return false --going from valid to invalid, definitely not allowed
		end
		--we're in invalid territory => extra leeway for getting back into valid territory
		x1 = x + 3 * costheta
		z1 = z - 3 * costheta
		if not IsFlyingPermittedFromPointToPoint(cx, 0, cz, x1, 0, z1) then
			return false
		end
	end

	return true
end

local function CanMoveInDir(inst, dir)
	dir = dir * DEGREES
	return CanMoveInDir2(inst, math.cos(dir), math.sin(dir))
end

local events =
{
	EventHandler("locomote", function(inst, data)
		if inst.sg:HasStateTag("busy") or inst.killed then
			return
		end

		local dir = data and data.dir
		if dir then
			local theta = dir * DEGREES
			local costheta = math.cos(theta)
			local sintheta = math.sin(theta)
			if CanMoveInDir2(inst, costheta, sintheta) then
				local sharpturn
				local canrotate = true
				if inst.sg.mem.lastdir and DiffAngle(inst.sg.mem.lastdir, dir) > 91 then
					if inst.sg.currentstate.name == "run_start" then
						canrotate = false
					else
						sharpturn = true
					end
				end

				if canrotate then
					inst.Transform:SetRotation(dir)
					inst.sg.mem.lastdir = dir

					local vx, vy, vz = inst.sg.mem.vel:Get()
					--now convert back to local space
					vx, vz = costheta * vx - sintheta * vz, sintheta * vx + costheta * vz
					inst.Physics:SetMotorVel(vx, vy, vz)
				end

				if inst.sg:HasStateTag("idle") or (sharpturn and inst.sg:HasStateTag("moving")) then
					inst.sg:GoToState("run_start", inst.sg.statemem.t)
				else
					inst.sg.statemem.stop = nil
				end
			else
				dir = nil
			end
		end

		if dir == nil and inst.sg:HasStateTag("moving") then
			if inst.sg.currentstate.name == "run_start" then
				inst.sg.statemem.stop = true
			else
				inst.sg.statemem.running = true
				inst.sg:GoToState("run_stop", inst.sg.statemem.t)
			end
		end
	end),
	EventHandler("doattack", function(inst)
		if not (inst.sg:HasStateTag("busy") or inst.killed) then
			inst.sg:GoToState("attack")
		end
	end),
}

--------------------------------------------------------------------------

local function CalcDecelVelXZ(inst, decel, costheta, sintheta)
	local vx, vz = inst.sg.mem.vel.x, inst.sg.mem.vel.z --world, not local!
	return vx > 0 and math.max(0, vx - decel) or math.min(0, vx + decel),
		vz > 0 and math.max(0, vz - decel) or math.min(0, vz + decel)
end

local function UpdateHover(inst, dt)
	if inst:IsAsleep() then
		return
	end

	local period = 1.2
	local amp = 0.2
	local ht0 = 7
	local liftoff_period = period * 3

	local x, y, z = inst.Transform:GetWorldPosition()
	local t = inst.sg.statemem.t
	if t == nil then
		if y < 2 then
			--liftoff: start from bottom of sin wave
			amp = ht0
			period = liftoff_period
			if y <= 0 then
				y = 0.01
				inst.Physics:Teleport(x, y, z)
			end
			t = math.asin((y - ht0) / amp) * period / TWOPI
		elseif y < ht0 - amp - 0.5 then
			t = 0.75 * period
		else
			t = math.random() * period
		end
		t = t + dt
	else
		t = t + dt
		if t < 0 then
			--lifting off
			amp = ht0
			period = liftoff_period
		end
	end

	local ht = ht0 + math.sin(t * TWOPI / period) * amp
	local vy = (ht - y) * 15

	local dir = inst.Transform:GetRotation()
	local theta = dir * DEGREES
	local costheta = math.cos(theta)
	local sintheta = math.sin(theta)
	local vx, vz = CalcDecelVelXZ(inst, 15 * dt, costheta, sintheta)

	if inst.sg:HasStateTag("moving") and inst.sg.statemem.speedmult ~= 0 then
		local speed = TUNING.SKILLS.WX78.ZAPDRONE_SPEED * (inst.sg.statemem.speedmult or 1)
		local vx1 = speed * costheta
		local vz1 = -speed * sintheta
		vx = vx1 > 0 and math.min(vx + vx1, vx1) or math.max(vx + vx1, vx1)
		vz = vz1 > 0 and math.min(vz + vz1, vz1) or math.max(vz + vz1, vz1)
	end

	inst.sg.mem.vel.x, inst.sg.mem.vel.y, inst.sg.mem.vel.z = vx, vy, vz
	--now convert back to local space
	vx, vz = costheta * vx - sintheta * vz, sintheta * vx + costheta * vz

	inst.Physics:SetMotorVel(vx, vy, vz)
	inst.sg.statemem.t = t

	if inst.sg:HasStateTag("moving") and not CanMoveInDir2(inst, costheta, sintheta) then
		inst.sg.statemem.running = true
		inst.sg:GoToState("run_stop", t)
	end
end

local function SetFlicker(inst, c)
	inst.AnimState:SetAddColour(c, c, c, 0)
	if c > 0 then
		inst.Light:SetIntensity(0.6 + c)
		inst.Light:Enable(true)
	else
		inst.Light:Enable(false)
	end
end

local function UpdateAttackHover(inst, dt)
	if inst:IsAsleep() then
		return
	end

	local charge_len = 12 * FRAMES
	local charge_period = charge_len * 4
	local charge_amp = 0.6
	local charge_ht0 = 7
	local recoil_len = 3 * FRAMES
	local recoil_period = recoil_len * 4
	local recoil_amp = 1
	local recoil_ht0 = charge_ht0 + charge_amp
	local idle_amp = 0.2 --from UpdateHover
	local idle_ht0 = 7 --from UpdateHover
	local settle_period = 12 * FRAMES * 2
	local settle_amp = ((recoil_ht0 + recoil_amp) - (idle_ht0 - idle_amp)) / 2
	local settle_ht0 = recoil_ht0 + recoil_amp - settle_amp

	local t, period, amp, ht0

	local hoverstate = inst.sg.statemem.hoverstate
	if hoverstate == 0 then --charging
		t = (inst.sg.statemem.t or 0) + dt
		period = t < charge_len and charge_period or nil
		amp = charge_amp
		ht0 = charge_ht0

		local flicker = inst.sg.statemem.flicker
		if flicker then
			if flicker == 0 then
				SetFlicker(inst, 0.2)
			elseif flicker == 2 then
				SetFlicker(inst, 0.15)
			end
			if t > 0 then
				inst.sg.statemem.flicker = (flicker + 1) % 4
			end
		end
	elseif hoverstate == 1 then --recoil from firing
		t = (inst.sg.statemem.t or 0) + dt
		period = t < recoil_len and recoil_period or nil
		amp = recoil_amp
		ht0 = recoil_ht0
	else--if hoverstate == 2 then --settle back to idle
		t = (inst.sg.statemem.t or settle_period / 4) + dt
		period = settle_period
		amp = settle_amp
		ht0 = settle_ht0
	end

	local x, y, z = inst.Transform:GetWorldPosition()
	local ht = ht0 + (period and (math.sin(t * TWOPI / period) * amp) or amp)
	local vy = (ht - y) * 15

	local dir = inst.Transform:GetRotation()
	local theta = dir * DEGREES
	local costheta = math.cos(theta)
	local sintheta = math.sin(theta)
	local vx, vz = CalcDecelVelXZ(inst, 20 * dt, costheta, sintheta)

	inst.sg.mem.vel.x, inst.sg.mem.vel.y, inst.sg.mem.vel.z = vx, vy, vz
	--now convert back to local space
	vx, vz = costheta * vx - sintheta * vz, sintheta * vx + costheta * vz

	inst.Physics:SetMotorVel(vx, vy, vz)
	inst.sg.statemem.t = t
end

local function UpdateLanding(inst, dt)
	if inst:IsAsleep() then
		return
	end

	local len = 60 * FRAMES
	local t = inst.sg.statemem.t
	if t ~= math.huge then
		local vy, g
		if t == nil then
			local _, y = inst.Transform:GetWorldPosition()
			_, vy = inst.Physics:GetMotorVel()
			--local vyf = -y * 2 / len - vy
			--g = (vyf - vy) / len
			g = -2 * (y / len + vy) / len
			inst.sg.statemem.g = g
			t = 0
		else
			vy = inst.sg.mem.vel.y
			g = inst.sg.statemem.g
		end

		t = t + dt
		if t < len then
			local dir = inst.Transform:GetRotation()
			local theta = dir * DEGREES
			local costheta = math.cos(theta)
			local sintheta = math.sin(theta)
			local vx, vz = CalcDecelVelXZ(inst, 20 * dt, costheta, sintheta)

			vy = vy + g * dt

			inst.sg.mem.vel.x, inst.sg.mem.vel.y, inst.sg.mem.vel.z = vx, vy, vz
			--now convert back to local space
			vx, vz = costheta * vx - sintheta * vz, sintheta * vx + costheta * vz

			inst.Physics:SetMotorVel(vx, vy, vz)
			inst.sg.statemem.t = t
		else
			local x, y, z = inst.Transform:GetWorldPosition()
			inst.Physics:Stop()
			inst.Transform:SetPosition(x, 0, z)
			inst.sg.statemem.t = math.huge --finished landing
		end
	end
end

--------------------------------------------------------------------------

local PROPELLER_VOLUME = 0.5

local SOUND_LOOPS =
{
	["idle"] = "rifts5/wagdrone_flying/idle",
	["run"] = "rifts5/wagdrone_flying/walk_lp",
}

local function SetSoundLoop(inst, name)
	for k, v in pairs(SOUND_LOOPS) do
		if k ~= name then
			inst.SoundEmitter:KillSound(k)
		elseif not inst.SoundEmitter:PlayingSound(k) then
			inst.SoundEmitter:PlaySound(v, k, PROPELLER_VOLUME)
		end
	end
end

local states =
{
	State{
		name = "deploy",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("deploy")
			SetSoundLoop(inst, "idle")
			inst.Physics:Stop()
			inst.sg.mem.vel = Vector3(0, 0 ,0)
		end,

		onupdate = UpdateHover,

		timeline =
		{
			--#SFX
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySoundWithParams("rifts5/wagdrone_rolling/beep_turnon", { pitch = 0.9 }, 0.4) end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle", inst.sg.statemem.t)
				end
			end),
		},
	},

	State{
		name = "collapse",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("collapse")
			SetSoundLoop(inst, nil)
		end,

		onupdate = UpdateLanding,

		timeline =
		{
			--#SFX
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySoundWithParams("rifts5/wagdrone_rolling/beep_turnoff", { pitch = 0.9 }, 0.4) end),
		},
	},

	State{
		name = "idle",
		tags = { "idle" },

		onenter = function(inst, t)
			inst.AnimState:PlayAnimation("idle", true)
			SetSoundLoop(inst, "idle")
			inst.sg.statemem.t = t
		end,

		onupdate = UpdateHover,
	},

	State{
		name = "run_start",
		tags = { "moving", "running" },

		onenter = function(inst, t)
			inst.Transform:SetFourFaced()
			inst.AnimState:PlayAnimation("run_pre")
			for k, v in pairs(SOUND_LOOPS) do
				if k ~= "run" then
					if k ~= "idle" then
						inst.SoundEmitter:KillSound(k)
					end
				elseif not inst.SoundEmitter:PlayingSound(k) then
					inst.SoundEmitter:PlaySound(v, k, PROPELLER_VOLUME)
				end
			end
			if inst.sg.lasttags["moving"] then
				inst.SoundEmitter:PlaySound("rifts5/wagdrone_flying/walk_pst", nil, PROPELLER_VOLUME)
			end
			inst.sg.statemem.t = t
			inst.sg.statemem.speedmult = 0
			inst.sg.statemem.speedk = 0
		end,

		onupdate = function(inst, dt)
			local k = inst.sg.statemem.speedk
			if k then
				k = k + 1
				local numaccelframes = 8
				if k < numaccelframes then
					inst.sg.statemem.speedk = k
					k = k / numaccelframes
					inst.sg.statemem.speedmult = k * k
				else
					inst.sg.statemem.speedk = nil
					inst.sg.statemem.speedmult = nil
				end
			end
			UpdateHover(inst, dt)
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg.statemem.running = true
					inst.sg:GoToState(inst.sg.statemem.stop and "run_stop" or "run", inst.sg.statemem.t)
				end
			end),
		},

		onexit = function(inst)
			if not inst.sg.statemem.running then
				inst.Transform:SetNoFaced()
			end
		end,
	},

	State{
		name = "run",
		tags = { "moving", "running" },

		onenter = function(inst, t)
			inst.Transform:SetFourFaced()
			inst.AnimState:PlayAnimation("run_loop", true)
			SetSoundLoop(inst, "run")
			inst.sg.statemem.t = t or 0
		end,

		onupdate = UpdateHover,

		onexit = function(inst)
			if not inst.sg.statemem.running then
				inst.Transform:SetNoFaced()
			end
		end,
	},

	State{
		name = "run_stop",
		tags = { "idle" },

		onenter = function(inst, t)
			inst.Transform:SetFourFaced()
			inst.AnimState:PlayAnimation("run_pst")
			inst.sg.statemem.t = t
		end,

		onupdate = UpdateHover,

		timeline =
		{
			--#SFX
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("rifts5/wagdrone_flying/walk_pst", nil, PROPELLER_VOLUME) end),
			FrameEvent(3, function(inst) SetSoundLoop(inst, "idle") end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle", inst.sg.statemem.t)
				end
			end),
		},

		onexit = function(inst)
			inst.Transform:SetNoFaced()
		end,
	},

	State{
		name = "attack",
		tags = { "attack", "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("atk_pre")
			inst.AnimState:PushAnimation("atk")
			inst.AnimState:PushAnimation("atk_pst", false)
			SetSoundLoop(inst, "idle")
			inst.sg.statemem.hoverstate = 0
		end,

		onupdate = UpdateAttackHover,

		timeline =
		{
			--#SFX
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("rifts5/generic_metal/ratchet") end),
			--FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("rifts5/wagpunk_fence/fence_activate", 0.4) end),
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("rifts5/wagdrone_stationary/beep_hurt") end),
			FrameEvent(3, function(inst) inst.SoundEmitter:PlaySound("rifts5/wagdrone_stationary/beep_hurt") end),
			FrameEvent(6, function(inst) inst.SoundEmitter:PlaySound("rifts5/wagdrone_stationary/beep_hurt") end),
			FrameEvent(9, function(inst) inst.SoundEmitter:PlaySound("rifts5/wagdrone_stationary/beep_hurt") end),
			FrameEvent(12, function(inst) inst.SoundEmitter:PlaySound("rifts5/wagdrone_stationary/beep_hurt") end),

			FrameEvent(0, function(inst)
				inst.sg.statemem.projectile = SpawnPrefab("wx78_drone_zap_projectile_fx")
				inst.sg.statemem.projectile.caster = inst.owner:value()
				inst.sg.statemem.projectile:AttachTo(inst)
				inst.sg.statemem.flicker = 0
				inst:PushEvent("ms_drone_zap_fired")
			end),
			FrameEvent(22, function(inst)
				inst.sg.statemem.hoverstate = 1
				inst.sg.statemem.t = nil
				inst.sg.statemem.flicker = nil
				SetFlicker(inst, 0)
				inst.sg.statemem.projectile:Launch(inst.Transform:GetWorldPosition())
				inst.sg.statemem.projectile = nil
			end),
			FrameEvent(25, function(inst)
				inst.sg.statemem.hoverstate = 2
				inst.sg.statemem.t = nil
			end),
		},

		events =
		{
			EventHandler("animqueueover", function(inst)
				if inst.AnimState:AnimDone() then
					local period = 1.2 --from UpdateIdleHover
					inst.sg:GoToState("idle", period * 0.75)
				end
			end),
		},

		onexit = function(inst)
			SetFlicker(inst, 0)
			if inst.sg.statemem.projectile then
				inst.sg.statemem.projectile:Remove()
			end
		end,
	},
}

return StateGraph("wx78_drone_zap", states, events, "deploy")
