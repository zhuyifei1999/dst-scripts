--------------------------------------------------------------------------
--[[ Flotsam generator class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "Flotsam generator should not exist on client")

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

local SourceModifierList = require("util/sourcemodifierlist")

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local flotsam_prefabs =
{
    driftwood_log = 1,
    boatfragment03 = 0.3,
    boatfragment04 = 0.3,
    boatfragment05 = 0.3,
    cutgrass = 1,
    twigs = 1,
	oceanfishableflotsam_water = 1,
}

local RANGE = 40 -- distance from player to spawn the flotsam.  should be 5 more than wanted
local SHORTRANGE = 5 -- radius that must be clear for flotsam to appear

local LIFESPAN = {	base = TUNING.TOTAL_DAY_TIME *3,
					varriance = TUNING.TOTAL_DAY_TIME }

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
local _minspawndelay = TUNING.FLOTSAM_SPAWN_DELAY.min
local _maxspawndelay = TUNING.FLOTSAM_SPAWN_DELAY.max
local _updating = false
local _flotsam = {}
local _maxflotsam = TUNING.FLOTSAM_SPAWN_MAX
local _timescale = 1
local _flotsam = {}
--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function GetSpawnPoint(pt)
    if TheWorld.has_ocean then
        --We have to use custom test function because birds can't land on creep
        local function TestSpawnPoint(offset)
            local spawnpoint_x, spawnpoint_y, spawnpoint_z = (pt + offset):Get()
            local tile = _map:GetTileAtPoint(spawnpoint_x, spawnpoint_y, spawnpoint_z)
            local allow_water = true            
            return IsOceanTile(tile) and
                   tile ~= GROUND.OCEAN_COASTAL_SHORE and
                   #TheSim:FindEntities(spawnpoint_x, spawnpoint_y, spawnpoint_z, RANGE-SHORTRANGE, nil, nil, {"player","flotsam"}) <= 0 and
                   #TheSim:FindEntities(spawnpoint_x, spawnpoint_y, spawnpoint_z, SHORTRANGE, nil, {"INLIMBO","fx"}) <= 0 
        end

        local theta = math.random() * 2 * PI
        local radius = RANGE
        local resultoffset = FindValidPositionByFan(theta, radius, 12, TestSpawnPoint)

        if resultoffset ~= nil then
            return pt + resultoffset
        end
    end
end

local function SpawnFlotsamForPlayer(player, reschedule)

    local pt = player:GetPosition()
    if player:GetCurrentPlatform() then
        local spawnpoint = GetSpawnPoint(pt)
        if spawnpoint ~= nil then
            self:SpawnFlotsam(spawnpoint)
        end
    end
    _scheduledtasks[player] = nil
    reschedule(player)
end

local function ScheduleSpawn(player, initialspawn)  
    if _scheduledtasks[player] == nil  then
        local mindelay = _minspawndelay
        local maxdelay = _maxspawndelay
        local lowerbound = initialspawn and 0 or mindelay
        local upperbound = initialspawn and (maxdelay - mindelay) or maxdelay
        _scheduledtasks[player] = player:DoTaskInTime(GetRandomMinMax(lowerbound, upperbound) * _timescale, SpawnFlotsamForPlayer, ScheduleSpawn)
    end
end

local function CancelSpawn(player)
    if _scheduledtasks[player] ~= nil then
        _scheduledtasks[player]:Cancel()
        _scheduledtasks[player] = nil
    end
end

local function ToggleUpdate(force)
    if _maxflotsam > 0 then
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

local function PickFlotsam(spawnpoint)
    local item = weighted_random_choice(flotsam_prefabs)
    return item
end

local function AutoRemoveTarget(inst, target)
    if _flotsam[target] ~= nil and target:IsAsleep() then
        target:Remove()
    end
end

local function rememberflotsam(inst)
    _flotsam[inst] = true
end
local function forgetflotsam(inst)
    if _flotsam[inst] then
        _flotsam[inst] = nil
    end
end

local function OnTimerDone(inst, data)
    if data.name == "sink" then
        forgetflotsam(inst)

		if inst.overrideflotsamsinkfn ~= nil then
			inst:overrideflotsamsinkfn()
		else
			SpawnPrefab("splash_sink").Transform:SetPosition(inst.Transform:GetWorldPosition())
			inst:Remove()
		end
    end
end
local function clearflotsamtimer(inst)
    inst:RemoveTag("flotsam")
    inst.components.timer:StopTimer("sink")
    forgetflotsam(inst)
end
--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnTargetSleep(target)
    inst:DoTaskInTime(0, AutoRemoveTarget, target)
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
inst:ListenForEvent("ms_playerjoined", OnPlayerJoined)
inst:ListenForEvent("ms_playerleft", OnPlayerLeft)

--------------------------------------------------------------------------
--[[ Post initialization ]]
--------------------------------------------------------------------------

function self:OnPostInit()
    ToggleUpdate(true)
end

--------------------------------------------------------------------------
--[[ Public getters and setters ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------
function self:SetSpawnTimes(delay)
    print "DEPRECATED: SetSpawnTimes() in birdspawner.lua, use birdattractor.spawnmodifier instead"
    _minspawndelay = delay.min
    _maxspawndelay = delay.max
end

function self:ToggleUpdate()
    ToggleUpdate(true)
end

function self:setinsttoflotsam(inst, time, notag)    
    if not time then
        time = LIFESPAN.base + (math.random()*LIFESPAN.varriance)
    end
    inst:AddComponent("timer")
    if not notag then
        inst:AddTag("flotsam")
    end
    inst.components.timer:StartTimer("sink", time)
    
    inst:ListenForEvent("timerdone", OnTimerDone)    
    inst:ListenForEvent("onpickup", clearflotsamtimer)
    inst:ListenForEvent("onremove", clearflotsamtimer)    

    rememberflotsam(inst)    
end

function self:SpawnFlotsam(spawnpoint,prefab,notrealflotsam)
    -- notrealflotsam means the prefab won't get the flotsam tag, so it won't block other flotsam from spawning. 
    if not prefab then
        prefab = PickFlotsam(spawnpoint)
    end

    if prefab == nil then
        return
    end

    local flotsam = SpawnPrefab(prefab)
    if math.random() < .5 then
        flotsam.Transform:SetRotation(180)
    end

    flotsam.Physics:Teleport(spawnpoint:Get())

    self:setinsttoflotsam(flotsam, nil, notrealflotsam)

    return flotsam
end

function self.StartTrackingFn(target)
    if _flotsam[target] == nil then
        _flotsam[target] = target.persists == true
        target.persists = false
        inst:ListenForEvent("entitysleep", OnTargetSleep, target)
    end
end

function self:StartTracking(target)
    self.StartTrackingFn(target)
end

function self.StopTrackingFn(target)
    local restore = _flotsam[target]
    if restore ~= nil then
        target.persists = restore
        _flotsam[target] = nil
        inst:RemoveEventCallback("entitysleep", OnTargetSleep, target)
    end
end

function self:StopTracking(target)
    self.StopTrackingFn(target)
end

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    local data =
    {
        maxflotsam = _maxflotsam,
        minspawndelay = _minspawndelay,
        maxspawndelay = _maxspawndelay,
    }
    local ents = {}
    data.flotsam = {}
    data.time = {}
    data.flotsamtag = {}

    for k,v in pairs(_flotsam) do 
        if k ~= nil then
            table.insert(data.flotsam, k.GUID)
            table.insert(ents, k.GUID)
            table.insert(data.time, k.components.timer:GetTimeLeft("sink") )
            table.insert(data.flotsamtag, k:HasTag("flotsam"))
        end
    end

    return data,ents
end

function self:OnLoad(data)
    _maxflotsam = data.maxflotsam or TUNING.FLOTSAM_SPAWN_MAX
    _minspawndelay = data.minspawndelay or TUNING.FLOTSAM_SPAWN_DELAY.min
    _maxspawndelay = data.maxspawndelay or TUNING.FLOTSAM_SPAWN_DELAY.max

    ToggleUpdate(true)
end

function self:LoadPostPass(newents, savedata)
    if savedata and savedata.flotsam then        
        for k,v in pairs(savedata.flotsam) do 
            if newents[v] ~= nil then 
                local notag = true
                if savedata.flotsamtag and savedata.flotsamtag[k] then
                    notag = nil
                end
                self:setinsttoflotsam(newents[v].entity, savedata.time[k], notag)
            end
        end
    end
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    local numflotsam = 0
    for k, v in pairs(_flotsam) do
        numflotsam = numflotsam + 1
    end
    return string.format("flotsam:%d/%d", numflotsam, _maxflotsam)
end

end)
