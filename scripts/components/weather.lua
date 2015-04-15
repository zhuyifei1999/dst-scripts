--------------------------------------------------------------------------
--[[ Weather class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

local easing = require("easing")

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local NOISE_SYNC_PERIOD = 30

--------------------------------------------------------------------------
--[[ Temperature constants ]]
--------------------------------------------------------------------------

local TEMPERATURE_NOISE_SCALE = .025
local TEMPERATURE_NOISE_MAG = 8

local MIN_TEMPERATURE = -20
local MAX_TEMPERATURE = 30
local CROSSOVER_TEMPERATURE = 8

local PHASE_TEMPERATURES =
{
    day = 5,
    night = -6,
}

--------------------------------------------------------------------------
--[[ Precipitation constants ]]
--------------------------------------------------------------------------

local PRECIP_MODE_NAMES =
{
    "dynamic",
    "always",
    "never",
}
local PRECIP_MODES = table.invert(PRECIP_MODE_NAMES)

local PRECIP_TYPE_NAMES =
{
    "none",
    "rain",
    "snow",
}
local PRECIP_TYPES = table.invert(PRECIP_TYPE_NAMES)

local PRECIP_RATE_SCALE = 10
local MIN_PRECIP_RATE = .1
local MIN_SUMMER_MOISTURE_RATE = .25
local MAX_SUMMER_MOISTURE_RATE = 1
local MOISTURE_SYNC_PERIOD = 100

local SNOW_ACCUM_RATE = 1 / 300
local SNOW_MELT_RATE = 1 / 20
local MIN_SNOW_MELT_RATE = 1 / 120
local SNOW_LEVEL_SYNC_PERIOD = .1

local MOISTURE_CEIL_MULTIPLIERS =
{
    summer = 2,
    winter = 1,
}

local START_SNOW_THRESHOLDS =
{
    summer = -5,
    winter = 5,
}

local STOP_SNOW_THRESHOLDS =
{
    summer = 0,
    winter = 10,
}

local SNOW_COVERED_THRESHOLD = .015

--------------------------------------------------------------------------
--[[ Lightning constants ]]
--------------------------------------------------------------------------

local LIGHTNING_MODE_NAMES =
{
    "rain",
    "snow",
    "any",
    "always",
    "never",
}
local LIGHTNING_MODES = table.invert(LIGHTNING_MODE_NAMES)

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _world = TheWorld
local _ismastersim = _world.ismastersim

--Temperature
local _seasontemperature
local _phasetemperature

--Precipiation
local _rainsound = false
--Dedicated server does not need to spawn the local fx
local _hasfx = not TheNet:IsDedicated()
local _rainfx = _hasfx and SpawnPrefab("rain") or nil
local _snowfx = _hasfx and SpawnPrefab("snow") or nil

--Light
local _daylight = true
local _winterlight = false

--Master simulation
local _moisturerateval
local _moisturerateoffset
local _moistureratemultiplier
local _moistureceilmultiplier
local _startsnowthreshold
local _stopsnowthreshold
local _lightningmode
local _minlightningdelay
local _maxlightningdelay
local _nextlightningtime
local _lightningtargets

--Network
local _noisetime = net_float(inst.GUID, "weather._noisetime")
local _moisture = net_float(inst.GUID, "weather._moisture")
local _moisturerate = net_float(inst.GUID, "weather._moisturerate")
local _moistureceil = net_float(inst.GUID, "weather._moistureceil", "moistureceildirty")
local _moisturefloor = net_float(inst.GUID, "weather._moisturefloor")
local _precipmode = net_tinybyte(inst.GUID, "weather._precipmode")
local _preciptype = net_tinybyte(inst.GUID, "weather._preciptype", "preciptypedirty")
local _precipintensity = net_float(inst.GUID, "weather._precipintensity")
local _snowlevel = net_float(inst.GUID, "weather._snowlevel")
local _snowcovered = net_bool(inst.GUID, "weather._snowcovered", "snowcovereddirty")

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function SetWithPeriodicSync(netvar, val, period, ismastersim)
    if netvar:value() ~= val then
        local trunc = val > netvar:value() and "floor" or "ceil"
        local prevperiod = math[trunc](netvar:value() / period)
        local nextperiod = math[trunc](val / period)

        if prevperiod == nextperiod then
            --Client and server update independently within current period
            netvar:set_local(val)
        elseif ismastersim then
            --Server sync to client when period changes
            netvar:set(val)
        else
            --Client must wait at end of period for a server sync
            netvar:set_local(nextperiod * period)
        end
    elseif ismastersim then
        --Force sync when value stops changing
        netvar:set(val)
    end
end

local function CalculateSeasonTemperature(season, progress)
    local peaktemp = season == "winter" and MIN_TEMPERATURE or MAX_TEMPERATURE
    return math.sin(PI * progress) * (peaktemp - CROSSOVER_TEMPERATURE) + CROSSOVER_TEMPERATURE
end

local function CalculatePhaseTemperature(phase, timeinphase)
    return PHASE_TEMPERATURES[phase] ~= nil and PHASE_TEMPERATURES[phase] * math.sin(timeinphase * PI) or 0
end

local function CalculateTemperature()
    local temperaturenoise = 2 * TEMPERATURE_NOISE_MAG * perlin(0, 0, _noisetime:value() * TEMPERATURE_NOISE_SCALE) - TEMPERATURE_NOISE_MAG
    return temperaturenoise + _seasontemperature + _phasetemperature
end

local CalculateMoistureRate = _ismastersim and function()
    return _moisturerateval * _moistureratemultiplier + _moisturerateoffset
end or nil

local RandomizeMoistureCeil = _ismastersim and function()
    return (1 + math.random() * 3) * TUNING.TOTAL_DAY_TIME * _moistureceilmultiplier
end or nil

local RandomizeMoistureFloor = _ismastersim and function()
    return (.25 + math.random() * .5) * _moisture:value()
end or nil

local RandomizePeakIntensity = _ismastersim and function()
    return math.random()
end or nil

local function CalculatePrecipitationRate()
    if _precipmode:value() == PRECIP_MODES.always then
        return .1 + perlin(0, _noisetime:value() * .1, 0) * .9
    elseif _preciptype:value() ~= PRECIP_TYPES.none and _precipmode:value() ~= PRECIP_MODES.never then
        local p = math.max(0, math.min(1, (_moisture:value() - _moisturefloor:value()) / (_moistureceil:value() - _moisturefloor:value())))
        return MIN_PRECIP_RATE + (1 - MIN_PRECIP_RATE) * math.sin(p * PI)
    end
    return 0
end

local StartPrecipitation = _ismastersim and function(temperature)
    _nextlightningtime = GetRandomMinMax(_minlightningdelay or 5, _maxlightningdelay or 15)
    _moisture:set(_moistureceil:value())
    _moisturefloor:set(RandomizeMoistureFloor())
    _precipintensity:set(RandomizePeakIntensity())
    _preciptype:set(temperature < _startsnowthreshold and PRECIP_TYPES.snow or PRECIP_TYPES.rain)
end or nil

local StopPrecipitation = _ismastersim and function()
    _moisture:set(_moisturefloor:value())
    _moistureceil:set(RandomizeMoistureCeil())
    _preciptype:set(PRECIP_TYPES.none)
end or nil

local function CalculatePOP()
    if _preciptype:value() ~= PRECIP_TYPES.none then
        return 1
    elseif _moistureceil:value() <= 0 or _moisture:value() <= _moisturefloor:value() then
        return 0
    elseif _moisture:value() < _moistureceil:value() then
        return (_moisture:value() - _moisturefloor:value()) / (_moistureceil:value() - _moisturefloor:value())
    end
    return 1
end

local function CalculateLight(temperature)
    if _precipmode:value() == PRECIP_MODES.never then
        return 1
    end
    local snowlight = _preciptype:value() == PRECIP_TYPES.snow or (_winterlight and _preciptype:value() == PRECIP_TYPES.none)
    local dynrange = snowlight and (_daylight and .05 or 0) or (_daylight and .4 or .25)
    if _precipmode:value() == PRECIP_MODES.always then
        return 1 - dynrange
    end
    local p = 1 - math.min(math.max((_moisture:value() - _moisturefloor:value()) / (_moistureceil:value() - _moisturefloor:value()), 0), 1)
    if _preciptype:value() ~= PRECIP_TYPES.none then
        p = easing.inQuad(p, 0, 1, 1)
    end
    return p * dynrange + 1 - dynrange
end

local function PushWeather(temperature, preciprate)
    temperature = temperature or CalculateTemperature()
    local data =
    {
        temperature = temperature,
        moisture = _moisture:value(),
        pop = CalculatePOP(),
        precipitationrate = preciprate or CalculatePrecipitationRate(),
        snowlevel = _snowlevel:value(),
        light = CalculateLight(temperature),
    }
    _world:PushEvent("weathertick", data)
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnSeasonTick(src, data)
    -- this is a little hacky but it guarantees that the season temp is artificially pushed closer to its extreme the first few days that the world exists
    -- this has the effect of preventing cold summer starts and hot winter starts
    if TheWorld.state.cycles <= 3 then 
        _seasontemperature = CalculateSeasonTemperature(data.season, math.max(data.progress, .4))
    else
        _seasontemperature = CalculateSeasonTemperature(data.season, data.progress)
    end
    _winterlight = data.season == "winter"

    if _ismastersim then
        if data.season == "summer" then
            --It rains less in the middle of summer
            local p = 1 - math.sin(PI * data.progress)
            _moisturerateval = MIN_SUMMER_MOISTURE_RATE + data.progress * (MAX_SUMMER_MOISTURE_RATE - MIN_SUMMER_MOISTURE_RATE)
            _moisturerateoffset = 0
        elseif data.season == "winter" and data.elapseddaysinseason == 2 then
            --We really want it to snow in early winter, so that we can get an initial ground cover
            _moisturerateval = 0
            _moisturerateoffset = 50
        else
            _moisturerateval = 1
            _moisturerateoffset = 0
        end

        _moisturerate:set(CalculateMoistureRate())
        _moistureceilmultiplier = MOISTURE_CEIL_MULTIPLIERS[data.season] or MOISTURE_CEIL_MULTIPLIERS.summer
        _startsnowthreshold = START_SNOW_THRESHOLDS[data.season] or START_SNOW_THRESHOLDS.summer
        _stopsnowthreshold = STOP_SNOW_THRESHOLDS[data.season] or STOP_SNOW_THRESHOLDS.summer
    end
end

local function OnClockTick(src, data)
    _phasetemperature = CalculatePhaseTemperature(data.phase, data.timeinphase)
end

local function OnPhaseChanged(src, phase)
    _daylight = phase == "day"
end

local OnPlayerActivated = _hasfx and function(src, player)
    _rainfx.entity:SetParent(player.entity)
    _snowfx.entity:SetParent(player.entity)
    self:OnPostInit()
end or nil

local OnPlayerDeactivated = _hasfx and function(src, player)
    _rainfx.entity:SetParent(nil)
    _snowfx.entity:SetParent(nil)
end or nil

local OnPlayerJoined = _ismastersim and function(src, player)
    for i, v in ipairs(_lightningtargets) do
        if v == player then
            return
        end
    end

    if player ~= nil then
        table.insert(_lightningtargets, player)
    end
end or nil

local OnPlayerLeft = _ismastersim and function(src, player)
    for i, v in ipairs(_lightningtargets) do
        if v == player then
            table.remove(_lightningtargets, i)
            return
        end
    end
end or nil

local OnForcePrecipitation = _ismastersim and function(src, enable)
    _moisture:set(enable ~= false and _moistureceil:value() or _moisturefloor:value())
end or nil

local OnSetPrecipitationMode = _ismastersim and function(src, mode)
    _precipmode:set(PRECIP_MODES[mode] or _precipmode:value())
end or nil

local OnSetMoistureScale = _ismastersim and function(src, data)
    _moistureratemultiplier = data or _moistureratemultiplier
    _moisturerate:set(CalculateMoistureRate())
end or nil

local OnDeltaMoisture = _ismastersim and function(src, delta)
    _moisture:set(math.min(math.max(_moisture:value() + delta, _moisturefloor:value()), _moistureceil:value()))
end or nil

local OnDeltaMoistureCeil = _ismastersim and function(src, delta)
    _moistureceil:set(math.max(_moistureceil:value() + delta, _moisturefloor:value()))
end or nil

local OnSetSnowLevel = _ismastersim and function(src, level)
    _snowlevel:set(level or _snowlevel:value())
end or nil

local OnSetLightningMode = _ismastersim and function(src, mode)
    _lightningmode = LIGHTNING_MODES[mode] or _lightningmode
end or nil

local OnSetLightningDelay = _ismastersim and function(src, data)
    if _preciptype:value() ~= PRECIP_TYPES.none and data.min and data.max then
        _nextlightningtime = GetRandomMinMax(data.min, data.max)
    end
    _minlightningdelay = data.min
    _maxlightningdelay = data.max
end or nil

local OnSendLightningStrike = _ismastersim and function(src, pos)
    local target = nil
    local isrod = false
    local mindistsq = nil
    local pos0 = pos

    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 40, nil, nil, { "lightningrod", "lightningtarget" })
    for k, v in pairs(ents) do
        local visrod = v:HasTag("lightningrod")
        local vpos = v:GetPosition()
        local vdistsq = distsq(pos0.x, pos0.z, vpos.x, vpos.z)
        if target == nil or
            (visrod and not isrod) or
            (visrod == isrod and vdistsq < mindistsq) then
            target = v
            isrod = visrod
            pos = vpos
            mindistsq = vdistsq
        end
    end

    if isrod then
        target:PushEvent("lightningstrike")
    else
        if target ~= nil and target.components.playerlightningtarget and target.components.playerlightningtarget:CanBeHit() then
            target:PushEvent("lightningstrike")
        end

        ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 3)
        for k, v in pairs(ents) do
            if not v:IsInLimbo() and v.components.burnable and not v.components.fueled and not v:HasTag("nofiredamagefromlightning") then
                v.components.burnable:Ignite()
            end
        end
    end

    local lightning = SpawnPrefab("lightning")
    lightning.Transform:SetPosition(pos:Get())
