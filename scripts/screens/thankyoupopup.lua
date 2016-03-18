local Screen = require "widgets/screen"
local Button = require "widgets/button"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"

require "skinsutils"

local ThankYouPopup = Class(Screen, function(self, items, bgatlas, bgimage, logoatlas, logoimage, callbackfn)
    Screen._ctor(self, "ThankYouPopup")

    bgatlas = bgatlas or "images/ui.xml"
    bgimage = bgimage or "black.tex"
    logoatlas = logoatlas or "images/ui.xml"
    logoimage = logoimage or "klei_new_logo.tex"

    self.callbackfn = callbackfn

    --darken everything behind the dialog
    self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black:SetTint(0,0,0,.75)
    
    self.proot = self:AddChild(Widget("ROOT"))
    self.proot:SetVAnchor(ANCHOR_MIDDLE)
    self.proot:SetHAnchor(ANCHOR_MIDDLE)
    self.proot:SetPosition(0,0,0)
    self.proot:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.bg = self.proot:AddChild(Image(bgatlas, bgimage))
    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg:SetScale(.97)
    
    --title 
    self.title = self.proot:AddChild(Text(BUTTONFONT, 60))
    self.title:SetPosition(-70, 235, 0)
    self.title:SetString(STRINGS.UI.ITEM_SCREEN.THANKS_POPUP_TITLE)    
    
    -- Logo
    self.logo_img = self.proot:AddChild(Image(logoatlas, logoimage))
    self.logo_img:SetVRegPoint(ANCHOR_MIDDLE)
    self.logo_img:SetHRegPoint(ANCHOR_MIDDLE)
    self.logo_img:SetScale(.9,.9,.9)
    self.logo_img:SetPosition(155, 215, 0)

    -- Actual animation
    self.spawn_portal = self.proot:AddChild(UIAnim())
    self.spawn_portal:SetScale(.6)
    self.spawn_portal:SetPosition(0, -55, 0)
    self.spawn_portal:GetAnimState():SetBuild("skingift_popup") -- file name
    self.spawn_portal:GetAnimState():SetBank("gift_popup") -- top level symbol

    self.banner = self.proot:AddChild(Image("images/giftpopup.xml", "banner.tex"))
    self.banner:SetPosition(0, -185, 0)
    self.banner:SetScale(.9)

    -- Name of the received item, parented to the banner so they show and hide together
    self.item_name = self.banner:AddChild(Text(BUTTONFONT, 55))
    self.item_name:SetString("Dragonfly Backpack")
    self.item_name:SetPosition(0, -10, 0)

    self.banner:Hide()

    -- Text saying "you received" on the upper banner
    self.upper_banner_text = self.proot:AddChild(Text(BUTTONFONT, 32, STRINGS.UI.ITEM_SCREEN.RECEIVED))
    self.upper_banner_text:SetPosition(0, 48, 0)


    self.right_btn = self.proot:AddChild(ImageButton("images/lobbyscreen.xml", "DSTMenu_PlayerLobby_arrow_paper_R.tex", "DSTMenu_PlayerLobby_arrow_paperHL_R.tex"))
    self.right_btn:SetPosition(275, -55, 0)
    self.right_btn:SetScale(0.6)
    self.right_btn:SetOnClick(
        function() -- Item navigation
            self.current_item = self.current_item + 1 
            self:NewGift() 
        end)


    self.left_btn = self.proot:AddChild(ImageButton("images/lobbyscreen.xml", "DSTMenu_PlayerLobby_arrow_paper_L.tex", "DSTMenu_PlayerLobby_arrow_paperHL_L.tex"))
    self.left_btn:SetPosition(-275, -55, 0)
    self.left_btn:SetScale(0.6)
    self.left_btn:SetOnClick(
        function() -- Item navigation
            self.current_item = self.current_item - 1 
            self:NewGift() 
        end)

    -- Open skin button
    self.open_btn = self.proot:AddChild(ImageButton("images/ui.xml", "button_large.tex", "button_large_over.tex", "button_large_disabled.tex"))
    self.open_btn:SetFont(BUTTONFONT)
    self.open_btn:SetText(STRINGS.UI.ITEM_SCREEN.OPEN_BUTTON)
    self.open_btn:SetScale(0.85)
    self.open_btn:SetPosition(0, -280, 0)
    self.open_btn:SetOnClick(function() self:OpenGift() end)
    self.open_btn:Hide()

    -- Close popup button, only shows up after ALL skins have been opened
    self.close_btn = self.proot:AddChild(ImageButton("images/ui.xml", "button_large.tex", "button_large_over.tex", "button_large_disabled.tex"))
    self.close_btn:SetFont(BUTTONFONT)
    self.close_btn:SetText(STRINGS.UI.ITEM_SCREEN.OK_BUTTON)
    self.close_btn:SetScale(0.85)
    self.close_btn:SetPosition(0, -280, 0)
    self.close_btn:SetOnClick(function() self:GoAway() end)
    self.close_btn:Hide()

    self.items = items
    self.revealed_items = {}
    self.current_item = 1

    self:EvaluateArrows()
    self:NewGift()
end)

