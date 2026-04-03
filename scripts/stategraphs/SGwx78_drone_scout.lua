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
	local vx, _, vz = inst.Physics:GetMotorVel()
	inst.Physics:SetMotorVel(vx, vy, vz)
	inst.sg.statemem.t = t
end

--------------------------------------------------------------------------

local states =
{
	State{
		name = "deploy",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("deploy")
			inst.Physics:Stop()
			inst.sg.mem.vel = Vector3(0, 0 ,0)
			inst.sg.statemem.t = nil
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
		name = "idle",
		tags = { "idle" },

		onenter = function(inst, t)
			inst.AnimState:PlayAnimation("idle", true)
			inst.sg.statemem.t = t
		end,

		onupdate = UpdateHover,
	},
}

return StateGraph("wx78_drone_scout", states, {}, "idle")
