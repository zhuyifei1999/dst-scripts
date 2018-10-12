local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local UIAnim = require "widgets/uianim"
local Image = require "widgets/image"
local OnlineStatus = require "widgets/onlinestatus"
local PopupDialogScreen = require "screens/redux/popupdialog"
local GenericWaitingPopup = require "screens/redux/genericwaitingpopup"
local ItemBoxOpenerPopup = require "screens/redux/itemboxopenerpopup"

local TEMPLATES = require("widgets/redux/templates")
local PURCHASE_INFO = require("skin_purchase_packs")
require("misc_items")


local PurchasePackScreen = Class(Screen, function(self)
	Screen._ctor(self, "PurchasePackScreen")
	self:DoInit()

	Profile:SetShopHash( CalculateShopHash() )

	self.default_focus = self.purchase_root
end)

function PurchasePackScreen:DoInit()
    self.root = self:AddChild(TEMPLATES.ScreenRoot())

    self.bg = self.root:AddChild(TEMPLATES.PlainBackground())

    self.title = self.root:AddChild(TEMPLATES.ScreenTitle(STRINGS.UI.PURCHASEPACKSCREEN.TITLE, ""))
    self.onlinestatus = self.root:AddChild(OnlineStatus(true))

    self.purchase_root = self:_BuildPurchasePanel()
    
    if not TheInput:ControllerAttached() then 
        self.back_button = self.root:AddChild(TEMPLATES.BackButton(
                function()
                    TheFrontEnd:FadeBack()
                end
            ))
    end
end

local build_price = function( currency_code, cents )
	local whole = tostring(cents / 100)
	return currency_code .. " " .. whole
