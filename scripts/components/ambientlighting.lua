--------------------------------------------------------------------------
--[[ AmbientLighting ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local NORMAL_COLOURS = {
    PHASE_COLOURS =
    {
        default = {
            day = { colour = Point(255 / 255, 230 / 255, 158 / 255), time = 4 },
            dusk = { colour = Point(150 / 255, 150 / 255, 150 / 255), time = 6 },
            night = { colour = Point(0 / 255, 0 / 255, 0 / 255), time = 8 },
        },
        spring = {
            day = { colour = Point(255 / 255, 244 / 255, 213 / 255), time = 4 },
            dusk = { colour = Point(171 / 255, 146 / 255, 147 / 255), time = 6 },
            night = { colour = Point(0 / 255, 0 / 255, 0 / 255), time = 8 },
        },
    },

    FULL_MOON_COLOUR = { colour = Point(84 / 255, 122 / 255, 156 / 255), time = 8 },
    CAVE_COLOUR = { colour = Point(0 / 255, 0 / 255, 0 / 255), time = 2 },
}
    
local NIGHTVISION_COLOURS = {
    PHASE_COLOURS =
    {
        default = {
            day = { colour = Point(200 / 255, 200 / 255, 200 / 255), time = 4 },
            dusk = { colour = Point(120 / 255, 120 / 255, 120 / 255), time = 6 },
            night = { colour = Point(200 / 255, 200 / 255, 200 / 255), time = 8 },
        },
    },

    FULL_MOON_COLOUR = { colour = Point(200 / 255, 200 / 255, 200 / 255), time = 8 },
    CAVE_COLOUR = { colour = Point(200 / 255, 200 / 255, 200 / 255), time = 2 },
}

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _iscave = inst:HasTag("cave")
local _season = "autumn"
local _phase = "day"
local _updating = false
local _realcolour = {
    remainingtimeinlerp = 0,
    totaltimeinlerp = 0,
    lerpfromcolour = Point(),
    lerptocolour = Point(),
    currentcolourset = NORMAL_COLOURS,
    currentcolour = _iscave and Point(NORMAL_COLOURS.CAVE_COLOUR.colour:Get()) or Point(NORMAL_COLOURS.PHASE_COLOURS.default.day.colour:Get()),
    currentoverridecolour = _iscave and Point(NORMAL_COLOURS.CAVE_COLOUR.colour:Get()) or Point(NORMAL_COLOURS.PHASE_COLOURS.default.day.colour:Get()),
    lightpercent = 1,
}
local _overridecolour = {
    remainingtimeinlerp = 0,
    totaltimeinlerp = 0,
    lerpfromcolour = Point(),
    lerptocolour = Point(),
    currentcolourset = NORMAL_COLOURS,
    currentcolour = _iscave and Point(NORMAL_COLOURS.CAVE_COLOUR.colour:Get()) or Point(NORMAL_COLOURS.PHASE_COLOURS.default.day.colour:Get()),
    currentoverridecolour = _iscave and Point(NORMAL_COLOURS.CAVE_COLOUR.colour:Get()) or Point(NORMAL_COLOURS.PHASE_COLOURS.default.day.colour:Get()),
    lightpercent = 1,
}
local _flash = false
local _flashtime = 0
local _flashintensity = 1
local _flashcolour = Point(0,0,0)
local _activatedplayer = nil --cached for activation/deactivation only, NOT for logic use
local _nightvision = false -- This is whether or not the active player is wearing a mole hat

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
	if _flash then
		TheSim:SetAmbientColour(_flashcolour.x, _flashcolour.y, _flashcolour.z)
		TheSim:SetVisualAmbientColour(_flashcolour.x, _flashcolour.y, _flashcolour.z)
	else
		TheSim:SetAmbientColour(_realcolour.currentcolour.x * _realcolour.lightpercent, _realcolour.currentcolour.y * _realcolour.lightpercent, _realcolour.currentcolour.z * _realcolour.lightpercent)
		TheSim:SetVisualAmbientColour(_overridecolour.currentcolour.x * _overridecolour.lightpercent, _overridecolour.currentcolour.y * _overridecolour.lightpercent, _overridecolour.currentcolour.z * _overridecolour.lightpercent)
	end
end

local function ComputeTargetColour(targetsettings, timeoverride)
    local col = _iscave and targetsettings.currentcolourset.CAVE_COLOUR
                or TheWorld.state.isfullmoon and targetsettings.currentcolourset.FULL_MOON_COLOUR
                or targetsettings.currentcolourset.PHASE_COLOURS[_season] and targetsettings.currentcolourset.PHASE_COLOURS[_season][_phase]
                or targetsettings.currentcolourset.PHASE_COLOURS.default[_phase]
    if col == nil then
        return
    end

    targetsettings.remainingtimeinlerp = col.colour ~= targetsettings.currentcolour and timeoverride or col.time or 0
    if targetsettings.remainingtimeinlerp > 0 then
        targetsettings.totaltimeinlerp = targetsettings.remainingtimeinlerp
        SetColour(targetsettings.lerpfromcolour, targetsettings.currentcolour)
        SetColour(targetsettings.lerptocolour, col.colour)
    else
        SetColour(targetsettings.currentcolour, col.colour)
    end

    -- Trigger at least one update so the cubes can refresh
    Start()
end


--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnPhaseChanged(src, phase)
    _phase = phase

    ComputeTargetColour(_realcolour)
    ComputeTargetColour(_overridecolour)
    PushCurrentColour()
end

local function OnWeatherTick(src, data)
    _realcolour.lightpercent = data.light
    _overridecolour.lightpercent = data.light
    if not _flash then
        PushCurrentColour()
    end
end

local function OnNightVision(player, enabled)
    _nightvision = enabled
    _overridecolour.currentcolourset = enabled and NIGHTVISION_COLOURS or NORMAL_COLOURS
    ComputeTargetColour(_overridecolour, 0.25)
    PushCurrentColour()
end

local function OnScreenFlash(src, intensity)
    _flash = true
    _flashtime = 0
    _flashintensity = intensity
    Start()
end

local function OnPlayerDeactivated(inst, player)
    inst:RemoveEventCallback("nightvision", OnNightVision, player)
    OnNightVision(player, false)
    if player == _activatedplayer then
        _activatedplayer = nil
    end
end

local function OnPlayerActivated(inst, player)
    if _activatedplayer == player then
        return
    elseif _activatedplayer ~= nil and _activatedplayer.entity:IsValid() then
        OnPlayerDeactivated(_activatedplayer)
    end
    _activatedplayer = player
    inst:ListenForEvent("nightvision", OnNightVision, player)
    OnNightVision(player, CanEntitySeeInDark(player))
end

local OnSeasonTick = not _iscave and function(inst, data)
    _season = data.season
end or nil

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

PushCurrentColour()

--Register events
inst:ListenForEvent("phasechanged", OnPhaseChanged)
inst:ListenForEvent("weathertick", OnWeatherTick)
inst:ListenForEvent("screenflash", OnScreenFlash)
if not _iscave then
    inst:ListenForEvent("seasontick", OnSeasonTick)
end

inst:ListenForEvent("playeractivated", OnPlayerActivated)
inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated)

--------------------------------------------------------------------------
--[[ Update ]]
--------------------------------------------------------------------------

local function DoUpdate(dt, targetsettings)
    if targetsettings.remainingtimeinlerp > 0 then
        targetsettings.remainingtimeinlerp = targetsettings.remainingtimeinlerp - dt
        if targetsettings.remainingtimeinlerp > 0 then
            local frompercent = targetsettings.remainingtimeinlerp / targetsettings.totaltimeinlerp
            local topercent = 1 - frompercent
            targetsettings.currentcolour.x = targetsettings.lerpfromcolour.x * frompercent + targetsettings.lerptocolour.x * topercent
            targetsettings.currentcolour.y = targetsettings.lerpfromcolour.y * frompercent + targetsettings.lerptocolour.y * topercent
            targetsettings.currentcolour.z = targetsettings.lerpfromcolour.z * frompercent + targetsettings.lerptocolour.z * topercent
            return true
        else
            SetColour(targetsettings.currentcolour, targetsettings.lerptocolour)
            return false
        end
    end
    return false
end

local function DoUpdateFlash(dt)
    if _flash then
        _flashtime = _flashtime + dt
        if _flashtime < 3 / 60 then
            _flashcolour = Point(0, 0, 0)
            return true
        elseif _flashtime < 7 / 60 then
            _flashcolour = Point(_flashintensity, _flashintensity, _flashintensity)
            return true
        elseif _flashtime < 9 / 60 then
            _flashcolour = Point(0, 0, 0)
            return true
        elseif _flashtime < 17 / 60 then
            _flashcolour = Point(_flashintensity, _flashintensity, _flashintensity)
            return true
        elseif _flashtime < 107 / 60 then
            local k = (.5 + (_flashtime * 60 - 17) / 180) * _overridecolour.lightpercent
            _flashcolour = Point(_overridecolour.currentcolour.x * k, _overridecolour.currentcolour.y * k, _overridecolour.currentcolour.z * k)
            return true
        else
            _flash = false
            return false
        end
    end
    return false
end

function self:OnUpdate(dt)
    local continue = false
    continue = DoUpdate(dt, _realcolour) or continue
    continue = DoUpdate(dt, _overridecolour) or continue
    continue = DoUpdateFlash(dt) or continue
    PushCurrentColour()
    if not continue then
        Stop()
    end
end

function self:LongUpdate(dt)
    if _updating then
        _flash = false
        SetColour(_realcolour.currentcolour, _realcolour.lerptocolour)
        SetColour(_overridecolour.currentcolour, _overridecolour.lerptocolour)
        _realcolour.remainingtimeinlerp = 0
        _overridecolour.remainingtimeinlerp = 0
        PushCurrentColour()
        Stop()
    end
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
