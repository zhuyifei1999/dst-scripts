require("behaviours/standstill")

local AlterGuardian_Phase4_LunarRiftBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

function AlterGuardian_Phase4_LunarRiftBrain:OnStart()
	local root = PriorityNode({
		StandStill(self.inst),
	}, 0.5)

	self.bt = BT(self.inst, root)
end

return AlterGuardian_Phase4_LunarRiftBrain