end
local PurchaseWidget = Class(Widget, function(self, screen_self)
	Widget._ctor(self, "PurchaseWidget")

	self.root  = self:AddChild(Widget("purchase_item_root"))
    self.root:SetScale(0.90)
    self.item_type = nil
        
    self.frame = self.root:AddChild(Image("images/fepanels_redux_shop_panel.xml", "shop_panel.tex"))
    self.frame:SetScale(0.55)
    self.frame:SetPosition(-10,-7)
    
    self.icon_root = self.root:AddChild(Widget("icon_root"))
	self.icon_root:SetPosition(-150, 0)

	self.icon_anim = self.icon_root:AddChild(UIAnim())
	self.icon_anim:GetAnimState():SetBuild("frames_comp")
	self.icon_anim:GetAnimState():SetBank("fr")
	self.icon_anim:GetAnimState():Hide("frame")
	self.icon_anim:GetAnimState():Hide("NEW")
	self.icon_anim:GetAnimState():PlayAnimation("icon")
	self.icon_anim:SetScale(1.75)

    self.icon_image = self.icon_root:AddChild(Image())
    self.icon_image:SetScale(0.35)
	
    self.text_root = self.root:AddChild(Widget("text_root"))
	self.title = self.text_root:AddChild(Text(HEADERFONT, 25, nil, UICOLOURS.GOLD_SELECTED))
	self.title:SetPosition(0, 6)
	self.text = self.text_root:AddChild(Text(CHATFONT, 22, nil, UICOLOURS.GREY))
	self.text:SetPosition(0, -55)
	self.text:SetRegionSize(245, 60)
	self.text:EnableWordWrap(true)

    local purchasefn = 
        function()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/collectionscreen/purchase")

            local commerce_popup = GenericWaitingPopup("ItemServerContactPopup", STRINGS.UI.ITEM_SERVER.CONNECT, nil, true)
            TheFrontEnd:PushScreen(commerce_popup)

            TheItems:StartPurchase(self.item_type, function(success, message)
                self.inst:DoTaskInTime(0, function()  --we need to delay a frame so that the popping of the screens happens at the right time in the frame.
                    commerce_popup:Close()
                    if success then
                        local display_items = PURCHASE_INFO.PACKS[self.item_type]
                        local options = {
                            allow_cancel = false,
                            box_build = GetBoxBuildForItem(self.item_type),
                            use_bigportraits = IsPackFeatured(self.item_type),
                        }
                        
                        local box_popup = ItemBoxOpenerPopup(screen_self, options, function(success_cb)
                            success_cb(display_items)
                        end)
                        TheFrontEnd:PushScreen(box_popup)

                    elseif message == "CANCELLED" then
                        -- If the user just cancelled, then everything's fine.

                    else
                        local body_text = STRINGS.UI.ITEM_SERVER[message] or STRINGS.UI.ITEM_SERVER.FAILED_DEFAULT
                        local server_error = PopupDialogScreen(STRINGS.UI.ITEM_SERVER.FAILED_TITLE, body_text,
                            {
                                {
                                    text=STRINGS.UI.TRADESCREEN.OK,
                                    cb = function()
                                        print("ERROR: Failed to contact the item server.", message )
                                        TheFrontEnd:PopScreen()
                                        if message == "FAILED_DEFAULT" then
                                            SimReset()
                                        end
                                    end
                                }
                            }
                            )
                        TheFrontEnd:PushScreen( server_error )
                    end
                end, self)
            end)
        end

    local onPurchaseClickFn = 
        function()
            if OwnsSkinPack(self.item_type) then
                local warning = PopupDialogScreen(STRINGS.UI.PURCHASEPACKSCREEN.PURCHASE_WARNING_TITLE, STRINGS.UI.PURCHASEPACKSCREEN.PURCHASE_WARNING_DESC, 
                            {
                                {text=STRINGS.UI.PURCHASEPACKSCREEN.PURCHASE_WARNING_OK, cb = function() 
                                    TheFrontEnd:PopScreen()
                                    purchasefn() 
                                end },
                                {text=STRINGS.UI.PURCHASEPACKSCREEN.PURCHASE_WARNING_CANCEL, cb = function() 
                                    TheFrontEnd:PopScreen()
                                end },
                            })
                TheFrontEnd:PushScreen( warning )    
            else
                purchasefn()
            end
        end

    self.button = self.text_root:AddChild(TEMPLATES.StandardButton(
			onPurchaseClickFn,
			nil,
			{230, 50}
		)
	)
    
    --second button for dlcid
	local onDLCGiftClickFn = 
        function()
			local body_text = subfmt(STRINGS.UI.PURCHASEPACKSCREEN.PURCHASE_GIFT_INFO_BODY, {pack_name=GetSkinName(self.button_dlc.item_type) })
			local instructions = PopupDialogScreen(STRINGS.UI.PURCHASEPACKSCREEN.PURCHASE_GIFT_INFO_TITLE, body_text, 
				{
					{text=STRINGS.UI.PURCHASEPACKSCREEN.OK, cb = function() 
							TheFrontEnd:PopScreen()
							VisitURL("http://store.steampowered.com/app/"..tostring(self.button_dlc.steam_dlc_id))
						end
					},
				}
			)
			TheFrontEnd:PushScreen( instructions )
		end
    self.button_dlc = self.text_root:AddChild(TEMPLATES.StandardButton(
			onDLCGiftClickFn,
			STRINGS.UI.PURCHASEPACKSCREEN.PURCHASE_GIFT,
			{230, 50}
		)
	)
    

    self.OnGainFocus = function()
        PurchasePackScreen._base.OnGainFocus(self)
        screen_self.purchase_root.scroll_window.grid:OnWidgetFocus(self)
    end
    
    self.focus_forward = self.button
end)

