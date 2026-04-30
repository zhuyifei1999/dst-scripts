local ContainerTransform = Class(function(self, inst)
	self.inst = inst
	self.cantransform = nil
	self.ontransform = nil
end)

function ContainerTransform:SetCanTransform(fn)
	self.cantransform = fn or nil
end

function ContainerTransform:SetOnTransform(fn)
	self.ontransform = fn or nil
end

function ContainerTransform:IsTryingToOpenMe(inst)
	local target
    local act = inst:GetBufferedAction()
	if act then
		target = act.target
		act = act.action
	elseif inst.components.playercontroller then
		act, target = inst.components.playercontroller:GetRemoteInteraction()
	end
	return target == self.inst and act == ACTIONS.RUMMAGE
end

------------------------------------------

function ContainerTransform:CanTransform(doer)
	local success, reason = FunctionOrValue(self.cantransform, self.inst, doer)
	return success, reason
end

function ContainerTransform:TryTransformToContainer()
	return self.ontransform ~= nil and self.ontransform(self.inst)
end

return ContainerTransform