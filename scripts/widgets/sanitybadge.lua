local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"

local function OnGhostDeactivated(inst)
    if inst.AnimState:IsCurrentAnimation("deactivate") then
        inst.widget:Hide()
    end
end

local SanityBadge = Class(Badge, function(self, owner)
    Badge._ctor(self, "sanity", owner)

    self.topperanim = self.underNumber:AddChild(UIAnim())
    self.topperanim:GetAnimState():SetBank("effigy_topper")
    self.topperanim:GetAnimState():SetBuild("effigy_topper")
    self.topperanim:GetAnimState():PlayAnimation("anim")
    self.topperanim:SetClickable(false)

    self.sanityarrow = self.underNumber:AddChild(UIAnim())
    self.sanityarrow:GetAnimState():SetBank("sanity_arrow")
    self.sanityarrow:GetAnimState():SetBuild("sanity_arrow")
    self.sanityarrow:GetAnimState():PlayAnimation("neutral")
    self.sanityarrow:SetClickable(false)

    --Hide the original frame since it is now overlapped by the topperanim
    self.anim:GetAnimState():Hide("frame")

    self.ghostanim = self.underNumber:AddChild(UIAnim())
    self.ghostanim:GetAnimState():SetBank("sanity_ghost")
    self.ghostanim:GetAnimState():SetBuild("sanity_ghost")
    self.ghostanim:GetAnimState():PlayAnimation("deactivate")
    self.ghostanim:Hide()
    self.ghostanim:SetClickable(false)
    self.ghostanim.inst:ListenForEvent("animover", OnGhostDeactivated)

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

local RATE_SCALE_ANIM =
{
    [RATE_SCALE.INCREASE_HIGH] = "arrow_loop_increase_most",
    [RATE_SCALE.INCREASE_MED] = "arrow_loop_increase_more",
    [RATE_SCALE.INCREASE_LOW] = "arrow_loop_increase",
    [RATE_SCALE.DECREASE_HIGH] = "arrow_loop_decrease_most",
    [RATE_SCALE.DECREASE_MED] = "arrow_loop_decrease_more",
    [RATE_SCALE.DECREASE_LOW] = "arrow_loop_decrease",
}

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
            local ratescale = sanity:GetRateScale()
            if ratescale == RATE_SCALE.INCREASE_LOW or
                ratescale == RATE_SCALE.INCREASE_MED or
                ratescale == RATE_SCALE.INCREASE_HIGH then
                if sanity:GetPercentWithPenalty() < 1 then
                    anim = RATE_SCALE_ANIM[ratescale]
                end
            elseif ratescale == RATE_SCALE.DECREASE_LOW or
                ratescale == RATE_SCALE.DECREASE_MED or
                ratescale == RATE_SCALE.DECREASE_HIGH then
                if sanity:GetPercentWithPenalty() > 0 then
                    anim = RATE_SCALE_ANIM[ratescale]
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
