
-- Pickable Loot:
--  none		- oversized veggie
--  low			- veggies and 2 seeds
--  moderate	- veggies and seeds
--  high		- veggies or seeds


local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS

local function call_for_reinforcements(inst, target)
	if not target:HasTag("plantkin") then
		local x, y, z = inst.Transform:GetWorldPosition()
		local defenders = TheSim:FindEntities(x, y, z, TUNING.FARM_PLANT_DEFENDER_SEARCH_DIST, {"farm_plant_defender"})
		for _, defender in ipairs(defenders) do
			if defender.components.burnable == nil or not defender.components.burnable.burning then
				defender:PushEvent("defend_farm_plant", {source = inst, target = target})
				break
			end
		end
	end
end

local function TryGrowResume(inst)
	if inst.components.growable ~= nil and not TheWorld.state.isnight and (inst.components.burnable == nil or not inst.components.burnable.burning) then
		inst.components.growable:Resume()
	end
end

local function OnIsNight(inst)
	if TheWorld.state.isnight and inst.components.growable ~= nil then
		inst.components.growable:Pause()
	else
		TryGrowResume(inst)
	end
end

local function dig_up(inst, worker)
    if inst.components.lootdropper ~= nil then
		inst.components.lootdropper:DropLoot()
    end

	call_for_reinforcements(inst, worker)

	if inst.components.growable ~= nil then
		local stage_data = inst.components.growable:GetCurrentStageData()
		if stage_data ~= nil and stage_data.dig_fx ~= nil then
			SpawnPrefab(stage_data.dig_fx).Transform:SetPosition(inst.Transform:GetWorldPosition())
		end
	end

    inst:Remove()
end

local function onburnt(inst)
    SpawnPrefab("ash").Transform:SetPosition(inst.Transform:GetWorldPosition())
	if inst.components.lootdropper ~= nil then
		inst.components.lootdropper:DropLoot()
	end

	inst:Remove()
end

local function onignite(inst, source, doer)
	inst.components.farmplantstress:SetStressed("happiness", true, doer or source)

	if inst.components.growable ~= nil then
		inst.components.growable:Pause()
		if inst.components.farmplanttendable ~= nil then
			inst.components.farmplanttendable:SetTendable(inst.components.growable:GetCurrentStageData().tendable)
		end
	end
end

local function onextinguish(inst)
	TryGrowResume(inst)
end

local function on_happiness_changed(inst, stressed, doer)
	inst:DoTaskInTime(0.5 + math.random() * 0.5, function()
		local fx = SpawnPrefab(stressed and "farm_plant_unhappy" or "farm_plant_happy")
		fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	end)
end

local function ontendto(inst, doer)
	inst.components.farmplantstress:SetStressed("happiness", false, doer)

	return true
end

local function GetDrinkRate(inst)
	return (inst.components.growable == nil or inst.components.growable:IsGrowing()) and inst.plant_def.moisture.drink_rate or 0
end

local function OnSoilMoistureStateChange(inst, is_soil_moist, was_soil_moist)
	inst.components.farmsoildrinker:UpdateMoistureTime(is_soil_moist, was_soil_moist)
end

local WEED_DEFS = require("prefabs/weed_defs").WEED_DEFS
local WEIGHTED_SEED_TABLE = require("prefabs/weed_defs").weighted_seed_table

