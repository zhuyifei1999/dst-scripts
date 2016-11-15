require("stategraphs/commonstates")
require("stategraphs/SGcritter_common")

local actionhandlers =
{
}

local events =
{
    SGCritterEvents.OnEat(),

    CommonHandlers.OnSleepEx(),
    CommonHandlers.OnWakeEx(),
    CommonHandlers.OnLocomote(false,true),
}

local states =
{
}

local emotes =
{
	{ anim="emote_bounce",
      timeline=
		{
			TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/buttstomp") inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/buttstomp_voice") end),
			TimeEvent(28*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/buttstomp") inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/buttstomp_voice") end),
			TimeEvent(43*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/buttstomp") inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/buttstomp_voice") end),
		},
	},
	{ anim="emote_yawn",
      timeline=
		{
			TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/blink") end),
			TimeEvent(9
			*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/sleep_pre") end),
		},
	},
	{ anim="emote_flame",
      timeline=
		{
			TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/blink") end),
			TimeEvent(14*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/emote_flame") end),
		},
	},
}

SGCritterStates.AddIdle(states, #emotes)
SGCritterStates.AddEmotes(states, emotes)
SGCritterStates.AddEat(states,
        {
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/eat_pre") end),
            TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/blink") end),

            TimeEvent((28+0)*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/eat") end),
            TimeEvent((28+10)*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/eat") end),
            
            TimeEvent((28+24+0)*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/eat") end),
            TimeEvent((28+24+6)*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/blink") end),
        })
SGCritterStates.AddHungry(states,
        {
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/angry") end),
            TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/angry") end),
            TimeEvent(29*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/angry") end),
            TimeEvent(36*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/angry") end),
        })
SGCritterStates.AddNuzzle(states, actionhandlers,
		{
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/emote") end),
        })

SGCritterStates.AddWalkStates(states, nil, true)


local function StartFlapping(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/fly_LP", "flying")
end

local function RestoreFlapping(inst)
    if not inst.SoundEmitter:PlayingSound("flying") then
        StartFlapping(inst)
    end
end

local function StopFlapping(inst)
    inst.SoundEmitter:KillSound("flying")
end

local function CleanupIfSleepInterrupted(inst)
    if not inst.sg.statemem.continuesleeping then
        RestoreFlapping(inst)
    end
end

CommonStates.AddSleepExStates(states,
		{
			starttimeline =
			{
				TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/sleep_pre") end),
                TimeEvent(44*FRAMES, StopFlapping),
				TimeEvent(48*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/sleep") end),
			},
			sleeptimeline = 
			{
				TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/sleep") end),
				TimeEvent(52*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/sleep") end),
			},
			endtimeline = 
			{
				TimeEvent(2*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/blink") end),
                TimeEvent(12*FRAMES, StartFlapping),
			},
		},
        {
            onexitsleep = CleanupIfSleepInterrupted,
            onexitsleeping = CleanupIfSleepInterrupted,
            onexitwake = RestoreFlapping,
            onwake = StopFlapping,
        })

return StateGraph("SGcritter_dragonling", states, events, "idle", actionhandlers)
