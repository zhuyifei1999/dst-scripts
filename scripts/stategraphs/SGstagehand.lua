require("stategraphs/commonstates")

local prefabs =
{
    "collapse_small",
}


local actionhandlers = 
{
}

local events=
{
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("worked", function(inst) inst.sg:GoToState("hit") end),
    EventHandler("workfinished", function(inst) inst.sg:GoToState("giveup") end),
    EventHandler("onignite", function(inst) if not inst.sg:HasStateTag("givingup") then inst.sg:GoToState("extinguish") end end),
    
	EventHandler("locomote", function(inst)
        local is_moving = inst.sg:HasStateTag("moving")
        local is_idling = inst.sg:HasStateTag("idle")
        local is_busy = inst.sg:HasStateTag("busy")

        local should_move = inst.components.locomotor:WantsToMoveForward()

        if is_moving and not should_move then
            inst.sg:GoToState("walk_stop")
        elseif (is_idling and should_move) or (is_moving and should_move) then
            if inst.sg.is_hiding then
                inst.sg:GoToState("standup")
            elseif is_busy then
				print "HERE"
                inst.sg:GoToState("walk_start")
            end
        end
    end),

    
}


local states=
{
	State{
        name = "initailstate",
        
        onenter = function(inst)
			inst.sg.is_hiding = true
            ChangeToObstaclePhysics(inst)
			inst.sg:GoToState("idle_hiding")
		end,
	},
	
    State{
        name = "death",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.Physics:Stop()            
			RemovePhysicsColliders(inst)            
			inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))

			local fx = SpawnPrefab("collapse_small")
			fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
			fx:SetMaterial("pot")

			inst:Remove()
        end,

    },
   
    State{
        name = "idle",
        onenter = function(inst)
			if (not inst:CanStandUp()) and not inst.components.locomotor:WantsToMoveForward() then
				inst.sg:GoToState("idle_hiding")
			else
				inst.sg:GoToState("idle_standing")
			end
        end
    },
   
    State{
        name = "idle_standing",
        tags = {"idle", "canrotate"},
        
        onenter = function(inst)
            inst.Physics:Stop()
            local animname = "idle"
          
            if inst.sg.is_hiding then
                inst.sg:GoToState("standup")
            else
	            inst.sg.is_hiding = false
                inst.AnimState:PlayAnimation("awake_idle")
            end
            
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },        
    },
        
    State{
        name = "idle_hiding",
        tags = {"idle", "hiding"},
        
        onenter = function(inst)
            inst.Physics:Stop()
            local animname = "idle"
			
            if not inst.sg.is_hiding then
                inst.sg:GoToState("hide")
            else
	            inst.sg.is_hiding = true
	            
	            local anim = "idle_loop_01"
	            if TheWorld.state.isdusk then
					local chance = math.random()
					if chance < 0.02 then
						anim = "peeking_idle_loop_01"
					elseif chance < 0.04 then
						anim = "peeking_idle_loop_02"
					end
				elseif TheWorld.state.isnight then
					local chance = math.random()
					if chance < 0.2 then
						anim = "peeking_idle_loop_01"
					elseif chance < 0.4 then
						anim = "peeking_idle_loop_02"
					end
	            end
	            inst.AnimState:PlayAnimation(anim)
            end

        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },        
    },
    
    State{
        name = "hide",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("sleep")
            inst.sg.is_hiding = true
            ChangeToObstaclePhysics(inst)
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },    
    
    State{
        name = "standup",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("awake_pre")
        end,
        
        events=
        {
            EventHandler("animover", function(inst) 
                inst.sg.is_hiding = false
                ChangeToCharacterPhysics(inst)
                inst.Physics:SetMass(inst.CharacterPhyscisMass)
                inst.sg:GoToState(inst.components.locomotor:WantsToMoveForward() and "walk_start" or "idle") end
            ),
        },
    },    
    
    State{
        name = "hit",
        tags = {"busy"},
        
        onenter = function(inst)
--            inst.SoundEmitter:PlaySound(inst.sounds.hit)
            inst.AnimState:PlayAnimation(inst.sg.is_hiding and "hit" or "awake_hit")
            inst.Physics:Stop()            
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },        
    },    
    
    State{
        name = "extinguish",
        tags = {"busy"},
        
        onenter = function(inst)
			if inst.sg.is_hiding then
	            inst.AnimState:PlayAnimation("extinguish")
		        inst.Physics:Stop()            
		    else
				inst.sg:GoToState("hide")
		    end
        end,
        
        timeline=
        {
	        TimeEvent(20*FRAMES, function(inst) inst.components.burnable:Extinguish() end ),
	    },
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },        
    },    
    
    State{
        name = "giveup",
        tags = {"busy", "givingup"},
        
        onenter = function(inst)
			if inst.sg.is_hiding then
	            inst.AnimState:PlayAnimation("extinguish")
		        inst.Physics:Stop()            
		    else
				inst.sg:GoToState("hide")
		    end
        end,
		
		onexit = function(inst)
		    inst.components.workable:SetWorkLeft(TUNING.STAGEHAND_HITS_TO_GIVEUP)
		end,
		
        timeline=
        {
	        TimeEvent(14*FRAMES, function(inst) inst.components.lootdropper:SpawnLootPrefab("endtable_blueprint", inst:GetPosition()) end ),
	    },
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },        
    },    
    
    
    
    
}

CommonStates.AddWalkStates(states,
{
	walktimeline = {
		TimeEvent(0*FRAMES, PlayFootstep ),
		TimeEvent(5*FRAMES, PlayFootstep ),
		TimeEvent(12*FRAMES, PlayFootstep ),
		TimeEvent(17*FRAMES, PlayFootstep ),
	},
})

return StateGraph("stagehand", states, events, "initailstate", actionhandlers)

