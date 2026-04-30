local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"

local SourceModifierList = require("util/sourcemodifierlist")
local GetModuleDefinitionFromNetID = require("wx78_moduledefs").GetModuleDefinitionFromNetID

local easing = require("easing")

local TIMEOUT = 2 --network calls
local EXTENDED_SCALE_Y = 7/6

-------------------------------------------------------------------------------------------------------

-- The more complex version of the modules display

local function Chip_OnControl(self, control, down, ...)
    if self._base.OnControl(self, control, down, ...) then
        return true
    end

    if not self.focus then
        return false
    end

    if control == CONTROL_ACCEPT and down then
        self.parent:UnplugModule(self.moduletype, self.chip_index)
    end
end

local function Chip_OnGainFocus(self, ...)
    self._base.OnGainFocus(self, ...)
    self.parent:OnChipGainFocus(self)
end

local function Chip_OnLoseFocus(self, ...)
    self._base.OnLoseFocus(self, ...)
    self.parent:OnChipLoseFocus(self)
end

local function ShadowSlot_OnControl(self, control, down, ...)
	if self._base.OnControl(self, control, down, ...) then
		return true
	end

	if not self.focus then
		return false
	end

	if control == CONTROL_ACCEPT and down then
		self.parent.parent:UnplugShadowSlot()
	end
end

local function ShadowSlot_OnGainFocus(self, ...)
	self._base.OnGainFocus(self, ...)
	self.parent.parent:OnShadowSlotGainFocus()
end

local function ShadowSlot_OnLoseFocus(self, ...)
	self._base.OnLoseFocus(self, ...)
	self.parent.parent:OnShadowSlotLoseFocus()
end

local function DoHeartBeat(inst)
	local self = inst.widget
	self.shadow_slot_item:GetAnimState():PlayAnimation("shadow_heart_chip_beat")
	local animdata = self.shadow_slot_item_oldanimdata
	if animdata and animdata.idle_anim then
		self.shadow_slot_item:GetAnimState():PushAnimation(animdata.idle_anim, animdata.loops or false)
	end
	TheFrontEnd:GetSound():PlaySound("dontstarve/sanity/shadow_heart_HUD")
	inst.beattask = inst:DoTaskInTime(0.75 + math.random() * 0.75, DoHeartBeat)
end

local function ShadowSlotItem_StartBeatingHeart(self)
	if self.inst.beattask == nil then
		self.inst.beattask = self.inst:DoTaskInTime(0.2 + math.random() * 0.5, DoHeartBeat)
	end
end

local function ShadowSlotItem_StopBeatingHeart(self)
	if self.inst.beattask then
		self.inst.beattask:Cancel()
		self.inst.beattask = nil
	end
end

local function DoHeartBeat_Infused(inst)
	local self = inst.widget
	self.shadow_slot_item:GetAnimState():PlayAnimation("shadow_heart_chip_beat")
	if self.shadow_slot_item.heart then
		self.shadow_slot_item.heart:GetAnimState():PlayAnimation("shadow_heart_chip_beat")
	end
	local animdata = self.shadow_slot_item_oldanimdata
	if animdata and animdata.idle_anim then
		self.shadow_slot_item:GetAnimState():PushAnimation(animdata.idle_anim, animdata.loops or false)
		if self.shadow_slot_item.heart then
			self.shadow_slot_item.heart:GetAnimState():PushAnimation(animdata.idle_anim, animdata.loops or false)
		end
	end
	TheFrontEnd:GetSound():PlaySound("dontstarve/sanity/shadow_heart_HUD")
	inst.beattask = inst:DoTaskInTime(0.75 + math.random() * 0.75, DoHeartBeat_Infused)
end

local function ShadowSlotItem_StartBeatingHeart_Infused(self)
	self.shadow_slot_item:GetAnimState():Hide("plug")

	if self.shadow_slot_item.fx == nil then
		self.shadow_slot_item.fx = self.shadow_slot_item:AddChild(UIAnim())
		self.shadow_slot_item.fx:SetClickable(false)
		self.shadow_slot_item.fx:GetAnimState():SetBank("status_wx_chest_shadow")
		self.shadow_slot_item.fx:GetAnimState():SetBuild("status_wx_chest_shadow")
		self.shadow_slot_item.fx:GetAnimState():PlayAnimation("shadow_heart_infused_chip_fx", true)
		self.shadow_slot_item.fx:GetAnimState():Hide("focus")
		if self.shadow_slot_item.focuschildren == nil then
			self.shadow_slot_item.focuschildren = { self.shadow_slot_item.fx }
		else
			table.insert(self.shadow_slot_item.focuschildren, self.shadow_slot_item.fx)
		end
	end

	local animdata = self.shadow_slot_item_oldanimdata
	if animdata and animdata.idle_anim then
		if self.shadow_slot_item.heart == nil then
			self.shadow_slot_item.heart = self.shadow_slot_item:AddChild(UIAnim())
			self.shadow_slot_item.heart:SetClickable(false)
			self.shadow_slot_item.heart:GetAnimState():SetBank("status_wx_chest_shadow")
			self.shadow_slot_item.heart:GetAnimState():SetBuild("status_wx_chest_shadow")
			self.shadow_slot_item.heart:GetAnimState():Hide("focus")
		end
		if animdata.plug_anim then
			self.shadow_slot_item.heart:GetAnimState():PlayAnimation(animdata.plug_anim)
			self.shadow_slot_item.heart:GetAnimState():PushAnimation(animdata.idle_anim, animdata.loops or false)
		else
			self.shadow_slot_item.heart:GetAnimState():PlayAnimation(animdata.idle_anim, animdata.loops)
		end
	end

	if self.inst.beattask == nil then
		self.inst.beattask = self.inst:DoTaskInTime(0.2 + math.random() * 0.5, DoHeartBeat_Infused)
	end
end

local function ShadowSlotItem_StopBeatingHeart_Infused(self)
	self.shadow_slot_item:GetAnimState():Show("plug")

	if self.shadow_slot_item.fx then
		if self.shadow_slot_item.focuschildren then
			table.removearrayvalue(self.shadow_slot_item.focuschildren, self.shadow_slot_item.fx)
			if #self.shadow_slot_item.focuschildren <= 0 then
				self.shadow_slot_item.focuschildren = nil
			end
		end
		self.shadow_slot_item.fx:Kill()
		self.shadow_slot_item.fx = nil
	end

	if self.shadow_slot_item.heart then
		self.shadow_slot_item.heart:Kill()
		self.shadow_slot_item.heart = nil
	end

	if self.inst.beattask then
		self.inst.beattask:Cancel()
		self.inst.beattask = nil
	end
end

local SOCKETQUALITY_TO_ANIMS = {
    [SOCKETNAMES.SHADOW] = {
        [SOCKETQUALITY.NONE] = {},
		[SOCKETQUALITY.LOW] =
		{
			bank = "status_wx_chest_shadow",
			build = "status_wx_chest_shadow",
			plug_anim = "nightmare_fuel_chip_plug",
			idle_anim = "nightmare_fuel_chip_idle",
			loops = true,
			plug_sound = "WX_rework/module_tray/shadowfuel_implant",
			unplug_sound = "WX_rework/module_tray/shadow_unplug",
		},
		[SOCKETQUALITY.MEDIUM] =
		{
			bank = "status_wx_chest_shadow",
			build = "status_wx_chest_shadow",
			plug_anim = "horror_fuel_chip_plug",
			idle_anim = "horror_fuel_chip_idle",
			loops = true,
			plug_sound = "WX_rework/module_tray/shadowfuel_implant",
			unplug_sound = "WX_rework/module_tray/shadow_unplug",
		},
		[SOCKETQUALITY.HIGH] = {
			bank = "status_wx_chest_shadow",
			build = "status_wx_chest_shadow",
			plug_anim = "shadow_heart_chip_plug",
			idle_anim = "shadow_heart_chip_idle",
			plug_sound = "WX_rework/module_tray/shadowheart_implant",
			unplug_sound = "WX_rework/module_tray/shadow_unplug",
			initfn = ShadowSlotItem_StartBeatingHeart,
			clearfn = ShadowSlotItem_StopBeatingHeart,
		},
		[SOCKETQUALITY.PERFECT] =
		{
			bank = "status_wx_chest_shadow",
			build = "status_wx_chest_shadow",
			plug_anim = "shadow_heart_infused_chip_plug",
			idle_anim = "shadow_heart_chip_idle",
			plug_sound = "WX_rework/module_tray/shadowheart2_implant",
			unplug_sound = "WX_rework/module_tray/shadow_unplug",
			initfn = ShadowSlotItem_StartBeatingHeart_Infused,
			clearfn = ShadowSlotItem_StopBeatingHeart_Infused,
		},
    },
}

