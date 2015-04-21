local Screen = require "widgets/screen"
local ContainerWidget = require("widgets/containerwidget")
local Controls = require("widgets/controls")
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local IceOver = require "widgets/iceover"
local FireOver = require "widgets/fireover"
local BloodOver = require "widgets/bloodover"
local HeatOver = require "widgets/heatover"
local easing = require("easing")

local PauseScreen = require "screens/pausescreen"
local ChatInputScreen = require "screens/chatinputscreen"
local PlayerStatusScreen = require "screens/playerstatusscreen"

local TargetIndicator = require "widgets/targetindicator"

local EventAnnouncer = require "widgets/eventannouncer"

-- local Ping = require "widgets/ping"

local PlayerHud = Class(Screen, function(self)
	Screen._ctor(self, "HUD")
    
    self.overlayroot = self:AddChild(Widget("overlays"))

    self.under_root = self:AddChild(Widget("under_root"))
    self.root = self:AddChild(Widget("root"))
end)

function PlayerHud:CreateOverlays(owner)	
	self.overlayroot:KillAllChildren()

    self.vig = self.overlayroot:AddChild(UIAnim())
    self.vig:GetAnimState():SetBuild("vig")
    self.vig:GetAnimState():SetBank("vig")
    self.vig:GetAnimState():PlayAnimation("basic", true)

    self.vig:SetHAnchor(ANCHOR_MIDDLE)
    self.vig:SetVAnchor(ANCHOR_MIDDLE)
    self.vig:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)

    self.vig:SetClickable(false)
    
    self.bloodover = self.overlayroot:AddChild(BloodOver(owner))
    self.iceover = self.overlayroot:AddChild(IceOver(owner))
    self.fireover = self.overlayroot:AddChild(FireOver(owner))
    self.heatover = self.overlayroot:AddChild(HeatOver(owner))
    self.iceover:Hide()
    self.fireover:Hide()
    self.heatover:Hide()

    self.clouds = self.overlayroot:AddChild(UIAnim())
    self.clouds:SetClickable(false)
    self.clouds:SetHAnchor(ANCHOR_MIDDLE)
    self.clouds:SetVAnchor(ANCHOR_MIDDLE)
    self.clouds:GetAnimState():SetBank("clouds_ol")
    self.clouds:GetAnimState():SetBuild("clouds_ol")
    self.clouds:GetAnimState():PlayAnimation("idle", true)
    self.clouds:GetAnimState():SetMultColour(1,1,1,0)
    self.clouds:Hide()

    self.eventannouncer = self.overlayroot:AddChild(Widget("eventannouncer_root"))
    self.eventannouncer:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.eventannouncer:SetHAnchor(ANCHOR_MIDDLE)
    self.eventannouncer:SetVAnchor(ANCHOR_TOP)
    self.eventannouncer = self.eventannouncer:AddChild(EventAnnouncer(owner))

    -- self.ping = self.overlayroot:AddChild(Ping(owner))
    -- self.ping:SetHAnchor(ANCHOR_LEFT)
    -- self.ping:SetVAnchor(ANCHOR_TOP)
end

function PlayerHud:OnDestroy()
    if self.playerstatusscreen ~= nil then
        self.playerstatusscreen:Kill()
        self.playerstatusscreen = nil
    end
    Screen.OnDestroy(self)
end

function PlayerHud:OnLoseFocus()
	Screen.OnLoseFocus(self)
	TheInput:EnableMouse(true)

	if self:IsControllerCraftingOpen() then
		self:CloseControllerCrafting()
	end

	if self:IsControllerInventoryOpen() then
		self:CloseControllerInventory()
	end

    if self.owner ~= nil and TheInput:ControllerAttached() then
    	self.owner.replica.inventory:ReturnActiveItem()
    end
    if self.controls ~= nil then
	   self.controls.hover:Hide()
    end
end

function PlayerHud:OnGainFocus()
	Screen.OnGainFocus(self)
	local controller = TheInput:ControllerAttached()
	if controller then
		TheInput:EnableMouse(false)
	else
		TheInput:EnableMouse(true)
	end
	
	if self.controls then
		self.controls:SetHUDSize()
		if controller then
			self.controls.hover:Hide()
		else
			self.controls.hover:Show()
		end
	end
	
	if not TheInput:ControllerAttached() then
		if self:IsControllerCraftingOpen() then
			self:CloseControllerCrafting()
		end

		if self:IsControllerInventoryOpen() then
			self:CloseControllerInventory()
		end
	end

