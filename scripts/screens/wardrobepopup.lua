local Widget = require "widgets/widget"
local Screen = require "widgets/screen"
local Button = require "widgets/button"
local DressupPanel = require "widgets/dressuppanel"
local TEMPLATES = require "widgets/templates"

local SCREEN_OFFSET = -.285 * RESOLUTION_X

local WardrobePopupScreen = Class(Screen, function(self, owner, profile, character, character_loadout_screen, recent_item_types, recent_item_ids)
	Screen._ctor(self, "WardrobePopupScreen")

    self.owner = owner --can be nil in FE, otherwise should be ThePlayer in HUD
	self.profile = profile

    if character_loadout_screen then
        --darken everything behind the dialog
        self.black = self:AddChild(Image("images/global.xml", "square.tex"))
        self.black:SetVRegPoint(ANCHOR_MIDDLE)
        self.black:SetHRegPoint(ANCHOR_MIDDLE)
        self.black:SetVAnchor(ANCHOR_MIDDLE)
        self.black:SetHAnchor(ANCHOR_MIDDLE)
        self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
        self.black:SetTint(0,0,0,.75)
    end

    --V2C: @liz
    -- recent_item_types and recent_item_ids are both tables of
    -- items that were just opened in the gift item popup.
    --
    -- Both params are nil if we did not come from GiftItemPopup.
    --
    -- They should be both in the same order, so recent_item_types[1]
    -- corresponds to recent_item_ids[1].
    -- (This is the exact same data that is passed into GiftItemPopup.)
    --
    -- Currently, it is safe to assume there will only be 1 item.
    --
    -- recent_item_ids is probably useless if we're only showing one
    -- of each item type in the spinners, and you should just match
    -- by recent_item_types[1].

	self.proot = self:AddChild(Widget("ROOT"))
    self.proot:SetVAnchor(ANCHOR_MIDDLE)
    self.proot:SetHAnchor(ANCHOR_MIDDLE)
    --self.proot:SetPosition(-13,12,0)
    self.proot:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.root = self.proot:AddChild(Widget("root"))
    self.root:SetPosition(-RESOLUTION_X/2, -RESOLUTION_Y/2, 0)

    self.dressup = self.root:AddChild(DressupPanel(self, profile, nil, nil, character_loadout_screen))
    self.dressup:SetPosition(-250, 0)
    self.dressup:SetCurrentCharacter(character or owner.prefab)

    self.heroportrait = self.root:AddChild(Image())
    self.heroportrait:SetScale(.75)
    self.heroportrait:SetPosition(475, 400)
    self:SetPortrait()
    
	self.cancelbutton = self.proot:AddChild(TEMPLATES.Button(STRINGS.UI.WARDROBE_POPUP.CANCEL, function() self:Cancel() end))
	self.cancelbutton:SetPosition(-230, -280)
	
    self.resetbutton = self.proot:AddChild(TEMPLATES.Button(STRINGS.UI.WARDROBE_POPUP.RESET, function() self:Reset() end))
	self.resetbutton:SetPosition(-5, -280)

	self.setbutton = self.proot:AddChild(TEMPLATES.Button(STRINGS.UI.WARDROBE_POPUP.SET, function() self:Close() end))
	self.setbutton:SetPosition(220, -280)		
	
    if owner ~= nil then
        TheCamera:PushScreenHOffset(self, SCREEN_OFFSET)
    end
end)

function WardrobePopupScreen:OnDestroy()
    if self.owner ~= nil then
        TheCamera:PopScreenHOffset(self)
    end
    self._base.OnDestroy(self)
end

function WardrobePopupScreen:OnControl(control, down)
    if WardrobePopupScreen._base.OnControl(self,control, down) then return true end
    
    --[[if control == CONTROL_CANCEL and not down then    
        if #self.buttons > 1 and self.buttons[#self.buttons] then
            self.buttons[#self.buttons].cb()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
            return true
        end
    end]]
end

function WardrobePopupScreen:Cancel()
	self:Reset()
	self:Close()
end

function WardrobePopupScreen:Reset()
	self.dressup:Reset()
	self:SetPortrait()
end

function WardrobePopupScreen:Close()
    -- Gets the current skin names (and sets them as the character default)
    local skins = self.dressup:GetSkinsForGameStart()

    if self.owner ~= nil then
        local data = {}
        if TheNet:IsOnlineMode() then
            data.base = skins.base
            data.body = skins.body
            data.hand = skins.hand
            data.legs = skins.legs
        end

        if not TheWorld.ismastersim then
            SendRPCToServer(RPC.CloseWardrobe, data.base, data.body, data.hand, data.legs)
        elseif self.owner ~= nil then
            self.owner:PushEvent("ms_closewardrobe", data)
        end
    end

    self.dressup:OnClose()
    TheFrontEnd:PopScreen(self)
end

function WardrobePopupScreen:SetPortrait()
	local herocharacter = self.dressup.currentcharacter

	if herocharacter ~= nil then
		
		local skin = "_none"

		-- TODO: get correct skin here if bases are enabled
		self.heroportrait:SetTexture("bigportraits/" .. herocharacter..".xml", herocharacter .. skin .. ".tex", herocharacter .. ".tex")
	end
end

function WardrobePopupScreen:GetHelpText()
	--[[local controller_id = TheInput:GetControllerID()
	local t = {}
	if #self.buttons > 1 and self.buttons[#self.buttons] then
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)	
    end
	return table.concat(t, "  ")
	]]
end

return WardrobePopupScreen