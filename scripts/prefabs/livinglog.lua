local assets =
{
	Asset("ANIM", "anim/livinglog.zip"),
}

local function FuelTaken(inst, taker)
    if taker and taker.SoundEmitter then
        taker.SoundEmitter:PlaySound("dontstarve/creatures/leif/livinglog_burn")
    end
end

local function oneaten(inst, eater)
	inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/livinglog_burn") 
end

local function onignite(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/livinglog_burn")
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("livinglog")
    inst.AnimState:SetBuild("livinglog")
    inst.AnimState:PlayAnimation("idle")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL
    inst.components.fuel:SetOnTakenFn(FuelTaken)

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.WOOD
    inst.components.edible.woodiness = 50
	inst.components.edible:SetOnEatenFn(oneaten)

	MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunchAndIgnite(inst)

    ---------------------       

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst:AddComponent("stackable")

	inst:AddComponent("repairer")
	inst.components.repairer.repairmaterial = MATERIALS.WOOD
	inst.components.repairer.healthrepairvalue = TUNING.REPAIR_LOGS_HEALTH*3

	inst:ListenForEvent("onignite", onignite)

    return inst
end

return Prefab("common/inventory/livinglog", fn, assets)