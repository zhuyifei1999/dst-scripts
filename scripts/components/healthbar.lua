local HealthBar = Class(function(self, inst)

    self.inst = inst

    local bar_width = 100
    local bar_height = 10
    local bar_offset = 12
    local bar_border = 1
    local hud_atlas = resolvefilepath("images/hud.xml")
    local bar_image = "stat_bar.tex"

    ----------------------------------
    self.bg = CreateEntity()
    --[[Non-networked entity]]
    self.bg.entity:AddTransform()

    self.bg.entity:AddImage()
    self.bg.Image:SetTexture(hud_atlas, bar_image)
    self.bg.Image:SetTint(0.075, 0.07, 0.07, 1)
    self.bg.Image:SetWorldOffset(0, 3, 0)
    self.bg.Image:SetUIOffset(bar_offset, 0, 0)
    self.bg.Image:SetSize(bar_width, bar_height)
    self.bg.Image:Enable(false)

    inst:AddChild(self.bg)

    ----------------------------------
    self.bar = CreateEntity()
    --[[Non-networked entity]]
    self.bar.entity:AddTransform()

    self.bar.entity:AddImage()
    self.bar.Image:SetTexture(hud_atlas, bar_image)
    self.bar.Image:SetTint(0.7, 0.1, 0, 1)
    self.bar.Image:SetWorldOffset(0, 3, 0)
    self.bar.Image:Enable(false)
    self.bar.width = bar_width - bar_border * 2
    self.bar.height = bar_height - bar_border * 2
    self.bar.offset = bar_offset

    self.bar.entity:AddLabel()
    self.bar.Label:SetFontSize(16)
    self.bar.Label:SetFont(SMALLNUMBERFONT)
    self.bar.Label:SetWorldOffset(0, 3, 0)
    self.bar.Label:SetUIOffset(-bar_width / 2, 0, 0)
    self.bar.Label:Enable(false)

    inst:AddChild(self.bar)

    ----------------------------------
    self:SetValue(1)
    inst:ListenForEvent("healthdelta", function(inst, data) self:SetValue(data.newpercent) end)

end)

function HealthBar:SetValue(percent)

    local hp = math.floor(percent * 100)
    if percent > 0 then
        local newwidth = self.bar.width * percent
        if hp < 1 then
            hp = 1
        end
        self.bar.Label:SetText(hp.."%")
        self.bar.Image:SetSize(newwidth, self.bar.height)
        self.bar.Image:SetUIOffset(self.bar.offset + (newwidth - self.bar.width) / 2, 0, 0)
        if self.inst ~= ThePlayer then
            self.bar.Label:Enable(true)
            self.bar.Image:Enable(true)
            self.bg.Image:Enable(true)
            if self.inst.Label then
                self.inst.Label:SetUIOffset(0, 20, 0)
            end
        end
    else
        self.bar.Label:Enable(false)
        self.bar.Image:Enable(false)
        self.bg.Image:Enable(false)
        if self.inst.Label then
            self.inst.Label:SetUIOffset(0, 0, 0)
        end
    end

end

return HealthBar