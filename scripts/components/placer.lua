local Placer = Class(function(self, inst)
    self.inst = inst
	self.can_build = false
	self.radius = 1
	self.selected_pos = nil
	self.inst:AddTag("NOCLICK")
end)

function Placer:SetBuilder(builder, recipe, invobject)
	self.builder = builder
	self.recipe = recipe
	self.invobject = invobject
	self.inst:StartUpdatingComponent(self)
end

function Placer:GetDeployAction()
	if self.invobject ~= nil then
		self.selected_pos = self.inst:GetPosition()
		local action = BufferedAction(self.builder, nil, ACTIONS.DEPLOY, self.invobject, self.selected_pos)
		table.insert(action.onsuccess, function() self.selected_pos = nil end)
		return action
	end
end

function Placer:OnUpdate(dt)
    if ThePlayer == nil then
        return
	elseif not TheInput:ControllerAttached() then
		local pt = self.selected_pos or Input:GetWorldPosition()
		if self.snap_to_tile then
			pt = Vector3(TheWorld.Map:GetTileCenterPoint(pt:Get()))
		elseif self.snap_to_meters then
			pt = Vector3(math.floor(pt.x)+.5, 0, math.floor(pt.z)+.5)
		end
		self.inst.Transform:SetPosition(pt:Get())	
	elseif self.snap_to_tile then
		--Using an offset in this causes a bug in the terraformer functionality while using a controller.
		local pt = Vector3(ThePlayer.entity:LocalToWorldSpace(0,0,0))
		pt = Vector3(TheWorld.Map:GetTileCenterPoint(pt:Get()))
		self.inst.Transform:SetPosition(pt:Get())
	elseif self.snap_to_meters then
		local pt = Vector3(ThePlayer.entity:LocalToWorldSpace(1,0,0))
		pt = Vector3(math.floor(pt.x)+.5, 0, math.floor(pt.z)+.5)
		self.inst.Transform:SetPosition(pt:Get())
	elseif self.inst.parent == nil then
		ThePlayer:AddChild(self.inst)
		self.inst.Transform:SetPosition(1,0,0)
	end

    if self.fixedcameraoffset then
        local rot = TheCamera:GetHeading()
        self.inst.Transform:SetRotation(-rot+self.fixedcameraoffset) -- rotate against the camera
    end

	self.can_build = self.testfn == nil or self.testfn(self.inst:GetPosition())

	--self.inst.AnimState:SetMultColour(0,0,0,.5)

	local color = self.can_build and Vector3(.25,.75,.25) or Vector3(.75,.25,.25)
	self.inst.AnimState:SetAddColour(color.x, color.y, color.z ,0)
end

return Placer
