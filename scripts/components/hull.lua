local Hull = Class(function(self, inst)
    self.inst = inst
end)

function Hull:FinishRemovingEntity(entity, constrain_to_boat)
    if entity:IsValid() then
        if constrain_to_boat then
            entity.Physics:ConstrainTo(nil) 
        end
        entity:Remove()
    end
end

function Hull:AttachEntityToBoat(obj, offset_x, offset_z, constrain_to_boat, parent_to_boat)
	obj:ListenForEvent("onremove", function() self:FinishRemovingEntity(obj, constrain_to_boat) end, self.inst)
    obj:ListenForEvent("onsink", function() self:FinishRemovingEntity(obj, constrain_to_boat) end, self.inst)

    self.inst:DoTaskInTime(0, function(boat)
    	local boat_x, boat_y, boat_z = boat.Transform:GetWorldPosition()
        obj.Transform:SetPosition(boat_x + offset_x, boat_y, boat_z + offset_z)
        if constrain_to_boat then
        	obj.Physics:ConstrainTo(self.inst.entity)
        end
        if parent_to_boat then
    		obj.entity:SetParent(self.inst.entity)
    		obj.Transform:SetPosition(offset_x, 0, offset_z)        	
        end
    end)    
end

--[[
function Hull:SetRudder(obj)
	self.rudder = obj;
	obj:ListenForEvent("onsink", function() obj:Remove() end, self.inst)
    self.inst:ListenForEvent("onremove", function(e) if e == self.rudder then self.rudder = nil end end, obj)  
	obj.entity:SetParent(self.inst.entity)
	obj.Transform:SetPosition(0,0,0)
    obj.AnimState:SetSortOrder(ANIM_SORT_ORDER.OCEAN_BOAT)
	obj.AnimState:SetFinalOffset(2)
end
]]--

function Hull:SetPlank(obj)
    self.plank = obj
end

function Hull:SetBoatLip(obj)
	self.boat_lip = obj;
	obj:ListenForEvent("onsink", function() obj:Remove() end, self.inst)
    self.inst:ListenForEvent("onremove", function(e) if e == self.boat_lip then self.boat_lip = nil end end, obj)  
	obj.entity:SetParent(self.inst.entity)
	obj.Transform:SetPosition(0,0,0)
    obj.AnimState:SetSortOrder(ANIM_SORT_ORDER.OCEAN_BOAT)
	obj.AnimState:SetFinalOffset(0)
end

function Hull:SetRadius(radius)
	self.radius = radius	
end

function Hull:OnDeployed()
	self.boat_lip.AnimState:PlayAnimation("place_lip")
	self.boat_lip.AnimState:PushAnimation("lip", true)
    self.plank:Hide()
    self.plank:DoTaskInTime(1.25, function() self.plank:Show() self.plank.AnimState:PlayAnimation("plank_place") end)    
end

return Hull
