local SourceModifierList = require("util/sourcemodifierlist")

local EfficientUser = Class(function(self, inst)
    self.inst = inst
    self.actions = {}
end)

function EfficientUser:OnRemoveFromEntity()
	for _, v in pairs(self.actions) do
		v:Reset()
	end
end

function EfficientUser:GetMultiplier(action)
    return self.actions[action] and self.actions[action]:Get() or 1
end

function EfficientUser:AddMultiplier(action, multiplier, source)
    if not self.actions[action] then
        self.actions[action] = SourceModifierList(self.inst)
    end

    self.actions[action]:SetModifier(source, multiplier)

	if action == ACTIONS.MINE then
		self:AddMultiplier(ACTIONS.REMOVELUNARBUILDUP, multiplier, source)
	end
end

function EfficientUser:RemoveMultiplier(action, source)
    if self.actions[action] then
        self.actions[action]:RemoveModifier(source)
    end

	if action == ACTIONS.MINE then
		self:RemoveMultiplier(ACTIONS.REMOVELUNARBUILDUP, source)
	end
end

return EfficientUser
