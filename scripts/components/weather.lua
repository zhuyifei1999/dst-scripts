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

local MIN_TEMPERATURE = -25
local MAX_TEMPERATURE = 95 
local WINTER_CROSSOVER_TEMPERATURE = 5
local SUMMER_CROSSOVER_TEMPERATURE = 55

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
local MOISTURE_RATES = {
    MIN = {
        autumn = .25,
        winter = .25,
        spring = 3,
        summer = .1,
    },
    MAX = {
        autumn = 1.0,
        winter = 1.0,
        spring = 3.75,
        summer = .5,
    }
}
local MOISTURE_SYNC_PERIOD = 100

local SNOW_ACCUM_RATE = 1 / 300
local SNOW_MELT_RATE = 1 / 20
local MIN_SNOW_MELT_RATE = 1 / 120
local SNOW_LEVEL_SYNC_PERIOD = .1

local MOISTURE_CEIL_MULTIPLIERS =
{
    autumn = 8,
    winter = 3,
    spring = 5.5,
    summer = 13,
}

local MOISTURE_FLOOR_MULTIPLIERS =
{
    autumn = 1,
    winter = 1,
    spring = 0.25,
    summer = 1.5,
}

local START_SNOW_THRESHOLDS =
{
    autumn = -5,
    winter = 5,
    spring = -5,
    summer = -5,
}

local STOP_SNOW_THRESHOLDS =
{
    autumn = 0,
    winter = 10,
    spring = 0,
    summer = 0,
}

local GROUND_OVERLAYS =
{
    snow =
    {
        texture = "levels/textures/snow.tex",
        colour =
        {
            { 1, 1, 1, 1 },
            { 1, 1, 1, 1 },
            { 1, 1, 1, 1 },
        },
    },
    puddles =
    {
        texture = "levels/textures/mud.tex",
        colour =
        {
            { 11 / 255, 15 / 255, 23 / 255, .3 },
            { 11 / 255, 15 / 255, 23 / 255, .2 },
            { 11 / 255, 15 / 255, 23 / 255, .12 },
        },
    },
}

local POLLEN_PARTICLES = .5

local SNOW_COVERED_THRESHOLD = .015

local PEAK_PRECIPITATION_RANGES =
{
    autumn = { min = .10, max = .66 },
    winter = { min = .10, max = .80 },
    spring = { min = .50, max = 1.00 },
    summer = { min = 1.0, max = 1.0 },
}

--------------------------------------------------------------------------
--[[ Wetness constants ]]
--------------------------------------------------------------------------

local DRY_THRESHOLD = TUNING.MOISTURE_DRY_THRESHOLD
local WET_THRESHOLD = TUNING.MOISTURE_WET_THRESHOLD
local MIN_WETNESS = 0
local MAX_WETNESS = 100
local MIN_WETNESS_RATE = 0
local MAX_WETNESS_RATE = .75
local MIN_DRYING_RATE = 0
local MAX_DRYING_RATE = .3
local OPTIMAL_DRYING_TEMPERATURE = 70
local WETNESS_SYNC_PERIOD = 10

--------------------------------------------------------------------------
--[[ Lightning (not LightING) constants ]]
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
--[[ Lighting (not LightNING) constants ]]
--------------------------------------------------------------------------

local SUMMER_BLOOM_BASE = 0.15   -- base amount of bloom applied during the day
local SUMMER_BLOOM_TEMP_MODIFIER = 0.10 / TUNING.DAY_HEAT   -- amount that the daily temp. variation factors into the overall bloom
local SUMMER_BLOOM_PERIOD_MIN = 5 -- min length of the bloom fluctuation period
local SUMMER_BLOOM_PERIOD_MAX = 10 -- max length of the bloom fluctuation period

local SEASON_DYNRANGE_DAY = {
    autumn = .4,
    winter = .05,
    spring = .4,
    summer = .7,
}

local SEASON_DYNRANGE_NIGHT = {
    autumn = .25,
    winter = 0,
    spring = .25,
    summer = .5,
}

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _world = TheWorld
local _map = _world.Map
local _ismastersim = _world.ismastersim
local _activatedplayer = nil

