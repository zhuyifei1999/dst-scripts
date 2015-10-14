local Screen = require "widgets/screen"
local ContainerWidget = require("widgets/containerwidget")
local WriteableWidget = require("widgets/writeablewidget")
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
local InputDialogScreen = require "screens/inputdialog"

local TargetIndicator = require "widgets/targetindicator"

local EventAnnouncer = require "widgets/eventannouncer"
local GiftItemPopUp = require "screens/giftitempopup"
local WardrobePopupScreen = require "screens/wardrobepopup"
local PlayerAvatarPopup = require "widgets/playeravatarpopup"


local PlayerHud = Class(Screen, function(self)
    Screen._ctor(self, "HUD")

    self.overlayroot = self:AddChild(Widget("overlays"))

    self.under_root = self:AddChild(Widget("under_root"))
    self.root = self:AddChild(Widget("root"))

    self.giftitempopup = nil
    self.wardrobepopup = nil
    self.playeravatarpopup = nil
    self.recentgifts = nil
    self.recentgiftstask = nil

    self.inst:ListenForEvent("continuefrompause", function() self:RefreshControllers() end, TheWorld)
end)

function PlayerHud:CreateOverlays(owner)
    self.overlayroot:KillAllChildren()
    self.under_root:KillAllChildren()

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

    self.clouds = self.under_root:AddChild(UIAnim())
    self.clouds:SetClickable(false)
    self.clouds:SetHAnchor(ANCHOR_MIDDLE)
    self.clouds:SetVAnchor(ANCHOR_MIDDLE)
    self.clouds:GetAnimState():SetBank("clouds_ol")
    self.clouds:GetAnimState():SetBuild("clouds_ol")
    self.clouds:GetAnimState():PlayAnimation("idle", true)
    self.clouds:GetAnimState():SetMultColour(1,1,1,0)
    self.clouds:Hide()

    self.eventannouncer = self.under_root:AddChild(Widget("eventannouncer_root"))
    self.eventannouncer:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.eventannouncer:SetHAnchor(ANCHOR_MIDDLE)
    self.eventannouncer:SetVAnchor(ANCHOR_TOP)
    self.eventannouncer = self.eventannouncer:AddChild(EventAnnouncer(owner))
end

function PlayerHud:OnDestroy()
    --Hack for holding offset when transitioning from giftitempopup to wardrobepopup
    TheCamera:PopScreenHOffset(self)

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
    self.root:Hide()
end

function PlayerHud:Show()
    self.shown = true
    self.root:Show()
end

function PlayerHud:GetFirstOpenContainerWidget()
    local k, v = next(self.controls.containers)
    return v
end

local function CloseContainerWidget(self, container, side)
    for k, v in pairs(self.controls.containers) do
        if v.container == container then
            v:Close()
        end
    end
end

function PlayerHud:CloseContainer(container, side)
    if container == nil then
        return
    elseif side and TheInput:ControllerAttached() then
        self.controls.inv.rebuild_pending = true
    else
        CloseContainerWidget(self, container, side)
    end
end

local function OpenContainerWidget(self, container, side)
    local containerwidget = ContainerWidget(self.owner)
    self.controls[side and "containerroot_side" or "containerroot"]:AddChild(containerwidget)
    containerwidget:Open(container, self.owner)
    self.controls.containers[container] = containerwidget
end

function PlayerHud:OpenContainer(container, side)
    if container == nil then
        return
    elseif side and TheInput:ControllerAttached() then
        self.controls.inv.rebuild_pending = true
    else
        OpenContainerWidget(self, container, side)
    end
end

function PlayerHud:TogglePlayerAvatarPopup(player_name, data, include_steam_link)
    if self.playeravatarpopup ~= nil then
        if self.playeravatarpopup.started and
            self.playeravatarpopup.inst:IsValid() then
            self.playeravatarpopup:Close()
            if player_name == nil or
                data == nil or
                self.playeravatarpopup.userid == data.userid or
                self.owner.userid == data.userid then
                self.playeravatarpopup = nil
                return
            end
        end
    end
    self.playeravatarpopup = self.controls.topright_root:AddChild(PlayerAvatarPopup(self.owner, player_name, data, include_steam_link))
end

function PlayerHud:OpenItemManagerScreen()
    --Hack for holding offset when transitioning from giftitempopup to wardrobepopup
    TheCamera:PopScreenHOffset(self)
    self:ClearRecentGifts()

    if self.giftitempopup ~= nil and self.giftitempopup.inst:IsValid() then
        TheFrontEnd:PopScreen(self.giftitempopup)
    end
    local item = TheInventory:GetUnopenedItems()[1]
    if item ~= nil then
        self.giftitempopup = GiftItemPopUp(self.owner, { item.item_type }, { item.item_id })
        TheFrontEnd:PushScreen(self.giftitempopup)
        return true
    else
        return false
    end
