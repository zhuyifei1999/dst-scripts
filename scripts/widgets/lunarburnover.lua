local Widget = require("widgets/widget")
local UIAnim = require("widgets/uianim")
local WagBossUtil = require("prefabs/wagboss_util")

local LunarBurnOver = Class(Widget, function(self, owner)
	self.owner = owner
	Widget._ctor(self, "LunarBurnOver")

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
	self.flags = WagBossUtil.LunarBurnFlags.ALL
	self.anim:GetAnimState():Hide("supernova_miss")
	self:Hide()

	self.inst:ListenForEvent("startlunarburn", function(owner, flags) self:TurnOn(flags) end, owner)
	self.inst:ListenForEvent("stoplunarburn", function(owner) self:TurnOff() end, owner)
	local health = owner.replica.health
	local flags = health and health:GetLunarBurnFlags() or 0
	if flags ~= 0 then
		self:TurnOn(flags)
	end
end)

function LunarBurnOver:TurnOn(flags)
	if flags ~= self.flags or self.targetalpha ~= 1 then
		self.flags = flags
		if WagBossUtil.HasLunarBurnDamage(flags) then
			self.anim:GetAnimState():Show("lvl0")

			if bit.band(flags, WagBossUtil.LunarBurnFlags.SUPERNOVA) ~= 0 then
				self.anim:GetAnimState():Show("lvl2")
				self.anim:GetAnimState():Show("supernova_hit")
				self.anim:GetAnimState():Hide("supernova_miss")
			else
				self.anim:GetAnimState():Hide("lvl2")
				self.anim:GetAnimState():Hide("supernova_hit")
				if bit.band(flags, WagBossUtil.LunarBurnFlags.NEAR_SUPERNOVA) ~= 0 then
					self.anim:GetAnimState():Show("supernova_miss")
				else
					self.anim:GetAnimState():Hide("supernova_miss")
				end
			end

			if bit.band(flags, WagBossUtil.LunarBurnFlags.GENERIC) ~= 0 then
				self.anim:GetAnimState():Show("lvl1")
			else
				self.anim:GetAnimState():Hide("lvl1")
			end

			TheFocalPoint.SoundEmitter:KillSound("lunarburn_miss")
			if not TheFocalPoint.SoundEmitter:PlayingSound("lunarburn_hit") then
				TheFocalPoint.SoundEmitter:PlaySound("rifts5/wagstaff_boss/beam_burning_fx_LP", "lunarburn_hit")
			end
		else
			self.anim:GetAnimState():Hide("lvl0")
			self.anim:GetAnimState():Hide("lvl1")
			self.anim:GetAnimState():Hide("lvl2")
			self.anim:GetAnimState():Hide("supernova_hit")
			if bit.band(flags, WagBossUtil.LunarBurnFlags.NEAR_SUPERNOVA) ~= 0 then
				self.anim:GetAnimState():Show("supernova_miss")
				if not TheFocalPoint.SoundEmitter:PlayingSound("lunarburn_miss") then
					TheFocalPoint.SoundEmitter:PlaySound("rifts5/lunar_boss/supernova_blocked_LP", "lunarburn_miss")
				end
			else
				self.anim:GetAnimState():Hide("supernova_miss")
				TheFocalPoint.SoundEmitter:KillSound("lunarburn_miss")
			end
			TheFocalPoint.SoundEmitter:KillSound("lunarburn_hit")
		end
	end

	self.targetalpha = 1

	if self.alpha ~= 1 then
		self:Show()
		self:StartUpdating()
	else
		self:StopUpdating()
	end
end

function LunarBurnOver:TurnOff()
	TheFocalPoint.SoundEmitter:KillSound("lunarburn_miss")
	if TheFocalPoint.SoundEmitter:PlayingSound("lunarburn_hit") then
		TheFocalPoint.SoundEmitter:KillSound("lunarburn_hit")
		TheFocalPoint.SoundEmitter:PlaySound("rifts5/wagstaff_boss/beam_burning_fx_pst")
	end
	self.targetalpha = 0
	if self.alpha ~= 0 then
		self:StartUpdating()
	else
		self:StopUpdating()
		self:Hide()
	end
end

function LunarBurnOver:OnUpdate(dt)
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
				self.alpha = self.targetalpha
				self:StopUpdating()
			end
		end
		self.anim:GetAnimState():SetMultColour(1, 1, 1, self.alpha)
	end
end

return LunarBurnOver
