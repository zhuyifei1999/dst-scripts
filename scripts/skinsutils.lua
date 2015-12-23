-- For shortcut purposes, but if needed there's a HexToRGB function in util.lua, as well as a
-- RGBToPercentColor and a HexToPercentColor one
SKIN_RARITY_COLORS =
{
	Common			= { 0.718, 0.824, 0.851, 1 }, -- B7D2D9 - a common item
	Classy			= { 0.255, 0.314, 0.471, 1 }, -- 415078 - an uncommon item
	Spiffy			= { 0.408, 0.271, 0.486, 1 }, -- 68457C - a rare item (eg bearger pack)
	Distinguished	= { 0.729, 0.455, 0.647, 1 }, -- BA74A5 - an extremely rare item (eg footpack)
	Elegant			= { 0.741, 0.275, 0.275, 1 }, -- BD4646 - not used
	Timeless		= { 0.957, 0.769, 0.188, 1 }, -- F4C430 - not used
	Loyal			= { 0.635, 0.769, 0.435, 1 }, -- A2C46F - a one-time giveaway (eg mini monument)
}

-- for use in sort functions
-- return true if rarity1 should go first in the list
function CompareRarities(a, b)
	local rarity1 = a.rarity
	local rarity2 = b.rarity

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


---------------------------------------------------
------------ Console functions --------------------
---------------------------------------------------

function c_skin_mode(mode)
	ConsoleCommandPlayer().components.skinner:SetSkinMode(mode)
end

function c_skin_name(name)
	ConsoleCommandPlayer().components.skinner:SetSkinName(name)
end

function c_clothing(name)
	ConsoleCommandPlayer().components.skinner:SetClothing(name)
end
function c_clothing_clear(type)
	ConsoleCommandPlayer().components.skinner:ClearClothing(type)
end

function c_cycle_clothing()
	local skinslist = TheInventory:GetFullInventory()

	local idx = 1
	local task = nil

	ConsoleCommandPlayer().cycle_clothing_task = ConsoleCommandPlayer():DoPeriodicTask(10, 
		function() 
			local type, name = GetTypeForItem(skinslist[idx].item_type)
			print("showing clothing idx ", idx, name, type, #skinslist) 
			if (type ~= "base" and type ~= "item") then 
				c_clothing(name) 
			end

			if idx < #skinslist then 
				idx = idx + 1 
			else
				print("Ending cycle")
				ConsoleCommandPlayer().cycle_clothing_task:Cancel()
			end
		end)

end

-- NOTE: only works on the host
function c_giftpopup()
	local GiftItemPopUp = require "screens/giftitempopup"
	TheFrontEnd:PushScreen(GiftItemPopUp(ThePlayer, { "body_suspenders_blue_cornflower", "body_buttons_teal_jade", "body_trenchcoat_grey_dark", "swap_backpack_bigfoot" }))
end

function c_avatarscreen()
    if ThePlayer ~= nil and ThePlayer.HUD ~= nil then
        local client_table = TheNet:GetClientTableForUser(ConsoleCommandPlayer().userid)
        if client_table ~= nil then
            --client_table.inst = ConsoleCommandPlayer() --don't track
            ThePlayer.HUD:TogglePlayerAvatarPopup(client_table.name, client_table)
        end
    end
end