end
	
function PlayerHud:Toggle()
	self.shown = not self.shown
	if self.shown then
		self.root:Show()
	else
		self.root:Hide()
	end
end

function PlayerHud:Hide()
    self.shown = false
    self.root:Hide() --#srosen need an exception for the timer here (and to always force-hide it if the rest of the HUD is shown)
end

function PlayerHud:Show()
    self.shown = true
    self.root:Show()
end

function PlayerHud:CloseContainer(container, side)
    if container == nil then
        return
    elseif side and TheInput:ControllerAttached() then
        self.controls.inv.rebuild_pending = true
    else
        for k, v in pairs(self.controls.containers) do
            if v.container == container then
                v:Close()
            end
        end
    end
end

function PlayerHud:GetFirstOpenContainerWidget()
    local k, v = next(self.controls.containers)
    return v
end

function PlayerHud:OpenContainer(container, side)
    if container == nil then
        return
    elseif side and TheInput:ControllerAttached() then
        self.controls.inv.rebuild_pending = true
    else
        local containerwidget = ContainerWidget(self.owner)
        self.controls[side and "containerroot_side" or "containerroot"]:AddChild(containerwidget)
        containerwidget:Open(container, self.owner)
        self.controls.containers[container] = containerwidget
    end
end

function PlayerHud:GoSane()
    self.vig:GetAnimState():PlayAnimation("basic", true)
end

function PlayerHud:GoInsane()
    self.vig:GetAnimState():PlayAnimation("insane", true)
end

function PlayerHud:SetMainCharacter(maincharacter)
    if maincharacter then
		maincharacter.HUD = self
		self.owner = maincharacter

		self:CreateOverlays(self.owner)
		self.controls = self.root:AddChild(Controls(self.owner))

		self.inst:ListenForEvent("badaura", function() return self.bloodover:Flash() end, self.owner)
		self.inst:ListenForEvent("attacked", function() return self.bloodover:Flash() end, self.owner)
		self.inst:ListenForEvent("damaged", function() return self.bloodover:Flash() end, self.owner) -- same as attacked, but for non-combat situations like making a telltale heart
		self.inst:ListenForEvent("startstarving", function() self.bloodover:UpdateState() end, self.owner)
		self.inst:ListenForEvent("stopstarving", function() self.bloodover:UpdateState() end, self.owner)
		self.inst:ListenForEvent("startfreezing", function() self.bloodover:UpdateState() end, self.owner)
		self.inst:ListenForEvent("stopfreezing", function() self.bloodover:UpdateState() end, self.owner)
		self.inst:ListenForEvent("startoverheating", function() self.bloodover:UpdateState() end, self.owner)
		self.inst:ListenForEvent("stopoverheating", function() self.bloodover:UpdateState() end, self.owner)
		self.inst:ListenForEvent("gosane", function() self:GoSane() end, self.owner)
		self.inst:ListenForEvent("goinsane", function() self:GoInsane() end, self.owner)

		if self.owner.replica.sanity ~= nil and not self.owner.replica.sanity:IsSane() then
			self:GoInsane()
		end
		self.controls.crafttabs:UpdateRecipes()

        local overflow = maincharacter.replica.inventory ~= nil and maincharacter.replica.inventory:GetOverflowContainer() or nil
		if overflow ~= nil then
			overflow:Close()
			overflow:Open(maincharacter)
		end
	end
end

function PlayerHud:OnUpdate(dt)
	if Profile and self.vig then
		if RENDER_QUALITY.LOW == Profile:GetRenderQuality() or TheConfig:IsEnabled("hide_vignette") then
			self.vig:Hide()
		else
			self.vig:Show()
		end
	end
end

function PlayerHud:HideControllerCrafting()
	
	self.controls.crafttabs:MoveTo(self.controls.crafttabs:GetPosition(), Vector3(-200, 0, 0), .25)
end

function PlayerHud:ShowControllerCrafting()
	self.controls.crafttabs:MoveTo(self.controls.crafttabs:GetPosition(), Vector3(0,0,0), .25)
end


