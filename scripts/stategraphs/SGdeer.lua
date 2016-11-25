require("stategraphs/commonstates")

local actionhandlers = 
{

}

local events=
{
    CommonHandlers.OnLocomote(true,true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),

    EventHandler("growantler", function(inst)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            inst.sg:GoToState("growantler")
        else
            inst.sg.mem.wantstogrowantler = true
        end
    end),

}

local states=
{   
    State{        
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim)
			if inst.components.locomotor ~= nil then
				inst.components.locomotor:StopMoving()
			end
			
			if inst.sg.mem.wantstogrowantler then
				inst.sg.mem.wantstogrowantler = nil
                inst.sg:GoToState("growantler")
			else
	            inst.AnimState:PlayAnimation("idle_loop")
	        end
        end,

        timeline = 
        { 
        },

        events=
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },
    
    State{        
        name = "growantler",
        tags = {"busy", "canrotate"},
        onenter = function(inst, playanim)
			if inst.components.locomotor ~= nil then
				inst.components.locomotor:StopMoving()
			end
			
            inst.AnimState:PlayAnimation("hit")
        end,

        timeline = 
        { 
			TimeEvent(6*FRAMES, function(inst) inst:ShowAntler() end),
        },

		onexit = function(inst)
			inst:ShowAntler()
		end,

        events=
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "alert",
        tags = {"idle", "canrotate"},
        
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("alert_pre")
            inst.AnimState:PushAnimation("alert_idle", true)
        end,
    },
}

CommonStates.AddWalkStates(states)
CommonStates.AddRunStates(states)

CommonStates.AddCombatStates(states,
{
    attacktimeline = 
    {
        TimeEvent(12*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
        TimeEvent(15*FRAMES, function(inst) inst.sg:RemoveStateTag("attack") end),
    },
    deathtimeline = 
    {
        TimeEvent(0*FRAMES, function(inst)
            inst:AddTag("dead")
        end),
        TimeEvent(34*FRAMES, function(inst)
            inst.Light:Enable(false)
            inst.AnimState:ClearBloomEffectHandle()
        end),
    },
})
CommonStates.AddFrozenStates(states)
CommonStates.AddSleepStates(states,
{
    startsleeptimeline = 
    {
    },
    sleeptimeline = 
    {
    },
})

return StateGraph("deer", states, events, "idle", actionhandlers)