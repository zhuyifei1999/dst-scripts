--------------------------------------------------------------------------
--[[ brightmarespawner class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "Brightmare spawner should not exist on client")

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local POP_CHANGE_INTERVAL = 10
local POP_CHANGE_VARIANCE = 2

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _map = TheWorld.Map
local _players = {}
local _gestalts = {}
local _poptask = nil
local _evolved_spawn_pool = 0

local _worldsettingstimer = TheWorld.components.worldsettingstimer
local ADDEVOLVED_TIMERNAME = "add_evolved_gestalt_to_pool"

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function despawn_evolved_gestalt(gestalt)
	gestalt._do_despawn = true
	gestalt:PushEvent("force_relocate")
	_evolved_spawn_pool = _evolved_spawn_pool + 1
end

local function on_sleep_despawned(gestalt)
	_evolved_spawn_pool = _evolved_spawn_pool + 1
end

local function GetTuningLevelForPlayer(player)
	local shard_wagbossinfo = TheWorld.shard.components.shard_wagbossinfo
    local sanity = (
			(player.components.sanity:IsLunacyMode() or (shard_wagbossinfo and shard_wagbossinfo:IsWagbossDefeated()))
			and player.components.sanity:GetPercentWithPenalty()
		) or 0
	if sanity >= TUNING.GESTALT_MIN_SANITY_TO_SPAWN then
		for k, v in ipairs(TUNING.GESTALT_POPULATION_LEVEL) do
			if sanity <= v.MAX_SANITY then
				return k, v
			end
		end
	end

	return 0, nil
end

local function IsValidTrackingTarget(target)
	return (target.components.health ~= nil and not target.components.health:IsDead())
		and not target:HasTag("playerghost")
		and target.entity:IsVisible()
end

local function StopTracking(ent)
	_gestalts[ent] = nil
end

local function GetGestaltSpawnType(player, pt)
	local type = "gestalt"

	if not TheWorld.Map:IsPointInWagPunkArenaAndBarrierIsUp(pt:Get()) then
		local do_extra_spawns = (player.components.inventory ~= nil and player.components.inventory:EquipHasTag("lunarseedmaxed"))

		local shard_wagbossinfo = TheWorld.shard.components.shard_wagbossinfo
		if shard_wagbossinfo and shard_wagbossinfo:IsWagbossDefeated() then
			local num_evolved = 0
			for ent in pairs(_gestalts) do
				if ent.prefab == "gestalt_guard_evolved" then
					num_evolved = num_evolved + 1
				end
			end

			if (num_evolved < TUNING.GESTALT_EVOLVED_MAXSPAWN or (do_extra_spawns and num_evolved < TUNING.GESTALT_EVOLVED_MAXSPAWN_HAT))
					and _evolved_spawn_pool > 0 then
				type = "gestalt_guard_evolved"
				_evolved_spawn_pool = _evolved_spawn_pool - 1
			end
		end
	end

	return type
end

local SPAWN_ONEOF_TAGS = {"brightmare_gestalt", "player", "playerghost"}
local function FindGestaltSpawnPtForPlayer(player, wantstomorph)
	local x, y, z = player.Transform:GetWorldPosition()

	local function IsValidGestaltSpawnPt(offset)
		local x1, z1 = x + offset.x, z + offset.z
		return #TheSim:FindEntities(x1, 0, z1, 6, nil, nil, SPAWN_ONEOF_TAGS) == 0
	end

    local offset = FindValidPositionByFan(
		math.random() * TWOPI,
		(wantstomorph and TUNING.GESTALT_SPAWN_MORPH_DIST or TUNING.GESTALT_SPAWN_DIST) + math.random() * 2 * TUNING.GESTALT_SPAWN_DIST_VAR - TUNING.GESTALT_SPAWN_DIST_VAR,
		8,
		IsValidGestaltSpawnPt
	)
	if offset ~= nil then
		offset.x = offset.x + x
		offset.z = offset.z + z
	end

	return offset
end

local function TrySpawnGestaltForPlayer(player, level, data)
	local pt = FindGestaltSpawnPtForPlayer(player, false)
	if pt ~= nil then
        local ent = SpawnPrefab(GetGestaltSpawnType(player, pt))
		_gestalts[ent] = true
		inst:ListenForEvent("onremove", StopTracking, ent)
		inst:ListenForEvent("sleep_despawn", on_sleep_despawned, ent)
        ent.Transform:SetPosition(pt.x, 0, pt.z)
		ent:SetTrackingTarget(player, GetTuningLevelForPlayer(player))
		ent:PushEvent("spawned")
	end
end

local BRIGHTMARE_TAGS = {"brightmare"}
local function UpdatePopulation()
	local shard_wagbossinfo = TheWorld.shard.components.shard_wagbossinfo
	local increased_spawn_factor = (shard_wagbossinfo
		and shard_wagbossinfo:IsWagbossDefeated()
		and TUNING.WAGBOSS_DEFEATED_GESTALT_SPAWN_FACTOR)
		or 1

	local total_levels = 0
	for player in pairs(_players) do
		if IsValidTrackingTarget(player) then
			local level, data = GetTuningLevelForPlayer(player)
			total_levels = total_levels + level

			if level > 0 then
				local x, y, z = player.Transform:GetWorldPosition()
				local gestalts = TheSim:FindEntities(x, y, z, TUNING.GESTALT_POPULATION_DIST, BRIGHTMARE_TAGS)
				local maxpop = data.MAX_SPAWNS
				local inc_chance = (#gestalts >= maxpop and 0)
								or (level == 1 and 0.2)
								or (level == 2 and 0.3)
								or 0.4

				inc_chance = inc_chance * increased_spawn_factor
				if math.random() < inc_chance then
					TrySpawnGestaltForPlayer(player, level, data)
				end
			end
		end
	end

	local min_change = math.min(total_levels, TUNING.GESTALT_POP_CHANGE_INTERVAL / 2)
	local random_change = TUNING.GESTALT_POP_CHANGE_VARIANCE * math.random()

	local next_task_time = TUNING.GESTALT_POP_CHANGE_INTERVAL - min_change + random_change
    _poptask = inst:DoTaskInTime(next_task_time, UpdatePopulation)
end

local function Start()
	_poptask = _poptask or inst:DoTaskInTime(0, UpdatePopulation)
end

local function Stop()
    if _poptask ~= nil then
        _poptask:Cancel()
        _poptask = nil
    end
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:FindBestPlayer(gestalt)
	local closest_player = nil
	local closest_distsq = TUNING.GESTALT_POPULATION_DIST * TUNING.GESTALT_POPULATION_DIST
	local closest_level = 0

	for player in pairs(_players) do
        if IsValidTrackingTarget(player) then
			local x, y, z = player.Transform:GetWorldPosition()
            local distsq = gestalt:GetDistanceSqToPoint(x, y, z)
            if distsq < closest_distsq then
				local level, data = GetTuningLevelForPlayer(player)
				if level > 0 and #TheSim:FindEntities(x, y, z, TUNING.GESTALT_POPULATION_DIST, BRIGHTMARE_TAGS) <= (data.MAX_SPAWNS + 1) then
	                closest_distsq = distsq
		            closest_player = player
					closest_level = level
				end
            end
        end
	end

	return closest_player, closest_level
end

function self:FindRelocatePoint(gestalt)
	return gestalt.tracking_target ~= nil and FindGestaltSpawnPtForPlayer(gestalt.tracking_target, gestalt.wantstomorph) or nil
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnSanityModeChanged(player, data)
	local is_lunacy = (data ~= nil and data.mode == SANITY_MODE_LUNACY)
	if is_lunacy then
		_players[player] = true
	else
		_players[player] = nil
	end

	-- We could check for WagbossDefeated too, but there shouldn't be any gestalt_guard_evolved prefabs
	-- in the world if that's false. Shouldn't need to control for debug spawning here.
	local gestalts_tracking_player = nil
	for gestalt in pairs(_gestalts) do
		if gestalt.prefab == "gestalt_guard_evolved" and gestalt.tracking_target == player and not gestalt._do_despawn then
			gestalts_tracking_player = gestalts_tracking_player or {}
			table.insert(gestalts_tracking_player, gestalt)
		end
	end

	if gestalts_tracking_player then
		-- If we're not in lunacy mode anymore, clean up all of the gestalts.
		-- If we are, but the hat is off, go down to our normal amount.
		if not is_lunacy then
			for _, gestalt in pairs(gestalts_tracking_player) do
				despawn_evolved_gestalt(gestalt)
			end
		elseif not (player.components.inventory ~= nil and player.components.inventory:EquipHasTag("lunarseedmaxed")) then
			shuffleArray(gestalts_tracking_player)
			for i, gestalt in ipairs(gestalts_tracking_player) do
				if i > TUNING.GESTALT_EVOLVED_MAXSPAWN then
					despawn_evolved_gestalt(gestalt)
				end
			end
		end
	end

	if next(_players) ~= nil then
		Start()
	else
		Stop()
	end
end

local function OnEquipmentChanged(player, data)
	local gestalts_tracking_player = nil
	for gestalt in pairs(_gestalts) do
		if gestalt.prefab == "gestalt_guard_evolved" and gestalt.tracking_target == player and not gestalt._do_despawn then
			gestalts_tracking_player = gestalts_tracking_player or {}
			table.insert(gestalts_tracking_player, gestalt)
		end
	end

	local is_lunacy = (player.components.sanity and player.components.sanity:GetSanityMode() == SANITY_MODE_LUNACY)
	if gestalts_tracking_player then
		if not is_lunacy then
			for _, gestalt in pairs(gestalts_tracking_player) do
				despawn_evolved_gestalt(gestalt)
			end
		elseif player.components.inventory == nil or not player.components.inventory:EquipHasTag("lunarseedmaxed") then
			shuffleArray(gestalts_tracking_player)
			for i, gestalt in ipairs(gestalts_tracking_player) do
				if i > TUNING.GESTALT_EVOLVED_MAXSPAWN then
					despawn_evolved_gestalt(gestalt)
				end
			end
		end
	end
end

local function OnPlayerJoined(i, player)
    i:ListenForEvent("sanitymodechanged", OnSanityModeChanged, player)
	i:ListenForEvent("equip", OnEquipmentChanged, player)
	i:ListenForEvent("unequip", OnEquipmentChanged, player)
	if player.components.sanity:IsLunacyMode() then
		OnSanityModeChanged(player, {mode = player.components.sanity:GetSanityMode()})
	end
end

local function OnPlayerLeft(i, player)
    i:RemoveEventCallback("sanitymodechanged", OnSanityModeChanged, player)
	i:RemoveEventCallback("equip", OnEquipmentChanged, player)
	i:RemoveEventCallback("unequip", OnEquipmentChanged, player)
	OnSanityModeChanged(player, nil)
end

local function OnWagbossDefeated()
	_evolved_spawn_pool = math.max(1, _evolved_spawn_pool or 0)
	_worldsettingstimer:StartTimer(ADDEVOLVED_TIMERNAME, TUNING.GESTALT_EVOLVED_ADDTOPOOLTIME)
end

local function OnEvolvedAddedToPool(_, data)
	if _evolved_spawn_pool < TUNING.GESTALT_EVOLVED_MAXPOOL then
		_evolved_spawn_pool = _evolved_spawn_pool + 1
	end
	_worldsettingstimer:StartTimer(ADDEVOLVED_TIMERNAME, TUNING.GESTALT_EVOLVED_ADDTOPOOLTIME)
end
_worldsettingstimer:AddTimer(ADDEVOLVED_TIMERNAME, TUNING.GESTALT_EVOLVED_ADDTOPOOLTIME, TUNING.GESTALT_EVOLVED_MAXPOOL > 0, OnEvolvedAddedToPool)

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
	return (_evolved_spawn_pool > 0 and {
		evolved_spawn_pool = _evolved_spawn_pool,
	}) or nil
end

function self:OnLoad(data)
	if data and data.evolved_spawn_pool then
		_evolved_spawn_pool = data.evolved_spawn_pool or 0
	end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Initialize variables
for i, v in pairs(AllPlayers) do
    OnPlayerJoined(inst, v)
end

--Register events
inst:ListenForEvent("ms_playerjoined", OnPlayerJoined)
inst:ListenForEvent("ms_playerleft", OnPlayerLeft)
inst:ListenForEvent("wagboss_defeated", OnWagbossDefeated)

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    return tostring(GetTableSize(_gestalts)) .. " Gestalts; Evolved Pool size is:" .. tostring(_evolved_spawn_pool)
end

function self:Debug_SetSpawnPoolSize(size)
	-- Don't nuke it out if we accidentally debug with nil
	_evolved_spawn_pool = size or _evolved_spawn_pool
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)