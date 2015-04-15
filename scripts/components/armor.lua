local function PercentChanged(inst, data)
    if inst.components.armor
       and data.percent and data.percent <= 0
       and inst.components.inventoryitem and inst.components.inventoryitem.owner then
        inst.components.inventoryitem.owner:PushEvent("armorbroke", {armor = inst})
        --ProfileStatsSet("armor_broke_" .. inst.prefab, true)
    end
end

local Armor = Class(function(self, inst)
    self.inst = inst
    self.condition = 100
    self.maxcondition = 100
    self.tags = nil
    self.inst:ListenForEvent("percentusedchange", PercentChanged)
end)

function Armor:InitCondition(amount, absorb_percent)
    self.condition = amount
	self.absorb_percent = absorb_percent
    self.maxcondition = amount
end

function Armor:GetPercent(amount)
    return self.condition / self.maxcondition
end


function Armor:SetTags(tags)
    self.tags = tags
end

function Armor:SetAbsorption(absorb_percent)
    self.absorb_percent = absorb_percent
end

function Armor:SetPercent(amount)
    self:SetCondition(self.maxcondition * amount)
end

function Armor:SetCondition(amount)
    self.condition = math.min( amount, self.maxcondition )
    self.inst:PushEvent("percentusedchange", {percent = self:GetPercent()})   
    
    if self.condition <= 0 then
        self.condition = 0
        ProfileStatsSet("armor_broke_" .. self.inst.prefab, true)
        ProfileStatsSet("armor", self.inst.prefab)
        
        if METRICS_ENABLED then
			FightStat_BrokenArmor(self.inst.prefab)
		end
		
        if self.onfinished then
            self.onfinished()
        end
        
        self.inst:Remove()
    end
end

function Armor:OnSave()
    if self.condition ~= self.maxcondition then
        return {condition = self.condition}
    end
end

function Armor:OnLoad(data)
    if data.condition then
        self:SetCondition(data.condition)
    end
end

function Armor:CanResist(attacker, weapon)
    if attacker and self.tags then
	    for k,v in pairs(self.tags) do
		    if attacker:HasTag(v) then
			    return true
		    end
		    if weapon and weapon:HasTag(v) then
			    return true
		    end
	    end
	    return false
	else
	    return self.tags == nil
	end
end

function Armor:GetAbsorption(attacker, weapon)
    if self:CanResist(attacker, weapon) then
        return self.absorb_percent
    end
    return nil
end

function Armor:TakeDamage(damage_amount)
    self:SetCondition(self.condition - damage_amount)
    if self.ontakedamage then
        self.ontakedamage(self.inst, damage_amount)
    end
end

return Armor