function PlayerHud:OpenControllerInventory()
	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/craft_open")
	TheFrontEnd:StopTrackingMouse()
	self:CloseControllerCrafting()
	self:HideControllerCrafting()
	self.controls.inv:OpenControllerInventory()
	self.controls:ShowStatusNumbers()

	self.owner.components.playercontroller:OnUpdate(0)
end

function PlayerHud:CloseControllerInventory()
	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/craft_close")
	self.controls:HideStatusNumbers()
	self:ShowControllerCrafting()
	self.controls.inv:CloseControllerInventory()
end

function PlayerHud:HasInputFocus()
    --We're checking that the active screen is NOT us, because HUD
    --is always active, and we're saying that it locks input focus
    --when anything else is active on top of it.
    local active_screen = TheFrontEnd:GetActiveScreen()
    return (active_screen ~= nil and active_screen ~= self)
        or (self.controls ~= nil and (self.controls.inv.open or self.controls.crafttabs.controllercraftingopen))
        or self.modfocus ~= nil
end

function PlayerHud:SetModFocus(modname, focusid, hasfocus)
    if hasfocus then
        if self.modfocus == nil then
            self.modfocus = { [modname] = { [focusid] = true } }
        elseif self.modfocus[modname] == nil then
            self.modfocus[modname] = { [focusid] = true }
        else
            self.modfocus[modname][focusid] = true
        end
    elseif self.modfocus ~= nil and self.modfocus[modname] ~= nil and self.modfocus[modname][focusid] then
        self.modfocus[modname][focusid] = nil
        if next(self.modfocus[modname]) == nil then
            self.modfocus[modname] = nil
            if next(self.modfocus) == nil then
                self.modfocus = nil
            end
        end
    end
end

function PlayerHud:IsControllerInventoryOpen()
	return self.controls ~= nil and self.controls.inv.open
end

function PlayerHud:IsControllerCraftingOpen()
    return self.controls ~= nil and self.controls.crafttabs.controllercraftingopen
end

function PlayerHud:IsCraftingOpen()
    return self.controls ~= nil and self.controls.crafttabs:IsCraftingOpen()
end

function PlayerHud:IsPauseScreenOpen()
	local active_screen = TheFrontEnd:GetActiveScreen()
	return active_screen ~= nil and active_screen.name == "PauseScreen"
end

function PlayerHud:IsChatInputScreenOpen()
	local active_screen = TheFrontEnd:GetActiveScreen()
	return active_screen ~= nil and active_screen.name == "ChatInputScreen"
end

function PlayerHud:IsConsoleScreenOpen()
    local active_screen = TheFrontEnd:GetActiveScreen()
    return active_screen ~= nil and active_screen.name == "ConsoleScreen"
end

function PlayerHud:IsMapScreenOpen()
    local active_screen = TheFrontEnd:GetActiveScreen()
    return active_screen ~= nil and active_screen.name == "MapScreen"
end

function PlayerHud:IsStatusScreenOpen()
    local active_screen = TheFrontEnd:GetActiveScreen()
    return active_screen ~= nil and active_screen.name == "PlayerStatusScreen"
end

function PlayerHud:OpenControllerCrafting()
	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/craft_open")
	TheFrontEnd:StopTrackingMouse()
	self:CloseControllerInventory()
	self.controls.inv:Disable()
	self.controls.crafttabs:OpenControllerCrafting()
end

function PlayerHud:CloseControllerCrafting()
	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/craft_close")
	self.controls.crafttabs:CloseControllerCrafting()	
	self.controls.inv:Enable()
end

function PlayerHud:ShowPlayerStatusScreen()
	if not self.playerstatusscreen then
		self.playerstatusscreen = PlayerStatusScreen(self.owner)
	end
	TheFrontEnd:PushScreen(self.playerstatusscreen)
	self.playerstatusscreen:MoveToFront()
	self.playerstatusscreen:Show()
end