end or nil

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

_seasontemperature = CalculateSeasonTemperature("summer", .5)
_phasetemperature = CalculatePhaseTemperature("day", 0)

--Initialize network variables
_noisetime:set(0)
_moisture:set(0)
_moisturerate:set(0)
_moistureceil:set(0)
_moisturefloor:set(0)
_precipmode:set(PRECIP_MODES.dynamic)
_preciptype:set(PRECIP_TYPES.none)
_precipintensity:set(1)
_snowlevel:set(0)

--Dedicated server does not need to spawn the local fx
if _hasfx then
    --Initialize rain particles
    _rainfx.particles_per_tick = 0
    _rainfx.splashes_per_tick = 0

    --Initialize snow particles
    _snowfx.particles_per_tick = 0
end

--Register network variable sync events
inst:ListenForEvent("moistureceildirty", function() _world:PushEvent("moistureceilchanged", _moistureceil:value()) end)
inst:ListenForEvent("preciptypedirty", function() _world:PushEvent("precipitationchanged", PRECIP_TYPE_NAMES[_preciptype:value()]) end)
inst:ListenForEvent("snowcovereddirty", function() _world:PushEvent("snowcoveredchanged", _snowcovered:value()) end)

--Register events
inst:ListenForEvent("seasontick", OnSeasonTick, _world)
inst:ListenForEvent("clocktick", OnClockTick, _world)
inst:ListenForEvent("phasechanged", OnPhaseChanged, _world)