require "prefabs/veggies"
--[[
function logseeds()
	local season_mod = TUNING.SEED_WEIGHT_SEASON_MOD

	local function calc_chance(t, var, season)
		local total = 0
		for _, v in ipairs(t) do
			total = total + (PLANT_DEFS[v.name].good_seasons[season] and v.season_weight or v.weight)
		end
		total = total * 1/(1-TUNING.FARM_PLANT_RANDOMSEED_WEED_CHANCE)
		for _, v in ipairs(t) do
			v[var] = 100 * (PLANT_DEFS[v.name].good_seasons[season] and v.season_weight or v.weight) / total
		end
	end

	local seeds = {}
	for k, v in pairs(VEGGIES) do
		if v.seed_weight > 0 then
			local weight = v.seed_weight * (1-TUNING.FARM_PLANT_RANDOMSEED_WEED_CHANCE) -- after weed modifier
			table.insert(seeds, {name = k, weight = weight, season_weight = weight * TUNING.SEED_WEIGHT_SEASON_MOD})
		end
	end

	calc_chance(seeds, "base_chance", "base_chance")
	calc_chance(seeds, "autumn", "autumn")
	calc_chance(seeds, "winter", "winter")
	calc_chance(seeds, "spring", "spring")
	calc_chance(seeds, "summer", "summer")

	table.sort(seeds, function(a, b) return a.name < b.name end)

	print("Seeds:             Base      Autumn    Winter    Spring    Summer")
	print(string.format("  %15s: %6.3f    %6.3f    %6.3f    %6.3f    %6.3f", "weeds", TUNING.FARM_PLANT_RANDOMSEED_WEED_CHANCE*100, TUNING.FARM_PLANT_RANDOMSEED_WEED_CHANCE*100, TUNING.FARM_PLANT_RANDOMSEED_WEED_CHANCE*100, TUNING.FARM_PLANT_RANDOMSEED_WEED_CHANCE*100, TUNING.FARM_PLANT_RANDOMSEED_WEED_CHANCE*100))
	for _, v in ipairs(seeds) do
		print(string.format("  %15s: %6.3f    %6.3f    %6.3f    %6.3f    %6.3f", v.name, v.base_chance, v.autumn, v.winter, v.spring, v.summer))
	end
end
]]
local function pickfarmplant()
	if math.random() < TUNING.FARM_PLANT_RANDOMSEED_WEED_CHANCE then
		return weighted_random_choice(WEIGHTED_SEED_TABLE)
	else
		local season = TheWorld.state.season
		local weights = {}
		local season_mod = TUNING.SEED_WEIGHT_SEASON_MOD

		for k, v in pairs(VEGGIES) do
			weights[k] = v.seed_weight * ((PLANT_DEFS[k] and PLANT_DEFS[k].good_seasons[season]) and season_mod or 1)
		end

		return "farm_plant_"..weighted_random_choice(weights)
	end
    return "weed_forgetmelots"
end

local function ReplaceWithRandomPlant(inst)
	local plant = SpawnPrefab(pickfarmplant())
	plant.Transform:SetPosition(inst.Transform:GetWorldPosition())

	if plant.plant_def ~= nil then
		plant.no_oversized = true
		plant.components.farmsoildrinker:CopyFrom(inst.components.farmsoildrinker)
		plant.components.farmplantstress:CopyFrom(inst.components.farmplantstress)
		plant.components.growable:DoGrowth()
		plant.AnimState:OverrideSymbol("veggie_seed", "farm_soil", "seed")
	end

	inst.grew_into = plant -- so the caller can get the new plant that replaced this object
	inst:Remove()
end

local KILLJOY_PLANT_MUST_TAGS = {"farm_plant_killjoy"}
local POLLEN_SOURCE_NOT_TAGS = {"farm_plant_killjoy"}

local function KillJoyStressTest(inst, currentstress, apply)
	if inst.plant_def.max_killjoys_tolerance then
		local x, y, z = inst.Transform:GetWorldPosition()
		return #TheSim:FindEntities(x, y, z, TUNING.FARM_PLANT_KILLJOY_RADIUS, KILLJOY_PLANT_MUST_TAGS) > inst.plant_def.max_killjoys_tolerance
	end
	return false
end

local function FamilyStressTest(inst, currentstress, apply)
	local x, y, z = inst.Transform:GetWorldPosition()
	local num_plants = inst.plant_def.family_min_count > 0 and #TheSim:FindEntities(x, y, z, inst.plant_def.family_check_dist, {inst.plant_def.plant_type_tag}, POLLEN_SOURCE_NOT_TAGS) or 0   -- family_min_count includes self
	return num_plants < inst.plant_def.family_min_count
end

local function SeasonStressTest(inst, currentstress, apply)
	return not inst.plant_def.good_seasons[TheWorld.state.season]
