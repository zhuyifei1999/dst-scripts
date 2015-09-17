local MakeWorldNetwork = require("prefabs/world_network")

local function custom_postinit(inst)
    inst:AddComponent("caveweather")
end

return MakeWorldNetwork("cave_network", custom_postinit)