end

local function OnClearRecentGifts(inst, self)
    self.recentgiftstask = nil
    self:ClearRecentGifts()
end

function PlayerHud:CloseItemManagerScreen()
    --Hack for holding offset when transitioning from giftitempopup to wardrobepopup
    TheCamera:PopScreenHOffset(self)
    if self.recentgiftstask == nil then
        self.recentgiftstask = self.inst:DoTaskInTime(0, OnClearRecentGifts, self)
    end

    if self.giftitempopup ~= nil then
        if self.giftitempopup.inst:IsValid() then
            TheFrontEnd:PopScreen(self.giftitempopup)
        end
        self.giftitempopup = nil
    end
end

function PlayerHud:OpenWardrobeScreen()
    --Hack for holding offset when transitioning from giftitempopup to wardrobepopup
    TheCamera:PopScreenHOffset(self)

    if self.wardrobepopup ~= nil and self.wardrobepopup.inst:IsValid() then
        TheFrontEnd:PopScreen(self.wardrobepopup)
    end
    self.wardrobepopup =
        WardrobePopupScreen(
            self.owner,
            Profile,
            nil,
            false,
            self.recentgifts ~= nil and self.recentgifts.item_types or nil,
            self.recentgifts ~= nil and self.recentgifts.item_ids or nil
        )
    self:ClearRecentGifts()
    TheFrontEnd:PushScreen(self.wardrobepopup)
    return true
end

function PlayerHud:CloseWardrobeScreen()
    --Hack for holding offset when transitioning from giftitempopup to wardrobepopup
    TheCamera:PopScreenHOffset(self)
    self:ClearRecentGifts()

    if self.wardrobepopup ~= nil then
        if self.wardrobepopup.inst:IsValid() then
            TheFrontEnd:PopScreen(self.wardrobepopup)
        end
        self.wardrobepopup = nil
    end
end

--Helper for transferring data between screens when transitioning from giftitempopup to wardrobepopup
function PlayerHud:SetRecentGifts(item_types, item_ids)
    if self.recentgiftstask ~= nil then
        self.recentgiftstask:Cancel()
        self.recentgiftstask = nil
    end
    self.recentgifts = { item_types = item_types, item_ids = item_ids }
end

--Helper for transferring data between screens when transitioning from giftitempopup to wardrobepopup
function PlayerHud:ClearRecentGifts()
    if self.recentgiftstask ~= nil then
        self.recentgiftstask:Cancel()
        self.recentgiftstask = nil
    end
    self.recentgifts = nil
end

function PlayerHud:RefreshControllers()
    local controller_mode = TheInput:ControllerAttached()
    if self.controls.inv.controller_build ~= controller_mode then
        self.controls.inv.rebuild_pending = true
        local overflow = self.owner.replica.inventory:GetOverflowContainer()
        if overflow == nil then
            --switching to controller inv with no backpack
            --don't animate out from the backpack position
            self.controls.inv.rebuild_snapping = true
        elseif controller_mode then
            --switching to controller with backpack
            --close mouse backpack container widget
            CloseContainerWidget(self, overflow.inst, overflow:IsSideWidget())
        elseif overflow:IsOpenedBy(self.owner) then
            --switching to mouse with backpack
            --reopen backpack if it was opened
            OpenContainerWidget(self, overflow.inst, overflow:IsSideWidget())
        end
    end
end

function PlayerHud:ShowWriteableWidget(writeable, config)
    if writeable == nil then
        return
    else
        self.writeablescreen = WriteableWidget(self.owner, writeable, config)
        TheFrontEnd:PushScreen(self.writeablescreen)
        -- Have to set editing AFTER pushscreen finishes.
        self.writeablescreen.edit_text:SetEditing(true)
        return self.writeablescreen
    end
end

function PlayerHud:CloseWriteableWidget()
    if self.writeablescreen then
        self.writeablescreen:Close()
        self.writeablescreen = nil
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

        if CHEATS_ENABLED then -- Just an indicator so we can tell if we're in godmode or not
            self.inst:ListenForEvent("invincibletoggle", function(inst, data)
                if data.invincible then
                    if self.controls.godmodeindicator == nil then
                        self.controls.godmodeindicator = self.controls.inv:AddChild(UIAnim())
                        self.controls.godmodeindicator:GetAnimState():SetBank("pigman")
                        self.controls.godmodeindicator:GetAnimState():SetBuild("pig_guard_build")
                        self.controls.godmodeindicator:SetHAnchor(ANCHOR_LEFT)
                        self.controls.godmodeindicator:SetVAnchor(ANCHOR_BOTTOM)
                        self.controls.godmodeindicator:SetPosition(100, 50, 0)
                        self.controls.godmodeindicator:SetScale(0.2, 0.2, 0.2)
                        self.controls.godmodeindicator:GetAnimState():PlayAnimation("idle_happy")
                        self.controls.godmodeindicator:GetAnimState():PushAnimation("idle_loop")
                    end
                elseif self.controls.godmodeindicator then
                    self.controls.godmodeindicator:GetAnimState():PlayAnimation("death")
                    local indicator = self.controls.godmodeindicator
                    self.inst:DoTaskInTime(2, function() indicator:Kill() end)
                    self.controls.godmodeindicator = nil
                end
            end, self.owner)
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
    self.controls.crafttabs:MoveTo(self.controls.crafttabs:GetPosition(), Vector3(0, 0, 0), .25)
