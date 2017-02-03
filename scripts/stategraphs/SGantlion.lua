require("stategraphs/commonstates")

local function SproutLaunch(inst, launcher, basespeed)
    local x0, y0, z0 = launcher.Transform:GetWorldPosition()
    local x1, y1, z1 = inst.Transform:GetWorldPosition()
    local dx, dz = x1 - x0, z1 - z0
    local dsq = dx * dx + dz * dz
    local angle
    if dsq > 0 then
        local dist = math.sqrt(dsq)
        angle = math.atan2(dz / dist, dx / dist) + (math.random() * 20 - 10) * DEGREES
    else
        angle = 2 * PI * math.random()
    end
    local speed = basespeed + math.random()
    inst.Physics:Teleport(x1, .1, z1)
    inst.Physics:SetVel(math.cos(angle) * speed, speed * 4 + math.random() * 2, math.sin(angle) * speed)
end

local events =
{
    EventHandler("onaccepttribute", function(inst, data)
        if not inst.sg:HasStateTag("busy") then
			if inst:HasRewardToGive() then
				inst.sg:GoToState("trinketribute")
			else
				inst.sg:GoToState("rocktribute", data)
			end
        end
    end),
    EventHandler("onrefusetribute", function(inst, data) 
        if not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("refusetribute", data)
        end
    end),
    EventHandler("antlion_leaveworld", function(inst, data) 
		inst.sg.mem.queueleaveworld = true
        if not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("leaveworld", data)
        end
    end),
    EventHandler("onsinkholesstarted", function(inst, data) 
		inst.sg.mem.causingsinkholes = true
        if not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("sinkhole_pre", data)
        end
    end),
    EventHandler("onsinkholesfinished", function(inst, data) 
		inst.sg.mem.causingsinkholes = false
    end),
}