--Temperature
local _seasontemperature
local _phasetemperature

--Precipiation
local _rainsound = false
local _treerainsound = nil
local _umbrellarainsound = false
local _seasonprogress = 0
local _groundoverlay = nil

--Dedicated server does not need to spawn the local fx
local _hasfx = not TheNet:IsDedicated()
local _rainfx = _hasfx and SpawnPrefab("rain") or nil
local _snowfx = _hasfx and SpawnPrefab("snow") or nil
local _pollenfx = _hasfx and SpawnPrefab("pollen") or nil

--Light
local _daylight = true
local _season = "autumn"

local _summerblooming = false
local _summerbloom_modifier = 0
local _summerbloom_current_time = 0
local _summerbloom_time_to_new_modifier = 0
local _summerbloom_ramp = 0
local _summerbloom_ramp_time = 5

--Master simulation
local _moisturerateval
local _moisturerateoffset
local _moistureratemultiplier
local _moistureceilmultiplier
local _moisturefloormultiplier
local _startsnowthreshold
local _stopsnowthreshold
local _lightningmode
local _minlightningdelay
local _maxlightningdelay
local _nextlightningtime
local _lightningtargets
local _lightningexcludetags

--Network
local _noisetime = net_float(inst.GUID, "weather._noisetime")
local _moisture = net_float(inst.GUID, "weather._moisture")
local _moisturerate = net_float(inst.GUID, "weather._moisturerate")
local _moistureceil = net_float(inst.GUID, "weather._moistureceil", "moistureceildirty")
local _moisturefloor = net_float(inst.GUID, "weather._moisturefloor")
local _precipmode = net_tinybyte(inst.GUID, "weather._precipmode")
local _preciptype = net_tinybyte(inst.GUID, "weather._preciptype", "preciptypedirty")
local _peakprecipitationrate = net_float(inst.GUID, "weather._peakprecipitationrate")
local _snowlevel = net_float(inst.GUID, "weather._snowlevel")
local _snowcovered = net_bool(inst.GUID, "weather._snowcovered", "snowcovereddirty")
local _wetness = net_float(inst.GUID, "weather._wetness")
local _wet = net_bool(inst.GUID, "weather._wet", "wetdirty")

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function StartAmbientRainSound(intensity)
    if not _rainsound then
        _rainsound = true
        _world.SoundEmitter:PlaySound("dontstarve/rain/rainAMB", "rain")
    end
    _world.SoundEmitter:SetParameter("rain", "intensity", intensity)
end

local function StopAmbientRainSound()
    if _rainsound then
        _rainsound = false
        _world.SoundEmitter:KillSound("rain")
    end
end

--V2C: hack to loop the tree rain sound without having to change the sound data :O
local function DoTreeRainSound(inst, soundemitter)
    --Intentionally (lazy) not caring if we kill a sound that isn't still playing.
    --Log spams should also be disabled for that.
    soundemitter:KillSound("treerainsound")
    soundemitter:PlaySound("dontstarve_DLC001/common/rain_on_tree", "treerainsound")
end

local function StartTreeRainSound()
    if _treerainsound == nil then
        _treerainsound = inst:DoPeriodicTask(19, DoTreeRainSound, 0, TheFocalPoint.SoundEmitter)
    end
end

local function StopTreeRainSound()
    if _treerainsound ~= nil then
        _treerainsound:Cancel()
        _treerainsound = nil
        TheFocalPoint.SoundEmitter:KillSound("treerainsound")
    end
end

local function StartUmbrellaRainSound()
    if not _umbrellarainsound then
        _umbrellarainsound = true
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve/rain/rain_on_umbrella", "umbrellarainsound")
    end
end

local function StopUmbrellaRainSound()
    if _umbrellarainsound then
        _umbrellarainsound = false
        TheFocalPoint.SoundEmitter:KillSound("umbrellarainsound")
    end
end

local function SetGroundOverlay(overlay, level)
    if _groundoverlay ~= overlay then
        _groundoverlay = overlay
        _map:SetOverlayTexture(overlay.texture)
        _map:SetOverlayColor0(unpack(overlay.colour[1]))
        _map:SetOverlayColor1(unpack(overlay.colour[2]))
        _map:SetOverlayColor2(unpack(overlay.colour[3]))
    end
    _map:SetOverlayLerp(level)