end

function PlayerHud:OpenControllerInventory()
    TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/craft_open")
    TheFrontEnd:StopTrackingMouse()
    self:CloseControllerCrafting()
    self:HideControllerCrafting()
    self.controls.inv:OpenControllerInventory()
    self.controls.item_notification:ToggleController(false)
    self.controls:ShowStatusNumbers()

    self.owner.components.playercontroller:OnUpdate(0)
end

function PlayerHud:CloseControllerInventory()
    TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/craft_close")
    self.controls:HideStatusNumbers()
    self:ShowControllerCrafting()
    self.controls.inv:CloseControllerInventory()
    self.controls.item_notification:ToggleController(true)
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

function PlayerHud:IsItemManagerScreenOpen()
    local active_screen = TheFrontEnd:GetActiveScreen()
    return active_screen ~= nil and active_screen.name == "GiftItemPopUp"
end

function PlayerHud:IsWardrobeScreenOpen()
    local active_screen = TheFrontEnd:GetActiveScreen()
    return active_screen ~= nil and active_screen.name == "WardrobePopupScreen"
end

function PlayerHud:IsPlayerAvatarPopUpOpen()
    return self.playeravatarpopup ~= nil
        and self.playeravatarpopup.started
        and self.playeravatarpopup.inst:IsValid()
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
    self.controls.item_notification:ToggleController(false)
end

function PlayerHud:ShowPlayerStatusScreen()
    if not self.playerstatusscreen then
        self.playerstatusscreen = PlayerStatusScreen(self.owner)
    end
    TheFrontEnd:PushScreen(self.playerstatusscreen)
    self.playerstatusscreen:MoveToFront()
    self.playerstatusscreen:Show()
end

function PlayerHud:InspectSelf()
    if self:IsVisible() and
        self.owner.components.playercontroller:IsEnabled() and
        self.owner.components.playercontroller:GetControllerTarget() == nil then
        local client_obj = TheNet:GetClientTableForUser(self.owner.userid)
        if client_obj ~= nil then
            --client_obj.inst = self.owner --don't track yourself
            self:TogglePlayerAvatarPopup(client_obj.name, client_obj)
            return true
        end
    end
end

function PlayerHud:OnControl(control, down)
    if PlayerHud._base.OnControl(self, control, down) then
        return true
    elseif not self.shown then
        return
    elseif not down and control == CONTROL_PAUSE then
        TheFrontEnd:PushScreen(PauseScreen())
        return true
    elseif down and control == CONTROL_INSPECT_SELF and self:InspectSelf() then 
        return true
    elseif self.owner == nil then
        return
    end

    --V2C: This kinda hax? Cuz we don't rly want to set focus to it I guess?
    local resurrectbutton = self.controls.status:GetResurrectButton()
    if resurrectbutton ~= nil and resurrectbutton:CheckControl(control, down) then
        return true
    elseif not down then
        if control == CONTROL_MAP then
            self.controls:ToggleMap()
            return true
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
        if not self:IsPlayerAvatarPopUpOpen() or self.playeravatarpopup.settled then
            self:ShowPlayerStatusScreen()
        end
        return true
    elseif control == CONTROL_OPEN_CRAFTING then
        if self:IsControllerCraftingOpen() then
            self:CloseControllerCrafting()
            return true
        end
        local inventory = self.owner.replica.inventory
        if inventory ~= nil and inventory:IsVisible() then
            self:OpenControllerCrafting()
            return true
        end
    elseif control == CONTROL_OPEN_INVENTORY then
        if self:IsControllerInventoryOpen() then
            self:CloseControllerInventory()
            return true
        end
        local inventory = self.owner.replica.inventory
        if inventory ~= nil and inventory:IsVisible() then
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
    elseif control >= CONTROL_INV_1 and control <= CONTROL_INV_10 then
        --inventory hotkeys
        local inventory = self.owner.replica.inventory
        if inventory ~= nil and inventory:IsVisible() then
            local item = inventory:GetItemInSlot(control - CONTROL_INV_1 + 1)
            if item ~= nil then
                self.owner.replica.inventory:UseItemFromInvTile(item)
            end
            return true
        end
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
