--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------
local easing = require("easing")


--------------------------------------------------------------------------
--[[ BaseHassler class definition ]]
--------------------------------------------------------------------------
return Class(function(self, inst)

assert(TheWorld.ismastersim, "ButterflySpawner should not exist on client")

--------------------------------------------------------------------------
--[[ Private constants ]]
--------------------------------------------------------------------------

local HASSLER_SPAWN_DIST = 40
local WANDER_AWAY_DIST = 100

--------------------------------------------------------------------------
--[[ Public Member Variables ]]
--------------------------------------------------------------------------
self.inst = inst

--------------------------------------------------------------------------
--[[ Private Member Variables ]]
--------------------------------------------------------------------------
local _warning = false
local _timetoattack = nil
local _warnduration = 60
local _timetonextwarningsound = 0
local _announcewarningsoundinterval = 4
local _hasslerprefab = "deerclops"
local _warningsound = "dontstarve/creatures/deerclops/distant"
	
local _attacksperwinter = 1
local _attackduringsummer = false
local _attackdelay = nil
local _attackrandom = nil
local _targetplayer = nil

local _activeplayers = {}

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function PickAttackTarget()
	local playeri = math.min(math.floor(easing.inQuint(math.random(), 1, #_activeplayers, 1)), #_activeplayers)
	local player = _activeplayers[playeri]
	table.remove(_activeplayers, playeri)
	table.insert(_activeplayers, player)
	_targetplayer = player
end

local function CeaseAttacks()
	_targetplayer = nil
    _timetoattack = nil
    _warning = false
    self.inst:StopUpdatingComponent(self)
end

local function PlanNextAttack()
    if (not TheWorld.state.iswinter and not _attackduringsummer) or not _attackdelay then
        CeaseAttacks()
        return
    end
	
	_timetoattack = GetRandomWithVariance(_attackdelay, _attackrandom or 0)
end

local function StartAttacks()
    local timeLeftInSeason = TheWorld.state.remainingdaysinseason * TUNING.TOTAL_DAY_TIME
	if _attacksperwinter > 0 then
	    if _attacksperwinter < 1 then
	        --special case: plan attack for NEXT season
	        local summersToSkip = math.floor( (1 / _attacksperwinter) - 1 )
	        local wintersToSkip = math.max(0, summersToSkip-1)
	        _attackdelay = 0.5 * timeLeftInSeason + TUNING.TOTAL_DAY_TIME * (summersToSkip * TheWorld.state.summerlength + wintersToSkip * TheWorld.state.winterlength)
            _attackrandom = 0.25*timeLeftInSeason
        else
            _attackdelay = timeLeftInSeason / _attacksperwinter
            _attackrandom = 0.25*_attackdelay
	    end
	    PlanNextAttack()
        self.inst:StartUpdatingComponent(self)
	end
	
end

local function GetSpawnPoint(pt)
    local theta = math.random() * 2 * PI
    local radius = HASSLER_SPAWN_DIST

	local offset = FindWalkableOffset(pt, theta, radius, 12, true)
	if offset then
		return pt+offset
	end
end

local function GetWanderAwayPoint(pt)
    local theta = math.random() * 2 * PI
    local radius = WANDER_AWAY_DIST
    
    local ground = TheWorld
    
    -- Walk the circle trying to find a valid spawn point
    local steps = 12
    for i = 1, 12 do
        local offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))
        local wander_point = pt + offset
        
        if ground.Map:IsPassableAtPoint(wander_point:Get()) and
            ground.Pathfinder:IsClear(
                pt.x, pt.y, pt.z,
                wander_point.x, wander_point.y, wander_point.z,
                { ignorewalls = true }) then
            return wander_point
        end
        theta = theta - (2 * PI / steps)
    end
end

local function ReleaseHassler(targetPlayer)
	assert(targetPlayer)
	local pt = Vector3(targetPlayer.Transform:GetWorldPosition())

    local spawn_pt = GetSpawnPoint(pt)
	
    if spawn_pt then
	    local hassler = TheSim:FindFirstEntityWithTag(_hasslerprefab)
	    if not hassler then
	        hassler = SpawnPrefab(_hasslerprefab)
	    end
        if hassler then
			-- KAJ: MP_LOGIC	this needs to be a tad more subtle
            hassler.Physics:Teleport(spawn_pt:Get())
            local target = GetClosestInstWithTag("structure", targetPlayer, 40)
            if target then
                local targetPos = Vector3(target.Transform:GetWorldPosition() )
		        hassler.components.knownlocations:RememberLocation("targetbase", targetPos)
                local wanderAwayPoint = GetWanderAwayPoint(targetPos)
                if wanderAwayPoint then
                    hassler.components.knownlocations:RememberLocation("home", wanderAwayPoint)
                end
		    else
		        hassler.components.combat:SetTarget(targetPlayer)
		    end
		end
	end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnSnowLevel(self, snowlevel)
    if snowlevel >= 0.2 then 
        if not _timetoattack then
            StartAttacks()
        end
    elseif snowlevel <= 0 and _attackduringsummer and not _timetoattack then
        StartAttacks()
    else
        CeaseAttacks()
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
			-- if this was the activetarget...cease the attack
			if player == _targetplayer then
				CeaseAttacks()
			end

            table.remove(_activeplayers, i)
            return
        end
    end
end


--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:SetHasslerPrefab(prefab)
    _hasslerprefab = prefab
end

function self:SetWarningSound(sound)
    _warningsound = sound
end

function self:SetAttacksPerWinter(attacks)
    _attacksperwinter = attacks
end

function self:SetAttackDuringSummer(attack)
    _attackduringsummer = attack
end

function self:OverrideAttacksPerSeason(name, num)
	if name == "DEERCLOPS" then
		_attacksperwinter = num
	end
end

function self:OverrideAttackDuringOffSeason(name, bool)
	if name == "DEERCLOPS" then
		_attackduringsummer = bool
	end
end

function self:OnUpdate(dt)
    if not _timetoattack then
        CeaseAttacks()
        return
    end
	_timetoattack = _timetoattack - dt
	if _timetoattack <= 0 then
		_warning = false
	    ReleaseHassler(_targetplayer)
		CeaseAttacks()
	else
		if not _warning and _timetoattack < _warnduration then
			-- let's pick a random player here
			PickAttackTarget()
			if not _targetplayer then
				CeaseAttacks()
				return
			end
			_warning = true
			_timetonextwarningsound = 0
		end
	end
	
	if _warning then
		_timetonextwarningsound	= _timetonextwarningsound - dt
		
		if _timetonextwarningsound <= 0 then
			assert(_targetplayer)
			_announcewarningsoundinterval = _announcewarningsoundinterval - 1
			if _announcewarningsoundinterval <= 0 then
				_announcewarningsoundinterval = 10 + math.random(5)
					-- KAJ:TODO:MP_TALK - should other players see this?
					_targetplayer.components.talker:Say(GetString(_targetplayer.prefab, "ANNOUNCE_DEERCLOPS"))
			end
		
			local inst = CreateEntity()
			inst.entity:AddTransform()
			inst.entity:AddSoundEmitter()
			inst.persists = false
			local theta = math.random() * 2 * PI

			local radius = 5
			_timetonextwarningsound = 15 + math.random(4)
			
			if _timetoattack < 30 then
				_timetonextwarningsound = 10 + math.random(1)
				radius = radius
			elseif _timetoattack < 60 then
				radius = radius + 10
			elseif _timetoattack < 90 then
				radius = radius + 15
			else
				radius = radius + 20
			end

			-- KAJ: TODO: MS_SOUND, should other players hear this?
			local offset = Vector3(_targetplayer.Transform:GetWorldPosition()) +  Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))
			
			inst.Transform:SetPosition(offset.x,offset.y,offset.z)
			inst.SoundEmitter:PlaySound(_warningsound)
			inst:DoTaskInTime(1.5, function() inst:Remove() end)
		end
	end
end

function self:LongUpdate(dt)
	self:OnUpdate(dt)
end


--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
	if not self.noserial then
		return 
		{
			warning = _warning,
			timetoattack = _timetoattack,
			attackdelay = _attackdelay,
			attackrandom = _attackrandom,
		}
	end
	self.noserial = false
end

function self:OnLoad(data)
	_warning = data.warning or false
	_timetoattack = data.timetoattack
	_attackdelay = data.attackdelay
	_attackrandom = data.attackrandom

	if _timetoattack then
    	self.inst:StartUpdatingComponent(self)
    end
end


function self:OnProgress()
	self.noserial = true
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
	if not _timetoattack then
	    return "DORMANT"
	elseif _timetoattack > 0 then
		return string.format("%s Deerclops is coming in %2.2f", _warning and "WARNING" or "WAITING", _timetoattack)
	else
		return string.format("ATTACKING!!!")
	end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------
for i, v in ipairs(AllPlayers) do
    table.insert(_activeplayers, v)
end

self.inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
self.inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)
self:WatchWorldState("snowlevel", OnSnowLevel)

end)