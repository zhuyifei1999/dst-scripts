require("stategraphs/commonstates")
local easing = require("easing")

local function ResetSpeed(inst)
	local owner = inst.components.follower:GetLeader()
	local socketquality = owner and owner.components.socketholder and owner.components.socketholder:GetHighestQualitySocketed(SOCKETNAMES.SHADOW) or SOCKETQUALITY.LOW
	inst.components.locomotor.runspeed =
		socketquality == SOCKETQUALITY.PERFECT and
		TUNING.SKILLS.WX78.SHADOWDRONE_DEBUFFER_RUNSPEED_BOOSTED or
		TUNING.SKILLS.WX78.SHADOWDRONE_DEBUFFER_RUNSPEED

	inst.components.locomotor.walkspeed = TUNING.SKILLS.WX78.SHADOWDRONE_DEBUFFER_WALKSPEED
end

local function UpdateSpeed(inst)--, dt)
	local owner = inst.components.follower:GetLeader()
	local ownerspeed = owner and owner.components.locomotor and owner.components.locomotor:GetRunSpeed()

	if inst.sg:HasStateTag("running") then
		local socketquality = owner and owner.components.socketholder and owner.components.socketholder:GetHighestQualitySocketed(SOCKETNAMES.SHADOW) or SOCKETQUALITY.LOW
		local speed =
			socketquality == SOCKETQUALITY.PERFECT and
			TUNING.SKILLS.WX78.SHADOWDRONE_DEBUFFER_RUNSPEED_BOOSTED or
			TUNING.SKILLS.WX78.SHADOWDRONE_DEBUFFER_RUNSPEED

		if not inst.sg.statemem.quickmove and ownerspeed then
			if ownerspeed > speed then
				local dsq = inst:GetDistanceSqToInst(owner)
				local target = inst:GetScanTarget()
				if not (target and target:IsValid() and inst:GetDistanceSqToInst(target) < dsq) then
					local rsq = TUNING.SKILLS.WX78.SHADOWDRONE_FOLLOW_RADIUS
					local rsq = rsq * rsq
					speed = math.clamp(Remap(dsq, rsq, rsq * 9, speed, ownerspeed), speed, ownerspeed)
				end
			end
			inst.components.locomotor.runspeed = inst.components.locomotor.runspeed * 0.9 + speed * 0.1
		else
			inst.components.locomotor.runspeed = speed
		end
	else
		local speed = TUNING.SKILLS.WX78.SHADOWDRONE_DEBUFFER_WALKSPEED

		if ownerspeed then
			if ownerspeed ~= speed then
				local minspeed = math.min(speed, ownerspeed)
				local maxspeed = math.max(speed, ownerspeed)
				local dsq = inst:GetDistanceSqToInst(owner)
				local rsq = TUNING.SKILLS.WX78.SHADOWDRONE_FOLLOW_RADIUS
				local rsq = rsq * rsq
				speed = math.clamp(Remap(dsq, rsq, rsq * 9, minspeed, maxspeed), minspeed, maxspeed)
			end
			inst.components.locomotor.walkspeed = inst.components.locomotor.walkspeed * 0.9 + speed * 0.1
		else
			inst.components.locomotor.walkspeed = speed
		end
	end
end

