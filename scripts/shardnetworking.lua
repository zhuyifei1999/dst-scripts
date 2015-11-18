--------------------------------------------------------------------------
--[[ Shard Networking ]]
--------------------------------------------------------------------------

ShardPortals = {}

local ShardConnected = {}

function Shard_IsWorldAvailable(world_id)
    return ShardConnected[world_id or SHARDID.MASTER] == true
end

function Shard_IsWorldFull(world_id)
    -- TODO
end

--Called from ShardManager whenever a shard is connected or
--disconnected, to automatically update known portal states
--NOTE: should never be called with for our own world_id
function Shard_UpdateWorldState(world_id, state)
    local ready = state == REMOTESHARDSTATE.READY
    print("World '"..world_id.."' is now "..(ready and 'connected' or 'disconnected'))

    ShardConnected[world_id] = ready or nil

    for k, v in pairs(ShardPortals) do
        if ready and (v.components.worldmigrator.linkedWorld == nil
                    or v.components.worldmigrator.auto == true) then
            -- Bind unused portals to this new server, mm-mm!
            v.components.worldmigrator:SetDestinationWorld(world_id)
        elseif v.components.worldmigrator.linkedWorld == world_id then
            v.components.worldmigrator:ValidateAndPushEvents()
        else
            print(string.format("Skipping portal %d (different permanent world)", v.components.worldmigrator.id))
        end
    end  
end

--Called from worldmigrator whenever a new portal is
--spawned to automatically link it with known shards
function Shard_UpdatePortalState(inst)
    if inst.components.worldmigrator.linkedWorld == nil then
        for k, v in pairs(ShardConnected) do
            -- Bind to first available shard
            inst.components.worldmigrator:SetDestinationWorld(k)
        end
    end
    inst.components.worldmigrator:ValidateAndPushEvents()
end

function Shard_GetConnectedShards() -- useful for debugging
    return deepcopy(ShardConnected)
end

--------------------------------------------------------------------------

function Shard_UpdateMasterSessionId(session_id)
    if TheWorld ~= nil then -- this will be nil if the connection happens during worldgen; it will be resent on game start
        TheWorld:PushEvent("ms_newmastersessionid", session_id)
    end
end
