CommonStates = {}
CommonHandlers = {}

--------------------------------------------------------------------------
local function onstep(inst)
    if inst.SoundEmitter ~= nil then
        inst.SoundEmitter:PlaySound("dontstarve/movement/run_dirt")
        --inst.SoundEmitter:PlaySound("dontstarve/movement/walk_dirt")
    end
end

CommonHandlers.OnStep = function()
    return EventHandler("step", onstep)
end

--------------------------------------------------------------------------
local function onsleep(inst)
    if inst.components.health ~= nil and not inst.components.health:IsDead() then
        inst.sg:GoToState(inst.sg:HasStateTag("sleeping") and "sleeping" or "sleep")
    end
end

CommonHandlers.OnSleep = function()
    return EventHandler("gotosleep", onsleep)
end

--------------------------------------------------------------------------
local function onfreeze(inst)
    if inst.components.health ~= nil and not inst.components.health:IsDead() then
        inst.sg:GoToState("frozen")
    end
end

CommonHandlers.OnFreeze = function()
    return EventHandler("freeze", onfreeze)
end

--------------------------------------------------------------------------
local function onattacked(inst, data)
    if inst.components.health ~= nil and not inst.components.health:IsDead()
        and (not inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("frozen")) then
        inst.sg:GoToState("hit")
    end
end

CommonHandlers.OnAttacked = function()
    return EventHandler("attacked", onattacked)
end

--------------------------------------------------------------------------
local function onattack(inst)
    if inst.components.health ~= nil and not inst.components.health:IsDead()
        and (not inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("hit")) then
        inst.sg:GoToState("attack")
    end
end

CommonHandlers.OnAttack = function()
    return EventHandler("doattack", onattack)
end

--------------------------------------------------------------------------
local function ondeath(inst, data)
    inst.sg:GoToState("death", data)
end    

CommonHandlers.OnDeath = function()
    return EventHandler("death", ondeath)
end

--------------------------------------------------------------------------
CommonHandlers.OnLocomote = function(can_run, can_walk)
    return EventHandler("locomote", function(inst)
        local is_moving = inst.sg:HasStateTag("moving")
        local is_running = inst.sg:HasStateTag("running")
        local is_idling = inst.sg:HasStateTag("idle")

        local should_move = inst.components.locomotor:WantsToMoveForward()
        local should_run = inst.components.locomotor:WantsToRun()

        if is_moving and not should_move then
            inst.sg:GoToState(is_running and "run_stop" or "walk_stop")
        elseif (is_idling and should_move) or (is_moving and should_move and is_running ~= should_run and can_run and can_walk) then
            if can_run and (should_run or not can_walk) then
                inst.sg:GoToState("run_start")
            elseif can_walk then
                inst.sg:GoToState("walk_start")
            end
        end
    end)
end

--------------------------------------------------------------------------
CommonStates.AddIdle = function(states, funny_idle_state, anim_override, timeline)
    table.insert(states, State
    {
        name = "idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst, pushanim)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end

            local anim =
                (anim_override == nil and "idle_loop") or
                (type(anim_override) ~= "function" and anim_override) or
                anim_override(inst)

            --pushanim could be bool or string?
            if pushanim then
                if type(pushanim) == "string" then
                    inst.AnimState:PlayAnimation(pushanim)
                end
                inst.AnimState:PushAnimation(anim, true)
            elseif not inst.AnimState:IsCurrentAnimation(anim) then
                inst.AnimState:PlayAnimation(anim, true)
            end
        end,

        timeline = timeline,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState(math.random() < .1 and funny_idle_state or "idle")
                end
            end),
        },
    })
end

--------------------------------------------------------------------------
CommonStates.AddSimpleState = function(states, name, anim, tags, finishstate)
    table.insert(states, State
    {
        name = name,
        tags = tags or {},

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation(anim)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState(finishstate or "idle")
                end
            end),
        },
    })
end

--------------------------------------------------------------------------
local function performbufferedaction(inst)
    inst:PerformBufferedAction()
end

--------------------------------------------------------------------------
CommonStates.AddSimpleActionState = function(states, name, anim, time, tags, finishstate)
    table.insert(states, State
    {
        name = name,
        tags = tags or {},

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation(anim)
        end,

        timeline =
        {
            TimeEvent(time, performbufferedaction),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState(finishstate or "idle")
                end
            end),
        },
    })
end

--------------------------------------------------------------------------
CommonStates.AddShortAction = function(states, name, anim, timeout, finishstate)
    table.insert(states, State
    {
        name = "name",
        tags = { "doing" },

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation(anim)
            inst.sg:SetTimeout(timeout or 6 * FRAMES)
        end,

        ontimeout = performbufferedaction,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState(finishstate or "idle")
                end
            end),
        },
    })
