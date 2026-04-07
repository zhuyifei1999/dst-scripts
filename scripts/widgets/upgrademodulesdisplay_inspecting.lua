local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"

local SourceModifierList = require("util/sourcemodifierlist")
local GetModuleDefinitionFromNetID = require("wx78_moduledefs").GetModuleDefinitionFromNetID

local easing = require("easing")

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

local UNPLUG_ANY_SKILLNAME = "wx78_circuitry_unpluganycircuit"
local UpgradeModulesDisplay_Inspecting = Class(Widget, function(self, owner, upgrademoduleowner, controls)
    Widget._ctor(self, "UpgradeModulesDisplay_Inspecting")
    self:UpdateWhilePaused(false)
    self.owner = owner
    self.upgrademoduleowner = upgrademoduleowner
    self.controls = controls

    local max_energy = owner:GetMaxEnergy()
    self.max_energy = max_energy
    self.energy_level = max_energy

    local scale = 0.88
    self:SetScale(scale, scale, scale)
    self:SetPosition(-425, 0)

    -- Skill
    self.can_unplug_any = owner.components.skilltreeupdater ~= nil and owner.components.skilltreeupdater:IsActivated(UNPLUG_ANY_SKILLNAME)
    local function OnUpdateSkill(_, data)
        if data.skill == UNPLUG_ANY_SKILLNAME then
            self.can_unplug_any = owner.components.skilltreeupdater:IsActivated(UNPLUG_ANY_SKILLNAME)
            self:DoFocusHookups()
        end
    end
    self.inst:ListenForEvent("onactivateskill_client", OnUpdateSkill, owner)
    self.inst:ListenForEvent("ondeactivateskill_client", OnUpdateSkill, owner)
    --

    self.bg = self:AddChild(UIAnim())
    self.bg:GetAnimState():SetBank("status_wx_chest")
    self.bg:GetAnimState():SetBuild("status_wx_chest")
    self.bg:GetAnimState():PlayAnimation("chest_open")
    self.bg:GetAnimState():PushAnimation("chest_idle")
    self.bg:GetAnimState():AnimateWhilePaused(false)
    self.bg:GetAnimState():Hide("bars")
    self.bg:GetAnimState():Hide("shadow")
    self.bg:GetAnimState():Hide("bars_extended")
    self.bg:GetAnimState():Hide("shadow_extended")
    self.bg:MoveToBack()

    self.bg_shadow = self:AddChild(UIAnim())
    self.bg_shadow:GetAnimState():SetBank("status_wx_chest")
    self.bg_shadow:GetAnimState():SetBuild("status_wx_chest")
    self.bg_shadow:GetAnimState():PlayAnimation("chest_open")
    self.bg_shadow:GetAnimState():PushAnimation("chest_idle")
    self.bg_shadow:GetAnimState():AnimateWhilePaused(false)
    self.bg_shadow:GetAnimState():Hide("frame_bg")
    self.bg_shadow:GetAnimState():Hide("bars_extended")
    self.bg_shadow:GetAnimState():Hide("bars")
    self.bg_shadow:GetAnimState():Hide("shadow_extended")

    self.bg_bars = self:AddChild(UIAnim())
    self.bg_bars:GetAnimState():SetBank("status_wx_chest")
    self.bg_bars:GetAnimState():SetBuild("status_wx_chest")
    self.bg_bars:GetAnimState():PlayAnimation("chest_open")
    self.bg_bars:GetAnimState():PushAnimation("chest_idle")
    self.bg_bars:GetAnimState():AnimateWhilePaused(false)
    self.bg_bars:GetAnimState():Hide("frame_bg")
    self.bg_bars:GetAnimState():Hide("shadow")
    self.bg_bars:GetAnimState():Hide("shadow_extended")
    self.bg_bars:GetAnimState():Hide("bars_extended")
    self.bg_bars:MoveToFront()

    self.plugs = self:AddChild(UIAnim())
    self.plugs:GetAnimState():SetBank("status_wx_chest")
    self.plugs:GetAnimState():SetBuild("status_wx_chest")
    self.plugs:GetAnimState():PlayAnimation("slot_open")
    self.plugs:GetAnimState():AnimateWhilePaused(false)
    self.plugs:MoveToFront()

    self.chip_objectpools = {}
    self.chip_poolindexes = {}
    self.chip_slotsinuse = {}
    for i, v in pairs(CIRCUIT_BARS) do
        self.chip_objectpools[v] = {}
        for i = 1, max_energy do
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
    self.moduleremover:GetAnimState():AnimateWhilePaused(false)
    self.moduleremover:SetScale(.5, .5)
    self.moduleremover:Hide()
    self.moduleremover.inst:AddTag("NOCLICK")

    if upgrademoduleowner.wx78_classified ~= nil then
        self:UpdateEnergyLevel(upgrademoduleowner.wx78_classified.currentenergylevel:value(), 0, true)
    end
    self:OnModulesDirty(upgrademoduleowner:GetModulesData(), true)
    self:FollowMouseConstrained()

	self.default_focus = self.chip_objectpools[0][1]
    self.inst:DoTaskInTime(0, function() self:ControllerSetFocus() end)
    self:DoFocusHookups()

    self.inst:ListenForEvent("newactiveitem", function() self:OnNewActiveItem() end, self.owner)
    self:OnNewActiveItem()

    self:UpdateMaxEnergy(self.max_energy, self.max_energy)
end)

