--------------------------------------------------------------------------
--[[ Seasons class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

local easing = require("easing")

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local SEASON_NAMES =
{
    "summer",
    "winter",
}
local SEASONS = table.invert(SEASON_NAMES)

local MODE_NAMES =
{
    "cycle",
    "endless",
    "always",
}
local MODES = table.invert(MODE_NAMES)

local NUM_CLOCK_SEGS = 16
local DEFAULT_CLOCK_SEGS =
{
    summer = { day = 10, dusk = 4, night = 2 },
    winter = { day = 6, dusk = 6, night = 4 },
}

local ENDLESS_PRE_DAYS = 10
local ENDLESS_RAMP_DAYS = 10
local ENDLESS_DAYS = 10000

local DSP =
{
    winter =
    {
        ["set_music"] = 2000,
        --["set_ambience"] = 5000,
        --["set_sfx/HUD"] = 5000,
        --["set_sfx/movement"] = 5000,
        ["set_sfx/creature"] = 5000,
        ["set_sfx/player"] = 5000,
        ["set_sfx/sfx"] = 5000,
        ["set_sfx/voice"] = 5000,
        ["set_sfx/set_ambience"] = 5000,
    },
}

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _world = TheWorld
local _ismastersim = _world.ismastersim
local _dsp = {}

--Master simulation
local _mode
local _preendlessmode
local _segs

--Network
local _season = net_tinybyte(inst.GUID, "seasons._season", "seasondirty")
local _totaldaysinseason = net_byte(inst.GUID, "seasons._totaldaysinseason", "seasondirty")
local _elapseddaysinseason = net_ushortint(inst.GUID, "seasons._elapseddaysinseason", "seasondirty")
local _remainingdaysinseason = net_byte(inst.GUID, "seasons._remainingdaysinseason", "seasondirty")
local _endlessdaysinseason = net_bool(inst.GUID, "seasons._endlessdaysinseason", "seasondirty")
local _lengths = {}
for i, v in ipairs(SEASON_NAMES) do
    _lengths[i] = net_byte(inst.GUID, "seasons._lengths."..v, "lengthsdirty")
end

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local GetPrevSeason = _ismastersim and function()
    if _preendlessmode or _mode == MODES.always then
        return _season:value()
    end

    local season = _season:value()
    while true do
        season = season > 1 and season - 1 or #SEASON_NAMES
        if _lengths[season]:value() > 0 or season == _season:value() then
            return season
        end
    end

    return season
end or nil

local GetNextSeason = _ismastersim and function()
    if not _preendlessmode and (_mode == MODES.endless or _mode == MODES.always) then
        return _season:value()
    end

    local season = _season:value()
    while true do
        season = (season % #SEASON_NAMES) + 1
        if _lengths[season]:value() > 0 or season == _season:value() then
            return season
        end
    end

    return season
end or nil

local PushSeasonClockSegs = _ismastersim and function()
    local p = 1 - (_totaldaysinseason:value() > 0 and _remainingdaysinseason:value() / _totaldaysinseason:value() or 0)
    local toseason = p < .5 and GetPrevSeason() or GetNextSeason()
    local tosegs = _segs[toseason]
    local segs = tosegs
    
    if _season:value() ~= toseason then
        local fromsegs = _segs[_season:value()]
        p = .5 - math.sin(PI * p) * .5
        segs =
        {
            day = math.floor(easing.linear(p, fromsegs.day, tosegs.day - fromsegs.day, 1) + .5),
            night = math.floor(easing.linear(p, fromsegs.night, tosegs.night - fromsegs.night, 1) + .5),
        }
        segs.dusk = NUM_CLOCK_SEGS - segs.day - segs.night
    end

    _world:PushEvent("ms_setclocksegs", segs)
end or nil

local function ModifySeasonDSP(duration)
    local dsp = DSP[SEASON_NAMES[_season:value()]]

    if dsp then
        for k, v in pairs(dsp) do
            _dsp[k] = v
        end

        for k in pairs(_dsp) do
            if dsp[k] == nil then
                _dsp[k] = nil
            end
        end
    else
        for k in pairs(_dsp) do
            _dsp[k] = nil
        end
    end

    _world:PushEvent("refreshdsp", duration)
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnSeasonDirty()
    ModifySeasonDSP(5)

    local data = {
        season = SEASON_NAMES[_season:value()],
        progress = 1 - (_totaldaysinseason:value() > 0 and _remainingdaysinseason:value() / _totaldaysinseason:value() or 0),
        elapseddaysinseason = _elapseddaysinseason:value(),
        remainingdaysinseason = _endlessdaysinseason:value() and ENDLESS_DAYS or _remainingdaysinseason:value(),
    }
    _world:PushEvent("seasontick", data)
end

local function OnLengthsDirty()
    local data = {}
    for i, v in ipairs(_lengths) do
        data[SEASON_NAMES[i]] = v:value()
    end
    _world:PushEvent("seasonlengthschanged", data)
end

local OnAdvanceSeason = _ismastersim and function()
    _elapseddaysinseason:set(_elapseddaysinseason:value() + 1)

    if _mode == MODES.cycle then
        if _remainingdaysinseason:value() > 1 then
            --Progress current season
            _remainingdaysinseason:set(_remainingdaysinseason:value() - 1)
        else
            --Advance to next season
            _season:set(GetNextSeason())
            _totaldaysinseason:set(_lengths[_season:value()]:value())
            _elapseddaysinseason:set(0)
            _remainingdaysinseason:set(_totaldaysinseason:value())
        end
    elseif _mode == MODES.endless then
        if _preendlessmode then
            if _remainingdaysinseason:value() > 1 then
                --Progress pre endless season
                _remainingdaysinseason:set(_remainingdaysinseason:value() - 1)
            else
                --Advance to endless season
                _season:set(GetNextSeason())
                _totaldaysinseason:set(ENDLESS_RAMP_DAYS * 2)
                _elapseddaysinseason:set(0)
                _remainingdaysinseason:set(_totaldaysinseason:value())
                _endlessdaysinseason:set(true)
                _preendlessmode = false
            end
        elseif _remainingdaysinseason:value() > ENDLESS_RAMP_DAYS then
            --Progress to peak of endless season
            _remainingdaysinseason:set(_remainingdaysinseason:value() - 1)
        end
    else
        return
    end

    PushSeasonClockSegs()
end or nil

local OnRetreatSeason = _ismastersim and function()
    if _elapseddaysinseason:value() > 0 then
        _elapseddaysinseason:set(_elapseddaysinseason:value() - 1)
    end

    if _mode == MODES.cycle then
        if _remainingdaysinseason:value() < _totaldaysinseason:value() then
            --Regress current season
            _remainingdaysinseason:set(_remainingdaysinseason:value() + 1)
        else
            --Retreat to previous season
            _season:set(GetPrevSeason())
            _totaldaysinseason:set(_lengths[_season:value()]:value())
            _elapseddaysinseason:set(math.max(_totaldaysinseason:value() - 1, 0))
            _remainingdaysinseason:set(1)
        end
    elseif _mode == MODES.endless then
        if not _preendlessmode then
            if _remainingdaysinseason:value() < _totaldaysinseason:value() then
                --Regress endless season
                _remainingdaysinseason:set(_remainingdaysinseason:value() + 1)
            else
                --Retreat to pre endless season
                _season:set(GetPrevSeason())
                _totaldaysinseason:set(ENDLESS_PRE_DAYS * 2)
                _elapseddaysinseason:set(math.max(ENDLESS_PRE_DAYS - 1, 0))
                _remainingdaysinseason:set(1)
                _endlessdaysinseason:set(false)
                _preendlessmode = true
            end
        elseif _remainingdaysinseason:value() < ENDLESS_PRE_DAYS then
            --Regress to peak of pre endless season
            _remainingdaysinseason:set(_remainingdaysinseason:value() + 1)
        end
    else
        return
    end

    PushSeasonClockSegs()
end or nil

local OnSetSeason = _ismastersim and function(src, season)
    assert(_ismastersim, "Invalid permissions")

    season = SEASONS[season]
    if season == nil then
        return
    end

    if _season:value() ~= season then
        _season:set(season)
        _elapseddaysinseason:set(0)
    end

    if _mode == MODES.endless then
        _preendlessmode = true
        _totaldaysinseason:set(ENDLESS_PRE_DAYS * 2)
        _remainingdaysinseason:set(ENDLESS_PRE_DAYS)
        _endlessdaysinseason:set(false)
    elseif _mode ~= MODES.always then
        _totaldaysinseason:set(_lengths[_season:value()]:value())
        _remainingdaysinseason:set(_totaldaysinseason:value())
    end

    PushSeasonClockSegs()
end or nil

local OnSetSeasonMode = _ismastersim and function(src, mode)
    if MODES[mode] == nil then
        return
    end

    _mode = MODES[mode]

    if _mode == MODES.endless then
        _preendlessmode = true
        _totaldaysinseason:set(ENDLESS_PRE_DAYS * 2)
        _remainingdaysinseason:set(ENDLESS_PRE_DAYS)
        _endlessdaysinseason:set(false)
    elseif _mode == MODES.always then
        _totaldaysinseason:set(2)
        _remainingdaysinseason:set(1)
        _endlessdaysinseason:set(true)
    else
        _totaldaysinseason:set(_lengths[_season:value()]:value())
        _remainingdaysinseason:set(math.ceil(_totaldaysinseason:value() * .5))
        _endlessdaysinseason:set(false)
    end

    PushSeasonClockSegs()
end or nil

local OnSetSeasonClockSegs = _ismastersim and function(src, segs)
    local default = nil
    for k, v in pairs(segs) do
        default = v
        break
    end

    if default == nil then
        if segs ~= DEFAULT_CLOCK_SEGS then
            OnSetSeasonClockSegs(DEFAULT_CLOCK_SEGS)
        end
        return
    end

    for i, v in ipairs(SEASON_NAMES) do
        _segs[i] = segs[v] or default
    end

    PushSeasonClockSegs()
end or nil

local OnSetSeasonLengths = _ismastersim and function(src, lengths)
    for i, v in ipairs(SEASON_NAMES) do
        _lengths[i]:set(lengths[v] or 0)
    end

    if _mode ~= MODES.endless and _mode ~= MODES.always then
        local p = 1
        if _totaldaysinseason:value() > 0 then
            p = _remainingdaysinseason:value() / _totaldaysinseason:value()
        end

        _totaldaysinseason:set(_lengths[_season:value()]:value())
        _remainingdaysinseason:set(math.ceil(_totaldaysinseason:value() * p))

        PushSeasonClockSegs()
    end
end or nil

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Initialize network variables
_season:set(SEASONS.summer)
_totaldaysinseason:set(TUNING.SUMMER_LENGTH)
_elapseddaysinseason:set(0)
_remainingdaysinseason:set(_totaldaysinseason:value())
_endlessdaysinseason:set(false)
for i, v in ipairs(_lengths) do
    v:set(TUNING[string.upper(SEASON_NAMES[i]).."_LENGTH"] or 0)
end

--Register network variable sync events
inst:ListenForEvent("seasondirty", OnSeasonDirty)
inst:ListenForEvent("lengthsdirty", OnLengthsDirty)

if _ismastersim then
    _mode = MODES.cycle
    _preendlessmode = false
    _segs = {}

    for i, v in ipairs(SEASON_NAMES) do
        _segs[i] = DEFAULT_CLOCK_SEGS[v]
    end

    PushSeasonClockSegs()

    --Register master simulation events
    inst:ListenForEvent("ms_cyclecomplete", OnAdvanceSeason, _world)
    inst:ListenForEvent("ms_advanceseason", OnAdvanceSeason, _world)
    inst:ListenForEvent("ms_retreatseason", OnRetreatSeason, _world)
    inst:ListenForEvent("ms_setseason", OnSetSeason, _world)
    inst:ListenForEvent("ms_setseasonmode", OnSetSeasonMode, _world)
    inst:ListenForEvent("ms_setseasonclocksegs", OnSetSeasonClockSegs, _world)
    inst:ListenForEvent("ms_setseasonlengths", OnSetSeasonLengths, _world)
end

local dsp = DSP[SEASON_NAMES[_season:value()]]
if dsp ~= nil then
    for k, v in pairs(dsp) do
        _dsp[k] = v
    end
end

_world:PushEvent("pushdsp", { dsp = _dsp, duration = 0 })

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

if _ismastersim then function self:OnSave()
    local data =
    {
        mode = MODE_NAMES[_mode],
        preendlessmode = _preendlessmode,
        segs = {},
        season = SEASON_NAMES[_season:value()],
        totaldaysinseason = _totaldaysinseason:value(),
        elapseddaysinseason = _elapseddaysinseason:value(),
        remainingdaysinseason = _remainingdaysinseason:value(),
        lengths = {},
    }

    for i, v in ipairs(SEASON_NAMES) do
        data.segs[v] = {}
        for k, v1 in pairs(_segs[i]) do
            data.segs[v][k] = v1
        end
        data.lengths[v] = _lengths[i]:value()
    end

    return data
end end

if _ismastersim then function self:OnLoad(data)
    for i, v in ipairs(SEASON_NAMES) do
        local segs = {}
        local totalsegs = 0

        for k, v1 in pairs(_segs[i]) do
            segs[k] = data.segs and data.segs[v][k] or 0
            totalsegs = totalsegs + segs[k]
        end

        if totalsegs == NUM_CLOCK_SEGS then
            _segs[i] = segs
        else
            _segs[i] = DEFAULT_CLOCK_SEGS[v]
        end

        _lengths[i]:set(data.lengths and data.lengths[v] or TUNING[string.upper(v).."_LENGTH"] or 0)
    end

    _preendlessmode = data.preendlessmode == true
    _mode = MODES[data.mode] or (_preendlessmode and MODES.endless or MODES.cycle)
    _preendlessmode = _preendlessmode and _mode == MODES.endless
    _season:set(SEASONS[data.season] or SEASONS.summer)
    _totaldaysinseason:set(data.totaldaysinseason or _lengths[_season:value()]:value())
    _elapseddaysinseason:set(data.elapseddaysinseason or 0)
    _remainingdaysinseason:set(math.min(data.remainingdaysinseason or _totaldaysinseason:value(), _totaldaysinseason:value()))
    _endlessdaysinseason:set(not _preendlessmode and _mode ~= MODES.cycle)

    PushSeasonClockSegs()
    ModifySeasonDSP(0)
end end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    return string.format("%s %d days", SEASON_NAMES[_season:value()], _endlessdaysinseason:value() and ENDLESS_DAYS or _remainingdaysinseason:value())
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)