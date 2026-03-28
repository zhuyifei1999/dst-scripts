local UIAnim = require("widgets/uianim")
local Widget = require("widgets/widget")

--controlled by wx78_classified
local WxPowerOver =  Class(Widget, function(self, owner)
	self.owner = owner
	Widget._ctor(self, "wxpowerover")

	self:UpdateWhilePaused(false)
	self:SetClickable(false)

	self.fx = self:AddChild(UIAnim())
	self.fx:SetVAnchor(ANCHOR_MIDDLE)
	self.fx:SetHAnchor(ANCHOR_MIDDLE)
	self.fx:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)
	self.fx:GetAnimState():SetBank("wx_overlay")
	self.fx:GetAnimState():SetBuild("wx_overlay")
	self.fx:GetAnimState():AnimateWhilePaused(false)
	self:Hide()
end)

function WxPowerOver:PowerOff()
    TheFrontEnd:GetSound():PlaySound("WX_rework/chassis/deactivate_HUD")
	self.fx:GetAnimState():PlayAnimation("wx_turnoff")
	self:MoveToFront()
	self:Show()
end

function WxPowerOver:Clear()
    TheFrontEnd:GetSound():PlaySound("WX_rework/chassis/activate_HUD")
	self:Hide()
end

return WxPowerOver
