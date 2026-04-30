local MapRevealer = Class(function(self, inst)
    self.inst = inst

    self.revealperiod = 5
    self.task = nil
	self.privateowner = nil
	self._players = {} --cached table used for periodic updates

    --V2C: Recommended to explicitly add tag to prefab pristine state
    --inst:AddTag("maprevealer")
    --Added in Start function

    self:Start()
end)

local function OnRestart(inst, self, delay)
    self.task = nil
    self:Start(delay)
end

local function OnRevealing(inst, self, delay, players)
    local player = table.remove(players)
    while not player:IsValid() do
        if #players <= 0 then
            OnRestart(inst, self, delay)
            return
        end
        player = table.remove(players)
    end

    self:RevealMapToPlayer(player)

    if #players > 0 then
        self.task = inst:DoTaskInTime(delay, OnRevealing, self, delay, players)
    else
        OnRestart(inst, self, delay)
    end
end

local function OnStart(inst, self)
	assert(#self._players == 0)

	if self.privateowner then
		if self.privateowner.isplayer and self.privateowner:IsValid() then
			self._players[1] = self.privateowner
			OnRevealing(inst, self, self.revealperiod, self._players)
		else
			self:Stop()
		end
	elseif #AllPlayers > 0 then
        for i, v in ipairs(AllPlayers) do
			self._players[i] = v
        end
		OnRevealing(inst, self, self.revealperiod / #self._players, self._players)
    else
        OnRestart(inst, self, self.revealperiod)
    end
end

function MapRevealer:Start(delay)
    if self.task == nil then
        self.inst:AddTag("maprevealer")
        self.task = self.inst:DoTaskInTime(delay or math.random() * .5, OnStart, self)
    end
end

function MapRevealer:Stop()
    if self.task ~= nil then
        self.inst:RemoveTag("maprevealer")
        self.task:Cancel()
        self.task = nil

		for i = 1, #self._players do
			self._players[i] = nil
		end
    end
end

function MapRevealer:RevealMapToPlayer(player)
    if player._PostActivateHandshakeState_Server ~= POSTACTIVATEHANDSHAKE.READY then
        return -- Wait until the player client is ready and has received the world size info.
    end

    if player.player_classified ~= nil then
        player.player_classified.MapExplorer:RevealArea(self.inst.Transform:GetWorldPosition())
    end
end

function MapRevealer:SetPrivateOwner(owner)
	if self.privateowner ~= owner then
		self.privateowner = owner

		if self.task then
			self:Stop()
			self:Start()
		end
	end
end

function MapRevealer:GetPrivateOwner()
	return self.privateowner
end

function MapRevealer:RestartPrivateRevealCooldown()
	if self.task then
		self.task:Cancel()
		self.task = nil

		for i = 1, #self._players do
			self._players[i] = nil
		end

		self:Start(self.revealperiod)
	end
end

MapRevealer.OnRemoveFromEntity = MapRevealer.Stop

return MapRevealer
