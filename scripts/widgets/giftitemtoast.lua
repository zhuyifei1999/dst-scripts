local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local UIAnim = require "widgets/uianim"
local UIAnimButton = require "widgets/uianimbutton"

-- Where the toast is supposed to be when it's active
local down_pos = -200
local last_click_time = 0 -- V2C: s'ok to be static
local TIMEOUT = 1

local function ClickButton()
    if not ThePlayer:HasTag("busy") then
        local time = GetTime()
        if time - last_click_time > TIMEOUT then
            last_click_time = time
            if not TheWorld.ismastersim then
                SendRPCToServer(RPC.OpenGift)
            elseif ThePlayer.components.giftreceiver ~= nil then
                ThePlayer.components.giftreceiver:OpenNextGift()
            end
        end
    end
end

local GiftItemToast = Class(Widget, function(self)
    Widget._ctor(self, "GiftItemToast")

    self.root = self:AddChild(Widget("ROOT"))

    self.tab_gift = self.root:AddChild(UIAnimButton("tab_gift", "tab_gift", nil, nil, "off", nil, nil))
    self.tab_gift:Disable()

    self.tab_gift:SetTooltip(STRINGS.UI.ITEM_SCREEN.DISABLED_TOAST_TOOLTIP)
    self.tab_gift:SetTooltipPos(0, -40, 0)
    
    if TheInput:ControllerAttached() then  
    	local controller_id = TheInput:GetControllerID()
    	self.controller_help = self.tab_gift:AddChild(Text(UIFONT, 30))
    	self.controller_help:SetString(TheInput:GetLocalizedControl(controller_id, CONTROL_CONTROLLER_ALTACTION) .. " " .. STRINGS.UI.HUD.OPENGIFT)
    	self.controller_help:SetPosition(0, -70, 0)
    	self.controller_help:Hide()
	end

    self.inst:ListenForEvent("giftreceiverupdate", function(player, data)
        self:OnToast(data.numitems)
        if data.active then
            self:EnableClick()
        else
            self:DisableClick()
        end
    end, ThePlayer)

    self.numitems = 0

    self.tab_gift:SetOnClick(ClickButton)
    self.tab_gift:SetOnFocus( -- Play the active animation
        function()
            self.tab_gift.animstate:PlayAnimation("active_pre", false)
            self.tab_gift:SetLoop("active_loop", true)
            self.tab_gift.animstate:PushAnimation("active_loop", true)
        end
    )

    self.controller_hide = false
    self.craft_hide = false
    self.opened = false
    self.enabled = false
    last_click_time = 0
end)

-- Moves the toast up or down
function GiftItemToast:UpdateElements()
    local from = self.root:GetPosition()
    if not self.controller_hide and not self.craft_hide and self.numitems > 0 then
        if not self.opened then
            self.opened = true
            last_click_time = 0

            local to = Vector3(0, down_pos, 0)

            -- We don't need to move if we're already in position
            if from ~= to then
                TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/skin_drop_slide_gift_DOWN")
                self.root:MoveTo(from, to, 1.0,
                    function()
                        --check we're still opened, cuz we don't cancel MoveTo
                        if self.opened then
                            if self:IsVisible() then
                                TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/skin_drop_slide_gift_BOTTOM_HIT")
                            end
                            if self.tab_gift:IsEnabled() then
                                self:OnClickEnabled()
                            end
                        end
                    end
                )
            end
        end
    elseif self.opened then
        self.opened = false
        local to = Vector3(0, 0, 0)
        if from ~= to then
            if self:IsVisible() then
                TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/skin_drop_slide_gift_UP")
            end
            self.root:MoveTo(from, to, 0.5, nil)
        end
    end
end

function GiftItemToast:ToggleController(show)
    self.controller_hide = show
    self:UpdateElements()
end

function GiftItemToast:ToggleCrafting(show)
    self.craft_hide = show
    self:UpdateElements()
end

function GiftItemToast:OnToast(num)
    if num == 0 then
        self.tab_gift:Disable()
    end

    self.numitems = num

    self:UpdateElements()
end

function GiftItemToast:OnControl(control, down)
	if GiftItemToast._base.OnControl(self, control, down) then return true end

	if control == CONTROL_CONTROLLER_ALTACTION and self.enabled then
		if down then 
			ClickButton()
		end
	end
end

function GiftItemToast:EnableClick()
    if self.numitems > 0 then
        self.tab_gift:Enable()
        last_click_time = 0

        local current_pos = self.root:GetPosition()
        if current_pos.y == down_pos then
            self:OnClickEnabled()
        end
    end
end

-- Handles animation stuff and such
function GiftItemToast:OnClickEnabled()
    if not self.tab_gift.animstate:IsCurrentAnimation("active_pre") then
        self.tab_gift.animstate:PlayAnimation("active_pre", false)
        self.tab_gift:SetLoop("active_loop", true)
        self.tab_gift:PushIdleAnim("active_loop", true)
    end

    self.tab_gift:SetTooltip(STRINGS.UI.ITEM_SCREEN.ENABLED_TOAST_TOOLTIP)

    if self:IsVisible() then
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/skin_tab_active")
        if TheInput:ControllerAttached() then 
        	self.controller_help:Show()
        end
        self.enabled = true
    end
end

function GiftItemToast:DisableClick()
    self.tab_gift:Disable()
    self.tab_gift:SetTooltip(STRINGS.UI.ITEM_SCREEN.DISABLED_TOAST_TOOLTIP)
    self.enabled = false
    if self.controller_help then 
    	self.controller_help:Hide()
    end
end

return GiftItemToast
