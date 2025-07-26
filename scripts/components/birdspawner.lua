--------------------------------------------------------------------------
--[[ BirdSpawner class definition ]]
--------------------------------------------------------------------------

local SourceModifierList = require("util/sourcemodifierlist")

return Class(function(self, inst)

assert(TheWorld.ismastersim, "BirdSpawner should not exist on client")

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

--Note: in winter, 'robin' is replaced with 'robin_winter' automatically
local BIRD_TYPES =
{
    --[WORLD_TILES.IMPASSABLE] = { "" },
    --[WORLD_TILES.ROAD] = { "crow" },
    [WORLD_TILES.ROCKY] = { "crow" },
    [WORLD_TILES.DIRT] = { "crow" },
    [WORLD_TILES.SAVANNA] = { "robin", "crow" },
    [WORLD_TILES.GRASS] = { "robin" },
    [WORLD_TILES.FOREST] = { "robin", "crow" },
    [WORLD_TILES.MARSH] = { "crow" },

    [WORLD_TILES.OCEAN_COASTAL] = {"puffin"},
    [WORLD_TILES.OCEAN_COASTAL_SHORE] = {"puffin"},
    [WORLD_TILES.OCEAN_SWELL] = {"puffin"},
    [WORLD_TILES.OCEAN_ROUGH] = {"puffin"},
    [WORLD_TILES.OCEAN_BRINEPOOL] = {"puffin"},
    [WORLD_TILES.OCEAN_HAZARDOUS] = {"puffin"},
    [WORLD_TILES.OCEAN_WATERLOG] = {},
}

local LUNARHAIL_EVENT_TIMER = "lunarhailbirdtimer"
local LUNARHAIL_PRE_EVENT_TIMER = "lunarhailprebirdtimer"

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _activeplayers = {}
local _scheduledtasks = {}
local _worldstate = TheWorld.state
local _map = TheWorld.Map
local _groundcreep = TheWorld.GroundCreep
local _updating = false
local _birds = {}
local _maxbirds = TUNING.BIRD_SPAWN_MAX
local _minspawndelay = TUNING.BIRD_SPAWN_DELAY.min
local _maxspawndelay = TUNING.BIRD_SPAWN_DELAY.max

local _maxcorpses = TUNING.BIRD_CORPSE_SPAWN_MAX
local _corpse_min_count = TUNING.BIRD_CORPSE_MIN_SPAWN
local _corpse_max_count = TUNING.BIRD_CORPSE_MAX_SPAWN
local _corpse_mutate_count = TUNING.BIRD_CORPSE_MUTATE_MAX_COUNT
local _corpse_fade_min_time = TUNING.BIRD_CORPSE_FADE_MIN_TIME
local _corpse_fade_max_time = TUNING.BIRD_CORPSE_FADE_MAX_TIME

local _corpse_gestalt_min_time = TUNING.BIRD_CORPSE_GESTALT_MIN_TIME
local _corpse_gestalt_max_time = TUNING.BIRD_CORPSE_GESTALT_MAX_TIME

local _timescale = 1 --Deprecated. Don't remove in case any mods are upvalue hacking this value
local _timescale_modifiers = SourceModifierList(self.inst, 1, SourceModifierList.multiply)

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function CalcValue(player, basevalue, modifier)
	local ret = basevalue
	local attractor = player and player.components.birdattractor
	if attractor then
		ret = ret + attractor.spawnmodifier:CalculateModifierFromKey(modifier)
	end
	return ret
end

local function GetSpawnPointAndSpawnBird(pt, ignorebait, is_corpse)
    local spawnpoint = self:GetSpawnPoint(pt, is_corpse)
    if spawnpoint ~= nil then
        return self:SpawnBird(spawnpoint, ignorebait, is_corpse)
    end
end

local CORPSE_MUST_TAGS = {"birdcorpse"}
local function SpawnCorpseForPlayer(player)
    local pt = player:GetPosition()
    local corpse_count = TheSim:CountEntities(pt.x, pt.y, pt.z, 64, CORPSE_MUST_TAGS)
    if corpse_count < _maxcorpses then
        return GetSpawnPointAndSpawnBird(pt, nil, true)
    end
end

local BIRD_MUST_TAGS = { "bird" }
local function SpawnBirdForPlayer(player, reschedule)
    local pt = player:GetPosition()
    local bird_count = TheSim:CountEntities(pt.x, pt.y, pt.z, 64, BIRD_MUST_TAGS)
    if bird_count < CalcValue(player, _maxbirds, "maxbirds") then
        GetSpawnPointAndSpawnBird(pt)
    end
    _scheduledtasks[player] = nil
    reschedule(player)
end

local function ScheduleSpawn(player, initialspawn)
    if _scheduledtasks[player] == nil then
		local mindelay = CalcValue(player, _minspawndelay, "mindelay")
		local maxdelay = CalcValue(player, _maxspawndelay, "maxdelay")
        local lowerbound = initialspawn and 0 or mindelay
        local upperbound = initialspawn and (maxdelay - mindelay) or maxdelay
        _scheduledtasks[player] = player:DoTaskInTime(GetRandomMinMax(lowerbound, upperbound) * _timescale_modifiers:Get(), SpawnBirdForPlayer, ScheduleSpawn)
    end
end

local function CancelSpawn(player)
    if _scheduledtasks[player] ~= nil then
        _scheduledtasks[player]:Cancel()
        _scheduledtasks[player] = nil
    end
end

local function CanBirdsSpawn()
    return not _worldstate.isnight and _maxbirds > 0 and not _worldstate.islunarhailing
end

local function ToggleUpdate(force)
    if CanBirdsSpawn() then
        if not _updating then
            _updating = true
            for i, v in ipairs(_activeplayers) do
                ScheduleSpawn(v, true)
            end
        elseif force then
            for i, v in ipairs(_activeplayers) do
                CancelSpawn(v)
                ScheduleSpawn(v, true)
            end
        end
    elseif _updating then
        _updating = false
        for i, v in ipairs(_activeplayers) do
            CancelSpawn(v)
        end
    end
end

local SCARECROW_TAGS = { "scarecrow" }
local CARNIVAL_EVENT_ONEOF_TAGS = { "carnivaldecor", "carnivaldecor_ranker" }
local function PickBird(spawnpoint)
    local bird = "crow"
	if TheNet:GetServerGameMode() == "quagmire" then
		bird = "quagmire_pigeon"
	else
	    local tile = _map:GetTileAtPoint(spawnpoint:Get())
		if BIRD_TYPES[tile] ~= nil then
			bird = GetRandomItem(BIRD_TYPES[tile])
		end

		if IsSpecialEventActive(SPECIAL_EVENTS.CARNIVAL) and bird ~= "crow" and IsLandTile(tile) then
			local x, y, z = spawnpoint:Get()
			if TheSim:CountEntities(x, y, z, TUNING.BIRD_CANARY_LURE_DISTANCE, nil, nil, CARNIVAL_EVENT_ONEOF_TAGS) > 0 then
				bird = "crow"
			end
		elseif bird == "crow" then
			local x, y, z = spawnpoint:Get()
			if TheSim:CountEntities(x, y, z, TUNING.BIRD_CANARY_LURE_DISTANCE, SCARECROW_TAGS) > 0 then
				bird = "canary"
			end
		end
	end

    return _worldstate.iswinter and bird == "robin" and "robin_winter" or bird
end

local DANGER_RANGE = 8
local SCARYTOPREY_TAGS = { "scarytoprey" }
local function IsDangerNearby(x, y, z)
    return TheSim:CountEntities(x, y, z, DANGER_RANGE, SCARYTOPREY_TAGS) > 0
end

local function AutoRemoveTarget(inst, target)
    if _birds[target] ~= nil and target:IsAsleep() then
        target:Remove()
    end
end

local function ClearLunarBirdEventTimer()
    inst.components.timer:StopTimer(LUNARHAIL_EVENT_TIMER)
end

local function OnLunarBirdEvent(inst)
    for _, player in ipairs(_activeplayers) do
        local corpse_bird_count = math.random(_corpse_min_count, _corpse_max_count)
        local mutate_bird_count = math.random(_corpse_mutate_count)

        local function SpawnBirdCorpse(_, mutate)
            local corpse = SpawnCorpseForPlayer(player)
            if corpse then
                if mutate then
                    corpse:StartGestaltTimer(GetRandomMinMax(_corpse_gestalt_min_time, _corpse_gestalt_max_time))
                else
                    corpse:StartFadeTimer(GetRandomMinMax(_corpse_fade_min_time, _corpse_fade_max_time))
                end
            end
        end

        for _ = 1, corpse_bird_count do
            inst:DoTaskInTime(math.random(), SpawnBirdCorpse)
        end

        for _ = 1, mutate_bird_count do
            inst:DoTaskInTime(math.random(), SpawnBirdCorpse, true)
        end

        local function AnnounceCorpses()
            player.components.talker:Say(GetString(player, "ANNOUNCE_LUNARHAIL_BIRD_CORPSES"))
        end
        inst:DoTaskInTime(2*math.random(), AnnounceCorpses)
    end
end

-- Players hear caws and screams in the sky
local function OnPreLunarBirdEvent(inst)
    for _, player in ipairs(_activeplayers) do
        player.components.talker:Say(GetString(player, "ANNOUNCE_LUNARHAIL_BIRD_SOUNDS"))
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnTargetSleep(target)
    inst:DoTaskInTime(0, AutoRemoveTarget, target)
end

local RAIN_FACTOR_KEY = "rainfactor"
local function OnIsRaining(inst, israining)
    if israining then
        _timescale_modifiers:SetModifier(inst, TUNING.BIRD_RAIN_FACTOR, RAIN_FACTOR_KEY)
    else
        _timescale_modifiers:RemoveModifier(inst, RAIN_FACTOR_KEY)
    end
end

local function OnIsLunarHailing(inst, ishailing)
    if ishailing then
        local bird_event_time = TUNING.LUNARHAIL_EVENT_TIME * GetRandomWithVariance(TUNING.LUNARHAIL_BIRD_EVENT, TUNING.LUNARHAIL_BIRD_EVENT_VARIANCE)
        if not inst.components.timer:TimerExists(LUNARHAIL_EVENT_TIMER) then --OnIsLunarHailing runs on load and timers already save
            inst.components.timer:StartTimer(LUNARHAIL_PRE_EVENT_TIMER, bird_event_time * 0.75)
            inst.components.timer:StartTimer(LUNARHAIL_EVENT_TIMER, bird_event_time)
        end
    else
        ClearLunarBirdEventTimer()
    end

    ToggleUpdate()
end

local function OnTimerDone(inst, data)
    if not data then
        return
    end

    if data.name == LUNARHAIL_PRE_EVENT_TIMER then
        OnPreLunarBirdEvent(inst)
    elseif data.name == LUNARHAIL_EVENT_TIMER then
        OnLunarBirdEvent(inst)
    end
end

local function OnPlayerJoined(src, player)
    for i, v in ipairs(_activeplayers) do
        if v == player then
            return
        end
    end
    table.insert(_activeplayers, player)
    if _updating then
        ScheduleSpawn(player, true)
    end
end

local function OnPlayerLeft(src, player)
    for i, v in ipairs(_activeplayers) do
        if v == player then
            CancelSpawn(player)
            table.remove(_activeplayers, i)
            return
        end
    end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Initialize variables
for i, v in ipairs(AllPlayers) do
    table.insert(_activeplayers, v)
end

--Register events
inst:WatchWorldState("islunarhailing", OnIsLunarHailing)
inst:WatchWorldState("israining", OnIsRaining)
inst:WatchWorldState("isnight", function() ToggleUpdate() end)
inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)
inst:ListenForEvent("timerdone", OnTimerDone, TheWorld)