end

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
    return (season == "winter" and math.sin(PI * progress) * (MIN_TEMPERATURE - WINTER_CROSSOVER_TEMPERATURE) + WINTER_CROSSOVER_TEMPERATURE)
        or (season == "spring" and Lerp(WINTER_CROSSOVER_TEMPERATURE, SUMMER_CROSSOVER_TEMPERATURE, progress))
        or (season == "summer" and math.sin(PI * progress) * (MAX_TEMPERATURE - SUMMER_CROSSOVER_TEMPERATURE) + SUMMER_CROSSOVER_TEMPERATURE)
        or Lerp(SUMMER_CROSSOVER_TEMPERATURE, WINTER_CROSSOVER_TEMPERATURE, progress)
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
    return (1 + math.random()) * TUNING.TOTAL_DAY_TIME * _moistureceilmultiplier
end or nil

local RandomizeMoistureFloor = _ismastersim and function(season)
    return (.25 + math.random() * .5) * _moisture:value() * _moisturefloormultiplier
end or nil

local RandomizePeakPrecipitationRate = _ismastersim and function(season)
    local range = PEAK_PRECIPITATION_RANGES[season]
    return range.min + math.random() * (range.max-range.min)
end or nil

local function CalculatePrecipitationRate()
    if _precipmode:value() == PRECIP_MODES.always then
        return .1 + perlin(0, _noisetime:value() * .1, 0) * .9
    elseif _preciptype:value() ~= PRECIP_TYPES.none and _precipmode:value() ~= PRECIP_MODES.never then
        local p = math.max(0, math.min(1, (_moisture:value() - _moisturefloor:value()) / (_moistureceil:value() - _moisturefloor:value())))
        local rate = MIN_PRECIP_RATE + (1 - MIN_PRECIP_RATE) * math.sin(p * PI)
        return math.min(rate, _peakprecipitationrate:value())
    end
    return 0
end

local StartPrecipitation = _ismastersim and function(temperature)
    _nextlightningtime = GetRandomMinMax(_minlightningdelay or 5, _maxlightningdelay or 15)
    _moisture:set(_moistureceil:value())
    _moisturefloor:set(RandomizeMoistureFloor(_season))
    _peakprecipitationrate:set(RandomizePeakPrecipitationRate(_season))
    _preciptype:set(temperature < _startsnowthreshold and PRECIP_TYPES.snow or PRECIP_TYPES.rain)
end or nil

local StopPrecipitation = _ismastersim and function()
    _moisture:set(_moisturefloor:value())
    _moistureceil:set(RandomizeMoistureCeil())
    _preciptype:set(PRECIP_TYPES.none)
end or nil

local function CalculatePOP()
    return (_preciptype:value() ~= PRECIP_TYPES.none and 1)
        or ((_moistureceil:value() <= 0 or _moisture:value() <= _moisturefloor:value()) and 0)
        or (_moisture:value() < _moistureceil:value() and (_moisture:value() - _moisturefloor:value()) / (_moistureceil:value() - _moisturefloor:value()))
        or 1
end

local function CalculateLight(temperature)
    if _precipmode:value() == PRECIP_MODES.never then
        return 1
    end
    local snowlight = _preciptype:value() == PRECIP_TYPES.snow
    local dynrange = snowlight and (_daylight and SEASON_DYNRANGE_DAY["winter"] or SEASON_DYNRANGE_NIGHT["winter"])
                                or (_daylight and SEASON_DYNRANGE_DAY[_season] or SEASON_DYNRANGE_NIGHT[_season])

    if _precipmode:value() == PRECIP_MODES.always then
        return 1 - dynrange
    end
    local p = 1 - math.min(math.max((_moisture:value() - _moisturefloor:value()) / (_moistureceil:value() - _moisturefloor:value()), 0), 1)
    if _preciptype:value() ~= PRECIP_TYPES.none then
        p = easing.inQuad(p, 0, 1, 1)
    end
    return p * dynrange + 1 - dynrange
