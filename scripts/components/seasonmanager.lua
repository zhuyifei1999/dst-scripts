local SeasonManager = Class(function(self, inst)
    self.inst = inst
end)

local season_manager = SeasonManager()

function SeasonManager:IsWetSeason()
	return false;
end

function SeasonManager:IsDrySeason()
	return false;
end

function GetSeasonManager()
	return season_manager
end