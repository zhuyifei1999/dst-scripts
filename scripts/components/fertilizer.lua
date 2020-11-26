local function onplanthealth(self, planthealth)
    if planthealth ~= nil then
        self.inst:AddTag("heal_fertilize")
    else
        self.inst:RemoveTag("heal_fertilize")
    end
end

local Fertilizer = Class(function(self, inst)
    self.inst = inst
    self.fertilizervalue = 1
    self.soil_cycles = 1
    self.withered_cycles = 1
    self.fertilize_sound = "dontstarve/common/fertilize"

    self.nutrients = { 0, 0, 0 }

    --For healing plant characters (e.g. Wormwood)
    --self.planthealth = nil
end,
nil,
{
    planthealth = onplanthealth,
})

function Fertilizer:OnRemoveFromEntity()
    self.inst:RemoveTag("heal_fertilize")
end

function Fertilizer:SetHealingAmount(health)
    self.planthealth = health
end

function Fertilizer:SetNutrients(nutrient1, nutrient2, nutrient3)
    if type(nutrient1) == "table" then
        self.nutrients = nutrient1
    else
        self.nutrients = { nutrient1, nutrient2, nutrient3 }
    end
end

function Fertilizer:OnApplied(doer, target)
	local final_use = true
	if self.inst.components.finiteuses ~= nil then
		self.inst.components.finiteuses:Use()
		final_use = self.inst.components.finiteuses:GetUses() <= 0
	end

	if self.onappliedfn ~= nil then
		self.onappliedfn(self.inst, final_use, doer, target)
	end

	if final_use then
		if self.inst.components.stackable ~= nil then
			self.inst.components.stackable:Get():Remove()
		else
			self.inst:Remove()
		end
	end
end

function Fertilizer:Heal(target)
    if self.planthealth ~= nil and target.components.health ~= nil and target.components.health.canheal and target:HasTag("healonfertilize") then
        if self.inst.components.finiteuses ~= nil then
            target.components.health:DoDelta(self.planthealth, false, self.inst.prefab)
        else
            target.components.health:DoDelta(self.planthealth, false, self.inst.prefab)
        end
        return true
    end
end

return Fertilizer
