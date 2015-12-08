--------------------------------------------------------------------------
--[[ AutoSaver class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _world = TheWorld
local _ismastersim = _world.ismastersim
local _ismastershard = _world.ismastershard
local _starttime = GetTime()
local _lastsavetime = _starttime
local _savingtasks = {}
local _restarting = false

--Master simulation
local _enabled

--Slave simulation
local _loading

--Network
local _issaving = net_bool(inst.GUID, "autosaver._issaving", "issavingdirty")

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function EndSave(inst, hud)
    if hud.inst:IsValid() then
        hud.controls.saving:EndSave()
    end
    _savingtasks[hud] = nil
end

local DoRollback = _ismastersim and not _ismastershard and function(snapshot)
    if not _restarting then
        _restarting = true

        print("Synchronizing backward to master snapshot "..tostring(snapshot))
        TheNet:TruncateSnapshots(_world.meta.session_identifier, snapshot)
        StartNextInstance({
            reset_action = RESET_ACTION.LOAD_SLOT,
            save_slot = SaveGameIndex:GetCurrentSaveSlot(),
        })
    end
end or nil

local function DoActualSave(inst, snapshot)
    if _restarting then
        return
    end

    _issaving:set_local(false)

    if snapshot ~= nil then
        local current_snapshot = TheNet:GetCurrentSnapshot()
        if snapshot > current_snapshot then
            print("Synchronizing forward to master snapshot "..tostring(snapshot))
            TheNet:SetCurrentSnapshot(snapshot) --Slave call only
        elseif snapshot == current_snapshot - 1 then
            --If we are one ahead of the master value, then we are in sync
            return
        elseif snapshot < current_snapshot then -- checking -1 again is redundant
            --Otherwise, we need to rollback
            DoRollback(snapshot)
            return
        end
    end

    SaveGameIndex:SaveCurrent()
    _lastsavetime = GetTime()
end

--------------------------------------------------------------------------
--[[ Private event listeners ]]
--------------------------------------------------------------------------

local function OnSave(src, mintime, snapshot)
    if _restarting or
        (mintime ~= nil and GetTime() - _starttime <= mintime) or
        (PLATFORM == "PS4" and ThePlayer ~= nil and not ThePlayer.profile:GetAutosaveEnabled()) then
        return
    elseif _ismastersim then
        _issaving:set(true)
        inst:DoTaskInTime(1, DoActualSave)
        if _ismastershard then
            _world:PushEvent("master_autosaverupdate", { snapshot = TheNet:GetCurrentSnapshot() })
        end
    else
        SerializeUserSession(ThePlayer)
        _lastsavetime = GetTime()
    end
end

local OnCyclesChanged = _ismastershard and function()
    OnSave(nil, 60)
end or nil

local OnSetAutoSaveEnabled = _ismastershard and function(src, enable)
    if _enabled == (enable == false) then
        _enabled = not _enabled
        if _enabled then
            self:WatchWorldState("cycles", OnCyclesChanged)
        else
            self:StopWatchingWorldState("cycles", OnCyclesChanged)
        end
    end
end or nil

local function OnIsSavingDirty()
    if _issaving:value() and ThePlayer ~= nil then
        local hud = ThePlayer.HUD
        if hud ~= nil then
            if _savingtasks[hud] then
                _savingtasks[hud]:Cancel()
            else
                hud.controls.saving:StartSave()
            end
            _savingtasks[hud] = inst:DoTaskInTime(3, EndSave, hud)
        end
        if not _ismastersim then
            OnSave()
        end
    end
end

local OnSaveRequest = _ismastersim and not _ismastershard and function()
    if not _restarting then
        TheNet:SendWorldSaveRequestToMaster()
    end
end or nil

local OnClearLoading = _ismastersim and not _ismastershard and function()
    _loading = nil
end or nil

local OnAutoSaverUpdate = _ismastersim and not _ismastershard and function(src, data)
    if not _restarting and data.snapshot > 0 then
        local current_snapshot = TheNet:GetCurrentSnapshot()
        if data.snapshot >= current_snapshot then
            _issaving:set(true)
            inst:DoTaskInTime(1, DoActualSave, data.snapshot)
        elseif _loading == nil or data.snapshot < current_snapshot - 1 then
            --If we are one ahead of the master value, then we are in sync
            --Otherwise, we need to rollback
            --If we are not loading, then we need to restart even if
            --snapshot value is in sync
            DoRollback(data.snapshot)
        end
    end
    if _loading == true then
        --We may receive 2 packets, construction and dirty, after
        --loading, so delay clearing the flag till the next frame
        _loading = inst:DoTaskInTime(0, OnClearLoading)
    end
end or nil

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Register network variable sync events
inst:ListenForEvent("issavingdirty", OnIsSavingDirty)

if _ismastershard then
    --Initialize master simulation variables
    _enabled = false

    --Register master simulation events
    inst:ListenForEvent("ms_save", OnSave, _world)
    inst:ListenForEvent("ms_setautosaveenabled", OnSetAutoSaveEnabled, _world)

    OnSetAutoSaveEnabled()
elseif _ismastersim then
    --Initialize slave simulation variables
    --We expect to get either one or 2 initial packets shortly after loading
    _loading = true

    --Register slave shard events
    inst:ListenForEvent("ms_save", OnSaveRequest, _world)
    inst:ListenForEvent("slave_autosaverupdate", OnAutoSaverUpdate, _world)
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:GetLastSaveTime()
    return _lastsavetime
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
