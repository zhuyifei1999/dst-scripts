-- For shortcut purposes, but if needed there's a HexToRGB function in util.lua, as well as a
-- RGBToPercentColor and a HexToPercentColor one
SKIN_RARITY_COLORS =
{
	Common			= { 0.718, 0.824, 0.851, 1 }, -- B7D2D9 - a common item
	Classy			= { 0.255, 0.314, 0.471, 1 }, -- 415078 - an uncommon item
	Spiffy			= { 0.408, 0.271, 0.486, 1 }, -- 68457C - a rare item (eg Trenchcoat)
	Distinguished	= { 0.729, 0.455, 0.647, 1 }, -- BA74A5 - a very rare item (eg Tuxedo)
	Elegant			= { 0.741, 0.275, 0.275, 1 }, -- BD4646 - an extremely rare item (eg rabbit pack, GoH base skins)
	Timeless		= { 0.957, 0.769, 0.188, 1 }, -- F4C430 - not used
	Loyal			= { 0.635, 0.769, 0.435, 1 }, -- A2C46F - a one-time giveaway (eg mini monument)
}

-- for use in sort functions
-- return true if rarity1 should go first in the list
function CompareRarities(a, b)
	local rarity1 = type(a) == "string" and a or a.rarity
	local rarity2 = type(b) == "string" and b or b.rarity

	if rarity1 == rarity2 then 
		return false
	elseif rarity1 == "Loyal" then 
		return true
	elseif rarity1 == "Timeless" and 
		rarity2 ~= "Loyal" then 
		return true
	elseif rarity1 == "Elegant" and 
		rarity2 ~= "Loyal" and 
		rarity2 ~= "Timeless" then 
		return true
	elseif rarity1 == "Distinguished" and 
		(	rarity2 == "Spiffy" or 
			rarity2 == "Classy" or 
			rarity2 == "Common" ) then 
		return true
	elseif rarity1 == "Spiffy" and 
		( rarity2 == "Classy" or rarity2 == "Common" ) then 
		return true
	elseif rarity1 == "Classy" and 
		rarity2 == "Common" then 
		return true
	else
		return false
	end

	return false
end

function GetNextRarity(rarity)
	local rarities = {Common = "Classy",
					  Classy = "Spiffy",
					  Spiffy = "Distinguished",
					  Distinguished = "Elegant",
					  Elegant = "Timeless",
					  Timeless = "Loyal"
					 }

	return rarities[rarity] or nil
end

function GetBuildForItem(type, name)
	if type == "base" or type == "item" then 
		local skinsData = Prefabs[name]
		if skinsData and skinsData.ui_preview then
			name = skinsData.ui_preview.build
		end
		return name
	else
		--for now assume that clothing build matches the item name
		return name
	end
end

function GetTypeForItem(item)


	local itemName = string.lower(item) -- they come back from the server in caps
	local type = "unknown"

	--print("Getting type for ", itemName)


	if CLOTHING[itemName] then 
		type = CLOTHING[itemName].type
	else
		local skinsData = Prefabs[itemName]

		if skinsData then 
			if table.contains(skinsData.tags, "CHARACTER") then 
				type = "base"
			else
				type = "item"
			end
		end
	end

	return type, itemName
end


function GetRarityForItem(type, item)
	local rarity = "Common"

	if type == "base" or type == "item" then 
		local skinsData = Prefabs[item]
		if skinsData then 
			rarity = skinsData.rarity
		end
	elseif CLOTHING[item] then 
		rarity = CLOTHING[item].rarity
	end

	if not rarity then 
		rarity = "Common"
	end

	return rarity
end


function GetNameWithRarity(type, item)
	local rarity = GetRarityForItem(type, item)

	local nameStr = STRINGS.SKIN_NAMES[item] or STRINGS.SKIN_NAMES["missing"]
	local alt = STRINGS.SKIN_NAMES[item.."_alt"]
	if alt then 
		nameStr = GetRandomItem({nameStr, alt})
	end

	return rarity.." "..nameStr

end

function GetName(item)

	local nameStr = STRINGS.SKIN_NAMES[item] or STRINGS.NAMES[string.upper(item)] 
					or STRINGS.SKIN_NAMES["missing"]
	local alt = STRINGS.SKIN_NAMES[item.."_alt"]
	if alt then 
		nameStr = GetRandomItem({nameStr, alt})
	end

	return nameStr

end

function IsSkinEntitlementReceived(entitlement)
	return Profile:IsEntitlementReceived(entitlement)
end

function SetSkinEntitlementReceived(entitlement)
	Profile:SetEntitlementReceived(entitlement)
end

----------------------------------------------------

local Widget = require "widgets/widget"
local ItemImage = require "widgets/itemimage"

