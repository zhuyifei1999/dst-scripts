--------------------------------------------------------------------------
--[[ Shard_CharlieInfo ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "Shard_CharlieInfo should not exist on client")

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _world = TheWorld
local _ismastershard = _world.ismastershard

--Network
local _isdefeated = net_bool(inst.GUID, "shard_charlieinfo._isdefeated", "ischarliedefeateddirty")

function self:IsCharlieDefeated()
    return _isdefeated:value()
end
--------------------------------------------------------------------------
--[[ Private event listeners ]]
--------------------------------------------------------------------------

local OnCharlieDefeated = _ismastershard and function(src, data)
    _isdefeated:set(data.isdefeated)
end or nil

local OnCharlieDefeatedDirty = not _ismastershard and function()
    _world:PushEvent("secondary_charlieinfoupdate", { isdefeated = _isdefeated:value() })
end or nil

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

if _ismastershard then
    --Register master shard events
    inst:ListenForEvent("master_charlieinfoupdate", OnCharlieDefeated, _world)
else
    --Register network variable sync events
    inst:ListenForEvent("ischarliedefeateddirty", OnCharlieDefeatedDirty)
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
