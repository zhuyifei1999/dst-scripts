local Widget = require "widgets/widget"
local SanityBadge = require "widgets/sanitybadge"
local HealthBadge = require "widgets/healthbadge"
local HungerBadge = require "widgets/hungerbadge"
local BeaverBadge = require "widgets/beaverbadge"
local MoistureMeter = require "widgets/moisturemeter"

local function OnSetPlayerMode(inst, self)
    self.modetask = nil

    if self.onhealthdelta == nil then
        self.onhealthdelta = function(owner, data) self:HealthDelta(data) end
        self.inst:ListenForEvent("healthdelta", self.onhealthdelta, self.owner)
        self:SetHealthPercent(self.owner.replica.health:GetPercent())
    end

    if self.onhungerdelta == nil then
        self.onhungerdelta = function(owner, data) self:HungerDelta(data) end
        self.inst:ListenForEvent("hungerdelta", self.onhungerdelta, self.owner)
        self:SetHungerPercent(self.owner.replica.hunger:GetPercent())
    end

    if self.onsanitydelta == nil then
        self.onsanitydelta = function(owner, data) self:SanityDelta(data) end
        self.inst:ListenForEvent("sanitydelta", self.onsanitydelta, self.owner)
        self:SetSanityPercent(self.owner.replica.sanity:GetPercent())
    end

    if self.onmoisturedelta == nil then
        self.onmoisturedelta = function(owner, data) self:MoistureDelta(data) end
        self.inst:ListenForEvent("moisturedelta", self.onmoisturedelta, self.owner)
        self:SetMoisturePercent(self.owner:GetMoisture())
    end

    if self.beaverness ~= nil and self.onbeavernessdelta == nil then
        self.onbeavernessdelta = function(owner, data) self:BeavernessDelta(data) end
        self.inst:ListenForEvent("beavernessdelta", self.onbeavernessdelta, self.owner)
        self:SetBeavernessPercent(self.owner:GetBeaverness())
    end
end

local function OnSetGhostMode(inst, self)
    self.modetask = nil

    if self.onhealthdelta ~= nil then
        self.inst:RemoveEventCallback("healthdelta", self.onhealthdelta, self.owner)
        self.onhealthdelta = nil
    end

    if self.onhungerdelta ~= nil then
        self.inst:RemoveEventCallback("hungerdelta", self.onhungerdelta, self.owner)
        self.onhungerdelta = nil
    end

    if self.onsanitydelta ~= nil then
        self.inst:RemoveEventCallback("sanitydelta", self.onsanitydelta, self.owner)
        self.onsanitydelta = nil
    end

    if self.onmoisturedelta ~= nil then
        self.inst:RemoveEventCallback("moisturedelta", self.onmoisturedelta, self.owner)
        self.onmoisturedelta = nil
    end

    if self.onbeavernessdelta ~= nil then
        self.inst:RemoveEventCallback("beavernessdelta", self.onbeavernessdelta, self.owner)
        self.onbeavernessdelta = nil
    end
end

local StatusDisplays = Class(Widget, function(self, owner)
    Widget._ctor(self, "Status")
    self.owner = owner

    self.beaverness = nil
    self.onbeavernessdelta = nil

    self.brain = self:AddChild(SanityBadge(owner))
    self.brain:SetPosition(0, -40, 0)
    self.onsanitydelta = nil

    self.stomach = self:AddChild(HungerBadge(owner))
    self.stomach:SetPosition(-40, 20, 0)
    self.onhungerdelta = nil

    self.heart = self:AddChild(HealthBadge(owner))
    self.heart:SetPosition(40, 20, 0)
    self.onhealthdelta = nil

    self.moisturemeter = self:AddChild(MoistureMeter(owner))
    self.moisturemeter:SetPosition(0, -115, 0)
    self.onmoisturedelta = nil

    self.modetask = nil
    self.isghostmode = true --force the initial SetGhostMode call to be dirty
    self:SetGhostMode(false)

    if owner:HasTag("beaverness") then
        self:AddBeaverness()
    end
end)

function StatusDisplays:AddBeaverness()
    if self.beaverness == nil then
        self.beaverness = self:AddChild(BeaverBadge(self.owner))
        self.beaverness:SetPosition(-80, -40, 0)

        if self.isghostmode then
            self.beaverness:Hide()
        elseif self.modetask == nil and self.onbeavernessdelta == nil then
            self.onbeavernessdelta = function(owner, data) self:BeavernessDelta(data) end
            self.inst:ListenForEvent("beavernessdelta", self.onbeavernessdelta, self.owner)
            self:SetBeavernessPercent(self.owner:GetBeaverness())
        end
    end
