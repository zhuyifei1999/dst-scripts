local Widget = require "widgets/widget"
local PagedList = require "widgets/pagedlist"
local Menu = require "widgets/menu"
local Text = require "widgets/text"

require "skinsutils"

local TEMPLATES = require "widgets/templates"

local DEBUG_MODE = BRANCH == "dev"

local NUM_ROWS = 4
local NUM_ITEMS_PER_ROW = 4
	
local ItemSelector = Class(Widget, function(self, parent, owner, profile)
    self.owner = owner
	self.parent = parent
    self.profile = profile
    Widget._ctor(self, "ItemSelector")
   
    self.root = self:AddChild(Widget("ItemSelectorRoot"))
	
    -- Title banner
    self.title_group = self.root:AddChild(Widget("Title"))
    self.title_group:SetPosition(25, 255)
   
    self.banner = self.title_group:AddChild(Image("images/tradescreen.xml", "banner0_small.tex"))
    self.banner:SetScale(.38)
    self.banner:SetPosition(-40, 27)
    self.title = self.title_group:AddChild(Text(BUTTONFONT, 35, STRINGS.UI.TRADESCREEN.SELECT_TITLE, BLACK))
    self.title:SetPosition(-35, 25)
    self.title:SetRotation(-17)
	
    self:BuildInventoryList()

    self.focus_forward = self.page_list
end)

function ItemSelector:Close()
	self:Kill()
end

function ItemSelector:BuildInventoryList()
	self.inventory_list = self.root:AddChild(Widget("container"))
	self.inventory_list:SetScale(.7)
    self.inventory_list:SetPosition( -18, 65)

	self.tiles_root = self.inventory_list:AddChild(Widget("tiles_root"))
	self.list_widgets = SkinGrid4x4Constructor(self, self.tiles_root, true)

	self.show_hover_text = true --shows the hover text on the paged list
	
	local grid_width = 420
	self.page_list = self.inventory_list:AddChild(PagedList(grid_width, function(widget, data) UpdateSkinGrid(widget, data, self) end, self.list_widgets))
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

	self.page_list:SetItemsData(self.skins_list)

	if page_number ~= 0 then
		self.page_list:SetPage(page_number)
	end
end

function ItemSelector:EnableInput()
	for _,item_image in pairs( self.list_widgets ) do
		item_image:Enable()
	end
	self.page_list:EvaluateArrows() --enables the correct arrow buttons
end

function ItemSelector:DisableInput()
	for _,item_image in pairs( self.list_widgets ) do
		item_image:Disable()
	end
	self.page_list.left_button:Disable()
	self.page_list.right_button:Disable()
end

-- OnItemSelect is called when an item in the list is clicked
function ItemSelector:OnItemSelect(type, item, item_id, itemimage)
	-- TODO: put this back if we stop removing the items from the list entirely
	--itemimage:PlaySpecialAnimation("off")

	--print("ItemSelector position", self:GetPosition(), self:GetWorldPosition())
	self.owner:StartAddSelectedItem( {type = type, item = item, item_id = item_id}, itemimage:GetWorldPosition())
end

-- This is the TOTAL number of items in the player's inventory, not the number shown in the filtered view.
function ItemSelector:NumItemsLikeThis(item_name)
	local count = 0

	for k,v in ipairs(self.full_skins_list) do 
		if v.item == item_name then 
			count = count + 1
		end
	end

	return count
end

function ItemSelector:GetNumFilteredItems()
	return #self.skins_list
end

return ItemSelector