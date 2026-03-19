require("stategraphs/commonstates")
require("stategraphs/SGcritter_common")

local actionhandlers = {
}

local events = {
	SGCritterEvents.OnEat(),
    SGCritterEvents.OnAvoidCombat(),
	SGCritterEvents.OnTraitChanged(),

    CommonHandlers.OnSleepEx(),
    CommonHandlers.OnWakeEx(),
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnHop(),
	CommonHandlers.OnSink(),
    CommonHandlers.OnFallInVoid(),
}

local states = {
}

local emotes = {
    {
        anim = "whistle",
        timeline = {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bulbin/whistle") end),
        },
    },
    {
        ignorestandardonenter = true,
        anim = "roll_pre",
        tags = {"busy", "jumping"},
        fns = {
            onenter = function(inst, data)
                if not data then
                    if inst.components.locomotor ~= nil then
                        inst.components.locomotor:StopMoving()
                    end
                    inst.Transform:SetRotation(math.random() * 360)
                    inst.sg.statemem.rollcount = math.random(3, 5)
                    inst.AnimState:PlayAnimation("roll_pre")
                    inst.AnimState:PushAnimation("roll_pre_hold")
                else
                    inst.sg.statemem.rollcount = data
                    if inst.sg.statemem.rollcount > 0 then
                        if not inst.SoundEmitter:PlayingSound("rolling") then
                            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bulbin/roll_LP", "rolling")
                        end
                        inst.Physics:ClearMotorVelOverride()
                        inst.Physics:SetMotorVelOverride(6, 0, 0)
                        inst.AnimState:PlayAnimation("roll_loop")
                    else
                        inst.Physics:ClearMotorVelOverride()
                        inst.AnimState:PlayAnimation("roll_pst")
                        if inst.SoundEmitter:PlayingSound("rolling") then
                            inst.SoundEmitter:KillSound("rolling")
                        end
                    end
                end
            end,
            animover = function(inst, selfstatename)
                if inst.AnimState:AnimDone() then
                    if (inst.sg.statemem.rollcount or 0) > 0 then
                        inst.sg:GoToState(selfstatename, inst.sg.statemem.rollcount - 1)
                    else
                        inst.sg:GoToState("idle")
                    end
                end
            end,
            onexit = function(inst)
                if (inst.sg.statemem.rollcount or 0) <= 0 then
                    inst.Physics:ClearMotorVelOverride()
                    if inst.SoundEmitter:PlayingSound("rolling") then
                        inst.SoundEmitter:KillSound("rolling")
                    end
                end
            end,
        },
    },
}

SGCritterStates.AddIdle(states, #emotes)
SGCritterStates.AddRandomEmotes(states, emotes)
SGCritterStates.AddEmote(states, "cute",
        {
            TimeEvent(28*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bulbin/yell") end),
        })
SGCritterStates.AddPetEmote(states,
        {
            TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bulbin/yell") end),
        })
SGCritterStates.AddCombatEmote(states, nil)
SGCritterStates.AddPlayWithOtherCritter(states, events, nil)
SGCritterStates.AddEat(states,
        {
            TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bulbin/curious") end),

            TimeEvent((22+16)*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bulbin/grunt") end),
        })
SGCritterStates.AddHungry(states,
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bulbin/yell") end),
        })
SGCritterStates.AddNuzzle(states, actionhandlers,
        {
            TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bulbin/grunt") end),
        })

SGCritterStates.AddWalkStates(states,
	{
		walktimeline =
		{
			TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/walk") end),
		},
		endtimeline =
		{
			TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/walk") end),
		},
	}, true)
CommonStates.AddSleepExStates(states,
		{
			starttimeline =
			{
				TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/bodyfall") end),
			},
			sleeptimeline =
			{
				TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bulbin/sleep") end),
				TimeEvent(57*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bulbin/sleep") end),
			},
		})

CommonStates.AddHopStates(states, true)
CommonStates.AddSinkAndWashAshoreStates(states)
CommonStates.AddVoidFallStates(states)

return StateGraph("SGcritter_bulbin", states, events, "idle", actionhandlers)
