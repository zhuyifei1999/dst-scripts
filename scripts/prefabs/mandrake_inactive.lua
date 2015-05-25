--Raw/ cooked versions
--Can not transform.

local assets =
{
	Asset("ANIM", "anim/mandrake.zip"),
}

local function onpickup(inst)
	inst.AnimState:PlayAnimation("object")
end

local function doareasleep(inst, range, time)
    local pos = Vector3(inst.Transform:GetWorldPosition())
    local ents = TheSim:FindEntities(pos.x,pos.y,pos.z, range)
    for k,v in pairs(ents) do
        local fudge = math.random()
        if v:HasTag("player") then
            v:PushEvent("yawn", { grogginess = 4, knockoutduration = time + fudge })
        elseif v.components.sleeper ~= nil then
            v.components.sleeper:AddSleepiness(7, time + fudge)
        elseif v.components.grogginess ~= nil then
            v.components.grogginess:AddGrogginess(4, time + fudge)
        else
            v:PushEvent("knockedout")
        end
    end
end

local function oneaten_raw(inst, eater)
	eater.SoundEmitter:PlaySound("dontstarve/creatures/mandrake/death")
    eater:DoTaskInTime(0.5, function() 
        doareasleep(eater, TUNING.MANDRAKE_SLEEP_RANGE, TUNING.MANDRAKE_SLEEP_TIME)
    end)
end

local function oncooked(inst, cooker, chef)
	chef.SoundEmitter:PlaySound("dontstarve/creatures/mandrake/death")
	chef:DoTaskInTime(0.5, function()
        doareasleep(chef, TUNING.MANDRAKE_SLEEP_RANGE_COOKED, TUNING.MANDRAKE_SLEEP_TIME)
	end)
end

local function oneaten_cooked(inst, eater)
	eater.SoundEmitter:PlaySound("dontstarve/creatures/mandrake/death")
	eater:DoTaskInTime(0.5, function() 
        doareasleep(eater, TUNING.MANDRAKE_SLEEP_RANGE_COOKED, TUNING.MANDRAKE_SLEEP_TIME)
	end)
end

local function commonfn()
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("mandrake")
    inst.AnimState:SetBuild("mandrake")
    inst.AnimState:PlayAnimation("object")


	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")

    inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.VEGGIE

	return inst
end

local function rawfn()
	local inst = commonfn()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
    	return inst
    end

    inst.components.edible.healthvalue = TUNING.HEALING_HUGE
    inst.components.edible.hungervalue = TUNING.CALORIES_HUGE
    inst.components.edible:SetOnEatenFn(oneaten_raw)

    inst.components.inventoryitem:SetOnPickupFn(onpickup)

    inst:AddComponent("cookable")
    inst.components.cookable.product = "cookedmandrake"
    inst.components.cookable:SetOnCookedFn(oncooked)

	return inst
end

local function cookedfn()
	local inst = commonfn()

    inst.AnimState:PlayAnimation("cooked")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
    	return inst
    end

    inst.components.edible.healthvalue = TUNING.HEALING_SUPERHUGE
    inst.components.edible.hungervalue = TUNING.CALORIES_SUPERHUGE
    inst.components.edible:SetOnEatenFn(oneaten_cooked)

    return inst
end

return Prefab("common/mandrake", rawfn, assets),
Prefab("common/cookedmandrake", cookedfn, assets)