function SkinLineConstructor(screen, parent, num_pictures, disable_selecting)

	local widget = parent:AddChild(Widget("inventory-line"))
	local offset = 0

	widget.screen = screen
	widget.images = {}

	--create the empty item image widgets which we'll populate later with data
	for i = 1,num_pictures do
		local itemimage = widget:AddChild(ItemImage(screen, nil, "", "", 0, 0, nil, nil, nil ))

		itemimage.clickFn = function(type, item, item_id) 
				screen:OnItemSelect(type, item, item_id, itemimage)
			end

		itemimage:SetPosition(offset, -15, 0)
		offset = offset + 80

		if i > 1 then 
			itemimage:SetFocusChangeDir(MOVE_LEFT, widget.images[#widget.images - 1])
			widget.images[i-1]:SetFocusChangeDir(MOVE_RIGHT, itemimage)
		end
		
		table.insert(widget.images, itemimage)
	end

	widget.focus_forward = widget.images[1]

	-- When the itemimage gets focus, it tells the screen to set the focus_column so we can look it up here
	widget.OnGainFocus = function() 
		local focus_column = widget.screen.focus_column or 1
		widget.images[focus_column]:SetFocus()
	end

	widget.ForceFocus = function()
		local focus_column = widget.screen.focus_column or 1
		widget.images[focus_column]:Embiggen()
	end

	if disable_selecting then 
		for _,item_image in pairs(widget.images) do
			item_image:DisableSelecting()
		end
	end	
	widget.disable_selecting = disable_selecting
	
	return widget
end

function UpdateSkinLine(widget, data, row_number, screen)
	local focus_index = screen.focus_index

	--print("UpdateSkinLine has screen", screen, screen.focus_index)
	local offset = 0
	for i = 1, #data do 
		local item = data[i]

		local idx = (row_number-1)*#data+i
		--print("Item ", idx, " is", item.item, item.item_id)
		widget.images[i]:SetItem(idx, item.type, item.item, item.item_id, item.timestamp)

		offset = offset + 100

		if not widget.disable_selecting then
			if focus_index and focus_index == (idx) then
				--print("Selecting image ", row_number, idx)
				widget.images[i]:Select()
				--widget.images[i]:ForceClick()
			else
				widget.images[i]:Unselect()
			end
		end

		widget.images[i]:Show()

		if screen.show_hover_text then
			local rarity = GetRarityForItem(item.type, item.item)
			local hover_text = rarity .. "\n" .. GetName(item.item)
			widget.images[i]:SetHoverText( hover_text, { font = NEWFONT_OUTLINE, size = 20, offset_x = 0, offset_y = 50, colour = {1,1,1,1}})
		end
	end

	if #data < #widget.images then 
		for i = (#data+1), #widget.images do 
			widget.images[i]:SetItem(nil, nil, nil, nil)
			widget.images[i]:Unselect()
			if screen.show_hover_text then
				widget.images[i]:ClearHoverText()
			end
		end
	end


end


function GetSortedSkinsList()
	local templist = TheInventory:GetFullInventory()
	local skins_list = {}
	local timestamp = 0

	local listoflists = 
	{
		feet = {},
		hand = {},
		body = {},
		legs = {},
		base = {},
		item = {},
	}

	for k,v in ipairs(templist) do 
		local type, item = GetTypeForItem(v.item_type)
		local rarity = GetRarityForItem(type, item)

		if type ~= "unknown" then

			local data = {}
			data.type = type
			data.item = item
			data.rarity = rarity
			data.timestamp = v.modified_time
			data.item_id = v.item_id
		
			table.insert(listoflists[type], data)
			
			if v.modified_time > timestamp then 
				timestamp = v.modified_time
			end
		end
	end

	local compare = function(a, b) 
						if a.rarity == b.rarity then 
							if a.item == b.item then 
								return a.timestamp > b.timestamp
							else
								return a.item < b.item 
							end
						else 
							return CompareRarities(a,b)
						end
					end
	table.sort(listoflists.feet, compare)

	table.sort(listoflists.hand, compare)
	table.sort(listoflists.body, compare)
	table.sort(listoflists.legs, compare)
	table.sort(listoflists.base, compare)
	table.sort(listoflists.item, compare)


	skins_list = JoinArrays(skins_list, listoflists.item)
	skins_list = JoinArrays(skins_list, listoflists.base)
	skins_list = JoinArrays(skins_list, listoflists.body)
	skins_list = JoinArrays(skins_list, listoflists.hand)
	skins_list = JoinArrays(skins_list, listoflists.legs)
	skins_list = JoinArrays(skins_list, listoflists.feet)


	return skins_list, timestamp
end


function CopySkinsList(list)
	local newList = {}
	for k, skin in ipairs(list) do 
		newList[k] = {}
		newList[k].type = skin.type
		newList[k].item = skin.item
		newList[k].item_id = skin.item_id
		newList[k].timestamp = skin.modified_time
	end

	return newList
end

function SplitSkinsIntoInventoryRows(skins_list, num_items_per_row)
	local inventory_rows = {}
	
	--split skins_list data into chunks of 4 items, for each row
	local line_items = {}
	for k,v in ipairs(skins_list) do	
		if #line_items < num_items_per_row then
			table.insert(line_items, v)
		end
		if #line_items == num_items_per_row then 
			inventory_rows[#inventory_rows + 1] = line_items
			line_items = {}
		end
	end
	if #line_items > 0 then 
		inventory_rows[#inventory_rows + 1] = line_items
	end
	
	return inventory_rows
end

