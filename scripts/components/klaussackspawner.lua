--------------------------------------------------------------------------
--[[ KlausSackSpawner class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "KlausSackSpawner should not exist on client")

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _spawners = {}
local _sack = nil
local _respawntask = nil

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function SpawnKlausSack()
    --print ("klaussack SpawnKlausSack")

    local numstructsatspawn = {}

    local x,y,z = nil, nil, nil
    for i,v in ipairs(_spawners) do
        x,y,z = TheWorld.Map:GetTileCenterPoint(v:GetPosition():Get())
        if not IsAnyPlayerInRange(x, y, z, 35) then
            local structs = TheSim:FindEntities(x,y,z, 5, {"structure"})
            if #structs == 0 then
                break
            end
            numstructsatspawn[v] = #structs
        end
        x = nil
    end

    if x == nil then
        local best_count = 200
        for spawner, structs in pairs(numstructsatspawn) do
            if structs < best_count then
                best_count = structs
                x,y,z = spawner.Transform:GetWorldPosition()
            end
        end 
    end

    if x ~= nil then
        local sack = SpawnPrefab("klaus_sack")
        local structs = TheSim:FindEntities(x,y,z, 1, {"structure"})
        for i,v in ipairs(structs) do
            if v.components.workable ~= nil then
                v.components.workable:Destroy(sack)
            else
                v:Remove()
            end
        end
        sack.Transform:SetPosition(x, y, z)
    end
end

local function StopRespawnTimer()
    if _respawntask ~= nil then
        _respawntask:Cancel()
        _respawntask = nil
    end
end

local function OnRespawnTimer()
    _respawntask = nil
    --print ("klaussack OnRespawnTimer", tostring(_sack))
    if _sack == nil then
        SpawnKlausSack()
    end
end

local function StartRespawnTimer(t)
    if _sack == nil or not _sack:IsValid() then
        StopRespawnTimer()
        --print "klaussack StartRespawnTimer"
        _respawntask = inst:DoTaskInTime(t or TUNING.KLAUSSACK_RESPAWN_TIME, OnRespawnTimer)
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------
local function OnRemoveSpawner(spawner)
    for i, v in ipairs(_spawners) do
        if v == spawner then
            table.remove(_spawners, i)
            return
        end
    end
end

local function OnRegisterSackSpawningPt(inst, spawner)
    for i, v in ipairs(_spawners) do
        if v == spawner then
            return
        end
    end

    table.insert(_spawners, spawner)
    inst:ListenForEvent("onremove", OnRemoveSpawner, spawner)
end

local function OnUnregisterSack(sack)
    --print ("klaussack OnUnregisterSack", sack)
    self.inst:RemoveEventCallback("onremove", OnUnregisterSack, sack)
    _sack = nil
    StartRespawnTimer()
end

local function RegisterKlausSack(inst, sack)
    if _sack == nil or not _sack:IsValid() then
        --print ("klaussack RegisterKlausSack", sack)
        _sack = sack
        inst:ListenForEvent("onremove", OnUnregisterSack, sack)
    end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Register events
inst:ListenForEvent("ms_registerdeerspawningground", OnRegisterSackSpawningPt)
inst:ListenForEvent("ms_registerklaussack", RegisterKlausSack)

--------------------------------------------------------------------------
--[[ Post initialization ]]
--------------------------------------------------------------------------

function self:OnPostInit()
    if _sack == nil and _respawntask == nil then
        local starting_delay = TheWorld.state.isautumn and (TheWorld.state.autumnlength + math.random(4)) or TUNING.NO_BOSS_TIME
        --print ("klaussack OnPostInit:", TheWorld.state.isautumn, TheWorld.state.autumnlength)
        StartRespawnTimer(starting_delay * TUNING.TOTAL_DAY_TIME)
    end
end

--------------------------------------------------------------------------
--[[ Update ]]
--------------------------------------------------------------------------

function self:LongUpdate(dt)
    if _respawntask ~= nil then
        local t = GetTaskRemaining(_respawntask)
        if t > dt then
            StartRespawnTimer(t - dt)
        else
            StopRespawnTimer()
            OnRespawnTimer()
        end
    end
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    local data = {}
    if _respawntask ~= nil then
        data.timetorespawn = math.ceil(GetTaskRemaining(_respawntask))
    end
    return data
end

function self:OnLoad(data)
    if data ~= nil and data.timetorespawn ~= nil then
        StartRespawnTimer(data.timetorespawn)
    else
        StopRespawnTimer()
    end
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    local s = ""
    if _sack ~= nil and _sack:IsValid() then
        s = "Klaus Sack is in the world."
    else
        s = string.format("Respawning in %.2f (%.2f days)", GetTaskRemaining(_respawntask), GetTaskRemaining(_respawntask) / TUNING.TOTAL_DAY_TIME)
    end
    return s
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
