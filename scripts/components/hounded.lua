--------------------------------------------------------------------------
--[[ Hounded class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "Hounded should not exist on client")

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local SPAWN_DIST = 30

local attack_levels =
{
	intro	=	{ warnduration = function() return 120 end, numspawns = function() return 2 end },
	light	=	{ warnduration = function() return 60 end, numspawns = function() return 2 + math.random(2) end },
	med		=	{ warnduration = function() return 45 end, numspawns = function() return 3 + math.random(3) end },
	heavy	=	{ warnduration = function() return 30 end, numspawns = function() return 4 + math.random(3) end },
	crazy	=	{ warnduration = function() return 30 end, numspawns = function() return 6 + math.random(4) end },
}

local attack_delays =
{
	rare		= function() return TUNING.TOTAL_DAY_TIME * 6, math.random() * TUNING.TOTAL_DAY_TIME * 7 end,
	occasional	= function() return TUNING.TOTAL_DAY_TIME * 4, math.random() * TUNING.TOTAL_DAY_TIME * 7 end,
	frequent	= function() return TUNING.TOTAL_DAY_TIME * 3, math.random() * TUNING.TOTAL_DAY_TIME * 5 end,
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

--Configure this data using hounded:SetSpawnData
local _spawndata =
	{
		base_prefab = "hound",
		winter_prefab = "icehound",
		summer_prefab = "firehound",

		attack_levels =
		{
			intro 	= { warnduration = function() return 120 end, numspawns = function() return 2 end },
			light 	= { warnduration = function() return 60 end, numspawns = function() return 2 + math.random(2) end },
			med 	= { warnduration = function() return 45 end, numspawns = function() return 3 + math.random(3) end },
			heavy 	= { warnduration = function() return 30 end, numspawns = function() return 4 + math.random(3) end },
			crazy 	= { warnduration = function() return 30 end, numspawns = function() return 6 + math.random(4) end },
		},

		attack_delays =
		{
			rare 		= function() return TUNING.TOTAL_DAY_TIME * 6, math.random() * TUNING.TOTAL_DAY_TIME * 7 end,
			occasional 	= function() return TUNING.TOTAL_DAY_TIME * 4, math.random() * TUNING.TOTAL_DAY_TIME * 7 end,
			frequent 	= function() return TUNING.TOTAL_DAY_TIME * 3, math.random() * TUNING.TOTAL_DAY_TIME * 5 end,
		},

		warning_speech = "ANNOUNCE_HOUND",
		warning_sound_thresholds =
		{	--Key = time, Value = sound prefab
			{time = 30, sound = "houndwarning_lvl4"},
			{time = 60, sound = "houndwarning_lvl3"},
			{time = 90, sound = "houndwarning_lvl2"},
			{time = 500, sound = "houndwarning_lvl1"},
		},
	}

local _attackdelayfn = _spawndata.attack_delays.occasional
local _attacksizefn = _spawndata.attack_levels.light.numspawns
local _warndurationfn = _spawndata.attack_levels.light.warnduration
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
		_attackdelayfn = _spawndata.attack_delays.rare
		_attacksizefn = _spawndata.attack_levels.intro.numspawns
		_warndurationfn = _spawndata.attack_levels.intro.warnduration
	elseif day < 25 then
		_attackdelayfn = _spawndata.attack_delays.rare
		_attacksizefn = _spawndata.attack_levels.light.numspawns
		_warndurationfn = _spawndata.attack_levels.light.warnduration
	elseif day < 50 then
		_attackdelayfn = _spawndata.attack_delays.occasional
		_attacksizefn = _spawndata.attack_levels.med.numspawns
		_warndurationfn = _spawndata.attack_levels.med.warnduration
	elseif day < 100 then
		_attackdelayfn = _spawndata.attack_delays.occasional
		_attacksizefn = _spawndata.attack_levels.heavy.numspawns
		_warndurationfn = _spawndata.attack_levels.heavy.warnduration
	else
		_attackdelayfn = _spawndata.attack_delays.frequent
		_attacksizefn = _spawndata.attack_levels.crazy.numspawns
		_warndurationfn = _spawndata.attack_levels.crazy.warnduration
	end

end

local function CalcPlayerAttackSize(player)
	local day = player.components.age:GetAgeInDays()
	local attacksize = 0
	if day < 10 then
		attacksize = _spawndata.attack_levels.intro.numspawns()
	elseif day < 25 then
		attacksize = _spawndata.attack_levels.light.numspawns()
	elseif day < 50 then
		attacksize = _spawndata.attack_levels.med.numspawns()
	elseif day < 100 then
		attacksize = _spawndata.attack_levels.heavy.numspawns()
	else
		attacksize = _spawndata.attack_levels.crazy.numspawns()
	end
	return attacksize
end

local function PlanNextAttack()
	if _timetoattack > 0 then
		-- we came in through a savegame that already had an attack scheduled
		return
	end
	-- if there are no players then try again later
	if #_activeplayers == 0 then
		_attackplanned = false
		self.inst:DoTaskInTime(1, PlanNextAttack)
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

local function GetWaveAmounts()

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
		local spawnsToRelease = CalcPlayerAttackSize(player)
		local playerInGame = GetTime() - player.components.age.spawntime

		-- if we never saw a warning or have lived shorter than the minimum wave delay then don't spawn hounds to us
		if playerInGame <= _warnduration or playerAge < attackdelaybase then
			spawnsToRelease = 0
		end

		if _spawninfo[group] == nil then
			_spawninfo[group] = {players = {player}, spawnstorelease = spawnsToRelease, timetonext = 0, totalplayerage=playerAge}
		else
			table.insert(_spawninfo[group].players, player)
			_spawninfo[group].spawnstorelease = _spawninfo[group].spawnstorelease + spawnsToRelease
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
		info.spawnstorelease = RoundBiasedDown(math.pow(info.spawnstorelease, groupexp))

		info.averageplayerage = info.totalplayerage / #info.players
	end
end

local function NoHoles(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end

local function GetSpawnPoint(pt)
    local offset = FindWalkableOffset(pt, math.random() * 2 * PI, SPAWN_DIST, 12, true, true, NoHoles)
    if offset ~= nil then
        offset.x = offset.x + pt.x
        offset.z = offset.z + pt.z
        return offset
    end
end

local function GetSpecialSpawnChance()
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

local function SummonSpawn(pt)
	assert(pt)

	local spawn_pt = GetSpawnPoint(pt)

	if spawn_pt then

		local prefab = _spawndata.base_prefab
		local special_spawn_chance = GetSpecialSpawnChance()

		if math.random() < special_spawn_chance then
		    if TheWorld.state.iswinter or TheWorld.state.isspring then
		        prefab = _spawndata.winter_prefab
		    else
			    prefab = _spawndata.summer_prefab
			end
		end

		local spawn = SpawnPrefab(prefab)
		if spawn then
			spawn.Physics:Teleport(spawn_pt:Get())
			spawn:FacePoint(pt)
            if spawn.components.spawnfader ~= nil then
                spawn.components.spawnfader:FadeIn()
            end

			return spawn
		end
	end
end

local function ReleaseSpawn(target)
	local pt = Vector3(target.Transform:GetWorldPosition())

	local spawn = SummonSpawn(pt)
	if spawn then
		spawn.components.combat:SuggestTarget(target)
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
PlanNextAttack()

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

function self:SetSpawnData(data)
	_spawndata = data
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:SpawnModeEscalating()
	_spawnmode = "escalating"
	PlanNextAttack()
end

function self:SpawnModeNever()
	_spawnmode = "never"
	PlanNextAttack()
end

function self:SpawnModeHeavy()
	_spawnmode = "constant"
	_attackdelayfn = _spawndata.attack_delays.frequent
	_attacksizefn = _spawndata.attack_levels.heavy.numspawns
	_warndurationfn = _spawndata.attack_levels.heavy.warnduration
	PlanNextAttack()
end

function self:SpawnModeMed()
	_spawnmode = "constant"
	_attackdelayfn = _spawndata.attack_delays.occasional
	_attacksizefn = _spawndata.attack_levels.med.numspawns
	_warndurationfn = _spawndata.attack_levels.med.warnduration
	PlanNextAttack()
end

function self:SpawnModeLight()
	_spawnmode = "constant"
	_attackdelayfn = _spawndata.attack_delays.rare
	_attacksizefn = _spawndata.attack_levels.light.numspawns
	_warndurationfn = _spawndata.attack_levels.light.warnduration
	PlanNextAttack()
end

-- Releases a hound near and attacking 'target'
function self:ForceReleaseSpawn(target)
	if target then
		ReleaseSpawn(target)
	end
end

-- Creates a hound near 'pt'
function self:SummonSpawn(pt)
	if pt then
		return SummonSpawn(pt)
	end
end

-- Spawns the next wave for debugging
function self:ForceNextWave()
	PlanNextAttack()
	_timetoattack = 0
	self:OnUpdate(1)
end

local function _DoWarningSpeech(player)
    player.components.talker:Say(GetString(player, _spawndata.warning_speech))
end

function self:DoWarningSpeech()
    for i, v in ipairs(_activeplayers) do
        v:DoTaskInTime(math.random() * 2, _DoWarningSpeech)
    end
end

function self:DoWarningSound()
    for k,v in pairs(_spawndata.warning_sound_thresholds) do
    	if _timetoattack <= v.time or _timetoattack == nil then
    		SpawnPrefab(v.sound)
    	end
    end
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
			GetWaveAmounts()
		end

		_warning = false

		local playersdone = {}
		for i,spawninforec in ipairs(_spawninfo) do
			spawninforec.timetonext = spawninforec.timetonext - dt
			if spawninforec.spawnstorelease > 0 and spawninforec.timetonext < 0 then
				-- hounds can attack anyone in the group, even new players.
				-- That's the risk you take!
				local playeridx = math.random(#spawninforec.players)
				ReleaseSpawn(spawninforec.players[playeridx])
				spawninforec.spawnstorelease = spawninforec.spawnstorelease - 1

				local day = spawninforec.averageplayerage / TUNING.TOTAL_DAY_TIME
				if day < 20 then
					spawninforec.timetonext = 3 + math.random()*5
				elseif day < 60 then
					spawninforec.timetonext = 2 + math.random()*3
				elseif day < 100 then
					spawninforec.timetonext = .5 + math.random()*3
				else
					spawninforec.timetonext = .5 + math.random()*1
				end

			end
			if spawninforec.spawnstorelease <= 0 then
				table.insert(playersdone,i)
			end
		end
		for i,v in ipairs(playersdone) do
			table.remove(_spawninfo, v)
		end
		if #_spawninfo == 0 then
			_spawninfo = nil
			PlanNextAttack()
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

function self:LongUpdate(dt)
	self:OnUpdate(dt)
end

--self.LongUpdate = self.OnUdpate
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
		PlanNextAttack()
	end
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
	if _timetoattack > 0 then
		return string.format("%s spawns are coming in %2.2f", _warning and "WARNING" or "WAITING",   _timetoattack)
	else
		local s = "ATTACKING\n"
		for i, spawninforec in ipairs(_spawninfo) do
			s = s..tostring(spawninforec.player).." - spawns left:"..tostring(spawninforec.spawnstorelease).." next spawn:"..tostring(spawninforec.timetonext)
			if i ~= #_activeplayers then
				s = s.."\n"
			end
		end
		return s
	end
end


end)
