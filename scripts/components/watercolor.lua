local COLORS =
{
    default = { color={0.0, 0.125, 0.17, 1.0}, blend_delay=0, blend_speed=1 },
    night = { color={0.0, 0.0, 0.0, 1.0}, blend_delay=6, blend_speed=0.1 },
    no_ocean = { color={0.0, 0.0, 0.0, 1.0}, blend_delay=6, blend_speed=0.1 }
}

local WaterColor = Class(function(self, inst)
	self.inst = inst

    self.inst:ListenForEvent("phasechanged", function(src, phase) self:OnPhaseChanged(src, phase) end)

	self.inst:StartUpdatingComponent(self)
    self.start_color = shallowcopy(COLORS.default.color)
    self.current_color = shallowcopy(COLORS.default.color)
    self.end_color = shallowcopy(COLORS.default.color)
    self.lerp = 1
    self.lerp_delay = 0

    self.blend_delay = COLORS.default.blend_delay
    self.blend_speed = COLORS.default.blend_speed
end)

function WaterColor:Initialize(has_ocean)
    if has_ocean then
        self.inst:StartWallUpdatingComponent(self)
        TheWorld.Map:SetClearColor(COLORS.default.color[1], COLORS.default.color[2], COLORS.default.color[3], COLORS.default.color[4])        
    else
        TheWorld.Map:SetClearColor(COLORS.no_ocean.color[1], COLORS.no_ocean.color[2], COLORS.no_ocean.color[3], COLORS.no_ocean.color[4])
    end    
end

function WaterColor:OnWallUpdate(dt)
    if self.lerp >= 1 then return end

    if self.lerp_delay < self.blend_delay then
        self.lerp_delay = math.min(self.lerp_delay + dt)
        if self.lerp_delay < self.blend_delay then
            return
        end
    end

    self.lerp = math.min(self.lerp + dt * self.blend_speed, 1)

    
    for i = 1,4 do
        self.current_color[i] = Lerp(self.start_color[i], self.end_color[i], self.lerp)
    end

    TheWorld.Map:SetClearColor(self.current_color[1], self.current_color[2], self.current_color[3], self.current_color[4])
end

function WaterColor:OnPhaseChanged(src, phase)
    local target_color = COLORS.default
    if COLORS[phase] ~= nil then
        target_color = COLORS[phase]
    end
    self.start_color[0] = self.current_color[0]
    self.start_color[1] = self.current_color[1]
    self.start_color[2] = self.current_color[2]
    self.start_color[3] = self.current_color[3]
    self.end_color = target_color.color
    self.lerp = 0
    self.lerp_delay = 0

    self.blend_delay = target_color.blend_delay
    self.blend_speed = target_color.blend_speed    
end

return WaterColor