local UpgradeModulesDisplay_Inspecting = Class(Widget, function(self, owner, controls)
    Widget._ctor(self, "UpgradeModulesDisplay_Inspecting")
    self:UpdateWhilePaused(false)
    self.owner = owner
    self.controls = controls

	self.busylocks = 0
	self.timeouttask = nil

    local max_energy = owner:GetMaxEnergy()
    self.max_energy = max_energy
    self.energy_level = max_energy

    local scale = 0.88
    self:SetScale(scale, scale, scale)
    self:SetPosition(-425, 0)

    -- Skill
    self.can_unplug_any = false
    self.has_shadow_affinity = false
    if owner.components.skilltreeupdater then
        self.can_unplug_any = owner.components.skilltreeupdater:IsActivated("wx78_circuitry_betterunplug")
        self.has_shadow_affinity = owner.components.skilltreeupdater:IsActivated("wx78_allegiance_shadow")
    end
    local function OnUpdateSkill(_, data)
        local needsrefresh = false
        if data.skill == "wx78_circuitry_betterunplug" then
            self.can_unplug_any = owner.components.skilltreeupdater:IsActivated("wx78_circuitry_betterunplug")
            needsrefresh = true
        elseif data.skill == "wx78_allegiance_shadow" then
            self.has_shadow_affinity = owner.components.skilltreeupdater:IsActivated("wx78_allegiance_shadow")
            if not self.has_shadow_affinity then
				self.bg_bars:UnhookCallback("animover")
				self.bg_bars:GetAnimState():Show("affinity_shadow")
				self.shadow_slot:Hide()
				self.bg_bars:GetAnimState():PlayAnimation("affinity_close")
				self.bg_bars:GetAnimState():PushAnimation("chest_idle", false)
				self.bg_bars:HookCallback("animover", function(ui_inst)
					self.bg_bars:UnhookCallback("animover")
					self.bg_bars:GetAnimState():Hide("affinity_shadow")
                end)
            else
				self.bg_bars:UnhookCallback("animover")
				self.bg_bars:GetAnimState():Show("affinity_shadow")
				self.bg_bars:GetAnimState():PlayAnimation("affinity_open")
				self.bg_bars:GetAnimState():PushAnimation("chest_idle", false)
				self.bg_bars:HookCallback("animover", function(ui_inst)
					self.bg_bars:UnhookCallback("animover")
                    if self.shadow_slot_item_isvalid then
						self.shadow_slot:Show()
                    end
                end)
            end
            needsrefresh = true
        end
        if needsrefresh then
            self:DoFocusHookups()
            self:RefocusChip()
        end
    end
	local function UpdateShadowSocketItem(owner, socketposition, nosound)
		self:CancelAsyncTimeout()

        local wasvalid = self.shadow_slot_item_isvalid
        self.shadow_slot_item_isvalid = nil
        local socketholder = owner.components.socketholder
        if socketholder then
            if socketholder:IsSocketNameForPosition(SOCKETNAMES.SHADOW, socketposition) then
                local socketquality = owner.components.socketholder:GetQualityForPosition(socketposition)
                local animdata = SOCKETQUALITY_TO_ANIMS[SOCKETNAMES.SHADOW][socketquality]
				if animdata and animdata.bank and animdata.build and animdata.idle_anim then
                    self.shadow_slot_item_isvalid = true
					if self.shadow_slot_item_oldanimdata and self.shadow_slot_item_oldanimdata.clearfn then
						self.shadow_slot_item_oldanimdata.clearfn(self)
					end
                    self.shadow_slot_item_oldanimdata = animdata
                    self.shadow_slot_item:GetAnimState():SetBank(animdata.bank)
                    self.shadow_slot_item:GetAnimState():SetBuild(animdata.build)
					if animdata.plug_anim then
						self.shadow_slot_item:GetAnimState():PlayAnimation(animdata.plug_anim)
						self.shadow_slot_item:GetAnimState():PushAnimation(animdata.idle_anim, animdata.loops or false)
					else
						self.shadow_slot_item:GetAnimState():PlayAnimation(animdata.idle_anim, animdata.loops)
					end
					if not nosound and animdata.plug_sound then
						TheFrontEnd:GetSound():PlaySound(animdata.plug_sound)
					end
					if animdata.initfn then
						animdata.initfn(self)
					end
                    self.shadow_slot_item:GetAnimState():Hide("focus")
					self.shadow_slot:Show()
                    if not wasvalid then
                        self:DoFocusHookups()
						if not self:IsBusy() then
							self:RefocusChip()
						end
                    end
                end
            end
        end
        if wasvalid and not self.shadow_slot_item_isvalid then
			if self.shadow_slot_item_oldanimdata then
				if not nosound and self.shadow_slot_item_oldanimdata.unplug_sound then
					TheFrontEnd:GetSound():PlaySound(self.shadow_slot_item_oldanimdata.unplug_sound)
				end
				if self.shadow_slot_item_oldanimdata.clearfn then
					self.shadow_slot_item_oldanimdata.clearfn(self)
				end
			end
			self.shadow_slot_item_oldanimdata = nil
			self.shadow_slot:Hide()
            self:DoFocusHookups()
			if not self:IsBusy() then
				self:RefocusChip(nil, nil, socketposition)
			end
        end
    end
    self.inst:ListenForEvent("onactivateskill_client", OnUpdateSkill, owner)
    self.inst:ListenForEvent("ondeactivateskill_client", OnUpdateSkill, owner)
	self.inst:ListenForEvent("onsocketeddirty1", function() UpdateShadowSocketItem(owner, 1, false) end, owner)
    --

    self.bg = self:AddChild(UIAnim())
    self.bg:GetAnimState():SetBank("status_wx_chest")
    self.bg:GetAnimState():SetBuild("status_wx_chest")
    self.bg:GetAnimState():PlayAnimation("chest_open")
	self.bg:GetAnimState():PushAnimation("chest_idle", false)
    self.bg:GetAnimState():AnimateWhilePaused(false)
    self.bg:GetAnimState():Hide("bars")
    self.bg:GetAnimState():Hide("bars_extended")
	self.bg:GetAnimState():Hide("bg_extended")
	self.bg:GetAnimState():Hide("affinity_shadow")
    self.bg:MoveToBack()

    self.shadow_slot = self.bg:AddChild(Image("images/ui.xml", "white.tex"))
    self.shadow_slot:SetTint(0, 0, 0, 0) -- This is used to normalize the click region to a rectangle only and keeps controller focus hookups.
    self.shadow_slot:SetPosition(-100, 175, 0)
    self.shadow_slot:SetSize(95, 122)
    self.shadow_slot:Hide()
	self.shadow_slot.OnControl = ShadowSlot_OnControl
	self.shadow_slot.OnGainFocus = ShadowSlot_OnGainFocus
	self.shadow_slot.OnLoseFocus = ShadowSlot_OnLoseFocus
    self.shadow_slot_item = self.shadow_slot:AddChild(UIAnim())
    self.shadow_slot_item:SetClickable(false)
    self.shadow_slot_item:GetAnimState():Hide("focus")

    self.bg_bars = self:AddChild(UIAnim())
    self.bg_bars:GetAnimState():SetBank("status_wx_chest")
    self.bg_bars:GetAnimState():SetBuild("status_wx_chest")
    self.bg_bars:GetAnimState():PlayAnimation("chest_open")
	self.bg_bars:GetAnimState():PushAnimation("chest_idle", false)
    self.bg_bars:GetAnimState():AnimateWhilePaused(false)
	self.bg_bars:GetAnimState():Hide("bg")
	self.bg_bars:GetAnimState():Hide("bg_extended")
    self.bg_bars:GetAnimState():Hide("bars_extended")
	if not self.has_shadow_affinity then
		self.bg_bars:GetAnimState():Hide("affinity_shadow")
	end
    self.bg_bars:MoveToFront()

    self.plugs = self:AddChild(UIAnim())
    self.plugs:GetAnimState():SetBank("status_wx_chest")
    self.plugs:GetAnimState():SetBuild("status_wx_chest")
    self.plugs:GetAnimState():Hide("affinity_shadow")
    self.plugs:GetAnimState():PlayAnimation("slot_open")
    self.plugs:GetAnimState():AnimateWhilePaused(false)
    self.plugs:MoveToFront()

    self.chip_objectpools = {}
    self.chip_poolindexes = {}
    self.chip_slotsinuse = {}
    for i, v in pairs(CIRCUIT_BARS) do
        self.chip_objectpools[v] = {}
        for i = 1, MAX_CIRCUIT_SLOTS do
            local chip_object = self:AddChild(UIAnim())
            chip_object:GetAnimState():SetBank("status_wx_chest")
            chip_object:GetAnimState():SetBuild("status_wx_chest")
            chip_object:GetAnimState():AnimateWhilePaused(false)
            chip_object.OnControl = Chip_OnControl
            chip_object.OnGainFocus = Chip_OnGainFocus
            chip_object.OnLoseFocus = Chip_OnLoseFocus
            chip_object.owner = owner
            chip_object.moduletype = v

            chip_object:GetAnimState():Hide("plug_on")
            chip_object:GetAnimState():Hide("glow")
            chip_object:GetAnimState():Hide("plug_symbol")
            chip_object:GetAnimState():Hide("focus")
            chip_object._power_hidden = true

            chip_object:Hide()

            chip_object.glow = self:AddChild(UIAnim())
            chip_object.glow:GetAnimState():SetBank("status_wx_chest")
            chip_object.glow:GetAnimState():SetBuild("status_wx_chest")
            chip_object.glow:GetAnimState():AnimateWhilePaused(false)
            chip_object.glow:GetAnimState():Hide("plug")
            chip_object.glow:GetAnimState():Hide("plug_on")
            chip_object.glow:GetAnimState():Hide("plug_symbol")
            chip_object.glow:GetAnimState():Hide("focus")
            chip_object.glow:Hide()
            chip_object.glow.inst:AddTag("NOCLICK")

            chip_object.symbol = chip_object.glow:AddChild(UIAnim())
            chip_object.symbol:GetAnimState():SetBank("status_wx_chest")
            chip_object.symbol:GetAnimState():SetBuild("status_wx_chest")
            chip_object.symbol:GetAnimState():AnimateWhilePaused(false)
            chip_object.symbol:GetAnimState():Hide("plug")
            chip_object.symbol:GetAnimState():Hide("glow")
            chip_object.symbol:GetAnimState():Hide("plug_on")
            chip_object.symbol:GetAnimState():Hide("focus")
            chip_object.symbol.inst:AddTag("NOCLICK")

            table.insert(self.chip_objectpools[v], chip_object)
        end

        self.chip_slotsinuse[v] = 0
        self.chip_poolindexes[v] = 1
    end

    self.plugs:MoveToFront()
    self.bg_bars:MoveToFront()

    self.energy_backing = self:AddChild(UIAnim())
    self.energy_backing:GetAnimState():SetBank("status_wx_chest")
    self.energy_backing:GetAnimState():SetBuild("status_wx_chest")
    self.energy_backing:GetAnimState():PlayAnimation("energy3_open")
    self.energy_backing:GetAnimState():PushAnimation("energy3")
    self.energy_backing:GetAnimState():AnimateWhilePaused(false)

    self.energy_blinking = self:AddChild(UIAnim())
    self.energy_blinking:GetAnimState():SetBank("status_wx_chest")
    self.energy_blinking:GetAnimState():SetBuild("status_wx_chest")
    self.energy_blinking:GetAnimState():PlayAnimation("energy2_open")
    self.energy_blinking:GetAnimState():PushAnimation("energy2")
    self.energy_blinking:GetAnimState():AnimateWhilePaused(false)

    self.anim = self:AddChild(UIAnim())
    self.anim:GetAnimState():SetBank("status_wx_chest")
    self.anim:GetAnimState():SetBuild("status_wx_chest")
    self.anim:GetAnimState():PlayAnimation("energy1_open")
    self.anim:GetAnimState():PushAnimation("energy1")
    self.anim:GetAnimState():AnimateWhilePaused(false)

    self.energy_nightmare = self:AddChild(UIAnim()) -- timer bar for the nightmare energy buff
    self.energy_nightmare:GetAnimState():SetBank("status_wx")
    self.energy_nightmare:GetAnimState():SetBuild("status_wx")
    self.energy_nightmare:GetAnimState():PlayAnimation("energy_nightmare")
    self.energy_nightmare:GetAnimState():AnimateWhilePaused(false)
    self.energy_nightmare:Hide()
    self.energy_nightmare:SetPosition(152, -85)
    self.energy_nightmare:SetScale(1.25, 1.25)

    self.energy_nightmare_top = self.energy_nightmare:AddChild(UIAnim())
    self.energy_nightmare_top:GetAnimState():SetBank("status_wx")
    self.energy_nightmare_top:GetAnimState():SetBuild("status_wx")
    self.energy_nightmare_top:GetAnimState():PlayAnimation("energy_nightmare_top", true)
    self.energy_nightmare_top:GetAnimState():AnimateWhilePaused(false)

    self.energy_nightmare_glow = self.energy_nightmare:AddChild(UIAnim())
    self.energy_nightmare_glow:GetAnimState():SetBank("status_wx")
    self.energy_nightmare_glow:GetAnimState():SetBuild("status_wx")
    self.energy_nightmare_glow:GetAnimState():PlayAnimation("energy_nightmare_glow", true)
    self.energy_nightmare_glow:GetAnimState():AnimateWhilePaused(false)

    -- Hack :(, we need the mousehandler to render on top of everything else, so add it as a child to controls instead of self
    -- Otherwise, this widget handles mousehandler
    self.mousehandler = controls:AddChild(Widget())
    self.mousehandler:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.inst:ListenForEvent("onremove", function() self.mousehandler:Kill() end) -- Kill ourselves manually on self's lifetime

    self.moduleremover = self.mousehandler:AddChild(UIAnim())
    self.moduleremover:GetAnimState():SetBank("ui_wx78moduleremover")
    self.moduleremover:GetAnimState():SetBuild("ui_wx78moduleremover")
    self.moduleremover:GetAnimState():PlayAnimation("appear")
    self.moduleremover:GetAnimState():PushAnimation("idle", false)
	--self.moduleremover:GetAnimState():AnimateWhilePaused(false)
    self.moduleremover:SetScale(.5, .5)
    self.moduleremover:Hide()
    self.moduleremover.inst:AddTag("NOCLICK")

	if self.owner.wx78_classified then
		self:UpdateEnergyLevel(self.owner.wx78_classified.currentenergylevel:value(), 0, true)
    end
	if self.owner.GetModulesData then
		self:OnModulesDirty(self.owner:GetModulesData(), true)
	end
    self:FollowMouseConstrained()

	self.default_focus = self.chip_objectpools[0][1]
    self:DoFocusHookups()

    self.inst:ListenForEvent("wx78_abilitycooldowns_update", function(_, data) self:UpdateAbilityCooldowns() end, owner)
	self.inst:ListenForEvent("controller_removing_module", function(_, item) self:OnControllerStartRemovingModule(item) end, owner)
	self.inst:ListenForEvent("newactiveitem", function(owner, data) self:OnNewActiveItem(true) end, owner)
	if not TheInput:ControllerAttached() then
		self:OnNewActiveItem()
	elseif owner._controller_start_moduleremover then
		self.inst:DoTaskInTime(0, function(_, item) self:OnControllerStartRemovingModule(item, true) end, owner._controller_start_moduleremover)
		owner._controller_start_moduleremover = nil
	end

	self.inst:ListenForEvent("continuefrompause", function()
		if self.is_using_module_remover and not TheInput:ControllerAttached() then
			local inventory = self.owner.replica.inventory
			local item = inventory and inventory:GetActiveItem()
			if not (item and item:HasActionComponent("upgrademoduleremover")) then
				self:StopControllerRemovingModule()
			end
		end
	end, TheWorld)

    self._overrideenergywithshadow = false
    self:UpdateAbilityCooldowns()
    self:UpdateMaxEnergy(self.max_energy, self.max_energy)

	UpdateShadowSocketItem(owner, 1, true)
end)

function UpgradeModulesDisplay_Inspecting:UpdateAbilityCooldowns()
    local old_override = self._overrideenergywithshadow
    self._overrideenergywithshadow = self.owner.components.wx78_abilitycooldowns:IsInCooldown("shadow_energy") or false
    self:CheckUpdating()

    if old_override ~= self._overrideenergywithshadow then
        if self._overrideenergywithshadow then
            self.energy_nightmare_top:Show()
            self.energy_nightmare:Hide()
            self.energy_nightmare_glow:UnhookCallback("animover")
            self.energy_nightmare_glow:GetAnimState():PlayAnimation("energy_nightmare_glow", true)
            self.energy_backing:Hide()
            self.energy_blinking:Hide()
            self.anim:Hide()
            self.energy_nightmare:Show()
        else
            self.energy_nightmare_glow:GetAnimState():PlayAnimation("energy_nightmare_glow_pst")
            self.energy_nightmare_glow:UnhookCallback("animover")
            self.energy_nightmare_glow:HookCallback("animover", function()
                self.energy_nightmare_top:Show()
                self.energy_nightmare:Hide()
                self.energy_nightmare_glow:UnhookCallback("animover")
                self.energy_nightmare_glow:GetAnimState():PlayAnimation("energy_nightmare_glow", true)
            end)
            self.energy_backing:Show()
            self.energy_blinking:Show()
            self.anim:Show()
            self.energy_nightmare_top:Hide()
        end
    end
end

function UpgradeModulesDisplay_Inspecting:IsBusy()
	return self.busylocks > 0
end

function UpgradeModulesDisplay_Inspecting:AddBusyLock()
	self.busylocks = self.busylocks + 1
end

function UpgradeModulesDisplay_Inspecting:StartAsyncTimeout()
	if self.timeouttask then
		self.timeouttask:Cancel()
	else
		self:AddBusyLock()
	end
	self.timeouttask = self.inst:DoTaskInTime(TIMEOUT, function()
		self.timeouttask = nil
		self:RemoveBusyLock()
	end)
end

function UpgradeModulesDisplay_Inspecting:CancelAsyncTimeout()
	if self.timeouttask then
		self.timeouttask:Cancel()
		self.timeouttask = nil
		self:RemoveBusyLock()
	end
end

function UpgradeModulesDisplay_Inspecting:RemoveBusyLock()
	self.busylocks = self.busylocks - 1
	if self.busylocks < 0 then
		assert(BRANCH ~= "dev")
		self.busylocks = 0
	end
	return self.busylocks == 0
end

function UpgradeModulesDisplay_Inspecting:ControllerSetFocus(focus)
	if focus then
		if TheInput:ControllerAttached() then
			TheFrontEnd:StopTrackingMouse()
			self.controllerfocuslock = true
			TheFrontEnd:LockFocus(true)
			self:DoFocusHookups()
			for bartype = 0, #self.chip_objectpools do
				local index = self.chip_poolindexes[bartype]
				if index > 1 then
					local chip = self.chip_objectpools[bartype][index - 1]
					if not chip.focus then
						chip:SetFocus()
					else
						self:OnChipGainFocus(chip)
					end
					return
				end
			end
			if self.shadow_slot_item_isvalid then
				if not self.shadow_slot.focus then
					self.shadow_slot:SetFocus()
				else
					self.shadow_slot:OnGainFocus()
				end
			end
		end
	elseif self.controllerfocuslock then
		self.controllerfocuslock = nil
		TheFrontEnd:LockFocus(false)
	end
end

function UpgradeModulesDisplay_Inspecting:HasInputFocus()
	return self.is_using_module_remover and TheInput:ControllerAttached()
end

-------------------------------------------------------------

function UpgradeModulesDisplay_Inspecting:IsExtended()
    return self.max_energy >= 7
end

function UpgradeModulesDisplay_Inspecting:UpdateSlotCount()
    if self:IsExtended() then
        self.energy_nightmare:SetScale(1.25, 1.25 * EXTENDED_SCALE_Y)
        self.energy_nightmare:SetPosition(152, -72)
		self.bg:GetAnimState():Hide("bg")
		self.bg:GetAnimState():Show("bg_extended")

        self.bg_bars:GetAnimState():Hide("bars")
        self.bg_bars:GetAnimState():Show("bars_extended")
    else
        self.energy_nightmare:SetScale(1.25, 1.25)
        self.energy_nightmare:SetPosition(152, -85)
		self.bg:GetAnimState():Show("bg")
		self.bg:GetAnimState():Hide("bg_extended")

        self.bg_bars:GetAnimState():Show("bars")
        self.bg_bars:GetAnimState():Hide("bars_extended")
    end
end

-------------------------------------------------------------

local BASE_TOOLTIP_Y_OFFSET = 140
local TOOLTIP_Y_DESTINATION = 40 -- usual offset
local DELAY_DISAPPEAR_TOOLTIP_LERP = 7 * FRAMES
local DELAY_APPEAR_TOOLTIP_LERP = 10 * FRAMES
function UpgradeModulesDisplay_Inspecting:GetToolTipYOffset()
    local y_offset = BASE_TOOLTIP_Y_OFFSET

    if self.moduleremover:GetAnimState():IsCurrentAnimation("appear") then
        local anim_time = math.min(DELAY_APPEAR_TOOLTIP_LERP, self.moduleremover:GetAnimState():GetCurrentAnimationTime())
        local anim_length = DELAY_APPEAR_TOOLTIP_LERP
        y_offset = easing.outCubic( anim_time, TOOLTIP_Y_DESTINATION, BASE_TOOLTIP_Y_OFFSET - TOOLTIP_Y_DESTINATION, anim_length)
    elseif self.moduleremover:GetAnimState():IsCurrentAnimation("disappear") then
        local anim_time = self.moduleremover:GetAnimState():GetCurrentAnimationTime()
        if anim_time >= DELAY_DISAPPEAR_TOOLTIP_LERP then
            anim_time = anim_time - DELAY_DISAPPEAR_TOOLTIP_LERP
            local anim_length = self.moduleremover:GetAnimState():GetCurrentAnimationLength() - DELAY_DISAPPEAR_TOOLTIP_LERP
            y_offset = easing.outCubic( anim_time, BASE_TOOLTIP_Y_OFFSET, TOOLTIP_Y_DESTINATION - BASE_TOOLTIP_Y_OFFSET, anim_length)
        end
    end

    return y_offset
end

function UpgradeModulesDisplay_Inspecting:OnLoseFocus()
	if self.is_using_module_remover and TheInput:ControllerAttached() then
		self:ToggleUsingModuleRemover(nil)
		self:OverrideModuleRemoverPositionAndSpeed(nil, nil, nil)
	end
end

function UpgradeModulesDisplay_Inspecting:OnGainFocus()
	if not self.is_using_module_remover and TheInput:ControllerAttached() then
		--coming back from pause menu?
		self.inst:DoStaticTaskInTime(0, function(inst)
			if not self.is_using_module_remover and TheInput:ControllerAttached() then
				self:ClearFocus()
			end
		end)
	end
end

function UpgradeModulesDisplay_Inspecting:StopControllerRemovingModule()
	self:ToggleUsingModuleRemover(nil)
	self:ClearFocus()
	self:OverrideModuleRemoverPositionAndSpeed(nil, nil, nil)
end

function UpgradeModulesDisplay_Inspecting:OnControllerStartRemovingModule(item, nosound)
	if item and item:HasActionComponent("upgrademoduleremover") then
		for _, v in pairs(self.chip_slotsinuse) do
			if v > 0 then
				--Found at lease one circuit
				self:ToggleUsingModuleRemover(item)
				return
			end
		end
	end
	if self.shadow_slot_item_isvalid then
		self:ToggleUsingModuleRemover(item)
		return
	end
	if not nosound then
		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_negative")
	end
end

function UpgradeModulesDisplay_Inspecting:OnNewActiveItem(force_anim)
	--NOTE: controllers do use "activeitem" system in the controller inverntory screen, so still need to check for controllers to block that
	if not TheInput:ControllerAttached() then
		local inventory = self.owner.replica.inventory
		local item = inventory and inventory:GetActiveItem()
		self:ToggleUsingModuleRemover(item and item:HasActionComponent("upgrademoduleremover") and item or nil, force_anim)
	else
		--possible to reach here when clearing active item when switching to controllers from options screen
		self:StopControllerRemovingModule()
	end
end

function UpgradeModulesDisplay_Inspecting:ToggleUsingModuleRemover(item, force_anim)
	if item then
		if not self.is_using_module_remover or force_anim then
            self.moduleremover:GetAnimState():PlayAnimation("appear")
            self.moduleremover:GetAnimState():PushAnimation("idle", false)
			self:UpdateModuleRemoverBuild(item)
        end
        self.moduleremover:Show()
		if self.moduleremover:HasCallback("animover") then
			self.moduleremover:UnhookCallback("animover")
			self:RemoveBusyLock()
			assert(self.moduleremover.animovertask == nil or BRANCH ~= "dev")
		elseif self.moduleremover.animovertask then
			self.moduleremover.animovertask:Cancel()
			self.moduleremover.animovertask = nil
			self:RemoveBusyLock()
		end
        self.owner:PushEvent("sethovertilehidemodifier", { source = self.inst, hidden = true} )

        TheFrontEnd:GetSound():PlaySound("WX_rework/module_tray/toolclick")

        local function GetTooltipPos(controls, hoverer)
            local hoverer_s = hoverer:GetScale()
            local hoverer_pos = hoverer:GetPosition()

            local mouse_s = hoverer_s
            local mouse_pos = self.mousehandler:GetPosition()

            return Vector3(
                    (mouse_pos.x / mouse_s.x - hoverer_pos.x / hoverer_s.x),
                    (mouse_pos.y / mouse_s.y - hoverer_pos.y / hoverer_s.y + self:GetToolTipYOffset())
                )
        end
        self.controls:OverrideTooltipPos(GetTooltipPos)
        self.controls.hover:ForceSettleTextPositionOnMove(true)
        self.is_using_module_remover = true
		self:ControllerSetFocus(true)
    else
        if self.moduleremover.shown then
            TheFrontEnd:GetSound():PlaySound("WX_rework/module_tray/toolclick")
            self.moduleremover:GetAnimState():PlayAnimation("disappear")

			if not self.moduleremover:HasCallback("animover") then
				if self.moduleremover.animovertask then
					self.moduleremover.animovertask:Cancel()
					self.moduleremover.animovertask = nil
				else
					self:AddBusyLock()
				end
			end
            self.moduleremover:HookCallback("animover", function(chip_ui_inst)
				self.moduleremover:UnhookCallback("animover")
				assert(self.moduleremover.animovertask == nil or BRANCH ~= "dev")
				self:RemoveBusyLock()
                self.controls:OverrideTooltipPos(nil)
                self.controls.hover:ForceSettleTextPositionOnMove(nil)
                self.moduleremover:Hide()
            end)
        end
        self.owner:PushEvent("sethovertilehidemodifier", { source = self.inst, hidden = false})
        self.is_using_module_remover = false
		self:ControllerSetFocus(false)
    end
end

function UpgradeModulesDisplay_Inspecting:UpdateModuleRemoverBuild(moduleremover)
    local build = moduleremover.AnimState:GetBuild()
	local skin_build = moduleremover.AnimState:GetSkinBuild()

	if skin_build and string.len(skin_build) > 0 then
		self.moduleremover:GetAnimState():OverrideItemSkinSymbol("wx78_moduleremover01", skin_build, "wx78_moduleremover01", moduleremover.GUID, build)
	else
		self.moduleremover:GetAnimState():OverrideSymbol("wx78_moduleremover01", build, "wx78_moduleremover01")
	end
end

-- Charge Displaying -----------------------------------------------------------

function UpgradeModulesDisplay_Inspecting:UpdateChipCharges(plugging_in, skipsound)
    for bartype, index in pairs(self.chip_poolindexes) do
        if index > 1 then
            local charge = self.energy_level
            local objectpool = self.chip_objectpools[bartype]
            for i = 1, index - 1 do
                local chip = objectpool[i]

                charge = charge - chip._used_modslots
                if charge < 0 and not chip._power_hidden then
                    if not plugging_in then
                        self:PlayChipAnimation(chip, "chip_off")
                        chip:GetAnimState():PlayAnimation("chip_off")
                        chip:HookCallback("animover", function(chip_ui_inst)
                            self:EnableChipGlow(chip, false)
                            self:PlayChipAnimation(chip, "chip_idle")
                            chip:UnhookCallback("animover")
                        end)
                    else
                        self:EnableChipGlow(chip, false)
                    end
                    chip._power_hidden = true

                    if not skipsound then
                        TheFrontEnd:GetSound():PlaySound("WX_rework/tube/HUD_off")
                    end
                elseif charge >= 0 and chip._power_hidden then
                    -- In case we changed charge before the power off animation finished.
                    chip:UnhookCallback("animover")

                    self:EnableChipGlow(chip, true)
                    if not plugging_in then
                        self:PlayChipAnimation(chip, "chip_on")
                        self:PushChipAnimation(chip, "chip_idle")
                    end
                    chip._power_hidden = false

                    if not skipsound then
                        TheFrontEnd:GetSound():PlaySound("WX_rework/tube/HUD_on")
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------------------

function UpgradeModulesDisplay_Inspecting:UpdateMaxEnergy(new_level, old_level)
    self.max_energy = new_level

    for i = 1, MAX_CIRCUIT_SLOTS do
        local slotn = "slot"..tostring(i)
        if i > new_level then
            self.anim:GetAnimState():Hide(slotn)
            self.energy_blinking:GetAnimState():Hide(slotn)
            self.energy_backing:GetAnimState():Hide(slotn)
            self.plugs:GetAnimState():Hide(slotn)
            self.plugs:GetAnimState():Hide(slotn.."_off")
        else
            self.anim:GetAnimState():Show(slotn)
            self.energy_blinking:GetAnimState():Show(slotn)
            self.energy_backing:GetAnimState():Show(slotn)
            -- UpdateEnergyLevel will fix these up.
            -- self.plugs:GetAnimState():Show(slotn)
            -- self.plugs:GetAnimState():Show(slotn.."_off")
        end
    end

    self:UpdateEnergyLevel(self.energy_level, self.energy_level, true)
    self:UpdateSlotCount()

    -- Pop off extra modules over the new limit
    local first = true
    for bartype, objectpool in pairs(self.chip_objectpools) do
        local remaining_level = self.max_energy
        for i, chip in ipairs(objectpool) do
            while chip ~= nil do
                if chip.chip_pos then
                    remaining_level = remaining_level - chip._used_modslots
                    if remaining_level < 0 then
                        self:PopOneModule(bartype)
                        chip = objectpool[i]

                        if first then
                            TheFrontEnd:GetSound():PlaySound("WX_rework/tube/HUD_out")
                            first = false
                        end
                    else
                        chip = nil
                    end
                else
                    chip = nil
                end
            end
        end
    end
end

function UpgradeModulesDisplay_Inspecting:UpdateEnergyLevel(new_level, old_level, skipsound)
    self.energy_level = new_level

    for i = 1, self.max_energy do
        local slotn = "slot"..tostring(i)

        if i > new_level then
            self.anim:GetAnimState():Hide(slotn)
            self.plugs:GetAnimState():Hide(slotn)
            self.plugs:GetAnimState():Show(slotn.."_off")
        else
            self.anim:GetAnimState():Show(slotn)
            self.plugs:GetAnimState():Show(slotn)
            self.plugs:GetAnimState():Hide(slotn.."_off")
        end

        if i == new_level + 1 then
            self.energy_blinking:GetAnimState():Show(slotn)
        else
            self.energy_blinking:GetAnimState():Hide(slotn)
        end
    end

    -- Change which level our yellow "charging" UI is at.
    if self.energy_blinking._flicker_task ~= nil then
        self.energy_blinking._flicker_task:Cancel()
        self.energy_blinking._flicker_task = nil
    end
    if new_level < self.max_energy then
        self.energy_blinking._flicker_alternator = false
        self.energy_blinking._flicker_task = self.inst:DoSimPeriodicTask(
            25*FRAMES,
            function(ui_inst)
                if self.energy_blinking._flicker_alternator then
                    self.energy_blinking:GetAnimState():PlayAnimation("energy2")
                else
                    self.energy_blinking:GetAnimState():PlayAnimation("energy2b")
                end
                self.energy_blinking._flicker_alternator = not self.energy_blinking._flicker_alternator
            end,
            10*FRAMES
        )
    end

    if not skipsound then
        if new_level > old_level then
            TheFrontEnd:GetSound():PlaySound("WX_rework/charge/up")
        elseif new_level < old_level then
            TheFrontEnd:GetSound():PlaySound("WX_rework/charge/down")
        end
    end

    self:UpdateChipCharges(false)
end

--------------------------------------------------------------------------------

function UpgradeModulesDisplay_Inspecting:GetChipXOffset(chiptypeindex)
    if chiptypeindex == CIRCUIT_BARS.ALPHA then
        return -94
    elseif chiptypeindex == CIRCUIT_BARS.BETA then
        return -3
    elseif chiptypeindex == CIRCUIT_BARS.GAMMA then
        return 128
    end
end

function UpgradeModulesDisplay_Inspecting:GetChipYOffset(chiptypeindex)
    if chiptypeindex == CIRCUIT_BARS.ALPHA then
        return -148
    elseif chiptypeindex == CIRCUIT_BARS.BETA then
        return 26
    elseif chiptypeindex == CIRCUIT_BARS.GAMMA then
        return 132
    end
end

function UpgradeModulesDisplay_Inspecting:OnModuleAdded(bartype, moduledefinition_index, init)
    local module_def = GetModuleDefinitionFromNetID(moduledefinition_index)
    if module_def == nil then
        return
    end
    bartype = bartype or module_def.type

    local modname = module_def.name
    local modslots = module_def.slots

    local objectpool = self.chip_objectpools[bartype]
    local chip_index = self.chip_poolindexes[bartype]
    local new_chip = objectpool[chip_index]
    self.chip_poolindexes[bartype] = self.chip_poolindexes[bartype] + 1

    if init then
        self:PlayChipAnimation(new_chip, "chip_idle")
    else
        self:PlayChipAnimation(new_chip, "plug")
        self:PushChipAnimation(new_chip, "chip_idle")
    end

    local overridebuild = module_def.overrideuibuild or "status_wx_chest"
    new_chip:GetAnimState():OverrideSymbol("movespeed2_chip", overridebuild, modname.."_chip")
    new_chip.glow:GetAnimState():OverrideSymbol("movespeed2_chip", overridebuild, modname.."_chip")
    new_chip.symbol:GetAnimState():OverrideSymbol("movespeed2_chip", overridebuild, modname.."_chip")
    new_chip.modulename = modname
    new_chip.overridebuild = overridebuild

    new_chip.chip_index = chip_index
    new_chip._used_modslots = modslots
    new_chip._net_id = moduledefinition_index

    local slot_distance_from_bottom = self.chip_slotsinuse[bartype] + (modslots - 1) * 0.5
    local y_pos = (slot_distance_from_bottom * 20) - 50
    self:SetChipPosition(new_chip, self:GetChipXOffset(bartype), y_pos + self:GetChipYOffset(bartype))

    new_chip:Show()

    self.chip_slotsinuse[bartype] = self.chip_slotsinuse[bartype] + modslots
end

local CHIP_MOVE_FRAMES = 13 * FRAMES
local START_MOVING_FRAME_DELAY = 3 * FRAMES
local MOVE_TIME = 5 * FRAMES
function UpgradeModulesDisplay_Inspecting:PopModuleAtIndex(bartype, startindex)
    local objectpool = self.chip_objectpools[bartype]
    local falling_chip = objectpool[startindex]

    self.chip_poolindexes[bartype] = self.chip_poolindexes[bartype] - 1
    self.chip_slotsinuse[bartype] = self.chip_slotsinuse[bartype] - falling_chip._used_modslots
    self:DropChip(falling_chip)

    local x_offset = self:GetChipXOffset(bartype)
    local y_offset = self:GetChipYOffset(bartype)

    local num_modules_moving = 0
    local slotsinuse = -falling_chip._used_modslots
    for i = 1, #objectpool do
		local prevchip = objectpool[i-1]
        local chip = objectpool[i]
        if i >= startindex + 1 then
            if chip.chip_pos then
                local start_pos = chip:GetPosition()
                local slot_distance_from_bottom = slotsinuse + (chip._used_modslots - 1) * 0.5
                local y_pos = (slot_distance_from_bottom * 20) - 50
                local pos = Vector3(x_offset, y_pos + y_offset)
				self:SetChipPosition(prevchip, pos.x, pos.y)
                self:PlayChipAnimation(chip, "chip_move")

                num_modules_moving = num_modules_moving + 1

                chip.inst:DoTaskInTime(START_MOVING_FRAME_DELAY, function()
                    chip:CancelMoveTo()
                    chip:MoveTo(start_pos, pos, MOVE_TIME)
                    self:EnableChipGlow(chip, false)
                end)
            end
        end
        slotsinuse = slotsinuse + (chip._used_modslots or 0)
    end

    TheFrontEnd:GetSound():PlaySoundWithParams("WX_rework/module_tray/module_movedown", { num_modules = num_modules_moving })

	self:AddBusyLock()
    self.inst:DoTaskInTime(CHIP_MOVE_FRAMES, function()
        slotsinuse = 0
        for i = 1, #objectpool do
            local chip = objectpool[i]
            local nextchip = objectpool[i + 1]
            if i >= startindex and nextchip then
                if nextchip.chip_pos then
                    chip._used_modslots = nextchip._used_modslots
                    chip._net_id = nextchip._net_id
                    chip.modulename = nextchip.modulename
                    chip.overridebuild = nextchip.overridebuild
                    chip.chip_index = chip.old_chip_index or chip.chip_index
                    chip._power_hidden = true

                    chip:GetAnimState():OverrideSymbol("movespeed2_chip", chip.overridebuild, chip.modulename.."_chip")
                    chip.glow:GetAnimState():OverrideSymbol("movespeed2_chip", chip.overridebuild, chip.modulename.."_chip")
                    chip.symbol:GetAnimState():OverrideSymbol("movespeed2_chip", chip.overridebuild, chip.modulename.."_chip")

                    local pos = nextchip:GetPosition()
                    self:SetChipPosition(chip, pos.x, pos.y)
                    self:PlayChipAnimation(chip, "chip_idle")

                    chip:Show()
                    nextchip:Hide()

                    nextchip.chip_pos = nil
                end
            end
            slotsinuse = slotsinuse + (chip and chip._used_modslots or 0)
        end

        self:DoFocusHookups()
        self:UpdateChipCharges(true)
		if self:RemoveBusyLock() then
			self:RefocusChip(bartype, startindex)
		end
    end)
end

function UpgradeModulesDisplay_Inspecting:OnModulesDirty(modules_data, init)
	self:CancelAsyncTimeout()

    local first = not init
    local function PlayFirstSound(soundpath)
        if first then
            TheFrontEnd:GetSound():PlaySound(soundpath)
            first = false
        end
    end

    for bartype, modules in pairs(modules_data) do
        local oldmodules = self._oldmodulesdata ~= nil and self._oldmodulesdata[bartype] or nil
        for i, module_index in ipairs(modules) do
            local oldmodule_index = oldmodules ~= nil and oldmodules[i] or 0

            -- Plugged a circuit
            if module_index ~= 0 and i == self.chip_poolindexes[bartype] then
                self:OnModuleAdded(bartype, module_index, init)
                PlayFirstSound("WX_rework/tube/HUD_in")
            -- Popped the top module
            elseif module_index == 0 and i == (self.chip_poolindexes[bartype] - 1) then
                self:PopOneModule(bartype)
                PlayFirstSound("WX_rework/tube/HUD_out")
            -- Unplugged a circuit in the middle
            elseif module_index ~= 0 and oldmodule_index ~= 0 and module_index ~= oldmodule_index then
                self:PopModuleAtIndex(bartype, i)
                PlayFirstSound("WX_rework/tube/HUD_out")
                break -- We can stop here for the module bar.
            end
        end
    end

    self._oldmodulesdata = modules_data
    self:UpdateChipCharges(true, init)
    self:DoFocusHookups()
	if not self:IsBusy() then
		self:RefocusChip()
	end
end

function UpgradeModulesDisplay_Inspecting:DropChip(falling_chip)
    falling_chip:HookCallback("animover", function(ui_inst)
        self:EnableChipGlow(falling_chip, false)
        falling_chip._power_hidden = true
        falling_chip:Hide()
        falling_chip.inst:RemoveTag("NOCLICK")
        falling_chip:UnhookCallback("animover")
    end)

    falling_chip.old_chip_index = falling_chip.chip_index
    falling_chip.chip_index = nil
    falling_chip.chip_pos = nil
    falling_chip:ClearFocus()
    falling_chip.inst:AddTag("NOCLICK")

    self:PlayChipAnimation(falling_chip, "chip_fall")
end

function UpgradeModulesDisplay_Inspecting:PopOneModule(bartype)
    local objectpool = self.chip_objectpools[bartype]
	local index = self.chip_poolindexes[bartype] - 1
	local falling_chip = objectpool[index]

	self.chip_poolindexes[bartype] = index
    self.chip_slotsinuse[bartype] = self.chip_slotsinuse[bartype] - falling_chip._used_modslots
    self:DropChip(falling_chip)

	if not self:IsBusy() then
		self:RefocusChip(bartype, index)
	end
end

--V2C: Very misleading, but this is a network callback like OnModulesDirty,
--     NOT an internal function like PopOneModule or PopModuleAtIndex.
function UpgradeModulesDisplay_Inspecting:PopAllModules()
	self:CancelAsyncTimeout()

    local play_sound = false

    for bartype, pool in pairs(self.chip_objectpools) do
        if self.chip_poolindexes[bartype] > 1 then
            play_sound = true

            while self.chip_poolindexes[bartype] > 1 do
                self.chip_poolindexes[bartype] = self.chip_poolindexes[bartype] - 1
                self:DropChip(pool[self.chip_poolindexes[bartype]])
            end
        end
    end

    if play_sound then
        TheFrontEnd:GetSound():PlaySound("WX_rework/tube/HUD_out")
    end

    for bartype, slots in pairs(self.chip_slotsinuse) do
        self.chip_slotsinuse[bartype] = 0
    end

	if not self:IsBusy() then
		self:DoFocusHookups()
		self:RefocusChip()
	end
end

function UpgradeModulesDisplay_Inspecting:PlayChipAnimation(chip, anim, loop)
    loop = loop or nil
    chip:GetAnimState():PlayAnimation(anim, loop)
    if chip.glow then
        chip.glow:GetAnimState():PlayAnimation(anim, loop)
    end
    if chip.symbol then
        chip.symbol:GetAnimState():PlayAnimation(anim, loop)
    end
end

function UpgradeModulesDisplay_Inspecting:PushChipAnimation(chip, anim, loop)
    loop = loop or nil
    chip:GetAnimState():PushAnimation(anim, loop)
    if chip.glow then
        chip.glow:GetAnimState():PushAnimation(anim, loop)
    end
    if chip.symbol then
        chip.symbol:GetAnimState():PushAnimation(anim, loop)
    end
end

function UpgradeModulesDisplay_Inspecting:SetChipPosition(chip, x, y, z)
    chip.chip_pos = Vector3(x, y, z)
    chip:SetPosition(x, y, z)
    if chip.glow then
        chip.glow:SetPosition(x, y, z)
    end
end

function UpgradeModulesDisplay_Inspecting:EnableChipGlow(chip, enable)
    if enable then
        chip.glow:Show()
    else
        chip.glow:Hide()
    end
end

function UpgradeModulesDisplay_Inspecting:Close()
    self.owner:PushEvent("sethovertilehidemodifier", { source = self.inst, hidden = false })
    self.controls:OverrideTooltipPos(nil)
	self:ControllerSetFocus(false)
    self:Kill()
end

function UpgradeModulesDisplay_Inspecting:ResolveUnplugModuleIndex(moduletype, moduleindex)
    if not self.can_unplug_any then
        moduleindex = self.chip_poolindexes[moduletype] - 1
    else
        -- If we're unplugging the same circuit as another one above us. forward to that one instead.
        -- Since we rely on net id's we unplug the top circuit if its the same type as the one we actually unplugged
        -- So just forward it to that one anwyways
        local original_chip = self.chip_objectpools[moduletype][moduleindex]
        for i = moduleindex + 1, self.chip_poolindexes[moduletype] - 1 do
            local nextchip = self.chip_objectpools[moduletype][i]
            if nextchip and nextchip._net_id == original_chip._net_id then
                moduleindex = i
            else
                break
            end
        end
    end

    return moduleindex
end

local MODULE_REMOVER_OFFSET = Vector3(-25, 0, 0)
local SHADOW_SLOT_MODULE_REMOVER_OFFSET = Vector3(0, 0, 0)
function UpgradeModulesDisplay_Inspecting:GetModuleRemoverPosition(chip)
    local w, h = TheSim:GetScreenSize()
    local res_scale = w / RESOLUTION_X
	local offset = chip == self.shadow_slot and SHADOW_SLOT_MODULE_REMOVER_OFFSET or MODULE_REMOVER_OFFSET
	return chip:GetWorldPosition() + offset * res_scale
end

local NO_UNPLUG_DELAY = 4 * FRAMES
function UpgradeModulesDisplay_Inspecting:UnplugShadowSlot()
	if self.is_using_module_remover and self.shadow_slot_item_isvalid and not self:IsBusy() then
		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
		self.moduleremover:GetAnimState():PlayAnimation("unplug_shadow")
		self.moduleremover:GetAnimState():PushAnimation("idle", false)

		if not self.moduleremover:HasCallback("animover") then
			if self.moduleremover.animovertask then
				self.moduleremover.animovertask:Cancel()
				self.moduleremover.animovertask = nil
			else
				self:AddBusyLock()
			end
		end
		self.moduleremover:HookCallback("animover", function(ui_inst)
			self.moduleremover:UnhookCallback("animover")
			if self.moduleremover.animovertask then
				self.moduleremover.animovertask:Cancel()
				assert(BRANCH ~= "dev")
			end
			self.moduleremover.animovertask = self.moduleremover.inst:DoTaskInTime(NO_UNPLUG_DELAY, function()
				self.moduleremover.animovertask = nil
				if self:RemoveBusyLock() then
					self:RefocusChip(nil, nil, 1)
				end
			end)
		end)

		local pos = self:GetModuleRemoverPosition(self.shadow_slot)
		self:OverrideModuleRemoverPositionAndSpeed(pos.x, pos.y, 0.3)

		local socketholder = self.owner.components.socketholder --exists on clients
		if socketholder and socketholder:IsSocketNameForPosition(SOCKETNAMES.SHADOW, 1) then
			self:StartAsyncTimeout()
			socketholder:TryToUnsocket(1)
		end
	end
end

function UpgradeModulesDisplay_Inspecting:UnplugModule(moduletype, moduleindex)
	if self.is_using_module_remover and not self:IsBusy() then
        moduleindex = self:ResolveUnplugModuleIndex(moduletype, moduleindex)
        local chip = self.chip_objectpools[moduletype][moduleindex]

        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        self.moduleremover:GetAnimState():PlayAnimation("unplug")
        self.moduleremover:GetAnimState():PushAnimation("idle", false)

		if not self.moduleremover:HasCallback("animover") then
			if self.moduleremover.animovertask then
				self.moduleremover.animovertask:Cancel()
				self.moduleremover.animovertask = nil
			else
				self:AddBusyLock()
			end
		end
        self.moduleremover:HookCallback("animover", function(ui_inst)
			self.moduleremover:UnhookCallback("animover")
			if self.moduleremover.animovertask then
				self.moduleremover.animovertask:Cancel()
				assert(BRANCH ~= "dev")
			end
			self.moduleremover.animovertask = self.moduleremover.inst:DoTaskInTime(NO_UNPLUG_DELAY, function()
				self.moduleremover.animovertask = nil
				if self:RemoveBusyLock() then
					self:RefocusChip(moduletype, moduleindex)
				end
            end)
        end)

        local pos = self:GetModuleRemoverPosition(chip)
        self:OverrideModuleRemoverPositionAndSpeed(pos.x, pos.y, .3)

		if self.owner.UnplugModule then
			self:StartAsyncTimeout()
			self.owner:UnplugModule(moduletype, moduleindex)
		end
    end
end

function UpgradeModulesDisplay_Inspecting:ResolveChip(chip)
    local moduletype = chip.moduletype
    if not self.can_unplug_any then
        local objectpool = self.chip_objectpools[moduletype]
        local chip_index = self.chip_poolindexes[moduletype] - 1
        if objectpool[chip_index] then
            return objectpool[chip_index], true
        end
    else
        -- If we're unplugging the same circuit as another one above us. forward to that one instead.
        -- Since we rely on net id's we unplug the top circuit if its the same type as the one we actually unplugged
        -- So just forward it to that one anwyways
        local moduleindex = chip.chip_index or chip.old_chip_index
        for i = moduleindex + 1, self.chip_poolindexes[moduletype] - 1 do
            local nextchip = self.chip_objectpools[moduletype][i]
            if nextchip and nextchip._net_id == chip._net_id then
                moduleindex = i
            else
                break
            end
        end

        if moduleindex ~= chip.chip_index then
            return self.chip_objectpools[moduletype][moduleindex] -- don't pass true for redirected even though we totally did :) we don't want the UNPLUG_TOP_CIRCUIT tooltip
        end
    end

    return chip
end

function UpgradeModulesDisplay_Inspecting:SetChipTooltip(chip, redirected)
	chip:SetTooltip(STRINGS.UI.UPGRADEMODULEDISPLAY[redirected and "UNPLUG_TOP_CIRCUIT" or "UNPLUG_CIRCUIT"])
end

function UpgradeModulesDisplay_Inspecting:IsChipValidToFocus(chip)
    return not chip:GetAnimState():IsCurrentAnimation("chip_fall") and not chip:GetAnimState():IsCurrentAnimation("chip_move")
end

function UpgradeModulesDisplay_Inspecting:IsChipFocused(chip)
    return chip.focus_sources and chip.focus_sources:Get() or false
end

function UpgradeModulesDisplay_Inspecting:SetChipFocusSource(chip, bool, source, redirected)
    if not chip.focus_sources then
        chip.focus_sources = SourceModifierList(chip.inst, false, SourceModifierList.boolean)
    end
    chip.focus_sources:SetModifier(source, bool, source)
    if chip.focus_sources:Get() then
		if not self:IsBusy() then
            local pos = self:GetModuleRemoverPosition(chip)
            self:OverrideModuleRemoverPositionAndSpeed(pos.x, pos.y, 0.2)
        end
        self:SetChipTooltip(chip, redirected)
        if self:IsChipValidToFocus(chip) then
            chip:GetAnimState():Show("focus")
        end
    else
		if not self:IsBusy() then
			local no_other_focus = true
			for bartype, index in pairs(self.chip_poolindexes) do
				local objectpool = self.chip_objectpools[bartype]
				for i = 1, index - 1 do
					local otherchip = objectpool[i]
					if otherchip.focus_sources and otherchip.focus_sources:Get() then
						no_other_focus = false
						break
					end
				end
			end
			if self.shadow_slot.focus then
				no_other_focus = false
			end
			if no_other_focus then
				self:OverrideModuleRemoverPositionAndSpeed(nil, nil, 0.25)
			end
		end
        chip:SetTooltip(nil)
		chip:GetAnimState():Hide("focus")
    end
end

function UpgradeModulesDisplay_Inspecting:SetShadowSlotFocus(focus)
	if focus then
		if not self:IsBusy() then
			local pos = self:GetModuleRemoverPosition(self.shadow_slot)
			self:OverrideModuleRemoverPositionAndSpeed(pos.x, pos.y, 0.2)
		end
		self.shadow_slot:SetTooltip(STRINGS.UI.UPGRADEMODULEDISPLAY.UNSOCKET)
        if self.shadow_slot_item_isvalid then
            self.shadow_slot_item:GetAnimState():Show("focus")
			if self.shadow_slot_item.focuschildren then
				for _, v in ipairs(self.shadow_slot_item.focuschildren) do
					v:GetAnimState():Show("focus")
				end
			end
        end
	else
		if not self:IsBusy() then
			local no_other_focus = true
			for bartype, index in pairs(self.chip_poolindexes) do
				local objectpool = self.chip_objectpools[bartype]
				for i = 1, index - 1 do
					local otherchip = objectpool[i]
					if otherchip.focus_sources and otherchip.focus_sources:Get() then
						no_other_focus = false
						break
					end
				end
			end
			if no_other_focus  then
				self:OverrideModuleRemoverPositionAndSpeed(nil, nil, 0.25)
			end
		end
		self.shadow_slot:SetTooltip(nil)
        if self.shadow_slot_item_isvalid then
            self.shadow_slot_item:GetAnimState():Hide("focus")
			if self.shadow_slot_item.focuschildren then
				for _, v in ipairs(self.shadow_slot_item.focuschildren) do
					v:GetAnimState():Hide("focus")
				end
			end
        end
	end
end

--NOTE: moduletype, moduleindex, unsockposition for the LAST REMOVED module or shadowslot, used by controller version only
function UpgradeModulesDisplay_Inspecting:RefocusChip(moduletype, moduleindex, unsocketposition)
	local focused_chip
	for _, objectpool in pairs(self.chip_objectpools) do
		for _, chip in ipairs(objectpool) do
			if chip.focus_sources then
				chip.focus_sources:Reset()
			end
			chip:SetTooltip(nil)
			chip:GetAnimState():Hide("focus")
			if chip.focus then
				focused_chip = chip
			end
		end
	end

	self.shadow_slot:SetTooltip(nil)

	if TheInput:ControllerAttached() then
		if self.is_using_module_remover then
			if moduletype == nil then
				--skill changed? removed shadow_slot_item?
				moduletype = focused_chip and focused_chip.moduletype
				if moduletype == nil then
					if self.shadow_slot_item_isvalid and self.shadow_slot.focus then
						self.shadow_slot:OnGainFocus()
						return
					else
						local barorder = {}
						if unsocketposition then
							--just unsocketed shadow slot
							for bartype = #self.chip_objectpools - 1, 0, -1 do
								table.insert(barorder, bartype)
							end
							table.insert(barorder, #self.chip_objectpools)
						else
							for bartype = 0, #self.chip_objectpools do
								table.insert(barorder, bartype)
							end
						end
						for _, bartype in ipairs(barorder) do
							local index = self.chip_poolindexes[bartype]
							if index > 1 then
								local chip = self.chip_objectpools[bartype][index - 1]
								if not chip.focus then
									chip:SetFocus()
								else
									self:OnChipGainFocus(chip)
								end
								return
							end
						end
					end
					if self.shadow_slot_item_isvalid then
						self.shadow_slot:SetFocus()
					elseif not self:IsBusy() then
						self:StopControllerRemovingModule()
					end
					return
				end
			end

			local newchip
			if focused_chip and focused_chip.moduletype ~= moduletype then
				newchip = focused_chip
			else
				local index = self.chip_poolindexes[moduletype]
				if index > 1 then
					local objectpool = self.chip_objectpools[moduletype]
					moduleindex = math.max(1, (moduleindex or index) - 1)
					newchip = objectpool[moduleindex]
					for i = moduleindex + 1, index - 1 do
						if objectpool[i]._net_id == newchip._net_id then
							newchip = objectpool[i]
						else
							break
						end
					end
				else
					--scan left
					for bartype = moduletype - 1, CIRCUIT_BARS.ALPHA, -1 do
						local index = self.chip_poolindexes[bartype]
						if index > 1 then
							newchip = self.chip_objectpools[bartype][index - 1]
							break
						end
					end
					if newchip == nil then
						--scan right
						for bartype = moduletype + 1, CIRCUIT_BARS.GAMMA do
							local index = self.chip_poolindexes[bartype]
							if index > 1 then
								newchip = self.chip_objectpools[bartype][index - 1]
								break
							end
						end
					end
				end
			end

			if newchip then
				if newchip.focus then
					self:OnChipGainFocus(newchip)
				else
					newchip:SetFocus()
				end
			elseif not self.shadow_slot_item_isvalid then
				self:StopControllerRemovingModule()
			elseif self.shadow_slot.focus then
				self.shadow_slot:OnGainFocus()
			else
				self.shadow_slot:SetFocus()
			end
		end
	elseif focused_chip then
		self:OnChipGainFocus(focused_chip)
	elseif self.shadow_slot_item_isvalid and self.shadow_slot.focus then
		self.shadow_slot:OnGainFocus()
	elseif not self:IsBusy() then
		self:OverrideModuleRemoverPositionAndSpeed(nil, nil, 0.25)
	end
end

function UpgradeModulesDisplay_Inspecting:OnChipGainFocus(chip)
    if self.is_using_module_remover then
        local original_chip = chip
        local redirected
        chip, redirected = self:ResolveChip(chip)
        local was_focused = self:IsChipFocused(chip)
        self:SetChipFocusSource(chip, true, original_chip, redirected)
        self:SetChipTooltip(original_chip, redirected)

        if not was_focused then
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover", nil, ClickMouseoverSoundReduction())
        end
    end
end

function UpgradeModulesDisplay_Inspecting:OnChipLoseFocus(chip)
	local original_chip = chip
	local redirected
	chip, redirected = self:ResolveChip(chip)
	self:SetChipFocusSource(chip, nil, original_chip, redirected)
	original_chip:SetTooltip(nil)
end

function UpgradeModulesDisplay_Inspecting:OnShadowSlotGainFocus()
	if self.is_using_module_remover and self.shadow_slot_item_isvalid then
		self:SetShadowSlotFocus(true)
	end
end

function UpgradeModulesDisplay_Inspecting:OnShadowSlotLoseFocus()
	self:SetShadowSlotFocus(false)
end

function UpgradeModulesDisplay_Inspecting:UpdateModuleRemoverPosition(x, y)
    local scale = self:GetScale()
    local scr_w, scr_h = TheSim:GetScreenSize()
    local w = 0
    local h = 0

    w = w * scale.x * .5
    h = h * scale.y * .5

    self.mousehandler:SetPosition(
        math.clamp(x, w, scr_w - w),
        math.clamp(y, h, scr_h - h),
        0)
end

function UpgradeModulesDisplay_Inspecting:CheckUpdating()
    if self._overridemoduleremoverspeed or self._overridetargetpos or self._overrideenergywithshadow then
        self:StartUpdating()
    else
        self:StopUpdating()
    end
end

function UpgradeModulesDisplay_Inspecting:OverrideModuleRemoverPositionAndSpeed(x, y, speed)
    self._overridetargetpos = (x ~= nil and y ~= nil and Vector3(x, y)) or nil
	self._overridemoduleremoverspeed = (self._overridetargetpos or not TheInput:ControllerAttached()) and speed or nil

    self:CheckUpdating()
    if not self._overridemoduleremoverspeed and not self._overridetargetpos then
		--likely reached here from unplugging last module
		if self.is_using_module_remover and TheInput:ControllerAttached() then
			self:StopControllerRemovingModule()
		end
    end
end

function UpgradeModulesDisplay_Inspecting:FollowMouseConstrained()
    if self.followhandler == nil then
        local pos = TheInput:GetScreenPosition()
        self._lasttime = GetTime()
        self._targetpos = Vector3(pos.x, pos.y)
        self.followhandler = TheInput:AddMoveHandler(function(x, y)
			if not (self._overridetargetpos or self._overridemoduleremoverspeed or TheInput:ControllerAttached()) then
                self._targetpos.x = x
                self._targetpos.y = y
                self:UpdateModuleRemoverPosition(x, y)
            end
        end)
        self:UpdateModuleRemoverPosition(pos.x, pos.y)
    end
end

local ENERGY_NIGHTMARE_TOP_MAX_Y = 55
local ENERGY_NIGHTMARE_TOP_MIN_Y = -60
local BACK_TO_MOUSE_DIST_SQ = 5 * 5
function UpgradeModulesDisplay_Inspecting:OnUpdate(dt)
    if self._overrideenergywithshadow then
        local ability_cooldown_percent = self.owner.components.wx78_abilitycooldowns:GetAbilityCooldownPercent("shadow_energy")
        local perc = 1 - (ability_cooldown_percent or 0)
        self.energy_nightmare:GetAnimState():SetPercent("energy_nightmare", perc)
        self.energy_nightmare_top:SetPosition(0, Lerp(ENERGY_NIGHTMARE_TOP_MAX_Y, ENERGY_NIGHTMARE_TOP_MIN_Y, perc))
    end

    if self._overridemoduleremoverspeed or self._overridetargetpos then
        local isoverriden = self._overridetargetpos ~= nil
        local pos = self._overridetargetpos or TheInput:GetScreenPosition()
        local k = self._overridemoduleremoverspeed
        self._targetpos.x = pos.x * k + self._targetpos.x * (1 - k)
        self._targetpos.y = pos.y * k + self._targetpos.y * (1 - k)
        self:UpdateModuleRemoverPosition(self._targetpos.x, self._targetpos.y)

        if not isoverriden then -- target pos isn't overriden but speed still is, so we're returning control back once we get to mouse
	    	if TheInput:ControllerAttached() then
	    		self:StopControllerRemovingModule()
	    	elseif DistXYSq(self._targetpos, pos) <= BACK_TO_MOUSE_DIST_SQ then
                self:OverrideModuleRemoverPositionAndSpeed(nil, nil, nil)
            else -- Ramp up speed, so you can't just have it chase the mouse.
                self._overridemoduleremoverspeed = self._overridemoduleremoverspeed + (dt / 2)
            end
        end
    end
end

function UpgradeModulesDisplay_Inspecting:GetFirstCircuit(bartype)
    local objectpool = self.chip_objectpools[bartype]
    for i = 1, #objectpool do
        local chip = objectpool[i]
        if chip and chip.chip_pos then
            return chip
        end
    end
end

function UpgradeModulesDisplay_Inspecting:GetLastCircuit(bartype)
    local objectpool = self.chip_objectpools[bartype]
    for i = #objectpool, 1, -1 do
        local chip = objectpool[i]
        if chip and chip.chip_pos then
            return chip
        end
    end
end

function UpgradeModulesDisplay_Inspecting:DoFocusHookups()
    for bartype = 0, #self.chip_objectpools do
        local objectpool = self.chip_objectpools[bartype]
        for i = 1, #objectpool do
            local chip = objectpool[i]
            chip:ClearFocusDirs()
            if chip.chip_pos then -- This means it's shown.
				local prevbarchip, nextbarchip
                local index = 1
                while self.chip_objectpools[bartype-index] do
					prevbarchip = self:GetLastCircuit(bartype-index)
					if prevbarchip then
                        break
                    else
                        index = index + 1
                    end
                end

                index = 1
                while self.chip_objectpools[bartype+index] do
                    nextbarchip = self:GetLastCircuit(bartype+index)
                    if nextbarchip then
                        break
                    else
                        index = index + 1
                    end
                end

				local prevchip, nextchip
				if self.can_unplug_any then
					for j = i - 1, 1, -1 do
						if objectpool[j]._net_id ~= chip._net_id then
							prevchip = objectpool[j]
							break
						end
					end
					for j = i + 1, #objectpool do
						if objectpool[j].chip_pos == nil then
							break
						elseif objectpool[j]._net_id ~= chip._net_id then
							--found next block of different chips
							--now find last chip in that block
							nextchip = objectpool[j]
							for j = j + 1, #objectpool do
								if objectpool[j].chip_pos and objectpool[j]._net_id == nextchip._net_id then
									nextchip = objectpool[j]
								else
									break
								end
							end
							break
						end
					end
				end
				prevchip = prevchip and prevchip.chip_pos and prevchip or prevbarchip
				nextchip = nextchip and nextchip.chip_pos and nextchip or nextbarchip

				chip:SetFocusChangeDir(MOVE_DOWN, prevchip)
				chip:SetFocusChangeDir(MOVE_UP, nextchip)
				chip:SetFocusChangeDir(MOVE_LEFT, prevbarchip)
				chip:SetFocusChangeDir(MOVE_RIGHT, nextbarchip)
            end
        end
    end

	self.shadow_slot:ClearFocusDirs()
	if self.shadow_slot_item_isvalid then
		local chip = self:GetLastCircuit(#self.chip_objectpools)
		if chip then
			chip:SetFocusChangeDir(MOVE_LEFT, self.shadow_slot)
			self.shadow_slot:SetFocusChangeDir(MOVE_RIGHT, chip)
		end

		for bartype = #self.chip_objectpools - 1, 0, -1 do
			local chip = self:GetLastCircuit(bartype)
			if chip then
				chip:SetFocusChangeDir(MOVE_UP, self.shadow_slot)
				self.shadow_slot:SetFocusChangeDir(MOVE_DOWN, chip)
				break
			end
		end
	end
end

function UpgradeModulesDisplay_Inspecting:OnControl(control, down)
	if UpgradeModulesDisplay_Inspecting._base.OnControl(self, control, down) then return true end

	if not (self.focus and TheInput:ControllerAttached()) then
		return false
	elseif control == CONTROL_CANCEL then
		if not down then
			self:StopControllerRemovingModule()
		end
		return true
	elseif down then
		local dir =
			(control == TheInput:ResolveVirtualControls(VIRTUAL_CONTROL_INV_LEFT) and MOVE_LEFT) or
			(control == TheInput:ResolveVirtualControls(VIRTUAL_CONTROL_INV_RIGHT) and MOVE_RIGHT) or
			(control == TheInput:ResolveVirtualControls(VIRTUAL_CONTROL_INV_UP) and MOVE_UP) or
			(control == TheInput:ResolveVirtualControls(VIRTUAL_CONTROL_INV_DOWN) and MOVE_DOWN) or
			nil

		if dir then
			for _, objectpool in pairs(self.chip_objectpools) do
				for _, chip in ipairs(objectpool) do
					if chip.focus then
						chip:OnFocusMove(dir, true)
						return true
					end
				end
			end
			if self.shadow_slot.focus then
				self.shadow_slot:OnFocusMove(dir, true)
			end
			return true
		end
	end
end

function UpgradeModulesDisplay_Inspecting:GetHelpText()
	if not (self.is_using_module_remover and TheInput:ControllerAttached()) then
		return
	end
	local controller_id = TheInput:GetControllerID()
	local t = {}

	--local scheme = TheInput:GetActiveControlScheme(CONTROL_SCHEME_CAM_AND_INV)
	--Check Profile directly since this code here is specifically for controller ui.
	local scheme = Profile:GetControlScheme(CONTROL_SCHEME_CAM_AND_INV) or 1
	if scheme == 2 then
		table.insert(t, TheInput:GetLocalizedVirtualDirectionalControl(controller_id, "rstick", CONTROL_CAM_AND_INV_MODIFIER, false).." "..STRINGS.UI.CRAFTING_MENU.NAVIGATION)
	elseif scheme == 3 then
		table.insert(t, TheInput:GetLocalizedVirtualDirectionalControl(controller_id, "rstick", CONTROL_CAM_AND_INV_MODIFIER, true).." "..STRINGS.UI.CRAFTING_MENU.NAVIGATION)
	elseif scheme == 4 or scheme == 5 then
		table.insert(t, TheInput:GetLocalizedVirtualDirectionalControl(controller_id, "dpad", CONTROL_CAM_AND_INV_MODIFIER, true).." "..STRINGS.UI.CRAFTING_MENU.NAVIGATION)
	elseif scheme == 6 or scheme == 7 then
		table.insert(t, TheInput:GetLocalizedVirtualDirectionalControl(controller_id, "dpad", CONTROL_CAM_AND_INV_MODIFIER, false).." "..STRINGS.UI.CRAFTING_MENU.NAVIGATION)
	else
		table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_UP).." "..TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_RIGHT).." "..TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_DOWN).." "..TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_LEFT).." "..STRINGS.UI.CRAFTING_MENU.NAVIGATION)
	end

	table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT, false, false).." "..STRINGS.UI.UPGRADEMODULEDISPLAY.UNPLUG_CIRCUIT)
	table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL, false, false).." "..STRINGS.UI.OPTIONS.CANCEL)
	return table.concat(t, "  ")
end

return UpgradeModulesDisplay_Inspecting