--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------
local easing = require("easing")

--------------------------------------------------------------------------
--[[ Deerherdspawner class definition ]]
--------------------------------------------------------------------------
return Class(function(self, inst)

assert(TheWorld.ismastersim, "DeerHerdspawner should not exist on client")

--------------------------------------------------------------------------
--[[ Private constants ]]
--------------------------------------------------------------------------

local STRUCTURE_DIST = 20
local HERD_SPAWN_DIST = 40
local STRUCTURES_PER_SPAWN = 4

local HERD_SPAWN_SIZE = 8
local HERD_SPAWN_SIZE_VARIANCE = 1
local HERD_SPAWN_RADIUS = 10

--------------------------------------------------------------------------
--[[ Public Member Variables ]]
--------------------------------------------------------------------------

self.inst = inst

--------------------------------------------------------------------------
--[[ Private Member Variables ]]
--------------------------------------------------------------------------	
local _spawners = {}

local _activedeer = {}

local _timetospawn = nil
local _lastherdsummonday = 0 -- pretty sure i dont need this any more
local _timetomigrate = nil

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function RemoveDeer(deer)
	_activedeer[deer] = nil
    self.inst:RemoveEventCallback("onremove", RemoveDeer, deer)
    self.inst:RemoveEventCallback("death", RemoveDeer, deer)
end

local function AddDeer(deer)
    _activedeer[deer] = true
    
	self.inst:ListenForEvent("onremove", RemoveDeer, deer)
	self.inst:ListenForEvent("death", RemoveDeer, deer)        
end

local function OnRemoveSpawner(spawner)
    for i, v in ipairs(_spawners) do
        if v == spawner then
            table.remove(_spawners, i)
            return
        end
    end
end

local function OnRegisterDeerSpawningGround(inst, spawner)
    for i, v in ipairs(_spawners) do
        if v == spawner then
            return
        end
    end

    table.insert(_spawners, spawner)
    inst:ListenForEvent("onremove", OnRemoveSpawner, spawner)
end

--------------------------------------------------------------------------
--[[ Register events ]]
--------------------------------------------------------------------------

inst:ListenForEvent("ms_registerdeerspawningground", OnRegisterDeerSpawningGround)

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------
local function FindHerdSpawningGroundPt()
	if #_spawners == 0 then
		if #AllPlayers == 0 then
			return nil
		end
		
		return AllPlayers[math.random(#AllPlayers)]:GetPosition()
    end

	_spawners = shuffleArray(_spawners)
	for i,v in ipairs(_spawners) do
	    if FindClosestPlayerToInst(v, HERD_SPAWN_DIST) == nil then
			return v:GetPosition()
	    end
	end

	return _spawners[1]:GetPosition()
end

local function SummonHerd()
	local loc = FindHerdSpawningGroundPt()
	if loc == nil then
		if TheWorld.state.isautumn == true and TheWorld.state.remainingdaysinseason > (TheWorld.state.autumnlength * 0.5) then
			_timetospawn = (1 + math.random()) * TUNING.TOTAL_DAY_TIME
		end

		return
	end

    --print("Spawn deer herd at:", loc.x, loc.z)

    local map = TheWorld.Map
    local herd_target_size = GetRandomWithVariance(HERD_SPAWN_SIZE, HERD_SPAWN_SIZE_VARIANCE)
    local num_spawned = 0
    local i = 0
    while num_spawned < herd_target_size and i < herd_target_size + 7 do
		local var = Vector3(GetRandomWithVariance(0,HERD_SPAWN_RADIUS),0.0,GetRandomWithVariance(0,HERD_SPAWN_RADIUS))
        local spawnPos = loc + Vector3(GetRandomWithVariance(0,HERD_SPAWN_RADIUS),0.0,GetRandomWithVariance(0,HERD_SPAWN_RADIUS))
        i = i + 1
        if map:IsAboveGroundAtPoint(spawnPos:Get()) then
            num_spawned = num_spawned + 1
            self.inst:DoTaskInTime(GetRandomWithVariance(1,1), self.SpawnDeer, spawnPos)
        end
    end
end

local function QueueSummonHerd()
	if TheWorld.state.isautumn == true and (TheWorld.state.cycles - _lastherdsummonday) > TheWorld.state.autumnlength then
		_lastherdsummonday = TheWorld.state.cycles

		local spawndelay = 0.2 * TheWorld.state.autumnlength * TUNING.TOTAL_DAY_TIME
		local spawnrandom = .33 * spawndelay
		
		_timetospawn = GetRandomWithVariance(spawndelay, spawnrandom)
		--print ("Deer Herd in " .. tostring(_timetospawn/TUNING.TOTAL_DAY_TIME) .. " days.", spawndelay/TUNING.TOTAL_DAY_TIME, spawnrandom/TUNING.TOTAL_DAY_TIME)
		self.inst:StartUpdatingComponent(self)
	end
end

local function QueueHerdMigration()
	if TheWorld.state.iswinter == true and next(_activedeer) ~= nil then
		local spawndelay = 0.75 * TheWorld.state.autumnlength * TUNING.TOTAL_DAY_TIME
		local spawnrandom = 0.1 * TheWorld.state.autumnlength * TUNING.TOTAL_DAY_TIME
		
		_timetomigrate = GetRandomWithVariance(spawndelay, spawnrandom)
		self.inst:StartUpdatingComponent(self)
		
		-- Trigger antler growing
		for k, _ in pairs(_activedeer) do
			if k:IsValid() then
				k:PushEvent("queuegrowantler")
			end
		end
	end
end

local function MigrateHerd()
	for k,_ in pairs(_activedeer) do
		if k:IsValid() then
			k:PushEvent("deerherdmigration")

			self.inst:RemoveEventCallback("onremove", RemoveDeer, k)
			self.inst:RemoveEventCallback("death", RemoveDeer, k)
		end
	end
	_activedeer = {}
end


--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:SpawnDeer(pos, angle)
    local deer = SpawnPrefab("deer")
    if deer then
        --print("Spawn deer at", pos.x, pos.z, "angle:", tostring(angle))

        deer.Transform:SetPosition(pos:Get())
        deer.Transform:SetRotation(angle or (math.random(360)-1))
        --deer.sg:GoToState("appear")
        
        AddDeer(deer)
    end
end

function self:OnUpdate(dt)
	if _timetospawn ~= nil then
		_timetospawn = _timetospawn - dt
		if _timetospawn <= 0 then
			_timetospawn = nil
			SummonHerd()
		end
	elseif _timetomigrate ~= nil then
		if next(_activedeer) == nil then
			_timetomigrate = nil
		else
			_timetomigrate = _timetomigrate - dt
			if _timetomigrate <= 0 then
				_timetomigrate = nil
				MigrateHerd()
			end
		end
		
	else
		self.inst:StopUpdatingComponent(self)
	end

end

function self:LongUpdate(dt)
	self:OnUpdate(dt)
end

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
	local data = 
	{
		_timetospawn = _timetospawn,
		_lastherdsummonday = _lastherdsummonday ~= 0 and _lastherdsummonday or nil,
		_timetomigrate = _timetomigrate,
	}
	
	for k, v in pairs(_activedeer) do
		if k:IsValid() then
			if data._activedeer == nil then
				data._activedeer = { k.GUID }
			else
				table.insert(data._activedeer, k.GUID)
			end
		end
    end
	
	return data, data._activedeer
end

function self:OnLoad(data)
	if data ~= nil then
		_lastherdsummonday = data._lastherdsummonday or 0
		_timetospawn = data._timetospawn
		_timetomigrate = data._timetomigrate
	end
end

function self:LoadPostPass(newents, data)
    if data ~= nil and data._activedeer ~= nil then
        for k, v in pairs(data._activedeer) do
            local deer = newents[v]
            if deer ~= nil then
                 AddDeer(deer.entity)
            end
        end
    end

	if _timetospawn ~= nil or _timetomigrate ~= nil then
		self.inst:StartUpdatingComponent(self)
	end
end


--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
	local s = ""
	if _timetomigrate ~= nil then
	    s = s .. string.format("Migration in %.2f (%.2f days). Deer remaining = %s", _timetomigrate, _timetomigrate/TUNING.TOTAL_DAY_TIME, tostring(GetTableSize(_activedeer)))
	elseif next(_activedeer) ~= nil then
		s = s .. "The deer are hear. Total Dear = " .. tostring(GetTableSize(_activedeer))
	elseif _timetospawn ~= nil then
	    s = s .. string.format("Summoning in %.2f (%.2f days)", _timetospawn, _timetospawn/TUNING.TOTAL_DAY_TIME)
	else
		s = s .. "Dormant: Waiting for autumn."
	end
	return s
end

-- TheWorld.components.deerherdspawner:DebugSummonHerd()
function self:DebugSummonHerd(time)
	_timetospawn = time or 5
	_lastherdsummonday = TheWorld.state.cycles
	self.inst:StartUpdatingComponent(self)
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

self:WatchWorldState("isautumn", QueueSummonHerd)
self:WatchWorldState("iswinter", QueueHerdMigration)

end)
