local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"

local SanityBadge = Class(Badge, function(self, owner)
	Badge._ctor(self, "sanity", owner)
	
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

	self.ghostanim = self.underNumber:AddChild(UIAnim())
	self.ghostanim:GetAnimState():SetBank("sanity_ghost")
	self.ghostanim:GetAnimState():SetBuild("sanity_ghost")
	self.ghostanim:GetAnimState():PlayAnimation("deactivate")
	self.ghostanim:Hide()
	self.ghostanim:SetClickable(false)

	self.val = 100
	self.max = 100
	self.penaltypercent = 0
	self.ghost = false

	self:StartUpdating()
end)

function SanityBadge:SetPercent(val, max, penaltypercent)
	self.val = val
	self.max = max
	Badge.SetPercent(self, self.val, self.max)

	self.penaltypercent = penaltypercent or 0
	self.topperanim:GetAnimState():SetPercent("anim", self.penaltypercent)
end

function SanityBadge:OnUpdate(dt)
    local sanity = self.owner.replica.sanity
    local anim = "neutral"
    local ghost = false

    if sanity ~= nil then
        if self.owner:HasTag("sleeping") then
            --Special case for sleeping: at night, sanity will ping between .9999 and 1 of max, so make an exception for the arrow
            if sanity:GetPercentWithPenalty() < 1 then
                anim = "arrow_loop_increase"
            end
        else
            local rate = sanity:GetRate()
            if rate > 0 and sanity:GetPercentWithPenalty() < 1 then
                if rate > .2 then
                    anim = "arrow_loop_increase_most"
                elseif rate > .1 then
                    anim = "arrow_loop_increase_more"
                elseif rate > .01 then
                    anim = "arrow_loop_increase"
                end
            elseif rate < 0 and sanity:GetPercentWithPenalty() > 0 then
                if rate < -.3 then
                    anim = "arrow_loop_decrease_most"
                elseif rate < -.1 then
                    anim = "arrow_loop_decrease_more"
                elseif rate < -.02 then
                    anim = "arrow_loop_decrease"
                end
            end
        end
        ghost = sanity:IsGhostDrain()
    end

	if self.arrowdir ~= anim then
		self.arrowdir = anim
		self.sanityarrow:GetAnimState():PlayAnimation(anim, true)
	end

    if self.ghost ~= ghost then
        self.ghost = ghost
        if ghost then
            self.ghostanim:GetAnimState():PlayAnimation("activate")
            self.ghostanim:GetAnimState():PushAnimation("idle", true)
            self.ghostanim:Show()
        else
            self.ghostanim:GetAnimState():PlayAnimation("deactivate")
        end
    end
end

return SanityBadge