local events =
{
	EventHandler("locomote", function(inst)
		if inst.components.locomotor:WantsToMoveForward() then
			if inst.sg:HasStateTag("moving") then
				if inst.components.locomotor:WantsToRun() then
					if not inst.sg:HasStateTag("running") then
						inst.sg:AddStateTag("running")
						UpdateSpeed(inst)
						inst.components.locomotor:RunForward()
					end
				elseif inst.sg:HasStateTag("running") then
					inst.sg:RemoveStateTag("running")
					UpdateSpeed(inst)
					inst.components.locomotor:WalkForward()
				end
			elseif inst.components.locomotor:WantsToRun() then
				if inst.sg:HasStateTag("quickmove") then
					inst.sg:GoToState("run", true)
				elseif not inst.sg:HasStateTag("busy") then
					inst.sg:GoToState("run_start")
				end
			else--walking
				if inst.sg:HasStateTag("idle") then
					inst.sg:GoToState("run_start")
				elseif inst.sg:HasStateTag("scanning") then
					inst.sg:GoToState("scan_stop")
				end
			end
		elseif inst.sg:HasStateTag("moving") then
			inst.sg:GoToState("run_stop")
		end
	end),
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
		if not inst.sg:HasAnyStateTag("busy", "scanning") then
			local target = inst:GetScanTarget()
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

		onenter = function(inst, randomize)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("idle_loop", true)
			if randomize then
				inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
			end
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
			if POPULATING then
				inst.sg.statemem.instant = true
			elseif delay and delay > 0 then
				inst.sg.statemem.delay = true
				inst.sg:SetTimeout(delay)
			end
		end,

		timeline =
		{
			FrameEvent(0, function(inst)
				ResetSpeed(inst)

				local owner = inst.components.follower:GetLeader()
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

				if inst.sg.statemem.instant then
					inst.sg:GoToState("idle", true)
				elseif not inst.sg.statemem.delay then
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

			local owner = inst.components.follower:GetLeader()
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
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("WX_rework/shadowdebuffer/stop", nil, 0.6) end),
			FrameEvent(9, function(inst) inst.SoundEmitter:PlaySound("rifts5/wagstaff_boss/missile_explode", nil, 0.3) end),

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
			FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("WX_rework/shadowdebuffer/stop") end),			
			FrameEvent(18, function(inst) inst.SoundEmitter:PlaySound("rifts5/generic_metal/clunk") end),	
			FrameEvent(18, function(inst) inst.SoundEmitter:PlaySound("rifts5/generic_metal/click_mult_high") end),	
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
	},

	State{
		name = "run_start",
		tags = { "moving", "canrotate" },

		onenter = function(inst)
			inst.components.locomotor:SetExternalSpeedMultiplier(inst, "run_start", 0)
			if inst.components.locomotor:WantsToRun() then
				inst.sg:AddStateTag("running")
				UpdateSpeed(inst)
				inst.components.locomotor:RunForward()
			else
				UpdateSpeed(inst)
				inst.components.locomotor:WalkForward()
			end
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
			UpdateSpeed(inst)
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
				ResetSpeed(inst)
			end
		end,
	},

	State{
		name = "run",
		tags = { "moving", "canrotate" },

		onenter = function(inst, quickmove)
			inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "run_start")
			if inst.components.locomotor:WantsToRun() then
				inst.sg:AddStateTag("running")
				inst.sg.statemem.quickmove = quickmove
				UpdateSpeed(inst)
				inst.components.locomotor:RunForward()
			else
				UpdateSpeed(inst)
				inst.components.locomotor:WalkForward()
			end
			inst.AnimState:PlayAnimation("run_loop", true)
		end,

		onupdate = UpdateSpeed,

		onexit = function(inst)
			inst.components.locomotor:SetExternalSpeedMultiplier(inst, "run_start", 0)
			ResetSpeed(inst)
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
		tags = { "scanning", "quickmove" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.Transform:SetEightFaced()
			inst.AnimState:PlayAnimation("debuffscan_pre")
			inst.SoundEmitter:PlaySound("WX_rework/shadowdebuffer/scanning_LP", "scanloop")
		end,

		onupdate = function(inst, dt)
			local target = inst:GetScanTarget()
			if target then
				inst:ForceFacePoint(target.Transform:GetWorldPosition())
			end
		end,

		timeline =
		{
			--#SFX
			--FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("WX_rework/shadowdebuffer/scanning_LP") end),
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
				inst.SoundEmitter:KillSound("scanloop")
			end
		end,
	},

	State{
		name = "scanning",
		tags = { "scanning", "quickmove" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.Transform:SetEightFaced()
			inst.AnimState:PlayAnimation("debuffscan_loop", true)
			if not inst.SoundEmitter:PlayingSound("scanloop") then
				inst.SoundEmitter:PlaySound("WX_rework/shadowdebuffer/scanning_LP", "scanloop")
			end
		end,

		onupdate = function(inst, dt)
			local target = inst:GetScanTarget()
			if target and not (target.components.health and target.components.health:IsDead()) then
				local range, maxrange = inst:CalcScanRange()
				if inst:IsNear(target, maxrange) then
					inst:ForceFacePoint(target.Transform:GetWorldPosition())
					inst:OnStartScanning()
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

		onexit = function(inst)
			if not inst.sg.statemem.scanning then
				inst.Transform:SetFourFaced()
			end
			inst.SoundEmitter:KillSound("scanloop")
			inst:OnStopScanning()
		end,
	},

	State{
		name = "scan_stop",
		tags = { "quickmove" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.Transform:SetEightFaced()
			inst.AnimState:PlayAnimation("debuffscan_pst")

			if inst.brain then
				inst.brain:ForceUpdate()
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
