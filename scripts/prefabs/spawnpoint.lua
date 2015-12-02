local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    --[[Non-networked entity]]

    inst:AddTag("spawnpoint")
    inst:AddTag("CLASSIFIED")

    inst.persists = false

    return inst
end

return Prefab("common/spawnpoint", fn)