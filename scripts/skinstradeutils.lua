require("skinsutils")
require("trade_recipes")

function GetNumberSelectedItems(selections)
	local count = 0

	for rarity, value in pairs(selections) do 
		for key, item in pairs(value) do 
			count = count + 1
		end
	end

	return count
end

-- Takes a flat array of items, and rebuilds it into a table 
-- indexed by rarity.
function RebuildSelectionsByRarity(selectionsIn)
	local selected_items = {}

	for k, item in pairs(selectionsIn) do 
		local rarity = GetRarityForItem(item.type, item.item)

		if not selected_items[rarity] then 
			selected_items[rarity] = {}
		end
		 
		table.insert(selected_items[rarity], item)
		
	end

	return selected_items
end


-- Returns a list of rules that does match this set of selected items or might match this set of selected items if more are added.
-- 
-- Assumes that there is only one input type per rule, and that input only specifies rarity and number.
function GetRecipeMatches(selectionsIn)

	local selections = RebuildSelectionsByRarity(selectionsIn)

	local rules = {}

	local num_selections = GetNumberSelectedItems(selections)

	for rule_name, rule_contents in pairs(TRADE_RECIPES) do 

		if num_selections == 0 then 
			table.insert(rules, rule_name)
		elseif selections[rule_contents.inputs.rarity] then 
			if #selections[rule_contents.inputs.rarity] <= rule_contents.inputs.number then 
				table.insert(rules, rule_name)
			end
		end

	end

	return rules
end


-- Returns true or false. If true, also returns the specific trade rule that will apply.
-- 
-- Assumes that there is only one input type per rule, and that input only specifies rarity and number.
function IsTradeAllowed(selectionsIn)

	local selections = RebuildSelectionsByRarity(selectionsIn)

	local rules = {}
	
	
	-- TODO: this doesn't handle tags, only rarities
	-- TODO: this also doesn't handle multiple input rules

	for rule_name, rule_contents in pairs(TRADE_RECIPES) do

		if selections[rule_contents.inputs.rarity] then 
				if #selections[rule_contents.inputs.rarity] == rule_contents.inputs.number then 
				return true, rule_name
			end
		end

	end

	return false
end


-- Generate a list of filters from a set of trade rules. Currently, this should always result in a table containing a single 
-- rarity name.
function GetFilters(rules)
	local filters = {}

	for k, v in pairs(rules) do
		local inputs = TRADE_RECIPES[v].inputs
		--print("Getting filter for", v, inputs.rarity)
		assert(inputs)
		
		table.insert(filters, inputs.rarity)
	end

	table.sort(filters, CompareRarities)

	return filters
end

function SubstituteRarity(text, rarity)
	return string.gsub(text, "<rarity>", rarity)
end