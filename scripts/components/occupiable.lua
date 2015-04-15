local function onoccupant(self, occupant)
    if occupant ~= nil then
        self.inst:AddTag("occupied")
        if self.occupanttype ~= nil then
            self.inst:RemoveTag(self.occupanttype.."_occupiable")
        end
    else
        self.inst:RemoveTag("occupied")
        if self.occupanttype ~= nil then
            self.inst:AddTag(self.occupanttype.."_occupiable")
        end
    end
end

local function onoccupanttype(self, occupanttype, old_occupanttype)
    if self.occupant == nil then
        if old_occupanttype ~= nil then
            self.inst:RemoveTag(old_occupanttype.."_occupiable")
        end
        if occupanttype ~= nil then
            self.inst:AddTag(occupanttype.."_occupiable")
        end
    end
end

local Occupiable = Class(function(self, inst)
    self.inst = inst
    self.occupant = nil
    self.occupanttype = nil
end,
nil,
{
    occupant = onoccupant,
    occupanttype = onoccupanttype,
})

function Occupiable:OnRemoveFromEntity()
    self.inst:RemoveTag("occupied")
    if self.occupanttype ~= nil then
        self.inst:RemoveTag(self.occupanttype.."_occupiable")
    end
end

function Occupiable:IsOccupied()
	return self.occupant ~= nil
end

function Occupiable:CanOccupy(occupier)
	return self.occupant == nil and
        self.occupanttype ~= nil and
        occupier:HasTag(self.occupanttype) and
        occupier.components.occupier ~= nil
end

function Occupiable:Occupy(occupier)
	
	if not self.occupant and occupier and occupier.components.occupier then
		self.occupant = occupier
		self.occupant.persists = true
		
		if occupier.components.occupier.onoccupied then
			occupier.components.occupier.onoccupied(occupier, self.inst)
		end
		
		if self.onoccupied then
			self.onoccupied(self.inst, occupier)
		end	
		
		self.inst:AddChild(occupier)
		occupier:RemoveFromScene()
	end
		
end

function Occupiable:Harvest()
	if self.occupant and self.occupant.components.inventoryitem then
		local occupant = self.occupant
		self.occupant = nil
		self.inst:RemoveChild(occupant)
		if self.onemptied then
			self.onemptied(self.inst)
		end
		occupant:ReturnToScene()
		return occupant
	end
end

function Occupiable:OnSave()
    local data = {}
    if self.occupant and self.occupant:IsValid() then
		data.occupant = self.occupant:GetSaveRecord()
    end
    return data
end   

function Occupiable:OnLoad(data, newents)

    if data.occupant then
        local inst = SpawnSaveRecord(data.occupant, newents)
		if inst then
			self:Occupy(inst)
		end
    end

end

return Occupiable