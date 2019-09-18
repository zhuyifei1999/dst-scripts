require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.EAT, "eat"),
}

local events =
{
	EventHandler("attacked", function(inst) if inst.components.health ~= nil and not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
		if inst:HasTag("swimming") then
			if inst.brain then
				inst.components.locomotor:StopMoving()
				inst.components.locomotor:Clear()

				inst.sg:GoToState("idle")
				inst.brain:ForceUpdate()
			end
		else
			inst.sg:GoToState("hit_land")
		end end end),
	EventHandler("gohome", function(inst) if inst.components.health ~= nil and not inst.components.health:IsDead() then inst.sg:GoToState("gohome") end end),
	EventHandler("death", function(inst) inst.sg:GoToState("death") end),
	EventHandler("gotosleep", function(inst) if inst.components.health ~= nil and not inst.components.health:IsDead() and inst:HasTag("swimming") and not inst.sg:HasStateTag("jumping") then inst.sg:GoToState(inst.sg:HasStateTag("sleeping") and "sleeping" or "sleep") end end),
    CommonHandlers.OnHop(),
	CommonHandlers.OnLocomote(true, true),
}

local function StartAura(inst)
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED
end

local function StopAura(inst)
    inst.components.sanityaura.aura = 0
end

local function UpdateWalkSpeedAndHopping(inst, forcechasingboattruefalse)
	if forcechasingboattruefalse ~= nil then
		if forcechasingboattruefalse then
			inst.components.locomotor.walkspeed = TUNING.COOKIECUTTER.APPROACH_SPEED
			inst.components.locomotor:SetAllowPlatformHopping(true)
		else
			inst.components.locomotor.walkspeed = TUNING.COOKIECUTTER.WANDER_SPEED
			inst.components.locomotor:SetAllowPlatformHopping(false)
		end
	else
		if inst.target_boat ~= nil and inst:GetBufferedAction() == nil then
			inst.components.locomotor.walkspeed = TUNING.COOKIECUTTER.APPROACH_SPEED
			inst.components.locomotor:SetAllowPlatformHopping(true)
		else
			inst.components.locomotor.walkspeed = TUNING.COOKIECUTTER.WANDER_SPEED
			inst.components.locomotor:SetAllowPlatformHopping(false)
		end
	end
end

