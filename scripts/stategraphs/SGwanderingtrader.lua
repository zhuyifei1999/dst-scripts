require("stategraphs/commonstates")

-- NOTES(JBK): The wanderingtrader is very relaxed and slow moving.
-- Any pending state change should happen in a sluggish way.

local events = {
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnHop(),
    CommonHandlers.OnSink(),
    CommonHandlers.OnFallInVoid(),
    EventHandler("dotrade", function(inst, data)
        if not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("dotrade", data)
        end
    end),
    EventHandler("arrive", function(inst)
        inst.sg:GoToState("arrive")
    end),
}

local states = {
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("idle_hooded")
        end,

        onupdate = function(inst)
            if inst.sg.mem.trading then
                inst.sg:GoToState("trading_start")
            end
        end,

        events = {
            EventHandler("animover", function(inst)
                if inst.sg.mem.trading then
                    inst.sg:GoToState("trading_start")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "walk_start",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("walk_pre")
        end,

        events = {
            EventHandler("animover", function(inst)
                if inst.sg.mem.trading then
                    inst.sg:GoToState("walk_stop")
                else
                    inst.sg:GoToState("walk")
                end
            end),
        },
    },

    State{
        name = "walk",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_loop")
        end,
        onupdate = function(inst)
            if inst.sg.mem.trading then
                inst.sg:GoToState("walk_stop")
            end
        end,
        onexit = function(inst)
            inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "dappertrot")
        end,
        timeline = {
            TimeEvent(2*FRAMES, function(inst) PlayFootstep(inst) end),
            TimeEvent(8*FRAMES, function(inst) inst.components.locomotor:SetExternalSpeedMultiplier(inst, "dappertrot", 0.35) end),
            TimeEvent(16*FRAMES, function(inst) inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "dappertrot") end),
            TimeEvent(33*FRAMES, function(inst) PlayFootstep(inst) end),
            TimeEvent(35*FRAMES, function(inst) inst.components.locomotor:SetExternalSpeedMultiplier(inst, "dappertrot", 0.35) end),
            TimeEvent(43*FRAMES, function(inst) inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "dappertrot") end),
        },
        events = {
            EventHandler("animover", function(inst)
                if inst.sg.mem.trading then
                    inst.sg:GoToState("walk_stop")
                else
                    inst.sg:GoToState("walk")
                end
            end),
        },
    },

    State{
        name = "walk_stop",
        tags = {"canrotate"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("walk_pst")
        end,

        events = {
            EventHandler("animover", function(inst)
                if inst.sg.mem.trading then
                    inst.sg:GoToState("trading_start")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "trading_start",
        tags = {"canrotate"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("reveal")
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:IsCurrentAnimation("reveal") then
                    if inst.sg.mem.trading then
                        inst.AnimState:PlayAnimation("trade_pre")
                    else
                        inst.AnimState:PlayAnimation("conceal")
                    end
                elseif inst.AnimState:IsCurrentAnimation("trade_pre") then
                    if inst.sg.mem.trading then
                        inst.sg:GoToState("trading")
                    else
                        inst.sg:GoToState("trading_stop")
                    end
                else -- conceal
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },
    State{
        name = "trading",
        tags = {"canrotate"},

        onenter = function(inst, data)
            if data == nil or not data.repeating then
                inst:TryChatter("WANDERINGTRADER_STARTTRADING", math.random(#STRINGS.WANDERINGTRADER_STARTTRADING), 1.5)
            end
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("trade_loop")
        end,
        onupdate = function(inst)
            if not inst.sg.mem.trading then
                inst.sg:GoToState("trading_stop")
            end
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.sg.mem.trading then
                    inst.sg:GoToState("trading", {repeating = true,})
                else
                    inst.sg:GoToState("trading_stop")
                end
            end),
        },
    },
    State{
        name = "trading_stop",
        tags = {"canrotate"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("trade_pst")
            if inst.sg.mem.didtrade then
                inst:TryChatter("WANDERINGTRADER_ENDTRADING_MADETRADE", math.random(#STRINGS.WANDERINGTRADER_ENDTRADING_MADETRADE), 1.5)
                inst.sg.mem.didtrade = nil
            else
                inst:TryChatter("WANDERINGTRADER_ENDTRADING_NOTRADES", math.random(#STRINGS.WANDERINGTRADER_ENDTRADING_NOTRADES), 1.5)
            end
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:IsCurrentAnimation("trade_pst") then
                    if inst.sg.mem.trading then
                        inst.AnimState:PlayAnimation("trade_pre")
                    else
                        inst.AnimState:PlayAnimation("conceal")
                    end
                elseif inst.AnimState:IsCurrentAnimation("trade_pre") then
                    if inst.sg.mem.trading then
                        inst.sg:GoToState("trading")
                    else
                        inst.sg:GoToState("trading_stop")
                    end
                else -- conceal
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },
    State{
        name = "dotrade",
        tags = {"busy"},
        onenter = function(inst, data)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("trade_give")
            if data and data.no_stock then
                inst:DoChatter("WANDERINGTRADER_OUTOFSTOCK_FROMTRADES", math.random(#STRINGS.WANDERINGTRADER_OUTOFSTOCK_FROMTRADES), 15)
            else
                if not inst.sg.mem.didtrade then
                    inst:DoChatter("WANDERINGTRADER_DOTRADE", math.random(#STRINGS.WANDERINGTRADER_DOTRADE), 1.5)
                else
                    inst:TryChatter("WANDERINGTRADER_DOTRADE", math.random(#STRINGS.WANDERINGTRADER_DOTRADE), 1.5)
                end
            end
            inst.SoundEmitter:PlaySound("rifts4/rabbit_king/trade") -- FIXME(JBK): WT: Sounds.
        end,
        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("trading") -- Let this state get out of trading.
            end),
        },
    },

    State{
        name = "talking",
        tags = {"canrotate"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("talk")
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("talking")
            end),
        },
    },

    State{
        name = "teleport",
        tags = {"busy"},

        onenter = function(inst)
            inst.components.talker:ShutUp()
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("disappear")
        end,

        timeline = {
            FrameEvent(24, function(inst) inst.DynamicShadow:Enable(false) end),
        },

        onexit = function(inst)
            inst.DynamicShadow:Enable(true)
        end,

        events = {
            EventHandler("animover", function(inst)
                if inst.OnEntitySleep then
                    inst:OnEntitySleep()
                end
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "arrive",
        tags = {"busy"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("appear")
            inst.DynamicShadow:Enable(false)
        end,

        timeline = {
            FrameEvent(2, function(inst) inst.DynamicShadow:Enable(true) end),
        },

        onexit = function(inst)
            inst.DynamicShadow:Enable(true)
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "hide",

        onenter = function(inst)
            inst.components.talker:ShutUp()
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("disappear")
        end,

        timeline = {
            FrameEvent(24, function(inst) inst.DynamicShadow:Enable(false) end),
        },

        onexit = function(inst)
            inst.DynamicShadow:Enable(true)
        end,


        events = {
            EventHandler("animover", function(inst)
                if inst.OnEntitySleep then
                    inst:OnEntitySleep()
                end
            end),
        },
    },

    State{ -- Blank state to do absolutely nothing when removed from the scene.
        name = "hiding",
    },
}

CommonStates.AddSinkAndWashAshoreStates(states)
CommonStates.AddVoidFallStates(states)

return StateGraph("wanderingtrader", states, events, "idle")