function ThankYouPopup:OnUpdate(dt)
    if self.spawn_portal:GetAnimState():IsCurrentAnimation("skin_loop") then
        -- We just revealed a new skin
        if self.reveal_skin then
            self.reveal_skin = false
            self:EvaluateArrows()
            self:SetSkinName()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/player_recieves_gift_idle", "gift_idle")
        -- We just navigated to an already revealed skin
        elseif self.transitioning then
            self.transitioning = false
            self:SetSkinName()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/player_recieves_gift_idle", "gift_idle")
        end
    -- We're closing the popup
    elseif self.spawn_portal:GetAnimState():IsCurrentAnimation("skin_out") and self.spawn_portal:GetAnimState():AnimDone() then
        TheFrontEnd:PopScreen(self)
        if self.callbackfn then 
            self.callbackfn()
        end
    -- We just navigated to an unrevealed skin
    elseif self.spawn_portal:GetAnimState():IsCurrentAnimation("idle") and self.transitioning then
        self.transitioning = false
        self.open_btn:Show()
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/player_recieves_gift_idle", "gift_idle")
    end
end

-- Sets the name of the skin on the banner and enables the close button if needed
function ThankYouPopup:SetSkinName()
    
    local skin_name = string.lower(self.items[self.current_item])
    local name_string = GetName(skin_name) 

    local itemtype = GetTypeForItem(skin_name)
    local rarity = GetRarityForItem(itemtype, skin_name)
    self.item_name:SetColour(SKIN_RARITY_COLORS[rarity])
    self.item_name:SetString(name_string or skin_name or "bad item name")
    self.banner:Show()

    local revealed_items_size = 0
    for k,v in pairs(self.revealed_items) do
        revealed_items_size = revealed_items_size + 1
    end

    if revealed_items_size == #self.items then
        self.close_btn:Show()
    end

end

-- Enables or disables arrows according to our current item
function ThankYouPopup:EvaluateArrows()
    if #self.items == 1 then
        self.right_btn:Hide()
        self.left_btn:Hide()
        return
    end

    if self.current_item == #self.items then
        self.right_btn:Hide()
        self.left_btn:Show()
    elseif self.current_item == 1 then
        self.right_btn:Show()
        self.left_btn:Hide()
    else
        self.right_btn:Show()
        self.left_btn:Show()
    end
end

-- Sets the new Gift after we navigated
function ThankYouPopup:NewGift()

    self.banner:Hide()

    if not self.revealed_items[self.current_item] then -- Unopened item
    	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/player_receives_gift_animation_spin")
        self.spawn_portal:GetAnimState():PlayAnimation("activate")
        self.spawn_portal:GetAnimState():PushAnimation("idle", true)
        self.open_btn:Hide()
        self.close_btn:Hide()
    else -- Already opened item
        local build = GetBuildForItem(GetTypeForItem(self.items[self.current_item]), self.items[self.current_item])
        self.spawn_portal:GetAnimState():OverrideSkinSymbol("SWAP_ICON", build, "SWAP_ICON")
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/player_receives_gift_animation_spin")
        self.spawn_portal:GetAnimState():PlayAnimation("skin_in")
        self.spawn_portal:GetAnimState():PushAnimation("skin_loop", true)
        self.close_btn:Hide()
        self.open_btn:Hide()
    end

    self.transitioning = true
    self:EvaluateArrows()

end

-- Plays the closing animation
function ThankYouPopup:GoAway()
	TheFrontEnd:GetSound():KillSound("gift_idle")
	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/player_receives_gift_animation_skinout")
    self.spawn_portal:GetAnimState():PlayAnimation("skin_out")
    
    self.banner:Hide()
    self.right_btn:Hide()
    self.left_btn:Hide()
    self.close_btn:Hide()
end

-- Plays the open gift animation
function ThankYouPopup:OpenGift()
    self.open_btn:Hide()
    self.right_btn:Hide()
    self.left_btn:Hide()

    local skin_name = self.items[self.current_item]
    local build = GetBuildForItem(GetTypeForItem(skin_name), skin_name)

    self.spawn_portal:GetAnimState():OverrideSkinSymbol("SWAP_ICON", build, "SWAP_ICON")

    TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/player_receives_gift_animation")
    self.spawn_portal:GetAnimState():PlayAnimation("open")
    self.spawn_portal:GetAnimState():PushAnimation("skin_loop", true)

    -- Mark the item as revealed
    self.revealed_items[self.current_item] = true
    self.reveal_skin = true -- Used on update
    --TODO: set the item as opened here

end

function ThankYouPopup:OnControl(control, down)
    if ThankYouPopup._base.OnControl(self,control, down) then 
        return true 
    end
end

return ThankYouPopup