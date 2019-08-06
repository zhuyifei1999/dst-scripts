local function OnRemovePlatform(inst, platform)
    local embarkercameracontroller = inst.components.embarkercameracontroller
    embarkercameracontroller:SetCameraTargetToMe(false)
end

local function OnGotOnPlatform(inst, platform)    
    local embarkercameracontroller = inst.components.embarkercameracontroller
    embarkercameracontroller:SetCameraTargetToPlatform(platform)
    embarkercameracontroller.platform = platform

    platform:ListenForEvent("onremove", embarkercameracontroller.on_remove_platform_cb)

    local platform_x, platform_y, platform_z = platform.Transform:GetWorldPosition()
    embarkercameracontroller.last_platform_x, embarkercameracontroller.last_platform_z = platform_x, platform_z
end

local function OnGotOffPlatform(inst, platform) 
    local embarkercameracontroller = inst.components.embarkercameracontroller
    embarkercameracontroller:SetCameraTargetToMe(false)

    if embarkercameracontroller.platform ~= nil and embarkercameracontroller.platform:IsValid() then
        embarkercameracontroller.platform:RemoveEventCallback("onremove", embarkercameracontroller.on_remove_platform_cb)
    end

    embarkercameracontroller.platform = nil
end

local function OnStartEmbarkMovement(inst, platform) 
    local embarker = inst.components.embarker
    local embarker_camera_controller = inst.components.embarkercameracontroller
    if embarker.embarkable ~= nil and embarker.embarkable:IsValid() then
        embarker_camera_controller:SetCameraTargetToPlatform(embarker.embarkable)
    else
        embarker_camera_controller:SetCameraTargetToMe(false)
    end    
end

local EmbarkerCameraController = Class(function(self, inst)
    self.inst = inst

    inst:ListenForEvent("start_embark_movement", OnStartEmbarkMovement)
    inst:ListenForEvent("got_on_platform", OnGotOnPlatform)
    inst:ListenForEvent("got_off_platform", OnGotOffPlatform)

    local pan_gain, heading_gain, distance_gain = TheCamera:GetGains()
    self.previous_pan_gain = pan_gain
    self.target_camera_offset = Point(0,0,0)
    self.camera_offset = Point(0,0,0)
    self.on_remove_platform_cb = function(platform) OnRemovePlatform(inst, platform) end

    self.velocities = {}

    for i=1,10 do
        self.velocities[i] = 0
    end
    self.next_velocity_idx = 0    
end)

function EmbarkerCameraController:SetCameraTargetToPlatform(platform)
    if self.camera_target_is_set then return end
    if self.inst ~= ThePlayer then return end

    local pan_gain, heading_gain, distance_gain = TheCamera:GetGains()
    TheCamera:SetTarget(platform)  
    TheCamera:SetGains(0.5, heading_gain, distance_gain) 

    self.target_pan_gain = 4       

    self.inst:StartUpdatingComponent(self)

    self.camera_target_is_set = true
end

function EmbarkerCameraController:SetCameraTargetToMe(snap_pan_gain)
    if not self.camera_target_is_set then return end
    if self.inst ~= ThePlayer then return end

    local pan_gain, heading_gain, distance_gain = TheCamera:GetGains()

    pan_gain = 0.5
    if snap_pan_gain then
        pan_gain = self.previous_pan_gain
    else
        self.inst:StartUpdatingComponent(self)
    end

    TheCamera:SetGains(pan_gain, heading_gain, distance_gain)
    TheCamera:SetTarget(TheFocalPoint)    

    self.target_pan_gain = self.previous_pan_gain       

    self.camera_target_is_set = false
end

function EmbarkerCameraController:OnUpdate(dt)
    local platform = self.platform
    if platform ~= nil and platform:IsValid() then        
        local platform_x, platform_y, platform_z = platform.Transform:GetWorldPosition()

        local velocity_x, velocity_z = (platform_x - self.last_platform_x) / dt, (platform_z - self.last_platform_z) / dt
        local velocity_normalized_x, velocity_normalized_z = 0, 0
        local velocity = 0        
        local min_velocity = 0.4
        local velocity_sq = velocity_x * velocity_x + velocity_z * velocity_z

        if velocity_sq >= min_velocity * min_velocity then
            velocity = math.sqrt(velocity_sq)
            velocity_normalized_x = velocity_x / velocity
            velocity_normalized_z = velocity_z / velocity
            velocity = math.max(velocity - min_velocity, 0)
        end

        local look_ahead_max_dist = 5
        local look_ahead_max_velocity = 3        
        local look_ahead_percentage = math.min(math.max(velocity / look_ahead_max_velocity, 0), 1)
        local look_ahead_amount = look_ahead_max_dist * look_ahead_percentage

        --Average target_camera_offset to get rid of some of the noise.
        self.target_camera_offset.x = (self.target_camera_offset.x + velocity_normalized_x * look_ahead_amount) / 2
        self.target_camera_offset.z = (self.target_camera_offset.z + velocity_normalized_z * look_ahead_amount) / 2        

        
        self.last_platform_x, self.last_platform_z = platform_x, platform_z

    else
        self.target_camera_offset.x = 0
        self.target_camera_offset.y = 1.5
        self.target_camera_offset.z = 0     

        self.camera_offset.x = 0
        self.camera_offset.y = 1.5
        self.camera_offset.z = 0        
    end

    local camera_offset_lerp_speed = 0.25
    self.camera_offset.x, self.camera_offset.z = VecUtil_Lerp(self.camera_offset.x, self.camera_offset.z, self.target_camera_offset.x, self.target_camera_offset.z, dt * camera_offset_lerp_speed)

    TheCamera:SetOffset(self.camera_offset)

    local pan_gain, heading_gain, distance_gain = TheCamera:GetGains()
    local pan_lerp_speed = 0.75
    pan_gain = Lerp(pan_gain, self.target_pan_gain, dt * pan_lerp_speed)        
    if self.target_pan_gain - pan_gain < 0.05 then
        pan_gain = self.target_pan_gain
        
        if self.platform == nil then
            self.inst:StopUpdatingComponent(self)
        end
    end
    TheCamera:SetGains(pan_gain, heading_gain, distance_gain)    
end

return EmbarkerCameraController