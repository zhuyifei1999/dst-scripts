local LeaderRollCall = Class(function(self, inst)
    self.inst = inst

    self.enable = false
    self.radius = TUNING.ONEMANBAND_RANGE
    self.maxfollowers = TUNING.ONEMANBAND_MAXFOLLOWERS
    self.onrollcallfn = nil
    self.update_time = 1
    self.can_tend_crop = nil

    -- Internal vars
    self.update_accumulation = 0

    if self.inst.components.inventoryitem ~= nil then
        self.hasitemsource = true
        MakeComponentAnInventoryItemSource(self)
    end
end)

function LeaderRollCall:OnRemoveFromEntity()
    if self.hasitemsource then
        RemoveComponentInventoryItemSource(self)
        self.hasitemsource = nil
    end
end

--------------------------------------------------------------------------
-- MakeComponentAnInventoryItemSource

function LeaderRollCall:OnItemSourceRemoved(owner)
    if owner.components.leader ~= nil then
        owner.components.leader:SetIsRollCaller(self.inst, false)
    end
end

function LeaderRollCall:OnItemSourceNewOwner(owner)
    if self.enable then
        if owner.components.leader ~= nil then
            owner.components.leader:SetIsRollCaller(self.inst, true)
        end
    end
end

--------------------------------------------------------------------------
--Public

function LeaderRollCall:Enable(inittime)
    self.enable = true
    self.update_accumulation = (inittime and self.update_time - inittime) or 0
    self.inst:StartUpdatingComponent(self)

    if self:IsValidLeader(self.itemsource_owner) then
        self.itemsource_owner.components.leader:SetIsRollCaller(self.inst, true)
    end
end

function LeaderRollCall:Disable()
    self.enable = false
    self.update_accumulation = 0
    self.inst:StopUpdatingComponent(self)

    if self:IsValidLeader(self.itemsource_owner) then
        self.itemsource_owner.components.leader:SetIsRollCaller(self.inst, false)
    end
end

function LeaderRollCall:IsEnabled()
    return self.enable
end

function LeaderRollCall:SetRadius(radius)
    self.radius = radius
end

function LeaderRollCall:GetRadius()
    return self.radius
end

function LeaderRollCall:SetMaxFollowers(max)
    self.maxfollowers = max
end

function LeaderRollCall:GetMaxFollowers()
    return self.maxfollowers
end

function LeaderRollCall:SetCanTendFarmPlant(boolval)
    self.can_tend_crop = boolval or nil
end

function LeaderRollCall:GetCanTendFarmPlant()
    return self.can_tend_crop
end

function LeaderRollCall:SetUpdateTime(time)
    self.update_time = time
end

function LeaderRollCall:SetOnRollCallFn(fn)
    self.onrollcallfn = fn
end

function LeaderRollCall:GetLeader()
    return self:IsValidLeader(self.itemsource_owner) and self.itemsource_owner
        or self:IsValidLeader(self.inst) and self.inst
        or nil
end

function LeaderRollCall:IsValidLeader(leader)
    return leader ~= nil and leader.components.leader ~= nil
end

--------------------------------------------------------------------------
--Everything below this should be internal

local ONEOF_TAGS = { "pig", "merm", "farm_plant" }
local CANT_TAGS = { "werepig", "player" }

function LeaderRollCall:DoRollCall()
    local leader = self:GetLeader()
    if not leader then
        return
    end

    local max_followers = self:GetMaxFollowers()
    local can_tend_crop = self:GetCanTendFarmPlant() -- One man band and wx both do this, so piggy back off same entity scan
    local x, y, z = leader.Transform:GetWorldPosition()
    for i, v in ipairs(TheSim:FindEntities(x, y, z, self:GetRadius(), nil, CANT_TAGS, ONEOF_TAGS)) do
        local follower = v.components.follower
        if follower ~= nil then
            if leader.components.leader:GetNumFollowers() < max_followers then
                if not v.components.follower:GetLeader()
                    and not leader.components.leader:IsFollower(v)
                    and follower:CanBeRollCalled(leader) then
                    leader.components.leader:AddFollower(v)
                end
            elseif not can_tend_crop then
                -- We're already full, so we can just stop (if we don't also tend crops)
                break
            end
        elseif can_tend_crop and v.components.farmplanttendable ~= nil then
            v.components.farmplanttendable:TendTo(leader)
        end
    end

    for ent in pairs(leader.components.leader.followers) do
        if ent:HasAnyTag(ONEOF_TAGS) and ent.components.follower:CanBeRollCalled(leader) then
            ent.components.follower:AddLoyaltyTime(5)
        end
    end

    if self.onrollcallfn ~= nil then
        self.onrollcallfn(self.inst)
    end
end

function LeaderRollCall:OnUpdate(dt)
    self.update_accumulation = self.update_accumulation + dt
    if self.update_accumulation < self.update_time then
        return
    end
    self.update_accumulation = 0
    self:DoRollCall()
end

function LeaderRollCall:GetDebugString()
    return string.format("leader: %s, update accumulation: %2.f", tostring(self:GetLeader()), self.update_accumulation)
end

return LeaderRollCall