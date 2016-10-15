
ShadowChessEvents = {}
ShadowChessStates = {}
ShadowChessFunctions = {}

--------------------------------------------------------------------------

local LEVELUP_RADIUS = 25
local AWAKEN_NEARBY_STATUES_RADIUS = 15

local function AwakenNearbyStatues(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, AWAKEN_NEARBY_STATUES_RADIUS, { "chess_moonevent" })
	for i, v in ipairs(ents) do
		v:PushEvent("shadowchessroar", true)
	end
end

ShadowChessFunctions.AwakenNearbyStatues = AwakenNearbyStatues

--------------------------------------------------------------------------
local function TriggerEpicScare(inst)
    if inst:HasTag("epic") then
        inst.components.epicscare:Scare(5)
    end
end

ShadowChessFunctions.TriggerEpicScare = TriggerEpicScare

--------------------------------------------------------------------------
local function levelup(inst, data)
	if not inst.components.health:IsDead()then
		local queued = inst:QueueLevelUp(data.source)
		if queued then
			if not inst.sg:HasStateTag("busy") then 
				inst.sg:GoToState("levelup")
			end
		end
	end
end

ShadowChessEvents.LevelUp = function()
    return EventHandler("levelup", levelup)
end

--------------------------------------------------------------------------
local function ondeath(inst, data)
    inst.sg:GoToState(inst.level == 1 and "death" or "evolved_death", data)
end    

ShadowChessEvents.OnDeath = function()
    return EventHandler("death", ondeath)
end


--------------------------------------------------------------------------
local function ondespawn(inst, data)
    if not inst.components.health:IsDead() then
        inst.sg:GoToState("despawn", data)
    end
end    

ShadowChessEvents.OnDespawn = function()
    return EventHandler("despawn", ondespawn)
end


--------------------------------------------------------------------------
ShadowChessStates.AddIdle = function(states, idle_anim)
    table.insert(states, State
    {
        name = "idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            if inst:WantsToLevelUp() then
                inst.sg:GoToState("levelup")
            else
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation(idle_anim, true)
            end
        end,
    })
end

--------------------------------------------------------------------------
ShadowChessStates.AddLevelUp = function(states, anim, sound_frame, transition_frame, busyover_frame)
    table.insert(states, State
    {
		name = "levelup",
        tags = {"busy", "levelup"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation(anim)
        end,

		timeline=
        {
			TimeEvent(sound_frame*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.levelup) end),
			TimeEvent(transition_frame*FRAMES, function(inst)
				while inst:WantsToLevelUp() do
					inst:LevelUp()
				end
                AwakenNearbyStatues(inst)
                TriggerEpicScare(inst)
			end),
            TimeEvent(busyover_frame*FRAMES, function(inst) inst.sg:RemoveStateTag("busy") end),
        },

        events=
        {
            EventHandler("animover", function(inst) if inst.AnimState:AnimDone() then inst.sg:GoToState("idle") end end),
        },
    })
end

--------------------------------------------------------------------------
ShadowChessStates.AddTaunt = function(states, anim, sound_frame, action_frame, busyover_frame)
    table.insert(states, State
    {
		name = "taunt",
        tags = { "taunt", "busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation(anim)
        end,

		timeline=
        {
			TimeEvent(sound_frame*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.taunt) end),
			TimeEvent(action_frame*FRAMES, function(inst)
                AwakenNearbyStatues(inst)
                TriggerEpicScare(inst)
            end),
            TimeEvent(busyover_frame*FRAMES, function(inst) inst.sg:RemoveStateTag("busy") end),
        },

        events=
        {
            EventHandler("animover", function(inst) if inst.AnimState:AnimDone() then inst.sg:GoToState("idle") end end),
        },
    })
end

--------------------------------------------------------------------------
ShadowChessStates.AddHit = function(states, anim, sound_frame, busyover_frame)
    table.insert(states, State
    {
		name = "hit",
        tags = {"busy", "hit"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation(anim)
        end,

		timeline=
        {
			TimeEvent(sound_frame*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.hit) end),
            TimeEvent(busyover_frame*FRAMES, function(inst) inst.sg:RemoveStateTag("busy") end),
        },

        events=
        {
            EventHandler("animover", function(inst) if inst.AnimState:AnimDone() then inst.sg:GoToState("idle") end end),
        },
    })
end

--------------------------------------------------------------------------
local function LevelUpAlliesTimelineEvent(frame)
	return TimeEvent(frame*FRAMES, function(inst)
		-- trigger all near by shadow chess pieces to level up
		local ents = inst:GetAllSCPInRange(LEVELUP_RADIUS)
		for i, v in ipairs(ents) do
			v:PushEvent("levelup", {source=inst})
		end
	end)
end

--------------------------------------------------------------------------
ShadowChessStates.AddDeath = function(states, anim, action_frame, timeline)
	timeline = timeline and JoinArrays(timeline, {LevelUpAlliesTimelineEvent(action_frame)}) or {LevelUpAlliesTimelineEvent(action_frame)}

    table.insert(states, State
    {
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation(anim)
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(inst:GetPosition())
        end,

		timeline = timeline,
    })
end

--------------------------------------------------------------------------
ShadowChessStates.AddEvolvedDeath = function(states, anim, action_frame, timeline)
	timeline = timeline and JoinArrays(timeline, {LevelUpAlliesTimelineEvent(action_frame)}) or {LevelUpAlliesTimelineEvent(action_frame)}

    table.insert(states, State
    {
        name = "evolved_death",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation(anim)
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(inst:GetPosition())
        end,

		timeline = timeline,
    })
end

--------------------------------------------------------------------------
ShadowChessStates.AddDespawn = function(states, anim, timeline)
    table.insert(states, State
    {
        name = "despawn",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation(anim)
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
        end,

		timeline = timeline,

        events=
        {
            EventHandler("animover", function(inst) if inst.AnimState:AnimDone() then inst:Remove() end end),
        },
    })
end
