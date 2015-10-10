local Screen = require "widgets/screen"
local Button = require "widgets/button"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"


local UnopenedItemPopup = Class(Screen, function(self, items)
    Screen._ctor(self, "UnopenedItemPopup")

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

    -- Sets the bg image
    self.bg = self.proot:AddChild(Image("images/rog_item_popup_2.xml", "blank_shield.tex"))
    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg:SetScale(.97)
    
    --title 
    self.title = self.proot:AddChild(Text(BUTTONFONT, 60))
    self.title:SetPosition(0, 235, 0)
    self.title:SetString(STRINGS.UI.ITEM_SCREEN.RECEIVED)    

    -- Actual animation
    self.spawn_portal = self.proot:AddChild(UIAnim())
    self.spawn_portal:SetScale(.6)
    self.spawn_portal:SetPosition(0, 0, 0)
    self.spawn_portal:GetAnimState():SetBuild("skingift_popup") -- file name
    self.spawn_portal:GetAnimState():SetBank("gift_popup") -- top level symbol

    self.banner = self.proot:AddChild(Image("images/giftpopup.xml", "banner.tex"))
    self.banner:SetPosition(0, -205, 0)
    self.banner:SetScale(.9)

    -- Name of the received item, parented to the banner so they show and hide together
    self.item_name = self.banner:AddChild(Text(UIFONT, 55))
    self.item_name:SetString("ITEM_NAME")
    self.item_name:SetPosition(0, -10, 0)

    self.banner:Hide()

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

function UnopenedItemPopup:OnUpdate(dt)
    if self.spawn_portal:GetAnimState():IsCurrentAnimation("skin_loop") then
        -- We just revealed a new skin
        if self.reveal_skin then
        	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/player_recieves_gift_idle", "gift_idle")
            self.reveal_skin = false
            self:EvaluateArrows()
            self:SetSkinName()
        -- We just navigated to an already revealed skin
        elseif self.transitioning then
        	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/player_recieves_gift_idle", "gift_idle")
            self.transitioning = false
            self:SetSkinName()
        end
    -- We're closing the popup
    elseif self.spawn_portal:GetAnimState():IsCurrentAnimation("skin_out") and self.spawn_portal:GetAnimState():AnimDone() then
        TheFrontEnd:PopScreen(self)
    -- We just navigated to an unrevealed skin
    elseif self.spawn_portal:GetAnimState():IsCurrentAnimation("idle") and self.transitioning then
    	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/player_recieves_gift_idle", "gift_idle")
        self.transitioning = false
        self.open_btn:Show()
    end
end

-- Sets the name of the skin on the banner and enables the close button if needed
function UnopenedItemPopup:SetSkinName()
    
    local skin_name = string.lower(self.items[self.current_item].item_type)
    local name_string = STRINGS.SKIN_NAMES[skin_name]

    local skin_data
    if CLOTHING[skin_name] ~= nil then
        skin_data = CLOTHING[skin_name]
    else
        skin_data = Prefabs[skin_name]
    end
    
    local rarity = "Common"
    if skin_data and skin_data.rarity then
        rarity = skin_data.rarity
    end

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
function UnopenedItemPopup:EvaluateArrows()
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
function UnopenedItemPopup:NewGift()

    self.banner:Hide()

    if not self.revealed_items[self.current_item] then -- Unopened item
    	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/player_receives_gift_animation_spin")
        self.spawn_portal:GetAnimState():PlayAnimation("activate")
        self.spawn_portal:GetAnimState():PushAnimation("idle", true)
        self.open_btn:Hide()
        self.close_btn:Hide()
    else -- Already opened item
        self.spawn_portal:GetAnimState():OverrideSkinSymbol("SWAP_ICON", self.items[self.current_item].item_type, "SWAP_ICON")
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/player_receives_gift_animation_spin")
        self.spawn_portal:GetAnimState():PlayAnimation("skin_in")
        self.inst:DoTaskInTime(51/FRAMES, function() TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/player_receives_gift_idle") end)
        self.spawn_portal:GetAnimState():PushAnimation("skin_loop", true)
        self.close_btn:Hide()
        self.open_btn:Hide()
    end

    self.transitioning = true
    self:EvaluateArrows()

end

-- Plays the closing animation
function UnopenedItemPopup:GoAway()
	TheFrontEnd:GetSound():KillSound("gift_idle")
	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/player_receives_gift_animation_skinout")
    self.spawn_portal:GetAnimState():PlayAnimation("skin_out")
    
    self.banner:Hide()
    self.right_btn:Hide()
    self.left_btn:Hide()
    self.close_btn:Hide()
end

-- Plays the open gift animation
function UnopenedItemPopup:OpenGift()
    self.open_btn:Hide()
    self.right_btn:Hide()
    self.left_btn:Hide()

    local skin_name = string.lower(self.items[self.current_item].item_type)
    if CLOTHING[skin_name] == nil then -- Is it a craftable?
        local skin_data = Prefabs[skin_name]
        if skin_data ~= nil then
			self.spawn_portal:GetAnimState():OverrideSkinSymbol("SWAP_ICON", skin_data.ui_preview.build, "SWAP_ICON")
		end
    else -- Nope, it's actually normal clothing
         self.spawn_portal:GetAnimState():OverrideSkinSymbol("SWAP_ICON", skin_name, "SWAP_ICON")
    end

    TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/player_receives_gift_animation")
    self.spawn_portal:GetAnimState():PlayAnimation("open")
    self.spawn_portal:GetAnimState():PushAnimation("skin_loop", true)

    -- Mark the item as revealed
    self.revealed_items[self.current_item] = true
    self.reveal_skin = true -- Used on update

    TheInventory:SetItemOpened( self.items[self.current_item].item_id ) -- Marks the items as opened on the backend

end

function UnopenedItemPopup:OnControl(control, down)
    if UnopenedItemPopup._base.OnControl(self,control, down) then 
        return true
    end
end

return UnopenedItemPopup