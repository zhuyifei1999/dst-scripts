local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    --HASHEATER (from heater component) added to pristine state for optimization
    inst:AddTag("HASHEATER")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakeSmallBurnable(inst, 4 + math.random() * 4)
    MakeSmallPropagator(inst)
    inst.components.burnable:Ignite()

    inst:AddComponent("heater")
    inst.components.heater.heat = 70

    return inst
end

return Prefab("willow_fire", fn)