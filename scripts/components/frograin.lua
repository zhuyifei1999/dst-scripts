--------------------------------------------------------------------------
--[[ FrogRain class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "FrogRain should not exist on client")

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
local _frogs = {}
local _frogcap = TUNING.FROG_RAIN_MAX
local _spawntime = TUNING.FROG_RAIN_DELAY
local _updating = false

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function GetSpawnPoint(pt)
    local function TestSpawnPoint(offset)
        local spawnpoint = pt + offset
        return _map:IsPassableAtPoint(spawn_point:Get())
    end

    local theta = math.random() * 2 * PI
    local radius = math.random() * TUNING.FROG_RAIN_SPAWN_RADIUS
    local resultoffset = FindValidPositionByFan(theta, radius, 12, TestSpawnPoint)

    if resultoffset ~= nil then
        return pt + resultoffset
    end
end

local function SpawnFrog(spawn_point)
    local frog = SpawnPrefab("frog")
    if math.random() < .5 then
        frog.Transform:SetRotation(180)
    end
    frog.sg:GoToState("fall")
    frog.Physics:Teleport(spawn_point.x, 35, spawn_point.z)
    return frog
end

local function SpawnFrogForPlayer(player, reschedule)
    local pt = player:GetPosition()
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, TUNING.FROG_RAIN_MAX_RADIUS, { "frog" })
    if #ents < _frogcap then
        local spawn_point = GetSpawnPoint(pt)
        if spawn_point ~= nil then
            local frog = SpawnFrog(spawn_point)
            self:StartTracking(frog)
        end
    end
    _scheduledtasks[player] = nil
    reschedule(player)
end

local function ScheduleSpawn(player, initialspawn)
    if _scheduledtasks[player] == nil and _spawntime ~= nil then
        local lowerbound = _spawntime.min
        local upperbound = _spawntime.max
        _scheduledtasks[player] = player:DoTaskInTime(GetRandomMinMax(lowerbound, upperbound), SpawnFrogForPlayer, ScheduleSpawn)
    end
end

local function CancelSpawn(player)
    if _scheduledtasks[player] ~= nil then
        _scheduledtasks[player]:Cancel()
        _scheduledtasks[player] = nil
    end
end

local function ToggleUpdate(force)
    if SaveGameIndex:GetCurrentMode() == "adventure" and 
        _worldstate.israining and
        _worldstate.precipitationrate > TUNING.FROG_RAIN_PRECIPITATION and
        _worldstate.moistureceil > TUNING.FROG_RAIN_MOISTURE then
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

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnIsRaining(inst, israining)
    if israining then
        _frogcap = math.random(10, TUNING.FROG_RAIN_LOCAL_MAX)
    end
    ToggleUpdate()
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
inst:WatchWorldState("israining", OnIsRaining)
inst:WatchWorldState("precipitationrate", ToggleUpdate)
inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)

ToggleUpdate(true)

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:SetSpawnTimes(times)
    _spawntime = times
    ToggleUpdate(true)
end

function self:SetMaxFrogs(max)
    _frogcap = max
end

function self:StartTracking(inst)
    _frogs[inst] = true
end

--V2C: FIXME: nobody calls this ever... c'mon...
function self:StopTracking(inst)
    _frogs[inst] = nil
end

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    return
    {
        frogcap = _frogcap,
        spawntime = _spawntime,
    }
end

function self:OnLoad(data)
    _frogcap = data.frogcap or TUNING.FROG_RAIN_MAX
    _spawntime = data.spawntime or TUNING.FROG_RAIN_DELAY

    ToggleUpdate(true)
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    local frog_count = 0
    for k, v in pairs(_frogs) do
        frog_count = frog_count + 1
    end
    return string.format("Frograin: %d/%d, next in %ds min: %2.2f max:%2.2f", frog_count, _frogcap, _timetospawn, _spawntime.min, _spawntime.max)
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)