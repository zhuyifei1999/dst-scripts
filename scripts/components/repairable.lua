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

function Repairable:NeedsRepairs()
	if self.inst.components.health then
		return self.inst.components.health:GetPercent() < 1
	elseif self.inst.components.workable.workleft then
		return self.inst.components.workable.workleft < self.inst.components.workable.maxwork
	end	
	return false		
end

function Repairable:Repair(doer, repair_item)
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
			
			if self.onrepaired then
				self.onrepaired(self.inst, doer, repair_item)
			end
			return true
		end
    elseif self.inst.components.workable.workleft and self.inst.components.workable.workleft < self.inst.components.workable.maxwork then
		if repair_item.components.repairer and self.repairmaterial == repair_item.components.repairer.repairmaterial then
	        self.inst.components.workable:SetWorkLeft( self.inst.components.workable.workleft + repair_item.components.repairer.workrepairvalue )
			
			if repair_item.components.stackable then
				repair_item.components.stackable:Get():Remove()
			else
				repair_item:Remove()
			end

			if self.onrepaired then
				self.onrepaired(self.inst, doer, repair_item)
			end
			return true
        end
	end
end

return Repairable