
--------------------------------------------------------------------------
--[[ Malbatross spawner class definition ]]
--------------------------------------------------------------------------
return Class(function(self, inst)

assert(TheWorld.ismastersim, "Malbatross spawner should not exist on the client")

--------------------------------------------------------------------------
--[[ Private constants ]]
--------------------------------------------------------------------------

local MALBATROSS_SPAWN_DIST = 10
local MALBATROSS_PLAYER_SPAWN_DISTSQ = 400 -- 20 * 20
local SHOAL_PERCENTAGE_TO_TEST = 0.25
local MALBATROSS_SPAWNDELAY = { BASE = 10, RANDOM = 5 }

--------------------------------------------------------------------------
--[[ Public Member Variables ]]
--------------------------------------------------------------------------

self.inst = inst

--------------------------------------------------------------------------
--[[ Private Member Variables ]]
--------------------------------------------------------------------------

local _fishshoals = {}
local _firstspawn = true
local _shuffled_shoals_for_spawning = nil
local _time_until_spawn = nil
local _activemalbatross = nil

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function SummonMalbatross(target_shoal, the_malbatross)
    assert(target_shoal ~= nil)

    the_malbatross = the_malbatross or
            TheSim:FindFirstEntityWithTag("malbatross") or 
            SpawnPrefab("malbatross")

    _firstspawn = false

    local shoal_position = target_shoal:GetPosition()
    local spawn_offset = FindSwimmableOffset(shoal_position, math.random() * 2 * PI, MALBATROSS_SPAWN_DIST, 12, true, false, nil, true)
    local spawn_position = (spawn_offset and shoal_position + spawn_offset) or shoal_position

    if the_malbatross ~= nil then
        the_malbatross.Physics:Teleport(spawn_position:Get())
        the_malbatross.components.knownlocations:RememberLocation("home", shoal_position)
        the_malbatross.components.entitytracker:TrackEntity("feedingshoal", target_shoal)

        the_malbatross.sg:GoToState("arrive")

        return the_malbatross
    else
        return nil
    end
end

local function TryBeginningMalbatrossSpawns()
    if next(_fishshoals) ~= nil then
        _time_until_spawn = _time_until_spawn or
                (_firstspawn and 0) or
                (TUNING.TOTAL_DAY_TIME * GetRandomWithVariance(MALBATROSS_SPAWNDELAY.BASE, MALBATROSS_SPAWNDELAY.RANDOM))

        _shuffled_shoals_for_spawning = _shuffled_shoals_for_spawning or
                shuffledKeys(_fishshoals)

        self.inst:StartUpdatingComponent(self)
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnFishShoalRemoved(fish_shoal)
    _fishshoals[fish_shoal] = nil
    if _shuffled_shoals_for_spawning then
        -- If a shoal got removed while we're waiting for a player to approach a shoal to spawn,
        -- just regenerate our shuffled list. Basically equivalently random.
        _shuffled_shoals_for_spawning = shuffledKeys(_fishshoals)
    end
end

local function OnFishShoalAdded(source, fish_shoal)
    if not _fishshoals[fish_shoal] then
        _fishshoals[fish_shoal] = true
        self.inst:ListenForEvent("onremove", OnFishShoalRemoved, fish_shoal)
        if not _activemalbatross then
            TryBeginningMalbatrossSpawns()
        end
    end
end

local function OnMalbatrossKilledOrRemoved(source, the_malbatross)
    _activemalbatross = nil
    TryBeginningMalbatrossSpawns()
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:OnUpdate(dt)
    if _time_until_spawn == nil then
        self.inst:StopUpdatingComponent(self)
    elseif _time_until_spawn > 0 then
        _time_until_spawn = _time_until_spawn - dt
    elseif _shuffled_shoals_for_spawning and #_shuffled_shoals_for_spawning > 0 then
        local max_shoals_to_test = math.ceil(#_shuffled_shoals_for_spawning * SHOAL_PERCENTAGE_TO_TEST)

        for i, shoal in ipairs(_shuffled_shoals_for_spawning) do
            local sx, sy, sz = shoal.Transform:GetWorldPosition()
            if FindClosestPlayerInRangeSq(sx, sy, sz, MALBATROSS_PLAYER_SPAWN_DISTSQ, true) then
                _activemalbatross = SummonMalbatross(shoal)

                _shuffled_shoals_for_spawning = nil
                _time_until_spawn = nil
                self.inst:StopUpdatingComponent(self)
            end

            if i == max_shoals_to_test then
                break
            end
        end
    end
end

function self:Relocate(target_malbatross)
    if next(_fishshoals) ~= nil then
        _shuffled_shoals_for_spawning = shuffledKeys(_fishshoals)
        _time_until_spawn = 0

        if target_malbatross then
            -- If a target was passed in, swap our current shoal to the end of the shuffled list,
            -- so it won't be picked (unless somebody modifies the spawn percentage!).
            local feedingshoal = target_malbatross.components.entitytracker:GetEntity("feedingshoal")
            local n_shoal_keys = #_shuffled_shoals_for_spawning
            for i, shoal in ipairs(_shuffled_shoals_for_spawning) do
                if i ~= n_shoal_keys and shoal == feedingshoal then
                    _shuffled_shoals_for_spawning[i], _shuffled_shoals_for_spawning[n_shoal_keys] = _shuffled_shoals_for_spawning[n_shoal_keys], shoal
                    break
                end
            end

            -- Remove the one that was passed in, and let its OnRemove listener call TryBeginningMalbatrossSpawns
            target_malbatross:Remove()
        else
            TryBeginningMalbatrossSpawns()
        end
    end
end

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    local data = { 
        _time_until_spawn = _time_until_spawn,
        _firstspawn = _firstspawn,
    }

    if _activemalbatross ~= nil then
        data.activeguid = _activemalbatross.GUID

        local ents = {}
        table.insert(ents, _activemalbatross.GUID)
        return data, ents
    else
        return data
    end
end

function self:OnLoad(data)
    _time_until_spawn = data._time_until_spawn
    _firstspawn = data._firstspawn
end

function self:LoadPostPass(newents, data)
    if data.activeguid ~= nil and newents[data.activeguid] ~= nil then
        _activemalbatross = newents[data.activeguid].entity
    end
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    local s = nil
    if not _time_until_spawn then
        s = "DORMANT <no time>"
    elseif self.inst.updatecomponents[self] == nil then
        s = "DORMANT ".._time_until_spawn
    elseif _time_until_spawn > 0 then
        s = string.format("Malbatross is coming in %2.2f", _time_until_spawn)
    else
        s = string.format("Trying to spawn: %2.2f", _time_until_spawn)
    end

    -- append any more debug info here.
    local num_shoals = 0
    for shoal, _ in pairs(_fishshoals) do
        num_shoals = num_shoals + 1
    end
    s = s .. " || Number of tracked shoals: " .. num_shoals

    return s
end

function self:Summon(_slow_debug_target_entity)
    if _fishshoals and next(_fishshoals) ~= nil then
        if _slow_debug_target_entity == nil then
            _shuffled_shoals_for_spawning = shuffledKeys(_fishshoals)
        else
            -- This isn't particularly efficient (we're recalculating the distancesq in each sort test),
            -- but this route should NOT be the intended spawn method, and is for debug/test/fun spawning instead.
            _shuffled_shoals_for_spawning = {}
            for shoal, _ in pairs(_fishshoals) do
                table.insert(_shuffled_shoals_for_spawning, shoal)
            end
            table.sort(_shuffled_shoals_for_spawning, function(sa, sb)
                return sa:GetDistanceSqToInst(_slow_debug_target_entity) < sb:GetDistanceSqToInst(_slow_debug_target_entity)
            end)
        end

        _time_until_spawn = 5
        self.inst:StartUpdatingComponent(self)
    end
end


--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

self.inst:ListenForEvent("ms_registerfishshoal", OnFishShoalAdded, TheWorld)
self.inst:ListenForEvent("malbatrossremoved", OnMalbatrossKilledOrRemoved, TheWorld)
self.inst:ListenForEvent("malbatrosskilled", OnMalbatrossKilledOrRemoved, TheWorld)

end)