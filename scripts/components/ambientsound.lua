--------------------------------------------------------------------------
--[[ AmbientSound class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

local easing = require("easing")

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local HALF_TILES = 5
local MAX_MIX_SOUNDS = 3
local WAVE_VOLUME_SCALE = 3 / (HALF_TILES * HALF_TILES * 8)
local WAVE_SOUND = "dontstarve/ocean/waves"
local WINTER_WAVE_SOUND = "dontstarve/winter/winterwaves"
local SANITY_SOUND = "dontstarve/sanity/sanity"

local AMBIENT_SOUNDS =
{
    [GROUND.ROAD] = { sound = "dontstarve/rocky/rockyAMB", wintersound = "dontstarve/winter/winterrockyAMB", rainsound = "dontstarve/rain/rainrockyAMB" },
    [GROUND.ROCKY] = { sound = "dontstarve/rocky/rockyAMB", wintersound = "dontstarve/winter/winterrockyAMB", rainsound = "dontstarve/rain/rainrockyAMB" },
    [GROUND.DIRT] = { sound = "dontstarve/badland/badlandAMB", wintersound = "dontstarve/winter/winterbadlandAMB", rainsound = "dontstarve/rain/rainbadlandAMB" },
    [GROUND.WOODFLOOR] = { sound = "dontstarve/rocky/rockyAMB", wintersound = "dontstarve/winter/winterrockyAMB", rainsound = "dontstarve/rain/rainrockyAMB" },
    [GROUND.SAVANNA] = { sound = "dontstarve/grassland/grasslandAMB", wintersound = "dontstarve/winter/wintergrasslandAMB", rainsound = "dontstarve/rain/raingrasslandAMB" },
    [GROUND.GRASS] = { sound = "dontstarve/meadow/meadowAMB", wintersound = "dontstarve/winter/wintermeadowAMB", rainsound = "dontstarve/rain/rainmeadowAMB" },
    [GROUND.FOREST] = { sound = "dontstarve/forest/forestAMB", wintersound = "dontstarve/winter/winterforestAMB", rainsound = "dontstarve/rain/rainforestAMB" },
    [GROUND.MARSH] = { sound = "dontstarve/marsh/marshAMB", wintersound = "dontstarve/winter/wintermarshAMB", rainsound = "dontstarve/rain/rainmarshAMB" },
    [GROUND.CHECKER] = { sound = "dontstarve/chess/chessAMB", wintersound = "dontstarve/winter/winterchessAMB", rainsound = "dontstarve/rain/rainchessAMB" },
    [GROUND.CAVE] = { sound = "dontstarve/cave/caveAMB" },

    [GROUND.FUNGUS] = { sound = "dontstarve/cave/fungusforestAMB" },
    [GROUND.FUNGUSRED] = { sound = "dontstarve/cave/fungusforestAMB" },
    [GROUND.FUNGUSGREEN] = { sound = "dontstarve/cave/fungusforestAMB" },

    [GROUND.SINKHOLE] = { sound = "dontstarve/cave/litcaveAMB" },
    [GROUND.UNDERROCK] = { sound = "dontstarve/cave/caveAMB" },
    [GROUND.MUD] = { sound = "dontstarve/cave/fungusforestAMB" },
    [GROUND.UNDERGROUND] = { sound = "dontstarve/cave/caveAMB" },
    [GROUND.BRICK] = { sound = "dontstarve/cave/ruinsAMB" },
    [GROUND.BRICK_GLOW] = { sound = "dontstarve/cave/ruinsAMB" },
    [GROUND.TILES] = { sound = "dontstarve/cave/civruinsAMB" },
    [GROUND.TILES_GLOW] = { sound = "dontstarve/cave/civruinsAMB" },
    [GROUND.TRIM] = { sound = "dontstarve/cave/ruinsAMB" },
    [GROUND.TRIM_GLOW] = { sound = "dontstarve/cave/ruinsAMB" },

    ABYSS = { sound = "dontstarve/cave/pitAMB" },
    VOID = { sound = "dontstarve/chess/void", wintersound = "dontstarve/chess/void", rainsound = "dontstarve/chess/void" },
    CIVRUINS = { sound = "dontstarve/cave/civruinsAMB" },
}

local DAYTIME_PARAMS =
{
    day = 1,
    dusk = 1.5,
    night = 2,
}

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _map = inst.Map
local _iscave = inst:HasTag("cave")
local _lightattenuation = false
local _wintermix = false
local _rainmix = false
local _lastplayerpos = nil
local _daytimeparam = 1
local _sanityparam = 0
local _soundvolumes = {}
local _wavessound = WAVE_SOUND
local _wavesvolume = 0
local _ambientvolume = 1
local _tileoverrides = {}
local _dspstack = {}
local _dspcomp = {}

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function SortByCount(a, b)
    return a.count > b.count
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnPrecipitationChanged(src, preciptype)
    if _rainmix ~= (preciptype == "rain") then
        _rainmix = not _rainmix
        _lastplayerpos = nil
    end
end

local function OnOverrideAmbientSound(src, data)
    _tileoverrides[data.tile] = data.override
end

local function OnSetAmbientSoundDaytime(src, daytime)
    if _daytimeparam ~= daytime and daytime ~= nil then
        _daytimeparam = daytime

        for k, v in pairs(_soundvolumes) do
            if v > 0 then
                inst.SoundEmitter:SetParameter(k, "daytime", daytime)
            end
        end
    end
end

local function OnRefreshDSP(src, duration)
    local dsp = {}
    duration = duration or 0

    for i, v in ipairs(_dspstack) do
        for k, v1 in pairs(v) do
            dsp[k] = v1
        end
    end

    for k, v in pairs(dsp) do
        if v ~= _dspcomp[k] then
            TheMixer:SetLowPassFilter(k, v, duration)
        end
    end

    for k, v in pairs(_dspcomp) do
        if dsp[k] == nil then
            TheMixer:ClearLowPassFilter(k, duration)
        end
    end

    _dspcomp = dsp
end

local function OnPushDSP(src, data)
    table.insert(_dspstack, data.dsp)
    OnRefreshDSP(data.duration)
end

local function OnPopDSP(src, data)
    for i = #_dspstack, 1, -1 do
        if _dspstack[i] == data.dsp then
            table.remove(_dspstack, i)
            OnRefreshDSP(data.duration)
            return
        end
    end
end

local function OnPhaseChanged(src, phase)
    _lightattenuation = phase ~= "day"
    OnSetAmbientSoundDaytime(src, DAYTIME_PARAMS[phase])
end

local function OnSeasonTick(src, data)
    if _wintermix ~= (data.season == "winter") then
        _wintermix = not _wintermix
        _lastplayerpos = nil

        if _wavesvolume <= 0 then
            _wavessound = _wintermix and WINTER_WAVE_SOUND or WAVE_SOUND
        end
    end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Register events
inst:ListenForEvent("overrideambientsound", OnOverrideAmbientSound)
inst:ListenForEvent("setambientsounddaytime", OnSetAmbientSoundDaytime)
inst:ListenForEvent("refreshdsp", OnRefreshDSP)
inst:ListenForEvent("pushdsp", OnPushDSP)
inst:ListenForEvent("popdsp", OnPopDSP)
inst:ListenForEvent("seasontick", OnSeasonTick)
inst:ListenForEvent("precipitationchanged", OnPrecipitationChanged)

TheSim:SetReverbPreset(_iscave and "cave" or "default")

inst.SoundEmitter:PlaySound(SANITY_SOUND, "SANITY")
inst.SoundEmitter:SetParameter("SANITY", "sanity", _sanityparam)

inst:StartUpdatingComponent(self)

--------------------------------------------------------------------------
--[[ Post initialization ]]
--------------------------------------------------------------------------

function self:OnPostInit()
    --Start the right sounds and give a large enough timestep to finish
    --any initial fading immediately
    self:OnUpdate(20)
end

--------------------------------------------------------------------------
--[[ Update ]]
--------------------------------------------------------------------------

function self:OnUpdate(dt)
    local player = ThePlayer
    local soundvolumes = nil
    local totalsoundcount = 0
    local wavesvolume = _wavesvolume
    local ambientvolume = _ambientvolume

    --Update the ambient mix based upon the player's surroundings
    --Only update if we've actually walked somewhere new
    --HACK: V2C: use camera pos when there's no player
    local playerpos = player ~= nil and Vector3(player.Transform:GetWorldPosition()) or Vector3(0, 0, 0)
    if _lastplayerpos == nil or _lastplayerpos:DistSq(playerpos) >= 16 then
        local x, y = _map:GetTileCoordsAtPoint(playerpos:Get())
        local wavecount = 0
        local soundmixcounters = {}
        local soundmix = {}

        for x1 = -HALF_TILES, HALF_TILES do
            for y1 = -HALF_TILES, HALF_TILES do
                local tile = _map:GetTile(x + x1, y + y1)
                tile = _tileoverrides[tile] or tile
                if tile == GROUND.IMPASSABLE then
                    wavecount = wavecount + 1
                elseif tile ~= nil then
                    local sound = AMBIENT_SOUNDS[tile]
                    if sound ~= nil then
                        sound = (_wintermix and sound.wintersound) or
                                (_rainmix and sound.rainsound) or
                                sound.sound
                        local counter = soundmixcounters[sound]
                        if counter == nil then
                            counter = { sound = sound, count = 1 }
                            soundmixcounters[sound] = counter
                            table.insert(soundmix, counter)
                        else
                            counter.count = counter.count + 1
                        end
                    end
                end
            end
        end

        _lastplayerpos = playerpos

        --Sort by highest count and truncate soundmix to MAX_MIX_SOUNDS
        table.sort(soundmix, SortByCount)
        soundmix[MAX_MIX_SOUNDS + 1] = nil
        soundvolumes = {}

        for i, v in ipairs(soundmix) do
            totalsoundcount = totalsoundcount + v.count
            soundvolumes[v.sound] = v.count
        end

        wavesvolume = _iscave and 0 or math.min(math.max(wavecount * WAVE_VOLUME_SCALE, 0), 1)
    end

    --Night/dusk ambience is attenuated in the light
    if _lightattenuation and player ~= nil and player.LightWatcher ~= nil then
        local lightval = player.LightWatcher:GetLightValue()
        local highlight = .9
        local lowlight = .2
        local lowvolume = .5
        ambientvolume = (lightval > highlight and lowvolume) or
                        (lightval < lowlight and 1) or
                        easing.outCubic(lightval - lowlight, 1, lowvol - 1, highlight - lowlight)
    elseif ambientvolume < 1 then
        ambientvolume = math.min(ambientvolume + dt * .05, 1)
    end

    if (_wavessound == WINTER_WAVE_SOUND) ~= _wintermix then
        if _wavesvolume > 0 then
            inst.SoundEmitter:KillSound("waves")
        end
        _wavessound = _wintermix and WINTER_WAVE_SOUND or WAVE_SOUND
        _wavesvolume = wavesvolume
        if wavesvolume > 0 then
            inst.SoundEmitter:PlaySound(_wavessound, "waves")
            inst.SoundEmitter:SetVolume("waves", wavesvolume)
        end
    elseif _wavesvolume ~= wavesvolume then
        if wavesvolume <= 0 then
            inst.SoundEmitter:KillSound("waves")
        else
            if _wavesvolume <= 0 then
                inst.SoundEmitter:PlaySound(_wavessound, "waves")
            end
            inst.SoundEmitter:SetVolume("waves", wavesvolume)
        end
        _wavesvolume = wavesvolume
    end

    if soundvolumes ~= nil then
        for k, v in pairs(_soundvolumes) do
            if soundvolumes[k] == nil then
                inst.SoundEmitter:KillSound(k)
            end
        end
        for k, v in pairs(soundvolumes) do
            local oldvol = _soundvolumes[k]
            local newvol = v / totalsoundcount
            if oldvol == nil then
                inst.SoundEmitter:PlaySound(k, k)
                inst.SoundEmitter:SetParameter(k, "daytime", _daytimeparam)
                inst.SoundEmitter:SetVolume(k, newvol * ambientvolume)
            elseif oldvol ~= newvol then
                inst.SoundEmitter:SetVolume(k, newvol * ambientvolume)
            end
            soundvolumes[k] = newvol
        end
        _soundvolumes = soundvolumes
        _ambientvolume = ambientvolume
    elseif _ambientvolume ~= ambientvolume then
        for k, v in pairs(_soundvolumes) do
            inst.SoundEmitter:SetVolume(k, v * ambientvolume)
        end
        _ambientvolume = ambientvolume
    end

    local sanityparam = player ~= nil and player.components.sanity ~= nil and (1 - player.components.sanity:GetPercent()) or 0
    if _sanityparam ~= sanityparam then
        inst.SoundEmitter:SetParameter("SANITY", "sanity", sanityparam)
        _sanityparam = sanityparam
    end
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    local str = {}
    
    table.insert(str, "AMBIENT SOUNDS:")
    table.insert(str, string.format("atten=%2.2f, day=%2.2f, waves=%2.2f", _ambientvolume, _daytimeparam, _wavesvolume))
    
    for k, v in pairs(_soundvolumes) do
        table.insert(str, string.format("\t%s = %2.2f", k, v))
    end

    return table.concat(str, "\n")
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)