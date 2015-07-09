local Placer = Class(function(self, inst)
    self.inst = inst
    self.can_build = false
    self.testfn = nil
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
            self.inst.Transform:SetPosition(TheWorld.Map:GetTileCenterPoint(pt:Get()))
        elseif self.snap_to_meters then
            self.inst.Transform:SetPosition(math.floor(pt.x) + .5, 0, math.floor(pt.z) + .5)
        else
            self.inst.Transform:SetPosition(pt:Get())
        end
    elseif self.snap_to_tile then
        --Using an offset in this causes a bug in the terraformer functionality while using a controller.
        self.inst.Transform:SetPosition(TheWorld.Map:GetTileCenterPoint(ThePlayer.entity:LocalToWorldSpace(0, 0, 0)))
    elseif self.snap_to_meters then
        local x, y, z = ThePlayer.entity:LocalToWorldSpace(1, 0, 0)
        self.inst.Transform:SetPosition(math.floor(x) + .5, 0, math.floor(z) + .5)
    elseif self.inst.parent == nil then
        ThePlayer:AddChild(self.inst)
        self.inst.Transform:SetPosition(1, 0, 0)
    end

    if self.fixedcameraoffset ~= nil then
        self.inst.Transform:SetRotation(self.fixedcameraoffset - TheCamera:GetHeading()) -- rotate against the camera
    end

    self.can_build = self.testfn == nil or self.testfn(self.inst:GetPosition())

    --self.inst.AnimState:SetMultColour(0, 0, 0, .5)

    if self.can_build then
        self.inst.AnimState:SetAddColour(.25, .75, .25, 0)
    else
        self.inst.AnimState:SetAddColour(.75, .25, .25, 0)
    end
end

return Placer
