local SourceModifierList = require("util/sourcemodifierlist")

local AoeDimishingReturns = Class(function(self, inst)
	self.inst = inst
	self.mult = SourceModifierList(inst)
end)

function AoeDimishingReturns:OnRemoveFromEntity()
	self.mult:Reset()
end

return AoeDimishingReturns