if _hasfx then
    inst:ListenForEvent("playeractivated", OnPlayerActivated, _world)
    inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated, _world)
end

if _ismastersim then
    --Initialize master simulation variables
    _moisturerateval = 1
    _moisturerateoffset = 0
    _moistureratemultiplier = 1
    _moistureceilmultiplier = 1
    _startsnowthreshold = START_SNOW_THRESHOLDS.summer
    _stopsnowthreshold = STOP_SNOW_THRESHOLDS.summer
    _lightningmode = LIGHTNING_MODES.rain
    _minlightningdelay = nil
    _maxlightningdelay = nil
    _nextlightningtime = 5
    _lightningtargets = {}

    for i, v in ipairs(AllPlayers) do
        table.insert(_lightningtargets, v)
    end

    _moisturerate:set(CalculateMoistureRate())
    _moistureceil:set(RandomizeMoistureCeil())

    --Register master simulation events
    inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, _world)
    inst:ListenForEvent("ms_playerleft", OnPlayerLeft, _world)
    inst:ListenForEvent("ms_forceprecipitation", OnForcePrecipitation, _world)
    inst:ListenForEvent("ms_setprecipitationmode", OnSetPrecipitationMode, _world)
    inst:ListenForEvent("ms_setmoisturescale", OnSetMoistureScale, _world)
    inst:ListenForEvent("ms_deltamoisture", OnDeltaMoisture, _world)
    inst:ListenForEvent("ms_deltamoistureceil", OnDeltaMoistureCeil, _world)
    inst:ListenForEvent("ms_setsnowlevel", OnSetSnowLevel, _world)
    inst:ListenForEvent("ms_setlightningmode", OnSetLightningMode, _world)
    inst:ListenForEvent("ms_setlightningdelay", OnSetLightningDelay, _world)
    inst:ListenForEvent("ms_sendlightningstrike", OnSendLightningStrike, _world)
