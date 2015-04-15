local function makefeather(name)
    
    local assetname = "feather_"..name
    local assets = 
    {
	    Asset("ANIM", "anim/"..assetname..".zip"),
    }
    
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        
        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(assetname)
        inst.AnimState:SetBuild(assetname)
        inst.AnimState:PlayAnimation("idle")
        
        if not TheWorld.ismastersim then
            return inst
        end

        inst.entity:SetPristine()

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("inspectable")

        MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
        MakeSmallPropagator(inst)

        MakeHauntableLaunchAndIgnite(inst)

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.nobounce = true
        
        return inst
    end
    return Prefab( "common/inventory/"..assetname, fn, assets)
end

return makefeather("crow"),
       makefeather("robin"),
	   makefeather("robin_winter")