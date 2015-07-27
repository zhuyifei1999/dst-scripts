 --------------------------------------------------------------------------
--[[ DSP class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

local easing = require("easing")

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local LOWDSP =
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

local SUMMER_FREQUENCIES = { 100, 250, 500, 750, 1000 }
local SUMMER_THRESHOLDS = { 65, 70, 75, 80 }

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _defaultlowdsp = {}
local _defaulthighdsp = {}

local _dsplowstack = {}
local _dsplowcomp = {}
local _dsphighstack = {}
local _dsphighcomp = {}
local _summerlevel = nil
local _activatedplayer = nil --cached for activation/deactivation only, NOT for logic use

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

-- gjans: this is here due to initialization order crap..
local SUMMER_DSP = function()
    return SUMMER_FREQUENCIES[_summerlevel]
end

-- gjans: this is here due to initialization order crap..
local HIGHDSP =
{
    summer =
    {
        ["set_music"] = 500,
        --["set_ambience"] = SUMMER_DSP,
        --["set_sfx/HUD"] = SUMMER_DSP,
        ["set_sfx/movement"] = SUMMER_DSP,
        ["set_sfx/creature"] = SUMMER_DSP,
        ["set_sfx/player"] = SUMMER_DSP,
        ["set_sfx/sfx"] = SUMMER_DSP,
        --["set_sfx/voice"] = SUMMER_DSP,
        ["set_sfx/set_ambience"] = SUMMER_DSP,
    },
}

local function RefreshDSP(duration)
    local lowdsp = {}
    local highdsp = {}
    duration = duration or 0

    for i, v in ipairs(_dsplowstack) do
        for k, v1 in pairs(v) do
            lowdsp[k] = v1
        end
    end
    for i, v in ipairs(_dsphighstack) do
        for k, v1 in pairs(v) do
            highdsp[k] = v1
        end
    end

    -- print("\n\n===============\nDSP Update:",duration,"second transition.")

    for k, v in pairs(lowdsp) do
        if v ~= _dsplowcomp[k] then
            -- print("Setting lowpass", k, v)
            TheMixer:SetLowPassFilter(k, v, duration)
        end
    end
    for k, v in pairs(_dsplowcomp) do
        if lowdsp[k] == nil then
            -- print("Clearing lowpass", k)
            TheMixer:ClearLowPassFilter(k, duration)
        end
    end
    _dsplowcomp = lowdsp

    for k, v in pairs(highdsp) do
        if v ~= _dsphighcomp[k] then
            -- print("Setting highpass", k, v)
            TheMixer:SetHighPassFilter(k, v, duration)
        end
    end
    for k, v in pairs(_dsphighcomp) do
        if highdsp[k] == nil then
            -- print("Clearing highpass", k)
            TheMixer:ClearHighPassFilter(k, duration)
        end
    end
    -- print("===============\n\n")
    _dsphighcomp = highdsp
end

local function UpdateSeasonDSP(season, duration)
    local lowdsp = LOWDSP[season]

    if lowdsp then
        for k, v in pairs(lowdsp) do
            _defaultlowdsp[k] = type(v) == "function" and v() or v
        end

        for k in pairs(_defaultlowdsp) do
            if lowdsp[k] == nil then
                _defaultlowdsp[k] = nil
            end
        end
    else
        for k in pairs(_defaultlowdsp) do
            _defaultlowdsp[k] = nil
        end
    end

    local highdsp = HIGHDSP[season]

    if highdsp then
        for k, v in pairs(highdsp) do
            _defaulthighdsp[k] = type(v) == "function" and v() or v
        end

        for k in pairs(_defaulthighdsp) do
            if highdsp[k] == nil then
                _defaulthighdsp[k] = nil
            end
        end
    else
        for k in pairs(_defaulthighdsp) do
            _defaulthighdsp[k] = nil
        end
    end
    RefreshDSP(duration)
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnWeatherTick(src, data)
    local step = #SUMMER_FREQUENCIES
    for i, v in ipairs(SUMMER_THRESHOLDS) do
        if data.temperature <= v then
            step = i
            break
        end
    end

    if step ~= _summerlevel then
        _summerlevel = step
        UpdateSeasonDSP(SEASONS.SUMMER, .5)
    end
end

local function OnUpdateSeasonDSP(season, duration)
    if season == SEASONS.SUMMER then
        if _summerlevel == nil then
            _summerlevel = 1
            inst:ListenForEvent("weatherick", OnWeatherTick)
        end
    elseif _summerlevel ~= nil then
        _summerlevel = nil
        inst:RemoveEventCallback("weathertick", OnWeatherTick)
    end
    UpdateSeasonDSP(season, duration)
end

local function OnSeasonTick(inst, data)
    OnUpdateSeasonDSP(data.season, 5)
end

local function OnPushDSP(inst, data)
    if data.lowdsp then
        table.insert(_dsplowstack, data.lowdsp)
    end
    if data.highdsp then
        table.insert(_dsphighstack, data.highdsp)
    end
    RefreshDSP(data.duration)
end

local function OnPopDSP(inst, data)
    if data.lowdsp then
        for i = #_dsplowstack, 1, -1 do
            if _dsplowstack[i] == data.lowdsp then
                table.remove(_dsplowstack, i)
                RefreshDSP(data.duration)
                return
            end
        end
    end
    if data.highdsp then
        for i = #_dsphighstack, 1, -1 do
            if _dsphighstack[i] == data.highdsp then
                table.remove(_dsphighstack, i)
                RefreshDSP(data.duration)
                return
            end
        end
    end
end

local function StartPlayerListeners(player)
    inst:ListenForEvent("seasontick", OnSeasonTick)
    OnUpdateSeasonDSP(TheWorld.state.season, 0)
end

local function StopPlayerListeners(player)
    inst:RemoveEventCallback("seasontick", OnSeasonTick)
    if _summerlevel ~= nil then
        _summerlevel = nil
        inst:RemoveEventCallback("weathertick", OnWeatherTick)
    end
    for i = #_dsplowstack, 2, -1 do
        table.remove(_dsplowstack, i)
    end
    for i = #_dsphighstack, 2, -1 do
        table.remove(_dsphighstack, i)
    end
    for k, v in pairs(_defaultlowdsp) do
        _defaultlowdsp[k] = nil
    end
    for k, v in pairs(_defaulthighdsp) do
        _defaulthighdsp[k] = nil
    end
    RefreshDSP(2)
end

local function OnPlayerActivated(inst, player)
    if _activatedplayer == player then
        return
    elseif _activatedplayer ~= nil and _activatedplayer.entity:IsValid() then
        StopPlayerListeners(_activatedplayer)
    end
    _activatedplayer = player
    StartPlayerListeners(player)
end

local function OnPlayerDeactivated(inst, player)
    StopPlayerListeners(player)
    if player == _activatedplayer then
        _activatedplayer = nil
    end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Register events
--V2C: push/pop should move into player listeners, but can't until we
--     refactor slurper dsp the same way we refactored nightvision as
--     a property of the equipment
inst:ListenForEvent("pushdsp", OnPushDSP)
inst:ListenForEvent("popdsp", OnPopDSP)
inst:ListenForEvent("playeractivated", OnPlayerActivated)
inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated)

-- This puts our own default DSP elements on the bottom of the stack
OnPushDSP(inst, { lowdsp = _defaultlowdsp, highdsp = _defaulthighdsp, duration = 0 })

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    local str = {}

    local lowdsplist = nil
    for k,v in pairs(_dsplowcomp) do
        if lowdsplist == nil then
            lowdsplist = "LOW: "
        else
            lowdsplist = lowdsplist..", "
        end
        lowdsplist = lowdsplist..string.format("%s=%d",k,v)
    end
    table.insert(str, lowdsplist)

    local highdsplist = nil
    for k,v in pairs(_dsplowcomp) do
        if highdsplist == nil then
            highdsplist = "HIGH: "
        else
            highdsplist = highdsplist..", "
        end
        highdsplist = highdsplist..string.format("%s=%d",k,v)
    end
    table.insert(str, highdsplist)

    return table.concat(str, "\n")
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
