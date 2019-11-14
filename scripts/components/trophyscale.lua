local function ontype(self, type, old_type)
	if old_type ~= nil then
		self.inst:Removetag("trophyscale_"..old_type)
	end
	if type ~= nil then
		self.inst:AddTag("trophyscale_"..type)
	end
end

local TrophyScale = Class(function(self, inst)
    self.inst = inst

	self.type = nil
	self.item_data = nil
	self.compare_postfn = nil

	self.accepts_items = true

	self.inst:AddTag("trophyscale")
end,
nil,
{
	type = ontype
})

function TrophyScale:OnRemoveFromEntity()
    self.inst:RemoveTag("trophyscale")
end

function TrophyScale:GetDebugString()
    return self.item_data ~= nil and string.format("weight: %.5f,   prefab: %s,   owner: %s", self.item_data.weight, self.item_data.prefab or "nil", self.item_data.owner ~= nil and self.item_data.owner or "nil")
		or string.format("empty")
end

function TrophyScale:SetComparePostFn(fn)
	self.compare_postfn = fn
end

function TrophyScale:GetItemData()
	return self.item_data
end

function TrophyScale:Compare(inst_compare, doer)
	local new_weight = inst_compare.components.weighable:GetWeight()

	if self.item_data == nil or new_weight > self.item_data.weight then
		local item_data_old = deepcopy(self.item_data)

		self.item_data = {}
		self.item_data.weight = new_weight
		self.item_data.prefab = inst_compare.prefab
		self.item_data.build = inst_compare.AnimState:GetBuild()
		self.item_data.owner_userid = doer.userid
		self.item_data.owner_name = doer.name

		if self.compare_postfn ~= nil then
			self.compare_postfn(self.item_data, inst_compare)
		end

		inst_compare:Remove()

		self.inst:PushEvent("onnewtrophy", { old = item_data_old, new = self.item_data })

		return true
	else
		return false, "TOO_SMALL"
	end
end

function TrophyScale:ClearItemData()
	self.item_data = nil
end

function TrophyScale:OnSave()
	return self.item_data
end

function TrophyScale:OnLoad(data)
	if data ~= nil then
		self.item_data = data
	end
end

return TrophyScale