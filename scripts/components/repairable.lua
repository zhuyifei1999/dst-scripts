local function onrepairmaterial(self, repairmaterial, old_repairmaterial)
    if old_repairmaterial ~= nil then
        self.inst:RemoveTag("repairable_"..old_repairmaterial)
    end
    if repairmaterial ~= nil then
        self.inst:AddTag("repairable_"..repairmaterial)
    end
end

local Repairable = Class(function(self, inst)
    self.inst = inst
    self.repairmaterial = nil
end,
nil,
{
    repairmaterial = onrepairmaterial,
})

function Repairable:OnRemoveFromEntity()
    if self.repairmaterial ~= nil then
        self.inst:RemoveTag("repairable_"..self.repairmaterial)
    end
end

local NEEDSREPAIRS_THRESHOLD = 0.95 -- don't complain about repairs if we're basically full.

function Repairable:NeedsRepairs()
	if self.inst.components.health then
		return self.inst.components.health:GetPercent() < NEEDSREPAIRS_THRESHOLD
	elseif self.inst.components.workable and self.inst.components.workable.workleft then
		return self.inst.components.workable.workleft < self.inst.components.workable.maxwork * NEEDSREPAIRS_THRESHOLD
    elseif self.inst.components.perishable and self.inst.components.perishable.perishremainingtime then
        return self.inst.components.perishable.perishremainingtime < self.inst.components.perishable.perishtime * NEEDSREPAIRS_THRESHOLD
	end
	return false
end

function Repairable:Repair(doer, repair_item)
    local didrepair = false

	if self.inst.components.health and self.inst.components.health:GetPercent() < 1 then
		if repair_item.components.repairer and self.repairmaterial == repair_item.components.repairer.repairmaterial then
			if self.inst.components.health.DoDelta then
                self.inst.components.health:DoDelta(repair_item.components.repairer.healthrepairvalue)
                self.inst.components.health:DoDelta(repair_item.components.repairer.healthrepairpercent * self.inst.components.health.maxhealth)
            end
			
			if repair_item.components.stackable then
				repair_item.components.stackable:Get():Remove()
			else
				repair_item:Remove()
			end

            didrepair = true
        end
    end
    if self.inst.components.workable and self.inst.components.workable.workleft and self.inst.components.workable.workleft < self.inst.components.workable.maxwork then
		if repair_item.components.repairer and self.repairmaterial == repair_item.components.repairer.repairmaterial then
	        self.inst.components.workable:SetWorkLeft( self.inst.components.workable.workleft + repair_item.components.repairer.workrepairvalue )
			
			if repair_item.components.stackable then
				repair_item.components.stackable:Get():Remove()
			else
				repair_item:Remove()
			end

            didrepair = true
        end
    end
    if self.inst.components.perishable and self.inst.components.perishable.perishremainingtime and self.inst.components.perishable.perishremainingtime < self.inst.components.perishable.perishtime then
        if repair_item.components.repairer and self.repairmaterial == repair_item.components.repairer.repairmaterial then
            self.inst.components.perishable:SetPercent( self.inst.components.perishable:GetPercent() + repair_item.components.repairer.perishrepairpercent )

            if repair_item.components.stackable then
                repair_item.components.stackable:Get():Remove()
            else
                repair_item:Remove()
            end

            didrepair = true
        end
    end

    if didrepair and self.onrepaired ~= nil then
        self.onrepaired(self.inst, doer, repair_item)
    end

    return didrepair
end

return Repairable