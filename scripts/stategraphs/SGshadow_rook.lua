require("stategraphs/commonstates")
require("stategraphs/sgshadow_chesspieces")

local events =
{
    EventHandler("attacked", function(inst)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            inst.sg:GoToState("hit")
        end
    end),
    EventHandler("doattack", function(inst, data)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            inst.sg:GoToState("attack", data.target)
        end
    end),

    ShadowChessEvents.LevelUp(),
    ShadowChessEvents.OnDeath(),
	ShadowChessEvents.OnDespawn(),
    CommonHandlers.OnLocomote(false, true),
}

local states =
{
    State{
        name = "attack",
        tags ={ "attack", "busy" },

        onenter = function(inst, target)
            inst.sg.statemem.target = target
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("teleport_pre")
            inst.AnimState:PushAnimation("teleport", false)
        end,

        timeline =
        {
            TimeEvent(19 * FRAMES, function(inst)
                inst.sg:AddStateTag("noattack")
                inst.components.health:SetInvincible(true)
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg.statemem.attack = true
                    inst.sg:GoToState("attack_teleport", inst.sg.statemem.target)
                end
            end),
        },

        onexit = function(inst)
            if not inst.sg.statemem.attack then
                inst.components.health:SetInvincible(false)
            end
        end,
    },

    State{
        name = "attack_teleport",
        tags = { "attack", "busy", "noattack" },

        onenter = function(inst, target)
            inst.components.health:SetInvincible(true)
            if target ~= nil and target:IsValid() then
                inst.sg.statemem.target = target
                inst.Physics:Teleport(target.Transform:GetWorldPosition())
            end
            inst.AnimState:PlayAnimation("teleport_atk")
            inst.AnimState:PushAnimation("teleport_pst", false)
        end,

        timeline =
        {
            TimeEvent(17 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("noattack")
                inst.components.health:SetInvincible(false)
                inst.components.combat:DoAreaAttack(inst, inst.components.combat.hitrange, nil, nil, nil, { "INLIMBO", "notarget", "invisible", "noattack", "flight", "playerghost", "shadow", "shadowchesspiece", "shadowcreature" })
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.components.health:SetInvincible(false)
        end,
    },
}

ShadowChessStates.AddIdle(states, "idle_loop")
ShadowChessStates.AddLevelUp(states, "transform", 20, 60)
ShadowChessStates.AddTaunt(states, "taunt", 20, 30)
ShadowChessStates.AddHit(states, "hit", 0)
ShadowChessStates.AddDeath(states, "disappear", 10, nil)
ShadowChessStates.AddEvolvedDeath(states, "death", 38, nil)
ShadowChessStates.AddDespawn(states, "disappear")

CommonStates.AddWalkStates(states)

return StateGraph("shadow_rook", states, events, "idle")
