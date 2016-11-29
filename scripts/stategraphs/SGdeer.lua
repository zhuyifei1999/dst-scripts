require("stategraphs/commonstates")

local events =
{
    CommonHandlers.OnLocomote(true, true),
    CommonHandlers.OnSleepEx(),
    CommonHandlers.OnWakeEx(),
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

local states =
{
    State{
        name = "idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst, playanim)
            if inst.sg.mem.wantstogrowantler then
                inst.sg:GoToState("growantler")
            else
                if inst.components.locomotor ~= nil then
                    inst.components.locomotor:StopMoving()
                end

                inst.AnimState:PlayAnimation("idle_loop")
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "alert",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("alert_pre")
            inst.AnimState:PushAnimation("alert_idle", true)
        end,
    },

    State{
        name = "growantler",
        tags = { "busy" },
        onenter = function(inst)
            inst.sg.mem.wantstogrowantler = nil

            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end

            inst.AnimState:PlayAnimation("hit")
        end,

        timeline =
        { 
            TimeEvent(6 * FRAMES, function(inst)
                inst:ShowAntler()
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst:ShowAntler()
        end,
    },
}

CommonStates.AddWalkStates(states)
CommonStates.AddRunStates(states)
CommonStates.AddCombatStates(states,
{
    attacktimeline =
    {
        TimeEvent(12 * FRAMES, function(inst)
            inst.components.combat:DoAttack(inst.sg.statemem.target)
        end),
        TimeEvent(15 * FRAMES, function(inst)
            inst.sg:RemoveStateTag("attack")
        end),
    },
})
CommonStates.AddFrozenStates(states)
CommonStates.AddSleepExStates(states)

return StateGraph("deer", states, events, "idle")
