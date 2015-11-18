local MakeWorldNetwork = require("prefabs/world_network")

local function custom_postinit(inst)
    inst:AddComponent("weather")
end

return MakeWorldNetwork("forest_network", custom_postinit)
