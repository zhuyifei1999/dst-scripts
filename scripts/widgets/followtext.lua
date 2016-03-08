local Widget = require "widgets/widget"
local Text = require "widgets/text"

local FollowText = Class(Widget, function(self, font, size, text)
    Widget._ctor(self, "followtext")

    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:SetMaxPropUpscale(MAX_HUD_SCALE)
    self.text = self:AddChild(Text(font, size, text))
    self.offset = Vector3(0,0,0)
    self.screen_offset = Vector3(0,0,0)

    self:StartUpdating()
end)


function FollowText:SetTarget(target)
    self.target = target
    self:OnUpdate()
end

function FollowText:SetOffset(offset)
    self.offset = offset
    self:OnUpdate()
end

function FollowText:SetScreenOffset(x,y)
    self.screen_offset.x = x
    self.screen_offset.y = y
    self:OnUpdate()
end

function FollowText:GetScreenOffset()
    return self.screen_offset.x, self.screen_offset.y
end

function FollowText:OnUpdate(dt)
    if self.target ~= nil and self.target:IsValid() then
        local scale = TheFrontEnd:GetHUDScale()
        self.text:SetScale(scale)
        local pos =
            self.target.AnimState ~= nil and
            Vector3(self.target.AnimState:GetSymbolPosition(self.symbol or "", self.offset.x, self.offset.y, self.offset.z)) or
            self.target:GetPosition()
        pos.x, pos.y = TheSim:GetScreenPos(pos:Get())
        pos.x, pos.y, pos.z = pos.x + self.screen_offset.x, pos.y + self.screen_offset.y, 0
        self:SetPosition(pos)
    end
end

return FollowText
