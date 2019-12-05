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

	self.owner_userid = nil
	self.owner_name = nil

	-- Set when trophy is dropped (considered "caught") by a mob, e.g. a merm
	-- self.prefab_override_owner = nil
end,
nil,
{
	type = ontype
})

function Weighable:OnRemoveFromEntity()
	if self.type ~= nil then
		self.inst:Removetag("weighable_"..self.type)
	end
end

function Weighable:CopyWeighable(src_weighable)
	if src_weighable ~= nil then
		self:OnLoad(src_weighable:OnSave())
	end
end

function Weighable:GetWeight()
	return self.weight
end

function Weighable:SetWeight(weight)
	self.weight = math.floor(weight * 100) / 100
end

function Weighable:SetPlayerAsOwner(owner)
	if owner ~= nil then
		self.owner_userid = owner.userid
		self.owner_name = owner.name
	else
		self.owner_userid = nil
		self.owner_name = nil
	end
end

function Weighable:OnSave()
	return { 
		weight = self.weight,
		owner_userid = self.owner_userid,
		owner_name = self.owner_name,
		prefab_override_owner = self.prefab_override_owner 
	}
end

function Weighable:OnLoad(data)
	if data ~= nil then
		self.weight = data.weight
		self.owner_userid = data.owner_userid
		self.owner_name = data.owner_name
		self.prefab_override_owner = data.prefab_override_owner
	end
end

function Weighable:GetDebugString()
    return string.format("weight %.5f, owner_userid %s, override owner: %s", self.weight, tostring(self.owner_userid), tostring(self.prefab_override_owner))
end

return Weighable