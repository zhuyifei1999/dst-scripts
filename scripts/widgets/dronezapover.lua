local UIAnim = require("widgets/uianim")
local easing = require("easing")

local DroneZapOver = Class(UIAnim, function(self, owner)
	self.owner = owner
	UIAnim._ctor(self)

	self:SetClickable(false)

	self:SetHAnchor(ANCHOR_MIDDLE)
	self:SetVAnchor(ANCHOR_MIDDLE)
	self:SetScaleMode(SCALEMODE_PROPORTIONAL)

	self:GetAnimState():SetBank("wx78_drone_zap_overlay")
	self:GetAnimState():SetBuild("wx78_drone_zap_overlay")
	self:GetAnimState():Hide("SIGNAL_0")
	self.signal_level = 4

	self.arrow = self:AddChild(UIAnim())
	self.arrow:GetAnimState():SetBank("wx78_drone_zap_overlay")
	self.arrow:GetAnimState():SetBuild("wx78_drone_zap_overlay")
	self.arrow:GetAnimState():PlayAnimation("range_arrow", true)
	self.arrow:Hide()

	self.source = nil
	self.fade_ent = nil
	self.fade_t = nil
	self.fade_len = nil
	self.fade_in = nil
	self:Hide()

	self.inst:ListenForEvent("onremove", function()
		PostProcessor:SetDistortionFishLensRadius(0)
	end)

	self.inst:ListenForEvent("dronevision", function(owner, data)
		self:Toggle(data.enable, data.source)
	end, owner)

	self.inst:ListenForEvent("continuefrompause", function()
		if self.shown and self.source then
			self:SetFocus()
		end
	end, TheWorld)

	self._onremovesource = function(source)
		assert(self.source == source)
		self:Disable()
	end

	self._onperecentusedchange = function(item, data)
		assert(self.item == item)
		if data and data.percent then
			self:SetPowerLevel(data.percent)
		end
	end
end)

function DroneZapOver:GetDrone()
	return self.source
end

local function OnAnimOver(inst)
	inst:RemoveEventCallback("animover", OnAnimOver)
	inst.widget:Hide()
end

function DroneZapOver:Toggle(show, source)
	if source then
		if show then
			if source ~= self.source then
				self:Enable(source)
			end
		elseif source == self.source then
			self:Disable()
		end
	end
end

function DroneZapOver:SetSkinBuild(source)
	local skin_build = source and source.AnimState:GetSkinBuild()
	if skin_build and string.len(skin_build) > 0 then
		skin_build = skin_build.."_overlay"
		self:GetAnimState():SetSkin(skin_build, "wx78_drone_zap_overlay")
		self.arrow:GetAnimState():SetSkin(skin_build, "wx78_drone_zap_overlay")
	else
		self:GetAnimState():SetBuild("wx78_drone_zap_overlay")
		self.arrow:GetAnimState():SetBuild("wx78_drone_zap_overlay")
	end
end

function DroneZapOver:Enable(source)
	assert(source)
	if self.source == nil then
		self.inst:RemoveEventCallback("animover", OnAnimOver)
	elseif self.source:IsValid() then
		self.source.AnimState:SetMultColour(1, 1, 1, 1)
		self.inst:RemoveEventCallback("onremove", self._onremovesource, self.source)
	end
	self.source = source
	self.inst:ListenForEvent("onremove", self._onremovesource, source)
	self:SetSkinBuild(source)
	self:Show()
	self:SetFocus()
	self:GetAnimState():PlayAnimation("zap_over_pre")
	self:GetAnimState():PushAnimation("zap_over_idle_loop", true)
	self.arrow:Hide()
	self:StartFadeOut(source, 0.1)--self:GetAnimState():GetCurrentAnimationLength())

	local inventory = self.owner.replica.inventory
	local item = inventory and inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	if self.item then
		self.inst:RemoveEventCallback("percentusedchange", self._onperecentusedchange, self.item)
		self.item = nil
	end
	if item and item:HasTag("wx_remotecontroller") then
		if TheWorld.ismastersim then
			if item.components.finiteuses then
				self.item = item
				self.inst:ListenForEvent("percentusedchange", self._onperecentusedchange, item)
				self:SetPowerLevel(item.components.finiteuses:GetPercent())
			end
		else
			local inventoryitem = item.replica.inventoryitem
			if inventoryitem then
				self.item = item
				self.inst:ListenForEvent("percentusedchange", self._onperecentusedchange, item)
				inventoryitem:DeserializeUsage()
			end
		end
	end
	if self.item == nil then
		self:SetPowerLevel(1)
	end

	local w, h = TheSim:GetScreenSize()
	self.aspect_ratio = w > 0 and h > 0 and w / h or RESOLUTION_X / RESOLUTION_Y
	PostProcessor:SetDistortionFishLensAspectRatio(self.aspect_ratio)
	PostProcessor:SetDistortionFishLensRadius(0.8)
	self:StartUpdating()
end

