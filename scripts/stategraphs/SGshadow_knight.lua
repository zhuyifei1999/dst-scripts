require("stategraphs/commonstates")
require("stategraphs/sgshadow_chesspieces")

-- basic attack extent = 2.75
-- plus attack extent = 4.75

local actionhandlers =
{
}

local events =
{
    EventHandler("attacked", function(inst) if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then inst.sg:GoToState("hit") end end),
    EventHandler("doattack", function(inst, data) if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then inst.sg:GoToState("attack_pre") end end),

	ShadowChessEvents.LevelUp(),
    ShadowChessEvents.OnDeath(),
	ShadowChessEvents.OnDespawn(),
    CommonHandlers.OnLocomote(false,true),
}

local states =
{

	State{
        name = "attack_pre",
        tags = { "attack", "busy" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.components.combat:StartAttack()
        end,

		timeline=
        {
			--TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.attack) end),
		},
		
        events =
        {
            EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then 
					if inst.components.combat.target ~= nil then
						local dist2 = distsq(inst:GetPosition(), inst.components.combat.target:GetPosition())
						if dist2 > inst.components.combat:CalcAttackRangeSq()*0.8 then
							inst.sg:GoToState("attack_long")
						else
							inst.sg:GoToState("attack_short")
						end
					end
				end
			end),
						
        },
    },

	State{
        name = "attack_short",
        tags = { "attack", "busy" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk")
        end,

		timeline=
        {
			TimeEvent(0, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.attack) end),
			TimeEvent(7*FRAMES, function(inst) inst.components.combat:DoAttack() end),
		},
		
        events =
        {
			
            EventHandler("animover", function(inst) if inst.AnimState:AnimDone() then inst.sg:GoToState("idle") end end),
        },
    },

	State{
        name = "attack_long",
        tags = { "attack", "busy" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk_plus")
        end,

		timeline=
        {
			TimeEvent(0, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.attack) end),
			TimeEvent(7*FRAMES, function(inst) inst.components.combat:DoAttack() end),
		},
		
        events =
        {
            EventHandler("animover", function(inst) if inst.AnimState:AnimDone() then inst.sg:GoToState("idle") end end),
        },
    },
    
    State{
		name = "taunt",
        tags = {"busy"},

        onenter = function(inst, remaining)
			inst.sg.statemem.remaining = (remaining or 2) - 1
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            
            if inst.sg.statemem.remaining == 0 then
				-- change target
                local rangesq = TUNING.SHADOWCREATURE_TARGET_DIST * TUNING.SHADOWCREATURE_TARGET_DIST
				local x, y, z = inst.Transform:GetWorldPosition()
				local players = shuffleArray(FindPlayersInRangeSq(x, y, z, rangesq, true))
				RemoveByValue(players, inst.components.combat.target)
				for i, v in ipairs(players) do
					if inst.components.combat:CanTarget(v) then
						inst.components.combat:SetTarget(v)
						break
					end
				end
			end
			
        end,

		timeline=
        {
			TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.taunt) end),
			TimeEvent(30*FRAMES, function(inst) ShadowChessFunctions.AwakenNearbyStatues(inst) end),
        },

        events=
        {
            EventHandler("animover", function(inst) if inst.AnimState:AnimDone() then inst.sg:GoToState(inst.sg.statemem.remaining > 0 and "taunt" or "idle", inst.sg.statemem.remaining) end end),
        },
    },

}

ShadowChessStates.AddIdle(states, "idle_loop")
ShadowChessStates.AddLevelUp(states, "transform", 20, 61)
ShadowChessStates.AddHit(states, "hit", 0)
ShadowChessStates.AddDeath(states, "disappear", 12, nil)
ShadowChessStates.AddEvolvedDeath(states, "death", 30, nil)
ShadowChessStates.AddDespawn(states, "disappear")

CommonStates.AddWalkStates(states)

return StateGraph("shadow_knight", states, events, "idle", actionhandlers)

