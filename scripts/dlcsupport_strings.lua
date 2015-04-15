USE_PREFIX = {} -- A table of which strings use prefixes and which use suffixes when constructing names in EntityScript
USE_PREFIX[STRINGS.SMOLDERINGITEM] = true
USE_PREFIX[STRINGS.WITHEREDITEM] = true
USE_PREFIX[STRINGS.WET_PREFIX.FOOD] = true
USE_PREFIX[STRINGS.WET_PREFIX.CLOTHING] = true
USE_PREFIX[STRINGS.WET_PREFIX.TOOL] = true
USE_PREFIX[STRINGS.WET_PREFIX.FUEL] = true
USE_PREFIX[STRINGS.WET_PREFIX.GENERIC] = true
USE_PREFIX[STRINGS.WET_PREFIX.WETGOOP] = true -- Special case using inst.wet_prefix set on wet goop to WET_PREFIX.WETGOOP
USE_PREFIX[STRINGS.NAMES.WETGOOP] = true -- Special case using inst.wet_prefix set on wet goop to WET_PREFIX.WETGOOP
USE_PREFIX[STRINGS.WET_PREFIX.RABBITHOLE] = true -- Special case using inst.wet_prefix on rabbit hole set to WET_PREFIX.RABBITHOLE
USE_PREFIX[STRINGS.NAMES.RABBITHOLE] = true -- Special case using inst.wet_prefix on rabbit hole set to WET_PREFIX.RABBITHOLE

local AdjectiveMode = "PREFIX"

local function TryGuaranteeCoverage(item, usePrefix)
	-- Look for item in the STRINGS.NAMES table
	local name = nil
	for i,v in pairs(STRINGS.NAMES) do
		if item == v then
			-- If we find it, save the key so we can look for that key in the STRINGS.WET_PREFIX table
			name = i
			break
		end
	end
	if name and STRINGS.WET_PREFIX[name] then USE_PREFIX[STRINGS.WET_PREFIX[name]] = usePrefix end

	-- And vice versa for prefix
	local prefix = nil
	for i,v in pairs(STRINGS.WET_PREFIX) do
		if item == v then
			prefix = i
			break
		end
	end
	if prefix and STRINGS.NAMES[prefix] then USE_PREFIX[STRINGS.NAMES[prefix]] = usePrefix end
	
	-- Now check if the value is a key itself in either of the tables. If so, add its value to USES_PREFIX
	if STRINGS.NAMES[string.upper(item)] then USE_PREFIX[STRINGS.NAMES[string.upper(item)]] = usePrefix end
	if STRINGS.WET_PREFIX[string.upper(item)] then USE_PREFIX[STRINGS.WET_PREFIX[string.upper(item)]] = usePrefix end
end

-- Use this to make all adjectives into suffixes
function MakeAllSuffixes(fn)
    for i,v in pairs(USE_PREFIX) do
        if fn then
            USE_PREFIX[i] = fn 
        else
            USE_PREFIX[i] = false
        end
    end
    AdjectiveMode = "SUFFIX"
end

-- Use this to make all adjectives into prefixes
function MakeAllPrefixes(fn)
    for i,v in pairs(USE_PREFIX) do
        if fn then
            USE_PREFIX[i] = fn
        else
            USE_PREFIX[i] = true
        end
    end
    AdjectiveMode = "PREFIX"
end

 -- Use this to specify whether a particular item should use a prefix or a suffix
 -- This can also be used to add a new item to the USE_PREFIX table
function SetUsesPrefix(item, usePrefix)
    if type(item) ~= "string" then return end

    if item and usePrefix ~= nil then
        USE_PREFIX[item] = usePrefix
        TryGuaranteeCoverage(item, usePrefix)
    end
end

-- Check if the item uses a prefix or a suffix
function UsesPrefix(item)
    if type(item) ~= "string" then return end
    if item then
        return USE_PREFIX[item]
    end
end

function ConstructAdjectivedName(inst, name, adjective)
	-- Pull the real name based on the prefab if we have only been handed that for some reason
	if not name and inst and inst.prefab then 
		name = STRINGS.NAMES[string.upper(inst.prefab)]
	end

	-- Adjective is stronger binding: we only want to base it off the name for special cases (in which case the adjective won't be in the table)
    local usePrefix = UsesPrefix(adjective) ~= nil and UsesPrefix(adjective) or UsesPrefix(name)

    local construction = nil

    -- First check if USES_PREFIX for this thing is a function
    if type(usePrefix) == "function" then
    	-- If so, try the function, but only use the result if it returns a string
    	local tryfunction = usePrefix(inst, name, adjective)
    	if type(tryfunction) == "string" then
    		construction = tryfunction
    	end
    end

    -- If we don't have a string yet (either the entry in the table wasn't a function or the function returned a bad value), try the table value directly
    if not construction then
    	if usePrefix == nil or usePrefix then
	        construction = adjective.." "..name
	    else
	        construction = name.." "..adjective
	    end
	end

	-- Last failsafe case: use prefix/suffix based on mode)
	if not construction then 
		if AdjectiveMode == "PREFIX" then
			construction = adjective.." "..name 
		else
			construction = name.." "..adjective
		end
	end

	return construction
end
