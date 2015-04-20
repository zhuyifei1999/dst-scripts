--Updated by "inventorymoisture" on the world.
--Updated in batches to avoid slowdown due to the amount of inventory items.

local function onmoisture(self, moisture)
	if self.inst.replica.inventoryitem ~= nil then
		self.inst.replica.inventoryitem:SetMoistureLevel(moisture)
	end
end

local function onwet(self, wet)
	if wet then
		self.inst:AddTag("wet")
		self.inst:RemoveTag("notwet")
	else
		self.inst:RemoveTag("wet")
		self.inst:AddTag("notwet")
	end

	if self.inst.replica.inventoryitem ~= nil then
		self.inst.replica.inventoryitem:SetWet(wet)
	end
end

local InventoryMoistureListener = Class(function(self, inst)
	self.inst = inst

	self.moisture = 0

	self.wet = false

	self.dryingSpeed = -1
	self.dryingResistance = 1
	
	self.wetnessSpeed = 0.5
	self.wetnessResistance = 1

	self.lastUpdate = GetTime() or 0

	self.wetnessThreshold = TUNING.MOISTURE_WET_THRESHOLD
	self.drynessThreshold = TUNING.MOISTURE_DRY_THRESHOLD
	
	self.inst:DoTaskInTime(0, function() TheWorld:PushEvent("trackinventoryitem", self.inst) end)
end,
nil,
{
	moisture = onmoisture,
	wet = onwet,
})

function InventoryMoistureListener:OnSave()
	local data = {}
	data.moisture = self.moisture
	return data
end

function InventoryMoistureListener:OnLoad(data)
	if data then
		self.moisture = data.moisture
	end
end

function InventoryMoistureListener:GetDebugString()
	return string.format("Current Moisture: %2.2f, Target Moisture: %2.2f", self.moisture, self:GetTargetMoisture() or 0)
end

function InventoryMoistureListener:IsWet()
	return self.wet
end

function InventoryMoistureListener:Dilute(number, moisture)
	if self.inst.components.stackable then
		self.moisture = (self.inst.components.stackable.stacksize * self.moisture + number * moisture) / ( number + self.inst.components.stackable.stacksize )
	end
end

function InventoryMoistureListener:GetMoisture()
	return self.moisture
end

function InventoryMoistureListener:GetIsWet()
    return self.wet
end

function InventoryMoistureListener:DoDelta(delta)
	self.moisture = self.moisture + delta
	self:DoUpdate(0)
end

function InventoryMoistureListener:GetTargetMoisture()
	if not self.inst.components.inventoryitem
		or (not TheWorld.state.israining
			and not self.inst.components.inventoryitem.owner) then
		return 0
	end
	local owner = self.inst.components.inventoryitem.owner
	if owner then
		if owner.components.container then
			--All containers keep items dry.
			return 0
		elseif owner.components.inventory and owner.components.moisture then
			return owner.components.moisture:GetMoisture() 
		end
	else
		return TheWorld.state.wetness
	end
end

function InventoryMoistureListener:DoUpdate()
	self:UpdateMoisture(GetTime() - self.lastUpdate)
end

function InventoryMoistureListener:UpdateMoisture(dt)
	local targetMoisture = self:GetTargetMoisture() or 0

	local speed = 0
	if targetMoisture and targetMoisture > self.moisture then
		speed = self.wetnessSpeed * self.wetnessResistance
	else
		speed = self.dryingSpeed * self.dryingResistance
	end
	
	local difference = targetMoisture - self.moisture
	local delta = speed * dt

	if math.abs(difference) < math.abs(delta) then
		delta = difference
	end

	self.moisture = self.moisture + delta

	if self.moisture >= self.wetnessThreshold then
		self.wet = true
        self.inst:PushEvent("wetnesschange", true)
	elseif self.moisture < self.drynessThreshold then
		self.wet = false
        self.inst:PushEvent("wetnesschange", false)
	end

	self.lastUpdate = GetTime()
end


return InventoryMoistureListener
