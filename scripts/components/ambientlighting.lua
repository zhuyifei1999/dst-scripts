--------------------------------------------------------------------------
--[[ AmbientLighting ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local PHASE_COLOURS =
{
    day = { colour = Point(255 / 255, 230 / 255, 158 / 255), time = 4 },
    dusk = { colour = Point(100 / 255, 100 / 255, 100 / 255), time = 6 },
    night = { colour = Point(0 / 255, 0 / 255, 0 / 255), time = 8 },
}

local FULL_MOON_COLOUR = { colour = Point(84 / 255, 122 / 255, 156 / 255), time = 8 }
local CAVE_COLOUR = { colour = Point(0 / 255, 0 / 255, 0 / 255), time = 2 }

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _iscave = inst:HasTag("cave")
local _updating = false
local _remainingtimeinlerp = 0
local _totaltimeinlerp = 0
local _lerpfromcolour = Point()
local _lerptocolour = Point()
local _currentcolour = _iscave and Point(CAVE_COLOUR.colour:Get()) or Point(PHASE_COLOURS.day.colour:Get())
local _lightpercent = 1
local _flash = false
local _flashtime = 0
local _flashintensity = 1

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function SetColour(dest, src)
    dest.x, dest.y, dest.z = src:Get()
end

local function Start()
    if not _updating then
        inst:StartUpdatingComponent(self)
        _updating = true
    end
end

local function Stop()
    if _updating then
        inst:StopUpdatingComponent(self)
        _updating = false
    end
end

local function PushCurrentColour()
    TheSim:SetAmbientColour(_currentcolour.x * _lightpercent, _currentcolour.y * _lightpercent, _currentcolour.z * _lightpercent)
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnPhaseChanged(src, phase)
    local col = _iscave and CAVE_COLOUR
                or TheWorld.state.isfullmoon and FULL_MOON_COLOUR
                or PHASE_COLOURS[phase]
    if col == nil then
        return
    end

    _remainingtimeinlerp = col.colour ~= _currentcolour and col.time or 0
    if _remainingtimeinlerp > 0 then
        _totaltimeinlerp = _remainingtimeinlerp
        SetColour(_lerpfromcolour, _currentcolour)
        SetColour(_lerptocolour, col.colour)
        if not _flash then
            PushCurrentColour()
        end
        Start()
    elseif not _flash then
        SetColour(_currentcolour, col.colour)
        PushCurrentColour()
        Stop()
    else
        SetColour(_currentcolour, col.colour)
    end
end

local function OnWeatherTick(src, data)
    _lightpercent = data.light
    if not _flash then
        PushCurrentColour()
    end
end

local function OnScreenFlash(src, intensity)
    _flash = true
    _flashtime = 0
    _flashintensity = intensity
    Start()
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

PushCurrentColour()

--Register events
inst:ListenForEvent("phasechanged", OnPhaseChanged)
inst:ListenForEvent("weathertick", OnWeatherTick)
inst:ListenForEvent("screenflash", OnScreenFlash)

--------------------------------------------------------------------------
--[[ Update ]]
--------------------------------------------------------------------------

function self:OnUpdate(dt)
    if _remainingtimeinlerp > 0 then
        _remainingtimeinlerp = _remainingtimeinlerp - dt
        if _remainingtimeinlerp > 0 then
            local frompercent = _remainingtimeinlerp / _totaltimeinlerp
            local topercent = 1 - frompercent
            _currentcolour.x = _lerpfromcolour.x * frompercent + _lerptocolour.x * topercent
            _currentcolour.y = _lerpfromcolour.y * frompercent + _lerptocolour.y * topercent
            _currentcolour.z = _lerpfromcolour.z * frompercent + _lerptocolour.z * topercent
            if not _flash then
                PushCurrentColour()
            end
        elseif not _flash then
            SetColour(_currentcolour, _lerptocolour)
            PushCurrentColour()
            Stop()
        else
            SetColour(_currentcolour, _lerptocolour)
        end
    end
    if _flash then
        _flashtime = _flashtime + dt
        if _flashtime < 3 / 60 then
            TheSim:SetAmbientColour(0, 0, 0)
        elseif _flashtime < 7 / 60 then
            TheSim:SetAmbientColour(_flashintensity, _flashintensity, _flashintensity)
        elseif _flashtime < 9 / 60 then
            TheSim:SetAmbientColour(0, 0, 0)
        elseif _flashtime < 17 / 60 then
            TheSim:SetAmbientColour(_flashintensity, _flashintensity, _flashintensity)
        elseif _flashtime < 107 / 60 then
            local k = (.5 + (_flashtime * 60 - 17) / 180) * _lightpercent
            TheSim:SetAmbientColour(_currentcolour.x * k, _currentcolour.y * k, _currentcolour.z * k)
        else
            _flash = false
            PushCurrentColour()
            if _remainingtimeinlerp <= 0 then
                Stop()
            end
        end
    end
end

function self:LongUpdate(dt)
    if _updating then
        SetColour(_currentcolour, _lerptocolour)
        _flash = false
        _remainingtimeinlerp = 0
        PushCurrentColour()
        Stop()
    end
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)