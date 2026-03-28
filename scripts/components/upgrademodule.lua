local UpgradeModule = Class(function(self, inst)
    self.inst = inst
    self.slots = 1
    self.type = CIRCUIT_BARS.ALPHA
    self.activated = false

    --self.target = nil
    --self.onactivatedfn = nil
    --self.ondeactivatedfn = nil
	--self.onaddedtoownerfn = nil
    --self.onremovedfromownerfn = nil
end)

function UpgradeModule:SetRequiredSlots(slots)
    self.slots = slots
end

function UpgradeModule:GetSlots()
    return self.slots
end

function UpgradeModule:SetTarget(target, isloading)
    self.target = target
	if target and self.onaddedtoownerfn then
		self.onaddedtoownerfn(self.inst, target, isloading)
	end
end

function UpgradeModule:SetType(bartype)
    self.type = bartype
end

function UpgradeModule:GetType()
    return self.type
end

--Should only be called by the upgrademoduleowner component
function UpgradeModule:TryActivate(isloading)
    if not self.activated then
        self.activated = true

        if self.onactivatedfn ~= nil then
            self.onactivatedfn(self.inst, self.target, isloading)
        end
    end
end

--Should only be called by the upgrademoduleowner component
function UpgradeModule:TryDeactivate()
    if self.activated then
        self.activated = false

        if self.ondeactivatedfn ~= nil then
            self.ondeactivatedfn(self.inst, self.target)
        end
    end
end

function UpgradeModule:RemoveFromOwner()
    local owner = self.target
    self:SetTarget(nil)

    if self.onremovedfromownerfn ~= nil then
        self.onremovedfromownerfn(self.inst, owner)
    end
end

return UpgradeModule