function UpgradeModulesDisplay_Inspecting:ControllerSetFocus()
    if TheInput:ControllerAttached() then
        -- TheFrontEnd:StopTrackingMouse()
        -- TheFrontEnd:LockFocus(true)
        self:DoFocusHookups()
        for bartype = 0, #self.chip_objectpools do
            local objectpool = self.chip_objectpools[bartype]
            for i = 1, #objectpool do
                local chip = objectpool[i]
                if chip and chip.chip_pos then
                    if not chip.focus and not TheFrontEnd.tracking_mouse then
	                	chip:SetFocus()
                        return
	                end
                end
            end
        end
    end
end

-------------------------------------------------------------

function UpgradeModulesDisplay_Inspecting:IsExtended()
    return self.max_energy >= 7
end

function UpgradeModulesDisplay_Inspecting:UpdateSlotCount()
    if self:IsExtended() then
        self.bg_shadow:GetAnimState():Hide("shadow")
        self.bg_shadow:GetAnimState():Show("shadow_extended")

        self.bg_bars:GetAnimState():Hide("bars")
        self.bg_bars:GetAnimState():Show("bars_extended")
    else
        self.bg_shadow:GetAnimState():Show("shadow")
        self.bg_shadow:GetAnimState():Hide("shadow_extended")

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

function UpgradeModulesDisplay_Inspecting:OnNewActiveItem()
    local active_item = self.owner.replica.inventory:GetActiveItem()
    if active_item ~= nil and active_item:HasActionComponent("upgrademoduleremover") then
        self:ControllerSetFocus()
        if not self.is_using_module_remover then
            self.moduleremover:GetAnimState():PlayAnimation("appear")
            self.moduleremover:GetAnimState():PushAnimation("idle", false)
            self:UpdateModuleRemoverBuild(active_item)
        end
        self.moduleremover:Show()
        self.moduleremover:UnhookCallback("animover")
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
    else
        if self.moduleremover.shown then
            TheFrontEnd:GetSound():PlaySound("WX_rework/module_tray/toolclick")
            self.moduleremover:GetAnimState():PlayAnimation("disappear")
            self.moduleremover:HookCallback("animover", function(chip_ui_inst)
                self.controls:OverrideTooltipPos(nil)
                self.controls.hover:ForceSettleTextPositionOnMove(nil)
                self.moduleremover:Hide()
                self.moduleremover:UnhookCallback("animover")
            end)
        end
        self.owner:PushEvent("sethovertilehidemodifier", { source = self.inst, hidden = false})
        self.is_using_module_remover = false
    end
end

function UpgradeModulesDisplay_Inspecting:UpdateModuleRemoverBuild(moduleremover)
    local build = moduleremover.AnimState:GetBuild()
    local skin_build = moduleremover:GetSkinBuild()

    if skin_build ~= nil then
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
        local lastchip = objectpool[i-1]
        local chip = objectpool[i]
        if i >= startindex + 1 then
            if chip.chip_pos then
                local start_pos = chip:GetPosition()
                local slot_distance_from_bottom = slotsinuse + (chip._used_modslots - 1) * 0.5
                local y_pos = (slot_distance_from_bottom * 20) - 50
                local pos = Vector3(x_offset, y_pos + y_offset)
                self:SetChipPosition(lastchip, pos.x, pos.y)
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
    end)
