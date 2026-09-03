require("stategraphs/commonstates")

local AOEUtil = require("aoeutil")

local function ChooseAttack(inst, target)
	target = target or inst.components.combat.target
	if target and target:IsValid() then
		inst.sg:GoToState("pounce", target)
		return true
	end
	return false
end

local events =
{
    CommonHandlers.OnLocomote(true, true),
    CommonHandlers.OnDeath(),
    EventHandler("doattack", function(inst, data)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            ChooseAttack(inst, data and data.target)
        end
    end),
    EventHandler("spawn", function(inst)
        inst.sg:GoToState("spawn")
    end),
}

local AOE_TAGSET
local function GetAOEAttackTagSet(inst) -- only if not tied to charlie boss (debug)
	if AOE_TAGSET == nil then
		AOE_TAGSET = AOEUtil.AttackTagSet()
		AOE_TAGSET:AppendCantTags("shadowthrall", "shadow", "shadowcreature", "shadowchesspiece", "charlie_npc")
		-- AOE_TAGSET:Register() don't register tags for the debug ones
	end
	return AOE_TAGSET
end

local AOE_RADIUS = 0.6
local function DoAOE(inst)
    local tagset
    if inst.caster and inst.caster:IsValid() then
        tagset = inst.caster:GetAOEAttackTagSet()
    else
        tagset = GetAOEAttackTagSet(inst)
        inst.caster = nil
    end

    AOEUtil.Attack(inst, AOE_RADIUS, tagset, nil, nil)
end

local states =
{
    State{
        name = "idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst, pushanim)
            inst.components.locomotor:Stop()

            if pushanim and not inst.AnimState:AnimDone() then
                inst.sg.statemem.pushanim = true
            else
                local anim = "idle"
				if not inst.AnimState:IsCurrentAnimation(anim) or inst.AnimState:AnimDone() then
					inst.AnimState:PlayAnimation(anim, true)
				end
				inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
            end
        end,

		events =
		{
			--NOTE: we may be have several anims still queued
			EventHandler("animqueueover", function(inst)
				if inst.sg.statemem.pushanim and inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},

		ontimeout = function(inst)
			inst.sg:GoToState("idle")
		end,
    },

    State{
        name = "pounce",
        tags = { "noattack", "attack", "busy", "jumping" },

        onenter = function(inst, target)
            inst.components.locomotor:Stop()
            inst.components.combat:StartAttack()
			if target and target:IsValid() then
                local x, y, z = inst.Transform:GetWorldPosition()
                local tx, ty, tz = target.Transform:GetWorldPosition()
                inst.sg.statemem.target = target
                inst.sg.statemem.tracking = true
                inst:ForceFacePoint(tx, ty, tz)

                local speed = TUNING.CHARLIE_BOSS_RUNNER_RUNSPEED
                inst.sg.statemem.speed = speed
                inst.Physics:SetMotorVelOverride(inst.sg.statemem.speed, 0, 0)
			end
            inst.AnimState:PlayAnimation("attack")
            inst.SoundEmitter:PlaySound("rifts8/shadow_insanity_player/pounce")
        end,

		onupdate = function(inst)
			if inst.sg.statemem.tracking then
				local target = inst.sg.statemem.target
                if target and target:IsValid() then
                    inst:ForceFacePoint(target.Transform:GetWorldPosition())
                else
                    inst.sg.statemem.target = nil
                end
			end
		end,

        timeline =
        {
            --#SFX
            -- FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("xxx") end),

			FrameEvent(6, function(inst)
				inst.sg.statemem.tracking = false
			end),

            FrameEvent(9, function(inst)
                inst.SoundEmitter:PlaySound("rifts8/shadow_insanity_player/death")
                DoAOE(inst)
                RemovePhysicsColliders(inst)
				inst.Physics:ClearMotorVelOverride()
				inst.Physics:Stop()
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst:Remove()
                end
            end),
        }
    },

    State{
        name = "spawn",
        tags = { "busy", "noattack", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("spawn")
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
        name = "death",
        tags = { "busy", "dead" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("disappear")
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(inst:GetPosition())
            inst:AddTag("NOCLICK")
            inst.persists = false
            inst.SoundEmitter:PlaySound("rifts8/shadow_insanity_player/death")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst:Remove()
            end),
        },

        onexit = function(inst)
            inst:RemoveTag("NOCLICK")
        end,
    },
}

CommonStates.AddWalkStates(states)
CommonStates.AddRunStates(states)

return StateGraph("charlie_boss_runner", states, events, "idle")
