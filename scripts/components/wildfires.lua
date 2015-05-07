--------------------------------------------------------------------------
--[[ FrogRain class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "Wildfires should not exist on client")

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _world = TheWorld
local _ismastersim = _world.ismastersim

local _activeplayers = {}
local _scheduledtasks = {}
local _worldstate = _world.state
local _map = _world.Map
local _tempthreshold = TUNING.WILDFIRE_THRESHOLD
local _retrytime = TUNING.WILDFIRE_RETRY_TIME
local _chance = TUNING.WILDFIRE_CHANCE
local _radius = 25
local _updating = false
local _excludetags = { "wildfireprotected", "fire", "burnt", "player", "companion", "NOCLICK", "INLIMBO" } -- things that don't start fires

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function CheckValidWildfireStarter(obj)
    if not obj:IsValid() or
        obj:HasTag("fireimmune") or
        (obj.components.witherable ~= nil and obj.components.witherable:IsProtected()) then
        return false --Invalid, immune, or temporarily protected
    elseif obj.components.pickable ~= nil then
        if obj.components.pickable:IsWildfireStarter() then
            --Wild plants
            return true
        end
    elseif obj.components.crop == nil and obj.components.growable == nil then
        --Non-plant
        return true
    end
    --Farm crop or tree
    return (obj.components.crop ~= nil and obj.components.witherable:IsWithered())
        or (obj.components.workable ~= nil and obj.components.workable:GetWorkAction() == ACTIONS.CHOP)
end

local function LightFireForPlayer(player, rescheduleFn)
    if _worldstate.temperature > _tempthreshold and _worldstate.isday and not _worldstate.israining then
        local rnd = math.random()
        if rnd <= _chance then
            local x, y, z = player.Transform:GetWorldPosition()
            local firestarters = TheSim:FindEntities(x, y, z, _radius, nil, _excludetags)
            if #firestarters > 0 then
                local highprio = {}
                local lowprio = {}
                for i, v in ipairs(firestarters) do
                    if v.components.burnable ~= nil then
                        table.insert(v:HasTag("wildfirepriority") and highprio or lowprio, v)
                    end
                end
                firestarters = #highprio > 0 and highprio or lowprio
                while #firestarters > 0 do
                    local i = math.random(#firestarters)
                    if CheckValidWildfireStarter(firestarters[i]) then
                        firestarters[i].components.burnable:StartWildfire()
                        break
                    else
                        table.remove(firestarters, i)
                    end
                end
            end
        end
    end

    if _scheduledtasks[player] ~= nil then
        _scheduledtasks[player]:Cancel()
        _scheduledtasks[player] = nil
    end
    rescheduleFn(player)
end

local function ScheduleSpawn(player, initialspawn)
    if _scheduledtasks[player] == nil and _retrytime ~= nil then
        _scheduledtasks[player] = player:DoTaskInTime(_retrytime, LightFireForPlayer, ScheduleSpawn)
    end
end

local function CancelSpawn(player)
    if _scheduledtasks[player] ~= nil then
        _scheduledtasks[player]:Cancel()
        _scheduledtasks[player] = nil
    end
end

local function ToggleUpdate(force)
    if _worldstate.issummer and -- wildfires only start in the summer, when it's hot enough and not raining
        _worldstate.temperature > _tempthreshold and 
        not _worldstate.israining then
        if not _updating then
            _updating = true
            for i, v in ipairs(_activeplayers) do
                ScheduleSpawn(v, true)
            end
        elseif force then
            for i, v in ipairs(_activeplayers) do
                CancelSpawn(v)
                ScheduleSpawn(v, true)
            end
        end
    elseif _updating then
        _updating = false
        for i, v in ipairs(_activeplayers) do
            CancelSpawn(v)
        end
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnStateChange(inst, data)
    ToggleUpdate()
end

local function OnPlayerJoined(src, player)
    for i, v in ipairs(_activeplayers) do
        if v == player then
            return
        end
    end
    table.insert(_activeplayers, player)
    if _updating then
        ScheduleSpawn(player, true)
    end
end

local function OnPlayerLeft(src, player)
    for i, v in ipairs(_activeplayers) do
        if v == player then
            CancelSpawn(player)
            table.remove(_activeplayers, i)
            return
        end
    end
end

local function OnSetWildfireChance(src, chance)
    _chance = chance
end

local function ForceWildfireForPlayer(src, player)
    LightFireForPlayer(player, ScheduleSpawn)
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Initialize variables
for i, v in ipairs(AllPlayers) do
    table.insert(_activeplayers, v)
end

--Register events
inst:WatchWorldState("temperature", OnStateChange)
inst:WatchWorldState("israining", OnStateChange)
inst:WatchWorldState("issummer", OnStateChange)
--inst:ListenForEvent("seasontick", ToggleUpdate, _world)
inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, _world)
inst:ListenForEvent("ms_playerleft", OnPlayerLeft, _world)

inst:ListenForEvent("ms_setwildfirechance", OnSetWildfireChance, _world)
inst:ListenForEvent("ms_lightwildfireforplayer", ForceWildfireForPlayer, _world)

ToggleUpdate(true)

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

if _ismastersim then function self:OnSave()
    return
    {
        tempthreshold = _tempthreshold,
        retrytime = _retrytime,
        chance = _chance,
    }
end end

if _ismastersim then function self:OnLoad(data)
    _tempthreshold = data.tempthreshold or _tempthreshold
    _retrytime = data.retrytime or _retrytime
    _chance = data.chance or _chance
end end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    return string.format("Wildfires: updating:%s,  retry time %2.2f, temperature %s, issummer %s ", tostring(_updating), _retrytime, _worldstate.temperature, tostring(_worldstate.issummer))
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
