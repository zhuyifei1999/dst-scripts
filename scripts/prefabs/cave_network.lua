local MakeWorldNetwork = require("prefabs/world_network")

local function custom_postinit(inst)
    inst:AddComponent("caveweather")
    inst:AddComponent("quaker")
end

return MakeWorldNetwork("cave_network", custom_postinit)
