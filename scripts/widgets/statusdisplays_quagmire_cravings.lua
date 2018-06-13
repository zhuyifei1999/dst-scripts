local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"

local function GetLevel()
    return TheWorld.net ~= nil and TheWorld.net.components.quagmire_hangriness:GetLevel() or 1
end

local function GetMouthLevel(level)
    return math.max(1, level - 1)
end

local function GetMeter()
    return TheWorld.net ~= nil and math.clamp(1 - TheWorld.net.components.quagmire_hangriness:GetPercent(), 0, 1) or 0
end

local function DoCameraShake(self, type, duration, speed, scale)
    if self.owner.HUD.shown and TheWorld.net ~= nil and TheWorld.net.components.quagmire_hangriness:GetCurrent() > 0 then
        TheCamera:Shake(type, duration, speed, scale)
    end
end

local function DoSound(self, sound, volume)
    if self.owner.HUD.shown then
        TheFocalPoint.SoundEmitter:PlaySound(sound, nil, volume)
    end
end

local function DoEatShake(src, self)
    DoCameraShake(self, CAMERASHAKE.VERTICAL, .4, .02, .4)
    DoSound(self, "dontstarve/quagmire/creature/gnaw/chomp")
end

local function DoAngryShake(src, self)
    DoCameraShake(self, CAMERASHAKE.FULL, 1.1, .045, .1)
    DoSound(self, "dontstarve/quagmire/creature/gnaw/rumble", .5)
end

