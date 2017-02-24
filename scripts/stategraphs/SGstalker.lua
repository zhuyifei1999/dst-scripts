require("stategraphs/commonstates")

--------------------------------------------------------------------------

local function ShakeIfClose(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .5, .02, .2, inst, 30)
end

local function ShakeRoar(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, 1.2, .03, .7, inst, 30)
end

local function ShakeSnare(inst)
    ShakeAllCameras(CAMERASHAKE.VERTICAL, .5, .03, .7, inst, 30)
end

local function ShakeDeath(inst)
    ShakeAllCameras(CAMERASHAKE.VERTICAL, .6, .02, .4, inst, 30)
end

--------------------------------------------------------------------------

local function BlinkHigh(inst)
    inst.AnimState:SetAddColour(1, 1, 1, 0)
end

local function BlinkMed(inst)
    inst.AnimState:SetAddColour(.3, .3, .3, 0)
end

local function BlinkLow(inst)
    inst.AnimState:SetAddColour(.2, .2, .2, 0)
end

local function BlinkOff(inst)
    inst.AnimState:SetAddColour(0, 0, 0, 0)
end

--------------------------------------------------------------------------

local events =
{
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnDeath(),
    EventHandler("doattack", function(inst)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            inst.sg:GoToState("attack")
        end
    end),
    EventHandler("fossilsnare", function(inst, data)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) and
            data ~= nil and data.targets ~= nil and #data.targets > 0 then
            inst.sg:GoToState("snare", data.targets)
        end
    end),
    EventHandler("attacked", function(inst)
        if not inst.components.health:IsDead() and
            (not inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("caninterrupt")) and
            (inst.sg.mem.last_hit_time or 0) + TUNING.STALKER_HIT_RECOVERY < GetTime() then
            inst.sg:GoToState("hit")
        end
    end),
    EventHandler("roar", function(inst)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            inst.sg:GoToState("taunt")
        elseif not inst.sg:HasStateTag("roar") then
            inst.sg.mem.wantstoroar = true
        end
    end),
}

