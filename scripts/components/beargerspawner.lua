--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------
local easing = require("easing")


--------------------------------------------------------------------------
--[[ BaseHassler class definition ]]
--------------------------------------------------------------------------
return Class(function(self, inst)

assert(TheWorld.ismastersim, "Beargerspawner should not exist on client")

--------------------------------------------------------------------------
--[[ Private constants ]]
--------------------------------------------------------------------------

local HASSLER_SPAWN_DIST = 40
local HASSLER_KILLED_DELAY_MULT = 4

--------------------------------------------------------------------------
--[[ Public Member Variables ]]
--------------------------------------------------------------------------

self.inst = inst

--------------------------------------------------------------------------
--[[ Private Member Variables ]]
--------------------------------------------------------------------------
local _warning = false
local _timetospawn = nil
local _warnduration = 60
local _timetonextwarningsound = 0
local _announcewarningsoundinterval = 4

local _targetNum = 0
local _firstBeargerSpawnChance = 1
local _secondBeargerSpawnChance = 0

local _numSpawned = 0

local _targetplayer = nil
local _activehasslers = {}
local _activeplayers = {}

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------


local function PickPlayer()
	local playeri = math.min(math.floor(easing.inQuint(math.random(), 1, #_activeplayers, 1)), #_activeplayers)
	local player = _activeplayers[playeri]
	table.remove(_activeplayers, playeri)
	table.insert(_activeplayers, player)
	_targetplayer = player
end


local function GetSpawnPoint(pt)
    local theta = math.random() * 2 * PI
    local radius = HASSLER_SPAWN_DIST

	local offset = FindWalkableOffset(pt, theta, radius, 12, true)
	if offset then
		return pt+offset
	end
end


local function ReleaseHassler(targetPlayer)
	assert(targetPlayer)

	self.inst:StopUpdatingComponent(self)

	local pt = Vector3(targetPlayer.Transform:GetWorldPosition())

	if _numSpawned >= _targetNum then 
		return 
	end

    local spawn_pt = GetSpawnPoint(pt)

    if spawn_pt then
	   
		local hassler = SpawnPrefab("bearger")
		_numSpawned = _numSpawned + 1
	   
	    --print("spawned bearger ", hassler)
        if hassler then
            hassler.Physics:Teleport(spawn_pt:Get())

			return hassler
		end
	end
end

local function SpawnBearger()

	--print("BeargerSpawner detected autumn", TheWorld.state.cycles, _numSpawned)
	local shouldSpawn = TheWorld.state.cycles > TUNING.NO_BOSS_TIME and TheWorld.state.isautumn == true and _numSpawned < _targetNum

	if shouldSpawn then 
		local spawndelay = .25 * ((TheWorld.state.remainingdaysinseason * TUNING.TOTAL_DAY_TIME) / _targetNum)
		local spawnrandom = .25 * spawndelay
		_timetospawn = GetRandomWithVariance(spawndelay, spawnrandom or 0)
		--print("Spawning Bearger ", _timetospawn)
		self.inst:StartUpdatingComponent(self)
	end

end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnAutumn()
	if (TheWorld.state.isautumn == true) then 
		--print("BeargerSpawner got isautumn event")

		_targetNum = 0
		local chance = math.random()
		--print("Spawning first bearger?", chance, _firstBeargerSpawnChance)
		if chance < _firstBeargerSpawnChance then 
			_targetNum = _targetNum + 1
		end

		chance = math.random()
		--print("Spawning second bearger?", chance, _secondBeargerSpawnChance)
		if _targetNum > 0 and chance < _secondBeargerSpawnChance then 
			_targetNum = _targetNum + 1
		end

		--print("OnAutumn chose target number ", _targetNum )
		local numActive = 0
		for i,v in pairs(_activehasslers) do 
			if v ~= nil then 
				numActive = numActive + 1
			end
		end

		_numSpawned = numActive
		if numActive >= _targetNum then 
			_targetNum = numActive
		end

		-- if _numSpawned is less than _targetNum, then allow spawning
		if _numSpawned < _targetNum then 
			SpawnBearger()
		end
	--else 
		--print("BeargerSpawner got end autumn")
	end
end


local function OnPlayerJoined(src,player)
    for i, v in ipairs(_activeplayers) do
        if v == player then
            return
        end
    end
    table.insert(_activeplayers, player)
end

local function OnPlayerLeft(src,player)
    for i, v in ipairs(_activeplayers) do
        if v == player then
            table.remove(_activeplayers, i)
            return
        end
    end
end

local function OnHasslerRemoved(src, hassler)
	--print("Bearger removed", hassler)
	_activehasslers[hassler] = nil
end


local function OnHasslerKilled(src, hassler)
	--print("Bearger killed", hassler)
	_activehasslers[hassler] = nil
	if (_firstBeargerSpawnChance >= 1 and _secondBeargerSpawnChance >= 1) then 
		_numSpawned = _numSpawned - 1
		SpawnBearger()
	end
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:SetSecondBeargerChance(chance)
	_secondBeargerSpawnChance = chance
end

function self:SetFirstBeargerChance(chance)
	_firstBeargerSpawnChance = chance
end

local function _DoWarningSpeech(player)
    --TODO: bearger specific strings
    player.components.talker:Say(GetString(player.prefab, "ANNOUNCE_DEERCLOPS"))
end

function self:DoWarningSpeech(_targetplayer)
    for i, v in ipairs(_activeplayers) do 
        if v == _targetplayer or v:IsNear(_targetplayer, HASSLER_SPAWN_DIST * 2) then
            v:DoTaskInTime(math.random() * 2, _DoWarningSpeech)
        end
    end
end

function self:DoWarningSound(_targetplayer)
    --Players near _targetplayer will hear the warning sound from the
    --same direction and volume offset from their own local positions
    SpawnPrefab("beargerwarning_lvl"..
        (((_timetospawn == nil or
        _timetospawn < 30) and "4") or
        (_timetospawn < 60 and "3") or
        (_timetospawn < 90 and "2") or
                               "1")
    ).Transform:SetPosition(_targetplayer.Transform:GetWorldPosition())
end

function self:OnUpdate(dt)
	--print("BeargerSpawner time to spawn is ", _timetospawn or "nil", _numSpawned or "0", _targetNum or "0")
    if _timetospawn ~= nil then 
		_timetospawn = _timetospawn - dt
		if _timetospawn <= 0 then
			_warning = false
			_timetospawn = nil
			if _targetplayer == nil then
				PickPlayer() -- In case a long update skipped the warning or something
			end
			--print("TimeToSpawn: ", _targetplayer)
	        if _targetplayer ~= nil then
	            _activehasslers[ReleaseHassler(_targetplayer)] = true
	        end
		else
			if not _warning and _timetospawn < _warnduration then
				-- let's pick a random player here
				PickPlayer()
				--print("Bearger warning player", _targetplayer)
				if not _targetplayer then
					return
				end
				_warning = true
				_timetonextwarningsound = 0
			end
		end
		--print("_warning is ", _warning, " and _timetospawn is ", _timetospawn, " and _warnduration is ", _warnduration)

		if _warning then
			_timetonextwarningsound	= _timetonextwarningsound - dt
			if _timetonextwarningsound <= 0 then
		        if _targetplayer == nil then
		        	PickPlayer()
		        	if _targetplayer == nil then
			            return
			        end
		        end
				_announcewarningsoundinterval = _announcewarningsoundinterval - 1
				if _announcewarningsoundinterval <= 0 then
					_announcewarningsoundinterval = 10 + math.random(5)
					self:DoWarningSpeech(_targetplayer)
				end

                _timetonextwarningsound = _timetospawn < 30 and 10 + math.random(1) or 15 + math.random(4)
				self:DoWarningSound(_targetplayer)
			end
		end
	elseif TheWorld.state.isautumn == true and TheWorld.state.cycles > TUNING.NO_BOSS_TIME and _numSpawned < _targetNum then 
		--print("BeargerSpawner spawning bearger")
		SpawnBearger()
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
		warning = _warning,
		timetospawn = _timetospawn,
		targetnum = _targetNum
	}

	local ents = {}

	data.activehasslers = {}

	for k,v in pairs(_activehasslers) do 
		if k ~= nil then
			table.insert(data.activehasslers, k.GUID)
			table.insert(ents, k.GUID)
		end
	end

	return data, ents
end

function self:OnLoad(data)
	_warning = data.warning or false
	_timetospawn = data.timetospawn
	_targetNum = data.targetnum

	--print("Bearger OnLoad", _targetNum or "nil", _timetospawn or "nil")
	self.inst:StopUpdatingComponent(self)

	--[[if _timetospawn and _timetospawn > 0 then 
		self.inst:StartUpdatingComponent(self)
	end]]
end

function self:LoadPostPass(newents, savedata)
	_numSpawned = 0
	if savedata.activehasslers ~= nil then
		for k,v in pairs(savedata.activehasslers) do 
			if newents[v] ~= nil then 
				_activehasslers[newents[v].entity] = true
				_numSpawned = _numSpawned + 1
				--self.inst:StopUpdatingComponent(self)
			end
		end
	end

	--print("BeargerSpawner LoadPostPass")

	if TheWorld.state.season == "autumn" then
		--print("calling OnAutumn") 
		OnAutumn() 
	end 
end


--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
	local s = ""
	if not _timetospawn then
	    s = s .. "DORMANT <no time>"
	elseif self.inst.updatecomponents[self] == nil then
		s = s .. "DORMANT ".._timetospawn
	elseif _timetospawn > 0 then
		s = s .. string.format("%s Bearger is coming in %2.2f (next warning in %2.2f), target number: %d, current number: %d", _warning and "WARNING" or "WAITING", _timetospawn, _timetonextwarningsound, _targetNum, _numSpawned)
	else
		s = s .. string.format("SPAWNING!!!")
	end
	local numActive = 0
	for k,v in pairs(_activehasslers) do 
		numActive = numActive + 1
	end
	s = s .. string.format(" active: %s", numActive)
	return s
end

function self:SummonMonster(player)
	ReleaseHassler(player)
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------
for i, v in ipairs(AllPlayers) do
    table.insert(_activeplayers, v)
end

self.inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
self.inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)
self:WatchWorldState("isautumn", OnAutumn)
self.inst:ListenForEvent("beargerremoved", OnHasslerRemoved, TheWorld)
self.inst:ListenForEvent("beargerkilled", OnHasslerKilled, TheWorld)

end)

