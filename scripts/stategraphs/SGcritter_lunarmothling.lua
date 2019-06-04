require("stategraphs/commonstates")
require("stategraphs/SGcritter_common")

local actionhandlers =
{
}

local events =
{
    SGCritterEvents.OnEat(),
    SGCritterEvents.OnAvoidCombat(),
	SGCritterEvents.OnTraitChanged(),

    CommonHandlers.OnSleepEx(),
    CommonHandlers.OnWakeEx(),
    CommonHandlers.OnLocomote(false,true),
}

local states =
{
}

local emotes =
{
	{ anim="emote1",
      timeline=
		{
			TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/buttstomp") inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/buttstomp_voice") end),
			TimeEvent(28*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/buttstomp") inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/buttstomp_voice") end),
			TimeEvent(43*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/buttstomp") inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/buttstomp_voice") end),
		},
	},
	{ anim="emote2",
      timeline=
		{
			TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/blink") end),
			TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/sleep_pre") end),
		},
	},
	{ anim="emote_nuzzle",
      timeline=
		{
            TimeEvent(2*FRAMES, LandFlyingCreature),
			TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/blink") end),
			TimeEvent(14*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/emote_flame") end),
            TimeEvent(50*FRAMES, RaiseFlyingCreature),
		},
	},
}

local idle_anim_weights = {3, 2, 1}
local function idle_anim_fn(inst)
	local num = weighted_random_choice(idle_anim_weights)
	inst.sg.statemem.anim_num = num
	return num == 1 and "idle_loop" or ("idle_loop"..num)
end

SGCritterStates.AddIdle(states, #emotes, 
	{
		TimeEvent(5*FRAMES, function(inst) if inst.sg.statemem.anim_num == 2 then inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/blink") end end),
	},
	idle_anim_fn)

SGCritterStates.AddRandomEmotes(states, emotes)
SGCritterStates.AddEmote(states, "cute", 
	{
		TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/blink") end),
		TimeEvent(6*FRAMES, LandFlyingCreature),
        TimeEvent(14*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/blink") end),
		TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/swipe") end),
		TimeEvent(42*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/blink") end),
        TimeEvent(57*FRAMES, RaiseFlyingCreature),
		TimeEvent(59*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/blink") end),
	})
SGCritterStates.AddCombatEmote(states,
	{
		pre =
		{
			TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/emote_combat") end),
            TimeEvent(10*FRAMES, LandFlyingCreature),
		},
		loop =
		{
			TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/emote_combat_2") end),
            TimeEvent(0*FRAMES, LandFlyingCreature),
		},
		pst =
		{
            TimeEvent(0*FRAMES, LandFlyingCreature),
			TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/blink") end),
            TimeEvent(8*FRAMES, RaiseFlyingCreature),
		},
	})
SGCritterStates.AddPlayWithOtherCritter(states, events,
	{
		active =
		{
			TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/emote") end),
			TimeEvent(33*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/emote") end),
		},
		passive = 
		{
            TimeEvent(8*FRAMES, LandFlyingCreature),
			TimeEvent(57*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/blink") end),
            TimeEvent(62*FRAMES, RaiseFlyingCreature),
		},
	},
    {
        inactive = RaiseFlyingCreature,
    })
SGCritterStates.AddEat(states,
    {
        TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/eat_pre") end),
        TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/blink") end),
        
        TimeEvent(26*FRAMES, LandFlyingCreature),

        TimeEvent((28+0)*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/eat") end),
        TimeEvent((28+10)*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/eat") end),

        TimeEvent((28+24+0)*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/eat") end),
        TimeEvent((28+24+6)*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/blink") end),
        
        TimeEvent((28+24+10)*FRAMES, RaiseFlyingCreature),
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
        TimeEvent(2*FRAMES, LandFlyingCreature),
        TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/emote") end),
        TimeEvent(50*FRAMES, RaiseFlyingCreature),
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
    RaiseFlyingCreature(inst)
end

SGCritterStates.AddPetEmote(states, 
	{
		TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/blink") end),
        TimeEvent(4*FRAMES, function(inst)
            StopFlapping(inst)
            LandFlyingCreature(inst)
        end),
		TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/emote") end),
        TimeEvent(27*FRAMES, StartFlapping),
        TimeEvent(50*FRAMES, RaiseFlyingCreature),
	},
    function(inst)
        RestoreFlapping(inst)
        RaiseFlyingCreature(inst)
    end)

CommonStates.AddSleepExStates(states,
	{
		starttimeline =
		{
			TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/sleep_pre") end),
            TimeEvent(18*FRAMES, LandFlyingCreature),
            TimeEvent(44*FRAMES, StopFlapping),
			TimeEvent(48*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/sleep") end),
		},
		sleeptimeline = 
		{
			TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/sleep") end),
			TimeEvent(52*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/sleep") end),
		},
		waketimeline = 
		{
			TimeEvent(2*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/dragonling/blink") end),
            TimeEvent(12*FRAMES, StartFlapping),
            TimeEvent(18*FRAMES, RaiseFlyingCreature),
		},
	},
    {
        onexitsleep = CleanupIfSleepInterrupted,
        onexitsleeping = CleanupIfSleepInterrupted,
        onsleeping = LandFlyingCreature,
        onexitwake = function(inst)
            RestoreFlapping(inst)
            RaiseFlyingCreature(inst)
        end,
        onwake = function(inst)
            StopFlapping(inst)
            LandFlyingCreature(inst)
        end,
    })

return StateGraph("SGcritter_lunarmoth", states, events, "idle", actionhandlers)
