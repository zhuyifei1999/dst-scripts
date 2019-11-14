require("stategraphs/commonstates")


local actionhandlers = 
{
    ActionHandler(ACTIONS.GOHOME, "action"),
}

local events=
{
    CommonHandlers.OnLocomote(true, true),
}

local states=
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("idle_loop", true)
        end,
    },
    
    State{
        name = "arrive",
        tags = {"busy", "canrotate"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("spawn_in")
        end,

        events =
        {
	        EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
    },
    
    State{
        name = "leave",
        tags = {"busy"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("spawn_out")
			inst.persists = false
        end,

        events =
        {
	        EventHandler("animqueueover", function(inst) inst:Remove() end),
		},
    },

}

CommonStates.AddWalkStates(states)
CommonStates.AddRunStates(states)

return StateGraph("sgoceanfish", states, events, "idle", actionhandlers)
