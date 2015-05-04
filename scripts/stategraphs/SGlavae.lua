require("stategraphs/commonstates")

-- Lavae doesn't want to change his target to attackers.
local function onattackedfn(inst, data)
	if inst.components.health and not inst.components.health:IsDead() and 
	(not inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("frozen")) then
		inst.sg:GoToState("hit")
	end
end

local function ondeathfn(inst, data)
	if inst.sg:HasStateTag("frozen") or inst.sg:HasStateTag("thawing") then
		inst.sg:GoToState("thaw_break", data)
	else
		inst.sg:GoToState("death", data)
	end
end

local actionhandlers =
{
	ActionHandler(ACTIONS.GOHOME, "gohome"),
}

local events =
{
    CommonHandlers.OnLocomote(false, true),
    EventHandler("attacked", onattackedfn),
    EventHandler("death", ondeathfn),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
}

local function SpawnMoveFx(inst)
    SpawnPrefab("lavae_move_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local states =
{
	State{
		name = "idle",
		tags = {"idle"},

		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("idle", true)
		end,
	},

	State{
		name = "attack",
		tags = {"attack", "canrotate", "busy", "jumping"},

		onenter = function(inst, target)
			inst.components.locomotor:Stop()
			inst.components.locomotor:EnableGroundSpeedMultiplier(false)

			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("atk_pre")
			inst.AnimState:PushAnimation("atk")
			inst.AnimState:PushAnimation("atk_pst", false)
		end,

		onexit = function(inst)
			inst.components.locomotor:Stop()
			inst.components.locomotor:EnableGroundSpeedMultiplier(true)
		end,

		timeline =
		{
			TimeEvent(16*FRAMES, function(inst) 
				inst.Physics:SetMotorVelOverride(20,0,0) 
			end),
			TimeEvent(21*FRAMES, function(inst)
				inst.components.combat:DoAttack()
			end),
			TimeEvent(23*FRAMES, function(inst)                     
				inst.Physics:ClearMotorVelOverride()
				inst.components.locomotor:Stop() 
			end),
		},

		events =
		{
			EventHandler("animqueueover", function(inst) inst.sg:GoToState("taunt") end),
		}
	},
	
	State{
		name = "gohome",
		tags = {"busy"},

		onenter = function(inst)
			inst.components.locomotor:StopMoving()
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("taunt")
		end,

		events = 
		{
			EventHandler("animover", function(inst) inst:PerformBufferedAction() end),
		},
	},

	State{
		name = "taunt",
		tags = {"busy"},

		onenter = function(inst)
			inst.components.locomotor:StopMoving()
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("taunt")
		end,

		events = 
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
	},

	State{
		name = "hit",

		onenter = function(inst)
			inst.AnimState:PlayAnimation("hit")
			inst.Physics:Stop()
		end,

		events = 
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		}
	},

	State{
		name = "walk_start",
		tags = {"moving", "canrotate"},

		onenter = function(inst)
			inst.AnimState:PlayAnimation("walk_pre")
			inst.components.locomotor:WalkForward()
		end,

		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("walk") end),
		},		
	},

	State{
		name = "walk",
		tags = {"moving", "canrotate"},

		onenter = function(inst)
			inst.components.locomotor:WalkForward()
			inst.AnimState:PlayAnimation("walk_loop")
		end,

		timeline =
		{
			TimeEvent(0*FRAMES, SpawnMoveFx),
			TimeEvent(5*FRAMES, SpawnMoveFx),
			TimeEvent(10*FRAMES, SpawnMoveFx),
			TimeEvent(2.5*FRAMES, SpawnMoveFx),
			TimeEvent(7.5*FRAMES, SpawnMoveFx),
			TimeEvent(12.5*FRAMES, SpawnMoveFx),
		},

		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("walk") end),
		},
	},

	State{
		name = "walk_stop",
		tags = {"canrotate"},

		onenter = function(inst)
			if inst.components.locomotor then
				inst.components.locomotor:StopMoving()
			end
			inst.AnimState:PlayAnimation("walk_pst")
		end,

		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
	},

	State{
		name = "death",
		tags = {"busy"},

		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("death")
    		inst.components.lootdropper:SetChanceLootTable('lavae_lava')
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))  
		end,
	},

    State{
        name = "frozen",
        tags = {"busy", "frozen"},
        
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("frozen")
            inst.SoundEmitter:PlaySound("dontstarve/common/freezecreature")
        end,
        
        events =
        {   
            EventHandler("unfreeze", function(inst)	inst.components.health:Kill() end ),
            EventHandler("onthaw", function(inst) inst.sg:GoToState("thaw") end ),        
        },
    },

    State{
        name = "thaw",
        tags = {"busy", "thawing"},
        
        onenter = function(inst) 
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("frozen_loop_pst", true)
            inst.SoundEmitter:PlaySound("dontstarve/common/freezethaw", "thawing")
        end,
        
        onexit = function(inst)
            inst.SoundEmitter:KillSound("thawing")
        end,

        events =
        {   
            EventHandler("unfreeze", function(inst) inst.components.health:Kill() end),
        },
    },

    State{
        name = "thaw_break",
        tags = {"busy"},
        
        onenter = function(inst) 
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("shatter")
    		inst.components.lootdropper:SetChanceLootTable('lavae_frozen')
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))            
        end,
    },
}

CommonStates.AddSleepStates(states)

return StateGraph("lavae", states, events, "idle", actionhandlers)