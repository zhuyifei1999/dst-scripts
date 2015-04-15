local ComplexProjectile = Class(function(self, inst)
	self.inst = inst

	self.velocity = Vector3(0,0,0)
	self.gravity = -9.81

	self.horizontalSpeed = 4
	self.launchoffset = nil
	self.targetoffset = nil

	self.owningweapon = nil
	self.attacker = nil

	self.onlaunchfn = nil
	self.onhitfn = nil
	self.onmissfn = nil

end)

function ComplexProjectile:GetDebugString()
	return tostring(self.velocity)
end

function ComplexProjectile:SetHorizontalSpeed(speed)
	self.horizontalSpeed = speed
end

function ComplexProjectile:SetLaunchOffset(offset)
    self.launchoffset = offset -- x is facing, y is height, z is ignored
end

function ComplexProjectile:SetTargetOffset(offset)
    self.targetoffset = offset -- x is ignored, y is height, z is ignored
end

function ComplexProjectile:SetOnLaunch(fn)
	self.onlaunchfn = fn
end

function ComplexProjectile:SetOnHit(fn)
	self.onhitfn = fn
end

function ComplexProjectile:CalculateTrajectory(startPos, endPos, speed)
	local speedSq = speed * speed;
	local speed4th = speedSq * speedSq;
	local g = -self.gravity

	local dx = math.sqrt((endPos.x-startPos.x)*(endPos.x-startPos.x) + (endPos.z-startPos.z)*(endPos.z-startPos.z));
	local dy = endPos.y - startPos.y;

	local discriminant = speed4th - g*(g*dx*dx + 2*dy*speedSq);
	local angle;
	if discriminant >= 0.0 then
		angle = math.atan( ( speedSq - math.sqrt( discriminant ) ) / ( g * dx ) )
	else
		angle = 30.0*DEGREES
	end
	local result = Vector3(endPos.x-startPos.x, 0.0, endPos.z-startPos.z):GetNormalized();
	result = result * math.cos( angle ) * speed;
	result.y = math.sin( angle ) * speed;

	return result;
end

function ComplexProjectile:Launch(targetPos, attacker, owningweapon)
	local pos = self.inst:GetPosition()
	self.owningweapon = owningweapon
	self.attacker = attacker

    local offset = self.launchoffset
    if attacker and offset then
        local facing_angle = attacker.Transform:GetRotation()*DEGREES
        local offset_vec = Vector3(offset.x * math.cos( facing_angle ), offset.y, -offset.x * math.sin( facing_angle ))
        -- print("facing", facing_angle)
        -- print("offset", offset)
        -- print("vec", offset_vec)
        pos = pos + offset_vec
        self.inst.Transform:SetPosition( pos:Get() )
    end

    if self.targetoffset then
	    targetPos.y = self.targetoffset.y
	else
		-- hit when you hit the ground
		targetPos.y = 0
	end

	self.velocity = self:CalculateTrajectory(pos, targetPos, self.horizontalSpeed)

	if self.onlaunchfn then
		self.onlaunchfn(self.inst)
	end

	self.inst:StartUpdatingComponent(self)
end

function ComplexProjectile:Hit(target)
	self.inst:StopUpdatingComponent(self)

	self.inst.Physics:SetMotorVel(0,0,0)
	self.inst.Physics:Stop()
	self.velocity = Vector3(0,0,0)

	if self.onhitfn then
		self.onhitfn(self.inst, self.attacker, target)
	end
end

function ComplexProjectile:OnUpdate(dt)
	self.inst.Physics:SetMotorVel(self.velocity.x, self.velocity.y, self.velocity.z)
	self.velocity.y = self.velocity.y + (self.gravity * dt)
	local pos = self.inst:GetPosition()
	if pos.y <= 0.05 and self.velocity.y < 0 then -- a tiny bit above the ground, to account for collision issues
		self:Hit()
	end
end

return ComplexProjectile