--------------------------------------------------------------------------
--[[ LunarHailBirdSoundManager class definition ]]
--------------------------------------------------------------------------

--Handled by birdmanager.lua
return Class(function(self, inst)

local _world = TheWorld
local _map = _world.Map

local HAIL_BIRD_SOUND_NAME = "hailbirdsoundname"

self.inst = inst

self.birds_dropping_param = net_tinybyte(self.inst.GUID, "lunarhailbirdsoundmanager.birds_dropping", "hailbirddirty")
self.birds_dropping_param:set(0)

self.sound_level = 0

-- Common.

--[[
0 = no sound
1 = first level of hail bird event sound
2 = second level of hail bird event sound (corpses are dropping)
]]

local function PlaySoundLevel(level)
    if level == 0 then
        TheFocalPoint.SoundEmitter:KillSound(HAIL_BIRD_SOUND_NAME)
    else
        if not TheFocalPoint.SoundEmitter:PlayingSound(HAIL_BIRD_SOUND_NAME) then
            TheFocalPoint.SoundEmitter:PlaySound("lunarhail_event/amb/gestalt_attack_storm", HAIL_BIRD_SOUND_NAME)
        end
        TheFocalPoint.SoundEmitter:SetParameter(HAIL_BIRD_SOUND_NAME, "birds_dropping", level)
    end
end

local function OnHailBirdDirty()
    PlaySoundLevel(self.birds_dropping_param:value())
end

if not _world.ismastersim then
    inst:ListenForEvent("hailbirddirty", OnHailBirdDirty)
end

-- Server.

function self:SetLevel(level)
    self.sound_level = level
    self.birds_dropping_param:set(level)

    if not TheNet:IsDedicated() then --Server doesn't need to play sound
        PlaySoundLevel(self.sound_level)
    end
end

end)