--------------------------------------------------------------------------
--[[ Post initialization ]]
--------------------------------------------------------------------------

function self:OnPostInit()
    OnIsRaining(inst, _worldstate.israining)
    OnIsLunarHailing(inst, _worldstate.islunarhailing)
    ToggleUpdate(true)
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:SetSpawnTimes()
    --depreciated
end

function self:SetMaxBirds()
    --depreciated
end

function self:ToggleUpdate()
    ToggleUpdate(true)
end

function self:SpawnModeNever()
    --depreciated
end

function self:SpawnModeLight()
    --depreciated
end

function self:SpawnModeMed()
    --depreciated
end

function self:SpawnModeHeavy()
    --depreciated
end

local BIRDBLOCKER_TAGS = {"birdblocker"}
function self:GetSpawnPoint(pt, is_corpse)
    --We have to use custom test function because birds can't land on creep
    local function TestSpawnPoint(offset)
        local spawnpoint_x, spawnpoint_y, spawnpoint_z = (pt + offset):Get()
        if TheWorld.Map:IsPointInWagPunkArenaAndBarrierIsUp(spawnpoint_x, spawnpoint_y, spawnpoint_z) then
            return false
        end
        local allow_water = true
        local moonstorm = false
        if TheWorld.net.components.moonstorms and next(TheWorld.net.components.moonstorms:GetMoonstormNodes()) then
            local node_index = TheWorld.Map:GetNodeIdAtPoint(spawnpoint_x, 0, spawnpoint_z)
            local nodes = TheWorld.net.components.moonstorms._moonstorm_nodes:value()
            for i, node in pairs(nodes) do
                if node == node_index then
                    moonstorm = true
                    break
                end
            end
        end

        return _map:IsPassableAtPoint(spawnpoint_x, spawnpoint_y, spawnpoint_z, allow_water) and
               #(TheSim:FindEntities(spawnpoint_x, 0, spawnpoint_z, 4, BIRDBLOCKER_TAGS)) == 0 and
               --A corpse isn't gonna care if it's the moonstorm or on creep!
               (is_corpse or (not moonstorm and not _groundcreep:OnCreep(spawnpoint_x, spawnpoint_y, spawnpoint_z)))
    end

    local theta = math.random() * TWOPI
    local radius = 6 + math.random() * 6
    local resultoffset = FindValidPositionByFan(theta, radius, 12, TestSpawnPoint)

    if resultoffset ~= nil then
        return pt + resultoffset
    end