end

local function MoistureStressTest(inst, currentstress, apply)
	local moisture = inst.components.farmsoildrinker
	if moisture then
		return moisture:CalcPercentTimeHydrated() < inst.plant_def.moisture.min_percent
	end
	return false
end

local function NutrientsStressTest(inst, currentstress, apply)
	local x, y, z = inst.Transform:GetWorldPosition()
	if TheWorld.components.farming_manager then
		return TheWorld.components.farming_manager:CycleNutrientsAtPoint(x, y, z, inst.plant_def.nutrient_consumption, inst.plant_def.nutrient_restoration, not apply)
	end
	return false
end

local function HappinessStressTest(inst, currentstress, apply)
	return currentstress
end

local function MakeStressCheckpoint(inst, is_final_stage)
	if inst.components.farmplantstress ~= nil then

		-- killjoys
		inst.components.farmplantstress:SetStressed("killjoys", KillJoyStressTest(inst, nil, true))

		-- family
		inst.components.farmplantstress:SetStressed("family", FamilyStressTest(inst, nil, true))

		-- season
		inst.components.farmplantstress:SetStressed("season", SeasonStressTest(inst, nil, true))
		
		-- moisture
		local moisture = inst.components.farmsoildrinker
		if moisture ~= nil then
			inst.components.farmplantstress:SetStressed("moisture", MoistureStressTest(inst, nil, true))
			moisture:Reset()
		end

		-- nutrients
		inst.components.farmplantstress:SetStressed("nutrients", NutrientsStressTest(inst, nil, true))

		-- happiness is update via an action callback

		-- update checkpoint for this stage
		inst.components.farmplantstress:MakeCheckpoint()
		if is_final_stage then
			inst.components.farmplantstress:CalcFinalStressState()
		end

		inst.scale = math.random() * 0.07 + (inst.components.farmplantstress.checkpoint_stress_points <= 0.5 * inst.components.farmplantstress.num_stressors and 0.93 or 0.86)
	end
end

local function PlaySowAnim(inst)
	if POPULATING or inst:IsAsleep() then
		inst.AnimState:PlayAnimation("sow_idle", true)
	else
		inst.AnimState:PlayAnimation("sow", false)
		inst.AnimState:PushAnimation("sow_idle", true)
	end
end

local function PlayStageAnim(inst, anim)
	if POPULATING or inst:IsAsleep() then
		inst.AnimState:PlayAnimation("crop_"..anim, true)
		inst.AnimState:SetTime(10 + math.random() * 2)
	else
		inst.AnimState:PlayAnimation("grow_"..anim, false)
		inst.AnimState:PushAnimation("crop_"..anim, true)
	end

	local scale = inst.scale or 1
	inst.Transform:SetScale(scale, scale, scale)
end

local function OnPicked(inst, doer)
    local soil = SpawnPrefab("farm_soil")
    soil.Transform:SetPosition(inst.Transform:GetWorldPosition())
    soil:PushEvent("breaksoil")

	call_for_reinforcements(inst, doer)

    inst:Remove()
end

local function MakePickable(inst, enable, product)
    if not enable then
		inst:RemoveTag("fruitflyspawner")
        inst:RemoveComponent("pickable")
    else
        if inst.components.pickable == nil then
            inst:AddComponent("pickable")
            inst.components.pickable.onpickedfn = OnPicked
        end
	    inst.components.pickable:SetUp(nil)
		inst.components.pickable.use_lootdropper_for_product = true
	    inst.components.pickable.picksound = product == "spoiled_food" and "dontstarve/wilson/harvest_berries" or "dontstarve/wilson/pickup_plants"
		inst:AddTag("fruitflyspawner")
    end
end

local function MakeRotten(inst, rotten)
	if rotten then
		inst:AddTag("farm_plant_killjoy") -- party pooper...
		inst:AddTag("pickable_harvest_str")
	else
		inst:RemoveTag("farm_plant_killjoy")
		inst:RemoveTag("pickable_harvest_str")
	end
end

