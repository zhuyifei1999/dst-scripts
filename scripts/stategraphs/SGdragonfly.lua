require("stategraphs/commonstates")

local function onattackedfn(inst, data)
	if inst.components.health and not inst.components.health:IsDead()
	and not inst.sg:HasStateTag("busy") then
		if inst.sg:HasStateTag("grounded") then
			inst.sg:GoToState("knockdown_hit")
		elseif inst.last_hit_time + TUNING.DRAGONFLY_HIT_RECOVERY <= GetTime() then
			inst.last_hit_time = GetTime()
			inst.sg:GoToState("hit")
		end
	end
end

local function onattackfn(inst, data)
    if inst.components.health and not inst.components.health:IsDead()
       and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy"))
       and not inst.sg:HasStateTag("grounded") then
       	if inst.enraged and inst.can_ground_pound then
       		inst.sg:GoToState("pound_pre")
       	else
        	inst.sg:GoToState("attack")
        end
    end
end

local function onstunnedfn(inst, data)
	if inst.components.health and not inst.components.health:IsDead() then
		inst.sg:GoToState("knockdown")
	end
end

local function onstunfinishedfn(inst, data)
	if inst.components.health and not inst.components.health:IsDead() then
		inst.sg:GoToState("knockdown_pst")
	end
end

local function ShakeIfClose(inst)
	for i, v in ipairs(AllPlayers) do
		v:ShakeCamera(CAMERASHAKE.FULL, .7, .02, .3, inst, 40)
	end
end

local function transform(inst, data)
	if inst.components.health and not inst.components.health:IsDead() and not
	(inst.sg:HasStateTag("frozen") or inst.sg:HasStateTag("grounded") or inst.sg:HasStateTag("sleeping")) then
		inst.sg:GoToState("transform_"..data.transformstate)
	end
end

local actionhandlers = 
{
	ActionHandler(ACTIONS.GOHOME, "flyaway"),
	ActionHandler(ACTIONS.SPAWN, "lavae"),
}

local events=
{
	CommonHandlers.OnLocomote(false,true),
	CommonHandlers.OnSleep(),
	CommonHandlers.OnFreeze(),
	CommonHandlers.OnDeath(),
	EventHandler("doattack", onattackfn),
	EventHandler("attacked", onattackedfn),
	EventHandler("stunned", onstunnedfn),
	EventHandler("stun_finished", onstunfinishedfn),
	EventHandler("transform", transform), 
	--Because this comes from an event players can prevent it by having dragonfly 
	--in sleep/ freeze/ knockdown states when this is triggered.
}

