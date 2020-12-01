local USE_SETTINGS_FILE = PLATFORM ~= "PS4" and PLATFORM ~= "NACL"

local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
local WEED_DEFS = require("prefabs/weed_defs").WEED_DEFS
local FERTILIZER_DEFS = require("prefabs/fertilizer_nutrient_defs").FERTILIZER_DEFS

local PlantRegistryData = Class(function(self)
	self.plants = {}
	self.fertilizers = {}
    
	self.filters = {}
	--self.save_enabled = nil
end)

function PlantRegistryData:GetKnownPlants()
	return self.plants
end

function PlantRegistryData:GetKnownPlantStages(plant)
	if self.plants[plant] then
		return self.plants[plant]
	end
	return {}
end

function PlantRegistryData:IsAnyPlantStageKnown(plant)
	if self.plants[plant] then
		return not IsTableEmpty(self.plants[plant])
	end
	return false
end

function PlantRegistryData:KnowsPlantStage(plant, stage)
	if self.plants[plant] then
		return self.plants[plant][stage] == true
	end
	return false
end

function PlantRegistryData:KnowsSeed(plant, plantregistryinfo)
	for stage in pairs(self.plants[plant] or {}) do
		if plantregistryinfo[stage] and plantregistryinfo[stage].learnseed then
			return true
		end
	end
	return false
end

function PlantRegistryData:KnowsPlantName(plant, plantregistryinfo, research_stage) -- research_stage is optional
	if research_stage ~= nil and plantregistryinfo[research_stage] and plantregistryinfo[research_stage].revealplantname then
		return true
	end

	for stage in pairs(self.plants[plant] or {}) do
		if plantregistryinfo[stage] and plantregistryinfo[stage].revealplantname then
			return true
		end
	end
	return false
end

function PlantRegistryData:KnowsFertilizer(fertilizer)
	return self.fertilizers[fertilizer] == true
end

function PlantRegistryData:HasOversizedPicture(plant)
	return false
end

function PlantRegistryData:GetPlantPercent(plant, plantregistryinfo)
	local totalstages = 0
	local knownstages = 0
	local hasfullgrown = false
	local knowsfullgrown = false
	for stage, data in pairs(plantregistryinfo) do
		if data.growing then
			totalstages = totalstages + 1
			if self:KnowsPlantStage(plant, stage) then
				knownstages = knownstages + 1
			end
		elseif data.fullgrown then
			if not hasfullgrown then
				hasfullgrown = true
				totalstages = totalstages + 1
			end
			if not knowsfullgrown and self:KnowsPlantStage(plant, stage) then
				knowsfullgrown = true
				knownstages = knownstages + 1
			end
		end
	end
	return knownstages / totalstages
end

function PlantRegistryData:Save(force_save)
	if force_save or (self.save_enabled and self.dirty) then
		local str = DataDumper({plants = self.plants, fertilizers = self.fertilizers, filters = self.filters}, nil, true)
		TheSim:SetPersistentString("plantregistry", str, false)
	end
end

function PlantRegistryData:Load()
	self.preparedfoods = {}
	TheSim:GetPersistentString("plantregistry", function(load_success, data) 
		if load_success and data ~= nil then
            local success, plant_registry = RunInSandbox(data)
		    if success and plant_registry then
				self.plants = plant_registry.plants or {}
				self.fertilizers = plant_registry.fertilizers or {}
				self.filters = plant_registry.filters or {}
			else
				print("Failed to load the plantregistry!", plant_registry)
			end
		end
	end)
end

local function DecodePlantRegistryStages(value)
	local bitstages = tonumber(value, 16)
	local stages = {}
	for i = 1, 8 do
		if checkbit(bitstages, 2^(i-1)) then
			stages[i] = true
		end
	end
	return stages
end

local function EncodePlantRegistryStages(stages)
	local bitstages = 0
	for i in pairs(stages) do
		bitstages = setbit(bitstages, 2^(i-1))
	end
	return string.format("%x", bitstages)
end

function PlantRegistryData:ApplyOnlineProfileData()
	if not self.synced and not (TheFrontEnd ~= nil and TheFrontEnd:GetIsOfflineMode() or not TheNet:IsOnlineMode()) and TheInventory:HasDownloadedInventory() then
		self.plants = self.plants or {}
		self.fertilizers = self.fertilizers or {}
		for k, v in pairs(TheInventory:GetLocalPlantRegistry()) do
			self.plants[k] = DecodePlantRegistryStages(v)
		end
		self.synced = true
	end
	return self.synced
end

function PlantRegistryData:ClearFilters()
	self.filters = {}
	self.dirty = true
end

function PlantRegistryData:SetFilter(category, value)
	if self.filters[category] ~= value then
		self.filters[category] = value
		self.dirty = true
	end
end

function PlantRegistryData:GetFilter(category)
	return self.filters[category]
end

local function UnlockPlant(self, plant)
	if self.plants[plant] == nil then
		self.plants[plant] = {}
	end
	return self.plants[plant]
end

function PlantRegistryData:LearnPlantStage(plant, stage)
	if plant == nil or stage == nil then
		print("Invalid plant or stage", plant, stage)
		return
	end

	local stages = UnlockPlant(self, plant)
	local updated = stages[stage] == nil
	stages[stage] = true

	if updated and self.save_enabled then
		local def = PLANT_DEFS[plant] or WEED_DEFS[plant]
		if def and not def.modded and not TheNet:IsDedicated() then
			TheInventory:SetPlantRegistryValue(plant, EncodePlantRegistryStages(stages))
		end
		self:Save(true)
	end

	return updated
end

function PlantRegistryData:LearnFertilizer(fertilizer)
	if fertilizer == nil then
		print("Invalid fertilizer", fertilizer)
		return
	end

	local updated = self.fertilizers[fertilizer] == nil
	self.fertilizers[fertilizer] = true

	if updated and self.save_enabled then
		local def = FERTILIZER_DEFS[fertilizer]
		if def and not def.modded and not TheNet:IsDedicated() then
			TheInventory:SetPlantRegistryValue(fertilizer, "true")
		end
		self:Save(true)
	end

	return updated
end

return PlantRegistryData