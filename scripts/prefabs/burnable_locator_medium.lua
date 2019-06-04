local function applytickdamage(inst)
	if inst.boat.components.health ~= nil then
		inst.boat.components.health:DoFireDamage(TUNING.BOAT.FIRE_DAMAGE, nil, true)
	end
end

local function onignite(inst)
	inst.boat.activefires = inst.boat.activefires + 1

	inst.task = inst:DoPeriodicTask(1, applytickdamage)
end

local function onextinguish(inst)
	inst.boat.activefires = inst.boat.activefires - 1

	if inst.task ~= nil then
		inst.task:Cancel()
		inst.task = nil
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("NOBLOCK")   
    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    MakeLargeBurnable(inst)
	inst.components.burnable.extinguishimmediately = false
	inst.components.burnable:SetBurnTime(nil)
	inst.components.burnable:SetOnIgniteFn(onignite)
	inst.components.burnable:SetOnExtinguishFn(onextinguish)
	MakeLargePropagator(inst)

    return inst
end

return Prefab("burnable_locator_medium", fn)
