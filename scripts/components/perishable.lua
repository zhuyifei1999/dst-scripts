local function onpercent(self)
    self.inst:RemoveTag("fresh")
    self.inst:RemoveTag("stale")
    self.inst:RemoveTag("spoiled")
    local percent = self:GetPercent()
    if percent >= .5 then
        self.inst:AddTag("fresh")
    elseif percent > .2 then
        self.inst:AddTag("stale")
    else
        self.inst:AddTag("spoiled")
    end
end

local Perishable = Class(function(self, inst)
    self.inst = inst
    self.perishfn = nil
    self.perishtime = nil
    
    self.targettime = nil
    self.perishremainingtime = nil
    self.updatetask = nil
    self.dt = nil
    self.onperishreplacement = nil
end,
nil,
{
    perishtime = onpercent,
    perishremainingtime = onpercent,
})

function Perishable:OnRemoveFromEntity()
    self.inst:RemoveTag("fresh")
    self.inst:RemoveTag("stale")
    self.inst:RemoveTag("spoiled")
end

local function Update(inst, dt)
    if inst.components.perishable then
		
		local modifier = 1
		local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner or nil
		if owner then
			if owner:HasTag("fridge") then
				modifier = TUNING.PERISH_FRIDGE_MULT 
			elseif owner:HasTag("spoiler") then
				modifier = TUNING.PERISH_GROUND_MULT 
			end
		else
			modifier = TUNING.PERISH_GROUND_MULT 
		end
		
		if TheWorld.state.temperature < 0 then
			modifier = modifier * TUNING.PERISH_WINTER_MULT
		end

		modifier = modifier * TUNING.PERISH_GLOBAL_MULT
		
		local old_val = inst.components.perishable.perishremainingtime
		inst.components.perishable.perishremainingtime = inst.components.perishable.perishremainingtime - dt*modifier
        if math.floor(old_val*100) ~= math.floor(inst.components.perishable.perishremainingtime*100) then
	        inst:PushEvent("perishchange", {percent = inst.components.perishable:GetPercent()})
	    end
        
        --trigger the next callback
        if inst.components.perishable.perishremainingtime <= 0 then
			inst.components.perishable:Perish()
        end
    end
end

function Perishable:IsFresh()
	return self.inst:HasTag("fresh")
end

function Perishable:IsStale()
	return self.inst:HasTag("stale")
end

function Perishable:IsSpoiled()
	return self.inst:HasTag("spoiled")
end

function Perishable:Dilute(number, timeleft)
	if self.inst.components.stackable then
		self.perishremainingtime = (self.inst.components.stackable.stacksize * self.perishremainingtime + number * timeleft) / ( number + self.inst.components.stackable.stacksize )
		self.inst:PushEvent("perishchange", {percent = self:GetPercent()})
	end
end

function Perishable:SetPerishTime(time)
	self.perishtime = time
	self.perishremainingtime = time
end

function Perishable:SetOnPerishFn(fn)
	self.perishfn = fn
end

function Perishable:GetPercent()
	if self.perishremainingtime and self.perishtime and self.perishtime > 0 then
		return math.min(1, self.perishremainingtime / self.perishtime)
	else
		return 0
	end
end

function Perishable:SetPercent(percent)
	if percent < 0 then percent = 0 end
	if percent > 1 then percent = 1 end
	self.perishremainingtime = percent*self.perishtime
end

function Perishable:ReducePercent(amount)
	local cur = self:GetPercent()
	self:SetPercent(cur - amount)
end

function Perishable:GetDebugString()
	if self.perishremainingtime and  self.perishremainingtime > 0 then
		return string.format("%s %2.2fs", self.updatetask and "Perishing" or "Paused", self.perishremainingtime)
	else
		return "perished"
	end
end

function Perishable:LongUpdate(dt)
	Update(self.inst, dt)
end

function Perishable:StartPerishing()
    
	if self.updatetask then
		self.updatetask:Cancel()
		self.updatetask = nil
	end

    local dt = 10 + math.random()*FRAMES*8--math.max( 4, math.min( self.perishtime / 100, 10)) + ( math.random()* FRAMES * 8)

    if dt > 0 then
        self.updatetask = self.inst:DoPeriodicTask(dt, Update, math.random()*2, dt)
    else
        Update(self.inst, 0)
    end
end

function Perishable:Perish()
    if self.updatetask ~= nil then
        self.updatetask:Cancel()
        self.updatetask = nil
    end

    if self.perishfn ~= nil then
        self.perishfn(self.inst)
    end

    if self.onperishreplacement ~= nil then
        local goop = SpawnPrefab(self.onperishreplacement)
        if goop ~= nil then
            if goop.components.stackable ~= nil and self.inst.components.stackable ~= nil then
                goop.components.stackable:SetStackSize(self.inst.components.stackable.stacksize)
            end
            local owner = self.inst.components.inventoryitem ~= nil and self.inst.components.inventoryitem.owner or nil
            local holder = owner ~= nil and (owner.components.inventory or owner.components.container) or nil
            if holder ~= nil then
                local slot = holder:GetItemSlot(self.inst)
                self.inst:Remove()
                holder:GiveItem(goop, slot)
            else
                local x, y, z = self.inst.Transform:GetWorldPosition()
                self.inst:Remove()
                goop.Transform:SetPosition(x, y, z)
            end
        end
    end
end

function Perishable:StopPerishing()
	if self.updatetask then
		self.updatetask:Cancel()
		self.updatetask = nil
	end
end

function Perishable:OnSave()
    local data = {}

    data.paused = self.updatetask == nil
    data.time = self.perishremainingtime

    return data
end   
      
function Perishable:OnLoad(data)

    if data and data.time then
		self.perishremainingtime = data.time
		if not data.paused then
			self:StartPerishing()
		end
    end
end

return Perishable