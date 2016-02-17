local Screen = require "widgets/screen"
local PopupDialogScreen = require "screens/popupdialog"
local ScrollableList = require "widgets/scrollablelist"
local PagedList = require "widgets/pagedlist"
local ImageButton = require "widgets/imagebutton"
local ItemImage = require "widgets/itemimage"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local TextEdit = require "widgets/textedit"
--local DropDown = require "widgets/dropdown"
local Widget = require "widgets/widget"
local Menu = require "widgets/menu"
local Puppet = require "widgets/skinspuppet"
local CharacterSelectScreen = require "screens/characterselectscreen"
local TEMPLATES = require "widgets/templates"

local DEBUG_MODE = BRANCH == "dev"


local NUM_ROWS = 4
local NUM_ITEMS_PER_ROW = 4

local SkinsScreen = Class(Screen, function(self, profile, screen)
	Screen._ctor(self, "SkinsScreen")

	--print("Is offline?", TheNet:IsOnlineMode() or "nil", TheFrontEnd:GetIsOfflineMode() or "nil")

	self.profile = profile
	self:DoInit() 
	self.prevScreen = screen

	self.applied_filters = {} -- filters that are currently applied (groups to show)
	 
   	self.default_focus = self.page_list
end)


function SkinsScreen:DoInit( )
	STATS_ENABLE = true
	TheFrontEnd:GetGraphicsOptions():DisableStencil()
	TheFrontEnd:GetGraphicsOptions():DisableLightMapComponent()
	
	TheInputProxy:SetCursorVisible(true)

	-- FIXED ROOT
    self.fixed_root = self:AddChild(Widget("root"))
    self.fixed_root:SetVAnchor(ANCHOR_MIDDLE)
    self.fixed_root:SetHAnchor(ANCHOR_MIDDLE)
    self.fixed_root:SetScaleMode(SCALEMODE_PROPORTIONAL)

 	-- Cover most of the normal backgrounds with a really big paper texture
    self.panel_bg = self.fixed_root:AddChild(Image("images/options_bg.xml", "options_panel_bg.tex"))
    self.panel_bg:SetScale(1.1, 1.2)
    self.panel_bg:SetPosition(0, 0)
 
    self.chest = self.fixed_root:AddChild(UIAnim())
    self.chest:GetAnimState():SetBuild("chest_bg") 
    self.chest:GetAnimState():SetBank("chest_bg") 
    self.chest:GetAnimState():PlayAnimation("idle", true)
    self.chest:SetScale(-.7, .7, .7)
    self.chest:SetPosition(100, -75)

    if not TheInput:ControllerAttached() then 
   		self.loadout_button = self.fixed_root:AddChild(TEMPLATES.SmallButton(STRINGS.UI.SKINSSCREEN.LOADOUT, 40, .75, 
    					function()
    							TheFrontEnd:Fade(false, SCREEN_FADE_TIME, function()
							       TheFrontEnd:PushScreen(CharacterSelectScreen(self.profile, "wilson"))
							       TheFrontEnd:Fade(true, SCREEN_FADE_TIME)
							    end)
    						end))
   		self.loadout_button:SetPosition(475, -300)
   	end

   	self.trade_button = self.fixed_root:AddChild(ImageButton("images/tradescreen.xml", "trade_buttonactive.tex", "trade_buttonactive_hover.tex", "trade_button_disabled.tex", "trade_button_pressed.tex"))
   	self.trade_button:SetScale(1.05)
   	self.trade_button:SetPosition(475, -170)
   	self.trade_button:Disable()
   	self.trade_button:SetHoverText(STRINGS.UI.SKINSSCREEN.TRADE_TOOLTIP, { font = NEWFONT_OUTLINE, size = 24, offset_x = 0, offset_y = 140, colour = {1,1,1,1}, wordwrap = true, region_h = 85, region_w = 215})


    local collection_name = self.profile:GetCollectionName() or (TheNet:GetLocalUserName()..STRINGS.UI.SKINSSCREEN.TITLE)
    local VALID_CHARS = [[ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:;[]\@!#$%&()'*+-/=?^_{|}~"<>]]
    self.title = self.fixed_root:AddChild(TextEdit(BUTTONFONT, 45, "", BLACK))
    self.title:SetPosition(-390, RESOLUTION_Y*.43)
    self.title:SetForceEdit(true)
    self.title:SetTextLengthLimit( 30 )
    self.title:SetCharacterFilter( VALID_CHARS )
    self.title:EnableWordWrap(false)
    self.title:EnableScrollEditWindow(true)
    self.title:SetTruncatedString(collection_name, 300, 30, true)
    self.title.OnTextEntered = function() 
    	self.profile:SetCollectionName(self.title:GetString())
    end

    self:BuildInventoryList()
    self:UpdateInventoryList()

    self:BuildDetailsPanel()

    if not TheInput:ControllerAttached() then 
    	self.exit_button = self.fixed_root:AddChild(TEMPLATES.BackButton(function() self:Quit() end)) 

    	self.exit_button:SetPosition(-RESOLUTION_X*.415, -RESOLUTION_Y*.505 + BACK_BUTTON_Y )
  	end

    self.details_panel:Hide()
end

function SkinsScreen:SetFocusColumn( itemimage )

	if self.page_list then 
		local row_widget = self.page_list:GetFocusedWidget()

		for i=1,#row_widget.images do 
			if row_widget.images[i] == itemimage then 
				self.focus_column = i
			end
		end
	else 
		self.focus_column = 1
	end
end


function SkinsScreen:SetFocusIndex(idx)
	self.focus_index = idx
end


function SkinsScreen:ClearFocus()
	--print("Clearing focus", debugstack())
	if self.list_widgets then 
		for i = 1, #self.list_widgets do 
			local line = self.list_widgets[i]

			for j = 1, #line.images do 
				--print("shrinking", line.images[j].name)
				line.images[j]:Unselect()
			end

		end
	end
	--self.details_panel:Hide()
end

-- Update the details panel when an item is clicked
function SkinsScreen:OnItemSelect(type, item, itemimage)

	if type == nil or item == nil then 
		self.details_panel:Hide()
		self.dressup_hanger:Show()
		return
	end

	self:SetFocusIndex(itemimage.index)

	self.dressup_hanger:Hide()

	local buildfile = item
	if type == "base" or type == "item" then 
		local skinsData = Prefabs[item]
		if skinsData and skinsData.ui_preview then 
			buildfile = skinsData.ui_preview.build
		end
	else
		local clothing_data = CLOTHING[item]
		if clothing_data and clothing_data.override_build then
			buildfile = clothing_data.override_build
		end
	end

	if type == "base"  then 
		self.details_panel.shadow:SetScale(.4)
	elseif type == "body" then 
		self.details_panel.shadow:SetScale(.55)
	else
		if type == "item" then 
			self.details_panel.shadow:SetScale(.7)
		else
			self.details_panel.shadow:SetScale(.6)
		end
	end

	self.details_panel.image:GetAnimState():OverrideSkinSymbol("SWAP_ICON", buildfile, "SWAP_ICON")

	local rarity = GetRarityForItem(type, item)
	local nameStr = GetName(item)

	self.details_panel.name:SetTruncatedString(nameStr, 200, 50, true)
	self.details_panel.name:SetColour(unpack(SKIN_RARITY_COLORS[rarity]))
	self.details_panel.description:SetString(STRINGS.SKIN_DESCRIPTIONS[item] or STRINGS.SKIN_DESCRIPTIONS["missing"])
 
	self.details_panel.rarity:SetString(rarity.." Item")
	self.details_panel.rarity:SetColour(unpack(SKIN_RARITY_COLORS[rarity]))

	self.details_panel:Show()
end

function SkinsScreen:BuildDetailsPanel()

    self.details_frame = self.fixed_root:AddChild(TEMPLATES.CurlyWindow(10, 450, .6, .6, 39, -25))
    self.details_frame:SetPosition(-400,0,0)

	self.details_bg = self.details_frame:AddChild(Image("images/serverbrowser.xml", "side_panel.tex"))
	self.details_bg:SetScale(-.66, -.7)
	self.details_bg:SetPosition(5, 5)


	self.dressup_hanger = self.details_bg:AddChild(Image("images/lobbyscreen.xml", "customization_coming_imageonwood.tex"))
	self.dressup_hanger:SetScale(-1, -1)
	self.dressup_hanger:SetPosition(0, 0)


	self.details_panel = self.fixed_root:AddChild(Widget("details-widget"))
	
    self.details_panel:SetPosition(-400, -0, 0)

    self.details_panel.shadow = self.details_panel:AddChild(Image("images/frontscreen.xml", "char_shadow.tex"))
	self.details_panel.shadow:SetPosition(0, 35)
	self.details_panel.shadow:SetScale(.8)

	self.details_panel.image = self.details_panel:AddChild(UIAnim()) 
	self.details_panel.image:GetAnimState():SetBuild("frames_comp")
	self.details_panel.image:GetAnimState():SetBank("fr")
	self.details_panel.image:GetAnimState():PlayAnimation("icon")
	self.details_panel.image:SetPosition(0, 125)
	self.details_panel.image:SetScale(1.65)
	
	self.details_panel.name = self.details_panel:AddChild(Text(TALKINGFONT, 30, "name", {0, 0, 0, 1}))
	self.details_panel.name:SetPosition(0, -30)

    self.details_panel.upper_horizontal_line = self.details_panel:AddChild(Image("images/ui.xml", "line_horizontal_6.tex"))
    self.details_panel.upper_horizontal_line:SetScale(.55)
    self.details_panel.upper_horizontal_line:SetPosition(0, -45, 0)

	self.details_panel.description = self.details_panel:AddChild(Text(NEWFONT, 20, "lorem ipsum dolor sit amet", {0, 0, 0, 1}))
	self.details_panel.description:SetRegionSize( 180, 150)
	self.details_panel.description:EnableWordWrap(true)
	self.details_panel.description:SetPosition(0, -120)

	self.details_panel.lower_horizontal_line = self.details_panel:AddChild(Image("images/ui.xml", "line_horizontal_6.tex"))
    self.details_panel.lower_horizontal_line:SetScale(.55)
    self.details_panel.lower_horizontal_line:SetPosition(0, -200, 0)


	self.details_panel.rarity = self.details_panel:AddChild(Text(TALKINGFONT, 20, "Common Item", {0, 0, 0, 1}))
	self.details_panel.rarity:SetPosition(0, -215)

end


function SkinsScreen:BuildInventoryList()
	self.inventory_list = self.fixed_root:AddChild(Widget("container"))

	-- MUST have two separate roots for the scrollable list and the widgets inside the scrollable list, 
	-- otherwise the sub-widgets don't get focus/click events.
	-- (I assume this applies to the paged list as well, since it's based on the scrollable list.)
	self.list_root = self.inventory_list:AddChild(Widget("list-root"))
	self.row_root = self.inventory_list:AddChild(Widget("row-root"))

	self.list_widgets = {}

	for i=1,NUM_ROWS do
		table.insert(self.list_widgets, SkinLineConstructor(self, self.row_root, NUM_ITEMS_PER_ROW, false))
	end

	local row_width = 240
	local row_height = 70
	local spacing = 10

	self.page_list = self.list_root:AddChild(PagedList(row_width, row_height, spacing, function(widget, data, index) UpdateSkinLine(widget, data, index, self) end, self.list_widgets))
	self.page_list:SetPosition(0, 0)	
	
	self.inventory_list:SetPosition(-20, 240)
end

function SkinsScreen:UpdateInventoryList()
	self:GetSkinsList() --populates self.skins_list	
	local inventory_rows = SplitSkinsIntoInventoryRows(self.skins_list, NUM_ITEMS_PER_ROW)	
	self.page_list:SetItemsData(inventory_rows)
end


function SkinsScreen:Quit()
	--print("Setting dressuptimestamp from skinsscreen:Quit", self.timestamp)
	self.profile:SetCollectionTimestamp(self.timestamp)
	
	TheFrontEnd:Fade(false, SCREEN_FADE_TIME, function()
        TheFrontEnd:PopScreen()
        TheFrontEnd:Fade(true, SCREEN_FADE_TIME)
    end)
end

function SkinsScreen:OnBecomeActive()
	if not self.popup and (not TheNet:IsOnlineMode() or TheFrontEnd:GetIsOfflineMode()) then
		-- The game is offline, open a popup saying "sorry"
		self.popup =  PopupDialogScreen(STRINGS.UI.SKINSSCREEN.SORRY, STRINGS.UI.SKINSSCREEN.OFFLINE, 
			{ {text=STRINGS.UI.POPUPDIALOG.OK, cb = function() TheFrontEnd:PopScreen() end}  }) 
		TheFrontEnd:PushScreen(self.popup)

	elseif not self.popup then 
		-- We don't have a saved popup, which means the game is online. Go ahead and activate it.
	    SkinsScreen._base.OnBecomeActive(self)  

		if not self.no_item_popup and #self.full_skins_list == 0 then
			self.no_item_popup = PopupDialogScreen(STRINGS.UI.SKINSSCREEN.NO_ITEMS_TITLE, STRINGS.UI.SKINSSCREEN.NO_ITEMS, { {text=STRINGS.UI.POPUPDIALOG.OK, cb = function() TheFrontEnd:PopScreen() end} }) 
			TheFrontEnd:PushScreen(self.no_item_popup)
		end	
	
	    if self.exit_button then 
	    	self.exit_button:Enable()
	    	self.exit_button:SetFocus()
	    end

	    self.leaving = nil

	    -- If we came from the tradescreen, we need to update the inventory list
    	self:UpdateInventoryList()
	else
		-- This triggers when the "sorry" popup closes. Just quit.
		self:Quit()
	end

end


function SkinsScreen:GetSkinsList()

	self.skins_list, self.timestamp = GetSortedSkinsList()

	-- Keep a copy so we can change the skins_list later (for filters)
	self.full_skins_list = CopySkinsList(self.skins_list)
end


local SCROLL_REPEAT_TIME = .15
local MOUSE_SCROLL_REPEAT_TIME = 0
local STICK_SCROLL_REPEAT_TIME = .25

function SkinsScreen:OnControl(control, down)
    
    if SkinsScreen._base.OnControl(self, control, down) then return true end

    if not self.no_cancel and
    	not down and control == CONTROL_CANCEL then 
		self:Quit()
		return true 
    end

    if  TheInput:ControllerAttached() then 

    	if not down and control == CONTROL_PAUSE then
    		TheFrontEnd:Fade(false, SCREEN_FADE_TIME, function()
		        TheFrontEnd:PushScreen(CharacterSelectScreen(self.profile, "wilson"))
		        TheFrontEnd:Fade(true, SCREEN_FADE_TIME)
		    end)
			return true
		end
    end

   	if down then 
	 	if control == CONTROL_PREVVALUE then  -- r-stick left
	    	self:ScrollBack(control)
			return true 
		elseif control == CONTROL_NEXTVALUE then -- r-stick right
			self:ScrollFwd(control)
			return true
		elseif control == CONTROL_SCROLLBACK then
            self:ScrollBack(control)
            return true
        elseif control == CONTROL_SCROLLFWD then
        	self:ScrollFwd(control)
            return true
       	end
	end
end

function SkinsScreen:ScrollBack(control)
	if not self.page_list.repeat_time or self.page_list.repeat_time <= 0 then
       	self.page_list:ChangePage(-1)
       	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        self.page_list.repeat_time =
            TheInput:GetControlIsMouseWheel(control)
            and MOUSE_SCROLL_REPEAT_TIME
            or (control == CONTROL_SCROLLBACK and SCROLL_REPEAT_TIME) 
            or (control == CONTROL_PREVVALUE and STICK_SCROLL_REPEAT_TIME)
    end
end

function SkinsScreen:ScrollFwd(control)
	if not self.page_list.repeat_time or self.page_list.repeat_time <= 0 then
        self.page_list:ChangePage(1)
		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        self.page_list.repeat_time =
            TheInput:GetControlIsMouseWheel(control)
            and MOUSE_SCROLL_REPEAT_TIME
            or (control == CONTROL_SCROLLFWD and SCROLL_REPEAT_TIME) 
            or (control == CONTROL_NEXTVALUE and STICK_SCROLL_REPEAT_TIME)
    end
end

function SkinsScreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}
    
    if not self.no_cancel then
    	table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.SKINSSCREEN.BACK)
    end
   
   	table.insert(t, self.page_list:GetHelpText())
  	
   	table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_PAUSE) .. " " .. STRINGS.UI.SKINSSCREEN.LOADOUT)
   	
    return table.concat(t, "  ")
end

return SkinsScreen
