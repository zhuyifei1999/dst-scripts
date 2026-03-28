local function oninuse(self, inuse)
	self.inst:AddOrRemoveTag("equipped_and_inuse", inuse)
end

local UseableEquippedItem = Class(function(self, inst)
	self.inst = inst
	self.inuse = false
	self.onusefn = nil
	self.onstopusefn = nil
end,
nil,
{
	inuse = oninuse,
})

function UseableEquippedItem:OnRemoveFromEntity()
	self.inst:RemoveTag("equipped_and_inuse")
end

function UseableEquippedItem:SetOnUseFn(fn)
	self.onusefn = fn
end

function UseableEquippedItem:SetOnStopUseFn(fn)
	self.onstopusefn = fn
end

function UseableEquippedItem:IsInUse()
	return self.inuse
end

function UseableEquippedItem:StartUsingItem(doer)
	if self.inuse then
		return false
	end

	self.inuse = true

    if self.onusefn then
        local success, reason = self.onusefn(self.inst, doer)
        if not success and success ~= nil then -- Fail state backwards compatible needs to check for nil.
            self.inuse = false
            return false, reason
        end
    end
	return true
end

function UseableEquippedItem:StopUsingItem(doer)
	if not self.inuse then
		return
	end

	self.inuse = false

	if self.onstopusefn then
		self.onstopusefn(self.inst, doer)
	end
end

return UseableEquippedItem