end

function UpgradeModulesDisplay_Inspecting:OnModulesDirty(modules_data, init)
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

    local our_objectpool = self.chip_objectpools[falling_chip.moduletype]
    local chip_to_focus = our_objectpool[falling_chip.old_chip_index - 1] -- the last one
    if not TheFrontEnd.tracking_mouse then
        if not chip_to_focus then -- If it doesn't exist then, the other bar.
            falling_chip:SetFocus()
            local success = self:OnFocusMove(MOVE_LEFT, true)
            if not success then
                self:OnFocusMove(MOVE_RIGHT, true)
            end
            falling_chip:ClearFocus()
        else
            chip_to_focus:SetFocus()
        end
    end

    for bartype, index in pairs(self.chip_poolindexes) do
        local objectpool = self.chip_objectpools[bartype]
        for i = 1, index - 1 do
            local otherchip = objectpool[i]
            if otherchip.focus then
                otherchip:ClearFocus()
                otherchip:SetFocus()
            end
        end
    end
    self:PlayChipAnimation(falling_chip, "chip_fall")
end

function UpgradeModulesDisplay_Inspecting:PopOneModule(bartype)
    local objectpool = self.chip_objectpools[bartype]
    local falling_chip = objectpool[self.chip_poolindexes[bartype] - 1]

    self.chip_poolindexes[bartype] = self.chip_poolindexes[bartype] - 1
    self.chip_slotsinuse[bartype] = self.chip_slotsinuse[bartype] - falling_chip._used_modslots
    self:DropChip(falling_chip)
end

function UpgradeModulesDisplay_Inspecting:PopAllModules()
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
    -- TODO close
    self.owner:PushEvent("sethovertilehidemodifier", { source = self.inst, hidden = false })
    self.controls:OverrideTooltipPos(nil)
    self:Kill()
    TheFrontEnd:LockFocus(false)
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
function UpgradeModulesDisplay_Inspecting:GetModuleRemoverPosition(chip)
    local w, h = TheSim:GetScreenSize()
    local res_scale = w / RESOLUTION_X
    return chip:GetWorldPosition() + (MODULE_REMOVER_OFFSET * res_scale)
end

local NO_UNPLUG_DELAY = 4 * FRAMES
function UpgradeModulesDisplay_Inspecting:UnplugModule(moduletype, moduleindex)
    if self.is_using_module_remover and not self.no_unplug_flag then
        moduleindex = self:ResolveUnplugModuleIndex(moduletype, moduleindex)
        local chip = self.chip_objectpools[moduletype][moduleindex]

        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        self.moduleremover:GetAnimState():PlayAnimation("unplug")
        self.moduleremover:GetAnimState():PushAnimation("idle", false)
        self.moduleremover:HookCallback("animover", function(ui_inst)
            self.moduleremover.inst:DoTaskInTime(NO_UNPLUG_DELAY, function()
                self.no_unplug_flag = nil
            end)
            self:OverrideModuleRemoverPositionAndSpeed(nil, nil, .2)
            -- local no_other_focus = true
            for bartype, index in pairs(self.chip_poolindexes) do
                local objectpool = self.chip_objectpools[bartype]
                for i = 1, index - 1 do
                    local otherchip = objectpool[i]
                    if otherchip.focus_sources and otherchip.focus_sources:Get() then
                        local pos = self:GetModuleRemoverPosition(otherchip)
                        self:OverrideModuleRemoverPositionAndSpeed(pos.x, pos.y, 0.2)
                        break
                    end
                end
            end
            self.moduleremover:UnhookCallback("animover")
        end)
        self.no_unplug_flag = true

        local pos = self:GetModuleRemoverPosition(chip)
        self:OverrideModuleRemoverPositionAndSpeed(pos.x, pos.y, .3)

        self.upgrademoduleowner:UnplugModule(moduletype, moduleindex)
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
        if not self.no_unplug_flag then
            local pos = self:GetModuleRemoverPosition(chip)
            self:OverrideModuleRemoverPositionAndSpeed(pos.x, pos.y, 0.2)
        end
        self:SetChipTooltip(chip, redirected)
        if self:IsChipValidToFocus(chip) then
            chip:GetAnimState():Show("focus")
        end
    else
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
        if no_other_focus and not self.no_unplug_flag then
            self:OverrideModuleRemoverPositionAndSpeed(nil, nil, .25)
        end
        chip:SetTooltip(nil)
        if self:IsChipValidToFocus(chip) then
            chip:GetAnimState():Hide("focus")
        end
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
    if self.is_using_module_remover then
        local original_chip = chip
        local redirected
        chip, redirected = self:ResolveChip(chip)
        self:SetChipFocusSource(chip, nil, original_chip, redirected)
        original_chip:SetTooltip(nil)
    end
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

