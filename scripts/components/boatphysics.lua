local function OnCollide(inst, other, world_position_on_a_x, world_position_on_a_y, world_position_on_a_z, world_position_on_b_x, world_position_on_b_y, world_position_on_b_z, world_normal_on_b_x, world_normal_on_b_y, world_normal_on_b_z, lifetime_in_frames)
	local boat_physics = inst.components.boatphysics
    if other ~= nil and other:IsValid() and (other == TheWorld or other:HasTag("BLOCKER") or other.components.boatphysics) and lifetime_in_frames <= 1 then

    	local relative_velocity_x = boat_physics.velocity_x
    	local relative_velocity_z = boat_physics.velocity_z

    	local other_boat_physics = other.components.boat_physics
    	if other_boat_physics ~= nil then
    		if other_boat_physics ~= nil then
	    		relative_velocity_x = relative_velocity_x - other_boat_physics.velocity_x
    			relative_velocity_z = relative_velocity_z - other_boat_physics.velocity_z
    		end
    	end  	

    	local velocity = VecUtil_Length(relative_velocity_x, relative_velocity_z)  


    	local hit_normal_x, hit_normal_z = VecUtil_Normalize(world_normal_on_b_x, world_normal_on_b_z)
    	local velocity_normalized_x, velocity_normalized_z = relative_velocity_x, relative_velocity_z
    	if velocity > 0 then
    		velocity_normalized_x, velocity_normalized_z = velocity_normalized_x / velocity, velocity_normalized_z / velocity
    	end
    	local hit_dot_velocity = VecUtil_Dot(hit_normal_x, hit_normal_z, velocity_normalized_x, velocity_normalized_z)

    	inst:PushEvent("on_collide", { other = other,
    										world_position_on_a_x = world_position_on_a_x, 
    										world_position_on_a_y = world_position_on_a_y, 
    										world_position_on_a_z = world_position_on_a_z,
    									    world_position_on_b_x = world_position_on_b_x, 
    									    world_position_on_b_y = world_position_on_b_y, 
    									    world_position_on_b_z = world_position_on_b_z, 
    									    world_normal_on_b_x = world_normal_on_b_x, 
    									    world_normal_on_b_y = world_normal_on_b_y, 
    									    world_normal_on_b_z = world_normal_on_b_z, 
    									    lifetime_in_frames = lifetime_in_frames,
    									    hit_dot_velocity = hit_dot_velocity})

		local push_back = -1.75 * velocity    	

		--[[
    	print("HIT DOT:", hit_dot_velocity)
    	print("HIT NORMAL:", hit_normal_x, hit_normal_z)
    	print("VELOCITY:", velocity_normalized_x, velocity_normalized_z)
    	print("PUSH BACK:", push_back)
    	]]--


        local shake_percent = math.min(math.abs(hit_dot_velocity) * velocity / boat_physics.max_velocity, 1)

        local platform = inst.components.walkableplatform
        if platform ~= nil then
	        for k,v in pairs(inst.components.walkableplatform:GetEntitiesOnPlatform({"player"})) do
				v:ShakeCamera(CAMERASHAKE.FULL, .7, .02, 0.15 * shake_percent)
	        end		
    	end

        local hit_intensity = shake_percent
        inst.SoundEmitter:PlaySoundWithParams("turnoftides/common/together/boat/damage", { intensity = hit_intensity })

        if velocity >= boat_physics.damageable_velocity then
        	local boat_x, boat_y, boat_z = inst.Transform:GetWorldPosition()        	

        end
        	other:PushEvent("hit_boat", inst)

        	local push_back = TUNING.BOAT.PUSH_BACK_VELOCITY * velocity * math.abs(hit_dot_velocity)
        	
        	boat_physics.velocity_x, boat_physics.velocity_z = relative_velocity_x + push_back * hit_normal_x, relative_velocity_z + push_back * hit_normal_z
    end
end