local function MakePlantedSeed(inst, seed_state)
	if seed_state then
		inst:AddTag("planted_seed")
	else
		inst:RemoveTag("planted_seed")
	end
end

local spoiled_food_loot = {"spoiled_food"}

local function SetupLoot(lootdropper)
	local inst = lootdropper.inst

	if inst:HasTag("farm_plant_killjoy") then -- if rotten
		lootdropper:SetLoot(inst.is_oversized and inst.plant_def.loot_oversized_rot or spoiled_food_loot)
	elseif inst.components.pickable ~= nil then
		local plant_stress = inst.components.farmplantstress ~= nil and inst.components.farmplantstress:GetFinalStressState() or FARM_PLANT_STRESS.HIGH

		if inst.is_oversized then
			lootdropper:SetLoot({inst.plant_def.product_oversized})
		elseif plant_stress == FARM_PLANT_STRESS.LOW  or plant_stress == FARM_PLANT_STRESS.NONE then
			lootdropper:SetLoot({inst.plant_def.product, inst.plant_def.seed, inst.plant_def.seed})
		elseif plant_stress == FARM_PLANT_STRESS.MODERATE then
			lootdropper:SetLoot({inst.plant_def.product, inst.plant_def.seed})
		else -- plant_stress == FARM_PLANT_STRESS.HIGH
			lootdropper:SetLoot({inst.plant_def.product})
		end
	end
end

local function GetGerminationTime(inst, stage_num, stage_data)
	local is_good_season = inst.plant_def.good_seasons[TheWorld.state.season]
	local grow_time = inst.plant_def.grow_time.seed
	return GetRandomMinMax(grow_time[1], grow_time[2]) * (is_good_season and 0.5 or 1)
end

local function CalcGrowTime(step, num_steps, min_time, max_time)
	local max_var = max_time - min_time
	local var_per_point = max_var / num_steps
	
	return min_time + step * var_per_point + math.random()*var_per_point
end

local function GetGrowTime(inst, stage_num, stage_data)
	local grow_time = inst.plant_def.grow_time[stage_data.name]
	local is_good_season = inst.plant_def.good_seasons[TheWorld.state.season]

	if grow_time ~= nil and inst.components.farmplantstress ~= nil then
		return CalcGrowTime(inst.components.farmplantstress.checkpoint_stress_points, inst.components.farmplantstress.num_stressors + 1, grow_time[1], grow_time[2]) * (is_good_season and 0.5 or 1)
	end
end

local function GetSpoilTime(inst)
	return inst.is_oversized and inst.plant_def.grow_time.oversized or inst.plant_def.grow_time.full
end

local function UpdateResearchStage(inst, stage)
	if stage == 5 and inst.is_oversized then
		stage = 6
	elseif stage == 6 then
		stage = 7
	end

	inst._research_stage:set(stage - 1) -- to make it a 0 a based range
end

local function GetResearchStage(inst)
	return inst._research_stage:value() + 1	-- +1 to make it 1 a based rage
end

local function GetPlantRegistryKey(inst)
	return inst.plantregistrykey
end

local GROWTH_STAGES_RANDOMSEED =
{
    {
        name = "seed",
        time = GetGerminationTime,
        fn = function(inst, stage, stage_data)
            MakePlantedSeed(inst, true)
			inst.components.farmplanttendable:SetTendable(stage_data.tendable)
            PlaySowAnim(inst)
        end,
		dig_fx = "dirt_puff",
		inspect_str = "SEED",
		tendable = true,
    },
    {
        name = "sprout",
        time = GetGrowTime,
        fn = function(inst, stage)
			ReplaceWithRandomPlant(inst)
        end,
		dig_fx = "dirt_puff",
		inspect_str = "GROWING",
		tendable = true,
    },
}

