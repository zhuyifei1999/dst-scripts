local function oninactive(self, inactive)
    if inactive then
        self.inst:AddTag("inactive")
    else
        self.inst:RemoveTag("inactive")
    end
end

local function onquickaction(self, quickaction)
    if quickaction then
        self.inst:AddTag("quickactivation")
    else
        self.inst:RemoveTag("quickactivation")
    end
end

local Activatable = Class(function(self, inst, activcb)
    self.inst = inst
    self.OnActivate = activcb
    self.inactive = true
	self.quickaction = false
end,
nil,
{
    inactive = oninactive,
    quickaction = onquickaction,
})

function Activatable:OnRemoveFromEntity()
    self.inst:RemoveTag("inactive")
    self.inst:RemoveTag("quickactivation")
end

function Activatable:CanActivate(doer)
    if self.CanActivateFn then
        return self.CanActivateFn(self.inst, doer)
    end

    return true
end

function Activatable:DoActivate(doer)
	if self.OnActivate ~= nil then
        self.inactive = false
		self.OnActivate(self.inst, doer)
	end
end

return Activatable