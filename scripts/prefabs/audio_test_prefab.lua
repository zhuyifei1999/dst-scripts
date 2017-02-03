-------------------------------------------------------------------------------
-- Commands:
--   c_spawn ""
--   c_sel().sg:GoToState("animation name")
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
----  TEMPLATE CODE
----  ADD AUDIO TEST PREFABS *NEAR* THE BOTTOM OF THE FILE
-------------------------------------------------------------------------------
require("stategraph")

local audioprefabs = {}
local audio_test_prefab_dep = {}
local stategraphs = {}

local function AudioSG(prefab, sgaudio, idle)
	local states = {}
	for k, v in pairs(sgaudio) do
		table.insert(states, State{ name=k, onenter=function(inst) inst.AnimState:PlayAnimation(k) end, timeline=v })
	end

	return StateGraph("SGAudio"..prefab, states, {}, idle ~= nil and idle or "idle")
end

local function AudioPrefab(prefab, artassets, bank, build, sgaudio, defaultstate)
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

		local sgname = "SGAudio"..prefab
		if stategraphs[sgname] == nil then
			stategraphs[sgname] = AudioSG(prefab, sgaudio)
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


AudioPrefab("audio_antlion", {"antlion_build", "antlion_basic", "antlion_action"}, "antlion", "antlion_build",
{
	idle = {
--TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/together/moondial/water_movement") end),
    },
	enter = {
		TimeEvent(2*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/enter") end),
    },
    out = {
		TimeEvent(28*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/enter") end),
    },
	taunt = {
		TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/sfx/taunt") end),
    },
    attack_pre = {
		TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/attack_pre") end),
    },
    attack = {
		TimeEvent(2*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/attack") end),
    },
    hit = {
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/hit") end),
    },
    death = {
		TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/death") end),
		TimeEvent(33*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/bodyfall_death") end),
    },
    sleep_pre = {
		TimeEvent(44*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/bodyfall_sleep") end),
		TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/unimpressed") end),
    },
    unimpressed = {
		TimeEvent(54*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/unimpressed") end),
    },

    eat_pre = {
		TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/eat") end),
    },
    eat_loop = {
		TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/eat") end),
		TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/eat") end),
    },
    eat_post = {
		TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/swallow") end),
    },
    spit = {
		TimeEvent(40*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/spit") end),
		TimeEvent(23*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/attack_pre") end),
		TimeEvent(60*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/unimpressed") end),
    },
    cast_pre = {
		TimeEvent(29*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/sfx/ground_break") end),
		TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/cast_pre") end),
    },
    eat_talisman = {
		TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/eat") end),
		TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/swallow") end),
    },
    spit_talisman = {
		TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/unimpressed") end),
		TimeEvent(40*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/spit") end),
		TimeEvent(23*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/attack_pre") end),
    },
    full_loop = {
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/purr") end),
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/rub") end),
		TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/rub") end),
		TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/rub") end),
		TimeEvent(46*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/rub") end),
    },
})

AudioPrefab("audio_md", {"moondial", "moondial_build", "moondial_waning_build"}, "moondial", "moondial_build",
{
	hit_threequarter = {
		TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/together/moondial/water_movement") end),
    },
}, "hit_threequarter")


-------------------------------------------------------------------------------
----  ADD AUDIO TEST PREFABS ABOVE THIS
-------------------------------------------------------------------------------
----  MORE TEMPLATE CODE BELOW
-------------------------------------------------------------------------------
return Prefab("audio_test_prefab", nil, nil, audio_test_prefab_dep), unpack(audioprefabs)
-------------------------------------------------------------------------------
----  END OF FILE
-------------------------------------------------------------------------------

