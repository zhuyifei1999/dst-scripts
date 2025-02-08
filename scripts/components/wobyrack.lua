local WobyRack = Class(function(self, inst)
	self.inst = inst
	self.container = SpawnPrefab("woby_rack_container").components.container
	self.container.inst.entity:SetParent(inst.entity)
	self.container.isexposed = false
	self.enabled = false
	self.dryingpaused = true
	self.dryinginfo = {}
	self.showitemfn = nil
	self.hideitemfn = nil

	inst:ListenForEvent("itemget", function(_, data)
		if data and data.item then
			self:OnGetItem(data.item, data.slot)
		end
	end, self.container.inst)
	inst:ListenForEvent("itemlose", function(_, data)
		if data and data.prev_item then
			self:OnLoseItem(data.prev_item, data.slot)
		end
	end, self.container.inst)
end)

function WobyRack:OnRemoveFromEntity()
	self:DisableDrying()
	self.container:DropEverything()
	self.container.inst:Remove()
end

function WobyRack:GetContainer()
	return self.container
end

function WobyRack:SetShowItemFn(fn)
	self.showitemfn = fn
end

function WobyRack:SetHideItemFn(fn)
	self.hideitemfn = fn
end

function WobyRack:GetItemInSlot(slot)
	local item = self.container:GetItemInSlot(slot)
	if item then
		local build
		if item.components.dryable then
			build = item.components.dryable:GetBuildFile()
		else
			local info = self.dryinginfo[item]
			if info then
				build = info.build
			end
		end
		return item, item.prefab, build or "meat_rack_food"
	end
end

local function OnIsRaining(self, israining)
	if israining and not self:HasRainImmunity() then
		self:PauseDrying()
	else
		self:ResumeDrying()
	end
end

local function OnRainImmunity(inst)
	inst.components.wobyrack:ResumeDrying()
end

local function OnRainVulnerable(inst)
	local self = inst.components.wobyrack
	if self:IsExposedToRain() then
		inst.components.wobyrack:PauseDrying()
	end
end

local function OnRiderChanged(inst, data)
	local self = inst.components.wobyrack
	if self._rider then
		inst:RemoveEventCallback("gainrainimmunity", self._onriderrainimmunity, self._rider)
		inst:RemoveEventCallback("loserainimmunity", self._onriderrainvulnerable, self._rider)
	end
	self._rider = data and data.newrider or nil
	if self._rider then
		inst:ListenForEvent("gainrainimmunity", self._onriderrainimmunity, self._rider)
		inst:ListenForEvent("loserainimmunity", self._onriderrainvulnerable, self._rider)
	end

	if self:IsExposedToRain() then
		self:PauseDrying()
	else
		self:ResumeDrying()
	end
end

local function DryingPerishRateFn(inst, item)
	return item.components.dryable and 0 or nil
end

function WobyRack:EnableDrying()
	if not self.enabled then
		self.enabled = true
		self.container.isexposed = true
		self.container.inst:AddComponent("preserver")
		self.container.inst.components.preserver:SetPerishRateMultiplier(DryingPerishRateFn)

		self:WatchWorldState("israining", OnIsRaining)
		self.inst:ListenForEvent("gainrainimmunity", OnRainImmunity)
		self.inst:ListenForEvent("loserainimmunity", OnRainVulnerable)
		if self.inst.components.rideable then
			self.inst:ListenForEvent("riderchanged", OnRiderChanged)
			self._onriderrainimmunity = function() OnRainImmunity(self.inst) end
			self._onriderrainvulnerable = function() OnRainVulnerable(self.inst) end
			self._rider = self.inst.components.rideable:GetRider()
			if self._rider then
				self.inst:ListenForEvent("gainrainimmunity", self._onriderrainimmunity, self._rider)
				self.inst:ListenForEvent("loserainimmunity", self._onriderrainvulnerable, self._rider)
			end
		end

		if not self:IsExposedToRain() then
			self:ResumeDrying()
		end
	end
end

function WobyRack:DisableDrying()
	if self.enabled then
		self.enabled = false
		self.container.isexposed = false
		self.container.inst:RemoveComponent("preserver")

		self:StopWatchingWorldState("israining", OnIsRaining)
		self.inst:RemoveEventCallback("gainrainimmunity", OnRainImmunity)
		self.inst:RemoveEventCallback("loserainimmunity", OnRainVulnerable)
		self.inst:RemoveEventCallback("riderchanged", OnRiderChanged)
		if self._rider then
			self.inst:RemoveEventCallback("gainrainimmunity", self._onriderrainimmunity, self._rider)
			self.inst:RemoveEventCallback("loserainimmunity", self._onriderrainvulnerable, self._rider)
		end

		self:PauseDrying()
	end
end

local function OnDoneDrying(inst, self, item)
	self.dryinginfo[item] = nil
	local slot = self.container:GetItemSlot(item)
	local product = item.components.dryable and item.components.dryable:GetProduct() or nil
	if slot and product then
		product = SpawnPrefab(product)
		if product then
			local build = item.components.dryable:GetDriedBuildFile()
			if product.components.inventoryitem then
				product.components.inventoryitem:InheritMoisture(item.components.inventoryitem:GetMoisture(), item.components.inventoryitem:IsWet())
			end
			item:Remove()
			print("WobyRack: Done drying", product.prefab)
			self.container:GiveItem(product, slot)
			local info = self.dryinginfo[product]
			if info == nil then --just making sure it's not another dryable item
				self.dryinginfo[product] = { build = build }
				if self.showitemfn then
					self.showitemfn(self.inst, slot, product.prefab, build or "meat_rack_food")
				end
			end
			return product --returned for LongUpdate
		end
	end
end