end

local BAIT_CANT_TAGS = { "INLIMBO", "outofreach" }

function self:SpawnBird(spawnpoint, ignorebait, is_corpse)
    local prefab = PickBird(spawnpoint)
    if prefab == nil then
        return
    end

    local bird = SpawnPrefab(is_corpse and "birdcorpse" or prefab)
    if math.random() < .5 then
        bird.Transform:SetRotation(180)
    end
    if is_corpse then
        bird:SetAltBuild(prefab)
        bird:SetAltBank(prefab) --banks have their unique bank
        bird._nameoverride:set(prefab)
        bird.displaynameoverride = prefab
    end
    if bird:HasTag("bird") or is_corpse then
        spawnpoint.y = 15
    end

    --see if there's bait nearby that we might spawn into
    --but if it's a corpse, i don't think they'll care for any bait :)
    if bird.components.eater and not ignorebait and not is_corpse then
		local bait = TheSim:FindEntities(spawnpoint.x, 0, spawnpoint.z, 15, nil, BAIT_CANT_TAGS)
        for k, v in pairs(bait) do
            local x, y, z = v.Transform:GetWorldPosition()
            if bird.components.eater:CanEat(v) and not v:IsInLimbo() and
                v.components.bait and
                not (v.components.inventoryitem and v.components.inventoryitem:IsHeld()) and
                not IsDangerNearby(x, y, z) and
                (bird.components.floater ~= nil or _map:IsPassableAtPoint(x, y, z)) then
                spawnpoint.x, spawnpoint.z = x, z
                bird.bufferedaction = BufferedAction(bird, v, ACTIONS.EAT)
                break
            elseif v.components.trap and
                v.components.trap.isset and
                (not v.components.trap.targettag or bird:HasTag(v.components.trap.targettag)) and
                not v.components.trap.issprung and
                math.random() < TUNING.BIRD_TRAP_CHANCE and
                not IsDangerNearby(x, y, z) then
                spawnpoint.x, spawnpoint.z = x, z
                break
            end
        end
    end

    bird.Physics:Teleport(spawnpoint:Get())

    return bird
