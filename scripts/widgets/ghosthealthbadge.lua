local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"

local GhostHealthBadge = Class(Badge, function(self, owner)
	Badge._ctor(self, "health_ghost", owner)

	self.sanityarrow = self.underNumber:AddChild(UIAnim())
	self.sanityarrow:GetAnimState():SetBank("sanity_arrow")
	self.sanityarrow:GetAnimState():SetBuild("sanity_arrow")
	self.sanityarrow:GetAnimState():PlayAnimation("neutral")
	self.sanityarrow:SetClickable(false)

	-- self.anim:GetAnimState():SetMultColour(.1,.7,.9,.9)
	
	self:StartUpdating()
end)

function GhostHealthBadge:OnUpdate(dt)
	local down = self.owner ~= nil and
        self.owner.replica.humanity ~= nil and
        self.owner.replica.humanity:IsDeteriorating() and
        not self.owner.replica.humanity:IsPaused()

	local anim = down and "arrow_loop_decrease_most" or "neutral"
	if self.arrowdir ~= anim then
		self.arrowdir = anim
		self.sanityarrow:GetAnimState():PlayAnimation(anim, true)
	end
end

return GhostHealthBadge