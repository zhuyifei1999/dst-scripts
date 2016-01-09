local Inspectable = Class(function(self, inst)
    self.inst = inst
    inst:AddTag("inspectable")
    self.description = nil
    self.getspecialdescription = nil
end)

function Inspectable:OnRemoveFromEntity()
    self.inst:RemoveTag("inspectable")
end

--can be a string, a table of strings, or a function
function Inspectable:SetDescription(desc)
    self.description = desc
end

function Inspectable:RecordViews(state)
    self.recordview = state or true
end

function Inspectable:GetStatus(viewer)
    if self.inst == viewer then
        return
    end

    if self.recordview then
        ProfileStatsSet(self.inst.prefab .. "_examined", true)
    end

    return (self.getstatus ~= nil and self.getstatus(self.inst, viewer))
        or (self.inst.components.health ~= nil and self.inst.components.health:IsDead() and "DEAD")
        or (self.inst.components.sleeper ~= nil and self.inst.components.sleeper:IsAsleep() and "SLEEPING")
        or (self.inst.components.burnable ~= nil and self.inst.components.burnable:IsBurning() and "BURNING")
        or (self.inst.components.pickable ~= nil
            and ((self.inst:HasTag("withered") and "WITHERED") or
                (self.inst.components.pickable:IsBarren() and "BARREN") or
                (not self.inst.components.pickable:CanBePicked() and "PICKED")))
        or (self.inst.components.inventoryitem ~= nil and self.inst.components.inventoryitem:IsHeld() and "HELD")
        or (self.inst.components.occupiable ~= nil and self.inst.components.occupiable:IsOccupied() and "OCCUPIED")
        or (self.inst:HasTag("burnt") and "BURNT")
        or nil
end

function Inspectable:GetDescription(viewer)
    if self.inst == viewer then
        return
    elseif not CanEntitySeeTarget(viewer, self.inst) then
        return GetString(viewer, "DESCRIBE_TOODARK")
    elseif self.inst.prefab == viewer.prefab and not (self.inst:HasTag("playerghost") or viewer:HasTag("playerghost")) then
        return GetString(viewer, "DESCRIBE_SAMECHARACTER")
    end

    local desc
    if self.getspecialdescription ~= nil then
        -- for cases where we need to do additional processing before calling GetDescription (i.e. player skeleton)
        desc = self.getspecialdescription(self.inst, viewer)
    elseif self.descriptionfn ~= nil then
        desc = self.descriptionfn(self.inst, viewer)
    else
        desc = self.description
    end

    if desc == nil or viewer:HasTag("playerghost") or viewer:HasTag("mime") then
        -- force the call for ghost/mime
        return GetDescription(viewer, self.inst, self:GetStatus(viewer))
    elseif self.inst.components.burnable ~= nil and self.inst.components.burnable:IsSmoldering() then
        return GetString(viewer, "DESCRIBE_SMOLDERING")
    end

    return desc
end

return Inspectable
