--------------------------------------------------------------------------
--[[ WorldState ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
assert(inst == TheWorld, "Invalid world")
self.inst = inst
self.data = {}

--Private
local _watchers = {}

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function SetVariable(var, val, togglename)
    if self.data[var] ~= val and val ~= nil then
        self.data[var] = val

        local watchers = _watchers[var]
        if watchers ~= nil then
            for k, v in pairs(watchers) do
                for i, fn in ipairs(v) do
                    fn[1](fn[2], val)
                end
            end
        end

        if togglename then
            watchers = _watchers[(val and "start" or "stop")..togglename]
            if watchers ~= nil then
                for k, v in pairs(watchers) do
                    for i, fn in ipairs(v) do
                        fn[1](fn[2])
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnClockTick(src, data)
    SetVariable("time", data.time)
    SetVariable("timeinphase", data.timeinphase)
end

local function OnCyclesChanged(src, cycles)
    SetVariable("cycles", cycles)
end

local function OnPhaseChanged(src, phase)
    SetVariable("phase", phase)
    SetVariable("isday", phase == "day", "day")
    SetVariable("isdusk", phase == "dusk", "dusk")
    SetVariable("isnight", phase == "night", "night")
end

local function OnMoonPhaseChanged(src, moonphase)
    SetVariable("isfullmoon", moonphase == "full")
end

local function OnSeasonTick(src, data)
    SetVariable("season", data.season)
    SetVariable("issummer", data.season == "summer", "summer")
    SetVariable("iswinter", data.season == "winter", "winter")
    SetVariable("elapseddaysinseason", data.elapseddaysinseason)
    SetVariable("remainingdaysinseason", data.remainingdaysinseason)
end

local function OnSeasonLengthsChanged(src, data)
    SetVariable("summerlength", data.summer)
    SetVariable("winterlength", data.winter)
end

local function OnWeatherTick(src, data)
    SetVariable("temperature", data.temperature)
    SetVariable("moisture", data.moisture)
    SetVariable("pop", data.pop)
    SetVariable("precipitationrate", data.precipitationrate)
    SetVariable("snowlevel", data.snowlevel)
end

local function OnMoistureCeilChanged(src, moistureceil)
    SetVariable("moistureceil", moistureceil)
end

local function OnPrecipitationChanged(src, preciptype)
    SetVariable("precipitation", preciptype)
    SetVariable("israining", preciptype == "rain", "rain")
    SetVariable("issnowing", preciptype == "snow", "snow")
end

local function OnSnowCoveredChanged(src, show)
    if show then
        TheSim:ShowAnimOnEntitiesWithTag("SnowCovered", "snow")
    else
        TheSim:HideAnimOnEntitiesWithTag("SnowCovered", "snow")
    end
    SetVariable("issnowcovered", show)
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------
--[[
    World state variables are initialized to default values that can be
    used by entities if there are no world components controlling those
    variables.  e.g. If there is no season component on the world, then
    everything will run in summer state.
--]]

--Clock
self.data.time = 0
self.data.timeinphase = 0
self.data.cycles = 0
self.data.phase = "day"
self.data.isday = true
self.data.isdusk = false
self.data.isnight = false
self.data.isfullmoon = false

inst:ListenForEvent("clocktick", OnClockTick)
inst:ListenForEvent("cycleschanged", OnCyclesChanged)
inst:ListenForEvent("phasechanged", OnPhaseChanged)
inst:ListenForEvent("moonphasechanged", OnMoonPhaseChanged)

--Season
self.data.season = "summer"
self.data.issummer = true
self.data.iswinter = false
self.data.elapseddaysinseason = 0
self.data.remainingdaysinseason = math.ceil(TUNING.SUMMER_LENGTH * .5)
self.data.summerlength = TUNING.SUMMER_LENGTH
self.data.winterlength = TUNING.WINTER_LENGTH

inst:ListenForEvent("seasontick", OnSeasonTick)
inst:ListenForEvent("seasonlengthschanged", OnSeasonLengthsChanged)

--Weather
self.data.temperature = 30
self.data.moisture = 0
self.data.moistureceil = 8 * TUNING.TOTAL_DAY_TIME
self.data.pop = 0
self.data.precipitationrate = 0
self.data.precipitation = "none"
self.data.israining = false
self.data.issnowing = false
self.data.issnowcovered = false
self.data.snowlevel = 0

inst:ListenForEvent("weathertick", OnWeatherTick)
inst:ListenForEvent("moistureceilchanged", OnMoistureCeilChanged)
inst:ListenForEvent("precipitationchanged", OnPrecipitationChanged)
inst:ListenForEvent("snowcoveredchanged", OnSnowCoveredChanged)

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:AddWatcher(var, inst, fn, target)
    local watchers = _watchers[var]
    if watchers == nil then
        watchers = {}
        _watchers[var] = watchers
    end

    local watcherfns = watchers[inst]
    if watcherfns == nil then
        watcherfns = {}
        watchers[inst] = watcherfns
    end

    table.insert(watcherfns, { fn, target })
end

function self:RemoveWatcher(var, inst, fn, target)
    local watchers = _watchers[var]
    if watchers ~= nil then
        local watcherfns = watchers[inst]
        if watcherfns ~= nil then
            if fn ~= nil then
                for i, v in ipairs(watcherfns) do
                    while fn == v[1] and (target == nil or target == v[2]) do
                        table.remove(watcherfns, i)
                        v = watcherfns[i]
                        if v == nil then
                            break
                        end
                    end
                end

                if next(watcherfns) == nil then
                    watchers[inst] = nil
                end
            else
                watchers[inst] = nil
            end
        end

        if next(watchers) == nil then
            _watchers[var] = nil
        end
    end
end

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    local data = {}
    for k, v in pairs(self.data) do
        data[k] = v
    end

    return data
end

function self:OnLoad(data)
    for k, v in pairs(data) do
        if self.data[k] ~= nil then
            self.data[k] = v
        end
    end
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)