local CravingsStatus = Class(Widget, function(self, owner)
    Widget._ctor(self, "CravingsStatus")
    self.owner = owner

    local root_scale_y = 1
    local root = self:AddChild(Widget("hangriness_bar"))
    root:SetScale(1, root_scale_y)
    root:SetPosition(0, -50 * root_scale_y)

    self.bar = root:AddChild(UIAnim())
    self.bar:GetAnimState():SetBank("quagmire_hangry_bar")
    self.bar:GetAnimState():SetBuild("quagmire_hangry_bar")
    self.bar:GetAnimState():PlayAnimation("bar", true)
    self.bar:GetAnimState():SetDeltaTimeMultiplier(.59)

    self.bar2 = root:AddChild(UIAnim())
    self.bar2:GetAnimState():SetBank("quagmire_hangry_bar")
    self.bar2:GetAnimState():SetBuild("quagmire_hangry_bar")
    self.bar2:GetAnimState():PlayAnimation("bar", true)
    self.bar2:GetAnimState():SetMultColour(1, 1, 1, .5)
    self.bar2:GetAnimState():SetDeltaTimeMultiplier(.29)
    self.bar2:SetScale(-1, 1)

    self.meter = GetMeter()
    self.frame = root:AddChild(UIAnim())
    self.frame:GetAnimState():SetBank("quagmire_hangry_bar")
    self.frame:GetAnimState():SetBuild("quagmire_hangry_bar")
    self.frame:GetAnimState():SetPercent("frame", self.meter)

    self.level = GetLevel()
    self.nextlevel = nil
    self.fx = root:AddChild(UIAnim())
    self.fx:GetAnimState():SetBank("quagmire_hangry_bar_fx")
    self.fx:GetAnimState():SetBuild("quagmire_hangry_bar_fx")
    self.fx:GetAnimState():PlayAnimation(tostring(self.level))
    self.fx:SetScale(.45, .45)

    self.mouthlevel = GetMouthLevel(self.level)
    self.nextmouthlevel = nil
    self.nextmouthanim = nil
    self.mouth = root:AddChild(UIAnim())
    self.mouth:GetAnimState():SetBank("quagmire_hangry_status")
    self.mouth:GetAnimState():SetBuild("quagmire_hangry_status")
    self.mouth:GetAnimState():PlayAnimation(self.mouthlevel > 1 and ("idle_"..tostring(self.mouthlevel)) or "idle")
    self.mouth:SetScale(1.1, 1.1)
    self.mouth:SetPosition(0, -.5)

    self:StartUpdating()

    self.inst:ListenForEvent("animover", function()
        if self.nextlevel == nil then
            self.fx:GetAnimState():PlayAnimation(tostring(self.level))
        elseif self.nextlevel > self.level then
            self.fx:GetAnimState():PlayAnimation(tostring(self.nextlevel).."_pre")
            self:ShakeScreen(self.level)
            self.level = self.nextlevel
            self.nextlevel = nil
        else
            self.fx:GetAnimState():PlayAnimation(tostring(self.level).."_pst")
            self.level = 1
            self.nextlevel = self.nextlevel > 1 and self.nextlevel or nil
        end
    end, self.fx.inst)

    self.inst:ListenForEvent("animover", function()
        if self.nextmouthanim ~= nil then
            if #self.nextmouthanim > 0 then
                local anim = table.remove(self.nextmouthanim, 1)
                self.mouth:GetAnimState():PlayAnimation(anim)
                if anim == "angry" then
                    self.inst:DoTaskInTime(24 * FRAMES, DoAngryShake, self)
                end
            else
                self.nextmouthanim = nil
            end
        end
        if self.nextmouthanim == nil then
            if self.nextmouthlevel == nil then
                self.mouth:GetAnimState():PlayAnimation(self.mouthlevel > 1 and ("idle_"..tostring(self.mouthlevel)) or "idle")
            elseif self.nextmouthlevel > self.mouthlevel then
                self.mouth:GetAnimState():PlayAnimation("idle_"..tostring(self.nextmouthlevel).."_pre")
                self.mouthlevel = self.nextmouthlevel
                self.nextmouthlevel = nil
            else
                self.mouth:GetAnimState():PlayAnimation("idle_"..tostring(self.mouthlevel).."_pst")
                self.mouthlevel = 1
                self.nextmouthlevel = self.nextmouthlevel > 1 and self.nextmouthlevel or nil
            end
        end
    end, self.mouth.inst)

    self.inst:ListenForEvent("quagmirehangrinessrumbled", function(src, data)
        if self.nextmouthanim == nil then
            self.mouth:GetAnimState():PlayAnimation(data.major and "snarl" or "spin")
            self.nextmouthlevel = self.nextmouthlevel or self.mouthlevel
            self.nextmouthlevel = self.nextmouthlevel > 1 and self.nextmouthlevel or nil
            self.mouthlevel = 1
        end
    end, TheWorld)

    self.inst:ListenForEvent("quagmirehangrinessmatched", function(src, data)
        self.mouth:GetAnimState():PlayAnimation("eat")
        DoSound(self, "dontstarve/quagmire/creature/gnaw/rumble", .4)
        self.nextmouthanim = { data.matched and "happy" or "angry" }
        self.nextmouthlevel = self.nextmouthlevel or self.mouthlevel
        self.nextmouthlevel = self.nextmouthlevel > 1 and self.nextmouthlevel or nil
        self.mouthlevel = 1
        self.inst:DoTaskInTime(13 * FRAMES, DoEatShake, self)
        self.inst:DoTaskInTime(24 * FRAMES, DoEatShake, self)
    end, TheWorld)
end)

function CravingsStatus:ShakeScreen(level)
    DoCameraShake(self, CAMERASHAKE.HORIZONTAL, .8, .03, level >= 3 and .15 or .1)
end

function CravingsStatus:SetMeter(percent)
    self.frame:GetAnimState():SetPercent("frame", percent)
end

function CravingsStatus:SetLevel(level)
    if level == self.level then
        self.nextlevel = nil
    elseif level > self.level and self.fx:GetAnimState():IsCurrentAnimation(tostring(self.level)) then
        --prevent flicker by checking current animation isn't a transition
        self.fx:GetAnimState():PlayAnimation(tostring(level).."_pre")
        self:ShakeScreen(level)
        self.level = level
        self.nextlevel = nil
    else
        self.nextlevel = level
    end
end

function CravingsStatus:SetMouth(mouthlevel)
    self.nextmouthlevel = mouthlevel ~= self.mouthlevel and mouthlevel or nil
end

function CravingsStatus:OnUpdate(dt)
    if TheWorld.net == nil then
        return
    end

    local meter = GetMeter()
    self.meter = meter * .1 + self.meter * .9
    self:SetMeter(self.meter)

    local level = GetLevel()
    self:SetLevel(level)
    self:SetMouth(GetMouthLevel(level))
end

return CravingsStatus