end

local function CalculateSummerBloom(dt)
    -- Update summer blooming
    if _daylight and _season == "summer" then
        _summerblooming = true
        _summerbloom_ramp = math.min(_summerbloom_ramp + dt / _summerbloom_ramp_time, 1)
    elseif _summerblooming then
        -- turn off the bloom out of summer
        _summerbloom_ramp = math.max(_summerbloom_ramp - dt / _summerbloom_ramp_time, 0)
        -- print("Killing off the summer bloom",_season,_daylight and "day" or "night",_summerbloom_ramp)
    else
        return
    end

    _summerbloom_current_time = _summerbloom_current_time + dt

    if _summerbloom_ramp <= 0 then
        _summerblooming = false
        _summerbloom_modifier = 0
        _summerbloom_time_to_new_modifier = 0
        _summerbloom_current_time = 0
        -- print("Turning off the summer bloom")
        return
    end

    if _summerbloom_time_to_new_modifier <= _summerbloom_current_time then
        -- start up the next throb
        local new_period = math.random(SUMMER_BLOOM_PERIOD_MIN, SUMMER_BLOOM_PERIOD_MAX)
        _summerbloom_modifier = 2 * PI / new_period
        _summerbloom_time_to_new_modifier = new_period
        _summerbloom_current_time = 0
        -- print("New Summer bloom phase",_summerbloom_time_to_new_modifier)
    end
    -- This is essentially a sine wave [sin(x - pi/2) = 1 - cos(x)] with amplitude 0 - 1, shifted to the left so that the magnitude is zero at time zero
    -- The result is multiplied to a combination of a base intensity value and a time-of-day temperature dependant value
    -- Finally we add this to the original intensity (1.0) so that we're always increasing the total intensity
    return 1 + _summerbloom_ramp * (1 - .5 * math.cos(_summerbloom_current_time * _summerbloom_modifier)) * (SUMMER_BLOOM_BASE + SUMMER_BLOOM_TEMP_MODIFIER * _phasetemperature)
end

local function UpdateSummerBloom(dt)
    local bloomval = CalculateSummerBloom(dt)
    _world:PushEvent("overridecolourmodifier", bloomval)
end

local function CalculateWetnessRate(temperature, preciprate)
    return --Positive wetness rate when it's raining
        (_preciptype:value() == PRECIP_TYPES.rain and easing.inSine(preciprate, MIN_WETNESS_RATE, MAX_WETNESS_RATE, 1))
        --Negative drying rate when it's not raining
        or (temperature < 0 and _season == "winter" and -1)
        or -math.clamp(easing.linear(temperature, MIN_DRYING_RATE, MAX_DRYING_RATE, OPTIMAL_DRYING_TEMPERATURE)
                    + easing.inExpo(_wetness:value(), 0, 1, MAX_WETNESS),
                    .01, 1)
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
        wetness = _wetness:value(),
        light = CalculateLight(temperature),
    }
    _world:PushEvent("weathertick", data)
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnSeasonTick(src, data)
    _seasontemperature = CalculateSeasonTemperature(data.season, data.progress)
    _season = data.season
    _seasonprogress = data.progress

    if _ismastersim then
        if data.season == "winter" and data.elapseddaysinseason == 2 then
            --We really want it to snow in early winter, so that we can get an initial ground cover
            _moisturerateval = 0
            _moisturerateoffset = 50
        else
            --It rains less in the middle of summer
            local p = 1 - math.sin(PI * data.progress)
            _moisturerateval = MOISTURE_RATES.MIN[_season] + p * (MOISTURE_RATES.MAX[_season] - MOISTURE_RATES.MIN[_season])
            _moisturerateoffset = 0
        end

        _moisturerate:set(CalculateMoistureRate())
        _moistureceilmultiplier = MOISTURE_CEIL_MULTIPLIERS[_season] or MOISTURE_CEIL_MULTIPLIERS.autumn
        _moisturefloormultiplier = MOISTURE_FLOOR_MULTIPLIERS[_season] or MOISTURE_FLOOR_MULTIPLIERS.autumn
        _startsnowthreshold = START_SNOW_THRESHOLDS[_season] or START_SNOW_THRESHOLDS.autumn
        _stopsnowthreshold = STOP_SNOW_THRESHOLDS[_season] or STOP_SNOW_THRESHOLDS.autumn
    end
