require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.TOSS,
        function(inst, action)
            if not inst.sg:HasStateTag('busy') then
                inst.sg:GoToState("shoot", action.target) 
            end
        end),    
}

local events =
{
    CommonHandlers.OnLocomote(false, true),

    EventHandler("death", function(inst)
		inst.sg:GoToState("death", "death")
	end),
    EventHandler("arrive", function(inst)
        inst.sg:GoToState("glide")
    end),    

    EventHandler("doattack", function(inst)
        if not (inst.sg:HasStateTag("busy")) then
            inst.sg:GoToState("attack")
        end
    end), 

    EventHandler("locomote", function(inst)
        local is_moving = inst.sg:HasStateTag("moving")
        local is_running = inst.sg:HasStateTag("running")
        local is_idling = inst.sg:HasStateTag("idle")

        local should_move = inst.components.locomotor:WantsToMoveForward()
        local should_run = inst.components.locomotor:WantsToRun()

        --if is_moving and not should_move then        
        if not inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("moving") then
            inst.sg:GoToState("walk")    
        end
        --end
    end),

}

local states=
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
		
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("idle",true)
            inst.sg:SetTimeout(math.random() *2 )
        end,
        
        ontimeout = function(inst)
            inst.sg:GoToState("idle_taunt")
        end,

        events =
        {
           -- EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "idle_taunt",
        tags = {"busy", "canrotate"},
        
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("caw")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "emerge",
        tags = {"busy", "noattack", "canrotate"},
		
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("land")
        end,

        timeline=
        {
            --TimeEvent(5*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/rabbit/hop") end ),
        },
        
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "death",
        tags = {"busy", "noattack"},
		
        onenter = function(inst)
            inst.components.locomotor:Stop()
            RemovePhysicsColliders(inst)
            inst.AnimState:PlayAnimation("death")
            inst.persists = false
        end,

        events =
        {
      --      EventHandler("animover", function(inst) inst:Remove() end),
        },

        onexit = function(inst)
        end,
    },


    State{
        name = "attack",
        tags = { "busy", "attack"},
		
        onenter = function(inst)
            inst.AnimState:PlayAnimation("attack")
			inst.components.locomotor:Stop()
			if inst.components.combat.target ~= nil then
				inst:ForceFacePoint(inst.components.combat.target.Transform:GetWorldPosition())
			end
	        inst.components.combat:StartAttack()
		end,
        
        timeline=
        {
            TimeEvent(8*FRAMES, function(inst) 
					inst.components.combat:DoAttack()
                    inst.sg:RemoveStateTag("attack")
                    inst.sg:RemoveStateTag("busy")
                    inst.components.combat.target = nil
				end ),
        },
        
        events =
        {
            EventHandler("animover", function(inst) 
				inst.sg:GoToState("idle") 
			end),
        },
    },

    State{
        name = "shoot",
        tags = { "attack", "busy" },

        onenter = function(inst, target)
            if not target then
                target = inst.components.combat.target
            end

            if target then
                inst.sg.statemem.target = target
            end

            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("attack")
        end,

        timeline =
        {   
            TimeEvent(14*FRAMES, function(inst)
                if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                    inst.sg.statemem.spitpos = Vector3(inst.sg.statemem.target.Transform:GetWorldPosition())            
                    inst:LaunchProjectile(inst.sg.statemem.spitpos)

                    inst.components.timer:StopTimer("spit_cooldown")
                    inst.components.timer:StartTimer("spit_cooldown", 3 + math.random()*3)
                end
            end),
        },

        events =
        {
            EventHandler("animover",function(inst) 
                inst.sg:GoToState("idle")
            end),
        },
    },    

    State{
        name = "walk",
        tags = { "moving", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("hop")

        end,

        onexit = function(inst)
            inst.components.locomotor:StopMoving()    
        end,

        timeline =
        {   
            TimeEvent(4*FRAMES, function(inst)
                inst.components.locomotor:WalkForward()
            end),
            TimeEvent(10*FRAMES, function(inst)
                inst.components.locomotor:StopMoving()
            end),            
        },

        events =
        {
            EventHandler("animover",function(inst)  
                if math.random() < 0.1 then
                    inst.sg:GoToState("walk_wait_caw")
                else
                    inst.sg:GoToState("walk_wait")
                end
            end),
        },
    },

    State{
        name = "walk_wait",
        tags = { "moving" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("idle", true)
            inst.sg:SetTimeout(math.random() *2 )
        end,
        
        ontimeout = function(inst)
            inst.sg:GoToState("walk")
        end,
    },

    State{
        name = "walk_wait_caw",
        tags = { "moving" },

        onenter = function(inst)
                    print("TAUNT")
            inst.AnimState:PlayAnimation("caw")
        end,
        events =
        {
            EventHandler("animover",function(inst)                
                inst.sg:GoToState("walk")
            end),
        },
    },


    State{
        name = "walk_stop",
        tags = { "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.sg:GoToState("idle")
        end,
    },

    State{
        name = "glide",
        tags = { "busy" },
        onenter = function(inst)
            inst.Physics:SetDamping(0)
            inst.Physics:SetMotorVel(0, math.random() * 10 - 20, 0)
            inst.AnimState:PlayAnimation("glide", true)
        end,

        onupdate = function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            if y < 2 then
                inst.Physics:SetMotorVel(0, 0, 0)
                if y <= .1 then
                    inst.Physics:Stop()
                    inst.Physics:SetDamping(5)
                    inst.Physics:Teleport(x, 0, z)
                    inst.sg:GoToState("idle", true)
                end
            end
        end,

        onexit = function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            inst.Transform:SetPosition(x, 0, z)
        end,
    },

    State{
        name = "land",
        tags = { "busy" },
        onenter = function(inst)
            inst.AnimState:PlayAnimation("land")
        end,
        events =
        {
            EventHandler("animover",function(inst)
                inst.AnimState:PlayAnimation("idle")                
            end),
        },
    },    
}

return StateGraph("bird_mutant", states, events, "idle", actionhandlers)