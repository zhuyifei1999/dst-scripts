-- TODO
--  Attack idle state needs to check to see if it attack
--      move newcombat event handling to stategraph
--
require("stategraphs/commonstates")

local EMERGE_MIN = 10
local EMERGE_MIN2 = EMERGE_MIN*EMERGE_MIN 
local EMERGE_MAX = 15
local EMERGE_MAX2 = EMERGE_MAX*EMERGE_MAX

local events=
{
    EventHandler("attacked", function(inst) 
        if not inst.components.health:IsDead()
            and not inst.sg:HasStateTag("hit")
            and not inst.sg:HasStateTag("attack") then 
            inst.sg:GoToState("hit")
        end
    end),
    EventHandler("newcombattarget", function(inst)
        if inst.components.combat.target ~= nil
            and inst.sg:HasStateTag("attack_idle") then -- other cases are handled within the stategraph.
            inst.sg:GoToState("attack")
        end
    end),
    EventHandler("death", function(inst)
        inst.sg:GoToState("death")
    end),
    EventHandler("emerge", function(inst)
        if inst.sg:HasStateTag("retracted") then
            inst.sg:GoToState("emerge")
        end
    end),
    EventHandler("retract", function(inst)
        if inst.sg:HasStateTag("emerged") then
            inst.sg:GoToState("retract")
        end
    end),
    EventHandler("full_retreat", function(inst)
        if not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("full_retreat")
        end
    end),
    CommonHandlers.OnFreeze(),
}

local states=
{
    State{
        name = "idle",
        tags = {"idle", "retracted"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("breach_pre", true)
            inst.AnimState:PushAnimation("breach_loop", true)
            inst.sg:SetTimeout(GetRandomWithVariance(7, 2) )
            inst.SoundEmitter:KillAllSounds()
        end,
    },

    State{
        name = "attack_idle",
        tags = {"attack_idle", "emerged"},
        onenter = function(inst)
            local speed = GetRandomWithVariance(0.9, 0.1)
            inst.AnimState:PlayAnimation("atk_idle")
            inst.AnimState:SetDeltaTimeMultiplier(speed)
            inst.SoundEmitter:KillAllSounds()
        end,

        events=
        {
            EventHandler("animover", function(inst)
                if inst.retracted == true then
                    inst.sg:GoToState("retract")
                elseif inst.components.combat.target then
                    inst.sg:GoToState("attack")
                else
                    inst.sg:GoToState("attack_idle")
                end
            end)
        },
    },

    State{
        name ="emerge",
        tags = {"emerge"},
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/tentacle/smalltentacle_emerge")
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:SetDeltaTimeMultiplier(GetRandomWithVariance(0.9, 0.1))
            inst.SoundEmitter:SetParameter( "tentacle", "state", 1)
        end,
        events=
        {
            EventHandler("animover", function(inst)
                if inst.retracted == true then
                    inst.sg:GoToState("retract")
                elseif inst.components.combat.target then
                    inst.sg:GoToState("attack")
                else
                    inst.sg:GoToState("attack_idle")
                end
            end)
        },
        timeline=
        {
            -- TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_emerge_VO") end),
        }

    },

    State{
        name = "attack",
        tags = {"attack"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("atk_loop")
            inst.AnimState:SetDeltaTimeMultiplier(GetRandomWithVariance(1.0, 0.05))
            inst.components.combat:StartAttack()
        end,

        timeline=
        {
            TimeEvent(2*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/tentacle/smalltentacle_attack") end),
            TimeEvent(7*FRAMES, function(inst) inst.components.combat:DoAttack() end),
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/tentacle/smalltentacle_attack") end),
            TimeEvent(17*FRAMES, function(inst) inst.components.combat:DoAttack() end),
            TimeEvent(18*FRAMES, function(inst) inst.sg:RemoveStateTag("attack") end),
        },

        events=
        {
            EventHandler("animover", function(inst)
                if inst.retracted == true then
                    inst.sg:GoToState("retract")
                elseif inst.components.combat.target then
                    inst.sg:GoToState("attack")
                else
                    inst.sg:GoToState("attack_idle")
                end
            end),
        },
    },

    State{
        name ="retract",
        tags = {"retract"},
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/tentacle/smalltentacle_disappear")
            inst.AnimState:PlayAnimation("atk_pst")
            inst.AnimState:SetDeltaTimeMultiplier(GetRandomWithVariance(1.0, 0.05))
        end,
        events=
        {
            EventHandler("animover", function(inst)
                if inst.retracted == false then
                    inst.sg:GoToState("emerge")
                else
                    inst.SoundEmitter:KillAllSounds()
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst, data)
            --inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentapiller_hurt_VO")
            inst.AnimState:PlayAnimation("death")
            inst.AnimState:SetDeltaTimeMultiplier(GetRandomWithVariance(0.8, 0.2))
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
        end,

        events =
        {
            EventHandler("animover",
            function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_splat")
            end ),
        },
    },

    State{  -- main pillar ordering us to hide
        name ="full_retreat",
        tags = {"busy"},
        onenter = function(inst)
            inst.SoundEmitter:KillAllSounds() -- kill sound, may be a bunch of arms retreating at the same time
            if inst.retracted then
                inst:Remove()
            else
                inst.AnimState:PlayAnimation("atk_pst")
            end
            inst.AnimState:SetDeltaTimeMultiplier(GetRandomWithVariance(0.8, 0.2))
        end,
        events=
        {
            EventHandler("animover", function(inst)
                inst:Remove()
            end),
        },
    },

    State{
        name = "hit",
        tags = {"busy", "hit"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentapiller_hurt_VO")
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("attack_idle") end),
        },
    },
}

CommonStates.AddFrozenStates(states)

return StateGraph("tentacle", states, events, "idle")

