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
	{ anim="emote_bounce",
      timeline=nil,
	},
	{ anim="emote_flame",
      timeline=nil,
	},
}

SGCritterStates.AddIdle(states, #emotes)
SGCritterStates.AddEmotes(states, emotes)
SGCritterStates.AddEat(states, nil)
SGCritterStates.AddHungry(states,
        {
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/smallbird/chirp") end),
        })
SGCritterStates.AddNuzzle(states, actionhandlers, nil)

CommonStates.AddWalkStates(states, nil, nil, true)
CommonStates.AddSleepStates(states)

return StateGraph("SGcritter_dragonling", states, events, "idle", actionhandlers)