end

PushWeather()
inst:StartUpdatingComponent(self)

--------------------------------------------------------------------------
--[[ Post initialization ]]
--------------------------------------------------------------------------

if _hasfx then function self:OnPostInit()
    if _preciptype:value() == PRECIP_TYPES.rain then
        _rainfx:PostInit()
    elseif _preciptype:value() == PRECIP_TYPES.snow then
        _snowfx:PostInit()
    end
end end

--------------------------------------------------------------------------
--[[ Deinitialization ]]
--------------------------------------------------------------------------

if _hasfx then function self:OnRemoveEntity()
    if _rainfx.entity:IsValid() then
        _rainfx:Remove()
    end
    if _snowfx.entity:IsValid() then
        _snowfx:Remove()
    end
end end

--------------------------------------------------------------------------
--[[ Update ]]
--------------------------------------------------------------------------

--[[
    Client updates temperature, moisture, precipitation effects, and snow
    level on its own while server force syncs values periodically. Client
    cannot start, stop, or change precipitation on its own, and must wait
    for server syncs to trigger these events.
--]]
function self:OnUpdate(dt)
    --Update noise
    SetWithPeriodicSync(_noisetime, _noisetime:value() + dt, NOISE_SYNC_PERIOD, _ismastersim)

    local temperature = CalculateTemperature()
    local preciprate = CalculatePrecipitationRate()

    --Update moisture and toggle precipitation
    if _precipmode:value() == PRECIP_MODES.always then
        if _ismastersim and _preciptype:value() == PRECIP_TYPES.none then
            StartPrecipitation(temperature)
        end
    elseif _precipmode:value() == PRECIP_MODES.never then
        if _ismastersim and _preciptype:value() ~= PRECIP_TYPES.none then
            StopPrecipitation()
        end
    elseif _preciptype:value() ~= PRECIP_TYPES.none then
        --Dissipate moisture
        local moisture = math.max(_moisture:value() - preciprate * dt * PRECIP_RATE_SCALE, 0)
        if moisture <= _moisturefloor:value() then
            if _ismastersim then
                StopPrecipitation()
            else
                _moisture:set_local(math.min(_moisturefloor:value() + .001, _moisture:value()))
            end
        else
            SetWithPeriodicSync(_moisture, moisture, MOISTURE_SYNC_PERIOD, _ismastersim)
        end
    elseif _moistureceil:value() > 0 then
        --Accumulate moisture
        local moisture = _moisture:value() + _moisturerate:value() * dt
        if moisture >= _moistureceil:value() then
            if _ismastersim then
                StartPrecipitation(temperature)
            else
                _moisture:set_local(math.max(_moistureceil:value() - .001, _moisture:value()))
            end
        else
            SetWithPeriodicSync(_moisture, moisture, MOISTURE_SYNC_PERIOD, _ismastersim)
        end
    end

    --Update precipitation effects
    if _preciptype:value() == PRECIP_TYPES.rain then
        if not _rainsound then
            _rainsound = true
            _world.SoundEmitter:PlaySound("dontstarve/rain/rainAMB", "rain")
        end
        _world.SoundEmitter:SetParameter("rain", "intensity", preciprate)
        if _hasfx then
            _rainfx.particles_per_tick = (5 + _precipintensity:value() * 25) * preciprate
            _rainfx.splashes_per_tick = 1 + 2 * _precipintensity:value() * preciprate
            _snowfx.particles_per_tick = 0
        end
    else
        if _rainsound then
            _rainsound = false
            _world.SoundEmitter:KillSound("rain")
        end
        if _hasfx then
            if _preciptype:value() == PRECIP_TYPES.snow then
                _snowfx.particles_per_tick = 20 * preciprate
                _rainfx.particles_per_tick = 0
                _rainfx.splashes_per_tick = 0
            else
                _snowfx.particles_per_tick = 0
                _rainfx.particles_per_tick = 0
                _rainfx.splashes_per_tick = 0
            end
        end
    end

    --Update ground snow level
    local snowlevel = _snowlevel:value()
    if _preciptype:value() == PRECIP_TYPES.snow then
        --Accumulate snow
        snowlevel = math.min(snowlevel + preciprate * dt * SNOW_ACCUM_RATE, 1)
    elseif snowlevel > 0 and temperature > 0 then
        --Melt snow
        local meltrate = MIN_SNOW_MELT_RATE + SNOW_MELT_RATE * math.min(temperature / 20, 1)
        snowlevel = math.max(snowlevel - meltrate * dt, 0)
    end
    SetWithPeriodicSync(_snowlevel, snowlevel, SNOW_LEVEL_SYNC_PERIOD, _ismastersim)
    _world.Map:SetOverlayLerp(_snowlevel:value() * 3)

    if _ismastersim then
        --Update entity snow cover
        _snowcovered:set(_snowlevel:value() >= SNOW_COVERED_THRESHOLD)

        --Switch precipitation type based on temperature
        if temperature < _startsnowthreshold and _preciptype:value() == PRECIP_TYPES.rain then
            _preciptype:set(PRECIP_TYPES.snow)
        elseif temperature > _stopsnowthreshold and _preciptype:value() == PRECIP_TYPES.snow then
            _preciptype:set(PRECIP_TYPES.rain)
        end

        --Update lightning
        if _lightningmode == LIGHTNING_MODES.always or
            LIGHTNING_MODE_NAMES[_lightningmode] == PRECIP_TYPE_NAMES[_preciptype:value()] or
            (_lightningmode == LIGHTNING_MODES.any and _preciptype:value() ~= PRECIP_TYPES.none) then
            if _nextlightningtime > dt then
                _nextlightningtime = _nextlightningtime - dt
            else
                local min = _minlightningdelay or easing.linear(preciprate, 30, 10, 1)
                local max = _maxlightningdelay or (min + easing.linear(preciprate, 30, 10, 1))
                _nextlightningtime = GetRandomMinMax(min, max)
                if (preciprate > .75 or _lightningmode == LIGHTNING_MODES.always) and next(_lightningtargets) ~= nil then
                    local targeti = math.min(math.floor(easing.inQuint(math.random(), 1, #_lightningtargets, 1)), #_lightningtargets)
                    local target = _lightningtargets[targeti]
                    table.remove(_lightningtargets, targeti)
                    table.insert(_lightningtargets, target)

                    local x, y, z = target.Transform:GetWorldPosition()
                    local radius = 2 + math.random() * 8
                    local theta = math.random() * 2 * PI
                    local pos = Vector3(x + radius * math.cos(theta), y, z + radius * math.sin(theta))
                    _world:PushEvent("ms_sendlightningstrike", pos)
                else
                    SpawnPrefab(preciprate > .5 and "thunder_close" or "thunder_far")
                end
            end
        end
    end

    PushWeather(temperature, preciprate)
end

self.LongUpdate = self.OnUpdate

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

if _ismastersim then function self:OnSave()
    return
    {
        seasontemperature = _seasontemperature,
        phasetemperature = _phasetemperature,
        noisetime = _noisetime:value(),
        moisturerateval = _moisturerateval,
        moisturerateoffset = _moisturerateoffset,
        moistureratemultiplier = _moistureratemultiplier,
        moisturerate = _moisturerate:value(),
        moisture = _moisture:value(),
        moisturefloor = _moisturefloor:value(),
        moistureceilmultiplier = _moistureceilmultiplier,
        moistureceil = _moistureceil:value(),
        precipmode = PRECIP_MODE_NAMES[_precipmode:value()],
        preciptype = PRECIP_TYPE_NAMES[_preciptype:value()],
        precipintensity = _precipintensity:value(),
        snowlevel = _snowlevel:value(),
        snowcovered = _snowcovered:value(),
        startsnowthreshold = _startsnowthreshold,
        stopsnowthreshold = _stopsnowthreshold,
        lightningmode = LIGHTNING_MODE_NAMES[_lightningmode],
        minlightningdelay = _minlightningdelay,
        maxlightningdelay = _maxlightningdelay,
        nextlightningtime = _nextlightningtime,
        daylight = _daylight,
        winterlight = _winterlight,
    }
end end

if _ismastersim then function self:OnLoad(data)
    _seasontemperature = data.seasontemperature or CalculateSeasonTemperature("summer", .5)
    _phasetemperature = data.phasetemperature or CalculatePhaseTemperature("day", 0)
    _noisetime:set(data.noisetime or 0)
    _moisturerateval = data.moisturerateval or 1
    _moisturerateoffset = data.moisturerateoffset or 0
    _moistureratemultiplier = data.moistureratemultiplier or 1
    _moisturerate:set(data.moisturerate or CalculateMoistureRate())
    _moisture:set(data.moisture or 0)
    _moisturefloor:set(data.moisturefloor or 0)
    _moistureceilmultiplier = data.moistureceilmultiplier or 1
    _moistureceil:set(data.moistureceil or RandomizeMoistureCeil())
    _precipmode:set(PRECIP_MODES[data.precipmode] or PRECIP_MODES.dynamic)
    _preciptype:set(PRECIP_TYPES[data.preciptype] or PRECIP_TYPES.none)
    _precipintensity:set(data.precipintensity or 1)
    _snowlevel:set(data.snowlevel or 0)
    _snowcovered:set(data.snowcovered == true)
    _startsnowthreshold = data.startsnowthreshold or START_SNOW_THRESHOLDS.summer
    _stopsnowthreshold = data.stopsnowthreshold or STOP_SNOW_THRESHOLDS.summer
    _lightningmode = LIGHTNING_MODES[data.lightningmode] or LIGHTNING_MODES.rain
    _minlightningdelay = data.minlightningdelay
    _maxlightningdelay = data.maxlightningdelay
    _nextlightningtime = data.nextlightningtime or 5
    _daylight = data.daylight ~= false
    _winterlight = data.winterlight == true

    PushWeather()
end end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    local str =
    {
        string.format("%2.2fC", CalculateTemperature()),
        string.format("moisture:%2.2f(%2.2f/%2.2f)", _moisture:value(), _moisturefloor:value(), _moistureceil:value()),
        string.format("preciprate:%2.2f/%2.2f", CalculatePrecipitationRate(), _precipintensity:value()),
        string.format("snowlevel:%2.2f", _snowlevel:value()),
    }

    if _ismastersim then
        table.insert(str, string.format("lightning:%2.2f", _nextlightningtime))
    end
    
    return table.concat(str, ", ")
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)