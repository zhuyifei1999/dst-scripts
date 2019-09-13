local Preserver = Class(function(self, inst)
    self.inst = inst
	self.perish_rate_multiplier = 1
end,
nil)

function Preserver:SetPerishRateMultiplier(rate)
	self.perish_rate_multiplier = rate
end

function Preserver:GetPerishRateMultiplier()
	return self.perish_rate_multiplier
end

return Preserver