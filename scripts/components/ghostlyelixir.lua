
local GhostlyElixir = Class(function(self, inst)
    self.inst = inst

    self.inst:AddTag("ghostlyelixir")
end)

function GhostlyElixir:Apply(doer, target)
	target = target.components.ghostlyelixirable:GetApplyToTarget(doer, self.inst)

	if target ~= nil and self.doapplyelixerfn ~= nil and self.doapplyelixerfn(self.inst, doer, target) then
		if self.inst.components.stackable ~= nil then
			self.inst.components.stackable:Get():Remove()
		else
			self.inst:Remove()
		end
		return true
	end

	return false
end

function GhostlyElixir:OnRemoveFromEntity()
    self.inst:RemoveTag("ghostlyelixir")
end

return GhostlyElixir