local states =
{
    State{
        name = "idle",
        tags = { "idle", "canrotate" },
        onenter = function(inst, playanim)
			local x, y, z = inst.Transform:GetWorldPosition()
			if inst.should_drill or TheWorld.Map:GetPlatformAtPoint(x, z) then
				if inst.should_start_drilling then
					inst.components.cookiecutterdrill:ResetDrillProgress()
					inst.attackdata.wants_to_attack = false
				end
				inst:setsortorderisinwaterfn(false)
				inst.sg:GoToState("drill")
			else
				inst.Physics:Stop()
				if playanim then
					inst.AnimState:PlayAnimation(playanim)
					inst.AnimState:PushAnimation("idle", true)
				else
					inst.AnimState:PlayAnimation("idle", true)
				end
				inst:setsortorderisinwaterfn(true)

				inst.sg:SetTimeout(2*math.random()+.5)
			end

			inst.should_start_drilling = false
        end,
    },

    State{
        name = "eat",
        tags = { "busy", "jumping" },

        onenter = function(inst, cb)
            inst.Physics:Stop()
			inst.AnimState:PlayAnimation("jumpout_antic")
			inst.AnimState:PushAnimation("jumpout", false)
			inst.AnimState:PushAnimation("jump_loop", false)
            inst.AnimState:PushAnimation("jumpin_pst", false)
        end,

        timeline =
        {
			TimeEvent(10*FRAMES, function(inst)
				SpawnPrefab("splash").Transform:SetPosition(inst.Transform:GetWorldPosition())
				inst.SoundEmitter:PlaySound(inst.sounds.jump)
			end),
			TimeEvent(12*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.attack)
			end),
			TimeEvent(17*FRAMES, function(inst)
				inst:setsortorderisinwaterfn(false)
			end),
            TimeEvent(28*FRAMES, function(inst)
				if inst:PerformBufferedAction() then
					inst.SoundEmitter:PlaySound(inst.sounds.eat_item)
				end
			end),
			TimeEvent(30*FRAMES, function(inst)
				SpawnPrefab("splash").Transform:SetPosition(inst.Transform:GetWorldPosition())
				inst.SoundEmitter:PlaySound(inst.sounds.splash)
				inst:setsortorderisinwaterfn(true)
			end),
        },

        events =
        {
			EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "drill",
		tags = { "drilling" },

        onenter = function(inst, cb)
			if not inst.SoundEmitter:PlayingSound("eat_LP") then inst.SoundEmitter:PlaySound(inst.sounds.eat, "eat_LP") end

			if inst.components.cookiecutterdrill:GetIsDoneDrilling() then
				inst.sg:GoToState("leaveboat")
			else
				if inst.attackdata.wants_to_attack and not inst.attackdata.on_cooldown then
					inst.sg:GoToState("areaattack")
				else
					inst.components.cookiecutterdrill:StartDrilling()

					inst.AnimState:PlayAnimation("eat_loop", true)
					SpawnPrefab("wood_splinter_drill").Transform:SetPosition(inst.Transform:GetWorldPosition())
				end
			end
		end,

		onexit = function(inst)
			inst.components.cookiecutterdrill:StopDrilling()
		end,

        events =
        {
            EventHandler("animover", function(inst)
				inst.sg:GoToState("drill")
			end),
        },
    },

    State{
        name = "leaveboat",
        tags = { "busy", "drilling", "leavingboat" },

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_pst")
			inst.should_drill = false
		end,

        timeline =
        {
			TimeEvent(3*FRAMES, function(inst)
				inst.components.cookiecutterdrill:FinishDrilling()
			end),
        },

        events =
        {
            EventHandler("animover", function(inst)
				inst:ClearBufferedAction()
				inst:PushEvent("onsubmerge")
                inst.SoundEmitter:KillSound("eat_LP")
				inst.SoundEmitter:PlaySound(inst.sounds.eat_finish)
			end),
        },
    },

    State{
        name = "areaattack",
        tags = { "attack", "busy" },

        onenter = function(inst, target)
			inst.attackdata.wants_to_attack = false
			inst.attackdata.on_cooldown = true
			inst:DoTaskInTime(inst.attackdata.cooldown_duration, function() inst.attackdata.on_cooldown = false end)

            inst.sg.statemem.target = target
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("attack_loop")
        end,

		onexit = function(inst)
			inst.components.cookiecutterdrill:StopDrilling()
		end,

        timeline =
        {
			TimeEvent(0, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.attack)
			end),

			TimeEvent(5*FRAMES, function(inst)
				inst.components.combat:DoAreaAttack(inst, TUNING.COOKIECUTTER.ATTACK_RADIUS, nil, nil, nil, { "ghost", "playerghost", "cookiecutter" })
			end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("drill") end),
        },
    },

    State{
        name = "surface",
        tags = { "busy" },

        onenter = function(inst, cb)
            inst.AnimState:PlayAnimation("resurface")
		end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

	State{
        name = "gohome",
        tags = { "busy" },

        onenter = function(inst, cb)
            inst.AnimState:PlayAnimation("submerge")
		end,

        events =
        {
            EventHandler("animover", function(inst)
				inst:doreturnfn()
			end),
        },
	},

    State{
        name = "hit_land", -- Skips straight to running away if hit in water
        tags = { "busy", "hit" },

        onenter = function(inst)
            inst.Physics:Stop()
			inst.components.cookiecutterdrill:StartDrilling()
			inst.AnimState:PlayAnimation("hit")
			if inst.SoundEmitter:PlayingSound("eat_LP") then inst.SoundEmitter:KillSound("eat_LP") end
        end,

		onexit = function(inst)
			inst.components.cookiecutterdrill:StopDrilling()
		end,

        events =
        {
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "death",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("death")
			if inst.components.amphibiouscreature ~= nil and inst.components.amphibiouscreature.in_water then
				inst:setsortorderisinwaterfn(true)
				inst.AnimState:PushAnimation("death_idle", true)
			else
				inst:setsortorderisinwaterfn(false)
				inst.AnimState:PushAnimation("death_idle", false)
			end

            inst.Physics:Stop()
            RemovePhysicsColliders(inst)

			if inst.SoundEmitter:PlayingSound("eat_LP") then inst.SoundEmitter:KillSound("eat_LP") end
            inst.SoundEmitter:PlaySound(inst.sounds.death)
            inst.components.lootdropper:DropLoot(inst:GetPosition())
        end,

        onexit = function(inst)
            if not inst:IsInLimbo() then
                inst.AnimState:Resume()
            end
        end,
    },

    State{
        name = "walk_start",
        tags = { "moving", "canrotate" },

        onenter = function(inst)
			inst.components.locomotor:WalkForward()
			inst.AnimState:PlayAnimation("walk_pre")
        end,

		onupdate = UpdateWalkSpeedAndHopping,

        events =
        {
            EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("walk")
				end
			end),
        },

		onexit = function(inst)
			UpdateWalkSpeedAndHopping(inst)
		end,
    },

    State{
        name = "walk",
        tags = { "moving", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
			inst.AnimState:PlayAnimation("walk_loop", true)
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,

		onupdate = UpdateWalkSpeedAndHopping,

        ontimeout = function(inst)
			inst.sg:GoToState("walk")
		end,

		onexit = function(inst)
			UpdateWalkSpeedAndHopping(inst)
		end,
    },

	State{
        name = "walk_stop",
        tags = { "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
			inst.AnimState:PushAnimation("walk_pst", false)
        end,
		onupdate = UpdateWalkSpeedAndHopping,

        events =
        {
            EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
        },

		onexit = function(inst)
			UpdateWalkSpeedAndHopping(inst)
		end,
    }
}

CommonStates.AddAmphibiousCreatureHopStates(states,
{ -- config
	swimming_clear_collision_frame = 1*FRAMES,
	onenters =
	{
		hop_antic = UpdateWalkSpeedAndHopping,
		hop_pre = UpdateWalkSpeedAndHopping,
		hop_pst = UpdateWalkSpeedAndHopping,
	},
	onexits =
	{
		hop_antic = UpdateWalkSpeedAndHopping,
		hop_pre = UpdateWalkSpeedAndHopping,
		hop_pst = UpdateWalkSpeedAndHopping,
	},
},
{ -- anims
},
{ -- timeline
	hop_antic = {
		TimeEvent(0, function(inst)
			inst.components.knownlocations:RememberLocation("resurfacepoint", Point(inst.Transform:GetWorldPosition()))
		end),
		TimeEvent(9*FRAMES, function(inst)
			SpawnPrefab("splash").Transform:SetPosition(inst.Transform:GetWorldPosition())
			inst.SoundEmitter:PlaySound(inst.sounds.jump)
		end),
		TimeEvent(12*FRAMES, function(inst)
			inst.sg:GoToState("hop_pre")
		end),
	},
	hop_pre =
	{
		TimeEvent(0, function(inst)
			inst:setsortorderisinwaterfn(false)
			inst.sg:SetTimeout(30*FRAMES) -- Overrides timeout set from commonstates hop_pre onenter

			inst.Physics:ClearCollidesWith(COLLISION.CHARACTERS)
		end),
		TimeEvent(1*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.attack)
		end),
	},
	hop_pst = {
		TimeEvent(3*FRAMES, function(inst)
			if inst.should_drill then
				SpawnPrefab("wood_splinter_jump").Transform:SetPosition(inst.Transform:GetWorldPosition())
				inst.SoundEmitter:PlaySound(inst.sounds.land)

				inst:ClearBufferedAction()
			end
		end),
		TimeEvent(4*FRAMES, function(inst) 
			if inst:HasTag("swimming") then
				inst.components.locomotor:StopMoving()
				SpawnPrefab("splash").Transform:SetPosition(inst.Transform:GetWorldPosition())
				inst.SoundEmitter:PlaySound(inst.sounds.splash)
				inst:setsortorderisinwaterfn(false)
			else
				inst.Physics:Stop()
				inst.Physics:SetActive(false)
			end
		end),
	},
})

CommonStates.AddSleepStates(states, {})

CommonStates.AddRunStates(states,
{
	starttimeline = {
		TimeEvent(0, function(inst)
			inst.components.health.invincible = true
			inst:AddTag("NOCLICK")
			inst:AddTag("notarget")

			UpdateWalkSpeedAndHopping(inst, false)
		end),
	},
	runtimeline = {
		TimeEvent(0, function(inst)
			inst.components.health.invincible = true
			inst:AddTag("NOCLICK")
			inst:AddTag("notarget")
		end),
	},
}, nil, nil, nil,
{
	startonexit = function(inst)
		inst.components.health.invincible = false
		inst:RemoveTag("NOCLICK")
		inst:RemoveTag("notarget")
	end,
	runonexit = function(inst)
		inst.components.health.invincible = false
		inst:RemoveTag("NOCLICK")
		inst:RemoveTag("notarget")
	end
})

return StateGraph("cookiecutter", states, events, "surface", actionhandlers)
