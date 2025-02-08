require("stategraphs/commonstates")
require("stategraphs/SGcritter_common")

local actionhandlers =
{
    ActionHandler(ACTIONS.WOBY_PICKUP, "pickup"),
    ActionHandler(ACTIONS.GIVEALLTOPLAYER, "give"),
    ActionHandler(ACTIONS.WOBY_PICK, "dolongaction"),
}

local LONGACTION_DEFAULT_TIMEOUT = 1.5

local events =
{
    SGCritterEvents.OnEat(),
    SGCritterEvents.OnAvoidCombat(),
    SGCritterEvents.OnTraitChanged(),

    CommonHandlers.OnSleepEx(),
    CommonHandlers.OnWakeEx(),
    CommonHandlers.OnLocomote(false,true),
    CommonHandlers.OnHop(),
    CommonHandlers.OnSink(),
    CommonHandlers.OnFallInVoid(),

    EventHandler("transform", function(inst, data)
        if inst.sg.currentstate.name ~= "transform" then
            inst.sg:GoToState("transform")
        end
    end),

    EventHandler("start_sitting", function(inst)
        if not inst.sg:HasStateTag("sitting") and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("sitting")
        end
    end),
}

-----------------------------------------------------------------------------------------------------------------------

local states =
{
        State{
        name="transform",
        tags = {"busy"},

        onenter = function(inst, data)
            inst.components.locomotor:StopMoving()
			inst:ApplyBigBuildOverrides()
            inst.AnimState:PlayAnimation("transform_small_to_big")
			inst:AddTag("transforming")
        end,

        timeline =
        {
            TimeEvent(1*FRAMES,  function(inst) inst.SoundEmitter:PlaySound("dontstarve/characters/walter/woby/transform_small_to_big") end),
			FrameEvent(37, function(inst)
				if inst.components.wobyrack then
					inst.SoundEmitter:PlaySound("meta5/woby/big_dryingrack_deploy")
				end
			end),
			FrameEvent(40, function(inst)
				if inst.pet_hunger_classified then
					inst.pet_hunger_classified:SetFlagBit(0, true) --big woby
				end
			end),
            TimeEvent(41*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/characters/walter/woby/big/roar") end),
            TimeEvent(42*FRAMES, function(inst) inst.DynamicShadow:SetSize(3, 1.5) end),
            TimeEvent(53*FRAMES, function(inst) inst.DynamicShadow:SetSize(5, 2) end),
            TimeEvent(80*FRAMES, function(inst)
                inst:FinishTransformation()
            end),
        },

		onexit = function(inst)
			--Interrupted???
			if inst.pet_hunger_classified then
				inst.pet_hunger_classified:SetFlagBit(0, false) --small woby
			end
			inst:RemoveTag("transforming")
		end,
    },

    State{
        name = "despawn",
        tags = {"busy", "nointerrupt"},

        onenter = function(inst, pushanim)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("idle_loop", true)
        end,

        onexit = function(inst)
            inst:DoTaskInTime(0, inst.Remove)
        end,
    },

    State{
        name = "pickup",
        tags = {"busy", "jumping"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            inst.AnimState:PlayAnimation("fetch")
            inst.AnimState:SetFrame(6)

            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil

            if target ~= nil and target:IsValid() then
                inst:ForceFacePoint(buffaction.target.Transform:GetWorldPosition())
            end
        end,

        onupdate = function(inst)
            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil

            if target == nil or not target:IsValid() then
                inst.Physics:ClearMotorVelOverride()
				inst.Physics:Stop()

                inst:ClearBufferedAction()

                return
            end

            local distance = math.sqrt(inst:GetDistanceSqToInst(target))

            if distance > .2 then
                inst.Physics:SetMotorVelOverride(math.max(distance, 4), 0, 0)
            else
                inst.Physics:ClearMotorVelOverride()
				inst.Physics:Stop()
            end
        end,

        timeline = {
            TimeEvent((21-6)*FRAMES, function(inst)
                local buffaction = inst:GetBufferedAction()
                local target = buffaction ~= nil and buffaction.target or nil
    
                if target == nil or not target:IsValid() then
                    inst.sg.statemem.missed = true

                    return -- Fail! No target.
                end

                local distance = math.sqrt(inst:GetDistanceSqToInst(target))

                if distance > .5 then
                    inst:ClearBufferedAction()

                    inst.sg.statemem.missed = true
                else
                    inst:PerformBufferedAction()
                end
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("pickup_pst", inst.sg.statemem.missed)
                end
            end)
        },

        onexit = function(inst)
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.Physics:ClearMotorVelOverride()
            inst.Physics:Stop()
        end,
    },

    State{
        name = "pickup_pst",
        tags = {"busy", "jumping"},

        onenter = function(inst, missed)
            inst.components.locomotor:StopMoving()

            inst.AnimState:PlayAnimation(missed and "fetch_fail_pst" or "fetch_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end)
        },
    },

    State {
        name = "give",
        tags = {"busy"},

        onenter = function(inst)
            inst.components.locomotor:Stop()

            inst.AnimState:PlayAnimation("give")
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
            FrameEvent(10, function(inst)
                inst:PerformBufferedAction()
            end),
        },
    },

    State{
        name = "dolongaction",
		tags = {"busy"},

        onenter = function(inst, timeout)
            timeout = timeout or LONGACTION_DEFAULT_TIMEOUT

            inst.components.locomotor:Stop()

            inst.AnimState:PlayAnimation("woby_forage_pre")
            inst.AnimState:PushAnimation("woby_forage_loop", true)

            inst.SoundEmitter:PlaySound("dontstarve/wilson/make_trap", "make")

            inst.sg.statemem.buffaction = inst:GetBufferedAction()

            inst.sg:SetTimeout(timeout)
        end,

        ontimeout = function(inst)
            inst.AnimState:PlayAnimation("woby_forage_pst")
            inst.SoundEmitter:KillSound("make")

            inst:PerformBufferedAction()
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),

            EventHandler("playernewstate", function(inst)
                if inst.sg.statemem.buffaction == inst.bufferedaction then
                    local pickable = inst.bufferedaction.target ~= nil and inst.bufferedaction.target.components.pickable or nil

                    if pickable ~= nil and pickable:CanBePicked() then -- If we can be picked, Walter didn't finish it!
                        inst.AnimState:PlayAnimation("woby_forage_pst")
                        inst.SoundEmitter:KillSound("make")

                        inst:ClearBufferedAction()
                    end
                end
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("make")
        end,
    },

    State{
        name = "sitting",
		tags = {"busy", "canrotate", "sitting"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            if inst.sg.lasttags["moving"] then
                inst.AnimState:PlayAnimation("walk_pst")
                inst.AnimState:PushAnimation("sit_woby")
            else
                inst.AnimState:PlayAnimation("sit_woby")
            end

            inst.AnimState:PushAnimation("sit_woby_loop", true)

            inst.sg.statemem.noleashing = inst.components.follower.noleashing

            inst.components.follower:DisableLeashing()
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),

            EventHandler("stop_sitting", function(inst)
                if inst:IsAsleep() then
                    inst.sg:GoToState("idle")
                else
                    inst.AnimState:PlayAnimation("sit_woby_pst")
                end
            end),
        },

        onexit = function(inst)
            if not inst.sg.statemem.noleashing then
                inst.components.follower:EnableLeashing()
            end
        end
    },
}

