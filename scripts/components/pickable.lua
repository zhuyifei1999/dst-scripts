local function onpickable(self)
    if self.canbepicked and self.caninteractwith then
        self.inst:AddTag("pickable")
    else
        self.inst:RemoveTag("pickable")
    end
end

local function oncyclesleft(self, cyclesleft)
    if cyclesleft == 0 then
        self.inst:AddTag("barren")
    else
        self.inst:RemoveTag("barren")
    end
end

local function onquickpick(self, quickpick)
    if quickpick then
        self.inst:AddTag("quickpick")
    else
        self.inst:RemoveTag("quickpick")
    end
end

local Pickable = Class(function(self, inst)
    self.inst = inst
    self.canbepicked = nil
    self.regentime = nil
    self.baseregentime = nil
    self.product = nil
    self.onregenfn = nil
    self.onpickedfn = nil
    self.makeemptyfn = nil
    self.makefullfn = nil
    self.cycles_left = nil
    self.transplanted = false
    self.caninteractwith = true
    self.numtoharvest = 1
    self.quickpick = false
    self.wildfirestarter = false
    
    self.paused = false
    self.pause_time = 0

    self.protected_cycles = nil
end,
nil,
{
    canbepicked = onpickable,
    caninteractwith = onpickable,
    cycles_left = oncyclesleft,
    quickpick = onquickpick,
})

function Pickable:OnRemoveFromEntity()
    self.inst:RemoveTag("pickable")
    self.inst:RemoveTag("barren")
    self.inst:RemoveTag("quickpick")
end

function Pickable:LongUpdate(dt)

	if not self.paused and self.targettime and not self.inst:HasTag("withered") then
	
		if self.task then 
			self.task:Cancel()
			self.task = nil
		end
	
	    local time = GetTime()
		if self.targettime > time + dt then
	        --resechedule
	        local time_to_pickable = self.targettime - time - dt
	        if TheWorld.state.isspring then time_to_pickable = time_to_pickable * TUNING.SPRING_GROWTH_MODIFIER end
			self.task = self.inst:DoTaskInTime(time_to_pickable, OnRegen, "regen")
			self.targettime = time + time_to_pickable
	    else
			--become pickable right away
			self:Regen()
	    end
	end
end

function Pickable:IsWildfireStarter()
	return (self.wildfirestarter == true or self.inst:HasTag("withered") == true)
end

function Pickable:FinishGrowing()
	if not self.canbepicked and not self.inst:HasTag("withered") then
		if self.task then
			self.task:Cancel()
			self.task = nil	
			self:Regen()
		end
	end
end

function Pickable:Resume()
	if self.paused then
		self.paused = false
		if not (self.canbepicked or self:IsBarren()) then
		
			if self.pause_time then
				if  TheWorld.state.isspring then self.pause_time = self.pause_time * TUNING.SPRING_GROWTH_MODIFIER end
				self.task = self.inst:DoTaskInTime(self.pause_time, OnRegen, "regen")
				self.targettime = GetTime() + self.pause_time
			else
				self:MakeEmpty()
			end
			
		end
	end
end

function Pickable:Pause()
	
	if self.paused == false then
		self.pause_time = nil
		self.paused = true
		
		if self.task then
			self.task:Cancel()
			self.task = nil	
		end
		
		if self.targettime then
			self.pause_time = math.max(0, self.targettime - GetTime())
		end
	end
end

function Pickable:GetDebugString()
	local time = GetTime()

    local str = ""
	if self.caninteractwith then
		str = str.. "caninteractwith "
    end
	if self.paused then
		str = str.. "paused "
		if self.pause_time then
			str = str.. string.format("%2.2f ", self.pause_time)
		end
    end
	if self.transplanted then
        if self.max_cycles and self.cycles_left then
            str = str.. string.format("transplated; cycles: %d/%d ", self.cycles_left, self.max_cycles)
        end
	else
		str = "Not transplanted "
    end
    if self.protected_cycles and self.protected_cycles > 0 then
        str = str.. string.format("protected cycles: %d ", self.protected_cycles)
    end
    if self.targettime and self.targettime > time then
        str = str.. string.format("Regen in: %.2f ", self.targettime - time)
    end
    return str
end

function Pickable:SetUp(product, regen, number)
    self.canbepicked = true
    self.product = product
    self.baseregentime = regen
    self.regentime = regen
    self.numtoharvest = number or 1
end

function Pickable:SetOnPickedFn(fn)
	self.onpickedfn = fn
end

function Pickable:SetOnRegenFn(fn)
	self.onregenfn = fn
end

function Pickable:SetMakeBarrenFn(fn)
	self.makebarrenfn = fn
end

function Pickable:SetMakeEmptyFn(fn)
	self.makeemptyfn = fn
end

function Pickable:CanBeFertilized()
    if self.fertilizable ~= false and self:IsBarren() then
		return true
	end
	if self.fertilizable ~= false and self.inst:HasTag("withered") then
		return true
	end
end

function Pickable:Fertilize(fertilizer, doer)
	if self.inst.components.burnable then
        self.inst.components.burnable:StopSmoldering()
    end

    if fertilizer.components.finiteuses then
        fertilizer.components.finiteuses:Use()
    else
        fertilizer.components.stackable:Get(1):Remove()
    end

	self.cycles_left = self.max_cycles

	if self.inst.components.witherable ~= nil then
        self.protected_cycles = (self.protected_cycles or 0) + fertilizer.components.fertilizer.withered_cycles
        if self.protected_cycles <= 0 then
            self.protected_cycles = nil
        end

        self.inst.components.witherable:Enable(self.protected_cycles == nil)
        if self.inst.components.witherable:IsWithered() then
            self.inst.components.witherable:ForceRejuvenate()
        else
            self:MakeEmpty()
        end
	else
		self:MakeEmpty()
	end	
	