end

function StatusDisplays:RemoveBeaverness()
    if self.beaverness ~= nil then
        if self.onbeavernessdelta ~= nil then
            self.inst:RemoveEventCallback("beavernessdelta", self.onbeavernessdelta, self.owner)
            self.onbeavernessdelta = nil
        end

        self:SetBeaverMode(false)
        self.beaverness:Kill()
        self.beaverness = nil
    end
end

function StatusDisplays:SetBeaverMode(beavermode)
    if self.isghostmode or self.beaverness == nil then
        return
    elseif beavermode then
        self.stomach:Hide()
        self.beaverness:SetPosition(-40, 20, 0)
    else
        self.stomach:Show()
        self.beaverness:SetPosition(-80, -40, 0)
    end
end

function StatusDisplays:SetGhostMode(ghostmode)
    if not self.isghostmode == not ghostmode then --force boolean
        return
    elseif ghostmode then
        self.isghostmode = true

        self.heart:Hide()
        self.stomach:Hide()
        self.brain:Hide()
        self.moisturemeter:Hide()

        self.heart:StopWarning()
        self.stomach:StopWarning()
        self.brain:StopWarning()

        if self.beaverness ~= nil then
            self.beaverness:Hide()
            self.beaverness:StopWarning()
        end
    else
        self.isghostmode = nil

        self.heart:Show()
        self.stomach:Show()
        self.brain:Show()
        self.moisturemeter:Show()

        if self.beaverness ~= nil then
            self.beaverness:Show()
        end
    end

    if self.modetask ~= nil then
        self.modetask:Cancel()
    end
    self.modetask = self.inst:DoTaskInTime(0, ghostmode and OnSetGhostMode or OnSetPlayerMode, self)
end

function StatusDisplays:SetHealthPercent(pct)
    self.heart:SetPercent(pct, self.owner.replica.health:Max(), self.owner.replica.health:GetPenaltyPercent()) 

    if pct <= .33 then
        self.heart:StartWarning()
    else
        self.heart:StopWarning()
    end
end

function StatusDisplays:HealthDelta(data)
    self:SetHealthPercent(data.newpercent)

    if not data.overtime then
        if data.newpercent > data.oldpercent then
            self.heart:PulseGreen()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/health_up")
        elseif data.newpercent < data.oldpercent then
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/health_down")
            self.heart:PulseRed()
        end
    end
end

function StatusDisplays:SetHungerPercent(pct)
    self.stomach:SetPercent(pct, self.owner.replica.hunger:Max())

    if pct <= 0 then
        self.stomach:StartWarning()
    else
        self.stomach:StopWarning()
    end
end

function StatusDisplays:HungerDelta(data)
    self:SetHungerPercent(data.newpercent)

    if not data.overtime then
        if data.newpercent > data.oldpercent then
            self.stomach:PulseGreen()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/hunger_up")
        elseif data.newpercent < data.oldpercent then
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/hunger_down")
            self.stomach:PulseRed()
        end
    end
end

function StatusDisplays:SetSanityPercent(pct)
    self.brain:SetPercent(pct, self.owner.replica.sanity:Max(), self.owner.replica.sanity:GetPenaltyPercent())

    if self.owner.replica.sanity:IsCrazy() then
        self.brain:StartWarning()
    else
        self.brain:StopWarning()
    end
end

function StatusDisplays:SanityDelta(data)
    self:SetSanityPercent(data.newpercent)

    if not data.overtime then
        if data.newpercent > data.oldpercent then
            self.brain:PulseGreen()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/sanity_up")
        elseif data.newpercent < data.oldpercent then
            self.brain:PulseRed()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/sanity_down")
        end
    end
end

function StatusDisplays:SetBeavernessPercent(pct)
    self.beaverness:SetPercent(pct)
end

function StatusDisplays:BeavernessDelta(data)
    self:SetBeavernessPercent(data.newpercent)

    if not data.overtime then
        if data.newpercent > data.oldpercent then
            self.beaverness:PulseGreen()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/health_up")
        elseif data.newpercent < data.oldpercent then
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/health_down")
            self.beaverness:PulseRed()
        end
    end
end

function StatusDisplays:SetMoisturePercent(pct)
    self.moisturemeter:SetValue(pct, self.owner:GetMaxMoisture(), self.owner:GetMoistureRateScale())
end

function StatusDisplays:MoistureDelta(data)
    self:SetMoisturePercent(data.new)
end

return StatusDisplays
