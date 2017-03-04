-------------------------------------------------------------------------------
-- Commands:
--   c_spawn ""
--   c_sel().sg:GoToState("animation name")

-- Notes:
--   Every time you add a new AudioPrefab(), you must run updateprefabs.bat
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
----  TEMPLATE CODE
----  ADD AUDIO TEST PREFABS *NEAR* THE BOTTOM OF THE FILE
-------------------------------------------------------------------------------
require("stategraph")

local audioprefabs = {}
local audio_test_prefab_dep = {}
local stategraphs = {}

local function AudioSG(prefab, sgdata, idle)
	local states = {}
	for k, v in pairs(sgdata) do

		local timeline = {}
		for sg_k, sg_v in pairs(v) do
			print (" - :", type(sg_k), type(sg_v))
		
			if type(sg_k) ~= "string" then
				table.insert(timeline, sg_v)
			end
		end


		local state = State{ name=k, onenter=function(inst, data) inst.AnimState:PlayAnimation(k) inst.sg.statemem.data = data end, timeline=timeline }
		if v.next ~= nil then
			local function onanimover(inst)
				if inst.AnimState:AnimDone() then 
					local nextstate = v.next
					local loopcount = inst.sg.statemem.data and (inst.sg.statemem.data.loopcount or 0) or 0
					if v.loop ~= nil and v.loop > 0 and loopcount < v.loop then
						loopcount = loopcount + 1
						nextstate = k
					end
											
					local data = {}
					data.loopcount = (loopcount > 0) and loopcount or nil
					
					inst.sg:GoToState(nextstate, (next(data) ~= nil and data or nil))
				end
			end
			state.events.animover = EventHandler("animover", onanimover)
		end
		
		
		table.insert(states, state)
	end

	return StateGraph("SGAudio"..prefab, states, {}, idle ~= nil and idle or "idle")
end

local function AudioPrefab(prefab, artassets, bank, build, sgdata, defaultstate, faced)
	defaultstate = defaultstate ~= nil and defaultstate or "idle"
	
	local assets = {}
	for _,v in ipairs(artassets) do
		table.insert(assets, Asset("ANIM", "anim/"..v..".zip"))
	end

	local function fn()
	    local inst = CreateEntity()
		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()

		inst.AnimState:SetBank(bank)
		inst.AnimState:SetBuild(build)
		inst.AnimState:PlayAnimation(defaultstate)

		if faced == "four" then
			inst.Transform:SetFourFaced()
		end

		local sgname = "SGAudio"..prefab
		if stategraphs[sgname] == nil then
			stategraphs[sgname] = AudioSG(prefab, sgdata)
		end
		inst.sg = StateGraphInstance(stategraphs[sgname], inst)
		SGManager:AddInstance(inst.sg)
		inst.sg:GoToState(defaultstate)

		return inst
	end

	table.insert(audioprefabs, Prefab(prefab, fn, assets, {prefab}))
	
	table.insert(audio_test_prefab_dep, prefab)
end

-------------------------------------------------------------------------------
----  END OF TEMPLATE CODE 
-------------------------------------------------------------------------------
----  ADD AUDIO TEST PREFABS BELOW THIS
-------------------------------------------------------------------------------

AudioPrefab("audio_stalker", {"stalker_basic", "stalker_action"}, "stalker", --[["stalker_basic"]] "stalker_action",
{
	idle_loop = {
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/in") end),
		TimeEvent(26*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/out") end),
		next = "idle_loop",
    },
	walk_loop = {
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/footstep") end),
		TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/footstep") end),
		TimeEvent(32*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/footstep") end),
    },
    attack1_pbaoe = {
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/attack1_pbaoe_pre") end),
		TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/attack1_pbaoe") end),    
   
    },
	taunt = {
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/taunt") end),
 
    },
    attack_down = {
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/attack_swipe") end),
		TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/head") end),
		TimeEvent(47*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/head") end),
	},
    enter = { ---new
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/music/stalker_enter_music") end),
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/enter") end),
		
    },
    hit_down = {
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/hit") end),
    },
    death2_down = { ---new
		TimeEvent(5*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/death_walk") end),
		TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/bone_drop") end),
		TimeEvent(40*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/bone_drop") end),
		TimeEvent(56*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/bone_drop") end),
		TimeEvent(69*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/bone_drop") end),
    },
    death = {
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/death") end),
		TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/death_pop") end),
		TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/death_pop") end),
		TimeEvent(21*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/death_pop") end),
		TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/death_pop") end),
		TimeEvent(27*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/death_pop") end),
		TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/death_pop") end),
		TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/death_bone_drop") end),

    },

	walk = { ---new FOR MINIONS!
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/minion/step") end),
			---set a loop for each minion (dontstarve/creatures/together/stalker/minion/monion_LP)
    },

    taunt1 = { ---new
		TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/hurt") end),
		TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/bone_drop") end),
		TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/bone_drop") end),
		TimeEvent(23*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/bone_drop") end),
		TimeEvent(50*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/arm") end),
		TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/out") end),
		TimeEvent(46*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/in") end),
    },

    taunt2_loop = { ---new
		TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/out") end),
		TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/hurt") end),
		TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/in") end),
	},

	taunt3_loop = { ---new
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/taunt") end),
		TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/head") end),
		},
})





-------------------------------------------------------------------------------
----  ADD AUDIO TEST PREFABS ABOVE THIS
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
----  EXAMPLES
-------------------------------------------------------------------------------

AudioPrefab("audio_ex_simple", {"antlion_build", "antlion_basic", "antlion_action"}, "antlion", "antlion_build",
{
	idle = {
    },
    death = {
		TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/death") end),
		TimeEvent(33*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/bodyfall_death") end),
    },
})

AudioPrefab("audio_ex_object_with_no_idle_anim", {"moondial", "moondial_build", "moondial_waning_build"}, "moondial", "moondial_build",
{
	hit_threequarter = {
		TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/together/moondial/water_movement") end),
    },
}, "hit_threequarter")


AudioPrefab("audio_ex_sequencing_and_looping_anim", {"antlion_build", "antlion_basic", "antlion_action"}, "antlion", "antlion_build",
{
	idle = {
		next = "idle",
    },
    cast_pre = {
		TimeEvent(29*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/sfx/ground_break") end),
		TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/cast_pre") end),
		next = "cast_loop_active",
    },
    cast_loop_active = {
		TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/cast_pre") end),
		loop = 1,
		next = "cast_pst",
    },
    cast_pst = {
		next = "idle",
    },
})


-------------------------------------------------------------------------------
----  MORE TEMPLATE CODE BELOW
-------------------------------------------------------------------------------
return Prefab("audio_test_prefab", nil, nil, audio_test_prefab_dep), unpack(audioprefabs)
-------------------------------------------------------------------------------
----  END OF FILE
-------------------------------------------------------------------------------

