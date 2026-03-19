local GetCreatureScanData = require("wx78_moduledefs").GetCreatureScanDataDefinition

local function process_data_increase(inst, self)
    for prefab, num in pairs(self.datahistory) do
        local creature_data = GetCreatureScanData(prefab)
        if creature_data ~= nil and num < creature_data.maxdata then
            self.datahistory[prefab] = math.min(num + (creature_data.maxdata/16), creature_data.maxdata)
        end
    end
end

local DataAnalyzer = Class(function(self, inst)
    self.inst = inst

    self.datahistory = {}
end)

function DataAnalyzer:StartDataRegen(dt)
    if self._process_data_task ~= nil then
        self._process_data_task:Cancel()
    end
    self._process_data_task = self.inst:DoPeriodicTask(dt, process_data_increase, nil, self)
end

function DataAnalyzer:StopDataRegen()
    if self._process_data_task ~= nil then
        self._process_data_task:Cancel()
        self._process_data_task = nil
    end
end

function DataAnalyzer:GetData(ent_or_prefab)
    local creature_data, scan_id = GetCreatureScanData(ent_or_prefab)
    if self.datahistory[scan_id] then
        return math.floor(self.datahistory[scan_id])
    else
        if creature_data ~= nil then
            self.datahistory[scan_id] = creature_data.maxdata
            return creature_data.maxdata
        end
    end

    return 0
end

function DataAnalyzer:SpendData(prefab)
    if self.datahistory[prefab] == nil then
        local creature_data = GetCreatureScanData(prefab)
        if creature_data ~= nil then
            self.datahistory[prefab] = creature_data.maxdata
        end
    end

    if self.datahistory[prefab] ~= nil then
        local data = math.floor(self.datahistory[prefab])
        self.datahistory[prefab] = self.datahistory[prefab] - data
        return data
    else
        return 0
    end
end

---- SAVE/LOAD ----------------------------------------------------------------------

function DataAnalyzer:OnSave()
    return {
        datahistory = self.datahistory,
    }
end

function DataAnalyzer:OnLoad(data, newents)
    if data ~= nil then
        if data.datahistory then
            self.datahistory = data.datahistory
        end
    end
end

return DataAnalyzer
