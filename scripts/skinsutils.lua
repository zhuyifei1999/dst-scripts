-- For shortcut purposes, but if needed there's a HexToRGB function in util.lua, as well as a
-- RGBToPercentColor and a HexToPercentColor one
SKIN_RARITY_COLORS =
{
	Common			= { 0.718, 0.824, 0.851, 1 }, -- B7D2D9 - a common item (eg t-shirt, plain gloves)
	Classy			= { 0.255, 0.314, 0.471, 1 }, -- 415078 - an uncommon item (eg dress shoes, checkered trousers)
	Spiffy			= { 0.408, 0.271, 0.486, 1 }, -- 68457C - a rare item (eg Trenchcoat)
	Distinguished	= { 0.729, 0.455, 0.647, 1 }, -- BA74A5 - a very rare item (eg Tuxedo)
	Elegant			= { 0.741, 0.275, 0.275, 1 }, -- BD4646 - an extremely rare item (eg rabbit pack, GoH base skins)
	Timeless		= { 0.424, 0.757, 0.482, 1 }, -- 6CC17B - not used
	Loyal			= { 0.635, 0.769, 0.435, 1 }, -- A2C46F - a one-time giveaway (eg mini monument)
	ProofOfPurchase = { 0.000, 0.478, 0.302, 1 }, -- 007A4D
	Reward			= { 0.910, 0.592, 0.118, 1 }, -- E8971E - a set bonus reward
	Event			= { 0.957, 0.769, 0.188, 1 }, -- F4C430 - an event item
	
	Lustrous		= { 1.000, 1.000, 0.298, 1 }, -- FFFF4C - rarity modifier
	-- #40E0D0 reserved skin colour
}
DEFAULT_SKIN_COLOR = SKIN_RARITY_COLORS["Common"]

--[[
Common #B7D2D9
Classy #415078
Spiffy #68457C
Distinguished #BA74A5
Elegant #BD4646
Timeless #6CC17B
Loyal #A2C46F
ProofOfPurchase #007A4D
Reward #E8971E
Event #F4C430
#40E0D0 reserved skin colour
]]

-- for use in sort functions
-- return true if rarity1 should go first in the list
local rarity_order =
{
	ProofOfPurchase = 1,
	Timeless = 2,
	Loyal = 3,
	Reward = 4,
	Event = 5,
	Elegant = 6,
	Distinguished = 7,
	Spiffy = 8,
	Classy = 9,
	Common = 10
}
function CompareRarities(a, b)
	local rarity1 = type(a) == "string" and a or a.rarity
	local rarity2 = type(b) == "string" and b or b.rarity

	return rarity_order[rarity1] < rarity_order[rarity2]
end

function GetNextRarity(rarity)
	--just used by the tradescreen
	local rarities = {Common = "Classy",
					  Classy = "Spiffy",
					  Spiffy = "Distinguished",
					  Distinguished = "Elegant",
					  Elegant = "Event",
					  Event = "Reward",
					  Reward = "Loyal",
					  Loyal = "Timeless",
					  Timeless = "ProofOfPurchase"
					 }

	return rarities[rarity] or nil
end

function GetBuildForItem(name)
	if CLOTHING[name] then
		name = name
	elseif MISC_ITEMS[name] then
		name = MISC_ITEMS[name].skin_build
	elseif EMOTE_ITEMS[name] then
		name = EMOTE_ITEMS[name].skin_build
	else
		if Prefabs[name] ~= nil then
			name = Prefabs[name].build_name
		end
	end
	
	return name
end

function IsClothingItem(name)
	if CLOTHING[name] then 
		return true
	end
	return false
end

function IsItemId(name)
	if Prefabs[name] then
		return true
	elseif MISC_ITEMS[name] then
		return true
	elseif CLOTHING[name] then
		return true
	elseif EMOTE_ITEMS[name] then
		return true
	end
	return false
end

function GetSkinData(item)
	local skin_data = {}
	
	if CLOTHING[item] then 
		skin_data = CLOTHING[item]
	elseif MISC_ITEMS[item] then 
		skin_data = MISC_ITEMS[item]
	elseif EMOTE_ITEMS[item] then 
		skin_data = EMOTE_ITEMS[item]
	else
		if Prefabs[item] ~= nil then
			skin_data = Prefabs[item]
		end
	end
	return skin_data
end

function GetColorForItem(item)
	local skin_data = GetSkinData(item)
	return SKIN_RARITY_COLORS[skin_data.rarity_modifier] or SKIN_RARITY_COLORS[skin_data.rarity] or DEFAULT_SKIN_COLOR
end

function GetModifiedRarityStringForItem( item )
	if GetRarityModifierForItem(item) ~= nil then
		return STRINGS.UI.RARITY[GetRarityModifierForItem(item)] .. " " .. STRINGS.UI.RARITY[GetRarityForItem(item)]
	else
		return STRINGS.UI.RARITY[GetRarityForItem(item)]
	end
end

function GetRarityModifierForItem(item)
	local skin_data = GetSkinData(item)
	local rarity_modifier = skin_data.rarity_modifier
	return rarity_modifier
