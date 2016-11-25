
SGCritterEvents = {}
SGCritterStates = {}


--------------------------------------------------------------------------
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
            elseif r <= 0.1 and (GetTime() - (inst.sg.mem.prevemotetime or 0) > TUNING.CRITTER_EMOTE_DELAY) then
				inst.sg.mem.prevemotetime = GetTime()
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
SGCritterStates.AddEat = function(states, timeline, fns)
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

            if fns ~= nil and fns.onenter ~= nil then
                fns.onenter(inst)
            end
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

        onexit = fns ~= nil and fns.onexit or nil,
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
SGCritterStates.AddNuzzle = function(states, actionhandlers, timeline, fns)
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
            
            inst.sg.mem.prevemotetime = GetTime()

            if fns ~= nil and fns.onenter ~= nil then
                fns.onenter(inst)
            end
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

        onexit = fns ~= nil and fns.onexit or nil,
    })
end

--------------------------------------------------------------------------
SGCritterStates.AddEmotes = function(states, emotes)
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

                if v.fns ~= nil and v.fns.onenter ~= nil then
                    v.fns.onenter(inst)
                end
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

            onexit = v.fns ~= nil and v.fns.onexit or nil,
		})
	end
end

--------------------------------------------------------------------------
local function walkontimeout(inst)
    inst.sg:GoToState("walk")
end

SGCritterStates.AddWalkStates = function(states, timelines, softstop)
    table.insert(states, State
    {
        name = "walk_start",
        tags = { "moving", "canrotate", "softstop" },

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_pre")
        end,

        timeline = timelines ~= nil and timelines.starttimeline or nil,

        events =
        {
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("walk")
				end
			end),
        },
    })

    table.insert(states, State
    {
        name = "walk",
        tags = { "moving", "canrotate", "softstop" },

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_loop", true)
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,

        timeline = timelines ~= nil and timelines.walktimeline or nil,

        ontimeout = walkontimeout,
    })

    table.insert(states, State
    {
        name = "walk_stop",
        tags = { "canrotate", "softstop" },

        onenter = function(inst)
            if softstop == true or (type(softstop) == "function" and softstop(inst)) then
                inst.AnimState:PushAnimation("walk_pst", false)
                if inst.AnimState:IsCurrentAnimation("walk_pst") then
                    inst.components.locomotor:StopMoving()
                else
                    local remaining = inst.AnimState:GetCurrentAnimationLength() - inst.AnimState:GetCurrentAnimationTime() - (inst:HasTag("flying") and 0 or 2 * FRAMES)
                    if remaining > 0 then
                        inst.sg.statemem.softstopmult = .9
                        inst.components.locomotor:SetExternalSpeedMultiplier(inst, "softstop", inst.sg.statemem.softstopmult)
                        inst.components.locomotor:WalkForward()
                        inst.sg:SetTimeout(remaining)
                    else
                        inst.components.locomotor:StopMoving()
                    end
                end
            else
                inst.components.locomotor:StopMoving()
                inst.AnimState:PlayAnimation("walk_pst")
            end
        end,

        timeline = timelines ~= nil and timelines.endtimeline or nil,

        onupdate = function(inst)
            if inst.sg.statemem.softstopmult ~= nil then
                inst.sg.statemem.softstopmult = inst.sg.statemem.softstopmult * .9
                inst.components.locomotor:SetExternalSpeedMultiplier(inst, "softstop", inst.sg.statemem.softstopmult)
                inst.components.locomotor:WalkForward()
            end
        end,

        ontimeout = function(inst)
            inst.sg.statemem.softstopmult = nil
            inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "softstop")
            inst.components.locomotor:StopMoving()
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
            if inst.sg.statemem.softstopmult ~= nil then
                inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "softstop")
            end
        end,
    })
end
