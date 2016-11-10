require("stategraphs/commonstates")
require("stategraphs/SGcritter_common")

local actionhandlers = 
{
}

local events=
{
	SGCritterEvents.OnGoToSleep(),
	SGCritterEvents.OnEat(),

    CommonHandlers.OnLocomote(false,true),
}

local states=
{
}

local emotes =
{
	{ anim="emote_shuffle",
      timeline=
		{
			TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/walk") end),
			TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/walk") end),
			TimeEvent(25*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/walk") end),
			TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/walk") end),
		},
    },
	{ anim="emote_stallion",
      timeline=
 		{
            TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/stallion") end),
			TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/grunt") end),
            TimeEvent(28*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/stallion") end),
            TimeEvent(40*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/stallion") end),
			TimeEvent(40*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/grunt") end),
            TimeEvent(45*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/stallion") end),
		},
	},
}

SGCritterStates.AddIdle(states, #emotes)
SGCritterStates.AddEmotes(states, emotes)
SGCritterStates.AddEat(states,
        {
            TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/curious") end),

            TimeEvent((22+16)*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/chew") end),
        })
SGCritterStates.AddHungry(states,
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/angry") end),
        })
SGCritterStates.AddNuzzle(states, actionhandlers,
        {
            TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/grunt") end),
        })

CommonStates.AddWalkStates(states, 
	{
		walktimeline =
		{
			TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/walk") end),
		},
		endtimeline =
		{
			TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/walk") end),
		},
	}, nil, true)
CommonStates.AddSleepStates(states,
		{
			starttimeline = 
			{
				TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/bodyfall") end),
			},
			sleeptimeline = 
			{
				TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/sleep") end),
				TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/sleep") end),
				TimeEvent(57*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/sleep") end),
			},
		})

return StateGraph("SGcritter_lamb", states, events, "idle", actionhandlers)

