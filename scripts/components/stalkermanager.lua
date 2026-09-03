--------------------------------------------------------------------------
--[[ StalkerManager class definition ]]
--------------------------------------------------------------------------

-- This component manages saving data for the fuelweaver quest line (since they spawn and despawn)
-- and also only having one stalker at a time
-- all worlds (forest and caves) have this component

return Class(function(self, inst)

assert(TheWorld.ismastersim, "RegrowthManager should not exist on client")

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------


--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _world = TheWorld
local _worldstate = TheWorld.state
local _map = TheWorld.Map

local _stalker
local _data = {}

local areas_to_chatter = {}
-- For searching:
--  not_first_spawn

-- 22 inspectables
-- 5 unique biomes
-- for full quest, 3 biomes and 10 inspectables needed?

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------




--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnRemoveStalker(sack)
    _stalker = nil
end

local function OnRegisterStalker(_, stalker)
    if BRANCH == "dev" then
        -- assert(_stalker == nil, "We already have a stalker, but we're trying to register another one.")
    end

    _stalker = stalker
    inst:ListenForEvent("onremove", OnRemoveStalker, stalker)
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:AddChatterArea(areadata)
    table.insert(areas_to_chatter, areadata)
end
-- to save data across instances of stalker
function self:GetData(var)
    return _data[var]
end

function self:SetData(var, val)
    _data[var] = val
end

function self:GetStalker()
    return _stalker
end

function self:StalkerExists()
    return _stalker ~= nil
end

function self:GetNumBiomesSeen()
    local c = 0
    for k, v in pairs(_data) do
        if v and k:find("seen_biome_") then
            c = c + 1
        end
    end
    return c
end

function self:GetNumInspected()
    local c = 0
    for k, v in pairs(_data) do
        if v and k:find("inspected_") then
            c = c + 1
        end
    end
    return c
end

-- TODO
function self:GetFriendshipLevel() -- 1 - 5
    local biomes_seen = 0
    local inspected_num = 0
    if inspected_num >= 12 and biomes_seen >= 3 then
        return 5
    elseif inspected_num >= 8 and biomes_seen >= 2 then
        return 4
    elseif inspected_num >= 6 and biomes_seen >= 1 then
        return 3
    elseif inspected_num >= 4 then
        return 2
    elseif inspected_num >= 3 then
        return 1
    end
end

function self:Debug_ResetData()
    _data = {}
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Initialize variables

self:AddChatterArea({
    id = "vault",
    testfn = function(inst, task_id, room_id) return task_id and task_id:find("Vault") end,
})
self:AddChatterArea({
    id = "atrium",
    testfn = function(inst, task_id, room_id) return task_id and task_id:find("Atrium") end,
})
self:AddChatterArea({
    id = "ruins",
    testfn = function(inst, task_id, room_id) return task_id and (task_id:find("Sacred") or task_id:find("Military") or task_id:find("Labyrinth")) and (room_id == nil or (not room_id:find("PitRoom") and not room_id:find("BridgeEntrance"))) end,
})
self:AddChatterArea({
    id = "archives",
    -- MoonMush check is here for Retrofitted Archives (Entire Grotto + Archives retrofit is marked with AncientArchivesRetrofit for task name)
    -- ArchiveMazeEntrance is not actually the archive, its a grotto room that acts as a connection.
    testfn = function(inst, task_id, room_id) return task_id and room_id and task_id:find("Archive") and not room_id:find("MoonMush") and not room_id:find("ArchiveMazeEntrance") end,
})
self:AddChatterArea({
    id = "lunar_grotto",
    -- MoonMush check is here for Retrofitted Archives (Entire Grotto + Archives retrofit is marked with AncientArchivesRetrofit for task name)
    -- ArchiveMazeEntrance is not actually the archive, its a grotto room that acts as a connection.
    testfn = function(inst, task_id, room_id) return room_id and room_id:find("MoonMush") end,
})

--Register events
inst:ListenForEvent("ms_registerstalker", OnRegisterStalker, _world)

--------------------------------------------------------------------------
--[[ Update ]]
--------------------------------------------------------------------------



--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    if next(_data) ~= nil then
        return { stalkerdata = _data }
    end
end

function self:OnLoad(data)
    if data ~= nil then
        if data.stalkerdata then
            _data = data.stalkerdata
        end
    end
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()

end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)