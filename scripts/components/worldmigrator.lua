local STATUS = {
    ACTIVE = 0,
    INACTIVE = 1,
    FULL = 2,
}

local function onstatus(self, val)
    if val == STATUS.ACTIVE then
        self.inst:AddTag("migrator")
    else
        self.inst:RemoveTag("migrator")
    end
end

local nextPortalID = 1 -- Start at 1
local function init(inst, self)
    if self.id == nil then
        self:SetID(nextPortalID)
    end
    TheWorld:PushEvent("ms_registermigrationportal", inst)
    Shard_UpdatePortalState(inst)
end

local WorldMigrator = Class(function(self, inst)
    self.inst = inst

    self.enabled = true
    self._status = -1

    self.id = nil

    self.linkedWorld = nil
    self.recievedPortal = nil

    self.inst:DoTaskInTime(0, init, self)
end,
nil,
{
    _status = onstatus,
})

function WorldMigrator:SetDestinationWorld(world)
    self.linkedWorld = world
    self:ValidateAndPushEvents()
end

function WorldMigrator:SetEnabled(t)
    self.enabled = t
    self:ValidateAndPushEvents()
end

function WorldMigrator:SetRecievedPortal(fromworld, fromportal)
    -- TODO: This needs to be part of a two-way process, so both ends of the portal link to each other
    -- (or IDs are handed down from the master or something, so that bi-directionality can be guaranteed)
    assert(self.linkedWorld == nil or self.linkedWorld == fromworld)
    self.linkedWorld = fromworld
    self.recievedPortal = fromportal
    self:ValidateAndPushEvents()
end

function WorldMigrator:ValidateAndPushEvents()
    if self.enabled == false then
        self._status = STATUS.INACTIVE
        self.inst:PushEvent("migration_unavailable")
        print(string.format("Validating %d, which is disabled by prefab: status: %s world: %s available: %s", self.id or -1, table.reverselookup(STATUS, self._status), self.linkedWorld or "<nil>", tostring(self.linkedWorld and Shard_IsWorldAvailable(self.linkedWorld) or false)))
        return
    end

    if self._status ~= STATUS.ACTIVE and self.linkedWorld ~= nil and Shard_IsWorldAvailable(self.linkedWorld) then
        self._status = STATUS.ACTIVE
        self.inst:PushEvent("migration_available")
    elseif self._status ~= STATUS.FULL and self.linkedWorld ~= nil and Shard_IsWorldFull(self.linkedWorld) then
        self._status = STATUS.FULL
        self.inst:PushEvent("migration_full")
    elseif self._status ~= STATUS.INACTIVE and (self.linkedWorld == nil or not Shard_IsWorldAvailable(self.linkedWorld)) then
        self._status = STATUS.INACTIVE
        self.inst:PushEvent("migration_unavailable")
    end
    print(string.format("Validating %d: status: %s world: %s available: %s", self.id or -1, table.reverselookup(STATUS, self._status), self.linkedWorld or "<nil>", tostring(self.linkedWorld and Shard_IsWorldAvailable(self.linkedWorld) or false)))
end

function WorldMigrator:IsBound()
    return self.id ~= nil and self.linkedWorld ~= nil and self.recievedPortal ~= nil
end

function WorldMigrator:SetID(id)
    self.id = id

    -- TEMP HACK! the recieved portal should be negotiated between servers
    self.recievedPortal = id

    if id >= nextPortalID then
        nextPortalID = id + 1
    end
end

function WorldMigrator:IsDestinationForPortal(otherWorld, otherPortal)
    return  self.linkedWorld == otherWorld and self.recievedPortal == otherPortal
end

function WorldMigrator:IsAvailableForLinking()
    return not self:IsLinked()
end

function WorldMigrator:IsLinked()
    return self.linkedWorld ~= nil and self.recievedPortal ~= nil
end

function WorldMigrator:IsActive()
    return self.enabled and self._status == STATUS.ACTIVE
end

function WorldMigrator:IsFull()
    return self._status == STATUS.FULL
end

function WorldMigrator:Activate(doer)
    print("Activating portal "..self.id.." to "..(self.linkedWorld or "<nil>"))
    if self.linkedWorld == nil then
        -- TODO
        --if not doer.admin then print("NOT ADMIN")return end
        -- ui popup
        -- inst.destWorldId = ???
        return false, "NODESTINATION"
    end

    self.inst:PushEvent("migration_activate")
    TheWorld:PushEvent("ms_playerdespawnandmigrate", { player = doer, portalid = self.id, worldid = self.linkedWorld })
    return true
end

function WorldMigrator:OnSave()
    return {
        id = self.id,
        linkedWorld = self.linkedWorld,
        recievedPortal = self.recievedPortal,
    }
end

function WorldMigrator:OnLoad(data)
    if data.id then
        self:SetID(data.id)
    end
    self.linkedWorld = data.linkedWorld
    self.recievedPortal = data.recievedPortal
end

function WorldMigrator:GetDebugString()
    return string.format("ID %d: status: %s world: %s available: %s recieves: %d", self.id or -1, table.reverselookup(STATUS, self._status), self.linkedWorld or "<nil>", tostring(self.linkedWorld and Shard_IsWorldAvailable(self.linkedWorld) or false), self.recievedPortal or -1)
end

return WorldMigrator