local states =
{
	State
	{
		name = "idle",
		tags = {"idle"},

		onenter = function(inst, loopcount)
			loopcount = (loopcount or 0) + 1

			inst.Physics:Stop()
			
			if inst:HasRewardToGive() then
				inst.sg:GoToState("awardtribute")
			elseif inst.sg.mem.queueleaveworld then
				inst.sg:GoToState("leaveworld")
			elseif inst.sg.mem.causingsinkholes then
				inst.sg:GoToState("sinkhole_pre")
			elseif loopcount > 5 and math.random() < 0.5 then
				if inst:GetRageLevel() == 3 then
					inst.sg:GoToState("idle_unhappy")
				else
					inst.AnimState:PlayAnimation("lookaround")
				end
			else
				inst.sg.statemem.loopcount = loopcount
				inst.AnimState:PlayAnimation("idle")
			end
		end,

		events = 
		{
			EventHandler("animover", function(inst) 
				inst.sg:GoToState("idle", inst.sg.statemem.loopcount) 
			end)
		},
	},

	State
	{
		name = "idle_unhappy",
		tags = {"idle"},

		onenter = function(inst, loopcount)
			inst.AnimState:PlayAnimation("taunt")
		end,

        timeline =
        {
			TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/sfx/taunt") end),
        },

		events = 
		{
            EventHandler("animover", function(inst) if inst.AnimState:AnimDone() then inst.sg:GoToState("idle") end end),
		},
	},


	State
	{
		name = "rocktribute",
		tags = {"busy"},

		onenter = function(inst, data)
			inst.AnimState:PlayAnimation("eat")
			inst.sg.statemem.tributepercent = data ~= nil and data.tributepercent or 0
		end,
        
        timeline =
        {
			TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/eat") end),
			TimeEvent(36*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/eat") end),
			TimeEvent(71*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/swallow") end),
        },

		events = 
		{
            EventHandler("animover", function(inst) 
				if inst.AnimState:AnimDone() then 
					local level = 
					inst.sg:GoToState(inst:GetRageLevel() == 1 and "hightributeresponse" or "idle")
				end
			end),
		},
	},

	State
	{
		name = "lowtributeresponse",
		tags = {"busy"},

		onenter = function(inst, data)
			inst.AnimState:PlayAnimation("taunt")
		end,
        
        timeline =
        {
			TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/sfx/taunt") end),
        },

		events = 
		{
            EventHandler("animover", function(inst) if inst.AnimState:AnimDone() then inst.sg:GoToState("idle") end end),
		},
	},

	State
	{
		name = "hightributeresponse",
		tags = {"busy"},

		onenter = function(inst, data)
			inst.AnimState:PlayAnimation("full_pre")
			inst.AnimState:PushAnimation("full_loop", false)
			inst.AnimState:PushAnimation("full_pst", false)
		end,
        
        timeline =
        {
			TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/purr") end),
			TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/rub") end),
			TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/rub") end),
			TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/rub") end),
			TimeEvent(46*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/rub") end),
        },

		events = 
		{
            EventHandler("animqueueover", function(inst) if inst.AnimState:AnimDone() then inst.sg:GoToState("idle") end end),
		},
	},

	State
	{
		name = "refusetribute",
		tags = {"busy"},

		onenter = function(inst)
			inst.AnimState:PlayAnimation("unimpressed")
		end,

        timeline =
        {
			TimeEvent(54*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/unimpressed") end),
        },

		events = 
		{
            EventHandler("animover", function(inst) if inst.AnimState:AnimDone() then inst.sg:GoToState("idle") end end),
		},
	},

	State
	{
		name = "awardtribute",
		tags = {"busy"},

		onenter = function(inst)
			inst.AnimState:PlayAnimation("spit")
		end,

        timeline =
        {
			TimeEvent(40*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/spit") end),
			TimeEvent(23*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/attack_pre") end),
            TimeEvent(26*FRAMES, function(inst) inst:GiveReward() end),
			TimeEvent(60*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/unimpressed") end),
        },

		events = 
		{
            EventHandler("animover", function(inst) if inst.AnimState:AnimDone() then inst.sg:GoToState("idle") end end),
		},
	},
	
	State
	{
		name = "trinketribute",
		tags = {"busy"},

		onenter = function(inst)
			inst.AnimState:PlayAnimation("eat_talisman")
			inst.AnimState:PushAnimation("spit_talisman", false)
		end,

        timeline =
        {
			TimeEvent(21*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/swallow") end),
			TimeEvent(44*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/unimpressed") end),
            TimeEvent(80*FRAMES, function(inst) inst:GiveReward() end),
			TimeEvent(80*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/spit") end),
        },

		events = 
		{
            EventHandler("animover", function(inst) if inst.AnimState:AnimDone() then inst.sg:GoToState("idle") end end),
		},
	},

    State
    {
        name = "enterworld",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("enter")
            inst.sg.statemem.spawnpos = inst:GetPosition()

            for i, v in ipairs(TheSim:FindEntities(inst.sg.statemem.spawnpos.x, 0, inst.sg.statemem.spawnpos.z, 2, nil, { "INLIMBO" }, { "CHOP_workable", "DIG_workable", "HAMMER_workable", "MINE_workable" })) do
                v.components.workable:Destroy(inst)
                if v:IsValid() and v:HasTag("stump") then
                    v:Remove()
                end
            end

            local totoss = TheSim:FindEntities(inst.sg.statemem.spawnpos.x, 0, inst.sg.statemem.spawnpos.z, 1.5, { "_inventoryitem" }, { "locomotor", "INLIMBO" })

            --toss flowers out of the way
            for i, v in ipairs(TheSim:FindEntities(inst.sg.statemem.spawnpos.x, 0, inst.sg.statemem.spawnpos.z, 1.5, { "flower", "pickable" })) do
                local loot = v.components.pickable.product ~= nil and SpawnPrefab(v.components.pickable.product) or nil
                if loot ~= nil then
                    loot.Transform:SetPosition(v.Transform:GetWorldPosition())
                    table.insert(totoss, loot)
                end
                v:Remove()
            end

            --toss stuff out of the way
            for i, v in ipairs(totoss) do
                if v:IsValid() and not v.components.inventoryitem.nobounce and v.Physics ~= nil then
                    SproutLaunch(v, inst, 1.5)
                end
            end

            inst.Physics:SetMass(999999)
            inst.Physics:CollidesWith(COLLISION.WORLD)
        end,

        timeline =
        {
            TimeEvent(2 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/enter") end),
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
            inst.Physics:SetMass(0)
            inst.Physics:ClearCollisionMask()
            inst.Physics:CollidesWith(COLLISION.ITEMS)
            inst.Physics:CollidesWith(COLLISION.CHARACTERS)
            inst.Physics:CollidesWith(COLLISION.GIANTS)
            inst.Physics:Teleport(inst.sg.statemem.spawnpos:Get())
        end,
    },

    State
    {
        name = "leaveworld",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("out")
        end,

        timeline =
        {
            TimeEvent(28 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/enter") end),
            TimeEvent(35 * FRAMES, function(inst)
                inst.Physics:SetActive(false)
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then 
                    inst:Remove()
                end
            end),
        },

        onexit = function(inst)
            --Should NOT reach here, but just in case
            inst.Physics:SetActive(true)
        end,
    },

	State
	{
		name = "sinkhole_pre",
		tags = {"busy", "attack"},

		onenter = function(inst)
			inst.AnimState:PlayAnimation("cast_pre")
		end,

        timeline =
        {
			TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/cast_pre") end),
			TimeEvent(29*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/sfx/ground_break") end),
			TimeEvent(29*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/cast_pre") end),
        },

		events = 
		{
            EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then 
					inst.sg:GoToState(inst.sg.mem.causingsinkholes and "sinkhole_loop" or "sinkhole_pst")
				end
			end),
		},
	},

	State
	{
		name = "sinkhole_loop",
		tags = {"busy", "attack"},

		onenter = function(inst, lastloop)
			inst.AnimState:PlayAnimation("cast_loop_actve")
			inst.sg.statemem.lastloop = lastloop
		end,

        timeline =
        {
			TimeEvent(28*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/cast_pre") end),
			TimeEvent(28*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/sfx/ground_break") end),
			TimeEvent(69*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/cast_pre") end),
			TimeEvent(69*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/sfx/ground_break") end),
        },

		events = 
		{
            EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then 
					if inst.sg.statemem.lastloop then
						inst.sg:GoToState("sinkhole_pst")
					else
						inst.sg:GoToState("sinkhole_loop", inst.sg.mem.causingsinkholes ~= true)
					end
				end
			end),
		},
	},

	State
	{
		name = "sinkhole_pst",
		tags = {"busy", "attack"},

		onenter = function(inst)
			inst.AnimState:PlayAnimation("cast_pst")
		end,

        timeline =
        {
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
  
return StateGraph("antlion", states, events, "idle")
