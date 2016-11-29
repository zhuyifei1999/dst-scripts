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
	{ anim="emote_scratch",
      timeline=
 		{
			TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/emote_scratch") end),
			TimeEvent(26*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/emote_scratch") end),
			TimeEvent(35*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/emote_scratch") end),
			TimeEvent(45*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/emote_scratch") end),
			TimeEvent(55*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/emote_scratch") end),
		},
	},
	{ anim="emote_play_dead",
      timeline=
 		{
			TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/pant") end),
			TimeEvent(48*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/pant") end),
			TimeEvent(76*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/bark") end),
		},
	},
}

SGCritterStates.AddIdle(states, #emotes,
	{
        --TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/pant") end),
	})
SGCritterStates.AddEmotes(states, emotes)
SGCritterStates.AddEat(states, nil)
SGCritterStates.AddHungry(states,
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/bark") end),
        })
SGCritterStates.AddNuzzle(states, actionhandlers,
        {
            TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/emote_scratch") end),
            TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/sleep") end),
            TimeEvent(35*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/emote_scratch") end),
            TimeEvent(36*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/sleep") end),
        })
        
SGCritterStates.AddWalkStates(states,
	{
		starttimeline = 
		{
	        TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/bark") end),
		},
		walktimeline =
		{
			TimeEvent(1*FRAMES, function(inst) PlayFootstep(inst, 0.25) end),
			TimeEvent(4*FRAMES, function(inst) PlayFootstep(inst, 0.25) end),
		},
	}, true)

CommonStates.AddSleepExStates(states,
		{
			starttimeline = 
			{
				TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/growl") end),
			},
			sleeptimeline = 
			{
				TimeEvent(14*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/sleep") end),
			},
		})

return StateGraph("SGcritter_puppy", states, events, "idle", actionhandlers)
