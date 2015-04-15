local BlinkStaff = Class(function(self, inst)
    self.inst = inst
    self.onblinkfn = nil
    self.blinkdistance_controller = 13 
end)

function BlinkStaff:GetBlinkPoint()
	--For use with controller.
	local owner = self.inst.components.inventoryitem.owner
	if not owner then return end
	local pt = nil
	local rotation = owner.Transform:GetRotation()*DEGREES
	local pos = owner:GetPosition()

	for r = self.blinkdistance_controller, 1, -1 do
        local numtries = 2*PI*r
		pt = FindWalkableOffset(pos, rotation, r, numtries)
		if pt then
			return pt + pos
		end
	end
end

function BlinkStaff:SpawnEffect(inst)
	SpawnPrefab("small_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
end

function BlinkStaff:Blink(pt, caster)
	if not TheWorld.Map:IsAboveGroundAtPoint(pt:Get()) then
		return false
	end

	self:SpawnEffect(caster)
	caster.SoundEmitter:PlaySound("dontstarve/common/staff_blink")
	caster:Hide()
	if caster.components.health then
		caster.components.health:SetInvincible(true)
	end
	caster:DoTaskInTime(0.25, function() 
		if caster.components.health then
			caster.components.health:SetInvincible(false)
		end
		caster.Physics:Teleport(pt:Get())
		self:SpawnEffect(caster)
		caster:Show()
		caster.SoundEmitter:PlaySound("dontstarve/common/staff_blink")
		end)
	
	if self.onblinkfn then
		self.onblinkfn(self.inst, pt, caster)
	end
	return true
end

return BlinkStaff
