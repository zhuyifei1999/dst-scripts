require("stategraphs/commonstates")

--------------------------------------------------------------------------------------------------------------

local function GoToIdle(inst)
    inst.sg:GoToState("idle")
end

local function Remove(inst)
    inst:Remove()
end

local SimpleAnimoverHandler = {
    EventHandler("animover", GoToIdle),
}

local RemoveOnAnimoverHandler = {
    EventHandler("animover", Remove),
}

--------------------------------------------------------------------------------------------------------------

local actionhandlers = {}

local events =
{
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnPossessChassis(),

	EventHandler("gestaltcapturable_targeted", function(inst)
		if inst.sg:HasStateTag("moving") then
			inst.sg:GoToState("walk_stop")
		end
	end),
}

--------------------------------------------------------------------------------------------------------------

local states =
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("idle")
        end,

        events = SimpleAnimoverHandler,
    },

    State{
        name = "spawn",
        tags = {"busy", "noattack"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("spawn")
            inst.Physics:SetMotorVelOverride(4, 0, 0)
            inst.SoundEmitter:PlaySound("rifts/lunarthrall/gestalt_vocalization")
            inst.components.gestaltcapturable:SetEnabled(false)
        end,

        onexit = function(inst)
            inst.components.gestaltcapturable:SetEnabled(true)
            inst.Physics:ClearMotorVelOverride()
            inst.Physics:Stop()
        end,

        events = SimpleAnimoverHandler,
    },

    -- NOTE(Omar): Why do we have two states with the same functionality?
    State{
        name = "infest",
        tags = { "busy", "noattack", "infesting" },

        onenter = function(inst)
            inst.AnimState:SetFinalOffset(3)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("infest")
            inst.SoundEmitter:PlaySound("rifts/lunarthrall/gestalt_infest")

            inst.sg.statemem.corpse = inst.components.entitytracker ~= nil and inst.components.entitytracker:GetEntity("corpse") or nil
			if inst.sg.statemem.corpse == nil then
				inst.persists = false
			end
        end,

        onexit = function(inst)
            -- Shouldn't enter here?
            inst.components.gestaltcapturable:SetEnabled(true)
        end,

        timeline =
        {
			FrameEvent(25, function(inst)
                inst.components.gestaltcapturable:SetEnabled(false)
				inst.persists = false

                -- lunarthrall_plant_gestalt handler.
                if inst.plant_target and inst.plant_target:IsValid() then
                    TheWorld.components.lunarthrall_plantspawner:SpawnPlant(inst.plant_target)

                -- corpse_gestalt handler.
                elseif inst.sg.statemem.corpse ~= nil and inst.sg.statemem.corpse:IsValid() then
                    inst.sg.statemem.corpse:StartLunarRiftMutation()
                end
            end ),
            FrameEvent(30, function(inst)
                if inst.sg.statemem.corpse ~= nil and inst.sg.statemem.corpse:IsValid() then
                    inst:Remove()
                end
            end ),
        },

		events = RemoveOnAnimoverHandler,
    },

	State{
		name = "infest_corpse",
		tags = { "busy", "noattack", "infesting" },

		onenter = function(inst)
            inst.sg.statemem.corpse = inst.components.entitytracker ~= nil and inst.components.entitytracker:GetEntity("corpse") or nil
			if inst.sg.statemem.corpse == nil then
				inst.persists = false
            else
                -- We're not using height because height always returns low for a corpse.
                local _, sz, _ = GetCombatFxSize(inst.sg.statemem.corpse)
                local is_small = sz == "tiny" or sz == "small"
                inst.AnimState:PlayAnimation(is_small and "infest_corpse_small" or "infest_corpse")
			end

			inst.AnimState:SetFinalOffset(3)
			inst.components.locomotor:Stop()
			inst.SoundEmitter:PlaySound("rifts/lunarthrall/gestalt_infest")
		end,

        onexit = function(inst)
            -- Shouldn't enter here?
            inst.components.gestaltcapturable:SetEnabled(true)
        end,

		timeline =
		{
			FrameEvent(19, function(inst)
                inst.components.gestaltcapturable:SetEnabled(false)
				inst.persists = false

				-- lunarthrall_plant_gestalt handler.
				if inst.plant_target and inst.plant_target:IsValid() then
					TheWorld.components.lunarthrall_plantspawner:SpawnPlant(inst.plant_target)

				-- corpse_gestalt handler.
				elseif inst.sg.statemem.corpse ~= nil and inst.sg.statemem.corpse:IsValid() then
                    inst.sg.statemem.corpse:StartLunarRiftMutation()
				end
			end),
		},

		events = RemoveOnAnimoverHandler,
	},

    State{ -- Zoom!
        name = "spawn_hail",
        tags = { "busy", "noattack" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("spawn_hail")
            inst.Transform:SetRotation(360 * math.random())

            inst.sg.statemem.base_speed = 1 + math.random() * 1
            inst.Physics:SetMotorVelOverride(inst.sg.statemem.base_speed, 0, 0)
            inst.SoundEmitter:PlaySound("rifts/lunarthrall/gestalt_vocalization")
        end,

        timeline =
        {
            FrameEvent(3, function(inst)
                inst.sg.statemem.base_speed = inst.sg.statemem.base_speed + math.random()
                inst.Physics:SetMotorVelOverride(inst.sg.statemem.base_speed, 0, 0)
            end),

            FrameEvent(9, function(inst)
                inst.sg.statemem.base_speed = inst.sg.statemem.base_speed + 2 + 1 * math.random()
                inst.Physics:SetMotorVelOverride(inst.sg.statemem.base_speed, 0, 0)
            end),

            FrameEvent(18, function(inst)
                inst.sg.statemem.base_speed = inst.sg.statemem.base_speed + 2 + 2 * math.random()
                inst.Physics:SetMotorVelOverride(inst.sg.statemem.base_speed, 0, 0)
            end),
        },

        onexit = Remove,
        events = RemoveOnAnimoverHandler,
    },
}

--------------------------------------------------------------------------------------------------------------

local function SpawnTrail(inst)
    if not inst._notrail then
        local trail = SpawnPrefab("gestalt_trail")
        trail.Transform:SetPosition(inst.Transform:GetWorldPosition())
        trail.Transform:SetRotation(inst.Transform:GetRotation())
    end
end

CommonStates.AddWalkStates(states,
{
    starttimeline =
    {
        FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("rifts/lunarthrall/gestalt_vocalization") end),
    },
    walktimeline =
    {
        FrameEvent(0, SpawnTrail),
    },
}, nil, nil, true)

CommonStates.AddPossessChassisState(states, "infest_corpse_small", 19,
{
    onenter = function(inst)
        inst.SoundEmitter:PlaySound("rifts/lunarthrall/gestalt_infest")
    end,
})

--------------------------------------------------------------------------------------------------------------

return StateGraph("lunarthrall_plant_gestalt", states, events, "idle", actionhandlers)