local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Button = require "widgets/button"
local Image = require "widgets/image"

local ImageButton = Class(Button, function(self, atlas, normal, focus, disabled, down)
    Button._ctor(self, "ImageButton")

    if not atlas then
        atlas = atlas or "images/ui.xml"
        normal = normal or "button.tex"
        focus = focus or "button_over.tex"
        disabled = disabled or "button_disabled.tex"
        down = down or "button_over.tex"
    end

    self.image = self:AddChild(Image())
    self.image:MoveToBack()

    self.atlas = atlas
	self.image_normal = normal
    self.image_focus = focus or normal
    self.image_disabled = disabled or normal
    self.image_down = down or self.image_focus
    self.has_image_down = down ~= nil

    self.scale_on_focus = true
    self.move_on_click = true
    
    self.image:SetTexture(self.atlas, self.image_normal)

    --self.control = CONTROL_ACCEPT --Defined in button.lua, but leaving comment here for clarity
end)


function ImageButton:OnGainFocus()
	ImageButton._base.OnGainFocus(self)
    if self:IsEnabled() then
    	self.image:SetTexture(self.atlas, self.image_focus)
	end

    if self.image_focus == self.image_normal then
        if self.scale_on_focus then
            self.image:SetScale(1.2,1.2,1.2)
        end
    end

end

function ImageButton:OnLoseFocus()
	ImageButton._base.OnLoseFocus(self)
    if self:IsEnabled() then
    	self.image:SetTexture(self.atlas, self.image_normal)
	end

    if self.image_focus == self.image_normal then
        if self.scale_on_focus then
            self.image:SetScale(1,1,1)
        end
    end
end

function ImageButton:OnControl(control, down)
    if not self:IsEnabled() or not self.focus then return end

    if control == self.control then
        if down then
            if self.has_image_down then
                self.image:SetTexture(self.atlas, self.image_down)
            end
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
            self.o_pos = self:GetLocalPosition()
            if self.move_on_click then
                self:SetPosition(self.o_pos + self.clickoffset)
            end
            self.down = true
            if self.whiledown then
                self:StartUpdating()
            end
            if self.ondown then
                self.ondown()
            end
        else
            if self.has_image_down then
                self.image:SetTexture(self.atlas, self.image_focus)
            end
            self.down = false
            if self.o_pos then
                self:SetPosition(self.o_pos) --#srosen this was crashing when spamming clicks... maybe fallout from not inheriting this fn properly?
            end
            if self.onclick then
                self.onclick()
            end
            self:StopUpdating()
        end
        return true
    end
end

function ImageButton:Enable()
	ImageButton._base.Enable(self)
    self.image:SetTexture(self.atlas, self.focus and self.image_focus or self.image_normal)
    self.text:SetColour(0,0,0,1)
    self.text:SetFont(BUTTONFONT)
    if self.image_focus == self.image_normal then
        if self.focus then 
            if self.scale_on_focus then
                self.image:SetScale(1.2,1.2,1.2)
            end
        else
            if self.scale_on_focus then 
                self.image:SetScale(1,1,1)
            end
        end
    end

end

function ImageButton:Disable()
	ImageButton._base.Disable(self)
	self.image:SetTexture(self.atlas, self.image_disabled)
    self.text:SetColour(.6,.6,.6,1)
    self.text:SetFont(self.disabledfont or UIFONT)
end

function ImageButton:GetSize()
    return self.image:GetSize()
end

return ImageButton