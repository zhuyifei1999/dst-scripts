local Haunter = Class(function(self, inst)
    self.inst = inst
end)

function Haunter:OnHaunt(target, val)
	-- This is mostly meaningless right now, ripped from kramped
	-- We probably want different haunt_vals for different classes of entities and possibly also for different haunt outcomes (i.e. more humanity for more ignite)
	local haunt_val = val
	if not haunt_val and target then

		-- Backup ways to calculate haunt value. Not intended to be all-encompassing.
		-- Just want to catch some common cases (creatures of various sizes, inv items, etc)
		if target:HasTag("smallcreature") then
			haunt_val = TUNING.HAUNT_TINY
		elseif target:HasTag("prey") then
			haunt_val = TUNING.HAUNT_TINY
		elseif target:HasTag("scarytoprey") then
			haunt_val = TUNING.HAUNT_SMALL
		elseif target.components.inventoryitem then
			haunt_val = TUNING.HAUNT_TINY
		else -- catch all
			haunt_val = TUNING.HAUNT_TINY
		end

	end

	-- Only resurrectors increase humanity
	if haunt_val and self.inst.components.humanity and target and target:HasTag("resurrector") then
		self.inst.components.humanity:DoDelta(haunt_val, target)
	elseif haunt_val and self.inst.components.humanity then
		self.inst.components.humanity:DoPause(haunt_val, target)
	end
end

return Haunter