end

function Pickable:OnSave()
	
	local data = { 
		protected_cycles = self.protected_cycles,
		picked = not self.canbepicked and true or nil, 
		transplanted = self.transplanted and true or nil,
		paused = self.paused and true or nil,
		caninteractwith = self.caninteractwith and true or nil,
		--pause_time = self.pause_time 
	}

	if self.cycles_left ~= self.max_cycles then
		data.cycles_left = self.cycles_left
		data.max_cycles = self.max_cycles 
	end
	
	if self.pause_time and self.pause_time > 0 then
		data.pause_time = self.pause_time
	end
	
	if self.targettime then
	    local time = GetTime()
		if self.targettime > time then
	        data.time = math.floor(self.targettime - time)
	    end
	end
	
    if next(data) then
		return data
	end
	
end

function Pickable:OnLoad(data)

	self.transplanted = data.transplanted or false
	
	self.cycles_left = data.cycles_left or self.cycles_left
	self.max_cycles = data.max_cycles or self.max_cycles
	
	if data.picked or data.time then
        if self:IsBarren() and self.makebarrenfn then
			self.makebarrenfn(self.inst, true)
        elseif self.makeemptyfn then
			self.makeemptyfn(self.inst)
		end
        self.canbepicked = false
	else
		if self.makefullfn then
			self.makefullfn(self.inst)
		end
		self.canbepicked = true
	end
    
    if data.caninteractwith then
    	self.caninteractwith = data.caninteractwith
    end

    if data.paused then
		self.paused = true
		self.pause_time = data.pause_time
    else
		if data.time then
			self.task = self.inst:DoTaskInTime(data.time, OnRegen, "regen")
			self.targettime = GetTime() + data.time
		end
	end    

    if data.makealwaysbarren == 1 and self.makebarrenfn ~= nil then
        self:MakeBarren()
    end

	self.protected_cycles = data.protected_cycles
    if self.protected_cycles ~= nil and self.protected_cycles <= 0 then
        self.protected_cycles = nil
    end
    if self.inst.components.witherable ~= nil then
        self.inst.components.witherable:Enable(self.protected_cycles == nil)
    end
end

function Pickable:IsBarren()
	return self.cycles_left == 0
end

function Pickable:CanBePicked()
    return self.canbepicked
end

function OnRegen(inst)
	if inst.components.pickable then
		inst.components.pickable:Regen()
	end
end

function Pickable:Regen()
    self.canbepicked = true
    if self.onregenfn then
        self.onregenfn(self.inst)
    end
    if self.makefullfn then
    	self.makefullfn(self.inst)
    end
    self.targettime = nil
    self.task = nil
end

function Pickable:MakeBarren()
    self.cycles_left = 0

    local wasempty = not self.canbepicked
    self.canbepicked = false

    if self.task ~= nil then
        self.task:Cancel()
    end

    if self.makebarrenfn ~= nil then
        self.makebarrenfn(self.inst, wasempty)
    end
end

function Pickable:OnTransplant()
	self.transplanted = true
	
	if self.ontransplantfn then
		self.ontransplantfn(self.inst)
	end
end

function Pickable:MakeEmpty()

    if self.task then
		self.task:Cancel()
    end
    
	if self.makeemptyfn then
		self.makeemptyfn(self.inst)
	end

    self.canbepicked = false
    
	if not self.paused then
		if self.baseregentime then
			local time = self.baseregentime
			
			if self.getregentimefn then
				time = self.getregentimefn(self.inst)
			end
			
			if TheWorld.state.isspring then time = time * TUNING.SPRING_GROWTH_MODIFIER end
			self.task = self.inst:DoTaskInTime(time, OnRegen, "regen")
			self.targettime = GetTime() + time
		end
	end
	
end

local function UpdateMoisture(item)
	if item.components.moisturelistener then 
		item.components.moisturelistener.moisture = item.target_moisture
		item.target_moisture = nil
		item.components.moisturelistener:DoUpdate()
	end
end

function Pickable:Pick(picker)
    
    if self.canbepicked and self.caninteractwith then

        if self.transplanted and self.cycles_left ~= nil then
            self.cycles_left = math.max(0, self.cycles_left - 1)
        end

        if self.protected_cycles ~= nil then
            self.protected_cycles = self.protected_cycles - 1
            if self.protected_cycles < 0 then
                self.protected_cycles = nil
                if self.inst.components.witherable ~= nil then
                    self.inst.components.witherable:Enable(true)
                end
            end
        end

		local loot = nil
        if picker and picker.components.inventory and self.product then
            loot = SpawnPrefab(self.product)

            if loot then
				loot.target_moisture = self.inst:GetCurrentMoisture()
				loot:DoTaskInTime(2*FRAMES, UpdateMoisture)

	            if self.numtoharvest > 1 and loot.components.stackable then
	            	loot.components.stackable:SetStackSize(self.numtoharvest)
	            end
		        picker:PushEvent("picksomething", {object = self.inst, loot= loot})
                picker.components.inventory:GiveItem(loot, nil, self.inst:GetPosition())
            end
        end
        
        if self.onpickedfn then
            self.onpickedfn(self.inst, picker, loot)
        end

        self.canbepicked = false

        if not self.paused and not self.inst:HasTag("withered") and self.baseregentime and not self:IsBarren() then
            if TheWorld.state.isspring then
                self.regentime = self.baseregentime * TUNING.SPRING_GROWTH_MODIFIER
            end

            self.task = self.inst:DoTaskInTime(self.regentime, OnRegen, "regen")
            self.targettime = GetTime() + self.regentime
        end

        self.inst:PushEvent("picked", {picker = picker, loot = loot, plant = self.inst})
    end
end

return Pickable