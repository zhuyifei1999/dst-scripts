local SPAWN_DIST = 30

--------------------------------------------------------------------------
--[[ Kramped class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "Kramped should not exist on client")

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst
    
--Private
local _activeplayers = {}

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function GetSpawnPoint(pt)

    local theta = math.random() * 2 * PI
    local radius = SPAWN_DIST
    
	local offset = FindWalkableOffset(pt, theta, radius, 12, true)
	if offset then
		return pt+offset
	end
end

local function MakeAKrampusForPlayer(player)
	local pt = Vector3(player.Transform:GetWorldPosition())
		
	local spawn_pt = GetSpawnPoint(pt)
	
	if spawn_pt then
	
		local kramp = SpawnPrefab("krampus")
		if kramp then
			kramp.Physics:Teleport(spawn_pt:Get())
			kramp:FacePoint(pt)
			kramp.spawnedforplayer = player
			kramp:ListenForEvent( "onremove",function() kramp.spawnedforplayer = nil end, player)
		end
	end
end

local function OnNaughtyAction(how_naughty, playerdata)
	local player = playerdata.player
	assert(player)

	if playerdata.threshold == nil then
		playerdata.threshold = TUNING.KRAMPUS_THRESHOLD + math.random(TUNING.KRAMPUS_THRESHOLD_VARIANCE)
	end

	playerdata.actions = playerdata.actions + (how_naughty or 1)
	playerdata.timetodecay = TUNING.KRAMPUS_NAUGHTINESS_DECAY_PERIOD

	if playerdata.actions >= playerdata.threshold and playerdata.threshold > 0 then
		
		local day = TheWorld.state.cycles
		
		local num_krampii = 1
		playerdata.threshold = TUNING.KRAMPUS_THRESHOLD + math.random(TUNING.KRAMPUS_THRESHOLD_VARIANCE)
		playerdata.actions = 0
		
		if TUNING.KRAMPUS_INCREASE_RAMP <= 1 then	-- KAJ 21-3-14:math.random can't be called with < 1. I am assuming that setting "never" in the tuning means to never spawn
			return
		end
		
		if day > TUNING.KRAMPUS_INCREASE_LVL1 then
			num_krampii = num_krampii + math.random(TUNING.KRAMPUS_INCREASE_RAMP)
		elseif day > TUNING.KRAMPUS_INCREASE_LVL2 then
			num_krampii = num_krampii + 1 + math.random(TUNING.KRAMPUS_INCREASE_RAMP)
		end

		for k = 1, num_krampii do
			MakeAKrampusForPlayer(player)
		end
    else
        self:DoWarningSound(player)
    end
end

local function onkilledother(victim, killer)
	-- KAJ: what happens if mobs kill someone?
	if killer and killer:IsValid() and killer:HasTag("player") then
		if victim and victim.prefab then
			local player = killer
			-- get the playerdata for this player
			local playerdata = _activeplayers[player]
			assert(playerdata)
			if victim.prefab == "pigman" then
				if not victim.components.werebeast or not victim.components.werebeast:IsInWereState() then
					OnNaughtyAction(3, playerdata)
				end
			elseif victim.prefab == "babybeefalo" then
				OnNaughtyAction(6, playerdata)
			elseif victim.prefab == "teenbird" then
				OnNaughtyAction(2, playerdata)
			elseif victim.prefab == "smallbird" then
				OnNaughtyAction(6, playerdata)
			elseif victim.prefab == "beefalo" then
				OnNaughtyAction(4, playerdata)
			elseif victim.prefab == "crow" then
				OnNaughtyAction(1, playerdata)
			elseif victim.prefab == "robin" then
				OnNaughtyAction(2, playerdata)
			elseif victim.prefab == "robin_winter" then
				OnNaughtyAction(2, playerdata)
			elseif victim.prefab == "butterfly" then
				OnNaughtyAction(1, playerdata)
			elseif victim.prefab == "rabbit" then
				OnNaughtyAction(1, playerdata)
			elseif victim.prefab == "mole" then
				OnNaughtyAction(1, playerdata)
			elseif victim.prefab == "tallbird" then
				OnNaughtyAction(2, playerdata)
			elseif victim.prefab == "bunnyman" then
				OnNaughtyAction(3, playerdata)
			elseif victim.prefab == "penguin" then
				OnNaughtyAction(2, playerdata)
			elseif victim.prefab == "glommer" then
				OnNaughtyAction(50, playerdata) -- You've been bad!
			elseif victim.prefab == "catcoon" then
				OnNaughtyAction(5, playerdata)
			end
		end
	end
end

local function GetDebugStringForPlayer(playerdata)
	assert(playerdata)

	local playerString = string.format("Player %s - ", tostring(playerdata.player))
	if playerdata.actions and playerdata.threshold and playerdata.timetodecay then
		return playerString..string.format("Actions: %d / %d, decay in %2.2f", playerdata.actions, playerdata.threshold, playerdata.timetodecay)
	else
		return playerString.."Actions: 0"
	end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnPlayerJoined(src, player)
	if _activeplayers[player] then
		return
	end
	_activeplayers[player] = {
								player = player,
								actions = 0,
								threshold = nil,
								timetodecay = TUNING.KRAMPUS_NAUGHTINESS_DECAY_PERIOD
							}
	if TUNING.KRAMPUS_THRESHOLD ~= -1 then
		self.inst:ListenForEvent( "killed", function(inst,data) onkilledother(data.victim, player) end, player )
	end
end

local function OnPlayerLeft(src, player)
	_activeplayers[player] = nil
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

for i, v in ipairs(AllPlayers) do
	OnPlayerJoined(self, v)
end

inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)

self.inst:StartUpdatingComponent(self)

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

local function _DoWarningSound(player)
    local playerdata = _activeplayers[player]
    if playerdata ~= nil then
        local score = (playerdata.threshold or 0) - playerdata.actions
        if score < 20 then
            SpawnPrefab("krampuswarning_lvl"..
                ((score < 5 and "3") or
                (score < 15 and "2") or
                                "1")
            ).Transform:SetPosition(player.Transform:GetWorldPosition())
        end
    end
end

function self:DoWarningSound(player)
    player:DoTaskInTime(1 + math.random() * 2, _DoWarningSound)
end

function self:OnUpdate(dt)	
	for _,playerdata in pairs(_activeplayers) do
		if playerdata.actions > 0 then
			playerdata.timetodecay = playerdata.timetodecay - dt
			
			if playerdata.timetodecay < 0 then
				playerdata.timetodecay = TUNING.KRAMPUS_NAUGHTINESS_DECAY_PERIOD
				playerdata.actions = playerdata.actions - 1
			end
		end
	end
end

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
	-- TODO:KAJ:This would need a mechanic for player saving, world saving is much less valid
end

function self:OnLoad(data)
	-- TODO:KAJ: See OnLoad
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
	local result = ""

	for player,playerdata in pairs(_activeplayers) do
		local str = GetDebugStringForPlayer(playerdata)
		if result ~= "" then
			result = result.."\n"
		end
		result = result..str
	end
	return result
end

end)