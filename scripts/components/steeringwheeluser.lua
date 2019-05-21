local SteeringWheelUser = Class(function(self, inst)
    self.inst = inst
    self.should_play_left_turn_anim = false

    self.inst:StartUpdatingComponent(self)

    self.inst:ListenForEvent("onsink", function() self:OnSink() end)

    self.wheel_remove_callback = function(wheel)
        if self.steering_wheel == wheel then
            self.steering_wheel.components.steeringwheel:StopSteering(self.inst)
            self.inst:PushEvent("stop_steering_boat")
            self.steering_wheel = nil
        end
    end
end)

function SteeringWheelUser:OnSink()
	self:SetSteeringWheel(nil)
end

function SteeringWheelUser:SetSteeringWheel(steering_wheel)
	if self.steering_wheel ~= nil then
		self.steering_wheel.components.steeringwheel:StopSteering(self.inst)

    	self.steering_wheel.AnimState:ShowSymbol("boat_wheel_round")
    	self.steering_wheel.AnimState:ShowSymbol("boat_wheel_stick")

        self.inst:RemoveEventCallback("onremove", self.wheel_remove_callback, steering_wheel)
	end
	if steering_wheel ~= nil then
		self.inst.Transform:SetPosition(steering_wheel.Transform:GetWorldPosition())
		self.inst.Physics:ClearTransformationHistory()

    	steering_wheel.AnimState:HideSymbol("boat_wheel_round")
    	steering_wheel.AnimState:HideSymbol("boat_wheel_stick")

        self.inst:ListenForEvent("onremove", self.wheel_remove_callback, steering_wheel)
	else
		self.inst:PushEvent("steer_boat_stop_turning")
	end

	self.steering_wheel = steering_wheel
end

function SteeringWheelUser:Steer(pos_x, pos_z)
	--TODO(YOG): Don't search for the boat
	local boat = self:GetBoat()
	if boat == nil then return end

	local boat_pos_x, boat_pos_y, boat_pos_z = boat.Transform:GetWorldPosition()

	local dir_x, dir_z = VecUtil_Normalize(pos_x - boat_pos_x, pos_z - boat_pos_z)

	self:SteerInDir(dir_x, dir_z)
end

function SteeringWheelUser:SteerInDir(dir_x, dir_z)
	local boat = self:GetBoat()
	if boat == nil then return end

	local right_vec = TheCamera:GetRightVec()

	self.should_play_left_turn_anim = VecUtil_Dot(right_vec.x, right_vec.z, dir_x, dir_z) < 0

	boat.components.boatphysics:SetTargetRudderDirection(dir_x, dir_z)
end

function SteeringWheelUser:GetBoat()
	local player_pos_x, player_pos_y, player_pos_z = self.inst.Transform:GetWorldPosition()
	local boat = TheWorld.Map:GetPlatformAtPoint(player_pos_x, player_pos_z)
	return boat	
end

function SteeringWheelUser:OnUpdate(dt)
	if self.steering_wheel == nil then return end

	local down_vec = TheCamera:GetDownVec()
	local my_pos_x, my_pos_y, my_pos_z = self.inst.Transform:GetWorldPosition()
	local wheel_pos_x, wheel_pos_y, wheel_pos_z = self.steering_wheel.Transform:GetWorldPosition()
	local facing_x, facing_z = my_pos_x + down_vec.x, my_pos_z + down_vec.z

	local player_offset = 0.05

	self.inst.Transform:SetPosition(wheel_pos_x - player_offset * down_vec.x, wheel_pos_y - player_offset * down_vec.y, wheel_pos_z - player_offset * down_vec.z)
	self.inst:FacePoint(facing_x, 0, facing_z)
	self.steering_wheel:FacePoint(facing_x, 0, facing_z)

	local boat = self:GetBoat()
	if boat ~= nil then
		local boat_physics = boat.components.boatphysics
		if VecUtil_Dot(boat_physics.rudder_direction_x, boat_physics.rudder_direction_z, boat_physics.target_rudder_direction_x, boat_physics.target_rudder_direction_z) > 0.95 then
			self.inst.PushEvent("steer_boat_stop_turning")
		end
	end
end

return SteeringWheelUser