end

function GetRarityForItem(item)
	local skin_data = GetSkinData(item)
	local rarity = skin_data.rarity
	
	if not rarity then 
		rarity = "Common"
	end
	
	return rarity
end

function GetSkinUsableOnString(item_type, popup_txt)
	local skin_data = GetSkinData(item_type)
	
	local skin_str = GetName(item_type)
	
	local usable_on_str = ""
	if skin_data ~= nil and skin_data.base_prefab ~= nil then
		if skin_data.granted_items == nil then
			local item_str = STRINGS.NAMES[string.upper(skin_data.base_prefab)]
			usable_on_str = subfmt(popup_txt and STRINGS.UI.SKINSSCREEN.USABLE_ON_POPUP or STRINGS.UI.SKINSSCREEN.USABLE_ON, { skin = skin_str, item = item_str })
		else
			local item1_str = STRINGS.NAMES[string.upper(skin_data.base_prefab)]
			local item2_str = nil
			local item3_str = nil
			
			local granted_skin_data = GetSkinData(skin_data.granted_items[1])
			if granted_skin_data ~= nil and granted_skin_data.base_prefab ~= nil then
				item2_str = STRINGS.NAMES[string.upper(granted_skin_data.base_prefab)]	
			end
			local granted_skin_data = GetSkinData(skin_data.granted_items[2])
			if granted_skin_data ~= nil and granted_skin_data.base_prefab ~= nil then
				item3_str = STRINGS.NAMES[string.upper(granted_skin_data.base_prefab)]	
			end
			
			if item3_str == nil then
				usable_on_str = subfmt(popup_txt and STRINGS.UI.SKINSSCREEN.USABLE_ON_MULTIPLE_POPUP or STRINGS.UI.SKINSSCREEN.USABLE_ON_MULTIPLE, { skin = skin_str, item1 = item1_str, item2 = item2_str })
			else
				usable_on_str = subfmt(popup_txt and STRINGS.UI.SKINSSCREEN.USABLE_ON_MULTIPLE_3_POPUP or STRINGS.UI.SKINSSCREEN.USABLE_ON_MULTIPLE_3, { skin = skin_str, item1 = item1_str, item2 = item2_str, item3 = item3_str })
			end
		end
	end
	
	return usable_on_str
end

function GetTypeForItem(item)

	local itemName = string.lower(item) -- they come back from the server in caps
	local type = "unknown"

	--print("Getting type for ", itemName)

	if CLOTHING[itemName] then 
		type = CLOTHING[itemName].type
	elseif MISC_ITEMS[itemName] then 
		type = MISC_ITEMS[itemName].type
	elseif EMOTE_ITEMS[itemName] then 
		type = EMOTE_ITEMS[itemName].type
	else
		if Prefabs[itemName] ~= nil then
			type = Prefabs[itemName].type
		end
	end

	return type, itemName
end

function GetSortCategoryForItem(item)
	local category = "none"

	if CLOTHING[item] then
		category = CLOTHING[item].type
	elseif MISC_ITEMS[item] then
		category = MISC_ITEMS[item].type
	elseif EMOTE_ITEMS[item] then
		category = EMOTE_ITEMS[item].type
	else
		local skinsData = Prefabs[item]
		category = skinsData.base_prefab
	end
	
	return category
end

--Note(Peter): do we actually want to do this here, or actually provide the json tags from the pipeline?
function GetTagFromType(type)
	if type == "body" or type == "hand" or type == "legs" or type == "feet" then
		return string.upper("CLOTHING_" .. type)
	elseif type == "base" then
		return "CHARACTER"
	elseif type == "emote" then
		return "EMOTE"
	elseif type == "item" then
		return nil --what tags are on item type things
	elseif type == "oddment" then
		return "ODDMENT"
	else
		return string.upper("MISC_" .. type)
	end
end
function GetTypeFromTag(tag)
	if string.find(tag, "CLOTHING_") then
		return string.lower( string.gsub(tag, "CLOTHING_", "") )
	elseif string.find(tag, "CHARACTER") then
		return "base"
	else
		return nil --What do we want to do about colour and misc tags?
	end
end

function GetColourFromColourTag(c) --UNTESTED!!!
	local s = string.lower(c)
	return s:sub(1,1):upper()..s:sub(2)
end
function GetColourTagFromColour(c)
	return string.upper(c)
end

function GetName(item)
	if string.sub( item, -8 ) == "_builder" then
		item = string.sub( item, 1, -9 )
	end
	local nameStr = STRINGS.SKIN_NAMES[item] or STRINGS.NAMES[string.upper(item)] or STRINGS.SKIN_NAMES["missing"]
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

