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
    if self.inst == viewer then return end

    local status = self.getstatus and self.getstatus(self.inst, viewer)
    if not status then
        if self.inst.components.health and self.inst.components.health:IsDead() then
            status = "DEAD"
        elseif self.inst.components.sleeper and self.inst.components.sleeper:IsAsleep() then
            status = "SLEEPING"
        elseif self.inst.components.burnable and self.inst.components.burnable:IsBurning() then
            status = "BURNING"
        elseif self.inst.components.pickable and self.inst:HasTag("withered") then 
        	status = "WITHERED"
		elseif self.inst.components.pickable and self.inst.components.pickable:IsBarren() then
			status = "BARREN"
        elseif self.inst.components.pickable and not self.inst.components.pickable:CanBePicked() then
            status = "PICKED"
        elseif self.inst.components.inventoryitem and self.inst.components.inventoryitem:IsHeld() then
            status = "HELD"
        elseif self.inst.components.occupiable and self.inst.components.occupiable:IsOccupied() then
            status = "OCCUPIED"
        elseif self.inst:HasTag("burnt") then
            status = "BURNT"
        end
    end
    if self.recordview then
        dprint("++++++++++++++++++STATUSVIEW")
        ProfileStatsSet(self.inst.prefab .. "_examined", true)
    end
    return status
end

function Inspectable:GetDescription(viewer)
    if self.inst == viewer then
        return
    end

    local desc = self.description

    if desc == nil and self.descriptionfn then
        desc = self.descriptionfn(self.inst, viewer)
    end

    -- for cases where we need to do additional processing before calling GetDescription (i.e. player skeleton)
    if self.getspecialdescription ~= nil then
        desc = self.getspecialdescription(self.inst, viewer)
    end

    if not CanEntitySeeTarget(viewer, self.inst) then
        return GetString(viewer, "DESCRIBE_TOODARK")
    elseif self.inst.prefab == viewer.prefab and not (self.inst:HasTag("playerghost") or viewer:HasTag("playerghost")) then
        return GetString(viewer, "DESCRIBE_SAMECHARACTER")
    elseif desc == nil or viewer:HasTag("playerghost") or viewer:HasTag("mime") then
        -- force the call for ghost/mime
        return GetDescription(viewer, self.inst, self:GetStatus(viewer))
    end

        
    if self.inst:HasTag("smolder") then
        desc = GetString(viewer.prefab, "DESCRIBE_SMOLDERING")
    end
        
    return desc
end

return Inspectable