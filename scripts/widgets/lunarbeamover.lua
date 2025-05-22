local Widget = require("widgets/widget")
local UIAnim = require("widgets/uianim")

local LunarBeamOver = Class(Widget, function(self, owner)
	self.owner = owner
	Widget._ctor(self, "LunarBeamOver")

	self.anim = self:AddChild(UIAnim())
	self:SetScaleMode(SCALEMODE_FIXEDPROPORTIONAL)

	self:SetClickable(false)
	self:SetHAnchor(ANCHOR_LEFT)
	self:SetVAnchor(ANCHOR_TOP)

	self.anim:GetAnimState():SetBank("wagboss_beam_over")
	self.anim:GetAnimState():SetBuild("wagboss_beam_over")
	self.anim:GetAnimState():PlayAnimation("anim", true)
	self.anim:GetAnimState():SetMultColour(1, 1, 1, 0)
	self.anim:GetAnimState():AnimateWhilePaused(false)

	self.alpha = 0
	self.targetalpha = 0
	self:Hide()

	self.inst:ListenForEvent("startlunarbeamdamage", function(owner) self:TurnOn() end, owner)
	self.inst:ListenForEvent("stoplunarbeamdamage", function(owner) self:TurnOff() end, owner)
	local health = owner.replica.health
	if health and health:IsTakingLunarBeamDamage() then
		self:TurnOn()
	end
end)

function LunarBeamOver:TurnOn()
	self.targetalpha = 1
	if self.alpha ~= 1 then
		self:Show()
		self:StartUpdating()
	else
		self:StopUpdating()
	end
end

function LunarBeamOver:TurnOff()
	self.targetalpha = 0
	if self.alpha ~= 0 then
		self:StartUpdating()
	else
		self:StopUpdating()
		self:Hide()
	end
end

function LunarBeamOver:OnUpdate(dt)
	if dt > 0 then
		dt = dt * 4
		if self.targetalpha > self.alpha then
			self.alpha = self.alpha + dt
			if self.alpha >= self.targetalpha then
				self.alpha = self.targetalpha
				self:StopUpdating()
			end
		else
			self.alpha = self.alpha - dt
			if self.alpha <= self.targetalpha then
				self.apha = self.targetalpha
				self:StopUpdating()
			end
		end
		self.anim:GetAnimState():SetMultColour(1, 1, 1, self.alpha)
	end
end

return LunarBeamOver
