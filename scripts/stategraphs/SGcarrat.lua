require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.EAT, "eat"),
}

local events =
{
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnLocomote(true, true),
    EventHandler("trapped", function(inst) inst.sg:GoToState("trapped") end),
}

local function play_carrat_scream(inst)
    inst.SoundEmitter:PlaySound(inst.sounds.scream)
end

local states =
{
    State {
        name = "idle",
        tags = { "idle", "canrotate" },
        onenter = function(inst, playanim)
            inst.Physics:Stop()

            local play_special_idle = (math.random() > 0.85)

            if playanim then
                inst.AnimState:PlayAnimation(playanim)
                if play_special_idle then
                    inst.AnimState:PushAnimation("idle2", false)
                end
                inst.AnimState:PushAnimation("idle1", true)
            elseif not inst.AnimState:IsCurrentAnimation("idle1") and not inst.AnimState:IsCurrentAnimation("idle2") then
                if play_special_idle then
                    inst.AnimState:PlayAnimation("idle2", false)
                    inst.AnimState:PushAnimation("idle1", true)
                else
                    inst.AnimState:PlayAnimation("idle1", true)
                end
            end
            inst.sg:SetTimeout(1 + math.random()*1)
        end,

        ontimeout= function(inst)
            if ((inst.sg.mem.emerge_time or 0) + TUNING.CARRAT.EMERGED_TIME_LIMIT) < GetTime() then
                inst.sg:GoToState("submerge")
            else
                inst.sg:GoToState("idle")
            end
        end,
    },

    State {
        name = "submerge",
        tags = { "busy", "noattack" },

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.Physics:Stop()
            inst.Physics:SetActive(false)

            -- Ensure that we're facing to the right, to match what a planted carrat looks like after
            -- submerging. This prevents us from flipping much more obviously after we've prefabbed swapped
            -- in the "submerged" state.
            inst.Transform:SetNoFaced()

            inst.AnimState:PlayAnimation("submerge")
        end,

        timeline =
        {
            TimeEvent(5*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.submerge)
            end),
            TimeEvent(30*FRAMES, function(inst)
                inst.DynamicShadow:Enable(false)
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("submerged")
            end),
        },

        onexit = function(inst)
            inst.Physics:SetActive(true)
            inst.Transform:SetSixFaced()
        end,
    },

    State {
        name = "submerged",
        tags = { "busy", "noattack" },

        onenter = function(inst, playanim)
            inst.Physics:SetActive(false)
            inst.Transform:SetNoFaced()

            local planted = SpawnPrefab("carrat_planted")
            planted.Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst:Remove()
        end,

        onexit = function(inst)
            inst.Physics:SetActive(true)
            inst.Transform:SetSixFaced()
        end,
    },

    State {
        name = "emerge_fast",
        tags = { "busy", "noattack" },

        onenter = function(inst)
            inst.Physics:SetActive(false)
            inst.SoundEmitter:PlaySound(inst.sounds.emerge)
            inst.AnimState:PlayAnimation("emerge_fast")

            inst.sg.mem.emerge_time = GetTime()
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        timeline =
        {
            TimeEvent(5*FRAMES, function(inst)
                inst.DynamicShadow:Enable(true)
            end),
        },

        onexit = function(inst)
            inst.Physics:SetActive(true)
        end,
    },

    State {
        name = "eat",

        onenter = function(inst)
            inst:PerformBufferedAction()
            inst.Physics:SetActive(false)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_pre", false)
            inst.AnimState:PushAnimation("eat_loop", false)
            inst.AnimState:PushAnimation("eat_pst", false)
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("submerge")
                end
            end),
        },

        timeline =
        {
            TimeEvent(3*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.eat)
            end)
        },

        onexit = function(inst)
            inst.Physics:SetActive(true)
        end,
    },

    State {
        name = "stunned",
        tags = { "busy", "stunned" },

        onenter = function(inst, dont_play_sound)
            inst.Physics:Stop()
            if not dont_play_sound then
                inst.SoundEmitter:PlaySound(inst.sounds.stunned)
            end
            inst.AnimState:PlayAnimation("stunned_loop", true)
            inst.sg:SetTimeout(GetRandomWithVariance(6, 2))
            if inst.components.inventoryitem then
                inst.components.inventoryitem.canbepickedup = true
            end
        end,

        onexit = function(inst)
            if inst.components.inventoryitem then
                inst.components.inventoryitem.canbepickedup = false
            end
        end,
        
        ontimeout = function(inst)
            inst.sg:GoToState("idle", "stunned_pst")
        end,
    },

    State {
        name = "trapped",
        tags = { "busy", "trapped" },
        
        onenter = function(inst)
            inst.Physics:Stop()
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("stunned_loop", true)
            inst.sg:SetTimeout(1)
        end,
        
        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end,
    },

    State {
        name = "dug_up",
        tags = { "busy", "stunned" },

        onenter = function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.stunned)
            inst.AnimState:PlayAnimation("stunned_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("stunned", true)
                end
            end),
        },

        timeline =
        {
            TimeEvent(5*FRAMES, function(inst)
                inst.DynamicShadow:Enable(true)
            end),
        },
    },
}
CommonStates.AddSleepStates(states,
{
    sleeptimeline =
    {
        TimeEvent(30 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.sleep) end),
    },
})
CommonStates.AddFrozenStates(states)
CommonStates.AddHitState(states)
CommonStates.AddDeathState(states,
{
    TimeEvent(0, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.death) end),
})
CommonStates.AddWalkStates(states)
CommonStates.AddRunStates(states,
{
    starttimeline =
    {
        TimeEvent(0, function(inst)
            if (inst.components.inventoryitem == nil or inst.components.inventoryitem.owner == nil) then
                inst.SoundEmitter:PlaySound(inst.sounds.stunned)
            end
        end),
    },
    runtimeline =
    {
        TimeEvent(0, PlayFootstep),
    },
    endtimeline =
    {
        TimeEvent(0, PlayFootstep),
    },
})

return StateGraph("carrat", states, events, "emerge_fast", actionhandlers)
