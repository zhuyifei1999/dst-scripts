local BoatTrail = Class(function(self, inst)
    self.inst = inst

    self.anim_idx = 0
    self.inst:StartUpdatingComponent(self)
end)

local ANIMS = { "idle_loop_1", "idle_loop_2", "idle_loop_3" }

function BoatTrail:SpawnEffectPrefab(x, y, z, dir_x, dir_z)
    local fx = SpawnPrefab("boat_water_fx")

    local boat_physics = self.inst.components.boatphysics    
    local rudder_angle = VecUtil_GetAngleInDegrees(dir_x, dir_z)

    local radius = 3
    fx.Transform:SetPosition(x - dir_x * radius, y, z - dir_z * radius)         


    local boat_trail_mover = fx.components.boattrailmover
    boat_trail_mover:UpdateDir(dir_x, dir_z)
    boat_trail_mover.velocity = 0.5
    boat_trail_mover.acceleration = -0.125
    boat_trail_mover.boat = self.inst        

    local anim_count = #ANIMS
    local anim_idx = self.anim_idx
    if math.random() > 0.5 then
        anim_idx = anim_idx + 1
    else
        anim_idx =anim_idx - 1
        if anim_idx < 0 then
            anim_idx = anim_count
        end
    end

    anim_idx = anim_idx % anim_count
    boat_trail_mover.inst.AnimState:PlayAnimation(ANIMS[anim_idx + 1])
    self.anim_idx = anim_idx
end

function BoatTrail:GetDir()
    return self.last_dir_x, self.last_dir_z
end

function BoatTrail:OnUpdate(dt)
    local total_distance_traveled = self.total_distance_traveled
    local x, y, z = self.inst.Transform:GetWorldPosition()
    
    if not total_distance_traveled then
        self.last_x, self.last_z = x, z
        self.total_distance_traveled = 0
        return
    end

    local effect_spawn_rate = 1.0
    local dir_x, dir_z = x - self.last_x, z - self.last_z
    local distance_traveled = VecUtil_Length(dir_x, dir_z)
    distance_traveled = math.min(effect_spawn_rate, distance_traveled)

    total_distance_traveled = total_distance_traveled + distance_traveled

    dir_x, dir_z = VecUtil_Normalize(dir_x, dir_z)

    local angle_apart = 30

    if total_distance_traveled > effect_spawn_rate then   
        self:SpawnEffectPrefab(x, y, z, dir_x, dir_z)

        total_distance_traveled = total_distance_traveled - effect_spawn_rate
    end        

    self.total_distance_traveled = total_distance_traveled

    self.last_x = x
    self.last_z = z
    self.last_dir_x = dir_x
    self.last_dir_z = dir_z

end

return BoatTrail