function PurchaseWidget:ApplyDataToWidget(iap_def)
    if iap_def and not iap_def.is_blank then
        self.item_type = iap_def.item_type

        local title = GetSkinName(self.item_type)
        local text = GetSkinDescription(self.item_type)
        local price = ""
        if IsSteam() then
            price = build_price( iap_def.currency_code, iap_def.cents )
        elseif IsRail() then
            price = iap_def.rail_price .. " RMB"
        end
        self.button:SetText(subfmt(STRINGS.UI.PURCHASEPACKSCREEN.PURCHASE_BTN, {price = price}))

        self.icon_image:Hide()
        self.icon_anim:Hide()
        local image = GetPurchaseDisplayForItem(self.item_type)
        if image then
            self.icon_image:SetTexture(unpack(image))
            self.icon_image:Show()
        else
            self.icon_anim:GetAnimState():OverrideSkinSymbol("SWAP_ICON", GetBuildForItem(self.item_type), "SWAP_ICON")
            self.icon_anim:Show()
        end


        self.title:SetString(title)
        self.text:SetString(text)

        if IsPackFeatured(self.item_type) then
            self.frame:SetTexture("images/fepanels_redux_shop_panel_wide.xml", "shop_panel_wide.tex")
            self.frame:SetScale(0.542)
            self.frame:SetPosition(235, -7)
            self.icon_root:SetPosition(-70, -5)
            self.icon_image:SetScale(0.30)
            self.text_root:SetScale(1.2)
            self.text_root:SetPosition(390, 60)
            self.title:SetHAlign(ANCHOR_LEFT)
            self.title:SetRegionSize(500,25)
            self.text:SetHAlign(ANCHOR_LEFT)
            self.text:SetRegionSize(500,75)
            self.button:SetPosition(-130,-115)
            
            if IsSteam() and IsPackGiftable(self.item_type) then
				self.button_dlc:Show()
				self.button_dlc:SetPosition(110,-115)
				self.button_dlc.item_type = self.item_type
				self.button_dlc.steam_dlc_id = GetPackGiftDLCID(self.item_type)
			else
				self.button_dlc:Hide()
				self.button_dlc.item_type = nil
				self.button_dlc.steam_dlc_id = nil
			end
			
			--Deal with focus hacks for featured widget with multiple buttons
			self.button:SetFocusChangeDir(MOVE_RIGHT, self.button_dlc)
			self.button_dlc:SetFocusChangeDir(MOVE_LEFT, self.button)
			self:SetFocusChangeDir(MOVE_RIGHT, nil)
			
		else
            self.frame:SetTexture("images/fepanels_redux_shop_panel.xml", "shop_panel.tex")
            self.frame:SetScale(0.55)
            self.frame:SetPosition(-10,-7)
            self.icon_root:SetPosition(-140, 0)
            self.icon_image:SetScale(0.35)
            self.text_root:SetScale(1)
            self.text_root:SetPosition(60, 50)
            self.title:SetHAlign(ANCHOR_MIDDLE)
            self.title:SetRegionSize(245, 60)
            self.text:SetHAlign(ANCHOR_MIDDLE)
            self.text:SetRegionSize(245, 75)
            self.button:SetPosition(0,-120)
            self.button_dlc:Hide()
            self.button_dlc.item_type = nil
			self.button_dlc.steam_dlc_id = nil
        end

        self.root:Show()
        
        self.ongainfocusfn = nil
    else
        -- Important that we hide a sub-element and not self because TrueScrollList manages our visiblity!
        self.root:Hide()
        
        if iap_def and iap_def.is_blank then
			--rather than focus forward, we don't know the widget from here, so manually do a FocusMove next frame.
			self.ongainfocusfn = function()
				self.inst:DoTaskInTime(0, function() TheFrontEnd:OnFocusMove(MOVE_LEFT, true) end )
			end
		end
    end
end

