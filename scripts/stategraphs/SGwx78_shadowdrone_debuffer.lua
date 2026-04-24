require("stategraphs/commonstates")
local easing = require("easing")

local events =
{
	CommonHandlers.OnLocomote(true, false),
	EventHandler("spawned", function(inst, data)
		if not inst.sg:HasStateTag("busy") then
			inst.sg:GoToState("spawndelay", data and data.delay or 0)
		end
	end),
	EventHandler("despawn", function(inst)
		inst.sg:GoToState("despawn")
	end),
	EventHandler("deactivate", function(inst)
		if not inst.sg:HasStateTag("despawn") then
			inst.sg:GoToState("deactivate")
		end
	end),
	EventHandler("ms_wx_shadowdrone_scan", function(inst)
		if not inst.sg:HasStateTag("busy") then
			local target = inst.target:value()
			if target then
				inst.sg:GoToState("scan_start", target)
			end
		end
	end),
}

local CAT_TOY_DELAY = 15

local function EndDelayCatToyTask(inst)
	inst.sg.mem.delaycattoytask = nil
	if inst.sg:HasStateTag("idle") then
		inst:AddTag("cattoyairborne")
	end
end

local function SetShadowScale(inst, scale)
	inst.DynamicShadow:SetSize(1.2 * scale, 0.75 * scale)
end

