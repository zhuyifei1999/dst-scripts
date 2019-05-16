local SteeringWheel = Class(function(self, inst)
    self.inst = inst

    self.inst:AddTag("steeringwheel")
    --TODO(YOG): Properly destroy items on the boat
    self.inst:ListenForEvent("onsink", function(inst) inst:Remove() end)
end)

function SteeringWheel:StartSteering(sailor)
	self.sailor = sailor
	sailor.components.steeringwheeluser:SetSteeringWheel(self.inst)
	sailor:AddTag("steeringboat")
	self.inst:AddTag("occupied")
end

function SteeringWheel:StopSteering(sailor)
	sailor:RemoveTag("steeringboat")
	self.inst:RemoveTag("occupied")
end

function SteeringWheel:OnRemoveFromEntity()
    if self.sailor ~= nil then
        self.sailor:RemoveTag("steeringboat")
    end
    self.inst:RemoveTag("occupied")
end

return SteeringWheel
