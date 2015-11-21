package.path = "c:\\DoNotStarve_Branches\\DLC\\data\\scripts\\?.lua;c:\\DoNotStarve_Branches\\DLC\\data\\scripts\\prefabs\\?.lua;"..package.path


local IGNORED_KEYWORDS = 
{
	"BLUEPRINTS",
	"PUPPET",
	"PLACER",
	"FX",
	"PILLAR",
	"HERD",
	"HUD",
	"CHARACTERS",
	"FISSURE",
	"DEBUG",
	"_MED",
	"_NORMAL",
	"_SHORT",
	"_TALL",
	"_LOW",
	"WORLDS",
}

local function GenerateFile(missingStrings)
	local outfile = io.open("MISSINGSTRINGS.lua", "w")
	if outfile then
		outfile:write(missingStrings)
		outfile:close()
	end
end

local function GenIndentString(num)
	local str = ""
	for i = 1, num or 0 do
		str = str.."\t"
	end
	return str
end

local function TableToString(key, table, numIndent)
	local indt = GenIndentString(numIndent)
	local str = ""
	str = str..GenIndentString(numIndent - 1)..key..' = '..'\n'..GenIndentString(numIndent - 1)..'{\n'
	for k,v in pairs(table) do
		if type(v) == "string" then	
			str = str..GenIndentString(numIndent)..k..' = '..'"'..v..'",\n'
		elseif type(v) == "table" then
			str = str..TableToString(k, v, numIndent + 1)			
		end
	end
	str = str..GenIndentString(numIndent - 1)..'},\n'

	return str
end

function GetPrefabsFromFile( fileName )
    local fn, r = loadfile(fileName)
    assert(fn, "Could not load file ".. fileName)
	if type(fn) == "string" then
		assert(false, "Error loading file "..fileName.."\n"..fn)
	end
    assert( type(fn) == "function", "Prefab file doesn't return a callable chunk: "..fileName)
	local ret = {fn()}
	return ret
end

local function GetMissingStrings(prefabs, character)
	local success, speechFile = pcall(require, "speech_"..character)

	if not success then
		return nil
	end

	--print(speechFile)
	local missingStrings = nil

	for k,v in pairs(prefabs) do
		if v and not speechFile.DESCRIBE[v] or (speechFile.DESCRIBE[v] and speechFile.DESCRIBE[v] == "") then
			if not missingStrings then
				missingStrings = {}
			end			
			missingStrings[v] = ""
		end
	end
 
	if missingStrings then
		return missingStrings
	end
end

local function LookForIgnoredKeywords(str)
	for k,v in pairs(IGNORED_KEYWORDS) do
		local IGNORED_KEYWORD, COUNT = string.gsub(string.upper(str), "("..string.upper(v)..")", "")
		if COUNT > 0 then
			return true
		end
	end	
end

local function MakePrefabsTable()
	local ret = {}

	for k,v in pairs(PREFABFILES) do
		local prefabs = GetPrefabsFromFile(v)
		for l,m in pairs(prefabs) do
			if type(m) == "table" then
				local name = m.name or nil
				if name then
					if not LookForIgnoredKeywords(m.path or "SAFEWORD") then
						name = string.upper(name)
						ret[name] = name
					end	
				else
					print("Prefab without name in file: "..v)
				end	
			end
		end
	end

	-- for k,v in pairs(ret) do
	-- 	if LookForIgnoredKeywords(k) then
	-- 		ret[k] = nil
	-- 	end
	-- end

	return ret
end

local function TestStrings()

	local str = ""

	local completePrefabList = MakePrefabsTable()

	local table = {}

	for k,v in pairs(CHARACTERLIST) do
		local tbl = GetMissingStrings(completePrefabList, v)
		table[v] = tbl
	end

	GenerateFile(TableToString("Missing Strings", table, 0))
end

TestStrings()