function DroneZapOver:Disable()
	if self.source then
		self.inst:RemoveEventCallback("onremove", self._onremovesource, self.source)
		self.inst:ListenForEvent("animover", OnAnimOver)
		self:GetAnimState():PlayAnimation("zap_over_pst")
		self.arrow:Hide()
		self:StartFadeIn(self.source, self:GetAnimState():GetCurrentAnimationLength())
		PostProcessor:SetDistortionFishLensRadius(0)
		self.aspect_ratio = nil
		self.source = nil
		self:ClearFocus()
	end
	if self.item then
		self.inst:RemoveEventCallback("percentusedchange", self._onperecentusedchange, self.item)
		self.item = nil
	end
end

function DroneZapOver:OnHide(was_visible)
	self:CancelFade()
	self:StopUpdating()
	self:ClearFocus()
end

function DroneZapOver:TryClose()
	if self.source then
		if self.owner.StopUsingDrone then
			self.owner:StopUsingDrone()
		end
		self:Disable()
		return true
	end
end

function DroneZapOver:StartFadeIn(ent, len)
	self:CancelFade()
	self.fade_ent = ent
	self.fade_t = 0
	self.fade_len = len
	self.fade_in = true
end

function DroneZapOver:StartFadeOut(ent, len)
	self:CancelFade()
	self.fade_ent = ent
	self.fade_t = 0
	self.fade_len = len
	self.fade_in = false
end

function DroneZapOver:CancelFade()
	if self.fade_ent then
		if self.fade_ent:IsValid() then
			self.fade_ent.AnimState:OverrideMultColour(1, 1, 1, 1)
		end
		self:EndFade()
	end
end

function DroneZapOver:EndFade()
	self.fade_ent = nil
	self.fade_t = nil
	self.fade_len = nil
	self.fade_in = nil
end

function DroneZapOver:SetPowerLevel(pct)
	local level = math.clamp(math.ceil(pct * 4), 0, 4)
	if level > 0 then
		self:GetAnimState():Hide("POWER_0")
		for i = 1, level do
			self:GetAnimState():Show("POWER_"..tostring(i))
		end
		for i = level + 1, 4 do
			self:GetAnimState():Hide("POWER_"..tostring(i))
		end
	else
		self:GetAnimState():Show("POWER_0")
		for i = 1, 4 do
			self:GetAnimState():Hide("POWER_"..tostring(i))
		end
	end
end

function DroneZapOver:SetSignalLevel(pctsq)
	local level = math.clamp(math.ceil(4 - pctsq * 4), 0, 4)
	if self.signal_level ~= level then
		self.signal_level = level
		if level > 0 then
			self:GetAnimState():Hide("SIGNAL_0")
			for i = 1, level do
				self:GetAnimState():Show("SIGNAL_"..tostring(i))
			end
			for i = level + 1, 4 do
				self:GetAnimState():Hide("SIGNAL_"..tostring(i))
			end
		else
			self:GetAnimState():Show("SIGNAL_0")
			for i = 1, 4 do
				self:GetAnimState():Hide("SIGNAL_"..tostring(i))
			end
		end
	end
end

function DroneZapOver:OnUpdate(dt)
	local w, h = TheSim:GetScreenSize()
	if self.aspect_ratio then
		local aspect_ratio = w > 0 and h > 0 and w / h or RESOLUTION_X / RESOLUTION_Y
		if self.aspect_ratio ~= aspect_ratio then
			self.aspect_ratio = aspect_ratio
			PostProcessor:SetDistortionFishLensAspectRatio(aspect_ratio)
		end
	end

	if self.source then
		local x, _, z = self.source.Transform:GetWorldPosition()
		local x0, _, z0 = self.owner.Transform:GetWorldPosition()

		local range = self.source:GetDroneRange(self.owner)
		self:SetSignalLevel(self.source:GetDistanceSqToInst(self.owner) / (range * range))

		local scrnx, scrny = w * 0.5, h * 0.5
		local scrnx0, scrny0 = TheSim:GetScreenPos(x0, 0, z0)
		local scrndx = scrnx - scrnx0
		local scrndy = scrny - scrny0
		local scrndistsq = scrndx * scrndx + scrndy * scrndy
		local showarrowdist = 0.6 * scrny
		if scrndistsq < showarrowdist * showarrowdist then
			self.arrow:Hide()
		else
			self.arrow:Show()
			self.arrow:SetRotation(math.atan2(-scrndy, scrndx) * RADIANS - 90)
		end
	end

	if self.fade_ent then
		if self.fade_ent:IsValid() then
			self.fade_t = math.min(self.fade_len, self.fade_t + dt)

			if self.fade_in then
				self.fade_ent.AnimState:OverrideMultColour(1, 1, 1, easing.outQuad(self.fade_t, 0, 1, self.fade_len))
			else
				self.fade_ent.AnimState:OverrideMultColour(1, 1, 1, easing.outQuad(self.fade_t, 1, -1, self.fade_len))
			end

			if self.fade_t >= self.fade_len then
				self:EndFade()
			end
		else
			self:EndFade()
		end
	end
end

function DroneZapOver:GetHelpText()
	local controller_id = TheInput:GetControllerID()
	local t = {}
	table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL, false, false).." "..STRINGS.ACTIONS.STOPUSINGEQUIPPEDITEM.WX78_DRONE_ZAP_REMOTE)
	table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CONTROLLER_ATTACK, false, false ).." "..STRINGS.UI.DRONE_ZAP_OVERLAY.ATTACK)
	return table.concat(t, "  ")
end

return DroneZapOver