function PurchasePackScreen:_BuildPurchasePanel()
    local purchase_ss = self.root:AddChild(Widget("purchase_ss"))
  
    -- Overlay is how we display purchasing.
    if PLATFORM == "WIN32_RAIL" or TheNet:IsNetOverlayEnabled() then
        local unvalidated_iap_defs = TheItems:GetIAPDefs()
        local iap_defs = {}
        for i,iap in ipairs(unvalidated_iap_defs) do
            -- Don't show items unless we have data/strings to describe them.
            if MISC_ITEMS[iap.item_type] then
                table.insert(iap_defs, iap)
            end
        end
        if #iap_defs == 0 then
            local msg = STRINGS.UI.PURCHASEPACKSCREEN.NO_PACKS_FOR_SALE
            if IsAnyFestivalEventActive() then
                msg = STRINGS.UI.PURCHASEPACKSCREEN.FAILED_TO_LOAD
            end
            local dialog = purchase_ss:AddChild(TEMPLATES.CurlyWindow(400, 200, "", nil, nil, msg))
            purchase_ss.focus_forward = dialog
        else
            local function DisplayOrderSort(a,b)
                return MISC_ITEMS[a.item_type].display_order < MISC_ITEMS[b.item_type].display_order
            end
            table.sort(iap_defs, DisplayOrderSort)

			local padded_defs = {}
			for _,def in pairs(iap_defs) do
				table.insert(padded_defs, def)
				if IsPackFeatured(def.item_type) then
					-- Make space for the featured pack's double-wide widget.
					table.insert(padded_defs, { is_blank = true })
				end
			end

            local function ScrollWidgetsCtor(context, index)
                return PurchaseWidget( self )
            end
            local function ScrollWidgetApply(context, widget, data, index)
                widget:ApplyDataToWidget(data)
            end
            
            purchase_ss.scroll_window = purchase_ss:AddChild(TEMPLATES.RectangleWindow(915, 620))
			purchase_ss.scroll_window:SetBackgroundTint(0,0,0,.8) -- black to contrast brown in shop widgets
    
			purchase_ss.scroll_window.grid = purchase_ss.scroll_window:InsertWidget(
				TEMPLATES.ScrollingGrid(
                    padded_defs,
                    {
                        context = {},
                        widget_width  = 440,
                        widget_height = 260,
                        num_visible_rows = 2.15,
                        num_columns      = 2,
                        item_ctor_fn = ScrollWidgetsCtor,
                        apply_fn     = ScrollWidgetApply,
                        scrollbar_offset = 20,
						scrollbar_height_offset = -60,
                    }
                )
			)
            purchase_ss.scroll_window:SetPosition(60,-3)
            purchase_ss.focus_forward = purchase_ss.scroll_window.grid
            
            --We need to inject this call to DoFocusHookups because the widgets are going to muck with the SetFocusChangedDir
            local oldRefreshView = purchase_ss.scroll_window.grid.RefreshView
            purchase_ss.scroll_window.grid.RefreshView = function(self)
				purchase_ss.scroll_window.grid.list_root.grid:DoFocusHookups()
				oldRefreshView(self)
            end
        end
    else
        local buttons = {
            {
                text = STRINGS.UI.PURCHASEPACKSCREEN.PURCHASE_OVERLAY_REQUIRED_HELP,
                cb = function() 
                    VisitURL("https://support.steampowered.com/kb_article.php?ref=9394-yofv-0014")
                end
            },
        }
        local dialog = purchase_ss:AddChild(TEMPLATES.CurlyWindow(400, 200,
                STRINGS.UI.PURCHASEPACKSCREEN.PURCHASE_OVERLAY_REQUIRED_TITLE,
                buttons, nil,
                STRINGS.UI.PURCHASEPACKSCREEN.PURCHASE_OVERLAY_REQUIRED_BODY
            ))
        purchase_ss.focus_forward = dialog
    end

    return purchase_ss
end





function PurchasePackScreen:OnBecomeActive()
    PurchasePackScreen._base.OnBecomeActive(self)

    if not self.shown then
        self:Show()
    end

    self.leaving = nil
end

function PurchasePackScreen:OnControl(control, down)
    if PurchasePackScreen._base.OnControl(self, control, down) then return true end

    if not down and control == CONTROL_CANCEL then
        TheFrontEnd:FadeBack()
        return true
    end
end

function PurchasePackScreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}
    table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.SERVERLISTINGSCREEN.BACK)
    return table.concat(t, "  ")
end


function PurchasePackScreen:OnUpdate(dt)
end


return PurchasePackScreen
