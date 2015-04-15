--------------------------------------------------------------------------
--[[ ColourCube ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

local easing = require("easing")

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local IDENTITY_COLOURCUBE = "images/colour_cubes/identity_colourcube.tex"

local INSANITY_COLOURCUBES =
{
    day = "images/colour_cubes/insane_day_cc.tex",
    dusk = "images/colour_cubes/insane_dusk_cc.tex",
    night = "images/colour_cubes/insane_night_cc.tex",
}

local SEASON_COLOURCUBES =
{
    summer =
    {
        day = "images/colour_cubes/day05_cc.tex",
        dusk = "images/colour_cubes/dusk03_cc.tex",
        night = "images/colour_cubes/night03_cc.tex",
    },
    winter =
    {
        day = "images/colour_cubes/snow_cc.tex",
        dusk = "images/colour_cubes/snowdusk_cc.tex",
        night = "images/colour_cubes/night04_cc.tex",
    },
}

local CAVE_COLOURCUBES =
{
    day = "images/colour_cubes/caves_default.tex",
    dusk = "images/colour_cubes/caves_default.tex",
    night = "images/colour_cubes/caves_default.tex",
}

local PHASE_BLEND_TIMES =
{
    day = 4,
    dusk = 6,
    night = 8,
}

local SEASON_BLEND_TIME = 10

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _iscave = inst:HasTag("cave")
local _phase = "day"
local _ambientcctable = _iscave and CAVE_COLOURCUBES or SEASON_COLOURCUBES.summer
local _ambientcc = { _ambientcctable.day, _ambientcctable.day }
local _insanitycc = { INSANITY_COLOURCUBES.day, INSANITY_COLOURCUBES.day }
local _overridecc = nil
local _remainingblendtime = 0
local _totalblendtime = 0
local _fxtime = 0
local _fxspeed = 0
local _activatedplayer = nil --cached for activation/deactivation only, NOT for logic use

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function Blend(time)
    local ambientcctarget = _ambientcctable[_phase] or IDENTITY_COLOURCUBE
    local insanitycctarget = INSANITY_COLOURCUBES[_phase] or IDENTITY_COLOURCUBE

    if _overridecc ~= nil then
        _ambientcc[2] = ambientcctarget
        _insanitycc[2] = insanitycctarget
        return
    end

    local newtarget = _ambientcc[2] ~= ambientcctarget or _insanitycc[2] ~= insanitycctarget

    if _remainingblendtime <= 0 then
        --No blends in progress, so we can start a new blend
        if newtarget then
            _ambientcc[1] = _ambientcc[2]
            _ambientcc[2] = ambientcctarget
            _insanitycc[1] = _insanitycc[2]
            _insanitycc[2] = insanitycctarget
            _remainingblendtime = time
            _totalblendtime = time
            PostProcessor:SetColourCubeData(0, _ambientcc[1], _ambientcc[2])
            PostProcessor:SetColourCubeData(1, _insanitycc[1], _insanitycc[2])
            PostProcessor:SetColourCubeLerp(0, 0)
        end
    elseif newtarget then
        --Skip any blend in progress and restart new blend
        if _remainingblendtime < _totalblendtime then
            _ambientcc[1] = _ambientcc[2]
            _insanitycc[1] = _insanitycc[2]
            PostProcessor:SetColourCubeLerp(0, 0)
        end
        _ambientcc[2] = ambientcctarget
        _insanitycc[2] = insanitycctarget
        _remainingblendtime = time
        _totalblendtime = time
        PostProcessor:SetColourCubeData(0, _ambientcc[1], _ambientcc[2])
        PostProcessor:SetColourCubeData(1, _insanitycc[1], _insanitycc[2])
    elseif _remainingblendtime >= _totalblendtime and time < _totalblendtime then
        --Same target, but hasn't ticked yet, so switch to the faster time
        _remainingblendtime = time
        _totalblendtime = time
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnSanityDelta(player, data)
    local distortion = easing.outQuad(data.newpercent, 0, 1, 1)
    PostProcessor:SetColourCubeLerp(1, 1 - distortion)
    PostProcessor:SetDistortionFactor(distortion)
    _fxspeed = easing.outQuad(1 - data.newpercent, 0, .2, 1)
end

local function OnPlayerActivated(inst, player)
    if _activatedplayer == player then
        return
    elseif _activatedplayer ~= nil and _activatedplayer.entity:IsValid() then
        inst:RemoveEventCallback("sanitydelta", OnSanityDelta, _activatedplayer)
    end
    _activatedplayer = player
    inst:ListenForEvent("sanitydelta", OnSanityDelta, player)
    if player.replica.sanity ~= nil then
        OnSanityDelta(player, { newpercent = player.replica.sanity:GetPercent() })
    end
end

local function OnPlayerDeactivated(inst, player)
    inst:RemoveEventCallback("sanitydelta", OnSanityDelta, player)
    OnSanityDelta(player, { newpercent = 1 })
    if player == _activatedplayer then
        _activatedplayer = nil
    end
end

local function OnPhaseChanged(inst, phase)
    if _phase ~= phase then
        _phase = phase

        local blendtime = PHASE_BLEND_TIMES[phase]
        if blendtime then
            Blend(blendtime)
        end
    end
end

local OnSeasonTick = not _iscave and function(inst, data)
    _ambientcctable = SEASON_COLOURCUBES[data.season] or _ambientcctable
    Blend(SEASON_BLEND_TIME)
end or nil

local function OnOverrideColourCube(inst, cc)
    if _overridecc ~= cc then
        _overridecc = cc

        if cc ~= nil then
            PostProcessor:SetColourCubeData(0, cc, cc)
            PostProcessor:SetColourCubeData(1, cc, cc)
            PostProcessor:SetColourCubeLerp(0, 1)
        else
            PostProcessor:SetColourCubeData(0, _ambientcc[2], _ambientcc[2])
            PostProcessor:SetColourCubeData(1, _insanitycc[2], _insanitycc[2])
        end
    end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Channel 0: ambient colour cube
--Channel 1: insanity colour cube
PostProcessor:SetColourCubeData(0, _ambientcc[1], _ambientcc[2])
PostProcessor:SetColourCubeData(1, _insanitycc[1], _insanitycc[2])
PostProcessor:SetColourCubeLerp(0, 1)
PostProcessor:SetColourCubeLerp(1, 0)
PostProcessor:SetDistortionRadii(0.5, 0.685)

--Register events
inst:ListenForEvent("playeractivated", OnPlayerActivated)
inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated)
inst:ListenForEvent("phasechanged", OnPhaseChanged)
if not _iscave then
    inst:ListenForEvent("seasontick", OnSeasonTick)
end
inst:ListenForEvent("overridecolourcube", OnOverrideColourCube)

inst:StartUpdatingComponent(self)

--------------------------------------------------------------------------
--[[ Update ]]
--------------------------------------------------------------------------

function self:OnUpdate(dt)
    if _overridecc == nil then
        if _remainingblendtime > dt then
            _remainingblendtime = _remainingblendtime - dt
            PostProcessor:SetColourCubeLerp(0, 1 - _remainingblendtime / _totalblendtime)
        elseif _remainingblendtime > 0 then
            _remainingblendtime = 0
            PostProcessor:SetColourCubeLerp(0, 1)
        end
    end

    _fxtime = _fxtime + dt * _fxspeed
    PostProcessor:SetEffectTime(_fxtime)
end

function self:LongUpdate(dt)
    self:OnUpdate(_remainingblendtime)
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)