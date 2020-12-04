local function onplayeractivated(inst)
	local self = inst.components.plantregistryupdater
	if not TheNet:IsDedicated() and inst == ThePlayer then
		self.plantregistry = ThePlantRegistry
		self.plantregistry.save_enabled = true
	end
end

local PlantRegistryUpdater = Class(function(self, inst)
    self.inst = inst

	self.plantregistry = require("plantregistrydata")()
	inst:ListenForEvent("playeractivated", onplayeractivated)
end)

function PlantRegistryUpdater:LearnPlantStage(plant, stage)
    if plant and stage then
		local updated = self.plantregistry:LearnPlantStage(plant, stage)
		--print("PlantRegistryUpdater:LearnPlantStage", plant, stage)

		-- Servers will only tell the clients if this is a new plant stage in this world
		-- Since the servers do not know the client's actual plantregistry data, this is the best we can do for reducing the amount of data sent
		if updated and (TheNet:IsDedicated() or (TheWorld.ismastersim and self.inst ~= ThePlayer)) then
			if self.inst.player_classified ~= nil then
				self.inst.player_classified.plantregistry_learnplantstage:set(plant..":"..stage)
			end
		end
	end
end

function PlantRegistryUpdater:LearnFertilizer(fertilizer)
    if fertilizer then
		local updated = self.plantregistry:LearnFertilizer(fertilizer)
		--print("PlantRegistryUpdater:LearnFertilizer", fertilizer)

		-- Servers will only tell the clients if this is a fertilizer in this world
		-- Since the servers do not know the client's actual plantregistry data, this is the best we can do for reducing the amount of data sent
		if updated and (TheNet:IsDedicated() or (TheWorld.ismastersim and self.inst ~= ThePlayer)) then
			if self.inst.player_classified ~= nil then
				self.inst.player_classified.plantregistry_learnfertilizer:set(fertilizer)
			end
		end
	end
end


return PlantRegistryUpdater