local GroupTargeter = Class(function(self, inst)
	self.inst = inst
	self.targets = {}
	self.total_weight = 1
	self.weight_change = 0.1
	self.num_targets = 0

	self.min_chance = 0
	self.max_chance = 0.7
	self.chance_delta = 0.1
	self.current_chance = 0
end)

function GroupTargeter:RedistributeWeight(oldTotal, newTotal, target)
	--print("RedistributeWeights...")
	if newTotal > oldTotal then
		local weighting = 0

		for k,v in pairs(self.targets) do
			local loss = oldTotal/newTotal
			local prev = v
			local new = v * loss
			self.targets[k] = new
			weighting = weighting + (prev - new)
		end

		self.targets[target] = weighting
	elseif oldTotal > newTotal then
		local targetThreat = self.targets[target]
		self.targets[target] = nil
		for k,v in pairs(self.targets) do
			self.targets[k] = v + (targetThreat / newTotal)
		end
	end
	--self:GetTotalWeight()
end

function GroupTargeter:GetTotalWeight() --For debug. This should only ever return 1.
	local totalWeight = 0
	for k,v in pairs(self.targets) do
		totalWeight = totalWeight + v
	end
	print(string.format("NEW TOTAL WEIGHT IS %2.2f", totalWeight))
end

function GroupTargeter:OnPickTarget(target)
	--print("GOT NEW TARGET! -", target or "ERROR - DID NOT FIND TARGET")
	
	if self.num_targets <= 1 then --[[ print("only 1 target - returning") ]] return end

	for k,v in pairs(self.targets) do
		if k == target then
			self.targets[k] = v - self.weight_change
		else
			self.targets[k] = v + (self.weight_change/(self.num_targets - 1))
		end
	end
	--self:GetTotalWeight()
end

function GroupTargeter:AddTarget(target)
	local oldNum = self.num_targets
	self.num_targets = self.num_targets + 1
	local newNum = self.num_targets

	if oldNum == 0 then
		self.targets[target] = 1
	else
		self:RedistributeWeight(oldNum, newNum, target)
	end

	--print("Adding target", target, "with a weight of", self.targets[target])
end

function GroupTargeter:RemoveTarget(target)
	--print("Removing target", target, "with a weight of", self.targets[target])

	local oldNum = self.num_targets
	self.num_targets = self.num_targets - 1
	local newNum = self.num_targets

	if newNum == 0 then
		self.targets = {}
	else
		self:RedistributeWeight(oldNum, newNum, target)
	end
end

function GroupTargeter:GetTargets()
	return self.targets
end

function GroupTargeter:TryGetNewTarget()
	--print("Trying to get a new target...")
	local change_chance = math.random()

	if change_chance < self.current_chance then
		self.current_chance = self.min_chance
		local target = self:SelectTarget()
		self:OnPickTarget(target)
		return target
	else
		--print("Failed to get new target!")
		self.current_chance = self.current_chance + self.chance_delta
		self.current_chance = math.clamp(self.current_chance, self.min_chance, self.max_chance)
		--print("New chance to get a new target is...", self.current_chance)
		return nil
	end
end

function GroupTargeter:SelectTarget()
	local selection_weight = math.random()
	--print(string.format("Picking new target with weight in %2.2f range.", selection_weight))

	local selected_target = nil
	local weight = 0

	for target, target_weight in pairs(self.targets) do
		--print(string.format("Checking %s in range %2.2f - %2.2f", target.prefab, weight, weight + target_weight))
		if selection_weight <= weight + target_weight and
		selection_weight > weight then
			return target
		else
			weight = weight + target_weight
		end
	end
end

return GroupTargeter