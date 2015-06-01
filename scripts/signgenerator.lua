
require "strings"


local function GenerateRandomDescription(inst, doer)

	local name = ""

	if math.random() < .4 then 
		name = name .. GetRandomItem(STRINGS.SIGNS.QUANTIFIERS) .. " "
	end

	name = name .. GetRandomItem(STRINGS.SIGNS.ADJECTIVES) .. " "

	local ground_type = doer:GetCurrentTileType()
	local noun = ""
	if STRINGS.SIGNS.NOUNS[ground_type] then 
		noun = GetRandomItem(STRINGS.SIGNS.NOUNS[ground_type])
	else 
		noun = GetRandomItem(STRINGS.SIGNS.DEFAULT_NOUNS)
	end
	name = name .. noun

	if math.random() < .2 then 
		name = name .. " " .. GetRandomItem(STRINGS.SIGNS.ADDITIONS)
	end

	return name
end

return GenerateRandomDescription
