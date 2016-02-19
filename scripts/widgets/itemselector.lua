local Widget = require "widgets/widget"
local PagedList = require "widgets/pagedlist"
local Menu = require "widgets/menu"
local Text = require "widgets/text"

require "skinsutils"

local TEMPLATES = require "widgets/templates"

local DEBUG_MODE = BRANCH == "dev"

local NUM_ROWS = 4
local NUM_ITEMS_PER_ROW = 4
	
local ItemSelector = Class(Widget, function(self, parent, owner, profile, selections, filters_list)
    self.owner = owner
	self.parent = parent
    self.profile = profile
    Widget._ctor(self, "ItemSelector")
   
    self.root = self:AddChild(Widget("ItemSelectorRoot"))

	self.focus_index = 1
	self.focus_column = 1
	
    -- Title banner
    self.title_group = self.root:AddChild(Widget("Title"))
    self.title_group:SetPosition(15, 285)
   
    self.banner = self.title_group:AddChild(Image("images/tradescreen.xml", "banner0_small.tex"))
    self.banner:SetScale(.38)
    self.banner:SetPosition(-38, -43)
    self.title = self.title_group:AddChild(Text(BUTTONFONT, 35, STRINGS.UI.TRADESCREEN.SELECT_TITLE, BLACK))
    self.title:SetPosition(-40, -45)
    self.title:SetRotation(-17)
	
    self:BuildInventoryList()
    self:UpdateData( selections, filters_list )

    self.focus_forward = self.page_list
end)

function ItemSelector:Close()
	self:Kill()
end

function ItemSelector:BuildInventoryList()
	self.inventory_list = self.root:AddChild(Widget("container"))
	self.inventory_list:SetScale(.78)
    self.inventory_list:SetPosition(-115, 141)

	-- MUST have two separate roots for the scrollable list and the widgets inside the scrollable list, 
	-- otherwise the sub-widgets don't get focus/click events.
	-- (I assume this applies to the paged list as well, since it's based on the scrollable list.)
	self.list_root = self.inventory_list:AddChild(Widget("list-root"))
	self.row_root = self.inventory_list:AddChild(Widget("row-root"))
	self.list_widgets = {}
	
	for i=1,NUM_ROWS do
		table.insert(self.list_widgets, SkinLineConstructor(self, self.row_root, NUM_ITEMS_PER_ROW, true))
	end

	local row_width = 240
	local row_height = 70
	local spacing = 10
	
	self.show_hover_text = true --shows the hover text on the paged list
	self.page_list = self.list_root:AddChild(PagedList(row_width, row_height, spacing, function(widget, data, index) UpdateSkinLine(widget, data, index, self) end, self.list_widgets))
	self.page_list:SetPosition(0, 0)
end

function ItemSelector:UpdateData( selections, filters_list )
    self.full_skins_list = GetSortedSkinsList()
    self.skins_list = ApplyFilters( self.full_skins_list, filters_list )
	
	local last_added_item = self.owner.GetLastAddedItem and self.owner:GetLastAddedItem()
	local page_number = 0
	
	--Remove selected items from the list so we can't select them twice
	--Note(Peter): this maintaining of the page focus will only work for mono-rarity recipes, otherwise the more complex filtering will produce weird results
	--The complex looping is so that we can track where the page should be for the last added item, while ignoring selections from earlier in skins_list
	--We need to do this to avoid the removal of selected items from shifting the last item's index in the paged list by however many items in the list were removed ahead of it
    local k = 1
	while k <= #self.skins_list do
		local v = self.skins_list[k]
		local removed = false
		for _,v2 in pairs(selections) do -- Note: selections is not a contiguous array
    		if v.item_id == v2.item_id then
    			-- Remove this thing from the list, and skip the rest of the skins_list
    			table.remove(self.skins_list, k)
    			removed = true
    			
    			if last_added_item ~= nil then
	    			if v2.item_id == last_added_item.item_id then
	    				page_number = math.floor((k-1)/16) + 1 -- the -1 and +1 is due to Lua indices starting at 1, boo :)
	    			end
				end
    			break
    		end
    	end
    	
    	if not removed then
    		k = k + 1
    	end
    end


	local inventory_rows = SplitSkinsIntoInventoryRows(self.skins_list, NUM_ITEMS_PER_ROW)	
	self.page_list:SetItemsData(inventory_rows)

	if page_number ~= 0 then
		self.page_list:SetPage(page_number)
	end
end

function ItemSelector:EnableInput()
	for _,line in pairs( self.list_widgets ) do
		for _,item_image in pairs( line.images ) do
			item_image:Enable()
		end
	end
	self.page_list:EvaluateArrows() --enables the correct arrow buttons
end

function ItemSelector:DisableInput()
	for _,line in pairs( self.list_widgets ) do
		for _,item_image in pairs( line.images ) do
			item_image:Disable()
		end
	end
	self.page_list.left_button:Disable()
	self.page_list.right_button:Disable()
end

function ItemSelector:SetFocusColumn( itemimage )

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

function ItemSelector:SetFocusIndex(idx)
	self.focus_index = idx
end

function ItemSelector:ClearFocus()
	--TODO(Peter): does clearing this also break the controller focus?
	-- Clear focus on buttons etc.
	for k,v in pairs(self.children) do
        if v.focus then
            v:ClearFocus()
        end
    end
end

function ItemSelector:TakeFocus()
	self.page_list:ForceFocus()
end

-- OnItemSelect is called when an item in the list is clicked
function ItemSelector:OnItemSelect(type, item, id, itemimage)
	-- TODO: put this back if we stop removing the items from the list entirely
	--itemimage:PlaySpecialAnimation("off")

	self:SetFocusIndex(itemimage.index)

	-- Tell the TradeScreen to add it to the claw machine
	return self.owner:AddSelectedItem( {type = type, item = item, item_id = id})
end

function ItemSelector:NumItemsLikeThis(item_name)
	local count = 0

	for k,v in ipairs(self.skins_list) do 
		if v.item == item_name then 
			count = count + 1
		end
	end

	--print("Returning ", count, " for ", item_name)
	return count

end

function ItemSelector:GetNumFilteredItems()
	return #self.skins_list
end

return ItemSelector