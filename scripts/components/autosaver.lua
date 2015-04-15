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
local _starttime = GetTime()
local _savingtasks = {}

--Master simulation
local _enabled

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

local function DoActualSave()
    SaveGameIndex:SaveCurrent()
    _issaving:set_local(false)
end

--------------------------------------------------------------------------
--[[ Private event listeners ]]
--------------------------------------------------------------------------

local function OnSave(src, mintime)
    if mintime ~= nil and GetTime() - _starttime <= mintime then
        return
    end

    if PLATFORM == "PS4" and ThePlayer ~= nil and not ThePlayer.profile:GetAutosaveEnabled() then
        return
    end

    if _ismastersim then
        _issaving:set(true)
        inst:DoTaskInTime(1, DoActualSave)
    else
        SerializeUserSession(ThePlayer)
    end
end

local OnCyclesChanged = _ismastersim and function()
    OnSave(nil, 60)
end or nil

local OnSetAutoSaveEnabled = _ismastersim and function(src, enable)
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

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Register network variable sync events
inst:ListenForEvent("issavingdirty", OnIsSavingDirty)

--Register events
inst:ListenForEvent("save", OnSave, _world)

if _ismastersim then
    --Initialize master simulation variables
    _enabled = false

    --Register master simulation events
    inst:ListenForEvent("ms_setautosaveenabled", OnSetAutoSaveEnabled, _world)

    OnSetAutoSaveEnabled()
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)