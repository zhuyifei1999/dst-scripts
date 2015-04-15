local function clearfoodprefs(self, foodprefs)
    for i, v in ipairs(foodprefs) do
        self.inst:RemoveTag((type(v) == "table" and v.name or v).."_eater")
    end
end

local function onfoodprefs(self, foodprefs, old_foodprefs)
    if old_foodprefs ~= nil then
        clearfoodprefs(self, old_foodprefs)
    end
    if foodprefs ~= nil then
        for i, v in ipairs(foodprefs) do
            self.inst:AddTag((type(v) == "table" and v.name or v).."_eater")
        end
    end
end

local Eater = Class(function(self, inst)
    self.inst = inst
    self.eater = false
    self.strongstomach = false
    self.foodprefs = nil
    self:SetOmnivore()
    self.oneatfn = nil
    self.lasteattime = nil
    self.ignoresspoilage = false
end,
nil,
{
    foodprefs = onfoodprefs,
})

function Eater:OnRemoveFromEntity()
    clearfoodprefs(self, self.foodprefs)
end

function Eater:SetVegetarian()
    self.foodprefs = { FOODTYPE.VEGGIE }
end

function Eater:SetCarnivore()
    self.foodprefs = { FOODTYPE.MEAT }
end

function Eater:SetInsectivore()
    self.foodprefs = { FOODTYPE.INSECT }
end

function Eater:SetBird()
    self.foodprefs = { FOODTYPE.SEEDS }
end

function Eater:SetSmallBird()
    self.foodprefs = { FOODGROUP.BERRIES_AND_SEEDS }
end

function Eater:SetBeaver()
    self.foodprefs = { FOODTYPE.WOOD }
end

function Eater:SetElemental()
    self.foodprefs = { FOODTYPE.ELEMENTAL }
end

function Eater:TimeSinceLastEating()
	if self.lasteattime then
		return GetTime() - self.lasteattime
	end
end

function Eater:OnSave()
    if self.lasteattime then
        return {time_since_eat = self:TimeSinceLastEating()}
    end
end

function Eater:OnLoad(data)
    if data.time_since_eat then
        self.lasteattime = GetTime() - data.time_since_eat
    end
end

function Eater:SetCanEatHorrible()
	table.insert(self.foodprefs, FOODTYPE.HORRIBLE)
    self.inst:AddTag(FOODTYPE.HORRIBLE.."_eater")
end

function Eater:SetCanEatGears()
    table.insert(self.foodprefs, FOODTYPE.GEARS)
    self.inst:AddTag(FOODTYPE.GEARS.."_eater")
end

function Eater:SetOmnivore()
    self.foodprefs = { FOODGROUP.OMNI }
end

function Eater:SetOnEatFn(fn)
    self.oneatfn = fn
end

function Eater:Eat(food)
    if self:CanEat(food) then
		
        if self.inst.components.health then
			local healthvalue = food.components.edible:GetHealth(self.inst)
			if healthvalue > 0 or not self.strongstomach then
				self.inst.components.health:DoDelta(healthvalue, nil, food.prefab)
			end
        end

        if self.inst.components.hunger then
            self.inst.components.hunger:DoDelta(food.components.edible:GetHunger(self.inst))
        end
        
        if self.inst.components.sanity then
			self.inst.components.sanity:DoDelta(food.components.edible:GetSanity(self.inst))
        end
        
        self.inst:PushEvent("oneat", {food = food})
        if self.oneatfn then
            self.oneatfn(self.inst, food)
        end
        
        if food.components.edible then
            food.components.edible:OnEaten(self.inst)
        end
        
        if food.components.stackable and food.components.stackable.stacksize > 1 then
            food.components.stackable:Get():Remove()
        else
            food:Remove()
        end
        
        self.lasteattime = GetTime()
        
        self.inst:PushEvent("oneatsomething", {food = food})
        
        return true
    end
end

function Eater:CanEat(inst)
    if inst ~= nil and inst.components.edible ~= nil then
        for i, v in ipairs(self.foodprefs) do
            if type(v) == "table" then
                for i2, v2 in ipairs(v.types) do
                    if inst:HasTag("edible_"..v2) then
                        return true
                    end
                end
            elseif inst:HasTag("edible_"..v) then
                return true
            end
        end
    end
end

return Eater