local GROWTH_STAGES =
{
    {
        name = "seed",
        time = GetGerminationTime,
        fn = function(inst, stage, stage_data)
            MakePlantedSeed(inst, true)
            MakeRotten(inst, false)
            MakePickable(inst, false)
			inst.components.farmplanttendable:SetTendable(stage_data.tendable)

			inst:UpdateResearchStage(stage)
			PlayStageAnim(inst, "seed")
        end,
		dig_fx = "dirt_puff",
		inspect_str = "SEED",
		tendable = true,
    },
    {
        name = "sprout",
        time = GetGrowTime,
		pregrowfn = function(inst)
			MakeStressCheckpoint(inst)
		end,
        fn = function(inst, stage, stage_data)
			MakePlantedSeed(inst, false)
			MakeRotten(inst, false)
			MakePickable(inst, false)
			inst.components.farmplanttendable:SetTendable(stage_data.tendable)

			inst:UpdateResearchStage(stage)
			PlayStageAnim(inst, "sprout")
        end,
		dig_fx = "dirt_puff",
		inspect_str = "GROWING",
		tendable = true,
    },
    {
        name = "small",
        time = GetGrowTime,
		pregrowfn = function(inst)
			MakeStressCheckpoint(inst)
		end,
        fn = function(inst, stage, stage_data)
            MakePlantedSeed(inst, false)
            MakeRotten(inst, false)
            MakePickable(inst, false)
			inst.components.farmplanttendable:SetTendable(stage_data.tendable)

			inst:UpdateResearchStage(stage)
            PlayStageAnim(inst, "small")
        end,
		dig_fx = "dirt_puff",
		inspect_str = "GROWING",
		tendable = true,
    },
    {
        name = "med",
        time = GetGrowTime,
 		pregrowfn = function(inst)
			MakeStressCheckpoint(inst)
		end,
        fn = function(inst, stage, stage_data)
            MakePlantedSeed(inst, false)
            MakeRotten(inst, false)
            MakePickable(inst, false)
			inst.components.farmplanttendable:SetTendable(stage_data.tendable)

			inst:UpdateResearchStage(stage)
            PlayStageAnim(inst, "med")
        end,
		dig_fx = "dirt_puff",
		inspect_str = "GROWING",
		tendable = true,
    },
    {
        name = "full",
        time = GetSpoilTime,
 		pregrowfn = function(inst)
			MakeStressCheckpoint(inst, true)
			inst.is_oversized = inst.force_oversized or (not inst.no_oversized and inst.components.farmplantstress ~= nil and inst.components.farmplantstress:GetFinalStressState() == FARM_PLANT_STRESS.NONE)
		end,
		fn = function(inst, stage, stage_data)
            MakePlantedSeed(inst, false)
            MakeRotten(inst, false)
            MakePickable(inst, true)
			inst.components.farmplanttendable:SetTendable(stage_data.tendable)

			TheWorld:PushEvent("ms_fruitflyspawneractive", {plant = inst, check_others = true})

			inst:UpdateResearchStage(stage)
            PlayStageAnim(inst, inst.is_oversized and "oversized" or "full")
        end,
		dig_fx = "dirt_puff",
		inspect_str = "FULL",
		tendable = false,
    },
    {
        name = "rotten",
		pregrowfn = function(inst)
			TheWorld:PushEvent("ms_oncroprotted", inst)
	   	end,
        fn = function(inst, stage, stage_data)
            MakeRotten(inst, true)
            MakePickable(inst, true)
            MakePlantedSeed(inst, false)
			inst.components.farmplanttendable:SetTendable(stage_data.tendable)
			inst.components.growable:StopGrowing()

			inst:UpdateResearchStage(stage)
            PlayStageAnim(inst, inst.is_oversized and "rot_oversized" or "rot")
        end,
		dig_fx = "dirt_puff",
		inspect_str = "ROTTEN",
		tendable = false,
    },
}

local function RepeatMagicGrowth(inst)
	if inst:IsValid() and inst.components.growable ~= nil then
		inst.components.growable:DoMagicGrowth()
	end
end

