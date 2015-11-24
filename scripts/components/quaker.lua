--------------------------------------------------------------------------
--[[ Quaker class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local QUAKESTATE = {
    WAITING = 0,
    WARNING = 1,
    QUAKING = 2,
}

local DENSITYRADIUS = 5 -- the minimum radius that can contain 3 debris (allows for some clumping)

local SMASHABLE_TAGS = { "smashable", "quakedebris", "_combat" }
local NON_SMASHABLE_TAGS = { "INLIMBO", "playerghost", "irreplaceable" }

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

-- Public

self.inst = inst

-- Private
local _world = TheWorld
local _ismastersim = _world.ismastersim
local _state = nil
local _debrispersecond = 1 -- how much junk falls
local _mammalsremaining = 0
local _task = nil
local _frequencymultiplier = 1

local _quakedata = nil -- populated through configuration

local _debris = {
    {weight = 1, loot = {"rocks"}},
}

local _activeplayers = {}
local _scheduleddrops = {}

-- Network Variables
local _intensity = net_float(inst.GUID, "quaker._intensity", "intensitydirty")

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

-- debris methods
local function UpdateShadowSize(inst, height)
    if inst.shadow then
        local scaleFactor = Lerp(0.5, 1.5, height/35)
        inst.shadow.Transform:SetScale(scaleFactor, scaleFactor, scaleFactor)
    end
end

local function GiveDebrisShadow(inst)
    local pt = Vector3(inst.Transform:GetWorldPosition())
    inst.shadow = SpawnPrefab("warningshadow")
    UpdateShadowSize(inst, 35)
    inst.shadow.Transform:SetPosition(pt.x, 0, pt.z)
    inst:ListenForEvent("onremove", function() inst.shadow:Remove() end)
end

local function GetDebris()
    local weighttotal = 0
    for i,v in ipairs(_debris) do
        weighttotal = weighttotal + v.weight
    end
    local val = math.random() * weighttotal
    local droptable = nil
    for i,v in ipairs(_debris) do
        if val < v.weight then
            droptable = deepcopy(v.loot) -- we will be modifying this
            break
        else
            val = val-v.weight
        end
    end

    local todrop = nil
    if droptable ~= nil then
        while todrop == nil and #droptable > 0 do
            local index = math.random(1,#droptable)
            todrop = droptable[index]
            if todrop == "mole" or todrop == "rabbit" then
                -- if it's a small creature, count it, or remove it from the table and try again
                if _mammalsremaining == 0 then
                    table.remove(droptable, index)
                    todrop = nil
                end
            end
        end
    end

    return todrop
end

local function SpawnDebris(spawn_point)
    local prefab = GetDebris()
    if prefab then
        local db = SpawnPrefab(prefab)
        if db and (prefab == "rabbit" or prefab == "mole") and db.sg then
            _mammalsremaining = _mammalsremaining - 1
            db.sg:GoToState("fall")
        end
        if math.random() < .5 then
            db.Transform:SetRotation(180)
        end
        spawn_point.y = 35


        db.Physics:Teleport(spawn_point.x,spawn_point.y,spawn_point.z)

        return db
    end
end

local function PlayFallingSound(inst, volume)
    volume = volume or 1
    local sound = inst.SoundEmitter
    if sound then
        local tile, tileinfo = inst:GetCurrentTileType()
        if tile and tileinfo then
            local x, y, z = inst.Transform:GetWorldPosition()
            local size_affix = "_small"
            --gjans: This doesn't play on the client! Not sure why...
            --sound:PlaySound(tileinfo.walksound .. size_affix, nil, volume)
        end
    end
end

local function _GroundDetectionUpdate(inst)
    local pt = Point(inst.Transform:GetWorldPosition())

    if not inst.shadow then
        GiveDebrisShadow(inst)
    else
        UpdateShadowSize(inst, pt.y)
    end

    if pt.y < 2 then
        inst.fell = true
        inst.Physics:SetMotorVel(0,0,0)
    end

    if pt.y <= .2 then
        PlayFallingSound(inst)
        if inst.shadow then
            inst.shadow:Remove()
        end

        -- break stuff we land on
        local ents = TheSim:FindEntities(pt.x, 0, pt.z, 2, nil, NON_SMASHABLE_TAGS, SMASHABLE_TAGS)
        for k,v in pairs(ents) do
            if v ~= inst and v.components.combat then  -- quakes shouldn't break the set dressing
                v.components.combat:GetAttacked(inst, 20, nil)
            end
            if v ~= inst and v:HasTag("quakedebris") then
                local pt = Vector3(v.Transform:GetWorldPosition())
                local breaking = SpawnPrefab("ground_chunks_breaking")
                breaking.Transform:SetPosition(pt.x, 0, pt.z)
                v:Remove()
            end
        end
        --play hit ground sound


        inst.Physics:SetDamping(0.9)

        if inst.updatetask then
            inst.updatetask:Cancel()
            inst.updatetask = nil
        end

        -- often break ourself as well
        local existingdebris = TheSim:FindEntities(pt.x, 0, pt.y, DENSITYRADIUS, nil, { "quakedebris" }, { "INLIMBO" }) -- note this will always be at least one, for self
        if (#existingdebris > 1 or math.random() < 0.75)
            and not (inst.prefab == "mole" or inst.prefab == "rabbit") then

            --spawn break effect
            local pt = Vector3(inst.Transform:GetWorldPosition())
            local breaking = SpawnPrefab("ground_chunks_breaking")
            breaking.Transform:SetPosition(pt.x, 0, pt.z)
            inst:Remove()
        end
    end

    -- Failsafe: if the entity has been alive for at least 1 second, hasn't changed height significantly since last tick, and isn't near the ground, remove it and its shadow
    if inst.last_y and pt.y > 2 and inst.last_y > 2 and (inst.last_y - pt.y  < 1) and inst:GetTimeAlive() > 1 and not inst.fell then
        if inst.shadow then
            inst.shadow:Remove()
        end
        inst:Remove()
    end
    inst.last_y = pt.y
end

local function StartGroundDetection(inst)
    inst.updatetask = inst:DoPeriodicTask(0.1, _GroundDetectionUpdate, 0.05)
end
-- /debris methods

local function GetTimeForNextDebris()
    return 1/_debrispersecond
end

local function GetSpawnPoint(pt, rad)

    local theta = math.random() * 2 * PI
    local radius = math.random()*(rad or TUNING.FROG_RAIN_SPAWN_RADIUS)

    local result_offset = FindValidPositionByFan(theta, radius, 12, function(offset)
        local spawn_point = pt + offset
        return _world.Map:IsAboveGroundAtPoint(spawn_point:Get())
    end)

    if result_offset then
        return pt+result_offset
    end

end

local function DoDropForPlayer(player, reschedulefn)
    local char_pos = Vector3(player.Transform:GetWorldPosition())
    local spawn_point = GetSpawnPoint(char_pos)
    if spawn_point then
        player:ShakeCamera(CAMERASHAKE.FULL, 0.7, 0.02, .75)
        local db = SpawnDebris(spawn_point)
        StartGroundDetection(db)
    end
    reschedulefn(player)
end

local function ScheduleDrop(player)
    if _scheduleddrops[player] ~= nil then
        _scheduleddrops[player]:Cancel()
    end
    _scheduleddrops[player] = player:DoTaskInTime(GetTimeForNextDebris(), DoDropForPlayer, ScheduleDrop)
end

local function CancelDropForPlayer(player)
    if _scheduleddrops[player] ~= nil then
        _scheduleddrops[player]:Cancel()
        _scheduleddrops[player] = nil
    end
end

local function CancelDrops()
    for i,v in pairs(_scheduleddrops) do
        v:Cancel()
    end
    _scheduleddrops = {}
end

local function _DoWarningSpeech(player)
    player.components.talker:Say(GetString(player, "ANNOUNCE_QUAKE"))
end

local SetNextQuake = nil -- forward declare this...
local EndQuake = nil -- forward declare this...

local function ClearTask()
    if _state == QUAKESTATE.QUAKING or _state == QUAKESTATE.WARNING then
        EndQuake(inst, false)
    end

    if _task ~= nil then
        _task:Cancel()
        _task = nil
    end

    _state = nil
end

local function UpdateTask(time, callback, data)
    if _task ~= nil then
        _task:Cancel()
        _task = nil
    end
    _task = inst:DoTaskInTime(time, callback, data)
end

-- was forward declared
EndQuake = function(inst, continue)
    --print("ENDING QUAKE")
    CancelDrops()

    _intensity:set(0)
    inst:PushEvent("endquake")

    if continue then
        SetNextQuake(_quakedata)
    end
end

local function StartQuake(inst, data, overridetime)
    --print("STARTING QUAKE")
    _intensity:set(1.0)

    _debrispersecond = type(data.debrispersecond) == "function" and data.debrispersecond() or data.debrispersecond
    _mammalsremaining = type(data.mammals) == "function" and data.mammals() or data.mammals

    for i, v in ipairs(_activeplayers) do
        ScheduleDrop(v)
    end

    inst:PushEvent("startquake")

    local quaketime = overridetime or (type(data.quaketime) == "function" and data.quaketime()) or data.quaketime
    UpdateTask(quaketime, EndQuake, true)
    _state = QUAKESTATE.QUAKING
end

local function WarnQuake(inst, data, overridetime)
    --print("WARNING QUAKE")
    inst:DoTaskInTime(1, function()
        for i, v in ipairs(_activeplayers) do
            v:DoTaskInTime(math.random() * 2, _DoWarningSpeech)
        end
        inst:PushEvent("warnquake")
    end)

    if not _world.SoundEmitter:PlayingSound("earthquake") then
        _world.SoundEmitter:PlaySound("dontstarve/cave/earthquake", "earthquake")
    end
    _world.SoundEmitter:SetParameter("earthquake", "intensity", 0.08)
    _intensity:set(0.08)

    local warntime = overridetime or (type(data.warningtime) == "function" and data.warningtime()) or data.warningtime
    ShakeAllCameras(CAMERASHAKE.FULL, warntime + 3, .02, .2, nil, 40)
    UpdateTask(warntime, StartQuake, data)
    _state = QUAKESTATE.WARNING
end

-- Was forward declared
SetNextQuake = function(data, overridetime)
    --print("RESCHEDULE QUAKE")
    local nexttime = overridetime or (type(data.nextquake) == "function" and data.nextquake()*_frequencymultiplier) or data.nextquake*_frequencymultiplier
    UpdateTask(nexttime, WarnQuake, data)
    _state = QUAKESTATE.WAITING
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnIntensityDirty(inst)
    if _intensity:value() > 0 then
        if not _world.SoundEmitter:PlayingSound("earthquake") then
            _world.SoundEmitter:PlaySound("dontstarve/cave/earthquake", "earthquake")
        end
        _world.SoundEmitter:SetParameter("earthquake", "intensity", 1)
    elseif _world.SoundEmitter:PlayingSound("earthquake") then
        _world.SoundEmitter:KillSound("earthquake")
    end
end

local OnMiniQuake = _ismastersim and function(inst, data)

    inst.SoundEmitter:PlaySound("dontstarve/cave/earthquake", "miniearthquake")
    inst.SoundEmitter:SetParameter("miniearthquake", "intensity", 1)
    _intensity:set(1.0)

    local char_pos = Vector3(data.target.Transform:GetWorldPosition())

    local time = 0
    for i=1,data.num do

        inst:DoTaskInTime(time, function()
            local spawn_point = GetSpawnPoint(char_pos, data.rad)
            if spawn_point then
                local db = SpawnDebris(spawn_point)
                StartGroundDetection(db)
            end
        end)

        time = time + data.duration/data.num
    end

    ShakeAllCameras(CAMERASHAKE.FULL, data.duration, .02, .5, data.target, 40)

    inst:DoTaskInTime(data.duration, function() inst.SoundEmitter:KillSound("miniearthquake") end)
end or nil


local OnExplosion = _ismastersim and function(inst, data)
    if _state == QUAKESTATE.WAITING then
        SetNextQuake(_quakedata, GetTaskRemaining(_task) - data.damage)
    elseif _state == QUAKESTATE.WARNING then
        WarnQuake(inst, _quakedata)
    end
end or nil

-- Immediately start the current or a specified quake
-- If a new quake type is forced, save current quake type and restore it once quake has finished
local OnForceQuake = _ismastersim and function(inst, data)
    if _state == QUAKESTATE.QUAKING then return false end

    if data then
        StartQuake(inst, data)
    else
        StartQuake(inst, _quakedata)
    end

    return true
end or nil

local OnPlayerJoined = _ismastersim and function (src, player)
    for i, v in ipairs(_activeplayers) do
        if v == player then
            return
        end
    end
    table.insert(_activeplayers, player)
    if _state == QUAKESTATE.QUAKING then
        ScheduleDrop(player)
    end
end or nil

local OnPlayerLeft = _ismastersim and function (src, player)
    for i, v in ipairs(_activeplayers) do
        if v == player then
            CancelDropForPlayer(player)
            table.remove(_activeplayers, i)
            return
        end
    end
end or nil

local OnFrequencyMultiplier = _ismastersim and function (src, multiplier)
    _frequencymultiplier = multiplier
    if _frequencymultiplier > 0 and _quakedata ~= nil then
        SetNextQuake(_quakedata)
    else
        ClearTask()
    end
end or nil

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:SetQuakeData(data)
    if not _ismastersim then return end

    _quakedata = data
    if _quakedata ~= nil and _frequencymultiplier > 0 then
        SetNextQuake(_quakedata)
    else
        ClearTask()
    end
end

function self:SetDebris(data)
    if not _ismastersim then return end

    _debris = data
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Register network variable sync events
inst:ListenForEvent("intensitydirty", OnIntensityDirty)

--Register events
if _ismastersim then
    inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, _world)
    inst:ListenForEvent("ms_playerleft", OnPlayerLeft, _world)

    inst:ListenForEvent("ms_miniquake", OnMiniQuake, _world)
    inst:ListenForEvent("ms_forcequake", OnForceQuake, _world)

    inst:ListenForEvent("ms_quakefrequencymultiplier", OnFrequencyMultiplier, _world)

    inst:ListenForEvent("explosion", OnExplosion, _world)
end

-- Default configuration
self:SetDebris( {
    { -- common
        weight = 0.75,
        loot = {
            "rocks",
            "flint",
        },
    },
    { -- uncomon
        weight = 0.20,
        loot = {
            "goldnugget",
            "nitre",
            "rabbit",
            "mole",
        },
    },
    { -- rare
        weight = 0.05,
        loot = {
            "redgem",
            "bluegem",
            "marble",
        },
    },
})

self:SetQuakeData({
    warningtime = 7,
    quaketime = function() return math.random(5, 10) + 5 end,
    debrispersecond = function() return math.random(5, 6) end,
    nextquake = function() return TUNING.TOTAL_DAY_TIME + math.random() * TUNING.TOTAL_DAY_TIME * 2 end,
    mammals = 1,
})

--------------------------------------------------------------------------
--[[ Update ]]
--------------------------------------------------------------------------

function self:LongUpdate(dt)
end

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

if _ismastersim then function self:OnSave()
    return {
        time = GetTaskRemaining(_task),
        state = _state,
        debrispersecond = _debrispersecond,
        mammalsremaining = _mammalsremaining
    }
end end

if _ismastersim then function self:OnLoad(data)
    _debrispersecond = data.debrispersecond or 1
    _mammalsremaining = data.mammalsremaining or 0

    _state = data.state
    if _state == QUAKESTATE.WAITING then
        SetNextQuake(_quakedata, data.time)
    elseif _state == QUAKESTATE.WARNING then
        WarnQuake(inst, _quakedata, data.time)
    elseif _state == QUAKESTATE.QUAKING then
        StartQuake(inst, _quakedata, data.time)
    end
end end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    local s = ""
    if _ismastersim then
        s = table.reverselookup(QUAKESTATE, _state)
        s = s .. string.format(" %.2f", GetTaskRemaining(_task))
        if _state == QUAKESTATE.QUAKING then
            s = s .. string.format(" debris/second: %.2f mammals: %d",
                _debrispersecond, _mammalsremaining)
        elseif _state == QUAKESTATE.WARNING then
        elseif _state == QUAKESTATE.WAITING then
        end
    end
    s = s .. " intensity: " .. tostring(_intensity:value())
    return s
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
