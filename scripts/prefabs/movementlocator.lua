local assets =
{

}

local prefabs =
{

}

local function fn()

    local inst = CreateEntity()

    inst.entity:AddTransform()
    
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")
    inst:AddTag("ignorewalkableplatforms")

    inst.persists = false
    inst.entity:SetCanSleep(false)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return Prefab("movementlocator", fn, assets, prefabs)