local states =
{
	State{
		name = "idle",
		tags = { "idle", "canrotate" },

		onenter = function(inst, t)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("idle_loop", true)
			if not (inst.sg.mem.delaycattoytask or inst:HasTag("cattoyairborne")) then
				inst:AddTag("cattoyairborne")
			end
		end,
	},

	State{
		name = "spawndelay",
		tags = { "busy" },

		onenter = function(inst, delay)
			inst.components.locomotor:Stop()
			inst:Hide()
			inst.DynamicShadow:Enable(false)
			inst.Physics:SetActive(false)
			if delay and delay > 0 then
				inst.sg.statemem.delay = true
				inst.sg:SetTimeout(delay)
			end
		end,

		timeline =
		{
			FrameEvent(0, function(inst)
				local owner = inst.components.follower and inst.components.follower:GetLeader()

				local socketquality = owner and owner.components.socketholder and owner.components.socketholder:GetHighestQualitySocketed(SOCKETNAMES.SHADOW) or SOCKETQUALITY.LOW
				inst.components.locomotor.runspeed =
					socketquality == SOCKETQUALITY.MEDIUM and
					TUNING.SKILLS.WX78.SHADOWDRONE_DEBUFFER_SPEED_BOOSTED or
					TUNING.SKILLS.WX78.SHADOWDRONE_DEBUFFER_SPEED

				if owner then
					local pos = owner:GetPosition()
					local offset = FindWalkableOffset(pos, math.random() * TWOPI, 3, 12, false, false, nil, false, true)
					if offset then
						pos = pos + offset
					end
					inst.Physics:Teleport(pos:Get())

					if owner.RecalculateShadowDronePattern then
						owner:RecalculateShadowDronePattern()
					end
				end

				if not inst.sg.statemem.delay then
					inst.sg:GoToState("spawned")
				end
			end),
		},

		ontimeout = function(inst)
			inst.sg:GoToState("spawned")
		end,

		onexit = function(inst)
			inst:Show()
			inst.DynamicShadow:Enable(true)
			inst.Physics:SetActive(true)
		end,
	},

	State{
		name = "spawned",
		tags = { "busy" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("deploy")
			SetShadowScale(inst, 0)
			inst.sg.statemem.t = 0
		end,

		onupdate = function(inst, dt)
			local t = inst.sg.statemem.t
			if t then
				t = t + dt
				inst.sg.statemem.t = t
				local len1 = 10 * FRAMES --pop up time
				local len2 = 6 * FRAMES --drop down time
				if t < len1 then
					SetShadowScale(inst, easing.outQuad(t, 0, 0.7, len1))
				else
					t = t - len1
					if t < len2 then
						SetShadowScale(inst, easing.inOutQuad(t, 0.7, 0.3, len2))
					else
						SetShadowScale(inst, 1)
						inst.sg.statemem.t = nil
					end
				end
			end
		end,

		timeline =
		{
			--#SFX
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("WX_rework/shadowdebuffer/start") end),
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
			SetShadowScale(inst, 1)
			inst.DynamicShadow:Enable(true)
		end,
	},

	State{
		name = "despawn",
		tags = { "busy", "despawn" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("death")

			local owner = inst.components.follower and inst.components.follower:GetLeader()
            if owner then
                if owner.components.petleash then
                    owner.components.petleash:DetachPet(inst)
                end
                if owner.RecalculateShadowDronePattern then
                    owner:RecalculateShadowDronePattern()
                end
            end
			if inst:IsAsleep() then
				inst:TryToDropRecipeLoot()
				inst:Remove()
			else
				inst:ListenForEvent("entitysleep", inst.Remove)
				inst.persists = true
			end
		end,

		timeline =
		{
			--#SFX
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("WX_rework/shadowdebuffer/stop") end),

			FrameEvent(8, function(inst)
				inst:TryToDropRecipeLoot()
				inst.DynamicShadow:Enable(false)
				inst.Physics:SetActive(false)
				inst.persists = false
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst:Remove()
				end
			end),
		},

		onexit = function(inst)
			--should not reach here
			inst:RemoveEventCallback("entitysleep", inst.Remove)
			inst.DynamicShadow:Enable(true)
			inst.Physics:SetActive(true)
		end,
	},

	State{
		name = "deactivate",
		tags = { "busy" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("death_2")
			if inst.sg.mem.delaycattoytask then
				inst.sg.mem.delaycattoytask:Cancel()
				inst.sg.mem.delaycattoytask = nil
			end
			inst:RemoveTag("cattoyairborne")
			inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() + 2 + math.random())
		end,

		timeline =
		{
			--#SFX
			--FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("WX_rework/shadowdebuffer/stop") end),			
		},

		ontimeout = function(inst)
			inst.sg:GoToState("reactivate")
		end,

		onexit = function(inst)
			inst.sg.mem.delaycattoytask = inst:DoTaskInTime(CAT_TOY_DELAY, EndDelayCatToyTask)
		end,
	},

	State{
		name = "reactivate",
		tags = { "busy" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("revive_from_death2")
		end,

		timeline =
		{
			--#SFX
			--FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("WX_rework/shadowdebuffer/stop") end),			
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},
	},

	State{
		name = "run_start",
		tags = { "moving", "running", "canrotate" },

		onenter = function(inst)
			inst.components.locomotor:SetExternalSpeedMultiplier(inst, "run_start", 0)
			inst.components.locomotor:RunForward()
			inst.AnimState:PlayAnimation("run_pre")
		end,

		onupdate = function(inst, dt)
			local k = inst.sg.statemem.speedk
			if k then
				k = k + 1
				local numaccelframes = 5
				if k < numaccelframes then
					inst.sg.statemem.speedk = k
					k = k / numaccelframes
					inst.components.locomotor:SetExternalSpeedMultiplier(inst, "run_start", k * k)
				else
					inst.sg.statemem.speedk = nil
					inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "run_start")
				end
			end
		end,

		timeline =
		{
			--#SFX
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("WX_rework/shadowdebuffer/movement") end),

			FrameEvent(3, function(inst)
				inst.sg.statemem.speedk = 0
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg.statemem.running = true
					inst.sg:GoToState("run")
				end
			end),
		},

		onexit = function(inst)
			if not inst.sg.statemem.running then
				inst.components.locomotor:SetExternalSpeedMultiplier(inst, "run_start", 0)
			end
		end,
	},

	State{
		name = "run",
		tags = { "moving", "running", "canrotate" },

		onenter = function(inst)
			inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "run_start")
			inst.components.locomotor:RunForward()
			inst.AnimState:PlayAnimation("run_loop", true)
		end,

		onexit = function(inst)
			if not inst.sg.statemem.running then
				inst.components.locomotor:SetExternalSpeedMultiplier(inst, "run_start", 0)
			end
		end,
	},

	State{
		name = "run_stop",
		tags = { "idle" },

		onenter = function(inst)
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("run_pst")
		end,

		timeline =
		{
			--#SFX
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("WX_rework/shadowdebuffer/movement") end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},
	},

	State{
		name = "scan_start",
		tags = { "busy", "scanning" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.Transform:SetEightFaced()
			inst.AnimState:PlayAnimation("debuffscan_pre")
		end,

		onupdate = function(inst, dt)
			local target = inst.target:value()
			if target then
				inst:ForceFacePoint(target.Transform:GetWorldPosition())
			end
		end,

		timeline =
		{
			--#SFX
			--FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("???") end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg.statemem.scanning = true
					inst.sg:GoToState("scanning")
				end
			end),
		},

		onexit = function(inst)
			if not inst.sg.statemem.scanning then
				inst.Transform:SetFourFaced()
			end
		end,
	},

	State{
		name = "scanning",
		tags = { "busy", "scanning" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.Transform:SetEightFaced()
			inst.AnimState:PlayAnimation("debuffscan_loop", true)
		end,

		onupdate = function(inst, dt)
			local target = inst.target:value()
			if target and not (target.components.health and target.components.health:IsDead()) then
				local range, maxrange = inst:CalcScanRange()
				if inst:IsNear(target, maxrange) then
					inst:ForceFacePoint(target.Transform:GetWorldPosition())
					inst.applyingdebuff:set(true)
					return
				end
			end

			inst.sg.statemem.scanning = true
			inst.sg:GoToState("scan_stop")
		end,

		timeline =
		{
			--#SFX
			--FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("???") end),
		},

		events =
		{
			EventHandler("locomote", function(inst, data)
				if inst.components.locomotor:WantsToMoveForward() then
					inst.sg.statemem.scanning = true
					inst.sg:GoToState("scan_stop")
				end
			end),
		},

		onexit = function(inst)
			if not inst.sg.statemem.scanning then
				inst.Transform:SetFourFaced()
			end
			inst.applyingdebuff:set(false)
		end,
	},

	State{
		name = "scan_stop",
		tags = { "busy" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.Transform:SetEightFaced()
			inst.AnimState:PlayAnimation("debuffscan_pst")
		end,

		timeline =
		{
			--#SFX
			--FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("???") end),
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
			inst.Transform:SetFourFaced()
		end,
	},
}

return StateGraph("wx78_shadowdrone_debuffer", states, events, "idle")
