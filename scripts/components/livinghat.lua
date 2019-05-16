local LivingHat = Class(function(self, inst)
    self.inst = inst    
    self.inst:StartUpdatingComponent(self)
end)

function LivingHat:SetHead(head)
	self.head = head

	self.inst.Follower:FollowSymbol(head.GUID, "swap_hat", -1, -126, -1)

	self.inst:DoPeriodicTask(4, function(inst) self:PlayTongueAttack() end)
end

function LivingHat:OnUpdate(dt)
	if self.head == nil or not self.head:IsValid() then return end

    self.inst.Transform:SetRotation(self.head.Transform:GetRotation())
end

function LivingHat:PlayTongueAttack()
	self.inst.AnimState:PlayAnimation("steal")
	self.inst.AnimState:PushAnimation("idle", true)
end

return LivingHat
