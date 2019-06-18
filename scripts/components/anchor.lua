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

function Anchor:GetDrag()
    return (self.inst:HasTag("burnt") and 0) or self.drag
end

function Anchor:OnSave()
    local data =
    {
        is_anchor_lowered = self.is_anchor_lowered
    }

    return data
end

function Anchor:OnLoad(data)
    if data ~= nil then
    	if data.is_anchor_lowered then
			self.inst:DoTaskInTime(0,
				function(i)
                    -- If our prefab loaded burnt, it removed its anchor component,
                    -- so we should not try to go to any anchor stategraph states.
                    if not i:HasTag("burnt") then
					    if self:GetBoat() ~= nil then
						    i.sg:GoToState("lowered")
					    else
						    i.sg:GoToState("lowered_land")
					    end
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
    if self.inst:HasTag("burnt") or self.inst:HasTag("anchor_raised") then
        return false
    else
	    self.inst:PushEvent("raising_anchor")
        return true
    end
end

function Anchor:StartLoweringAnchor()
    if self.inst:HasTag("burnt") or self.inst:HasTag("anchor_lowered") then
        return false
    else
	    self.inst:PushEvent("lowering_anchor")
        return true
    end
end

return Anchor