local function domagicgrowthfn(inst)
	if inst:IsValid() and inst.components.growable:IsGrowing() then
		inst.no_oversized = true

		if inst.components.farmsoildrinker ~= nil then
			local remaining_time = inst.components.growable.targettime - GetTime()
			local drink = remaining_time * inst.components.farmsoildrinker:GetMoistureRate()

			local x, y, z = inst.Transform:GetWorldPosition()
			TheWorld.components.farming_manager:AddSoilMoistureAtPoint(x, y, z, drink)
		end

		inst.components.growable:DoGrowth()
		if inst.grew_into ~= nil then
			inst = inst.grew_into
		end
		if inst:IsValid() and inst.components.pickable == nil then
			inst:DoTaskInTime(0.5 + math.random() + 0.25, RepeatMagicGrowth)	-- we need a new function so that seeds grow into a weeds, it will call the right function
		end
		return true
	end

	return false
end

local function GetStatus(inst)
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
		return "BURNING"
	end

	local stage_data = inst.components.growable:GetCurrentStageData()
	local str = stage_data ~= nil and stage_data.inspect_str or nil
	if inst.is_oversized then
		str = str.."_OVERSIZED"
	end

	return str
end

local function GetDisplayName(inst)
	local plantregistryinfo = inst.plant_def.plantregistryinfo
	if plantregistryinfo == nil then
		return nil
	end
	local research_stage = inst:GetResearchStage()
	local research_stage_info = plantregistryinfo[research_stage]
	local registry_key = inst:GetPlantRegistryKey()

	if research_stage_info == nil then
		return nil
	end

	if research_stage_info.learnseed then
		local seed_name = (ThePlantRegistry:KnowsSeed(registry_key, plantregistryinfo) and ThePlantRegistry:KnowsPlantName(registry_key, plantregistryinfo)) and STRINGS.NAMES["KNOWN_"..string.upper(inst.plant_def.seed)] or STRINGS.NAMES[string.upper(inst.plant_def.seed)]
		return subfmt(STRINGS.NAMES.FARM_PLANT_SEED, {seed = seed_name})
	end

	return research_stage_info.is_rotten and STRINGS.NAMES.FARM_PLANT_ROTTEN
		or not ThePlantRegistry:KnowsPlantName(registry_key, plantregistryinfo, research_stage) and STRINGS.NAMES.FARM_PLANT_UNKNOWN
		or nil
end

local function plantresearchfn(inst)
	return inst:GetPlantRegistryKey(), inst:GetResearchStage()
end

local function PushFruitFlySpawnerEvent(inst)
	if inst:HasTag("fruitflyspawner") then
		TheWorld:PushEvent("ms_fruitflyspawneractive", {plant = inst, check_others = false})
	end
end

local function OnLootPrefabSpawned(inst, data)
	local loot = data.loot
	if loot then
		loot.from_plant = true
	end
end

local function OnSave(inst, data)
	data.is_oversized = inst.is_oversized
	data.no_oversized = inst.no_oversized
	data.scale = inst.scale
end

local function OnPreLoad(inst, data)
	if data ~= nil then
		inst.is_oversized = data.is_oversized
		inst.no_oversized = data.no_oversized
		inst.scale = data.scale
	end
end