local states=
{
	State{
		name = "idle",
		tags = {"idle"},

		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("idle", true)
		end,
	},

	State{
		name = "walk_start",
		tags = {"moving", "canrotate"},

		onenter = function(inst)
			if inst.enraged then
				inst.AnimState:PlayAnimation("walk_angry_pre")
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/angry")
			else
				inst.AnimState:PlayAnimation("walk_pre")
			end
			inst.components.locomotor:WalkForward()
		end,

		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("walk") end ),
		},

		timeline=
		{
			TimeEvent(1*FRAMES, function(inst) if not inst.enraged then inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end end),
			TimeEvent(2*FRAMES, function(inst) if inst.enraged then inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end end)
		},
	},

	State{
		name = "hit",
		tags = {"hit", "busy"},

		onenter = function(inst, cb)
			if inst.components.locomotor then
				inst.components.locomotor:StopMoving()
			end

			inst.AnimState:PlayAnimation("hit")
			inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink")
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "walk",
		tags = {"moving", "canrotate"},

		onenter = function(inst)
			inst.components.locomotor:WalkForward()
			if inst.enraged then
				inst.AnimState:PlayAnimation("walk_angry")
				if math.random() < .5 then inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/angry") end
			else
				inst.AnimState:PlayAnimation("walk")
			end
		end,
		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("walk") end ),
		},
	},

	State{
		name = "walk_stop",
		tags = {"canrotate"},

		onenter = function(inst)
			if inst.components.locomotor then
				inst.components.locomotor:StopMoving()
			end

			local should_softstop = false
			if should_softstop then
				if inst.enraged then
					inst.AnimState:PushAnimation("walk_angry_pst", false)
				else
					inst.AnimState:PushAnimation("walk_pst", false)
				end
			else
				if inst.enraged then
					inst.AnimState:PlayAnimation("walk_angry_pst")
				else
					inst.AnimState:PlayAnimation("walk_pst")
				end
			end
		end,

		events=
		{
			EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end ),
		},

		timeline=
		{
			TimeEvent(1*FRAMES, function(inst) if not inst.enraged then inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end end),
			TimeEvent(2*FRAMES, function(inst) if inst.enraged then inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end end)
		},
	},

	State{
		name = "knockdown",
		tags = {"busy"},

		onenter = function(inst)
			if inst.components.locomotor then
				inst.components.locomotor:StopMoving()
			end

			--Start taking extra damage
			--Start tracking progress towards breakoff loot
			inst.AnimState:PlayAnimation("hit_large")
			inst.components.damagetracker:Start()
		end,

		timeline=
		{
			TimeEvent(22*FRAMES, function(inst) if inst.enraged then inst:TransformNormal() end end)
		},

		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("knockdown_idle") end)
		},
	},

	State{
		name = "knockdown_idle",
		tags = {"grounded"},

		onenter = function(inst)
			if inst.components.locomotor then
				inst.components.locomotor:StopMoving()
			end
			inst.AnimState:PlayAnimation("sleep_loop")
		end,

		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("knockdown_idle") end)
		},
	},

	State{
		name = "knockdown_hit",
		tags = {"busy", "grounded"},

		onenter = function(inst)
			if inst.components.locomotor then
				inst.components.locomotor:StopMoving()
			end

			inst.AnimState:PlayAnimation("hit_ground")
		end,

		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("knockdown_idle") end)
		},
	},

	State{
		name = "knockdown_pst",
		tags = {"busy"},

		onenter = function(inst)
			inst.AnimState:PlayAnimation("sleep_pst")
			inst.components.damagetracker:Stop()
			--Stop taking extra damage.
			--Stop tracking progress towards breakoff loot
		end,

		onexit = function(inst)
		end,

		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
		},
	},

	State{
		name = "flyaway",
		tags = {"flying", "busy"},

		onenter = function(inst)
			inst.Physics:Stop()
			inst.DynamicShadow:Enable(false)
			inst.AnimState:PlayAnimation("taunt_pre")
			inst.AnimState:PushAnimation("taunt")
			inst.AnimState:PushAnimation("taunt_pst") --59 frames

			inst.AnimState:PushAnimation("walk_angry_pre") -- 75 frames
			inst.AnimState:PushAnimation("walk_angry", true)

		end,

		timeline =
		{
			TimeEvent(75*FRAMES, function(inst)
				inst.Physics:SetMotorVel(math.random()*4,7+math.random()*2,math.random()*4)
			end),
			TimeEvent(6, function(inst) 
				--Push event to spawner to respawn in a day or two.
				inst:Remove()
			end)
		}
	},

	State{
		name = "attack",
		tags = {"attack", "busy", "canrotate"},

		onenter = function(inst)
			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("atk")
			if inst.enraged then
				local attackfx = SpawnPrefab("attackfire_fx")
				attackfx.Transform:SetPosition(inst.Transform:GetWorldPosition())
				attackfx.Transform:SetRotation(inst.Transform:GetRotation())
			end
		end,

		timeline=
		{
			TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/swipe") end),
			TimeEvent(15*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/punchimpact")
				inst.components.combat:DoAttack()
				if inst.components.combat.target and inst.components.combat.target.components.health and inst.enraged then
					inst.components.combat.target.components.health:DoFireDamage(5)
				end
			end),
		},

		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
	},

	State{
		name = "transform_fire",
		tags = {"busy"},

		onenter = function(inst)

			if inst.enraged then
				inst.sg:GoToState("idle")
			end

			inst.components.locomotor:StopMoving()
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("fire_on")
		end,

		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},

		timeline=
		{
			TimeEvent(2*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end),
			TimeEvent(7*FRAMES, function(inst)
				inst:TransformFire()
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/firedup", "fireflying")
			end),
		},
	},	

	State{
		name = "transform_normal",
		tags = {"busy"},

		onenter = function(inst)

			if not inst.enraged then
				inst.sg:GoToState("idle")
			end

			inst.components.locomotor:StopMoving()
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("fire_off")
		end,

		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},

		timeline=
		{
			TimeEvent(2*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end),
			TimeEvent(17*FRAMES, function(inst)
				inst:TransformNormal()
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/firedup", "fireflying")
			end),
		},
	},

	State{
		name = "pound_pre",
		tags = {"busy"},

		onenter = function(inst)
			inst.components.locomotor:StopMoving()
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("taunt_pre")
		end,

		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("pound") end),
		},

		timeline=
		{
			TimeEvent(2*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") 
			end),
			TimeEvent(6*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/firedup", "fireflying")
			end),
		},
	},

	State{
		name = "pound",
		tags = {"busy"},

		onenter = function(inst)
			inst.components.locomotor:StopMoving()
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("taunt")
			local tauntfx = SpawnPrefab("tauntfire_fx")
			tauntfx.Transform:SetPosition(inst.Transform:GetWorldPosition())
			tauntfx.Transform:SetRotation(inst.Transform:GetRotation())

			inst.can_ground_pound = false
			inst.components.timer:StartTimer("groundpound_cd", TUNING.DRAGONFLY_POUND_CD)
		end,

		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("pound_post") end),
		},

		timeline=
		{
			TimeEvent(2*FRAMES, function(inst)
				inst.components.groundpounder:GroundPound()
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/buttstomp")
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/buttstomp_voice")
			end),
			TimeEvent(9*FRAMES, function(inst)
				inst.components.groundpounder:GroundPound()
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/buttstomp")
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/buttstomp_voice")
			end),
			TimeEvent(20*FRAMES, function(inst)
				inst.components.groundpounder:GroundPound()
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/buttstomp")
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/buttstomp_voice")
			end),
		},
	},

	State{
		name = "pound_post",
		tags = {"busy"},

		onenter = function(inst)
			inst.AnimState:PlayAnimation("taunt_pst")
		end,

		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},

		timeline=
		{
			TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end),
		},
	},

	State{
		name = "lavae",
		tags = {"busy"},

		onenter = function(inst)
			inst.Transform:SetTwoFaced()
			if inst.components.locomotor then
				inst.components.locomotor:StopMoving()
			end
			inst.AnimState:PlayAnimation("vomit")
			inst.vomitfx = SpawnPrefab("vomitfire_fx")
			inst.vomitfx.Transform:SetPosition(inst.Transform:GetWorldPosition())
			inst.vomitfx.Transform:SetRotation(inst.Transform:GetRotation())
			inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/vomitrumble", "vomitrumble")
		end,

		onexit = function(inst)
			inst.Transform:SetSixFaced()
			if inst.vomitfx then
				inst.vomitfx:Remove()
			end
			inst.vomitfx = nil
			inst.SoundEmitter:KillSound("vomitrumble")
		end,

		events=
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		timeline=
		{
			TimeEvent(2*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end),
			TimeEvent(55*FRAMES, function(inst)
				inst.SoundEmitter:KillSound("vomitrumble")
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/vomit")
			end),
			TimeEvent(59*FRAMES, function(inst)
				inst:PerformBufferedAction()
			end),
		},
	},

	State{
		name = "sleep",
		tags = {"busy", "sleeping"},

		onenter = function(inst)
			if inst.components.locomotor then
				inst.components.locomotor:StopMoving()
			end
			inst.AnimState:PlayAnimation("land")
			inst.AnimState:PushAnimation("land_idle", false)
			inst.AnimState:PushAnimation("takeoff", false)
			inst.AnimState:PushAnimation("sleep_pre", false)
		end,

		events=
		{
			EventHandler("animqueueover", function(inst) inst.sg:GoToState("sleeping") end ),
			EventHandler("onwakeup", function(inst) inst.sg:GoToState("wake") end),
		},

		timeline=
		{
			TimeEvent(14*FRAMES, function(inst) inst.SoundEmitter:KillSound("flying") end),
			TimeEvent(16*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink")
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/land")
				if inst.enraged then
					inst:TransformNormal()
				end
			end),
			TimeEvent(74*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end),
			TimeEvent(78*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/fly", "flying") end),
			TimeEvent(91*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end),
			TimeEvent(111*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/sleep_pre") end),
			TimeEvent(202*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink")
				inst.SoundEmitter:KillSound("flying")
			end),
			TimeEvent(203*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/land") end),
		},
	},

	State{
		name = "sleeping",
		tags = {"busy", "sleeping"},

		onenter = function(inst)
			inst.AnimState:PlayAnimation("sleep_loop")
			inst.playsleepsound = not inst.playsleepsound
			if inst.playsleepsound then
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/sleep", "sleep")
			end
		end,

		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("sleeping") end ),
			EventHandler("onwakeup", function(inst) inst.sg:GoToState("wake") end),
		},
	},

	State{
		name = "wake",
		tags = {"busy", "waking"},

		onenter = function(inst)
			inst.SoundEmitter:KillSound("sleep")
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("sleep_pst")
			inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/wake")
			if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
				inst.components.sleeper:WakeUp()
			end
		end,

		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
		},

		timeline=
		{
			TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end),
			TimeEvent(26*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/fly", "flying") end),
		},
	},

	State{
		name = "death",
		tags = {"busy"},

		onenter = function(inst)
			if inst.components.locomotor then
				inst.components.locomotor:StopMoving()
			end
			inst.Light:Enable(false)
			inst.components.propagator:StopSpreading()
			inst.AnimState:PlayAnimation("death")
			inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/death")
		end,

		timeline=
		{
			TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end),
			TimeEvent(26*FRAMES, function(inst)
				inst.SoundEmitter:KillSound("flying")
				inst.SoundEmitter:KillSound("fireflying")
			end),
			TimeEvent(28*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/land") end),
			TimeEvent(29*FRAMES, function(inst)
				ShakeIfClose(inst)
				inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
			end),
		},

	},

	State{
		name = "land",
		tags = {"flying", "busy"},

		onenter= function(inst)
			inst.AnimState:PlayAnimation("walk_angry", true)
			inst.Physics:SetMotorVelOverride(0,-11,0)
		end,

		onupdate= function(inst)
			inst.Physics:SetMotorVelOverride(0,-15,0)
			local pt = Point(inst.Transform:GetWorldPosition())
			if pt.y < 2 then
				inst.Physics:ClearMotorVelOverride()
				pt.y = 0
				inst.Physics:Stop()
				inst.Physics:Teleport(pt.x,pt.y,pt.z)
				inst.DynamicShadow:Enable(true)
				inst.sg:GoToState("idle", {softstop = true})
				ShakeIfClose(inst)
			end
		end,

		onexit = function(inst)
			if inst:GetPosition().y > 0 then
				local pos = inst:GetPosition()
				pos.y = 0
				inst.Transform:SetPosition(pos:Get())
			end
		end,
	},

}

CommonStates.AddFrozenStates(states)

return StateGraph("dragonfly", states, events, "idle", actionhandlers)