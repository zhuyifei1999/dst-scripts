local Sewing = Class(function(self, inst)
    self.inst = inst
    self.repair_value = 1
end)

function Sewing:DoSewing(target, doer)

    if target:HasTag("needssewing") then
		
		target.components.fueled:DoDelta(self.repair_value)

		if self.inst.components.finiteuses then
			self.inst.components.finiteuses:Use(1)
		end

		if self.onsewn then
			self.onsewn(self.inst, target, doer)
		end

		return true
	end

end

return Sewing