local Widget = require "widgets/widget"
local Screen = require "widgets/screen"
local Button = require "widgets/button"
local Menu = require "widgets/menu"
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

    self.dressup = self.root:AddChild(DressupPanel(self, profile, nil, nil, character_loadout_screen, recent_item_types, recent_item_ids))
    self.dressup:SetPosition(-250, 0)
    self.dressup:SetCurrentCharacter(character or owner.prefab)

    self.heroportrait = self.root:AddChild(Image())
    self.heroportrait:SetScale(.75)
    self.heroportrait:SetPosition(475, 400)
    self:SetPortrait()

    local spacing = 225
    local buttons = {}

    local offline = not TheNet:IsOnlineMode()

    if offline then 
    	buttons = {{text = STRINGS.UI.POPUPDIALOG.OK, cb = function() self:Close() end}}
    else
    	buttons = {{text = STRINGS.UI.WARDROBE_POPUP.CANCEL, cb = function() self:Cancel() end}, 
                     {text = STRINGS.UI.WARDROBE_POPUP.RESET, cb = function() self:Reset() end},
                     {text = STRINGS.UI.WARDROBE_POPUP.SET, cb = function() self:Close() end},
                  }
    end

    self.menu = self.proot:AddChild(Menu(buttons, spacing, true))
    self.menu:SetPosition(-230, -280, 0) 

    if offline then 
		self.menu:SetPosition(0, -280, 0)
    end
   
	self.default_focus = self.menu

	self.dressup:ReverseFocus()
	self.menu.reverse = true

    if owner ~= nil then
        TheCamera:PushScreenHOffset(self, SCREEN_OFFSET)
    end

    self:DoFocusHookups()
end)

function WardrobePopupScreen:OnDestroy()
    if self.owner ~= nil then
        TheCamera:PopScreenHOffset(self)
    end
    self._base.OnDestroy(self)
end

function WardrobePopupScreen:DoFocusHookups()
	self.menu:SetFocusChangeDir(MOVE_UP, self.dressup)
    self.dressup:SetFocusChangeDir(MOVE_DOWN, self.menu)
end

function WardrobePopupScreen:OnControl(control, down)
    if WardrobePopupScreen._base.OnControl(self,control, down) then return true end
    
    if control == CONTROL_CANCEL and not down then    
        self:Cancel()
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        return true
    end
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
	local controller_id = TheInput:GetControllerID()
	local t = {}
    table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.CANCEL)
	return table.concat(t, "  ")
	
end

return WardrobePopupScreen