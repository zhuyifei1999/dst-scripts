require("stategraphs/commonstates")

local function startaura(inst)
    inst.Light:SetColour(255/255, 32/255, 32/255)
    inst.SoundEmitter:PlaySound(inst:HasTag("girl") and "dontstarve/ghost/ghost_girl_attack_LP" or "dontstarve/ghost/ghost_attack_LP", "angry")
    inst.AnimState:SetMultColour(207/255, 92/255, 92/255, 1)
end

local function stopaura(inst)
    inst.Light:SetColour(180/255, 195/255, 225/255)
    inst.SoundEmitter:KillSound("angry")
    inst.AnimState:SetMultColour(1, 1, 1, 1)
end

local events =
{
    CommonHandlers.OnLocomote(true, true),
    EventHandler("startaura", startaura),
    EventHandler("stopaura", stopaura),
    EventHandler("attacked", function(inst)
        if not inst.components.health:IsDead() then
            inst.sg:GoToState("hit")
        end
    end),
    EventHandler("death", function(inst)
        inst.sg:GoToState("dissipate")
    end),
}

local function getidleanim(inst)
    return ((inst.components.combat:HasTarget() or inst.components.aura.applying) and "angry")
        or (inst.components.health:GetPercent() < .25 and "shy")
        or "idle"
end

local states =
{
    State
    {
        name = "idle",
        tags = { "idle", "canrotate", "canslide" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation(getidleanim(inst), true)
        end,
    },

    State
    {
        name = "appear",

        onenter = function(inst)
            inst.AnimState:PlayAnimation("appear")
            inst.SoundEmitter:PlaySound(inst:HasTag("girl") and "dontstarve/ghost/ghost_girl_howl" or "dontstarve/ghost/ghost_howl")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.components.aura:Enable(true)
        end,
    },

    State{
        name = "hit",
        tags = { "busy" },

        onenter = function(inst)
            inst.SoundEmitter:PlaySound(inst:HasTag("girl") and "dontstarve/ghost/ghost_girl_howl" or "dontstarve/ghost/ghost_howl")
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
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
        name = "haunted",
        tags = { "busy" },

        onenter = function(inst)
            inst.SoundEmitter:PlaySound(inst:HasTag("girl") and "dontstarve/ghost/ghost_girl_attack_LP" or "dontstarve/ghost/ghost_attack_LP", "haunted")
            inst.AnimState:PlayAnimation("angry")
            inst.Physics:Stop()
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("haunted")
        end
    },

    State{
        name = "dissipate",

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("dissipate")
            inst.SoundEmitter:PlaySound(inst:HasTag("girl") and "dontstarve/ghost/ghost_girl_howl" or "dontstarve/ghost/ghost_howl")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.components.lootdropper ~= nil then
                        inst.components.lootdropper:DropLoot()
                    end
                    inst:PushEvent("detachchild")
                    inst:Remove()
                end
            end)
        },
    },
}

CommonStates.AddSimpleWalkStates(states, getidleanim)
CommonStates.AddSimpleRunStates(states, getidleanim)

return StateGraph("ghost", states, events, "appear")
