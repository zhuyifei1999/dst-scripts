--------------------------------------------------------------------------
--[[ PlayerSpawner class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "PlayerSpawner should not exist on client")

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

local easing = require("easing")

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local MODES =
{
    fixed = "Fixed",
    scatter = "Scatter",
}

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _mode = "fixed"
local _masterpt = nil
local _openpts = {}
local _usedpts = {}

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function GetNextSpawnPosition()
    if next(_openpts) == nil then
        print("No registered spawn points")
        return 0, 0, 0
    end

    local nextpoint
    if _mode == "scatter" then
        local nexti = math.min(math.floor(easing.inQuart(math.random(), 1, #_openpts, 1)), #_openpts)
        nextpoint = _openpts[nexti]
        table.remove(_openpts, nexti)
        table.insert(_usedpts, nextpoint)
    else --default to "fixed"
        if _masterpt == nil then
            print("No master spawn point")
            _masterpt = _openpts[1]
        end
        nextpoint = _masterpt
        for i, v in ipairs(_openpts) do
            if v == nextpoint then
                table.remove(_openpts, i)
                table.insert(_usedpts, nextpoint)
                break
            end
        end
    end

    if next(_openpts) == nil then
        local swap = _openpts
        _openpts = _usedpts
        _usedpts = swap
    end

    local x, y, z = nextpoint.Transform:GetWorldPosition()
    return x, 0, z
end

local function PlayerRemove(player, deletesession, readytoremove)
    if readytoremove then
        player:OnDespawn()
        if deletesession then
            DeleteUserSession(player)
        else
            SerializeUserSession(player)
        end
        player:Remove()
    else
        player:DoTaskInTime(0, PlayerRemove, deletesession, true)
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnPlayerDespawn(inst, player, cb)
    player.components.playercontroller:Enable(false)
    player.components.locomotor:StopMoving()
    player.components.locomotor:Clear()

    --Portal FX
    local fx = SpawnPrefab("spawn_fx_medium")
    if fx ~= nil then
        fx.Transform:SetPosition(player.Transform:GetWorldPosition())
    end

    --After colour tween, remove player via task, because
    --we don't want to remove during component update loop
    player.components.colourtweener:StartTween({ 0, 0, 0, 1 }, 13 * FRAMES, cb or PlayerRemove)
end

local function OnPlayerDespawnAndDelete(inst, player)
    OnPlayerDespawn(inst, player, function(player) PlayerRemove(player, true) end)
end

local function OnSetSpawnMode(inst, mode)
    if mode ~= nil or MODES[mode] ~= nil then
        _mode = mode
    else
        _mode = "fixed"
        print('Set spawn mode "'..tostring(mode)..'" -> defaulting to Fixed mode')
    end
end

local function UnregisterSpawnPoint(spawnpt)
    if spawnpt == nil then
        return
    elseif _masterpt == spawnpt then
        _masterpt = nil
    end
    RemoveByValue(_openpts, spawnpt)
    RemoveByValue(_usedpts, spawnpt)
end

local function OnRegisterSpawnPoint(inst, spawnpt)
    if spawnpt == nil or
        _masterpt == spawnpt or
        table.contains(_openpts, spawnpt) or
        table.contains(_usedpts, spawnpt) then
        return
    elseif _masterpt == nil and spawnpt.master then
        _masterpt = spawnpt
    end
    table.insert(_openpts, spawnpt)
    inst:ListenForEvent("onremove", UnregisterSpawnPoint, spawnpt)
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

inst:ListenForEvent("ms_playerdespawn", OnPlayerDespawn)
inst:ListenForEvent("ms_playerdespawnanddelete", OnPlayerDespawnAndDelete)
inst:ListenForEvent("ms_setspawnmode", OnSetSpawnMode)
inst:ListenForEvent("ms_registerspawnpoint", OnRegisterSpawnPoint)

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:SpawnAtNextLocation(inst, player)
    local x, y, z = GetNextSpawnPosition()
    self:SpawnAtLocation(inst, player, x, y, z)
end
 
function self:SpawnAtLocation(inst, player, x, y, z, isloading)
    print(string.format("[%s] SPAWNING PLAYER AT: (%2.2f, %2.2f, %2.2f)", isloading and "Load" or MODES[_mode], x, y, z))
    player.Physics:Teleport(x, y, z)

    -- Spawn a light if it's dark
    if not inst.state.isday then
        SpawnPrefab("spawnlight_multiplayer").Transform:SetPosition(x, y, z)
    end

    -- Portal FX, disable/give control to player if they're loading in
    if isloading or _mode ~= "fixed" then
        player.AnimState:SetMultColour(0,0,0,1)
        player:Hide()
        player.components.playercontroller:Enable(false)
        local fx = SpawnPrefab("spawn_fx_medium")
        if fx ~= nil then
            fx.entity:SetParent(player.entity)
        end
        player:DoTaskInTime(6*FRAMES, function(inst)
            player:Show()
            player.components.colourtweener:StartTween({1,1,1,1}, 19*FRAMES, function(player)
                player.components.playercontroller:Enable(true)
            end)
        end)
    else
        TheWorld:PushEvent("ms_newplayercharacterspawned", { player = player, mode = isloading and "Load" or MODES[_mode] })
    end
end

self.GetAnySpawnPoint = GetNextSpawnPosition

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)