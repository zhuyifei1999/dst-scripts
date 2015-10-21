local Screen = require "widgets/screen"
local PopupDialogScreen = require "screens/popupdialog"
local ScrollableList = require "widgets/scrollablelist"
local PagedList = require "widgets/pagedlist"
local ImageButton = require "widgets/imagebutton"
local ItemImage = require "widgets/itemimage"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local TextEdit = require "widgets/textedit"
local DropDown = require "widgets/dropdown"
local Widget = require "widgets/widget"
local Puppet = require "widgets/skinspuppet"
local CharacterSelectScreen = require "screens/characterselectscreen"
local TEMPLATES = require "widgets/templates"



local DEBUG_MODE = BRANCH == "dev"


local function line_constructor(screen, parent, num_pictures, data)

	local widget = parent:AddChild(Widget("inventory-line"))
	local offset = 0

	widget.images = {}

	for k, item in ipairs(data.items) do 

		local itemimage = widget:AddChild(ItemImage(screen, item.type, item.item, item.timestamp,
			function(type, item) 
				screen:UpdateDetailsPanel(type, item)
			end,

		    nil,

			nil

			))

		itemimage:SetPosition(offset, -15, 0)
		offset = offset + 80

		table.insert(widget.images, itemimage)
	end

	while #widget.images < num_pictures do
		local itemimage = widget:AddChild(ItemImage(screen, "", "", 0,
			function(type, item) 
				screen:UpdateDetailsPanel(type, item)
			end,

			nil,

			nil

			))

		itemimage:SetPosition(offset, -15, 0)
		offset = offset + 80

		table.insert(widget.images, itemimage)
	end


	return widget
end