local function MakePlant(plant_def)
    local assets =
    {
        Asset("ANIM", "anim/"..plant_def.bank..".zip"),
        Asset("ANIM", "anim/"..plant_def.build..".zip"),
        Asset("ANIM", "anim/farm_soil.zip"),
		Asset("SCRIPT", "scripts/prefabs/farm_plant_defs.lua"),
		Asset("SCRIPT", "scripts/prefabs/weed_defs.lua"),
    }

    local prefabs =
    {
        "spoiled_food",
		"farm_plant_happy",
		"farm_plant_unhappy",
    }
	if plant_def.product ~= nil then			table.insert(prefabs, plant_def.product) end
	if plant_def.product_oversized ~= nil then	table.insert(prefabs, plant_def.product_oversized) end
	if plant_def.seed ~= nil then				table.insert(prefabs, plant_def.seed) end
	for k, v in pairs(GROWTH_STAGES) do
		if v.dig_fx ~= nil then
			table.insert(prefabs, v.dig_fx)
		end
	end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank(plant_def.bank)
        inst.AnimState:SetBuild(plant_def.build)
		inst.AnimState:OverrideSymbol("soil01", "farm_soil", "soil01")

		inst:SetPhysicsRadiusOverride(TUNING.FARM_PLANT_PHYSICS_RADIUS)

        inst:AddTag("plantedsoil")
        inst:AddTag("farm_plant")
		inst:AddTag("plant")
		if plant_def.plant_type_tag then
			inst:AddTag(plant_def.plant_type_tag)
		end
		inst:AddTag("plantresearchable")
		inst:AddTag("farmplantstress") --for plantresearchable component.
		inst:AddTag("tendable_farmplant") -- for farmplanttendable component

		inst._research_stage = (plant_def.stage_netvar or net_tinybyte)(inst.GUID, "farm_plant.research_stage") -- use inst:GetResearchStage() to access this value
		inst.plantregistrykey = plant_def.product
		inst.GetPlantRegistryKey = GetPlantRegistryKey
		inst.GetResearchStage = GetResearchStage

		inst.displaynamefn = GetDisplayName

        inst.plant_def = plant_def
        
        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

		inst.UpdateResearchStage = UpdateResearchStage

		inst:AddComponent("inspectable")
		inst.components.inspectable.getstatus = GetStatus
		inst.components.inspectable.nameoverride = "FARM_PLANT"

		inst:AddComponent("plantresearchable")
		inst.components.plantresearchable:SetResearchFn(plantresearchfn)

		inst:AddComponent("farmplantstress")
		inst.components.farmplantstress:AddStressCategory("nutrients", NutrientsStressTest)
		inst.components.farmplantstress:AddStressCategory("moisture", MoistureStressTest)
		inst.components.farmplantstress:AddStressCategory("killjoys", KillJoyStressTest)
		inst.components.farmplantstress:AddStressCategory("family", FamilyStressTest)
		inst.components.farmplantstress:AddStressCategory("season", SeasonStressTest)
		inst.components.farmplantstress:AddStressCategory("happiness", HappinessStressTest, on_happiness_changed)

		inst:AddComponent("farmsoildrinker")
		inst.components.farmsoildrinker.getdrinkratefn = GetDrinkRate
		inst.components.farmsoildrinker.onsoilmoisturestatechangefn = OnSoilMoistureStateChange

		inst:AddComponent("farmplanttendable")
		inst.components.farmplanttendable.ontendtofn = ontendto

		inst:AddComponent("hauntable")
		inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

	    inst:AddComponent("lootdropper")
		inst.components.lootdropper.lootsetupfn = SetupLoot

		inst:AddComponent("growable")
		inst.components.growable.growoffscreen = true
		inst.components.growable.stages = plant_def.is_randomseed and GROWTH_STAGES_RANDOMSEED or GROWTH_STAGES
		inst.components.growable:SetStage(1)
		inst.components.growable:StartGrowing()
		inst.components.growable.domagicgrowthfn = domagicgrowthfn
		inst.components.growable.magicgrowable = true

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.DIG)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(dig_up)

		if not plant_def.fireproof then
			MakeSmallBurnable(inst)
			MakeSmallPropagator(inst)
			inst.components.burnable:SetOnBurntFn(onburnt)
			inst.components.burnable:SetOnIgniteFn(onignite)
			inst.components.burnable:SetOnExtinguishFn(onextinguish)
		end

		--inst.no_oversized = false

		inst:WatchWorldState("isnight", OnIsNight)

		inst:ListenForEvent("ms_fruitflytimerfinished", function() PushFruitFlySpawnerEvent(inst) end, TheWorld)
		inst:ListenForEvent("entitywake", PushFruitFlySpawnerEvent)
		inst:ListenForEvent("loot_prefab_spawned", OnLootPrefabSpawned)

		inst.OnSave = OnSave
		inst.OnPreLoad = OnPreLoad

        return inst
    end

    return Prefab(plant_def.prefab, fn, assets, prefabs)
end


local plant_prefabs = {}
for k, v in pairs(PLANT_DEFS) do
	if not v.data_only then --allow mods to skip our prefab constructor.
		table.insert(plant_prefabs, MakePlant(v))
	end
end

return unpack(plant_prefabs)
