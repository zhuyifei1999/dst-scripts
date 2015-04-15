require("stategraphs/commonstates")

local actionhandlers=
{

}

local events=
{
}

local states=
{
	State{
		name = "idle",
		tags = {"idle"},

		onenter = function(inst)
			inst.AnimState:PlayAnimation("idle_loop", false)
			-- inst.SoundEmitter:PlaySound("dontstarve/common/spawn/spawnportal_blink")
			inst.SoundEmitter:PlaySound("dontstarve/common/spawn/spawnportal_jacob")
			if not inst.idle_sound_playing then
				inst.SoundEmitter:PlaySound("dontstarve/common/spawn/spawnportal_idle", "portalidle")
				inst.idle_sound_playing = true
			end
        end,

        events = {
        	EventHandler("animover", function(inst) 
        		if math.random() < .7 then
        			inst.sg:GoToState("idle")
        		else 
        			inst.sg:GoToState("funnyidle")
        		end
        	end),
    	},

    	timeline = {
    		TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/spawn/spawnportal_jacob") end),
    		TimeEvent(59*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/spawn/spawnportal_blink") end),
    	},
	},

	State{
        name = "funnyidle",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
			inst.AnimState:PlayAnimation("idle_eyescratch", false)
			-- inst.SoundEmitter:PlaySound("dontstarve/common/spawn/spawnportal_blink")
			inst.SoundEmitter:PlaySound("dontstarve/common/spawn/spawnportal_jacob")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },

        timeline = 
        {
        	TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/spawn/spawnportal_scratch") end),
        	TimeEvent(27*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/spawn/spawnportal_scratch") end),
        	TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/spawn/spawnportal_jacob") end),
        	TimeEvent(41*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/spawn/spawnportal_scratch") end),
        	TimeEvent(59*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/spawn/spawnportal_blink") end),
    	},
    },

	State{
		name = "spawn_pre",
		tags = {"idle", "open"},
		onenter = function(inst)
			inst.AnimState:PlayAnimation("pre_fx", false)
			inst.SoundEmitter:KillSound("portalidle")
			inst.idle_sound_playing = false
			inst.SoundEmitter:PlaySound("dontstarve/common/spawn/spawnportal_spawning", "portalactivate")
			inst.SoundEmitter:PlaySound("dontstarve/common/spawn/spawnportal_armswing")
			inst.SoundEmitter:PlaySound("dontstarve/common/spawn/spawnportal_shake")
		end,

		events = 
		{
			EventHandler("animover", function(inst) 
				inst.sg:GoToState("spawn_loop")
			end),
		},

		timeline = 
		{
			TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/spawn/spawnportal_blink") end),
		},
	},

	State{
		name = "spawn_loop",
		tags = {"busy", "open"},
		onenter = function(inst)
			inst.AnimState:PlayAnimation("fx", false)
			if not inst.idle_sound_playing then
				inst.SoundEmitter:PlaySound("dontstarve/common/spawn/spawnportal_idle", "portalidle")
				inst.idle_sound_playing = true
			end
		end,

		events = 
		{
			EventHandler("animover", function(inst) 
				inst.sg:GoToState("spawn_pst")
			end),
		},

		timeline =
		{
			TimeEvent(55*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/spawn/spawnportal_open") end),
		},
	},
		
	State{
		name = "spawn_pst",
		tags = {"busy"},
		onenter = function(inst)
			inst.AnimState:PlayAnimation("pst_fx", false)
			inst.SoundEmitter:KillSound("portalactivate")
		end,

		events=
		{
			EventHandler("animover", function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/common/spawn/spawnportal_blink")
				inst.sg:GoToState("idle")
			end),
		},

		timeline = 
		{
			TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/spawn/spawnportal_armswing") end)
		},
	},
}

return StateGraph("multiplayer_portal", states, events, "idle", actionhandlers)