end

local function OnClockTick(src, data)
    _phasetemperature = CalculatePhaseTemperature(data.phase, data.timeinphase)
end

local function OnPhaseChanged(src, phase)
    _daylight = phase == "day"
end

local function OnPlayerActivated(src, player)
    _activatedplayer = player
    if _hasfx then
        _rainfx.entity:SetParent(player.entity)
        _snowfx.entity:SetParent(player.entity)
        _pollenfx.entity:SetParent(player.entity)
        self:OnPostInit()
    end
end

local function OnPlayerDeactivated(src, player)
    if _activatedplayer == player then
        _activatedplayer = nil
    end
    if _hasfx then
        _rainfx.entity:SetParent(nil)
        _snowfx.entity:SetParent(nil)
        _pollenfx.entity:SetParent(nil)
    end
end

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
    _snowlevel:set(math.clamp(level or _snowlevel:value(), 0, 1))
end or nil

local OnDeltaWetness = _ismastersim and function(src, delta)
    _wetness:set(math.clamp(_wetness:value() + delta, MIN_WETNESS, MAX_WETNESS))
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

    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 40, nil, { "playerghost", "INLIMBO" }, { "lightningrod", "lightningtarget" })
    for k, v in pairs(ents) do
        local visrod = v:HasTag("lightningrod")
        local vpos = v:GetPosition()
        local vdistsq = distsq(pos0.x, pos0.z, vpos.x, vpos.z)
        --First, check if we're a valid target:
        --rods are always valid
        --playerlightning target is valid by chance (when not invincible)
        if (visrod or
            (   (v.components.health == nil or not v.components.health:IsInvincible()) and
                (v.components.playerlightningtarget == nil or math.random() <= v.components.playerlightningtarget:GetHitChance())
            ))
            --Now check for better match
            and (target == nil or
                (visrod and not isrod) or
                (visrod == isrod and vdistsq < mindistsq)) then
            target = v
            isrod = visrod
            pos = vpos
            mindistsq = vdistsq
        end
    end

    if isrod then
        target:PushEvent("lightningstrike")
    else
        if target ~= nil and target.components.playerlightningtarget ~= nil then
            target.components.playerlightningtarget:DoStrike()
        end

        ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 3, nil, _lightningexcludetags)
        for k, v in pairs(ents) do
            if v.components.burnable ~= nil then
                v.components.burnable:Ignite()
            end
        end
    end

    SpawnPrefab("lightning").Transform:SetPosition(pos:Get())
end or nil

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

_seasontemperature = CalculateSeasonTemperature(_season, .5)
_phasetemperature = CalculatePhaseTemperature(_daylight and "day" or "dusk", 0)

--Initialize network variables
_noisetime:set(0)
_moisture:set(0)
_moisturerate:set(0)
_moistureceil:set(0)
_moisturefloor:set(0)
_precipmode:set(PRECIP_MODES.dynamic)
_preciptype:set(PRECIP_TYPES.none)
_peakprecipitationrate:set(1)
_snowlevel:set(0)
_wetness:set(0)
_wet:set(false)

--Dedicated server does not need to spawn the local fx
if _hasfx then
    --Initialize rain particles
    _rainfx.particles_per_tick = 0
    _rainfx.splashes_per_tick = 0

    --Initialize snow particles
    _snowfx.particles_per_tick = 0

    --Initialize pollen
    _pollenfx.particles_per_tick = 0
end

--Register network variable sync events
inst:ListenForEvent("moistureceildirty", function() _world:PushEvent("moistureceilchanged", _moistureceil:value()) end)
inst:ListenForEvent("preciptypedirty", function() _world:PushEvent("precipitationchanged", PRECIP_TYPE_NAMES[_preciptype:value()]) end)
inst:ListenForEvent("snowcovereddirty", function() _world:PushEvent("snowcoveredchanged", _snowcovered:value()) end)
inst:ListenForEvent("wetdirty", function() _world:PushEvent("wetchanged", _wet:value()) end)

