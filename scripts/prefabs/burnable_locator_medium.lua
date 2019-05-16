
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    MakeLargeBurnable(inst)
    MakeSmallPropagator(inst)

    return inst
end

return Prefab("burnable_locator_medium", fn)
