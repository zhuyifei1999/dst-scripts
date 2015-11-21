
local startlocations = {}

function AddStartLocation(name, data)
    startlocations[name] = data
end

function GetGenStartLocations(world)
    local ret = {}
    for k,v in pairs(startlocations) do
        if world == nil or v.location == world then
            table.insert(ret, {text = v.name, data = k})
        end
    end
    return ret
end

function GetStartLocation(name)
    return startlocations[name]
end

AddStartLocation("default", {
    name = STRINGS.UI.SANDBOXMENU.DEFAULTSTART,
    location = "forest",
    start_setpeice = "DefaultStart",
    start_node = "Clearing",
})

AddStartLocation("plus", {
    name = STRINGS.UI.SANDBOXMENU.PLUSSTART,
    location = "forest",
    start_setpeice = "DefaultPlusStart",	
    start_node = {"DeepForest", "Forest", "SpiderForest", "Plain", "Rocky", "Marsh"},
})

AddStartLocation("darkness", {
    name = STRINGS.UI.SANDBOXMENU.DARKSTART,
    location = "forest",
    start_setpeice = "DarknessStart",	
    start_node = {"DeepForest", "Forest"},	
})

AddStartLocation("caves", {
    name = STRINGS.UI.SANDBOXMENU.CAVESTART,
    location = "cave",
    start_setpeice = "CaveStart",	
    start_node = {
        "RabbitArea",
        "RabbitTown",
        "RabbitSinkhole",
        "SpiderIncursion",
        "SinkholeForest",
        "SinkholeCopses",
        "SinkholeOasis",
        "GrasslandSinkhole",
        "GreenMushSinkhole",
        "GreenMushRabbits",
    },
})

return {
    startlocations = startlocations,
    GetGenStartLocations = GetGenStartLocations,
    GetStartLocation = GetStartLocation,
}
