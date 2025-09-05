require("behaviours/wander")

-- This controller determines which head segment should reign control, and then lets their brain handle things.

local ShadowThrallCentipedeControllerBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

local UPDATE_RATE = 3
function ShadowThrallCentipedeControllerBrain:OnStart()
    local centipedebody = self.inst.components.centipedebody

	local root = PriorityNode({
        ConditionNode(function()
            local controller_head = nil
            local priority = self.inst.PRIORITY_BEHAVIOURS.WANDERING
            for i, head in ipairs(centipedebody.heads) do
                if head.control_priority > priority then
                    priority = head.control_priority
                    controller_head = head
                end
            end

            if controller_head
                and controller_head ~= centipedebody.head_in_control then
                centipedebody:GiveControlToHead(controller_head)
                return true
            end

            return false
		end)
	}, UPDATE_RATE)

	self.bt = BT(self.inst, root)
end

return ShadowThrallCentipedeControllerBrain