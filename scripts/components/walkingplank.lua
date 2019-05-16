local WalkingPlank = Class(function(self, inst)
    self.inst = inst
    self.doer = nil
    self.stop_mounting_cb = function(inst) self:StopMounting() end
end)

function WalkingPlank:Extend()	
	self.inst:PushEvent("start_extending")
end

function WalkingPlank:Retract()
	self.inst:PushEvent("start_retracting")
end

function WalkingPlank:MountPlank(doer)
	self.doer = doer
	doer.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
	doer.Physics:ClearTransformationHistory()	
	self.inst:PushEvent("start_mounting")
	doer.components.walkingplankuser.current_plank = self.inst
end

function WalkingPlank:StopMounting()
	self.doer.components.walkingplankuser.current_plank = nil
	self.inst:PushEvent("stop_mounting")
end

function WalkingPlank:AbandonShip(doer)
	self.doer.components.walkingplankuser.current_plank = nil
	self.inst:PushEvent("start_abandoning")
end

return WalkingPlank