local states =
{
    State{
        name = "idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            if inst.sg.mem.wantstoroar then
                inst.sg:GoToState("taunt")
            else
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("idle")
            end
        end,

        timeline =
        {
            TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/in") end),
            TimeEvent(26 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/out") end),
        },

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
        name = "resurrect",
        tags = { "busy", "noattack" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.components.health:SetInvincible(true)
            inst.Transform:SetNoFaced()
            inst.AnimState:PlayAnimation("enter")
            inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_get_bloodpump")
        end,

        timeline =
        {
            TimeEvent(18 * FRAMES, BlinkLow),
            TimeEvent(19 * FRAMES, BlinkOff),

            TimeEvent(29 * FRAMES, BlinkLow),
            TimeEvent(30 * FRAMES, function(inst)
                BlinkOff(inst)
                ShakeIfClose(inst)
                inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_use_bloodpump")
            end),

            TimeEvent(31 * FRAMES, BlinkMed),
            TimeEvent(32 * FRAMES, BlinkLow),
            TimeEvent(33 * FRAMES, BlinkOff),

            TimeEvent(37 * FRAMES, BlinkMed),
            TimeEvent(38 * FRAMES, BlinkLow),
            TimeEvent(39 * FRAMES, BlinkOff),

            TimeEvent(40 * FRAMES, BlinkMed),
            TimeEvent(41 * FRAMES, BlinkOff),

            TimeEvent(42 * FRAMES, function(inst)
                BlinkMed(inst)
                ShakeIfClose(inst)
                inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_use_bloodpump", nil, .3)
            end),
            TimeEvent(43 * FRAMES, BlinkLow),
            TimeEvent(44 * FRAMES, BlinkOff),

            TimeEvent(50 * FRAMES, BlinkMed),
            TimeEvent(51 * FRAMES, BlinkLow),
            TimeEvent(52 * FRAMES, BlinkOff),

            TimeEvent(54 * FRAMES, BlinkMed),
            TimeEvent(55 * FRAMES, BlinkLow),
            TimeEvent(56 * FRAMES, BlinkOff),

            TimeEvent(57 * FRAMES, function(inst)
                BlinkHigh(inst)
                ShakeIfClose(inst)
                inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_use_bloodpump")
            end),
            TimeEvent(58 * FRAMES, BlinkOff),

            TimeEvent(60 * FRAMES, BlinkMed),
            TimeEvent(61 * FRAMES, BlinkLow),
            TimeEvent(62 * FRAMES, BlinkOff),
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
            inst.Transform:SetFourFaced()
            inst.components.health:SetInvincible(false)
            BlinkOff(inst)
        end,
    },

    State{
        name = "walk_start",
        tags = { "moving", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("walk_pre")
        end,

        timeline =
        {
            TimeEvent(14 * FRAMES, function(inst)
                inst.components.locomotor:WalkForward()
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("walk")
                end
            end),
        },
    },

    State{
        name = "walk",
        tags = { "moving", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_loop", true)
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,

        timeline =
        {
            TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/footstep") end),
            TimeEvent(15 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/footstep") end),
            TimeEvent(32 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/footstep") end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("walk")
        end,
    },

    State{
        name = "walk_stop",
        tags = { "canrotate" },

        onenter = function(inst) 
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("walk_pst")
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
        name = "hit",
        tags = { "hit", "busy" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("hit")
            inst.sg.mem.last_hit_time = GetTime()
        end,

        timeline =
        {
            TimeEvent(16 * FRAMES, function(inst)
                if not inst.components.health:IsDead() then
                    if inst.sg.statemem.dosnare then
                        local targets = inst:FindSnareTargets()
                        if targets ~= nil then
                            inst.sg:GoToState("snare", targets)
                            return
                        end
                    end
                    if inst.sg.statemem.doattack then
                        inst.sg:GoToState("attack")
                        return
                    end
                end
                inst.sg.statemem.doattack = nil
                inst.sg.statemem.dosnare = nil
                inst.sg:RemoveStateTag("busy")
            end),
        },

        events =
        {
            EventHandler("doattack", function(inst)
                inst.sg.statemem.doattack = true
            end),
            EventHandler("fossilsnare", function(inst)
                inst.sg.statemem.dosnare = true
            end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if not inst.components.health:IsDead() then
                        if inst.sg.statemem.dosnare then
                            local targets = inst:FindSnareTargets()
                            if targets ~= nil then
                                inst.sg:GoToState("snare", targets)
                                return 
                            end
                        end
                        if inst.sg.statemem.doattack then
                            inst.sg:GoToState("attack")
                            return
                        end
                    end
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "death",
        tags = { "busy" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("death")
            inst:AddTag("NOCLICK")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/death")
        end,

        timeline =
        {
            TimeEvent(15 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/death_pop") end),
            TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/death_pop") end),
            TimeEvent(21 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/death_pop") end),
            TimeEvent(24 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/death_pop") end),
            TimeEvent(27 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/death_pop") end),
            TimeEvent(30 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/death_pop") end),
            TimeEvent(30 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/death_bone_drop") end),
            TimeEvent(55 * FRAMES, function(inst)
                if inst.persists then
                    inst.persists = false
                    inst.components.lootdropper:DropLoot(inst:GetPosition())
                end
            end),
            TimeEvent(55.5 * FRAMES, ShakeDeath),
            TimeEvent(5, ErodeAway),
        },

        onexit = function(inst)
            --Should NOT happen!
            inst:RemoveTag("NOCLICK")
        end,
    },

    State{
        name = "taunt",
        tags = { "busy", "roar" },

        onenter = function(inst)
            inst.sg.mem.wantstoroar = nil
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("taunt1")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/out")
        end,

        timeline =
        {
            TimeEvent(14 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/taunt") end),
            TimeEvent(18 * FRAMES, ShakeRoar),
            TimeEvent(19 * FRAMES, function(inst)
                inst.components.epicscare:Scare(5)
            end),
            TimeEvent(58 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
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
    },

    State{
        name = "attack",
        tags = { "attack", "busy" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("attack")
            inst.components.combat:StartAttack()
            inst.sg.statemem.target = inst.components.combat.target
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/out")
        end,

        timeline =
        {
            TimeEvent(13 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/attack_swipe") end),
            TimeEvent(32 * FRAMES, function(inst)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
            end),
            TimeEvent(63 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
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
    },

    State{
        name = "snare",
        tags = { "attack", "busy", "snare" },

        onenter = function(inst, targets)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("attack1")
            --V2C: don't trigger attack cooldown
            --inst.components.combat:StartAttack()
            inst.components.timer:StartTimer("snare_cd", TUNING.STALKER_SNARE_CD)
            inst.sg.statemem.targets = targets
        end,

        timeline =
        {
            TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/attack1_pbaoe_pre") end),
            TimeEvent(24 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/attack1_pbaoe") end),
            TimeEvent(25.5 * FRAMES, function(inst)
                ShakeSnare(inst)
                inst.components.combat:DoAreaAttack(inst, 3.5, nil, nil, nil, { "INLIMBO", "notarget", "invisible", "noattack", "flight", "playerghost", "shadow", "shadowchesspiece", "shadowcreature" })
                if inst.sg.statemem.targets ~= nil then
                    inst:SpawnSnares(inst.sg.statemem.targets)
                end
            end),
            TimeEvent(39 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
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
    },
}

return StateGraph("SGstalker", states, events, "idle")
