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
for i, level in ipairs(Levels.sandbox_levels) do
    if i > 0 then
        presets = presets .. " or "
    end
    presets = presets .. '"' ..level.id.. '"'
end
table.insert(out, string.format("\tpreset = %s, %s", Levels.sandbox_levels[1].id, presets))

for name,group in pairs(Customise.GROUP) do
    local desc = group.desc

    if desc then
        table.insert(out, string.format("\t%s = { %s", name, makedescstring(desc)))
    else
        table.insert(out, string.format("\t%s = {", name, makedescstring(desc)))
    end

    local itemkeys = {}
    for itemname,_ in pairs(group.items) do
        table.insert(itemkeys, itemname)
    end
    table.sort(itemkeys)

    for i,itemname in ipairs(itemkeys) do
        local item = group.items[itemname]
        if desc == nil and item.desc ~= nil then
            table.insert(out, string.format('\t\t%s = "%s", %s', itemname, item.value, makedescstring(item.desc)))
        else
            table.insert(out, string.format('\t\t%s = "%s",', itemname, item.value))
        end
    end

    table.insert(out, "\t},")
end
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