--Register events
inst:ListenForEvent("seasontick", OnSeasonTick, _world)
inst:ListenForEvent("clocktick", OnClockTick, _world)
inst:ListenForEvent("phasechanged", OnPhaseChanged, _world)
inst:ListenForEvent("playeractivated", OnPlayerActivated, _world)
inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated, _world)

if _ismastersim then
    --Initialize master simulation variables
    _moisturerateval = 1
    _moisturerateoffset = 0
    _moistureratemultiplier = 1
    _moistureceilmultiplier = 1
    _moisturefloormultiplier = 1
    _startsnowthreshold = START_SNOW_THRESHOLDS.autumn
    _stopsnowthreshold = STOP_SNOW_THRESHOLDS.autumn
    _lightningmode = LIGHTNING_MODES.rain
    _minlightningdelay = nil
    _maxlightningdelay = nil
    _nextlightningtime = 5
    _lightningtargets = {}
    _lightningexcludetags = { "player", "INLIMBO" }

    for k, v in pairs(FUELTYPE) do
        if v ~= FUELTYPE.USAGE then --Not a real fuel
            table.insert(_lightningexcludetags, v.."_fueled")
        end
    end

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
    inst:ListenForEvent("ms_deltawetness", OnDeltaWetness, _world)
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

    if _season == "summer" then
        _pollenfx:PostInit()
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
    if _pollenfx.entity:IsValid() then
        _pollenfx:Remove()
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

    --Update wetness
    local wetrate = CalculateWetnessRate(temperature, preciprate)
    SetWithPeriodicSync(_wetness, math.clamp(_wetness:value() + wetrate * dt, MIN_WETNESS, MAX_WETNESS), WETNESS_SYNC_PERIOD, _ismastersim)
    if _ismastersim then
        if _wet:value() then
            if _wetness:value() < DRY_THRESHOLD then
                _wet:set(false)
            end
        elseif _wetness:value() > WET_THRESHOLD then
            _wet:set(true)
        end
    end

    --Update precipitation effects
    if _preciptype:value() == PRECIP_TYPES.rain then
        local preciprate_sound = preciprate
        if _activatedplayer == nil then
            StopTreeRainSound()
            StopUmbrellaRainSound()
        elseif _activatedplayer.replica.sheltered ~= nil and _activatedplayer.replica.sheltered:IsSheltered() then
            StartTreeRainSound()
            StopUmbrellaRainSound()
            preciprate_sound = preciprate_sound - .4
        else
            StopTreeRainSound()
            if _activatedplayer.replica.inventory:EquipHasTag("umbrella") then
                preciprate_sound = preciprate_sound - .4
                StartUmbrellaRainSound()
            else
                StopUmbrellaRainSound()
            end
        end
        StartAmbientRainSound(preciprate_sound)
        if _hasfx then
            _rainfx.particles_per_tick = 5 * preciprate
            _rainfx.splashes_per_tick = 2 * preciprate
            _snowfx.particles_per_tick = 0
        end
    else
        StopAmbientRainSound()
        StopTreeRainSound()
        StopUmbrellaRainSound()
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

    --Update ground overlays
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
    if _snowlevel:value() > 0 and (temperature < 0 or _wetness:value() < 5) then
        SetGroundOverlay(GROUND_OVERLAYS.snow, _snowlevel:value() * 3) -- snowlevel goes from 0-1
    else
        SetGroundOverlay(GROUND_OVERLAYS.puddles, _wetness:value() * 3 / 100) -- wetness goes from 0-100
    end

    --Update pollen
    if _hasfx then
        if _season ~= "summer" then
            _pollenfx.particles_per_tick = 0
        elseif _seasonprogress < .2 then
            local ramp = _seasonprogress / .2
            _pollenfx.particles_per_tick = ramp * POLLEN_PARTICLES
        elseif _seasonprogress > .8 then
            local ramp = (1-_seasonprogress) / .2
            _pollenfx.particles_per_tick = ramp * POLLEN_PARTICLES
        else
            _pollenfx.particles_per_tick = POLLEN_PARTICLES
        end
    end

    if _ismastersim then
        --Update entity snow cover
        _snowcovered:set(_groundoverlay == GROUND_OVERLAYS.snow and _snowlevel:value() >= SNOW_COVERED_THRESHOLD)

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

    UpdateSummerBloom(dt)

    PushWeather(temperature, preciprate)
