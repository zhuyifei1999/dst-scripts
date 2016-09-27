--this is called back by the engine side

PhysicsCollisionCallbacks = {}
function OnPhysicsCollision(guid1, guid2)
	local i1 = Ents[guid1]
	local i2 = Ents[guid2]

	if PhysicsCollisionCallbacks[guid1] then
		PhysicsCollisionCallbacks[guid1](i1, i2)
	end

	if PhysicsCollisionCallbacks[guid2] then
		PhysicsCollisionCallbacks[guid2](i2, i1)
	end

end

function Launch(inst, launcher, basespeed)
    if inst and inst.Physics and launcher then
        local x, y, z = inst:GetPosition():Get()
        y = .1
        inst.Physics:Teleport(x,y,z)

        local hp = inst:GetPosition()
        local pt = launcher:GetPosition()
        local vel = (hp - pt):GetNormalized()     
        local speed = (basespeed or 5) + (math.random() * 2)
        local angle = math.atan2(vel.z, vel.x) + (math.random() * 20 - 10) * DEGREES
        inst.Physics:SetVel(math.cos(angle) * speed, 10, math.sin(angle) * speed)
    end
end