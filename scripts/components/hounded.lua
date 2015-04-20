--------------------------------------------------------------------------
--[[ Hounded class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "Hounded should not exist on client")

local HOUND_SPAWN_DIST = 30

local attack_levels=
{
	intro={warnduration= function() return 120 end, numhounds = function() return 2 end},
	light={warnduration= function() return 60 end, numhounds = function() return 2 + math.random(2) end},
	med={warnduration= function() return 45 end, numhounds = function() return 3 + math.random(3) end},
	heavy={warnduration= function() return 30 end, numhounds = function() return 4 + math.random(3) end},
	crazy={warnduration= function() return 30 end, numhounds = function() return 6 + math.random(4) end},
}

local attack_delays=
{
	rare = function() return TUNING.TOTAL_DAY_TIME * 6, math.random() * TUNING.TOTAL_DAY_TIME * 7 end,
	occasional = function() return TUNING.TOTAL_DAY_TIME * 4, math.random() * TUNING.TOTAL_DAY_TIME * 7 end,
	frequent = function() return TUNING.TOTAL_DAY_TIME * 3, math.random() * TUNING.TOTAL_DAY_TIME * 5 end,
}

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _activeplayers = {}
local _warning = false
local _timetoattack = 0
local _warnduration = 30
local _attackplanned = false
local _timetonextwarningsound = 0
local _announcewarningsoundinterval = 4

local _attackdelayfn = attack_delays.occasional
local _attacksizefn = attack_levels.light.numhounds
local _warndurationfn = attack_levels.light.warnduration
local _spawnmode = "escalating"
local _spawninfo = nil


--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function GetAveragePlayerAgeInDays()
	local sum = 0
	for i,v in ipairs(_activeplayers) do
		sum = sum + v.components.age:GetAgeInDays()		
	end
	local average = sum / #_activeplayers
	return average
end

local function CalcEscalationLevel()
	local day = GetAveragePlayerAgeInDays()
	
	if day < 10 then
		_attackdelayfn = attack_delays.rare
		_attacksizefn = attack_levels.intro.numhounds
		_warndurationfn = attack_levels.intro.warnduration
	elseif day < 25 then
		_attackdelayfn = attack_delays.rare
		_attacksizefn = attack_levels.light.numhounds
		_warndurationfn = attack_levels.light.warnduration
	elseif day < 50 then
		_attackdelayfn = attack_delays.occasional
		_attacksizefn = attack_levels.med.numhounds
		_warndurationfn = attack_levels.med.warnduration
	elseif day < 100 then
		_attackdelayfn = attack_delays.occasional
		_attacksizefn = attack_levels.heavy.numhounds
		_warndurationfn = attack_levels.heavy.warnduration
	else
		_attackdelayfn = attack_delays.frequent
		_attacksizefn = attack_levels.crazy.numhounds
		_warndurationfn = attack_levels.crazy.warnduration
	end
	
end

local function CalcPlayerAttackSize(player)
	local day = player.components.age:GetAgeInDays()
	local attacksize = 0	
	if day < 10 then
		attacksize = attack_levels.intro.numhounds()
	elseif day < 25 then
		attacksize = attack_levels.light.numhounds()
	elseif day < 50 then
		attacksize = attack_levels.med.numhounds()
	elseif day < 100 then
		attacksize = attack_levels.heavy.numhounds()
	else
		attacksize= attack_levels.crazy.numhounds()
	end
	return attacksize
end

local function PlanNextHoundAttack()
	if _timetoattack > 0 then
		-- we came in through a savegame that already had an attack scheduled
		return
	end
	-- if there are no players then try again later
	if #_activeplayers == 0 then
		_attackplanned = false
		self.inst:DoTaskInTime(1, PlanNextHoundAttack)
		return
	end

	if _spawnmode == "escalating" then
		CalcEscalationLevel()
	end
	
	if _spawnmode ~= "never" then
		local timetoattackbase, timetoattackvariance = _attackdelayfn()
		_timetoattack = timetoattackbase + timetoattackvariance
		_warnduration = _warndurationfn()
		_attackplanned = true
	end
    _warning = false
end

local GROUP_DIST = 20
local EXP_PER_PLAYER = 0.05
local ZERO_EXP = 1 - EXP_PER_PLAYER -- just makes the math a little easier

local function GetHoundAmounts()

	-- first bundle up the players into groups based on proximity
	-- we want to send slightly reduced hound waves when players are clumped so that
	-- the numbers aren't overwhelming
	local groupindex = {}
	local nextgroup = 1
	for i,playerA in ipairs(_activeplayers) do
		for j,playerB in ipairs(_activeplayers) do
			if i == 1 and j == 1 then
				groupindex[playerA] = 1
				nextgroup = 2
			end
			if j > i then
				if playerA:IsNear(playerB, GROUP_DIST) then
					if groupindex[playerA] and groupindex[playerB] and groupindex[playerA] ~= groupindex[playerB] then
						local mingroup = math.min(groupindex[playerA], groupindex[playerB])
						groupindex[playerA] = mingroup
						groupindex[playerB] = mingroup
					else
						groupindex[playerB] = groupindex[playerA]
					end
				elseif groupindex[playerB] == nil then
					groupindex[playerB] = nextgroup
					nextgroup = nextgroup + 1
				end
			end
		end
	end

	-- calculate the hound attack for each player
	_spawninfo = {}
	for player,group in pairs(groupindex) do
		local playerAge = player.components.age:GetAge()
		local attackdelaybase, attackdelayvariance =  _attackdelayfn()

		-- amount of hounds relative to our age
		local houndsToRelease = CalcPlayerAttackSize(player)
		local playerInGame = GetTime() - player.components.age.spawntime

		-- if we never saw a warning or have lived shorter than the minimum wave delay then don't spawn hounds to us
		if playerInGame <= _warnduration or playerAge < attackdelaybase then
			houndsToRelease = 0
		end

		if _spawninfo[group] == nil then
			_spawninfo[group] = {players = {player}, houndstorelease = houndsToRelease, timetonexthound = 0, totalplayerage=playerAge}
		else
			table.insert(_spawninfo[group].players, player)
			_spawninfo[group].houndstorelease = _spawninfo[group].houndstorelease + houndsToRelease
			_spawninfo[group].totalplayerage = _spawninfo[group].totalplayerage + playerAge
		end
	end

	-- some groups were created then destroyed in the first step, crunch the array so we can ipairs() over it
	_spawninfo = GetFlattenedSparse(_spawninfo)

	-- we want fewer hounds for larger groups of players so they don't get overwhelmed
	for i, info in ipairs(_spawninfo) do

		-- pow the number of hounds by a fractional exponent, to stave off huge groups
		-- e.g. hounds ^ 1/1.1 for three players
		local groupexp = 1.0 / (ZERO_EXP + (EXP_PER_PLAYER * #info.players))
		info.houndstorelease = RoundBiasedDown(math.pow(info.houndstorelease, groupexp))

		info.averageplayerage = info.totalplayerage / #info.players
	end
end

local function GetSpawnPoint(pt)

    local theta = math.random() * 2 * PI
    local radius = HOUND_SPAWN_DIST

	local offset = FindWalkableOffset(pt, theta, radius, 12, true)
	if offset then
		return pt+offset
	end
end

local function GetSpecialHoundChance()
	local day = GetAveragePlayerAgeInDays()
	local chance = 0
	for k,v in ipairs(TUNING.HOUND_SPECIAL_CHANCE) do
	    if day > v.minday then
	        chance = v.chance
	    elseif day <= v.minday then
	        return chance
	    end
	end

	if TheWorld.state.issummer then
		chance = chance * 1.5
	end
	
	return chance
end

local function SummonHound(pt)
	assert(pt)
		
	local spawn_pt = GetSpawnPoint(pt)
	
	if spawn_pt then
		
		local prefab = "hound"
		local special_hound_chance = GetSpecialHoundChance()

		if math.random() < special_hound_chance then
		    if TheWorld.state.iswinter or TheWorld.state.isspring then
		        prefab = "icehound"
		    else
			    prefab = "firehound"
			end
		end
		
		local hound = SpawnPrefab(prefab)
		if hound then
			hound.Physics:Teleport(spawn_pt:Get())
			hound:FacePoint(pt)

			return hound
		end
	end
end

local function ReleaseHound(target)
	local pt = Vector3(target.Transform:GetWorldPosition())
	
	local hound = SummonHound(pt)
	if hound then
		hound.components.combat:SuggestTarget(target)
		return true
	end

	return false
end

local function RemovePendingSpawns(player)
    if _spawninfo ~= nil then
    	for i,spawninforec in ipairs(_spawninfo) do
    		if spawninforec.player == player then
    			table.remove(_spawninfo, i)
    			return
    		end
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
    table.insert(_activeplayers, player)
end

local function OnPlayerLeft(src, player)
    for i, v in ipairs(_activeplayers) do
        if v == player then
			RemovePendingSpawns(player)
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
inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)

self.inst:StartUpdatingComponent(self)
PlanNextHoundAttack()

--------------------------------------------------------------------------
--[[ Public getters and setters ]]
--------------------------------------------------------------------------

function self:GetTimeToAttack()
	return _timetoattack
end

function self:GetWarning()
	return _warning
end

function self:GetAttacking()
	return ((_timetoattack <= 0) and _attackplanned)
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:SpawnModeEscalating()
	_spawnmode = "escalating"
	PlanNextHoundAttack()
end

function self:SpawnModeNever()
	_spawnmode = "never"
	PlanNextHoundAttack()
end

function self:SpawnModeHeavy()
	_spawnmode = "constant"
	_attackdelayfn = attack_delays.frequent
	_attacksizefn = attack_levels.heavy.numhounds
	_warndurationfn = attack_levels.heavy.warnduration
	PlanNextHoundAttack()
end

function self:SpawnModeMed()
	_spawnmode = "constant"
	_attackdelayfn = attack_delays.occasional
	_attacksizefn = attack_levels.med.numhounds
	_warndurationfn = attack_levels.med.warnduration
	PlanNextHoundAttack()
end

function self:SpawnModeLight()
	_spawnmode = "constant"
	_attackdelayfn = attack_delays.rare
	_attacksizefn = attack_levels.light.numhounds
	_warndurationfn = attack_levels.light.warnduration
	PlanNextHoundAttack()
end

-- Releases a hound near and attacking 'target'
function self:ForceReleaseHound(target)
	if target then
		ReleaseHound(target)
	end
end

-- Creates a hound near 'pt'
function self:SummonHound(pt)
	if pt then
		return SummonHound(pt)
	end
end

-- Spawns the next wave for debugging
function self:ForceNextHoundWave()
	PlanNextHoundAttack()
	_timetoattack = 0
	self:OnUpdate(1)
end

local function _DoWarningSpeech(player)
    player.components.talker:Say(GetString(player.prefab, "ANNOUNCE_HOUNDS"))
end

function self:DoWarningSpeech()
    for i, v in ipairs(_activeplayers) do
        v:DoTaskInTime(math.random() * 2, _DoWarningSpeech)
    end
end

function self:DoWarningSound()
    --All players hear their own warning sound from a random
    --random direction relative to their own local positions
    SpawnPrefab("houndwarning_lvl"..
        (((_timetoattack == nil or
        _timetoattack < 30) and "4") or
        (_timetoattack < 60 and "3") or
        (_timetoattack < 90 and "2") or
                                "1")
    )
end

function self:OnUpdate(dt)
	if _spawnmode == "never" then
		return
	end
	
	-- if there's no players, then don't even try
	if #_activeplayers == 0  or not _attackplanned then
		return
	end

	_timetoattack = _timetoattack - dt

	if _timetoattack < 0 then
		-- Okay, it's hound-day, get number of dogs for each player
		if not _spawninfo then
			GetHoundAmounts()
		end

		_warning = false

		local playersdone = {}		
		for i,spawninforec in ipairs(_spawninfo) do
			spawninforec.timetonexthound = spawninforec.timetonexthound - dt		
		
			if spawninforec.houndstorelease > 0 and spawninforec.timetonexthound < 0 then
				-- hounds can attack anyone in the group, even new players.
				-- That's the risk you take!
				local playeridx = math.random(#spawninforec.players)
				ReleaseHound(spawninforec.players[playeridx]) 
				spawninforec.houndstorelease = spawninforec.houndstorelease - 1

				local day = spawninforec.averageplayerage / TUNING.TOTAL_DAY_TIME
				if day < 20 then
					spawninforec.timetonexthound = 3 + math.random()*5
				elseif day < 60 then
					spawninforec.timetonexthound = 2 + math.random()*3
				elseif day < 100 then
					spawninforec.timetonexthound = .5 + math.random()*3
				else
					spawninforec.timetonexthound = .5 + math.random()*1
				end

			end
			if spawninforec.houndstorelease <= 0 then
				table.insert(playersdone,i)
			end
		end
		for i,v in ipairs(playersdone) do
			table.remove(_spawninfo, v)
		end
		if #_spawninfo == 0 then
			_spawninfo = nil
			PlanNextHoundAttack()
		end
	else
		if not _warning and _timetoattack < _warnduration then
			_warning = true
			_timetonextwarningsound = 0
		end
	end

    if _warning then
        _timetonextwarningsound	= _timetonextwarningsound - dt

        if _timetonextwarningsound <= 0 then
            _announcewarningsoundinterval = _announcewarningsoundinterval - 1
            if _announcewarningsoundinterval <= 0 then
                _announcewarningsoundinterval = 10 + math.random(5)
                self:DoWarningSpeech()
            end

            _timetonextwarningsound =
                (_timetoattack < 30 and .3 + math.random(1)) or
                (_timetoattack < 60 and 2 + math.random(1)) or
                (_timetoattack < 90 and 4 + math.random(2)) or
                                        5 + math.random(4)
            self:DoWarningSound()
        end
    end
end

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
	return 
	{
		warning = _warning,
		timetoattack = _timetoattack,
		warnduration = _warnduration,
		attackplanned = _attackplanned,
	}
end

function self:OnLoad(data)
	_warning = data.warning or false
	_warnduration = data.warnduration or 0
	_timetoattack = data.timetoattack or 0
	_attackplanned = data.attackplanned  or false
	if _timetoattack > _warnduration then
		-- in case everything went out of sync
		_warning = false
	end
	if _attackplanned then
		if _timetoattack < _warnduration then
			-- at least give players a fighting chance if we quit during the warning phase
			_timetoattack = _warnduration + 5
		end
	else
		PlanNextHoundAttack()
	end
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
	if _timetoattack > 0 then
		return string.format("%s hounds are coming in %2.2f", _warning and "WARNING" or "WAITING",   _timetoattack)
	else	
		local s = "ATTACKING\n"
		for i, spawninforec in ipairs(_spawninfo) do
			s = s..tostring(spawninforec.player).." - hounds left:"..tostring(spawninforec.houndstorelease).." next hound:"..tostring(spawninforec.timetonexthound)
			if i ~= #_activeplayers then
				s = s.."\n"
			end
		end
		return s
	end
end


end)