end

--------------------------------------------------------------------------
local function idleonanimover(inst)
    if inst.AnimState:AnimDone() then
        inst.sg:GoToState("idle")
    end
end

--------------------------------------------------------------------------
local function get_loco_anim(inst, override, default)
    return (override == nil and default)
        or (type(override) ~= "function" and override)
        or override(inst)
end

--------------------------------------------------------------------------
local function runonanimover(inst)
    if inst.AnimState:AnimDone() then
        inst.sg:GoToState("run")
    end
end

local function runontimeout(inst)
    inst.sg:GoToState("run")
end

CommonStates.AddRunStates = function(states, timelines, anims, softstop)
    table.insert(states, State
    {
        name = "run_start",
        tags = { "moving", "running", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation(get_loco_anim(inst, anims ~= nil and anims.startrun or nil, "run_pre"))
        end,

        timeline = timelines ~= nil and timelines.starttimeline or nil,

        events =
        {
            EventHandler("animover", runonanimover),
        },
    })

    table.insert(states, State
    {
        name = "run",
        tags = { "moving", "running", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:RunForward()
            local anim_to_play = get_loco_anim(inst, anims ~= nil and anims.run or nil, "run_loop")
            if not inst.AnimState:IsCurrentAnimation(anim_to_play) then
                inst.AnimState:PlayAnimation(anim_to_play, true)
            end
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,

        timeline = timelines ~= nil and timelines.runtimeline or nil,

        ontimeout = runontimeout,
    })

    table.insert(states, State
    {
        name = "run_stop",
        tags = { "idle" },

        onenter = function(inst) 
            inst.components.locomotor:StopMoving()
            if softstop == true or (type(softstop) == "function" and softstop(inst)) then
                inst.AnimState:PushAnimation(get_loco_anim(inst, anims ~= nil and anims.stoprun or nil, "run_pst"))
            else
                inst.AnimState:PlayAnimation(get_loco_anim(inst, anims ~= nil and anims.stoprun or nil, "run_pst"))
            end
        end,

        timeline = timelines ~= nil and timelines.endtimeline or nil,

        events =
        {
            EventHandler("animover", idleonanimover),
        },
    })
end

--------------------------------------------------------------------------
CommonStates.AddSimpleRunStates = function(states, anim, timelines)
    CommonStates.AddRunStates(states, timelines, { startrun = anim, run = anim, stoprun = anim } )
end

--------------------------------------------------------------------------
local function walkonanimover(inst)
    if inst.AnimState:AnimDone() then
        inst.sg:GoToState("walk")
    end
end

local function walkontimeout(inst)
    inst.sg:GoToState("walk")
end

CommonStates.AddWalkStates = function(states, timelines, anims, softstop)
    table.insert(states, State
    {
        name = "walk_start",
        tags = { "moving", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation(get_loco_anim(inst, anims ~= nil and anims.startwalk or nil, "walk_pre"))
        end,

        timeline = timelines ~= nil and timelines.starttimeline or nil,

        events =
        {
            EventHandler("animover", walkonanimover),
        },
    })

    table.insert(states, State
    {
        name = "walk",
        tags = { "moving", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            local anim_to_play = get_loco_anim(inst, anims ~= nil and anims.walk or nil, "walk_loop")
            if not inst.AnimState:IsCurrentAnimation(anim_to_play) then
                inst.AnimState:PlayAnimation(anim_to_play, true)
            end
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,

        timeline = timelines ~= nil and timelines.walktimeline or nil,

        ontimeout = walkontimeout,
    })

    table.insert(states, State
    {
        name = "walk_stop",
        tags = { "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            if softstop == true or (type(softstop) == "function" and softstop(inst)) then
                inst.AnimState:PushAnimation(get_loco_anim(inst, anims ~= nil and anims.stopwalk or nil, "walk_pst"))
            else
                inst.AnimState:PlayAnimation(get_loco_anim(inst, anims ~= nil and anims.stopwalk or nil, "walk_pst"))
            end
        end,

        timeline = timelines ~= nil and timelines.endtimeline or nil,

        events =
        {
            EventHandler("animover", idleonanimover),
        },
    })
end

--------------------------------------------------------------------------
CommonStates.AddSimpleWalkStates = function(states, anim, timelines)
    CommonStates.AddWalkStates(states, timelines, { startwalk = anim, walk = anim, stopwalk = anim }, true)
end

--------------------------------------------------------------------------
local function sleeponanimover(inst)
    if inst.AnimState:AnimDone() then
        inst.sg:GoToState("sleeping")
    end
end

local function onwakeup(inst)
    inst.sg:GoToState("wake")
end

local function onentersleeping(inst)
    inst.AnimState:PlayAnimation("sleep_loop")
end

CommonStates.AddSleepStates = function(states, timelines, fns)
    table.insert(states, State
    {
        name = "sleep",
        tags = { "busy", "sleeping" },

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("sleep_pre")
            if fns ~= nil and fns.onsleep ~= nil then
                fns.onsleep(inst)
            end
        end,

        timeline = timelines ~= nil and timelines.starttimeline or nil,

        events =
        {
            EventHandler("animover", sleeponanimover),
            EventHandler("onwakeup", onwakeup),
        },
    })

    table.insert(states, State
    {
        name = "sleeping",
        tags = { "busy", "sleeping" },

        onenter = onentersleeping,

        timeline = timelines ~= nil and timelines.sleeptimeline or nil,

        events =
        {
            EventHandler("animover", sleeponanimover),
            EventHandler("onwakeup", onwakeup),
        },
    })

    table.insert(states, State
    {
        name = "wake",
        tags = { "busy", "waking" },

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("sleep_pst")
            if inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
                inst.components.sleeper:WakeUp()
            end
            if fns ~= nil and fns.onwake ~= nil then
                fns.onwake(inst)
            end
        end,

        timeline = timelines ~= nil and timelines.waketimeline or nil,

        events =
        {
            EventHandler("animover", idleonanimover),
        },
    })
end

--------------------------------------------------------------------------
local function onenterfrozen(inst)
    if inst.components.locomotor ~= nil then
        inst.components.locomotor:StopMoving()
    end
    inst.AnimState:PlayAnimation("frozen")
    inst.SoundEmitter:PlaySound("dontstarve/common/freezecreature")
    inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
end

local function onexitfrozen(inst)
    inst.AnimState:ClearOverrideSymbol("swap_frozen")
end

local function onunfreeze(inst)
    inst.sg:GoToState(inst.sg.sg.states.hit ~= nil and "hit" or "idle")
end

local function onthaw(inst)
    inst.sg:GoToState("thaw")
end

local function onenterthaw(inst)
    if inst.components.locomotor ~= nil then
        inst.components.locomotor:StopMoving()
    end
    inst.AnimState:PlayAnimation("frozen_loop_pst", true)
    inst.SoundEmitter:PlaySound("dontstarve/common/freezethaw", "thawing")
    inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
end

local function onexitthaw(inst)
    inst.SoundEmitter:KillSound("thawing")
    inst.AnimState:ClearOverrideSymbol("swap_frozen")
end

CommonStates.AddFrozenStates = function(states)
    table.insert(states, State
    {
        name = "frozen",
        tags = { "busy", "frozen" },

        onenter = onenterfrozen,

        events =
        {
            EventHandler("unfreeze", onunfreeze),
            EventHandler("onthaw", onthaw),
        },

        onexit = onexitfrozen,
    })

    table.insert(states, State
    {
        name = "thaw",
        tags = { "busy", "thawing" },

        onenter = onenterthaw,

        events =
        {
            EventHandler("unfreeze", onunfreeze),
        },

        onexit = onexitthaw,
    })
end

--------------------------------------------------------------------------
CommonStates.AddCombatStates = function(states, timelines, anims)
    table.insert(states, State
    {
        name = "hit",
        tags = { "hit", "busy" },

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end

            local hitanim =
                ((anims == nil or anims.hit == nil) and "hit") or
                (type(anims.hit) ~= "function" and anims.hit) or
                anims.hit(inst)

            inst.AnimState:PlayAnimation(hitanim)

            if inst.SoundEmitter ~= nil and inst.sounds ~= nil and inst.sounds.hit ~= nil then
                inst.SoundEmitter:PlaySound(inst.sounds.hit)
            end
        end,

        timeline = timelines ~= nil and timelines.hittimeline or nil,

        events =
        {
            EventHandler("animover", idleonanimover),
        },
    })

    table.insert(states, State
    {
        name = "attack",
        tags = { "attack", "busy" },

        onenter = function(inst, target)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation(anims ~= nil and anims.attack or "atk")
            inst.components.combat:StartAttack()

            --V2C: Cached to force the target to be the same one later in the timeline
            --     e.g. combat:DoAttack(inst.sg.statemem.target)
            inst.sg.statemem.target = target
        end,

        timeline = timelines ~= nil and timelines.attacktimeline or nil,

        events =
        {
            EventHandler("animover", idleonanimover),
        },
    })

    table.insert(states, State
    {
        name = "death",
        tags = { "busy" },

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation(anims ~= nil and anims.death or "death")
            inst.Physics:ClearCollisionMask()
            inst.components.lootdropper:DropLoot(inst:GetPosition())
        end,

        timeline = timelines ~= nil and timelines.deathtimeline or nil,
    })
end
