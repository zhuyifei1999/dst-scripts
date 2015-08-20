local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"

local function OnEffigyDeactivated(inst)
    if inst.AnimState:IsCurrentAnimation("deactivate") then
        inst.widget:Hide()
    end
end

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

    --Hide the original frame since it is now overlapped by the topperanim
    self.anim:GetAnimState():Hide("frame")

    self.effigyanim = self.underNumber:AddChild(UIAnim())
    self.effigyanim:GetAnimState():SetBank("health_effigy")
    self.effigyanim:GetAnimState():SetBuild("health_effigy")
    self.effigyanim:GetAnimState():PlayAnimation("deactivate")
    self.effigyanim:Hide()
    self.effigyanim:SetClickable(false)
    self.effigyanim.inst:ListenForEvent("animover", OnEffigyDeactivated)
    self.effigy = false
    self.effigybreaksound = nil

    self:StartUpdating()
end)

function HealthBadge:ShowEffigy()
    if not self.effigy then
        self.effigy = true
        self.effigyanim:GetAnimState():PlayAnimation("activate")
        self.effigyanim:GetAnimState():PushAnimation("idle", false)
        self.effigyanim:Show()
    end
end

local function PlayEffigyBreakSound(inst, self)
    inst.task = nil
    if self:IsVisible() and inst.AnimState:IsCurrentAnimation("deactivate") then
        TheFocalPoint.SoundEmitter:PlaySound(self.effigybreaksound)
    end
end

function HealthBadge:HideEffigy()
    if self.effigy then
        self.effigy = false
        self.effigyanim:GetAnimState():PlayAnimation("deactivate")
        if self.effigyanim.inst.task ~= nil then
            self.effigyanim.inst.task:Cancel()
        end
        self.effigyanim.inst.task = self.effigyanim.inst:DoTaskInTime(7 * FRAMES, PlayEffigyBreakSound, self)
    end
end

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
        (self.owner.replica.health ~= nil and self.owner.replica.health:IsTakingFireDamage()) or
        (self.owner.IsBeaverStarving ~= nil and self.owner:IsBeaverStarving())

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