local function updateWidget(widget, data, index, screen)

	local offset = 0
	for i = 1, #data do 
		local item = data[i]

		if widget.images[i] and item then 
			widget.images[i]:SetItem(item.type, item.item, item.timestamp)
		elseif item then 
			widget.images[i] = widget:AddChild(ItemImage(screen, item.type, item.item, item.timestamp))
			widget.images[i]:SetPosition(offset, 0, 0)
		end

		--print("Screen selected item is ", screen.selected_item, item.item)
		if screen.selected_item and screen.selected_item == item.item then 
			--print("Updating selected item, embiggening")
			widget.images[i]:Select()
		else
			widget.images[i]:Unselect()
		end

		offset = offset + 100
		widget.images[i]:Show()
	end

	if #data < #widget.images then 
		for i = (#data+1), #widget.images do 
			widget.images[i]:SetItem(nil, nil)
			widget.images[i]:Unselect()
		end
	end

end


local SkinsScreen = Class(Screen, function(self, profile, screen)
	Screen._ctor(self, "SkinsScreen")

	--print("Is offline?", TheNet:IsOnlineMode() or "nil", TheFrontEnd:GetIsOfflineMode() or "nil")

	self.profile = profile
	self:DoInit() 
	self.prevScreen = screen

	self.applied_filters = {} -- filters that are currently applied (groups to show)
	 
    --self.default_focus = self.play_button
end)


function SkinsScreen:DoInit( )
	STATS_ENABLE = true
	TheFrontEnd:GetGraphicsOptions():DisableStencil()
	TheFrontEnd:GetGraphicsOptions():DisableLightMapComponent()
	
	TheInputProxy:SetCursorVisible(true)

	--self.bg = self:AddChild(TEMPLATES.AnimatedPortalBackground())
   	
	
	-- FIXED ROOT
    self.fixed_root = self:AddChild(Widget("root"))
    self.fixed_root:SetVAnchor(ANCHOR_MIDDLE)
    self.fixed_root:SetHAnchor(ANCHOR_MIDDLE)
    self.fixed_root:SetScaleMode(SCALEMODE_PROPORTIONAL)

  	--self.fg = self.fixed_root:AddChild(TEMPLATES.AnimatedPortalForeground())



 	-- Cover most of the normal backgrounds with a really big paper texture
    self.panel_bg = self.fixed_root:AddChild(Image("images/options_bg.xml", "options_panel_bg.tex"))
    self.panel_bg:SetScale(1.1, 1.2)
    self.panel_bg:SetPosition(0, 0)

    -- Add tab buttons 
    -- TODO: add trade tab and make buttons functional
    -- self.loadout_button = self.fixed_root:AddChild(TEMPLATES.TabButton(-RESOLUTION_X*.45, RESOLUTION_Y*.325, STRINGS.UI.SKINSSCREEN.LOADOUT, function()  end))
    --self.loadout_button:Disable()
    
    --self.trade_button = self.fixed_root:AddChild(TEMPLATES.TabButton(-RESOLUTION_X*.35, RESOLUTION_Y*.325, STRINGS.UI.SKINSSCREEN.TRADE, function()  end))
    
    self.chest = self.fixed_root:AddChild(UIAnim())
    self.chest:GetAnimState():SetBuild("chest_bg") 
    self.chest:GetAnimState():SetBank("chest_bg") 
    self.chest:GetAnimState():PlayAnimation("idle", true)
    self.chest:SetScale(-.7, .7, .7)
    self.chest:SetPosition(100, -75)


    self.loadout_button = self.fixed_root:AddChild(TEMPLATES.SmallButton(STRINGS.UI.SKINSSCREEN.LOADOUT, 40, .75, 
    					function()
    						TheFrontEnd:PushScreen(CharacterSelectScreen(self.profile, "wilson"))
    						end))
   	self.loadout_button:SetPosition(475, -300)

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

	self:GetSkinsList()

    self:BuildInventoryList(self.skins_list)

    self:BuildDetailsPanel()

    --self.divider = self.fixed_root:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
    --self.divider:SetScale(1, 1)
    --self.divider:SetPosition(RESOLUTION_X*.1, 0, 0)

    --[[local items = {STRINGS.UI.SKINSSCREEN.NONE, STRINGS.UI.SKINSSCREEN.BODY, STRINGS.UI.SKINSSCREEN.HAND, STRINGS.UI.SKINSSCREEN.LEGS, STRINGS.UI.SKINSSCREEN.ITEM,
     STRINGS.UI.SKINSSCREEN.COMMON, STRINGS.UI.SKINSSCREEN.CLASSY, STRINGS.UI.SKINSSCREEN.SPIFFY, STRINGS.UI.SKINSSCREEN.DISTINGUISHED, STRINGS.UI.SKINSSCREEN.ELEGANT, STRINGS.UI.SKINSSCREEN.ELEGANT, STRINGS.UI.SKINSSCREEN.LOYAL}
    self.filters = self.fixed_root:AddChild(DropDown( 175, nil, STRINGS.UI.SKINSSCREEN.FILTERS, items, true, 
    																		function(text) 
    																			self:ApplyFilter(text) 
    																		end, 
    																		function(text) 
    																			self:RemoveFilter(text)
    																		end))
    self.filters:SetPosition(-200, 370, 0)
	]]
    --self.num_items = self.fixed_root:AddChild(Text(BUTTONFONT, 20, STRINGS.UI.SKINSSCREEN.ITEMS..": "..#self.full_skins_list, {0, 0, 0, 1}))
    --self.num_items:SetPosition(-335, -RESOLUTION_Y*.5 + 50)

    self.exit_button = self.fixed_root:AddChild(TEMPLATES.BackButton(function() self:Quit() end)) 

    self.exit_button:SetPosition(-RESOLUTION_X*.415, -RESOLUTION_Y*.505 + BACK_BUTTON_Y )
  
    if TheInput:ControllerAttached() then
        self.exit_button:SetPosition(-RESOLUTION_X*.415, -RESOLUTION_Y*.505 + BACK_BUTTON_Y+25)
    end

    self.details_panel:Hide()

	--focus moving
    --self.exit_button:SetFocusChangeDir(MOVE_UP, self.play_button)

end

function SkinsScreen:OnRawKey( key, down )
end

function SkinsScreen:ClearFocus()
	--print("Clearing focus")
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


function SkinsScreen:ClearFilters()
	--print("Clearing filters")
	self.filters:ClearAllSelections()
	self.applied_filters = {}
end

local typeList = {}
typeList[STRINGS.UI.SKINSSCREEN.BASE] = "base" 
typeList[STRINGS.UI.SKINSSCREEN.BODY] = "body" 
typeList[STRINGS.UI.SKINSSCREEN.HAND] = "hand"
typeList[STRINGS.UI.SKINSSCREEN.LEGS] = "legs" 
typeList[STRINGS.UI.SKINSSCREEN.FEET] = "feet" 
typeList[STRINGS.UI.SKINSSCREEN.ITEM] = "item"
				
local rarityList = {}
rarityList[STRINGS.UI.SKINSSCREEN.COMMON] = STRINGS.UI.SKINSSCREEN.COMMON
rarityList[STRINGS.UI.SKINSSCREEN.CLASSY] = STRINGS.UI.SKINSSCREEN.CLASSY
rarityList[STRINGS.UI.SKINSSCREEN.SPIFFY] = STRINGS.UI.SKINSSCREEN.SPIFFY
rarityList[STRINGS.UI.SKINSSCREEN.DISTINGUISHED] = STRINGS.UI.SKINSSCREEN.DISTINGUISHED
rarityList[STRINGS.UI.SKINSSCREEN.ELEGANT] = STRINGS.UI.SKINSSCREEN.ELEGANT
rarityList[STRINGS.UI.SKINSSCREEN.TIMELESS] = STRINGS.UI.SKINSSCREEN.TIMELESS
rarityList[STRINGS.UI.SKINSSCREEN.LOYAL] = STRINGS.UI.SKINSSCREEN.LOYAL


-- Apply a filter.
-- If filter is "none", remove all filters.
-- If filter is nil, just reapply whatever is in the applied_filters list.
function SkinsScreen:ApplyFilter(filter)

	if filter == nil and #self.applied_filters == 0 then 
		--print("No applied filters, using none")
		filter = STRINGS.UI.SKINSSCREEN.NONE
	end

	if filter == STRINGS.UI.SKINSSCREEN.NONE then 
		--print("Got filter none")
		self:ClearFilters()
		self.skins_list = self:CopySkinsList(self.full_skins_list)
		self:BuildInventoryList(self.skins_list)
	else
		self.skins_list = nil

		if filter and typeList[filter] then
			filter = typeList[filter]
		elseif filter and rarityList[filter] then 
			filter = rarityList[filter]
		end
		
		if filter then 
			table.insert(self.applied_filters, filter)
		end

		--print("Got type filter", filter)
		for k,v in ipairs(self.applied_filters) do
			--print("Adding skin type ", v) 
			if not self.skins_list then 
				self.skins_list = self:AddSkinType(v)
			else
				local tempList = self:AddSkinType(v)
				
				for k2,v2 in ipairs(tempList) do 
					--print("Inserting ", k2, v2)
					if not table.contains(self.skins_list, v2) then 
						table.insert(self.skins_list, v2)
					end
				end
			end
			--dumptable(self.skins_list)
		end
		
		if not self.skins_list then 
			self.skins_list = {}
		end

		-- Call BuildInventoryList again with the new skins_list
		self:BuildInventoryList(self.skins_list)
	end
end


function SkinsScreen:RemoveFilter(filter)
	--print("Removing filter ", filter)
	if filter and typeList[filter] then
		filter = typeList[filter]
	elseif filter and rarityList[filter] then 
		filter = rarityList[filter]
	end


	local applied_filters = {}
	for k,v in ipairs(self.applied_filters) do
		if v ~= filter then 
			table.insert(applied_filters, v)
		end
	end

	self.applied_filters = applied_filters
	if not self.applied_filters then 
		self.applied_filters = {}
	end

	--print("Dumping applied_filters table:")
	--dumptable(self.applied_filters)
	self:ApplyFilter(nil)
end


function SkinsScreen:AddSkinType(filter)
	--print("Adding skin type", filter)

	local newList = {}

	for k,v in ipairs(self.full_skins_list) do 
		if v.type == filter then 
			table.insert(newList, v)
		elseif GetRarityForItem(v.type, v.item) == filter then 
			table.insert(newList, v)
		end
	end

	return newList

end


function SkinsScreen:UpdateDetailsPanel(type, item)

	if type == nil or item == nil then 
		self.details_panel:Hide()
		self.dressup_hanger:Show()
		return
	end

	self.dressup_hanger:Hide()

	local buildfile = item
	if type == "base" or type == "item" then 
		local skinsData = Prefabs[item]
		if skinsData and skinsData.ui_preview then 
			buildfile = skinsData.ui_preview.build
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


function SkinsScreen:BuildInventoryList(skins_list)

	if not skins_list then 
		skins_list = {}
	end

	if not self.inventory_list then 
		self.inventory_list = self.fixed_root:AddChild(Widget("container"))
	end

	-- MUST have two separate roots for the scrollable list and the widgets inside the scrollable list, 
	-- otherwise the sub-widgets don't get focus/click events.
	-- (I assume this applies to the paged list as well, since it's based on the scrollable list.)
	if not self.list_root then 
		self.list_root = self.inventory_list:AddChild(Widget("list-root"))
	end

	if not self.row_root then 
		self.row_root = self.inventory_list:AddChild(Widget("row-root"))
	end


	self.inventory_lines = {}

	if not self.list_widgets then 
		self.list_widgets = {}
	end

	local line_items = {}

	local num_items_per_row = 4
	local num_visible_rows = 4

	for k,v in pairs(skins_list) do 
		
		--print("adding ", v, v.item_id, v.item_type)

		if #line_items < num_items_per_row then 
			table.insert(line_items, v)
		end

		if #line_items == num_items_per_row then 
			self.inventory_lines[#self.inventory_lines + 1] = line_items
			
			if #self.list_widgets < num_visible_rows then 
				table.insert(self.list_widgets, line_constructor(self, self.row_root, num_items_per_row, {items = line_items}))
			end

			line_items = {}
		end

	end

	if #line_items > 0 then 
		self.inventory_lines[#self.inventory_lines + 1] = line_items

		if #self.list_widgets < num_visible_rows then 
			table.insert(self.list_widgets, line_constructor(self, self.row_root, num_items_per_row, {items = line_items}))
		end
	end

	while #self.list_widgets < num_visible_rows do 
		table.insert(self.list_widgets, line_constructor(self, self.row_root, num_items_per_row, {items = {}}))
	end

	local row_height = 70
	local spacing = 10
	if not self.page_list then 
		self.page_list = self.list_root:AddChild(PagedList(self.inventory_lines, 240, row_height, spacing, function(widget, data, index) updateWidget(widget, data, index, self) end, self.list_widgets, true))
		--self.page_list:LayOutStaticWidgets()
		self.page_list:SetPosition(0, 0)
	else
		self.page_list:Show()
		self.page_list:SetList(self.inventory_lines)
	end

	self.inventory_list:SetPosition(-20, 240)

end

function SkinsScreen:Quit()
	--print("Setting dressuptimestamp from skinsscreen:Quit", self.timestamp)
	self.profile:SetCollectionTimestamp(self.timestamp)
	self.profile:SetDressupTimestamp(self.timestamp)

	TheFrontEnd:PopScreen()
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
	    self.exit_button:Enable()
	    self.exit_button:SetFocus()
	    self.leaving = nil

	    -- Refresh the paged list to update the equipped stars (in case we're returning from the loadout screen)
	    self.page_list:RefreshView()

	else
		-- This triggers when the "sorry" popup closes. Just quit.
		self:Quit()
	end

end


function SkinsScreen:GetSkinsList()

	local templist = TheInventory:GetFullInventory()
	self.skins_list = {}
	self.timestamp = 0

	for k,v in ipairs(templist) do 
		local type, item = GetTypeForItem(v.item_type)
		if type ~= "unknown" then
			self.skins_list[k] = {}
			self.skins_list[k].type = type
			self.skins_list[k].item = item
			self.skins_list[k].timestamp = v.modified_time
			
			if v.modified_time > self.timestamp then 
				self.timestamp = v.modified_time
			end
		end
	end

	-- Keep a copy so we can change the skins_list later (for filters)
	self.full_skins_list = self:CopySkinsList(self.skins_list)

end


function SkinsScreen:CopySkinsList(list)

	local newList = {}
	for k, skin in ipairs(list) do 
		newList[k] = {}
		newList[k].type = skin.type
		newList[k].item = skin.item
		newList[k].timestamp = skin.modified_time
	end

	return newList
end


return SkinsScreen