local emotes =
{
    { anim="emote_scratch",
      timeline=
         {
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/emote_scratch") end),
            TimeEvent(26*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/emote_scratch") end),
            TimeEvent(35*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/emote_scratch") end),
            TimeEvent(45*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/emote_scratch") end),
            TimeEvent(55*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/emote_scratch") end),
        },
    },
    { anim="emote_play_dead",
      timeline=
         {
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/pant") end),
            TimeEvent(48*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/pant") end),
            TimeEvent(76*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/characters/walter/woby/small/bark") end),
        },
    },
}

SGCritterStates.AddIdle(states, #emotes,
	--[[{
        --TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/pant") end),
	}]]nil,
	function(inst)
		if inst.sg.mem.recentlytransformed then
			if inst.sg.lasttags and inst.sg.lasttags["idle"] then
				return "idle_loop_nodir"
			end
			inst.sg.mem.recentlytransformed = nil
		end
		return "idle_loop"
	end)
SGCritterStates.AddRandomEmotes(states, emotes)
SGCritterStates.AddEmote(states, "cute",
    {
        TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/stallion") end),
        TimeEvent(14*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/stallion") end),
        TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/stallion") end),
        TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/stallion") end),
        TimeEvent(25*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/stallion") end),
        TimeEvent(29*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/stallion") end),
        TimeEvent(34*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/sheepington/stallion") end),
    })
SGCritterStates.AddPetEmote(states,
    {
        TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/tail") end),
        TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/tail") end),
        TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/tail") end),
        TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/tail") end),
    })
SGCritterStates.AddCombatEmote(states,
    {
        pre =
        {
            TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/characters/walter/woby/small/bark") end),
        },
        loop =
        {
            TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/characters/walter/woby/small/bark") end),
            TimeEvent(26*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/pant") end),
            TimeEvent(34*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/pant") end),
            TimeEvent(48*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/characters/walter/woby/small/bark") end),
        },
    })
SGCritterStates.AddPlayWithOtherCritter(states, events,
    {
        active =
        {
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/growl") end),
            TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/growl") end),
        },
        passive =
        {
            TimeEvent(5*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/pant") end),
            TimeEvent(14*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/pant") end),
        },
    })
SGCritterStates.AddEat(states,
    {
        TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/characters/walter/woby/small/eat") end),
    })


SGCritterStates.AddHungry(states,
    {
        TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/characters/walter/woby/small/bark") end),
    })
SGCritterStates.AddNuzzle(states, actionhandlers,
    {
        TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/emote_scratch") end),
        TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/sleep") end),
        TimeEvent(35*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/emote_scratch") end),
        TimeEvent(36*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/sleep") end),
    })

SGCritterStates.AddWalkStates(states,
    {
        starttimeline =
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/pant") end),
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/pant") end),
        },
        walktimeline =
        {
            TimeEvent(1*FRAMES, function(inst) PlayFootstep(inst, 0.25) end),
            TimeEvent(4*FRAMES, function(inst) PlayFootstep(inst, 0.25) end),
        },
    }, true)

CommonStates.AddSleepExStates(states,
    {
        starttimeline =
        {
            TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/growl") end),
        },
        sleeptimeline =
        {
            TimeEvent(14*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/pupington/sleep") end),
        },
    })

CommonStates.AddHopStates(states, true)
CommonStates.AddSinkAndWashAshoreStates(states)
CommonStates.AddVoidFallStates(states)

return StateGraph("wobysmall", states, events, "idle", actionhandlers)
