local function onmatured(self, matured)
    if matured then
        self.inst:AddTag("readyforharvest")
        self.inst:RemoveTag("notreadyforharvest")
    else
        self.inst:RemoveTag("readyforharvest")
        self.inst:AddTag("notreadyforharvest")
    end
end

local Crop = Class(function(self, inst)
    self.inst = inst
    self.product_prefab = nil
    self.growthpercent = 0
    self.rate = 1/120
    self.task = nil
    self.matured = false
    self.onmatured = nil
end,
nil,
{
    matured = onmatured,
})

function Crop:OnRemoveFromEntity()
    self.inst:RemoveTag("readyforharvest")
    self.inst:RemoveTag("notreadyforharvest")
end

function Crop:SetOnMatureFn(fn)
    self.onmatured = fn
end

function Crop:OnSave()
    local data = 
    {
        prefab = self.product_prefab,
        percent = self.growthpercent,
        rate = self.rate,
        matured = self.matured,
    }
    return data
end   

function Crop:OnLoad(data)
	if data then
		self.product_prefab = data.prefab or self.product_prefab
		self.growthpercent = data.percent or self.growthpercent
		self.rate = data.rate or self.rate
		self.matured = data.matured or self.matured
	end
	
	self:DoGrow(0)
    if self.product_prefab and self.matured then
		self.inst.AnimState:PlayAnimation("grow_pst")
        if self.onmatured then
            self.onmatured(self.inst)
        end
    end
	
end   

function Crop:Fertilize(fertilizer)
	
	if not (TheWorld.state.iswinter and TheWorld.state.temperature <= 0) then
		self.growthpercent = self.growthpercent + fertilizer.components.fertilizer.fertilizervalue*self.rate
		self.inst.AnimState:SetPercent("grow", self.growthpercent)
		if self.growthpercent >=1 then
			self.inst.AnimState:PlayAnimation("grow_pst")
			self:Mature()
			self.task:Cancel()
			self.task = nil
		end
		fertilizer:Remove()
		return true
	end    
end

function Crop:DoGrow(dt)
    self.inst.AnimState:SetPercent("grow", self.growthpercent)
    
    local temp_rate = 1
    
    if TheWorld.state.temperature < TUNING.MIN_CROP_GROW_TEMP then
		temp_rate = 0
    else
        if TheWorld.state.temperature > TUNING.CROP_BONUS_TEMP then
		  temp_rate = temp_rate + TUNING.CROP_HEAT_BONUS
        end

        if TheWorld.state.israining then
            temp_rate = temp_rate + TUNING.CROP_RAIN_BONUS * TheWorld.state.precipitationrate
        end

    end

    local in_light = TheSim:GetLightAtPoint(self.inst.Transform:GetWorldPosition()) > TUNING.DARK_CUTOFF
    if in_light then
        self.growthpercent = self.growthpercent + dt*self.rate*temp_rate
    end

    if self.growthpercent >= 1 then
        self.inst.AnimState:PlayAnimation("grow_pst")
        self:Mature()
        if self.task then
            self.task:Cancel()
            self.task = nil
        end
    end
end

function Crop:GetDebugString()
    local s = "[" .. tostring(self.product_prefab) .. "] "
    if self.matured then
        s = s .. "DONE"
    else
        s = s .. string.format("%2.2f%% (done in %2.2f)", self.growthpercent, (1 - self.growthpercent)/self.rate)
    end
    return s
end

function Crop:Resume()
    if not self.matured then
    
		if self.task then
			scheduler:KillTask(self.task)
		end
		self.inst.AnimState:SetPercent("grow", self.growthpercent)
		local dt = 2
		self.task = self.inst:DoPeriodicTask(dt, function() self:DoGrow(dt) end)
	end
end

function Crop:StartGrowing(prod, grow_time, grower, percent)
    self.product_prefab = prod
    if self.task then
        scheduler:KillTask(self.task)
    end
    self.rate = 1/ grow_time
    local me = self
    self.growthpercent = percent or 0
    self.inst.AnimState:SetPercent("grow", self.growthpercent)
    
    local dt = 2
    self.task = self.inst:DoPeriodicTask(dt, function() self:DoGrow(dt) end)
    self.grower = grower
end

function Crop:Harvest(harvester)
    
    if self.matured then
		local product = SpawnPrefab(self.product_prefab)
        if harvester then
            harvester.components.inventory:GiveItem(product)
        else
            product.Transform:SetPosition(self.grower.Transform:GetWorldPosition())
            Launch(product, self.grower, TUNING.LAUNCH_SPEED_SMALL)
        end 
        ProfileStatsAdd("grown_"..product.prefab) 
        
        self.matured = false
        self.growthpercent = 0
        self.product_prefab = nil
        self.grower.components.grower:RemoveCrop(self.inst)
        self.grower = nil
        
        return true
    end
end

function Crop:Mature()
    if self.product_prefab and not self.matured then
        self.matured = true
        if self.onmatured then
            self.onmatured(self.inst)
        end
    end
end

function Crop:IsReadyForHarvest()
    return self.matured == true
end

function Crop:LongUpdate(dt)
	self:DoGrow(dt)		
end

return Crop