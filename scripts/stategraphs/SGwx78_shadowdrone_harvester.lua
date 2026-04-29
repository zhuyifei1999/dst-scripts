require("stategraphs/commonstates")

local actionhandlers =
{
	ActionHandler(ACTIONS.PICK, "take"),
	ActionHandler(ACTIONS.PICKUP, "take"),
	ActionHandler(ACTIONS.CHECKTRAP, "take"),
	ActionHandler(ACTIONS.GIVE, "give"),
	ActionHandler(ACTIONS.GIVEALLTOPLAYER, "give"),
	ActionHandler(ACTIONS.DROP, "give"),
	ActionHandler(ACTIONS.STORE, "give"),
}

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
}

local CAT_TOY_DELAY = 15

local function EndDelayCatToyTask(inst)
	inst.sg.mem.delaycattoytask = nil
	if inst.sg:HasStateTag("idle") then
		inst:AddTag("cattoyairborne")
	end
end

local states =
{
	State{
		name = "idle",
		tags = { "idle", "canrotate" },

		onenter = function(inst, t)
			inst.components.locomotor:StopMoving()
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
			inst.components.locomotor:StopMoving()
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
					TUNING.SKILLS.WX78.SHADOWDRONE_HARVESTER_SPEED_BOOSTED or
					TUNING.SKILLS.WX78.SHADOWDRONE_HARVESTER_SPEED

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
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("deploy")
		end,

		timeline =
		{
			--#SFX
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("WX_rework/harvester/start") end),
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
		name = "despawn",
		tags = { "busy", "despawn" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.components.locomotor:Clear()
			inst:ClearBufferedAction()
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
				inst.components.inventory:DropEverything()
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
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("WX_rework/harvester/stop") end),
			FrameEvent(10, function(inst) inst.SoundEmitter:PlaySound("rifts5/wagstaff_boss/missile_explode", nil, 0.3) end),

			FrameEvent(9, function(inst)
				inst.components.inventory:DropEverything()
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
			inst.components.locomotor:Clear()
			inst:ClearBufferedAction()
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
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("WX_rework/harvester/stop") end),	
			FrameEvent(17, function(inst) inst.SoundEmitter:PlaySound("rifts5/generic_metal/clunk") end),	
			FrameEvent(17, function(inst) inst.SoundEmitter:PlaySound("rifts5/generic_metal/click_mult_high") end),	
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
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("revive_from_death2")
		end,

		timeline =
		{
			--#SFX
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("WX_rework/harvester/start") end),			
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
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("WX_rework/harvester/movement") end),

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
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("WX_rework/harvester/movement") end),
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
		name = "take",
		tags = { "busy" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("harvest")
		end,

		timeline =
		{
			--#SFX
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("WX_rework/harvester/movement") end),
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("rifts5/generic_metal/ratchet", nil, 0.3) end),
			FrameEvent(13, function(inst) inst.SoundEmitter:PlaySound("balatro/balatro_cabinet/cards_flip") end),
			FrameEvent(20, function(inst) inst.SoundEmitter:PlaySound("rifts5/generic_metal/ratchet", nil, 0.3) end),

			FrameEvent(13, function(inst)
				inst:PerformBufferedAction()
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
	},

	State{
		name = "give",
		tags = { "busy" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("give")
		end,

		timeline =
		{
			--#SFX
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("WX_rework/harvester/movement") end),
			FrameEvent(17, function(inst) inst.SoundEmitter:PlaySound("rifts5/generic_metal/ratchet", nil, 0.1) end),
			FrameEvent(21, function(inst) inst.SoundEmitter:PlaySound("balatro/balatro_cabinet/cards_flip") end),
			FrameEvent(23, function(inst) inst.SoundEmitter:PlaySound("WX_rework/harvester/movement") end),

			FrameEvent(18, function(inst)
				local success = inst:PerformBufferedAction()
                if success then
                    inst:ApplyUse()
                end
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
	},
}

return StateGraph("wx78_shadowdrone_harvester", states, events, "idle", actionhandlers)