function WobyRack:OnGetItem(item, slot)
	local info = self.dryinginfo[item]
	if info == nil then
		if item.components.dryable then
			local product = item.components.dryable:GetProduct()
			local drytime = item.components.dryable:GetDryTime()
			if product and drytime then
				info = {}
				self.dryinginfo[item] = info
				if self.dryingpaused then
					print("WobyRack: Start drying (paused)", item, drytime)
					info.drytime = drytime
				else
					print("WobyRack: Start drying", item, drytime)
					info.task = self.inst:DoTaskInTime(drytime, OnDoneDrying, self, item)
				end
			end
			if slot and self.showitemfn then
				self.showitemfn(self.inst, slot, item.prefab, item.components.dryable:GetBuildFile() or "meat_rack_food")
			end
		elseif slot and self.showitemfn then
			self.showitemfn(self.inst, slot, item.prefab, "meat_rack_food")
		end
	end
end

function WobyRack:OnLoseItem(item, slot)
	local info = self.dryinginfo[item]
	if info then
		if info.task or info.drytime then
			print("WobyRack: Stop drying", item)
		end
		if info.task then
			info.task:Cancel()
		end
		self.dryinginfo[item] = nil
	end
	if slot and self.hideitemfn then
		self.hideitemfn(self.inst, slot)
	end
end

function WobyRack:IsExposedToRain()
	return TheWorld.state.israining and not self:HasRainImmunity()
end

function WobyRack:HasRainImmunity()
	return self.inst.components.rainimmunity ~= nil or (self._rider ~= nil and self._rider.components.rainimmunity ~= nil)
end

function WobyRack:PauseDrying()
	if not self.dryingpaused then
		self.dryingpaused = true
		print("WobyRack: Drying paused")
		for item, info in pairs(self.dryinginfo) do
			if info.task then
				info.drytime = GetTaskRemaining(info.task)
				print("WobyRack: --", item, info.drytime)
				info.task:Cancel()
				info.task = nil
			end
		end
	end
end

function WobyRack:ResumeDrying()
	if self.dryingpaused then
		self.dryingpaused = false
		print("WobyRack: Drying resumed")
		for item, info in pairs(self.dryinginfo) do
			if info.drytime then
				print("WobyRack: --", item, info.drytime)
				info.task = self.inst:DoTaskInTime(info.drytime, OnDoneDrying, self, item)
				info.drytime = nil
			end
		end
	end
end

function WobyRack:LongUpdate(dt)
	if self.enabled then
		local todone = {}
		for item, info in pairs(self.dryinginfo) do
			if info.task then
				local t = GetTaskRemaining(info.task)
				info.task:Cancel()
				if t > dt then
					info.task = self.inst:DoTaskInTime(t - dt, OnDoneDrying, self, item)
				else
					table.insert(todone, { item = item, dt = dt - t })
				end
			elseif info.drytime then
				if info.drytime > dt then
					info.drytime = info.drytime - dt
				else
					table.insert(todone, { item = item, dt = dt - info.drytime })
				end
			end
		end
		for i, v in ipairs(todone) do
			local product = OnDoneDrying(self.inst, self, v.item)
			if product and v.dt > 0 then
				product:LongUpdate(v.dt)
			end
		end
	end
end

function WobyRack:OnSave()
	if not self.container:IsEmpty() then
		local contents, refs = self.container.inst:GetPersistData()
		local info = {}
		for k, v in pairs(self.dryinginfo) do
			local slot = self.container:GetItemSlot(k)
			if slot then
				info[slot] =
					(v.task and math.floor(GetTaskRemaining(v.task))) or
					(v.drytime and math.floor(v.drytime)) or
					v.build
			end
		end
		return { contents = contents, info = next(info) and info or nil }, refs
	end
end

function WobyRack:OnLoad(data, newents)
	if data.contents then
		self.container.inst:SetPersistData(data.contents, newents)
		if data.info then
			for k, v in pairs(data.info) do
				local item = self.container:GetItemInSlot(k)
				if item then
					local info = self.dryinginfo[item]
					if type(v) == "number" then
						if info then
							if info.task then
								info.task:Cancel()
								info.task = self.inst:DoTaskInTime(v, OnDoneDrying, self, item)
								print("WobyRack: Restart drying", item, v)
							elseif info.drytime then
								info.drytime = v
								print("WobyRack: Restart drying (paused)", item, v)
							end
						end
					elseif info == nil then
						self.dryinginfo[ent.entity] = { build = v }
						if self.showitemfn then
							self.showitemfn(self.inst, k, ent.entity.prefab, v)
						end
					end
				end
			end
		end
	end
end

function WobyRack:GetDryingInfoSnapshot()
	local info = {}
	for k, v in pairs(self.dryinginfo) do
		info[k] =
			(v.task and GetTaskRemaining(v.task)) or
			(v.drytime and v.drytime) or
			v.build
	end
	return next(info) and info or nil
end

function WobyRack:ApplyDryingInfoSnapshot(snapshot)
	for k, v in pairs(snapshot) do
		local info = self.dryinginfo[k]
		if type(v) == "number" then
			if info then
				if info.task then
					info.task:Cancel()
					info.task = self.inst:DoTaskInTime(v, OnDoneDrying, self, k)
					print("WobyRack: Restart drying", k, v)
				elseif info.drytime then
					info.drytime = v
					print("WobyRack: Restart drying (paused)", k, v)
				end
			end
		elseif info == nil then
			local slot = self.container:GetItemSlot(ent.entity)
			if slot then
				self.dryinginfo[k] = { build = v }
				if self.showitemfn then
					self.showitemfn(self.inst, slot, k.prefab, v)
				end
			end
		end
	end
end

return WobyRack