function PlayerHud:OnControl(control, down)
    if PlayerHud._base.OnControl(self, control, down) then
        return true
    elseif not self.shown then
        return
    elseif not down and control == CONTROL_PAUSE then
        TheFrontEnd:PushScreen(PauseScreen())
        return true
    elseif self.owner == nil then
        return
    elseif not down then
        if control == CONTROL_MAP then
            if not self.owner:HasTag("beaver") then
                self.controls:ToggleMap()
                return true
            end
        elseif control == CONTROL_CANCEL then
            local closed = false
            if self:IsControllerCraftingOpen() then
                self:CloseControllerCrafting()
                closed = true
            end
            if self:IsControllerInventoryOpen() then
                self:CloseControllerInventory()
                closed = true
            end
            return closed
        elseif control == CONTROL_TOGGLE_PLAYER_STATUS then
            self:ShowPlayerStatusScreen()
            return true
        end
    elseif control == CONTROL_SHOW_PLAYER_STATUS then
        self:ShowPlayerStatusScreen()
        return true
    elseif control == CONTROL_OPEN_CRAFTING then
        if self:IsControllerCraftingOpen() then
            self:CloseControllerCrafting()
            return true
        elseif self.owner.replica.inventory ~= nil and
            self.owner.replica.inventory:IsVisible() and
            not self.owner:HasTag("beaver") then
            self:OpenControllerCrafting()
            return true
        end
    elseif control == CONTROL_OPEN_INVENTORY then
        if self:IsControllerInventoryOpen() then
            self:CloseControllerInventory()
            return true
        elseif self.owner.replica.inventory ~= nil and
            self.owner.replica.inventory:IsVisible() and
            not self.owner:HasTag("beaver") then
            self:OpenControllerInventory()
            return true
        end
    elseif control == CONTROL_TOGGLE_SAY then
        TheFrontEnd:PushScreen(ChatInputScreen(false))
        return true
    elseif control == CONTROL_TOGGLE_WHISPER then
        TheFrontEnd:PushScreen(ChatInputScreen(true))
        return true
    elseif control == CONTROL_TOGGLE_SLASH_COMMAND then
        local chat_input_screen = ChatInputScreen(false)
        chat_input_screen.chat_edit:SetString("/")
        TheFrontEnd:PushScreen(chat_input_screen)
        return true
    elseif control >= CONTROL_INV_1 and
        control <= CONTROL_INV_10 and
        self.owner.replica.inventory ~= nil and
        self.owner.replica.inventory:IsVisible() and
        not self.owner:HasTag("beaver") then
        --inventory hotkeys
        local item = self.owner.replica.inventory:GetItemInSlot(control - CONTROL_INV_1 + 1)
        if item ~= nil then
            self.owner.replica.inventory:UseItemFromInvTile(item)
        end
        return true
    end
end

function PlayerHud:OnRawKey(key, down)
    if PlayerHud._base.OnRawKey(self, key, down) then return true end	
end

function PlayerHud:UpdateClouds(camera)
    --this is kind of a weird place to do all of this, but the anim *is* a hud asset...
    if camera.distance and not camera.dollyzoom then
        local dist_percent = (camera.distance - camera.mindist) / (camera.maxdist - camera.mindist)
        local cutoff = .6
        if dist_percent > cutoff then
            if not self.clouds_on then
                camera.should_push_down = true
                self.clouds_on = true
                self.clouds:Show()
                TheFocalPoint.SoundEmitter:PlaySound("dontstarve/common/clouds", "windsound")
                TheMixer:PushMix("high")
            end
            local p = easing.outCubic(dist_percent - cutoff, 0, 1, 1 - cutoff)
            self.clouds:GetAnimState():SetMultColour(1, 1, 1, p)
            TheFocalPoint.SoundEmitter:SetVolume("windsound", p)
        elseif self.clouds_on then
            camera.should_push_down = false
            self.clouds_on = false
            self.clouds:Hide()
            TheFocalPoint.SoundEmitter:KillSound("windsound")
            TheMixer:PopMix("high")
        end
    end
end

function PlayerHud:AddTargetIndicator(target)
	if not self.targetindicators then
		self.targetindicators = {}
	end

	local ti = self.under_root:AddChild(TargetIndicator(self.owner, target))
	table.insert(self.targetindicators, ti)
end

function PlayerHud:HasTargetIndicator(target)
	if not self.targetindicators then return end

	for i,v in pairs(self.targetindicators) do
		if v and v:GetTarget() == target then
			return true
		end
	end
	return false
end

function PlayerHud:RemoveTargetIndicator(target)
	if not self.targetindicators then return end

	local index = nil
	for i,v in pairs(self.targetindicators) do
		if v and v:GetTarget() == target then
			index = i
			break
		end
	end
	if index then
		local ti = table.remove(self.targetindicators, index)
		if ti then ti:Kill() end
	end
end

return PlayerHud
