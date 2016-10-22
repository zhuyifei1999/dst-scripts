require("stategraphs/commonstates")
require("stategraphs/SGshadow_chesspieces")

-- basic attack extent = 2.75
-- plus attack extent = 4.75

local events =
{
    EventHandler("attacked", function(inst)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            inst.sg:GoToState("hit")
        end
    end),
    EventHandler("doattack", function(inst, data)
        if not (inst.sg:HasStateTag("busy") or
                inst.sg:HasStateTag("attack") or
                inst.sg:HasStateTag("taunt") or
                inst.sg:HasStateTag("levelup") or
                inst.components.health:IsDead()) then
            inst.sg:GoToState("attack_pre")
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
        name = "attack_pre",
        tags = { "attack", "busy" },

        onenter = function(inst)
            inst.Transform:SetEightFaced()
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.components.combat:StartAttack()
        end,

        timeline =
        {
            ShadowChessFunctions.ExtendedSoundTimelineEvent(0, "attack_grunt"),
            ShadowChessFunctions.ExtendedSoundTimelineEvent(3.5 * FRAMES, "attack"),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg.statemem.attack = true
                    inst.sg:GoToState(
                        inst.components.combat.target ~= nil and
                        inst:GetDistanceSqToInst(inst.components.combat.target) > inst.components.combat:CalcAttackRangeSq() * .8 and
                        "attack_long" or
                        "attack_short"
                    )
                end
            end),
        },

        onexit = function(inst)
            if not inst.sg.statemem.attack then
                inst.Transform:SetFourFaced()
            end
        end,
    },

    State{
        name = "attack_short",
        tags = { "attack", "busy" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk")
        end,

        timeline =
        {
            TimeEvent(3 * FRAMES, function(inst)
                inst.components.combat:DoAttack()
            end),
            TimeEvent(13 * FRAMES, function(inst)
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

        onexit = function(inst)
            inst.Transform:SetFourFaced()
        end,
    },

    State{
        name = "attack_long",
        tags = { "attack", "busy" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk_plus")
        end,

        timeline =
        {
            TimeEvent(5 * FRAMES, function(inst)
                inst.components.combat:DoAttack()
            end),
            TimeEvent(17 * FRAMES, function(inst)
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

        onexit = function(inst)
            inst.Transform:SetFourFaced()
        end,
    },

    State{
        name = "taunt",
        tags = { "taunt", "busy" },

        onenter = function(inst, remaining)
            inst.sg.statemem.remaining = (remaining or 2) - 1
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")

            if inst.sg.statemem.remaining == 0 then
                -- change target
                local x, y, z = inst.Transform:GetWorldPosition()
                local players = shuffleArray(FindPlayersInRange(x, y, z, TUNING.SHADOWCREATURE_TARGET_DIST, true))
                for i, v in ipairs(players) do
                    if v ~= inst.components.combat.target and inst.components.combat:CanTarget(v) then
                        inst.components.combat:SetTarget(v)
                        break
                    end
                end
            end
        end,

        timeline =
        {
            ShadowChessFunctions.ExtendedSoundTimelineEvent(3.5 * FRAMES, "taunt"),
            TimeEvent(30 * FRAMES, function(inst)
                ShadowChessFunctions.AwakenNearbyStatues(inst)
                ShadowChessFunctions.TriggerEpicScare(inst)
            end),
            TimeEvent(44 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState(inst.sg.statemem.remaining > 0 and "taunt" or "idle", inst.sg.statemem.remaining)
                end
            end),
        },
    },

}

ShadowChessStates.AddIdle(states, "idle_loop")
ShadowChessStates.AddLevelUp(states, "transform", 20, 61, 91)
ShadowChessStates.AddHit(states, "hit", 0, 13)
ShadowChessStates.AddDeath(states, "disappear", 12)
ShadowChessStates.AddEvolvedDeath(states, "death", 30,
{
    ShadowChessFunctions.DeathSoundTimelineEvent(14 * FRAMES),
    ShadowChessFunctions.DeathSoundTimelineEvent(30 * FRAMES),
    ShadowChessFunctions.DeathSoundTimelineEvent(45 * FRAMES),
    ShadowChessFunctions.DeathSoundTimelineEvent(61 * FRAMES),
})
ShadowChessStates.AddDespawn(states, "disappear")

CommonStates.AddWalkStates(states)

return StateGraph("shadow_knight", states, events, "idle")
