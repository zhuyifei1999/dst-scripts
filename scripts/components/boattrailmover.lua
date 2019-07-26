local BoatTrailMover = Class(function(self, inst)
    self.inst = inst

    self.inst:StartUpdatingComponent(self)
    self.track_boat_time = 0.4
end)

function BoatTrailMover:UpdateDir(dir_x, dir_z)
	self.dir_x = -dir_x
	self.dir_z = -dir_z
    local rudder_angle = VecUtil_GetAngleInDegrees(dir_x, dir_z)

    self.inst.Transform:SetRotation(-rudder_angle + 90)        
end

function BoatTrailMover:OnUpdate(dt)
	self.track_boat_time = self.track_boat_time - dt
    
    --[[
	local boat = self.boat
	if self.track_boat_time > 0 and boat:IsValid() then
		self:UpdateDir(self.boat.components.boattrail:GetDir())
	end
    ]]

    self.velocity = self.velocity + dt * self.acceleration

    local x, y, z = self.inst.Transform:GetWorldPosition()
    x = x + self.dir_x * self.velocity * dt
    z = z + self.dir_z * self.velocity * dt

    self.inst.Transform:SetPosition(x, y, z)
end

return BoatTrailMover