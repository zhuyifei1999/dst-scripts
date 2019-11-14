local function ontype(self, type, old_type)
	if old_type ~= nil then
		self.inst:Removetag("weighable_"..old_type)
	end
	if type ~= nil then
		self.inst:AddTag("weighable_"..type)
	end
end

local Weighable = Class(function(self, inst)
    self.inst = inst

	self.type = nil
	self.weight = nil

	self.inst:AddTag("weighable")
end,
nil,
{
	type = ontype
})

function Weighable:OnRemoveFromEntity()
    self.inst:RemoveTag("weighable")
end

function Weighable:GetDebugString()
    return string.format("weight %.5f", self.weight)
end

function Weighable:GetWeight()
	return self.weight
end

function Weighable:SetWeight(weight)
	self.weight = math.floor(weight * 100) / 100
end

function Weighable:OnSave()
	return { weight = self.weight }
end

function Weighable:OnLoad(data)
	if data ~= nil then
		self.weight = data.weight
	end
end

return Weighable