function UpgradeModulesDisplay_Inspecting:OverrideModuleRemoverPositionAndSpeed(x, y, speed)
    self._overridetargetpos = (x ~= nil and y ~= nil and Vector3(x, y)) or nil
    self._overridemoduleremoverspeed = speed or nil

    if self._overridemoduleremoverspeed or self._overridetargetpos then
        self:StartUpdating()
    else
        self:StopUpdating()
    end
end

function UpgradeModulesDisplay_Inspecting:FollowMouseConstrained()
    if self.followhandler == nil then
        local pos = TheInput:GetScreenPosition()
        self._lasttime = GetTime()
        self._targetpos = Vector3(pos.x, pos.y)
        self.followhandler = TheInput:AddMoveHandler(function(x, y)
            if not self._overridetargetpos and not self._overridemoduleremoverspeed then
                self._targetpos.x = x
                self._targetpos.y = y
                self:UpdateModuleRemoverPosition(x, y)
            end
        end)
        self:UpdateModuleRemoverPosition(pos.x, pos.y)
    end
end

local BACK_TO_MOUSE_DIST_SQ = 5 * 5
function UpgradeModulesDisplay_Inspecting:OnUpdate(dt)
    local isoverriden = self._overridetargetpos ~= nil
    local pos = self._overridetargetpos or TheInput:GetScreenPosition()
    local k = self._overridemoduleremoverspeed
    self._targetpos.x = pos.x * k + self._targetpos.x * (1 - k)
    self._targetpos.y = pos.y * k + self._targetpos.y * (1 - k)
    self:UpdateModuleRemoverPosition(self._targetpos.x, self._targetpos.y)

    if not isoverriden then -- target pos isn't overriden but speed still is, so we're returning control back once we get to mouse
        if DistXYSq(self._targetpos, pos) <= BACK_TO_MOUSE_DIST_SQ then
            self:OverrideModuleRemoverPositionAndSpeed(nil, nil, nil)
            self:StopUpdating()
        else -- Ramp up speed, so you can't just have it chase the mouse.
            self._overridemoduleremoverspeed = self._overridemoduleremoverspeed + (dt / 2)
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
                local lastbarchip, nextbarchip
                local index = 1
                while self.chip_objectpools[bartype-index] do
                    lastbarchip = self:GetLastCircuit(bartype-index)
                    if lastbarchip then
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

                local lastchip = self.can_unplug_any and objectpool[i-1] or lastbarchip
                lastchip = (lastchip and lastchip.chip_pos and lastchip) or lastbarchip or nil

                local nextchip = self.can_unplug_any and objectpool[i+1] or nextbarchip
                nextchip = (nextchip and nextchip.chip_pos and nextchip) or nextbarchip or nil

                if lastchip ~= nil then
                    chip:SetFocusChangeDir(MOVE_DOWN, lastchip)
                end
                if nextchip ~= nil then
                    chip:SetFocusChangeDir(MOVE_UP, nextchip)
                end
                if lastbarchip ~= nil then
                    chip:SetFocusChangeDir(MOVE_LEFT, lastbarchip)
                end
                if nextbarchip ~= nil then
                    chip:SetFocusChangeDir(MOVE_RIGHT, nextbarchip)
                end
            end
        end
    end
end

function UpgradeModulesDisplay_Inspecting:GetHelpText()
	local controller_id = TheInput:GetControllerID()
	local t = {}
   	table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL, false, false ) .. " " .. STRINGS.UI.OPTIONS.CLOSE)
   	table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT, false, false ) .. " " .. STRINGS.UI.UPGRADEMODULEDISPLAY.UNPLUG_CIRCUIT)
	return table.concat(t, "  ")
end

return UpgradeModulesDisplay_Inspecting