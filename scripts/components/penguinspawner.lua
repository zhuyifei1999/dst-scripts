local FLOCK_SIZE = 9
local MIN_SPAWN_DIST = 40
local LAND_CHECK_RADIUS = 6
local WATER_CHECK_RADIUS = 2

local LOCAL_CHEATS_ENABLED = false

local MAX_DIST_FROM_PLAYER = 12
local MAX_DIST_FROM_WATER = 6

local SEARCH_RADIUS = 50
local SEARCH_RADIUS2 = SEARCH_RADIUS*SEARCH_RADIUS

local ICEBLOCKER_SEARCH_RADIUS = 15

local DEFAULT_NUM_BOULDERS = 7

--------------------------------------------------------------------------
--[[ PenguinSpawner class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "PenguinSpawner should not exist on client")

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _colonies = {}       -- existing colonies
local _maxColonySize = 12
local _totalBirds = 0    -- current number of birds alive
local _flockSize = FLOCK_SIZE
local _seasonLimit = 0  -- total spawned this season
local _spacing = 60
local _checktime = 5
local _lastSpawnTime = 0

local _maxPenguins = 50  -- max simultaneous penguins
local _spawnInterval = 30

local _maxColonies = 10
local _maxSpawnsPerSeason = 35
local _active = true

local _numBoulders = DEFAULT_NUM_BOULDERS

local _activeplayers = {}

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------
local function FindLandNextToWater( playerpos, waterpos )
    --print("FindWalkableOffset:")
    local ignore_walls = true 
    local radius = WATER_CHECK_RADIUS
    local ground = TheWorld

    local test = function(offset)
        local run_point = waterpos + offset

        -- TODO: Also test for suitability - trees or too many objects
        return ground.Map:IsAboveGroundAtPoint(run_point:Get()) and
            ground.Pathfinder:IsClear(
                playerpos.x, playerpos.y, playerpos.z,
                run_point.x, run_point.y, run_point.z,
                { ignorewalls = ignore_walls, ignorecreep = true })
    end

    -- FindValidPositionByFan(start_angle, radius, attempts, test_fn)
    -- returns offset, check_angle, deflected
    local loc,landAngle,deflected = FindValidPositionByFan(0, radius, 8, test)
    if loc then
        --print("Fan angle=",landAngle)
        return waterpos+loc,landAngle,deflected
    end
end


local function FindSpawnLocationForPlayer(player)
    local playerPos = Vector3(player.Transform:GetWorldPosition())

    local radius = LAND_CHECK_RADIUS
    local landPos
    local tmpAng
    local map = TheWorld.Map

    local test = function(offset)
        local run_point = playerPos + offset
        -- Above ground, this should be water
        if not map:IsAboveGroundAtPoint(run_point:Get()) then
            local loc, ang, def= FindLandNextToWater(playerPos, run_point)
            if loc ~= nil then
                landPos = loc
                tmpAng = ang
                --print("true angle",ang,ang/DEGREES)
                return true
            end
        end
        return false
    end

    local cang = (TheCamera:GetHeading() % 360) * DEGREES
    --print("cang:",cang)
    local loc, landAngle, deflected = FindValidPositionByFan(cang, radius, 4, test)
    if loc ~= nil then
        return landPos, tmpAng, deflected
    end
end

--[[
--KAJ:I believe this isn't used
function self:Kill(reset)
    for i,v in ipairs(_colonies) do
        local members = v.members or {}
        for pengu,v in pairs(members) do
            pengu:Remove()
        end
        if reset and v.ice then
            v.ice:Remove()
        end
    end
    if reset then
        _colonies = {}
    end
end
]]


local function LostPenguin(pengu)
    for i,v in ipairs(_colonies) do
        local members = v.members or {}
        if members[pengu] then
            members[pengu] = nil
            _totalBirds = _totalBirds-1
            self.inst:RemoveEventCallback("death", pengu.deathfn, pengu)
            self.inst:RemoveEventCallback("onremove", pengu.deathfn, pengu)
            return
        end
    end
end

local function SpawnPenguin(inst,spawner,colonyNum,pos,angle)

    if _totalBirds >= _maxPenguins or _seasonLimit > _maxSpawnsPerSeason then
        return
    end

    local pengu = SpawnPrefab("penguin")
    if pengu then
        --print(TheCamera:GetHeading()," spawnPenguin at",pos,"angle:",angle)

        pengu.Transform:SetPosition(pos.x,pos.y,pos.z)
        pengu.Transform:SetRotation(angle)
        pengu.sg:GoToState("appear")
        self:AddToColony(colonyNum,pengu)
    end
end

local function SpawnFlock(colonyNum,loc,check_angle)
    local map = TheWorld.Map
    local flock = GetRandomWithVariance(_flockSize,3)
    local spawned = 0
    local i = 0
    local pang = check_angle/DEGREES
    while spawned < flock and i < flock + 7 do
        local spawnPos = loc + Vector3(GetRandomWithVariance(0,0.5),0.0,GetRandomWithVariance(0,0.5))
        i = i + 1
        if map:IsAboveGroundAtPoint(spawnPos:Get()) then
            spawned = spawned + 1
            --print(TheCamera:GetHeading()%360,"Spawn flock at:",spawnPos,(check_angle/DEGREES),"degrees"," c_off=",c_off)
            --print(TheCamera:GetHeading()," spawnPenguin at",pos,"angle:",angle)
            self.inst:DoTaskInTime(GetRandomWithVariance(1,1), SpawnPenguin, self, colonyNum, spawnPos,(check_angle/DEGREES))
        end
    end
end

local function EstablishColony(loc)

    local radius = SEARCH_RADIUS
    local pos
    local ignore_walls = false
    local check_los = true
    local colonies = _colonies
    local ground = TheWorld

     local testfn = function(offset)
        local run_point = loc + offset
        if not ground.Map:IsAboveGroundAtPoint(run_point:Get()) then
            return false
        end

        local NearWaterTest = function(offset)
            local test_point = run_point + offset
            return not ground.Map:IsAboveGroundAtPoint(test_point:Get())
        end

        --  FindValidPositionByFan(start_angle, radius, attempts, test_fn)
        if check_los and
            not ground.Pathfinder:IsClear(loc.x, loc.y, loc.z,
                                                         run_point.x, run_point.y, run_point.z,
                                                         {ignorewalls = ignore_walls, ignorecreep = true}) then 
            return false
        end
        if FindValidPositionByFan(0, 6, 16, NearWaterTest) then
            --print("colony too near water")
            return false
        end
            -- Now check that the rookeries are not too close together
        local found = true
        for i,v in ipairs(colonies) do
            local pos = v.rookery
            -- What about penninsula effects? May have a long march
            if pos and distsq(run_point,pos) < _spacing*_spacing then
                found = false
            end
        end
        return found
    end

    -- Look for any nearby colonies with enough room
    -- return the colony if you find it
    for i,v in ipairs(_colonies) do
        --print(i,"looking at size:",GetTableSize(v.members),v.rookery,"dist=",math.sqrt(distsq(loc,v.rookery)))
        if GetTableSize(v.members) <= (_maxColonySize-(FLOCK_SIZE*.8)) then
            pos = v.rookery
            if pos and distsq(loc,pos) < SEARCH_RADIUS2+60 and
                ground.Pathfinder:IsClear(loc.x, loc.y, loc.z,                    -- check for interposing water
                                         pos.x, pos.y, pos.z,
                                         {ignorewalls = false, ignorecreep = true}) then 
                --print("************* Found existing colony")
                return i
            end
        end
    end
    -- Make a new colony
    local newFlock = { members={} }

    radius = SEARCH_RADIUS
    -- Otherwise, find another good spot far enough away from the other colonies
    while not newFlock.rookery and radius>30 do
        -- Starting angle set towards player (to reduce peninsula effects)
        local angle
        -- angle = GetRandomWithVariance(ThePlayer:GetAngleToPoint(loc)-180, 10)
        angle = GetRandomWithVariance(0, PI) -- otherwise will 
        --newFlock.rookery = FindWalkableOffset(loc, angle, radius, 16, true)
        --                  FindValidPositionByFan(start_angle, radius, attempts, test_fn)
        newFlock.rookery =  FindValidPositionByFan(angle, radius, 32, testfn)
        radius = radius - 10
    end
    if newFlock.rookery then
        newFlock.rookery = newFlock.rookery + loc
        newFlock.ice = SpawnPrefab("penguin_ice")
        newFlock.ice.Transform:SetPosition(newFlock.rookery:Get())
        newFlock.ice.spawner = self

        local numboulders = math.random(math.floor(_numBoulders/2), _numBoulders)
        local sectorsize = 360 / numboulders
        local numattempts = 50
        while numboulders > 0 and numattempts > 0 do
            local foundvalidplacement = false
            local placement_attempts = 0
            while not foundvalidplacement do
                local minang = (sectorsize * (numboulders - 1)) >= 0 and (sectorsize * (numboulders - 1)) or 0
                local maxang = (sectorsize * numboulders) <= 360 and (sectorsize * numboulders) or 360
                local angle = math.random(minang, maxang)
                local pos = newFlock.ice:GetPosition()
                local offset = FindWalkableOffset(pos, angle*DEGREES, math.random(5,15), 120, false, false)
                if offset then 
                    local ents = TheSim:FindEntities(pos.x + offset.x, pos.y + offset.y, pos.z + offset.z, 1.2)
                    if #ents == 0 then
                        foundvalidplacement = true
                        numboulders = numboulders - 1
                        
                        -- Note: if the rock_ice is trying to be placed near something that is prevents it from spawning, then abort this attempt
                        --       but still count it as a placed rock_ice, that way they dont pile up around the radius of the iceblocker
	                    ents = TheSim:FindEntities(pos.x + offset.x, pos.y + offset.y, pos.z + offset.z, ICEBLOCKER_SEARCH_RADIUS, {"iceblocker"})
                        if #ents == 0 then
                            local icerock = SpawnPrefab("rock_ice")
                            icerock.Transform:SetPosition(pos.x + offset.x, pos.y + offset.y, pos.z + offset.z)
                        end
                    end
                end
                placement_attempts = placement_attempts + 1
                --print("placement_attempts:", placement_attempts)
                if placement_attempts > 10 then break end
            end
            numattempts = numattempts - 1
        end
    else
        return false
    end

    _colonies[#_colonies+1] = newFlock
    return #_colonies

end

local function TryToSpawnFlockForPlayer(playerdata)
    if _active then
        --print("---------:", TheWorld.state.season, TheWorld.state.remainingdaysinseason)
	    if not TheWorld.state.iswinter or TheWorld.state.remainingdaysinseason <= 3 then
            return
        end

        --print("Totalbirds=",_totalBirds,_maxPenguins)
        if #_colonies > _maxColonies then
            --print("Maxed out colonies")
            return
        end

        if _totalBirds >= _maxPenguins or _seasonLimit > _maxSpawnsPerSeason then
            --print("TryToSpawn maxed out")
            return
        end

		-- if too close to any player, then don't spawn
--        local playerPos = ThePlayer:GetPosition()
		-- if any player too close to any of the spawnlocs then bail
		-- if this player is too close to any of the lastSpawnLocs then don't try
        local player = playerdata.player
		local playerPos = player:GetPosition()
		for i,v in ipairs(_activeplayers) do
			if v.lastSpawnLoc and distsq(v.lastSpawnLoc,playerPos) < MIN_SPAWN_DIST*MIN_SPAWN_DIST then
				return
			end
		end

        if (_lastSpawnTime and (GetTime() - _lastSpawnTime) < _spawnInterval) then
            --print("too soon to spawn")
            return
        end

        -- Go find a spot on land close to water
        -- returns offset, check_angle, deflected
        local loc,check_angle,deflected = FindSpawnLocationForPlayer(player)
        if loc then 
            --print("trying to spawn: Angle is",check_angle/DEGREES)
            local colony = EstablishColony(loc)

            if not colony then
                --print("can't establish colony")
                return
            end

            _lastSpawnTime = GetTime()
			playerdata.lastSpawnLoc = loc

            SpawnFlock(colony,loc,check_angle)
        end
    end
end

local function TryToSpawnFlock()
	-- Round robin the players
	if #_activeplayers > 0 then
		local playerdata = _activeplayers[1]
		TryToSpawnFlockForPlayer(playerdata)
		table.remove(_activeplayers,1)
		table.insert(_activeplayers, playerdata)
	end
	self.inst:DoTaskInTime(_checktime / math.max(#_activeplayers,1), function() TryToSpawnFlock() end)
end

local function OnLoadColonies(data)

    --print("____________ LOADING PSpawner")
    _colonies = _colonies or {}
    if data.colonies then
        for i,v in ipairs(data.colonies) do
            local ice = SpawnPrefab("penguin_ice")
            --print(i,ice,"+++++++ pos=",v[1],v[2],v[3])
            if ice then
                ice.Transform:SetPosition(v[1],v[2],v[3])
                ice.spawner = self
            end
            _colonies[i] = { rookery = Vector3(v[1],v[2],v[3]), members={}, ice=ice }
        end
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------
local function OnPlayerJoined(src, player)
    for i, v in ipairs(_activeplayers) do
        if v == player then
            return
        end
    end
    table.insert(_activeplayers, {player = player, lastSpawnLoc = nil})
end

local function OnPlayerLeft(src, player)
    for i, v in ipairs(_activeplayers) do
        if v.player == player then
            table.remove(_activeplayers, i)
            return
        end
    end
end

local function OnSetNumBoulders(val)
    _numBoulders = val or DEFAULT_NUM_BOULDERS
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------
--Initialize variables
for i, v in ipairs(AllPlayers) do
	OnPlayerJoined(self, v)
end

inst:ListenForEvent("ms_playerjoined", function(src, player) OnPlayerJoined(src, player) end, TheWorld)
inst:ListenForEvent("ms_playerleft", function(src, player) OnPlayerLeft(src,player) end, TheWorld)
inst:ListenForEvent("ms_setpenguinnumboulders", function(src, val) OnSetNumBoulders(val) end, TheWorld)

-- Reschedule based on number of players
self.inst:DoTaskInTime(_checktime / math.max(#_activeplayers,1), function() TryToSpawnFlock() end)

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------
function self:AddToColony(colonyNum,pengu)
    local colony = _colonies[colonyNum]
    if colony then
        --print(pengu," added to ",colonyNum)
        colony.members = colony.members or {}
        colony.members[pengu] = true
        pengu.colonyNum = colonyNum
        _totalBirds = _totalBirds + 1
        _seasonLimit = _seasonLimit + 1
        -- NB. Have to create a separate function because
        --     RemoveEventCallback matches the specific function address
        pengu.deathfn = function() LostPenguin(pengu) end
        self.inst:ListenForEvent("death", pengu.deathfn, pengu )
        self.inst:ListenForEvent("onremove", pengu.deathfn, pengu )
        pengu.components.knownlocations:RememberLocation("rookery", colony.rookery)
        pengu.components.knownlocations:RememberLocation("home", colony.rookery) -- important for sleep
    end
end

function self:SpawnModeNever()
    _maxPenguins = 0
    _spawnInterval = -1
    _maxColonies = 0
    _maxSpawnsPerSeason = 0
    _active = false
    self.inst:StopUpdatingComponent(self)
end

function self:SpawnModeHeavy()
    _maxPenguins = 70 
    _spawnInterval = 10
    _maxColonies = 15
    _maxSpawnsPerSeason = 70
end

function self:SpawnModeMed()
    _maxPenguins = 60 
    _spawnInterval = 20
    _maxColonies = 12
    _maxSpawnsPerSeason = 50
end

function self:SpawnModeLight()
    _maxPenguins = 25
    _spawnInterval = 60
    _maxColonies = 5
    _maxSpawnsPerSeason = 20
end
--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------
function self:OnSave()
    local data = {}
    if #_colonies >= 1 then
        data.colonies = {}
        for i,v in ipairs(_colonies) do
            data.colonies[i] = {v.rookery.x,v.rookery.y,v.rookery.z}
        end
    else
        --print("__NO COLONIES")
    end
    data.maxPenguins = _maxPenguins
    data.spawnInterval = _spawnInterval
    data.maxColonies = _maxColonies
    data.maxSpawnsPerSeason = _maxSpawnsPerSeason
    data.active = _active
    data.numBoulders = _numBoulders
    return data
end

function self:OnLoad(data)
    if data then
		OnLoadColonies(data)
        _active = data.active or true
        if not _active then
            self.inst:StopUpdatingComponent(self)
        end
        _maxPenguins = data.maxPenguins or 50 
        _spawnInterval = data.spawnInterval or 30
        _maxColonies = data.maxColonies or 10
        _maxSpawnsPerSeason = data.maxSpawnsPerSeason or 35
        _numBoulders = data.numBoulders or DEFAULT_NUM_BOULDERS
    end
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------
end)
