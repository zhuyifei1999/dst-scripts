--------------------------------------------------------------------------
--[[ Lunar Alter Guardian Spawner class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "Lunar Alter Guardian Spawner should not exist on client")

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local SPAWN_DIST = 10

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _activeguardian = nil

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function NoHoles(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end

local function GetSpawnPoint(pt)
    if not TheWorld.Map:IsAboveGroundAtPoint(pt:Get()) then
        pt = FindNearbyLand(pt, 1) or pt
    end

    local offset = FindWalkableOffset(pt, math.random() * TWOPI, SPAWN_DIST, 12, true, true, NoHoles)
    if offset then
        offset.x = offset.x + pt.x
        offset.z = offset.z + pt.z
        return offset
    end
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:TrySpawnLunarGuardian(spawner)
    if not spawner or _activeguardian then return end

    local pt = spawner:GetPosition()
    local spawn_pt = GetSpawnPoint(pt)
    if spawn_pt then
        spawner:PushEvent("lunarguardianincoming")
        self.inst:DoTaskInTime(4.5, function(i)
            _activeguardian = SpawnPrefab("alterguardian_phase1_lunarrift")
            _activeguardian.Physics:Teleport(spawn_pt:Get())
            _activeguardian:FacePoint(pt)

            _activeguardian:ListenForEvent("onremove", function()
                _activeguardian = nil
            end)

            _activeguardian.sg:GoToState("spawn_lunar")
        end)
    end
end

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    if _activeguardian ~= nil then
        return { activeguid = _activeguardian.GUID }, { _activeguardian.GUID }
    end
end

function self:LoadPostPass(newents, data)
    if data.activeguid and newents[data.activeguid] then
        _activeguardian = newents[data.activeguid].entity
        _activeguardian:ListenForEvent("onremove", function()
            _activeguardian = nil
        end)
    end
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:_Debug_SpawnGuardian(player)
    self:TrySpawnLunarGuardian((player or ThePlayer).Transform:GetWorldPosition())
end

end)