local BoatPhysics = Class(function(self, inst)
    self.inst = inst
    self.velocity_x = 0
    self.velocity_z = 0
    self.has_speed = false
    self.damageable_velocity = 1.25
    self.max_velocity = TUNING.BOAT.MAX_VELOCITY
    self.rudder_turn_speed = TUNING.BOAT.RUDDER_TURN_SPEED
    self.fx_spawn_rate = 1.5
    self.fx_spawn_timer = 0
    self.leak_count = 0
    self.is_sinking = false
    self.masts = {}
    self.anchor_cmps = {}

    self.lastzoomtime = nil
    self.lastzoomwasout = false

    self.target_rudder_direction_x = 1
    self.target_rudder_direction_z = 0
    self.rudder_direction_x = 1
    self.rudder_direction_z = 0

    self.inst:StartUpdatingComponent(self)

    self.inst.Physics:SetCollisionCallback(OnCollide)

    self.inst:ListenForEvent("onsink", function(inst) self:OnSink() end)
    self.inst:ListenForEvent("onignite", function() self:OnIgnite() end)
    self.inst:ListenForEvent("onbuilt", function(inst, data)  self:OnBuilt(data.builder, data.pos) end)  
    self.inst:ListenForEvent("deployed", function(inst, data)  self:OnBuilt(data.deployer, data.pos) end)  
    self.inst:ListenForEvent("death", function() self:OnDeath() end)    
end)

function BoatPhysics:OnSave()
    local data =
    {
        target_rudder_direction_x = self.target_rudder_direction_x,
        target_rudder_direction_z = self.target_rudder_direction_z,
    }

    return data
end

function BoatPhysics:OnLoad(data)
    if data ~= nil then
        self.target_rudder_direction_x = data.target_rudder_direction_x
        self.rudder_direction_x = data.target_rudder_direction_x
        self.target_rudder_direction_z = data.target_rudder_direction_z
        self.rudder_direction_z = data.target_rudder_direction_z
    end
end

function BoatPhysics:OnSink()
	self.is_sinking = true
end

function BoatPhysics:AddAnchorCmp(anchor_cmp)
    self.anchor_cmps[anchor_cmp] = anchor_cmp
end

function BoatPhysics:RemoveAnchorCmp(anchor_cmp)
    self.anchor_cmps[anchor_cmp] = nil
end

function BoatPhysics:IncrementLeakCount()
	self.leak_count = self.leak_count + 1
end

function BoatPhysics:DecrementLeakCount()
	self.leak_count = self.leak_count - 1
end

function BoatPhysics:SetTargetRudderDirection(dir_x, dir_z)
	self.target_rudder_direction_x = dir_x
	self.target_rudder_direction_z = dir_z
end

function BoatPhysics:AddMast(mast)
    self.masts[mast] = mast
end

function BoatPhysics:RemoveMast(mast)
    self.masts[mast] = nil
end

function BoatPhysics:OnDeath()
	self.sinking = true

    self.inst.SoundEmitter:KillSound("boat_movement")
end

function BoatPhysics:OnIgnite()
	self.max_velocity = 1

	local my_pos = Vector3(self.inst.Transform:GetWorldPosition())

    local burnable_locator = SpawnPrefab('burnable_locator_medium')
    burnable_locator.Transform:SetPosition(my_pos.x + 2.5, my_pos.y + 0, my_pos.z + 0)

    burnable_locator = SpawnPrefab('burnable_locator_medium')
    burnable_locator.Transform:SetPosition(my_pos.x + -2.5, my_pos.y + 0, my_pos.z + 0)

    burnable_locator = SpawnPrefab('burnable_locator_medium')
    burnable_locator.Transform:SetPosition(my_pos.x + 0, my_pos.y + 0, my_pos.z + 2.5)

    burnable_locator = SpawnPrefab('burnable_locator_medium')
    burnable_locator.Transform:SetPosition(my_pos.x + 0, my_pos.y + 0, my_pos.z + -2.5)

end

function BoatPhysics:Row(row_dir_x, row_dir_z, row_force)
    self.velocity_x, self.velocity_z = self.velocity_x + row_dir_x * row_force, self.velocity_z + row_dir_z * row_force
end

