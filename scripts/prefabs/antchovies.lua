local assets =
{
    Asset("ANIM", "anim/water_antchovies.zip"),
}

local function fn()

    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()    
    MakeInventoryPhysics(inst)

    inst.entity:AddDynamicShadow()
    
    inst.DynamicShadow:SetSize(0.65, 0.25)

    inst.AnimState:SetBank("antchovies")
    inst.AnimState:SetBuild("water_antchovies")     

    inst.entity:SetPristine()    

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst:SetStateGraph("SGantchovies")

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.MEAT

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM    

    return inst
end

return Prefab("antchovies", fn, assets)
