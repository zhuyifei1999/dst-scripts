require "stategraphs/commonstates"

local function ondeathfn(inst, data)
    if not inst.sg:HasStateTag("deactivating") then
        inst.sg:GoToState("death", data)
    end
end

local actionhandlers =
{
    ActionHandler(ACTIONS.TAUNT, function(inst)
        if not inst.sg:HasStateTag("deactivating") then
            return "taunt"
        end
    end),
}

local events =
{
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnAttacked(),
    EventHandler("death", ondeathfn),
}

local states =
{
    State{
        name = "idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_loop", true)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/idle")
        end,
    },

    State{
        name = "taunt",
        tags = { "busy", "taunt" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            inst:PerformBufferedAction()
        end,

        onexit = function(inst)
            inst.components.timer:StartTimer("taunt_cd", 4)
        end,

        timeline = 
        {
            --3, 12, 21, 30
            TimeEvent(FRAMES*3, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/taunt") end),
            TimeEvent(FRAMES*12, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/taunt") end),
            TimeEvent(FRAMES*21, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/taunt") end),
            TimeEvent(FRAMES*30, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/taunt") end),
            --10, 20, 28, 36
            TimeEvent(FRAMES*10, PlayFootstep),
            TimeEvent(FRAMES*20, PlayFootstep),
            TimeEvent(FRAMES*28, PlayFootstep),
            TimeEvent(FRAMES*36, PlayFootstep),
            
            TimeEvent(FRAMES*20, function(inst) inst.sg:RemoveStateTag("busy") end),
        },

        events = 
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "hit",
        tags = { "busy" },
        
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/hit")
        end,

        events = 
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "death",
        tags = { "busy", "deactivating" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("death")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/death")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst:GoInactive() end),
        },
    },

    State{
        name = "activate",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("activate")
        end,
        
        timeline =
        {
            TimeEvent(5*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/sit_up")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "deactivate",
        tags = { "busy", "deactivating" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("deactivate")
        end,

        timeline =
        {
            TimeEvent(5*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/sit_down")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst:GoInactive() end),
        },
    },
}

CommonStates.AddWalkStates(states,
{
    walktimeline = {
        TimeEvent(10*FRAMES, function(inst) 
            PlayFootstep(inst) 
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/walk")
        end),
        TimeEvent(30*FRAMES, function(inst) 
            PlayFootstep(inst) 
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/walk")
        end),
    },
    endtimeline = {
        TimeEvent(3*FRAMES, function(inst) 
            PlayFootstep(inst) 
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/walk")
        end),
    },
})

return StateGraph("bernie", states, events, "activate", actionhandlers)
