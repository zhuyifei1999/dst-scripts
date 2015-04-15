local Widget = require "widgets/widget"
local SanityBadge = require "widgets/sanitybadge"
local HealthBadge = require "widgets/healthbadge"
local HungerBadge = require "widgets/hungerbadge"
--local GhostHungerBadge = require "widgets/ghosthungerbadge"
--local GhostHealthBadge = require "widgets/ghosthealthbadge"

local function OnSetPlayerMode(inst, self)
    self.modetask = nil

    if self.onhealthdelta == nil then
        self.onhealthdelta = function(owner, data) self:HealthDelta(data) end
        self.inst:ListenForEvent("healthdelta", self.onhealthdelta, self.owner)
        self.heart:SetPercent(self.owner.replica.health:GetPercent(), self.owner.replica.health:Max(), self.owner.replica.health:GetPenaltyPercent())
    end

    if self.onhungerdelta == nil then
        self.onhungerdelta = function(owner, data) self:HungerDelta(data) end
        self.inst:ListenForEvent("hungerdelta", self.onhungerdelta, self.owner)
        self.stomach:SetPercent(self.owner.replica.hunger:GetPercent(), self.owner.replica.hunger:Max())
    end

    if self.onsanitydelta == nil then
        self.onsanitydelta = function(owner, data) self:SanityDelta(data) end
        self.inst:ListenForEvent("sanitydelta", self.onsanitydelta, self.owner)
        self.brain:SetPercent(self.owner.replica.sanity:GetPercent(), self.owner.replica.sanity:Max(), self.owner.replica.sanity:GetPenaltyPercent())
    end
--[[
    if self.onghostdelta ~= nil then
        self.inst:RemoveEventCallback("ghostdelta", self.onghostdelta, self.owner)
        self.onghostdelta = nil
    end
]]
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

--[[
    if self.onghostdelta == nil then
        self.onghostdelta = function(owner, data) self:GhostDelta(data) end
        self.inst:ListenForEvent("ghostdelta", self.onghostdelta, self.owner)
        self.ghost_heart:SetPercent(1 - self.owner.replica.humanity:GetHealthPenaltyPercent(), self.owner.replica.humanity:HealthPenaltyMax())
        self.ghost_stomach:SetPercent(self.owner.replica.humanity:GetPercent(), self.owner.replica.humanity:Max())
    end
]]
end

local StatusDisplays = Class(Widget, function(self, owner)
    Widget._ctor(self, "Status")
    self.owner = owner

    self.brain = self:AddChild(SanityBadge(owner))
    --self.brain:SetPosition(0,35,0)
    self.brain:SetPosition(0,-40,0)

    self.stomach = self:AddChild(HungerBadge(owner))
    --self.stomach:SetPosition(-38,-32,0)
    self.stomach:SetPosition(-40,20,0)

    self.heart = self:AddChild(HealthBadge(owner))
    --self.heart:SetPosition(38,-32,0)
    self.heart:SetPosition(40,20,0)
--[[
    self.ghost_stomach = self:AddChild(GhostHungerBadge(owner))
    self.ghost_stomach:SetPosition(-40,10,0)
    self.ghost_stomach:SetPercent(50,100,0)
    self.ghost_stomach:Hide()

    self.ghost_heart = self:AddChild(GhostHealthBadge(owner))
    self.ghost_heart:SetPosition(40,10,0)
    self.ghost_heart:SetPercent(100,100,0)
    self.ghost_heart:Hide()
]]
    self.modetask = nil
    self:SetGhostMode(false)
end)

function StatusDisplays:SetGhostMode(ghostmode)
    if ghostmode then
        self.heart:Hide()
        self.stomach:Hide()
        self.brain:Hide()
        --self.ghost_heart:Show()
        --self.ghost_stomach:Show()
    else
        self.heart:Show()
        self.stomach:Show()
        self.brain:Show()
        --self.ghost_heart:Hide()
        --self.ghost_stomach:Hide()
    end

    if self.modetask ~= nil then
        self.modetask:Cancel()
    end
    self.modetask = self.inst:DoTaskInTime(0, ghostmode and OnSetGhostMode or OnSetPlayerMode, self)
end

function StatusDisplays:HealthDelta(data)
	self.heart:SetPercent(data.newpercent, self.owner.replica.health:Max(), self.owner.replica.health:GetPenaltyPercent()) 
	
	if data.oldpercent > .33 and data.newpercent <= .33 then
		self.heart:StartWarning()
	else
		self.heart:StopWarning()
	end
	
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

function StatusDisplays:HungerDelta(data)
	self.stomach:SetPercent(data.newpercent, self.owner.replica.hunger:Max())

	if data.newpercent <= 0 then
		self.stomach:StartWarning()
	else
		self.stomach:StopWarning()
	end

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

function StatusDisplays:SanityDelta(data)
	self.brain:SetPercent(data.newpercent, self.owner.replica.sanity:Max(), self.owner.replica.sanity:GetPenaltyPercent())
	
	if self.owner.replica.sanity:IsCrazy() then
		self.brain:StartWarning()
	else
		self.brain:StopWarning()
	end
	
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
--[[
local function IsWarningRed(badge)
    local r, g, b = badge.warning:GetAnimState():GetMultColour()
    return r == 1 and g == 0 and b == 0
end

function StatusDisplays:GhostDelta(data)
	self.ghost_heart:SetPercent(1 - data.newhealthpenaltypercent, self.owner.replica.humanity:HealthPenaltyMax())
	self.ghost_stomach:SetPercent(data.newpercent, self.owner.replica.humanity:Max())

    if self.owner.replica.humanity:IsPaused() then
        if not TheFrontEnd:GetSound():PlayingSound("ghostpulse") then
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/sanity_down", "ghostpulse")
        end
        if self.owner.replica.humanity:IsDeteriorating() then
            --Restart if red
            self.ghost_heart:StartWarning(.8, .8, 1, 1, IsWarningRed(self.ghost_heart))
            self.ghost_stomach:StopWarning()    
        else
            --Restart if red
            self.ghost_stomach:StartWarning(.8, .8, 1, 1, IsWarningRed(self.ghost_stomach))
            self.ghost_heart:StopWarning()  
        end
    elseif self.owner.replica.humanity:IsDeteriorating() then
        --Restart if not red
        self.ghost_heart:StartWarning(1, 0, 0, 1, not IsWarningRed(self.ghost_heart))
        self.ghost_stomach:StartWarning(1, 0, 0, 1, not IsWarningRed(self.ghost_stomach))
    else
        self.ghost_heart:StopWarning()
        self.ghost_stomach:StopWarning()
    end
end
]]
return StatusDisplays