--------------------------------------------------------------------------
--[[ WorldReset class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local SYNC_PERIOD_SLOW = 5
local SYNC_PERIOD_FAST = 2

--If a world reset is triggered within this period of an alive
--player's d/c, that player can cancel the timer by rejoining.
local DISCONNECT_GRACE_PERIOD = 10

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _world = TheWorld
local _ismastersim = _world.ismastersim
local _updating = false
local _shown = false
local _resetting = false
local _countdownf = nil
local _lastcountdown = nil
local _dtoverride = 0

--Master simulation
local _countdownmax
local _countdownloadingmax
local _countdownskipped
local _syncperiod
local _cancellable
local _recentplayers

--Network
local _countdown = net_byte(inst.GUID, "worldreset._countdown", "countdowndirty")

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function UpdateCountdown(time)
    _world:PushEvent("worldresettick", { time = time })
end

local OnSkipCountdown = _ismastersim and function()
    _countdownskipped = true
end or nil

local function ShowResetDialog()
    if not _shown then
        _shown = true
        if _ismastersim then
            _countdownskipped = false
            inst:ListenForEvent("ms_worldreset", OnSkipCountdown, _world)
        end
    end
    _world:PushEvent("showworldreset")
    if _lastcountdown ~= nil then
        UpdateCountdown(_lastcountdown)
    end
end

local function HideResetDialog()
    if _shown then
        _shown = false
        if _ismastersim then
            _countdownskipped = false
            inst:RemoveEventCallback("ms_worldreset", OnSkipCountdown, _world)
        end
    end
    _world:PushEvent("hideworldreset")
end

local DoReset = _ismastersim and function()
    StartNextInstance({
        reset_action = RESET_ACTION.LOAD_SLOT,
        save_slot = SaveGameIndex:GetCurrentSaveSlot()
    })
end or nil

local DoDeleteAndReset = _ismastersim and function()
    SaveGameIndex:DeleteSlot(
        SaveGameIndex:GetCurrentSaveSlot(),
        DoReset,
        true -- true causes world gen options to be preserved
    )
end or nil

local WorldReset = _ismastersim and function()
    if _resetting then
        return
    end
    _resetting = true
    if TheNet:IsDedicated() then
        DoDeleteAndReset()
    else
        TheFrontEnd:Fade(false, .25, DoDeleteAndReset)
    end
end or nil

local CheckRecentPlayers = _ismastersim and function()
    if next(_recentplayers) == nil then
        return false
    end
    local time = GetTime()
    for k, v in pairs(_recentplayers) do
        if v + DISCONNECT_GRACE_PERIOD < time then
            _recentplayers[k] = nil
        end
    end
    return next(_recentplayers) ~= nil
end or nil

local ClearRecentPlayers = _ismastersim and function()
    if next(_recentplayers) ~= nil then
        _recentplayers = {}
    end
end or nil

local IsRecentPlayer = _ismastersim and function(userid)
    return userid ~= nil and _recentplayers[userid] ~= nil
end or nil

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function CancelCountdown()
    if _resetting then
        return
    end
    if _updating then
        inst:StopUpdatingComponent(self)
        _updating = false
    end
    if _ismastersim then
        TheNet:SetIsWorldResetting(false)
        _countdown:set(0)
        if _cancellable ~= nil then
            inst:RemoveEventCallback("ms_playerjoined", _cancellable, _world)
            _cancellable = nil
        end
        ClearRecentPlayers()
    end
    _countdownf = nil
    _lastcountdown = nil
    HideResetDialog()
end

local function OnCountdownDirty()
    if _resetting then
        return
    elseif _countdown:value() > 0 then
        if not _updating then
            inst:StartUpdatingComponent(self)
            _updating = true
            ShowResetDialog()
        end
        _countdownf = _countdown:value()
        local newcountdown = _countdownf - 1
        if _lastcountdown == nil or _lastcountdown > newcountdown then
            _lastcountdown = newcountdown
            UpdateCountdown(newcountdown)
        end
    else
        CancelCountdown()
    end
end

local function OnRefreshDialog()
    if _resetting then
        return
    elseif _shown then
        ShowResetDialog()
    else
        HideResetDialog()
    end
end

local OnPlayerJoined = _ismastersim and function(src, player)
    if not player:HasTag("playerghost") then
        CancelCountdown()
    end
end or nil

local OnPlayerRejoined = _ismastersim and function(src, player)
    if IsRecentPlayer(player.userid) and not player:HasTag("playerghost") then
        CancelCountdown()
    end
end or nil

local OnPlayersLiveCheck = _ismastersim and function()
    if _resetting then
        return
    elseif #AllPlayers <= 0 then
        if _cancellable ~= nil and TheNet:IsDedicated() then
            CancelCountdown()
        end
    elseif _countdown:value() <= 0 then
        _cancellable = OnPlayerJoined
        for i, v in ipairs(AllPlayers) do
            if not v:HasTag("playerghost") then
                --someone is still alive!!!1
                return
            end
            _cancellable = v.loading_ghost and _cancellable or nil
        end
        --everyone's a ghost, it's hopeless, sigh...
        --3 min bonus time if loading
        TheNet:SetIsWorldResetting(true)
        local countdown = _cancellable ~= nil and _countdownloadingmax or _countdownmax
        _countdown:set(countdown < 255 and countdown or 255)
        _syncperiod = _countdown:value() > 10 and SYNC_PERIOD_SLOW or SYNC_PERIOD_FAST
        if _cancellable ~= nil then
            --cancellable by other players joining in
            ClearRecentPlayers()
            inst:ListenForEvent("ms_playerjoined", _cancellable, _world)
        elseif CheckRecentPlayers() then
            --cancellable by recently disconnected player rejoining
            _cancellable = OnPlayerRejoined
            inst:ListenForEvent("ms_playerjoined", _cancellable, _world)
        end
    end
end or nil

local OnPlayerLeft = _ismastersim and function(src, player)
    if _resetting then
        return
    elseif _countdown:value() <= 0 then
        CheckRecentPlayers()
    end
    if player.userid ~= nil then
        _recentplayers[player.userid] = _countdown:value() <= 0 and not player:HasTag("playerghost") and GetTime() or nil
    end
    OnPlayersLiveCheck()
end or nil

local OnPlayerSpawn = _ismastersim and function(src, player)
    inst:ListenForEvent("ms_becameghost", OnPlayersLiveCheck, player)
    inst:ListenForEvent("ms_respawnedfromghost", CancelCountdown, player)
end or nil

local OnSetWorldResetTime = _ismastersim and function(src, data)
    local wasenabled = _countdownmax > 0
    _countdownmax = data ~= nil and data.time or 0
    _countdownloadingmax = data ~= nil and data.loadingtime or _countdownmax
    if wasenabled ~= (_countdownmax > 0) then
        if wasenabled then
            inst:RemoveEventCallback("ms_playerspawn", OnPlayerSpawn, _world)
            inst:RemoveEventCallback("ms_playerleft", OnPlayerLeft, _world)
            for i, v in ipairs(AllPlayers) do
                inst:RemoveEventCallback("ms_becameghost", OnPlayersLiveCheck, v)
                inst:RemoveEventCallback("ms_respawnedfromghost", CancelCountdown, v)
            end
            CancelCountdown()
        else
            inst:ListenForEvent("ms_playerspawn", OnPlayerSpawn, _world)
            inst:ListenForEvent("ms_playerleft", OnPlayerLeft, _world)
            for i, v in ipairs(AllPlayers) do
                OnPlayerSpawn(_world, v)
            end
            OnPlayersLiveCheck()
        end
    end
end or nil

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Register network variable sync events
inst:ListenForEvent("countdowndirty", OnCountdownDirty)

if not (_ismastersim and TheNet:IsDedicated()) then
    --Register events
    inst:ListenForEvent("playeractivated", OnRefreshDialog, _world)
    inst:ListenForEvent("entercharacterselect", OnRefreshDialog, _world)
end

if _ismastersim then
    --Initialize master simulation variables
    _countdownmax = 0
    _countdownloadingmax = 0
    _countdownskipped = false
    _syncperiod = SYNC_PERIOD_SLOW
    _cancellable = nil
    _recentplayers = {}

    --Register master simulation events
    inst:ListenForEvent("ms_setworldresettime", OnSetWorldResetTime, _world)

    --Also reset this flag in case it's invalid
    TheNet:SetIsWorldResetting(false)
end

--------------------------------------------------------------------------
--[[ Post initialization ]]
--------------------------------------------------------------------------

function self:OnPostInit()
    OnCountdownDirty()
    if not _ismastersim and _countdown:value() > 0 then
        --HACK: fast forward a bit, donno where we seem to be getting
        --      some delay to process the packet after loading
        _dtoverride = _dtoverride + 4
    end
end

--------------------------------------------------------------------------
--[[ Update ]]
--------------------------------------------------------------------------

function self:OnUpdate(dt)
    if _dtoverride > 0 then
        dt = dt + _dtoverride
        _dtoverride = 0
    end

    if _countdownf <= dt then
        _countdownf = 0
    else
        _countdownf = _countdownf - dt
    end

    local newcountdown = math.floor(_countdownf)
    if _lastcountdown ~= newcountdown then
        if _ismastersim and (newcountdown <= 0 or (newcountdown % _syncperiod) == 0) then
            _countdown:set(newcountdown > 0 and (newcountdown + 1) or 1)
        else
            _countdown:set_local(newcountdown + 1)
            if newcountdown < _lastcountdown then
                _lastcountdown = newcountdown
                UpdateCountdown(newcountdown)
            end
        end
    end

    if _countdownskipped or _countdownf <= 0 then
        if _updating then
            inst:StopUpdatingComponent(self)
            _updating = false
        end
        if _ismastersim then
            WorldReset()
        end
    end
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
