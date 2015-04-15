
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()

    --[[Non-networked entity]]

    return inst
end
   
return Prefab("forest/objects/cave_stairs", fn, assets)