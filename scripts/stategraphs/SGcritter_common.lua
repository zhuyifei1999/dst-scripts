
SGCritterEvents = {}
SGCritterStates = {}


--------------------------------------------------------------------------
SGCritterEvents.OnGoToSleep = function()
    return EventHandler("gotosleep", function(inst) inst.sg:GoToState(inst.sg:HasStateTag("sleeping") and "sleeping" or "sleep") end)
end

SGCritterEvents.OnEat = function()
    return EventHandler("oneat", function(inst) inst.sg:GoToState("eat") end)
end

--------------------------------------------------------------------------
SGCritterStates.AddIdle = function(states, num_emotes, timeline)
    table.insert(states, State
    {
        name = "idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst, pushanim)
			if inst.components.locomotor ~= nil then
				inst.components.locomotor:StopMoving()
			end

			local r = math.random()
            if r <= inst:GetPeepChance() then
                inst.sg:GoToState("hungry")
            elseif r <= 0.1 then
                inst.sg:GoToState("emote"..math.random(num_emotes))
            else
				inst.AnimState:PlayAnimation("idle_loop")
            end
        end,
        
        timeline = timeline,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    })
end

--------------------------------------------------------------------------
SGCritterStates.AddEat = function(states, timeline)
    table.insert(states, State
    {
        name = "eat",
        tags = { "busy" },

        onenter = function(inst, pushanim)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end

            inst.AnimState:PlayAnimation("eat_pre")
            inst.AnimState:PushAnimation("eat_loop", false)
            inst.AnimState:PushAnimation("eat_pst", false)
        end,

		timeline = timeline,

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
					local dest_state = inst.sg.mem.queuethankyou and "emote1" or "idle"
					inst.sg.mem.queuethankyou = nil
                    inst.sg:GoToState(dest_state)
                end
            end),
        },
    })
end

--------------------------------------------------------------------------
SGCritterStates.AddHungry = function(states, timeline)
    table.insert(states, State
    {
        name = "hungry",
        tags = {"idle"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("distress")
        end,
       
        timeline = timeline,

        events=
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    })
end

--------------------------------------------------------------------------
SGCritterStates.AddNuzzle = function(states, actionhandlers, timeline)
    table.insert(actionhandlers, ActionHandler(ACTIONS.NUZZLE, "nuzzle"))

    table.insert(states, State
    {
		name = "nuzzle",
		tags = {"busy"},

		onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("emote_nuzzle")
		end,

		timeline = timeline,

		events =
		{
			EventHandler("animover", function(inst) 
                if inst.AnimState:AnimDone() then
					inst:PerformBufferedAction()
					inst.sg:GoToState("idle") 
				end
			end)
		},
    })
end


--------------------------------------------------------------------------
SGCritterStates.AddEmotes = function(states, emotes, timeline)
	for i,v in ipairs(emotes) do
		table.insert(states, State
		{
			name = "emote"..i,
			tags = { "busy", "canrotate" },

			onenter = function(inst, pushanim)
				if inst.components.locomotor ~= nil then
					inst.components.locomotor:StopMoving()
				end

				inst.AnimState:PlayAnimation(v.anim)
			end,

			timeline = v.timeline,

			events =
			{
				EventHandler("animover", function(inst)
					if inst.AnimState:AnimDone() then
						inst.sg:GoToState("idle")
					end
				end),
			},
		})
	end
end