end

self.LongUpdate = self.OnUpdate

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

if _ismastersim then function self:OnSave()
    return
    {
        daylight = _daylight or nil,
        season = _season,
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
        moisturefloormultiplier = _moisturefloormultiplier,
        moistureceil = _moistureceil:value(),
        precipmode = PRECIP_MODE_NAMES[_precipmode:value()],
        preciptype = PRECIP_TYPE_NAMES[_preciptype:value()],
        peakprecipitationrate = _peakprecipitationrate:value(),
        snowlevel = _snowlevel:value(),
        snowcovered = _snowcovered:value() or nil,
        startsnowthreshold = _startsnowthreshold,
        stopsnowthreshold = _stopsnowthreshold,
        lightningmode = LIGHTNING_MODE_NAMES[_lightningmode],
        minlightningdelay = _minlightningdelay,
        maxlightningdelay = _maxlightningdelay,
        nextlightningtime = _nextlightningtime,
        wetness = _wetness:value(),
        wet = _wet:value() or nil,
    }
end end

if _ismastersim then function self:OnLoad(data)
    _daylight = data.daylight == true
    _season = data.season or "autumn"
    _seasontemperature = data.seasontemperature or CalculateSeasonTemperature(_season, .5)
    _phasetemperature = data.phasetemperature or CalculatePhaseTemperature(_daylight and "day" or "dusk", 0)
    _noisetime:set(data.noisetime or 0)
    _moisturerateval = data.moisturerateval or 1
    _moisturerateoffset = data.moisturerateoffset or 0
    _moistureratemultiplier = data.moistureratemultiplier or 1
    _moisturerate:set(data.moisturerate or CalculateMoistureRate())
    _moisture:set(data.moisture or 0)
    _moisturefloor:set(data.moisturefloor or 0)
    _moistureceilmultiplier = data.moistureceilmultiplier or 1
    _moisturefloormultiplier = data.moisturefloormultiplier or 1
    _moistureceil:set(data.moistureceil or RandomizeMoistureCeil())
    _precipmode:set(PRECIP_MODES[data.precipmode] or PRECIP_MODES.dynamic)
    _preciptype:set(PRECIP_TYPES[data.preciptype] or PRECIP_TYPES.none)
    _peakprecipitationrate:set(data.peakprecipitationrate or 1)
    _snowlevel:set(data.snowlevel or 0)
    _snowcovered:set(data.snowcovered == true)
    _startsnowthreshold = data.startsnowthreshold or START_SNOW_THRESHOLDS.autumn
    _stopsnowthreshold = data.stopsnowthreshold or STOP_SNOW_THRESHOLDS.autumn
    _lightningmode = LIGHTNING_MODES[data.lightningmode] or LIGHTNING_MODES.rain
    _minlightningdelay = data.minlightningdelay
    _maxlightningdelay = data.maxlightningdelay
    _nextlightningtime = data.nextlightningtime or 5
    _wetness:set(data.wetness or 0)
    _wet:set(data.wet == true)

    PushWeather()
end end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    local temperature = CalculateTemperature()
    local preciprate = CalculatePrecipitationRate()
    local wetrate = CalculateWetnessRate(temperature, preciprate)
    local str =
    {
        string.format("%2.2fC", temperature),
        string.format("moisture:%2.2f(%2.2f/%2.2f) + %2.2f", _moisture:value(), _moisturefloor:value(), _moistureceil:value(), _moisturerate:value()),
        string.format("preciprate:(%2.2f of %2.2f)", preciprate, _peakprecipitationrate:value()),
        string.format("snowlevel:%2.2f", _snowlevel:value()),
        string.format("wetness:%2.2f(%s%2.2f)%s", _wetness:value(), wetrate > 0 and "+" or "", wetrate, _wet:value() and " WET" or ""),
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