end

function self.StartTrackingFn(target)
    if _birds[target] == nil then
        _birds[target] = target.persists == true
        target.persists = false
        inst:ListenForEvent("entitysleep", OnTargetSleep, target)
    end
end

function self:StartTracking(target)
    self.StartTrackingFn(target)
end

function self.StopTrackingFn(target)
    local restore = _birds[target]
    if restore ~= nil then
        target.persists = restore
        _birds[target] = nil
        inst:RemoveEventCallback("entitysleep", OnTargetSleep, target)
    end
end

function self:StopTracking(target)
    self.StopTrackingFn(target)
end

function self:SetBirdTypesForTile(tile_id, bird_list) -- Mods.
    BIRD_TYPES[tile_id] = bird_list -- Don't make me regret giving you access!
end

function self:SetTimeScaleModifier(factor, key) -- Mods.
    _timescale_modifiers:SetModifier(inst, factor, key)
end

function self:RemoveTimeScaleModifier(key)
    _timescale_modifiers:RemoveModifier(inst, key)
end

function self:SpawnCorpseForPlayer(player) --Wicker book
    return SpawnCorpseForPlayer(player)
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    local numbirds = 0
    for k, v in pairs(_birds) do
        numbirds = numbirds + 1
    end
    return string.format("birds:%d/%d", numbirds, _maxbirds)
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)