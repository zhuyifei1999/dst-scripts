local UIAnim = require "widgets/uianim"
local easing = require "easing"

local ShroudenOver = Class(UIAnim, function(self, owner)
    self.owner = owner
    UIAnim._ctor(self)

    self:SetClickable(false)

    self:SetHAnchor(ANCHOR_LEFT)
    self:SetVAnchor(ANCHOR_TOP)
    self:SetScaleMode(SCALEMODE_FIXEDPROPORTIONAL)

    self:GetAnimState():SetBank("shrouden_overlay")
    self:GetAnimState():SetBuild("shrouden_overlay")
    self:GetAnimState():AnimateWhilePaused(false)
    self:Hide()

    self.scrnw = nil
    self.scrnh = nil
    self.soundlevel = 0
    self.sounddelay = 0
    self.inst:ListenForEvent("animover", function()
        if self:GetAnimState():IsCurrentAnimation("shrouden_tentacles_over_pst") and not self:GetAnimState():AnimDone() then
            TheFrontEnd:GetSound():PlaySound("rifts8/shrouden_portal/screen_transition_out")
        end
    end)
    self.inst:ListenForEvent("animqueueover", function()
        TheFrontEnd.overlayroot:RemoveChild(self)
        self:Hide()
        self:StopUpdating()
    end)
    if owner ~= nil then
        self.inst:ListenForEvent("shroudensummoned", function(owner) self:TriggerShrouden() end, owner)
    end
end)

function ShroudenOver:TriggerShrouden()
    self.soundlevel = 1
    self.sounddelay = 0
    self:UpdateScale()
    self:StartUpdating()
    self:Show()

    TheFrontEnd.overlayroot:AddChild(self) -- dont want to be affected by screen fade
    TheFrontEnd:GetSound():PlaySound("rifts8/shrouden_portal/screen_transition_in")
    self:GetAnimState():PlayAnimation("shrouden_tentacles_over_pre")
    self:GetAnimState():PushAnimation("shrouden_tentacles_over_pst", false)
end

function ShroudenOver:UpdateScale()
    -- local scrnh
    -- self.scrnw, scrnh = TheSim:GetScreenSize()
    -- if self.scrnh ~= scrnh then
    --     self.scrnh = scrnh
    --     local scale = scrnh / RESOLUTION_Y
    --     self:SetScale(scale, scale)
    -- end
end

function ShroudenOver:OnUpdate(dt)
    if TheNet:IsServerPaused() then return end

    self:UpdateScale()

    -- if self.sounddelay > dt then
    --     self.sounddelay = self.sounddelay - dt
    -- elseif self.soundlevel > 0 then
    --     local volume = easing.outQuad(math.min(.75, self.soundlevel), 0, 1, .75)
    --     TheFocalPoint.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap", nil, volume)
    --     if self.soundlevel > .05 then
    --         self.soundlevel = self.soundlevel - .05
    --         self.sounddelay = math.random(3, 4) * FRAMES
    --     else
    --         self.soundlevel = 0
    --         self.sounddelay = 0
    --     end
    -- end
end

return ShroudenOver
