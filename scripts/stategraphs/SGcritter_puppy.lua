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
	{ anim="emote_scratch",
      timeline=nil,
	},
	{ anim="emote_play_dead",
      timeline=
 		{
			--TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/pant") end),
			--TimeEvent(40*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/pant") end),
			--TimeEvent(60*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/pant") end),
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
SGCritterStates.AddNuzzle(states, actionhandlers, nil)

CommonStates.AddWalkStates(states,
	{
		walktimeline =
		{
			TimeEvent(1*FRAMES, PlayFootstep),
			TimeEvent(4*FRAMES, PlayFootstep),
		},
	}, nil, true)

CommonStates.AddSleepStates(states,
		{
			starttimeline = 
			{
				TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/growl") end),
			},
		})


return StateGraph("SGcritter_puppy", states, events, "idle", actionhandlers)