function SkinGrid4x4Constructor(screen, parent, disable_selecting)
	local NUM_ROWS = 4
	local NUM_COLUMNS = 4
	local SPACING = 85
	--assert( parent.images == nil )
	--parent.images = {}
	local widgets = {}
	
	--local widget = parent:AddChild(Widget("inventory-line"))
	
	local x_offset = (NUM_COLUMNS/2) * SPACING + SPACING/2
	local y_offset = (NUM_ROWS/2) * SPACING + SPACING/2
	
	for y = 1,NUM_ROWS do
		for x = 1,NUM_COLUMNS do
			local index = ((y-1) * NUM_COLUMNS) + x
			
			local itemimage = parent:AddChild(ItemImage(screen, "", "", 0, 0, nil ))
			itemimage.clickFn = function(type, item, item_id) 
				screen:OnItemSelect(type, item, item_id, itemimage)
			end
		
			itemimage:SetPosition( x * SPACING - x_offset, -y * SPACING + y_offset, 0)
		
			
			--parent.images[index] = itemimage
			widgets[index] = itemimage
			
			if x > 1 then 
				itemimage:SetFocusChangeDir(MOVE_LEFT, widgets[index-1])
				widgets[index-1]:SetFocusChangeDir(MOVE_RIGHT, itemimage)
			end
			if y > 1 then 
				itemimage:SetFocusChangeDir(MOVE_UP, widgets[index-NUM_COLUMNS])
				widgets[index-NUM_COLUMNS]:SetFocusChangeDir(MOVE_DOWN, itemimage)
			end
		end	
	end
	
	if disable_selecting then
		for _,item_image in pairs(widgets) do
			item_image:DisableSelecting()
		end
	end
	
	return widgets
end

function UpdateSkinGrid(list_widget, data, screen)
	if data ~= nil then
		list_widget:SetItem(data.type, data.item, data.item_id, data.timestamp)

		if not list_widget.disable_selecting then
			list_widget:Unselect() --unselect everything when the data is updated
			if list_widget.focus then --but maintain focus on the widget
				list_widget:Embiggen()
			end
		end

		list_widget:Show()

		if screen.show_hover_text then
			local rarity = GetRarityForItem(data.item)
			local hover_text = rarity .. "\n" .. GetName(data.item)
			list_widget:SetHoverText( hover_text, { font = NEWFONT_OUTLINE, size = 20, offset_x = 0, offset_y = 60, colour = {1,1,1,1}})
			if list_widget.focus then --make sure we force the hover text to appear on the default focused item
				list_widget:OnGainFocus()
			end
		end
	else
		list_widget:SetItem(nil, nil, nil)
		list_widget:Unselect()
		if list_widget.focus then --maintain focus on the widget
			list_widget:Embiggen()
		end
		if screen.show_hover_text then
			list_widget:ClearHoverText()
		end
	end
end

function GetSortedSkinsList()
	local templist = TheInventory:GetFullInventory()
	local skins_list = {}
	local timestamp = 0

	local listoflists = 
	{
		oddment = {},
		emote = {},
		feet = {},
		hand = {},
		body = {},
		legs = {},
		base = {},
		item = {},
		misc = {},
		unknown = {},
	}

	for k,v in ipairs(templist) do 
		local type, item = GetTypeForItem(v.item_type)
		local rarity = GetRarityForItem(item)

		--if type ~= "unknown" then

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
		--end
	end

	local compare = function(a, b) 
						if a.rarity == b.rarity then 
							if a.item == b.item then 
								return a.timestamp > b.timestamp
							else
								return GetSortCategoryForItem(a.item)..GetName(a.item)..a.item < GetSortCategoryForItem(b.item)..GetName(b.item)..b.item
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
	table.sort(listoflists.emote, compare)
	table.sort(listoflists.oddment, compare)
	table.sort(listoflists.misc, compare)
	table.sort(listoflists.unknown, compare)

	skins_list = JoinArrays(skins_list, listoflists.oddment)
	skins_list = JoinArrays(skins_list, listoflists.emote)
	skins_list = JoinArrays(skins_list, listoflists.item)
	skins_list = JoinArrays(skins_list, listoflists.base)
	skins_list = JoinArrays(skins_list, listoflists.body)
	skins_list = JoinArrays(skins_list, listoflists.hand)
	skins_list = JoinArrays(skins_list, listoflists.legs)
	skins_list = JoinArrays(skins_list, listoflists.feet)
	skins_list = JoinArrays(skins_list, listoflists.misc)
	skins_list = JoinArrays(skins_list, listoflists.unknown)

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



local SKIN_SET_ITEMS = require("skin_set_info")
function IsItemInCollection(item_type)
	for bonus_item,input_items in pairs(SKIN_SET_ITEMS) do
		if bonus_item == item_type then
			return true
		end
		for _,input_item in pairs(input_items) do
			if input_item == item_type then
				return true
			end
		end
	end
	return false
end
function IsItemIsReward(item_type)
	for bonus_item,input_items in pairs(SKIN_SET_ITEMS) do
		if bonus_item == item_type then
			return true
		end
	end
	return false
end
function GetSkinSetData(item_type)
	for bonus_item,input_items in pairs(SKIN_SET_ITEMS) do
		local item_pos = 0
		local set_count = 0
		for _,input_item in pairs(input_items) do
			set_count = set_count + 1
			if input_item == item_type then
				item_pos = set_count
			end
		end
		if item_pos > 0 then
			return item_pos,set_count,bonus_item
		end
	end
end