local Customise = require "map/customise"
local Levels = require "map/levels"


local function makedescstring(desc)
    if desc ~= nil then
        local descstring = "-- "
        if type(desc) == "function" then
            desc = desc()
        end
        for i,v in ipairs(desc) do
            descstring = descstring..string.format('"%s"', v.data)
            if i < #desc then
                descstring = descstring..", "
            end
        end
        return descstring
    else
        return nil
    end
end


local out = {}
table.insert(out, "return {")
table.insert(out, "\toverride_enabled = true,")


local presets = "-- "
for i, level in ipairs(Levels.GetLevelList(LEVELTYPE.SURVIVAL)) do
    if i > 0 then
        presets = presets .. " or "
    end
    presets = presets .. '"' ..level.data.. '"'
end
table.insert(out, string.format("\tpreset = %s, %s", Levels.GetLevelList(LEVELTYPE.SURVIVAL)[1].data, presets))

table.insert(out, '\toverrides = {')
local lastgroup = nil
for i,item in ipairs(Customise.GetOptions()) do
    if lastgroup ~= nil and lastgroup ~= item.group then
        table.insert(out, '')
    end
    lastgroup = item.group

    if item.desc ~= nil then
        table.insert(out, string.format('\t\t%s = "%s", %s', item.name, item.value, makedescstring(item.desc)))
    else
        table.insert(out, string.format('\t\t%s = "%s",', item.name, item.value))
    end
end
table.insert(out, "\t},")
table.insert(out, "}")

print( table.concat(out, "\n"))

local path = "worldgenoverride.lua"

local file, err = io.open(path, "w")
if err ~= nil then
    print("ERROR! ",err)
else
    file:write( table.concat(out, "\n") )
    file:close()
    print()
    print("Wrote to worldgenoverride.lua")
end
