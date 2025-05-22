require("stategraphs/commonstates")

local events =
{
	CommonHandlers.OnLocomote(false, true),
}

local states =
{
	State{
		name = "idle",
		tags = { "idle", "canrotate" },

		onenter = function(inst)
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("idle", true)
		end,
	},
}

CommonStates.AddWalkStates(states)

return StateGraph("alterguardian_phase4_lunarrift", states, events, "idle")
