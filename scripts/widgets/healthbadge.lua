local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"

local HealthBadge = Class(Badge, function(self, owner)
	Badge._ctor(self, "health", owner)

	self.sanityarrow = self.underNumber:AddChild(UIAnim())
	self.sanityarrow:GetAnimState():SetBank("sanity_arrow")
	self.sanityarrow:GetAnimState():SetBuild("sanity_arrow")
	self.sanityarrow:GetAnimState():PlayAnimation("neutral")
	self.sanityarrow:SetClickable(false)

	
	self.topperanim = self.underNumber:AddChild(UIAnim())
	self.topperanim:GetAnimState():SetBank("effigy_topper")
	self.topperanim:GetAnimState():SetBuild("effigy_topper")
	self.topperanim:GetAnimState():PlayAnimation("anim")
	self.topperanim:SetClickable(false)
	
	self:StartUpdating()
end)

function HealthBadge:SetPercent(val, max, penaltypercent)
	Badge.SetPercent(self, val, max)

	penaltypercent = penaltypercent or 0
	self.topperanim:GetAnimState():SetPercent("anim", penaltypercent)
end	

function HealthBadge:OnUpdate(dt)
	local down = self.owner ~= nil and
        (self.owner.IsFreezing ~= nil and self.owner:IsFreezing()) or
        (self.owner.IsOverheating ~= nil and self.owner:IsOverheating()) or
        (self.owner.replica.hunger ~= nil and self.owner.replica.hunger:IsStarving()) or
        (self.owner.replica.health ~= nil and self.owner.replica.health:IsTakingFireDamage())

	-- Show the up-arrow when we're sleeping (but not in a straw roll: that doesn't heal us)
	local up = not down and self.owner ~= nil and
        self.owner.player_classified ~= nil and self.owner.player_classified.issleephealing:value() and
		self.owner.replica.health ~= nil and self.owner.replica.health:IsHurt()
	
	local anim = down and "arrow_loop_decrease_most" or (up and "arrow_loop_increase" or "neutral")
	if self.arrowdir ~= anim then
		self.arrowdir = anim
		self.sanityarrow:GetAnimState():PlayAnimation(anim, true)
	end
end

return HealthBadge