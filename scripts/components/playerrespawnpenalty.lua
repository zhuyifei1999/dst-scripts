--------------------------------------------------------------------------
--[[ PlayerRespawnPenalty class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "PlayerRespawnPenalty should not exist on client")

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _clients = {}

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function DoRespawnPenalty(player, respawns)
    local preventburning = {}
    for i, v in ipairs(AllPlayers) do
        if v.components.health ~= nil and not v.components.health:IsDead() then
            --#v2c hacky way to prevent lightning from igniting us
            if v.components.burnable ~= nil and not v.components.burnable.burning then
                v.components.burnable.burning = true
                table.insert(preventburning, v)
            end
        end
    end

    for i, v in ipairs(AllPlayers) do
        if v.components.health ~= nil and not v.components.health:IsDead() then
            --Lightning FX
            inst:PushEvent("ms_sendlightningstrike", v:GetPosition())

            --Health penalty
            if v == player then
                v.components.health.teamrespawnpenalty = respawns * v.components.health.maxhealth / 3
            else
                v.components.health.teamrespawnpenalty = v.components.health.teamrespawnpenalty + v.components.health.maxhealth / 3
            end
            v.components.health:RecalculatePenalty(true)
        end
    end

    --#v2c hacky way to prevent lightning from igniting us
    for i, v in ipairs(preventburning) do
        v.components.burnable.burning = false
    end
end

local function TimeoutClients()
    --If a client hasn't respawned in a while,
    --then reset their respawn counter
    local t = GetTime() - 900 --15min
    for k, v in pairs(_clients) do
        if v.t ~= nil and v.t < t then
            _clients[k] = nil
        end
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnSetOwner(player)
    TimeoutClients()

    local id = player.Network:GetUserID()
    if _clients[id] == nil then
        _clients[id] = { respawns = 0 }
    else
        _clients[id].t = nil
        _clients[id].respawns = _clients[id].respawns + 1
        print("PLAYER ID: "..tostring(id).." RESPAWN COUNT: "..tostring(_clients[id].respawns))

        DoRespawnPenalty(player, _clients[id].respawns)
    end
end

local function OnPlayerSpawn(inst, player)
    inst:ListenForEvent("setowner", OnSetOwner, player)
end

local function OnPlayerLeft(inst, player)
    local id = player.Network:GetUserID()
    if _clients[id] ~= nil then
        _clients[id].t = GetTime()
    end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Register events
inst:ListenForEvent("ms_playerspawn", OnPlayerSpawn)
inst:ListenForEvent("ms_playerleft", OnPlayerLeft)

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)