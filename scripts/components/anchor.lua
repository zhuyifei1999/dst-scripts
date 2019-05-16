local function on_is_anchor_lowered(self, is_anchor_lowered)
	if is_anchor_lowered then					
		self.inst:RemoveTag("anchor_raised")
		self.inst:AddTag("anchor_lowered")				
	else			
		self.inst:RemoveTag("anchor_lowered")
		self.inst:AddTag("anchor_raised")
	end
end

local Anchor = Class(function(self, inst)
    self.inst = inst
    self.is_anchor_lowered = false
end,
nil,
{	
    is_anchor_lowered = on_is_anchor_lowered,
})

function Anchor:GetBoat()
	local pos_x, pos_y, pos_z = self.inst.Transform:GetWorldPosition()
	return TheWorld.Map:GetPlatformAtPoint(pos_x, pos_z)
end

function Anchor:SetIsAnchorLowered(is_lowered)
	if is_lowered ~= self.is_anchor_lowered then
		self.is_anchor_lowered = is_lowered
		local boat = self:GetBoat()
		if boat ~= nil then
			if is_lowered then
				boat.components.boatphysics:IncrementLoweredAnchorCount()
			else
				boat.components.boatphysics:DecrementLoweredAnchorCount()
			end
		end
	end
end

function Anchor:StartRaisingAnchor()
	self.inst:PushEvent("raising_anchor")
end

function Anchor:StartLoweringAnchor()
	self.inst:PushEvent("lowering_anchor")
end

return Anchor
