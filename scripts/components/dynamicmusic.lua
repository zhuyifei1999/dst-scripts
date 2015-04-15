--------------------------------------------------------------------------
--[[ DynamicMusic class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _isruin = inst:HasTag("ruin")
local _iscave = _isruin or inst:HasTag("cave")
local _isenabled = true
local _busytask = nil
local _dangertask = nil
local _isday = nil
local _isbusydirty = nil
local _extendtime = nil
local _soundemitter = nil
local _activatedplayer = nil --cached for activation/deactivation only, NOT for logic use

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function StopBusy(inst, istimeout)
    if _busytask ~= nil then
        if not istimeout then
            _busytask:Cancel()
        elseif _extendtime > 0 then
            local time = GetTime()
            if time < _extendtime then
                _busytask = inst:DoTaskInTime(_extendtime - time, StopBusy, true)
                _extendtime = 0
                return
            end
        end
        _busytask = nil
        _extendtime = 0
        _soundemitter:SetParameter("busy", "intensity", 0)
    end
end

local function StartBusy()
    if not (_iscave or _isday) then
        return
    elseif _busytask ~= nil then
        _extendtime = GetTime() + 15
    elseif _dangertask == nil and (_extendtime == 0 or GetTime() >= _extendtime) and _isenabled then
        if _isbusydirty then
            _isbusydirty = false
            _soundemitter:KillSound("busy")
            _soundemitter:PlaySound(
                (_isruin and "dontstarve/music/music_work_ruins") or
                (_iscave and "dontstarve/music/music_work_cave") or
                (inst.state.iswinter and "dontstarve/music/music_work_winter") or
                "dontstarve/music/music_work",
                "busy")
        end
        _soundemitter:SetParameter("busy", "intensity", 1)
        _busytask = inst:DoTaskInTime(15, StopBusy, true)
        _extendtime = 0
    end
end

local function ExtendBusy()
    if _busytask ~= nil then
        _extendtime = math.max(_extendtime, GetTime() + 10)
    end
end

local function StopDanger(inst, istimeout)
    if _dangertask ~= nil then
        if not istimeout then
            _dangertask:Cancel()
        elseif _extendtime > 0 then
            local time = GetTime()
            if time < _extendtime then
                _dangertask = inst:DoTaskInTime(_extendtime - time, StopDanger, true)
                _extendtime = 0
                return
            end
        end
        _dangertask = nil
        _extendtime = 0
        _soundemitter:KillSound("danger")
    end
end

local function StartDanger(player)
    if _dangertask ~= nil then
        _extendtime = GetTime() + 10
    elseif _isenabled then
        StopBusy()
        _soundemitter:PlaySound(
            GetClosestInstWithTag("epic", player, 30) ~= nil
            and ((_isruin and "dontstarve/music/music_epicfight_ruins") or
                (_iscave and "dontstarve/music/music_epicfight_cave") or
                (inst.state.iswinter and "dontstarve/music/music_epicfight_winter") or
                "dontstarve/music/music_epicfight")
            or ((_isruin and "dontstarve/music/music_danger_ruins") or
                (_iscave and "dontstarve/music/music_danger_cave") or
                (inst.state.iswinter and "dontstarve/music/music_danger_winter") or
                "dontstarve/music/music_danger"),
            "danger")
        _dangertask = inst:DoTaskInTime(10, StopDanger, true)
        _extendtime = 0
    end
end

local function CheckAction(player)
    if player:HasTag("attack") then
        local target = player.replica.combat:GetTarget()
        if target ~= nil and
            not (target:HasTag("prey") or
                target:HasTag("bird") or
                target:HasTag("butterfly") or
                target:HasTag("shadow") or
                target:HasTag("smashable") or
                target:HasTag("wall") or
                target:HasTag("veggie")) then
            StartDanger(player)
            return
        end
    end
    if player:HasTag("working") then
        StartBusy()
    end
end

local function OnAttacked(player, data)
    if data ~= nil and
        --For a valid client side check, shadowattacker must be
        --false and not nil, pushed from player_classified
        (data.shadowattacker == false or
        --For a valid server side check, attacker must be non-nil
        (data.attacker ~= nil and not data.attacker:HasTag("shadow"))) then

        StartDanger(player)
    end
end

local function OnInsane()
    if _dangertask == nil and _isenabled then
        _soundemitter:PlaySound("dontstarve/sanity/gonecrazy_stinger")
        StopBusy()
        --Repurpose this as a delay before stingers or busy can start again
        _extendtime = GetTime() + 15
    end
end

local function StartPlayerListeners(player)
    inst:ListenForEvent("buildsuccess", StartBusy, player)
    inst:ListenForEvent("gotnewitem", ExtendBusy, player)
    inst:ListenForEvent("performaction", CheckAction, player)
    inst:ListenForEvent("attacked", OnAttacked, player)
    inst:ListenForEvent("goinsane", OnInsane, player)
end

local function StopPlayerListeners(player)
    inst:RemoveEventCallback("buildsuccess", StartBusy, player)
    inst:RemoveEventCallback("gotnewitem", ExtendBusy, player)
    inst:RemoveEventCallback("performaction", CheckAction, player)
    inst:RemoveEventCallback("attacked", OnAttacked, player)
    inst:RemoveEventCallback("goinsane", OnInsane, player)
end

local function OnPhase(inst, phase)
    _isday = phase == "day"
    if _dangertask ~= nil or not _isenabled then
        return
    end
    --Don't want to play overlapping stingers
    local time
    if _busytask == nil and _extendtime ~= 0 then
        time = GetTime()
        if time < _extendtime then
            return
        end
    end
    if _isday then
        _soundemitter:PlaySound("dontstarve/music/music_dawn_stinger")
    elseif phase == "dusk" then
        _soundemitter:PlaySound("dontstarve/music/music_dusk_stinger")
    else
        return
    end
    StopBusy()
    --Repurpose this as a delay before stingers or busy can start again
    _extendtime = (time or GetTime()) + 15
end

local function OnIsWinter()
    _isbusydirty = true
end

local function StartSoundEmitter()
    if _soundemitter == nil then
        _soundemitter = TheFocalPoint.SoundEmitter
        _extendtime = 0
        _isbusydirty = true
        if not _iscave then
            _isday = inst.state.isday
            inst:WatchWorldState("phase", OnPhase)
            inst:WatchWorldState("iswinter", OnIsWinter)
        end
    end
end

local function StopSoundEmitter()
    if _soundemitter ~= nil then
        StopDanger()
        StopBusy()
        _soundemitter:KillSound("busy")
        inst:StopWatchingWorldState("phase", OnPhase)
        inst:StopWatchingWorldState("iswinter", OnIsWinter)
        _isday = nil
        _isbusydirty = nil
        _extendtime = nil
        _soundemitter = nil
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnPlayerActivated(inst, player)
    if _activatedplayer == player then
        return
    elseif _activatedplayer ~= nil and _activatedplayer.entity:IsValid() then
        StopPlayerListeners(_activatedplayer)
    end
    _activatedplayer = player
    StopSoundEmitter()
    StartSoundEmitter()
    StartPlayerListeners(player)
end

local function OnPlayerDeactivated(inst, player)
    StopPlayerListeners(player)
    if player == _activatedplayer then
        _activatedplayer = nil
        StopSoundEmitter()
    end
end

local function OnEnableDynamicMusic(inst, enable)
    if _isenabled ~= enable then
        if not enable and _soundemitter ~= nil then
            StopDanger()
            StopBusy()
            _soundemitter:KillSound("busy")
            _isbusydirty = true
        end
        _isenabled = enable
    end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Register events
inst:ListenForEvent("playeractivated", OnPlayerActivated)
inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated)
inst:ListenForEvent("enabledynamicmusic", OnEnableDynamicMusic)

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)