function BoatPhysics:GetTotalAnchorDrag()
    local total_anchor_drag = 0
    for k,v in pairs(self.anchor_cmps) do
        total_anchor_drag = total_anchor_drag + k:GetDrag()
    end
    return total_anchor_drag
end

function BoatPhysics:OnUpdate(dt)
    local boat_pos_x, boat_pos_y, boat_pos_z = self.inst.Transform:GetWorldPosition()

    self.rudder_direction_x, self.rudder_direction_z = VecUtil_Slerp(self.rudder_direction_x, self.rudder_direction_z, self.target_rudder_direction_x, self.target_rudder_direction_z, dt * self.rudder_turn_speed)

    local raised_sail_count = 0
    local sail_force = 0
    for k,v in pairs(self.masts) do
        if k.is_sail_raised then
            sail_force = sail_force + k.sail_force
            raised_sail_count = raised_sail_count + 1
        end
    end

    local total_anchor_drag = self:GetTotalAnchorDrag()

    if raised_sail_count > 0 and total_anchor_drag <= 0 and not self.is_sinking then
        self.velocity_x, self.velocity_z = VecUtil_Add(self.velocity_x, self.velocity_z, VecUtil_Scale(self.rudder_direction_x, self.rudder_direction_z, sail_force * dt))
	elseif raised_sail_count == 0 or total_anchor_drag > 0 then
		local velocity_length = VecUtil_Length(self.velocity_x, self.velocity_z)	
		local min_velocity = 0.55
		local drag = TUNING.BOAT.BASE_DRAG

		if total_anchor_drag > 0 then
			min_velocity = 0
			drag = drag + total_anchor_drag
		end

		if velocity_length > min_velocity then			
			local dragged_velocity_length = Lerp(velocity_length, min_velocity, dt * drag)
			self.velocity_x, self.velocity_z = VecUtil_Scale(self.velocity_x, self.velocity_z, dragged_velocity_length / velocity_length)
		end
	end
	
	local velocity_length = VecUtil_Length(self.velocity_x, self.velocity_z)
	if velocity_length > self.max_velocity then	
		self.velocity_x, self.velocity_z = self.velocity_x * 0.95, self.velocity_z * 0.95
	end

    if raised_sail_count > 0 then
        self.fx_spawn_timer = self.fx_spawn_timer + dt * self.fx_spawn_rate
        if self.fx_spawn_timer >= 1 then
            self.fx_spawn_timer = 0
            local fx = SpawnPrefab("boat_water_fx")
            fx.Transform:SetPosition(boat_pos_x, boat_pos_y, boat_pos_z)
            local rudder_angle = VecUtil_GetAngleInDegrees(self.rudder_direction_x, self.rudder_direction_z)
            fx.Transform:SetRotation(-rudder_angle + 90)
        end
    end    

    local new_speed_is_scary = ((self.velocity_x*self.velocity_x) + (self.velocity_z*self.velocity_z)) > TUNING.BOAT.SCARY_MINSPEED_SQR
    if not self.has_speed and new_speed_is_scary then
        self.has_speed = true
        self.inst:AddTag("scarytoprey")
    elseif self.has_speed and not new_speed_is_scary then
        self.has_speed = false
        self.inst:RemoveTag("scarytoprey")
    end

    local time = GetTime()
    if self.lastzoomtime == nil or time - self.lastzoomtime > 1.0 then
        local should_zoom_out = raised_sail_count > 0 and total_anchor_drag <= 0 and not self.is_sinking
        if not self.lastzoomwasout and should_zoom_out then
            self.inst:AddTag("doplatformcamerazoom")
            self.lastzoomwasout = true
        elseif self.lastzoomwasout and not should_zoom_out then
            self.inst:RemoveTag("doplatformcamerazoom")
            self.lastzoomwasout = false
        end

        self.lastzoomtime = time
    end

	self.inst.Physics:SetMotorVel(self.velocity_x, 0, self.velocity_z)	

    self.inst.SoundEmitter:SetParameter("boat_movement", "speed", velocity_length / self.max_velocity)
end

function BoatPhysics:OnRemoveFromEntity()
    self.inst:RemoveTag("doplatformcamerazoom")
end

return BoatPhysics
