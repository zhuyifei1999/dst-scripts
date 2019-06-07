local function on_is_anchor_lowered(self, is_anchor_lowered)
	if is_anchor_lowered then
		self.inst:RemoveTag("anchor_raised")
		self.inst:AddTag("anchor_lowered")
	else
		self.inst:RemoveTag("anchor_lowered")
		self.inst:AddTag("anchor_raised")
	end
end

local function on_remove(inst)
    local anchor = inst.components.anchor
    if anchor ~= nil then
        if anchor.is_anchor_lowered then
            local boat = anchor:GetBoat()
            if boat ~= nil and boat:IsValid() then
                boat.components.boatphysics:RemoveAnchorCmp(anchor)
            end
        end
        anchor.inst:RemoveEventCallback("onremove", on_remove)
    end
end

local Anchor = Class(function(self, inst)
    self.inst = inst
    self.inst:ListenForEvent("onremove", on_remove)

    self.is_anchor_lowered = false
    self.drag = TUNING.BOAT.ANCHOR_DRAG
end,
nil,
{
    is_anchor_lowered = on_is_anchor_lowered,
})

function Anchor:OnSave()
    local data =
    {
        is_anchor_lowered = self.is_anchor_lowered
    }

    return data
end

function Anchor:GetDrag()
	if self.inst:HasTag("burnt") then
		return 0
	else
		return self.drag
	end
end

function Anchor:OnLoad(data)
    if data ~= nil then
    	if data.is_anchor_lowered then
			self.inst:DoTaskInTime(0,
				function()
					if self:GetBoat() ~= nil then
						self.inst.sg:GoToState("lowered")
					else
						self.inst.sg:GoToState("lowered_land")
					end    							
				end)

    	end
    end
end

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
				boat.components.boatphysics:AddAnchorCmp(self)
			else
				boat.components.boatphysics:RemoveAnchorCmp(self)
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
