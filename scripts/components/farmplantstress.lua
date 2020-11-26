local SourceModifierList = require("util/sourcemodifierlist")

-- Stress:
--  plant stress slows down the growth rate of the plant and reducing the time you have to pick the plant when it's ready to harvest
--  failing a stress category will never be a hard failure.
--  ignoring the plant stress shouldn't be much worse than the old system

-- Grow Score 
--  each growth stage will track how well the player did for each stress category

-- Final Score 
-- Scoring: 6 categories * 4 growth stages = 24 stress points (lower score is better)
--  0 -  1: none
--  2 -  6: low
--  7 - 12: moderate
-- 13 - 20: high

-- Stress Categories --
-----------------------
-- Ground Nutrients
--  Idea: There needs to be enough nutrients in the soil for the plant to grow
--  Scoring: check for enough nutrients at growth stage change
--	Indicator: ground tile nutrient art

-- Ground Moisture
--  Idea: There needs to be enough moisture in the soil for the plant to grow
--	Scoring: track the amount of time the soil was moist during the plant's growth state. Check if the amount of moisture was within the plant's tolerance at growth stage change 
--	indicator: ground tile moisture art

-- Killjoys
--  Idea: Plants don't like being near weeds, rotting planets, etc
--  Scoring: check for killjoys at growth stage change
--	indicator: player sees weeds and rotten plants are nearby

-- Season
--  Idea: Each plant has preferred growing season(s)
--  Scoring: check for the season at growth stage change
--	indicator: see farming book for info

-- Happiness
--  Idea: Research shows that plants grow better when given a little TLC (citation needed)
--	Actions: Tend to an individual plant (right-click action) or play music for an AOE effect
--  Scoring: At growth stage change, check if a plant has been tended to during the previous stage
--	indicator: when a plant becomes happy it will play sparkle fx

-- Family
--  Idea: Plants need other plants of the same type nearby in order to properly pollinate
--  Scoring: At growth stage change, check for the number of the same type of plants nearby (not including rotten plants)
--	indicator: none


local FarmPlantStress = Class(function(self, inst)
    self.inst = inst

	self.stressors = {}
	self.stressors_testfns = {}
	self.stressor_fns = {}
	self.stress_points = 0
	self.max_stress_points = 0
	self.num_stressors = 0
	self.checkpoint_stress_points = 0

	self.final_stress_state = nil

	self.inst:AddTag("farmplantstress")
end)

function FarmPlantStress:AddStressCategory(name, testfn, onchangefn)
	self.stressors[name] = true -- default to stressed
	self.stressors_testfns[name] = testfn
	self.stressor_fns[name] = onchangefn
	self.num_stressors = self.num_stressors + 1
end

function FarmPlantStress:CopyFrom(rhs)
	self:OnLoad(rhs:OnSave())
end

function FarmPlantStress:SetStressed(name, stressed, doer)
	local prev = self.stressors[name]
	if prev ~= nil then
		self.stressors[name] = stressed == true
		if stressed ~= prev and self.stressor_fns[name] ~= nil then
			self.stressor_fns[name](self.inst, stressed, doer)
		end
	end
end

function FarmPlantStress:MakeCheckpoint()
	if c_sel() == self.inst then
		print("FarmPlantStress: ", self.inst)
		for stressor, stressed in pairs(self.stressors) do
			print("  " .. (stressed and "stressed" or "all good"), stressor)
		end
	end

	self.checkpoint_stress_points = 0

	for stressor, stressed in pairs(self.stressors) do
		if stressed then
			self.checkpoint_stress_points = self.checkpoint_stress_points + 1
		else
			self.stressors[stressor] = true -- reset to stressed
		end

	end

	self.stress_points = self.stress_points + self.checkpoint_stress_points
	self.max_stress_points = self.max_stress_points + self.num_stressors
end

function FarmPlantStress:CalcFinalStressState()
	local stress = self.max_stress_points > 0 and (self.stress_points / self.max_stress_points) or 0
	self.final_stress_state = stress <= .051 and FARM_PLANT_STRESS.NONE
							or stress <= .251 and FARM_PLANT_STRESS.LOW
							or stress <= .501 and FARM_PLANT_STRESS.MODERATE
							or FARM_PLANT_STRESS.HIGH

	--self.final_stress_state = FARM_PLANT_STRESS.NONE

	return self.final_stress_state
end

function FarmPlantStress:GetFinalStressState()
	return self.final_stress_state
end

function FarmPlantStress:OnInteractWith(doer)
	return self.oninteractwithfn ~= nil and self.oninteractwithfn(self.inst, doer)
end

function FarmPlantStress:GetStressDescription(viewer)
    if self.inst == viewer then
        return
    elseif not CanEntitySeeTarget(viewer, self.inst) then
		return GetString(viewer, "DESCRIBE_TOODARK")
	elseif self.inst.components.burnable ~= nil and self.inst.components.burnable:IsSmoldering() then
        return GetString(viewer, "DESCRIBE_SMOLDERING")
	end
	
	local stressors = {}
	for stressor, testfn in pairs(self.stressors_testfns) do
		if testfn(self.inst, self.stressors[stressor], false) then
			table.insert(stressors, stressor)
		end
	end

	if #stressors == 0 then
		return GetString(viewer, "DESCRIBE_PLANTHAPPY")
	elseif viewer:HasTag("plantkin") or (viewer.replica.inventory and viewer.replica.inventory:EquipHasTag("detailedplanthappiness")) then
		local stressor = shuffleArray(stressors)[1]
		return GetString(viewer, "DESCRIBE_PLANTSTRESSOR"..string.upper(stressor))
	else
		if #stressors >= 5 then
			return GetString(viewer, "DESCRIBE_PLANTVERYSTRESSED")
		else --if #stressors <= 4 then
			return GetString(viewer, "DESCRIBE_PLANTSTRESSED")
		end
	end
end

function FarmPlantStress:OnSave()
	return {
		final_stress_state = self.final_stress_state,
		max_stress_points = self.max_stress_points,
		stress_points = self.stress_points,
		stressors = self.stressors,
		checkpoint = self.checkpoint_stress_points,
	}
end

function FarmPlantStress:OnLoad(data)
	if data ~= nil then
		self.final_stress_state = data.final_stress_state
		self.max_stress_points = data.max_stress_points
		self.stress_points = data.stress_points
		self.checkpoint_stress_points = data.checkpoint
		for k, _ in pairs(self.stressors) do
			self.stressors[k] = data.stressors[k]
		end
	end
end

function FarmPlantStress:GetDebugString()
	local final_stress = self.final_stress_state ~= nil and (", Final: " .. tostring(table.invert(FARM_PLANT_STRESS)[self.final_stress_state])) or ""
	return "" .. tostring(self.stress_points) .. "/" .. tostring(self.max_stress_points) .. "(" .. string.format("%.3f", self.max_stress_points > 0 and (self.stress_points / self.max_stress_points) or 0) .. "), Checkpint stress: " .. tostring(self.checkpoint_stress_points) .. final_stress .. ", #Cats: " .. tostring(GetTableSize(self.stressors))
end

return FarmPlantStress
