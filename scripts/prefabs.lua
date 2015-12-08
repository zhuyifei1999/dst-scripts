require("class")
--require("entityscript")
--PREFABS.LUA
require("prefabskins")

Prefab = Class( function(self, name, fn, assets, deps)
    self.name = string.sub(name, string.find(name, "[^/]*$"))  --remove any legacy path on the name
    self.desc = ""
    self.fn = fn
    self.assets = assets or {}
    self.deps = deps or {}
    
    if PREFAB_SKINS[self.name] ~= nil then
		for _,prefab_skin in pairs(PREFAB_SKINS[self.name]) do
			table.insert( self.deps, prefab_skin )
		end
    end
end)

function Prefab:__tostring()
    return string.format("Prefab %s - %s", self.name, self.desc)
end

Asset = Class( function(self, type, file)
    self.type = type
    self.file = file
end)