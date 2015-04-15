local assets =
{
	Asset("ANIM", "anim/fireflies.zip"),
}

local INTENSITY = .5

local function fadein(inst)
    inst.components.fader:StopAll()
    inst.AnimState:PlayAnimation("swarm_pre")
    inst.AnimState:PushAnimation("swarm_loop", true)
    inst.Light:Enable(true)
    inst.Light:SetIntensity(0)
    inst.components.fader:Fade(0, INTENSITY, 3+math.random()*2, function(v) inst.Light:SetIntensity(v) end, function() inst:RemoveTag("NOCLICK") end)
end

local function fadeout(inst)
    inst.components.fader:StopAll()
    inst.AnimState:PlayAnimation("swarm_pst")
    inst.components.fader:Fade(INTENSITY, 0, .75+math.random()*1, function(v) inst.Light:SetIntensity(v) end, function() inst:AddTag("NOCLICK") inst.Light:Enable(false) end)
end

local function updatelight(inst)
    if TheWorld.state.isnight and not inst.components.playerprox:IsPlayerClose() and not inst.components.inventoryitem.owner then
        if not inst.lighton then
            fadein(inst)
        end
        inst.lighton = true
    else
        inst:AddTag("NOCLICK")
        if inst.lighton then
            fadeout(inst)
        end
        inst.lighton = false
    end
end

local function ondropped(inst)
    inst.components.workable:SetWorkLeft(1)
    fadein(inst)
    inst.lighton = true
    inst:DoTaskInTime(2 + math.random(), updatelight)
end

local function onworked(inst, worker)
    if worker.components.inventory ~= nil then
        worker.components.inventory:GiveItem(inst, nil, inst:GetPosition())
        fadeout(inst)
    end
end

local function getstatus(inst)
    if inst.components.inventoryitem.owner then
        return "HELD"
    end
end

local function OnIsNight(inst)
    inst:DoTaskInTime(2 + math.random(), updatelight)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddPhysics()
    inst.entity:AddLight()
    inst.entity:AddNetwork()
 
    inst:AddTag("NOBLOCK")

    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(INTENSITY)
    inst.Light:SetRadius(1)
    inst.Light:SetColour(180/255, 195/255, 150/255)
    inst.Light:Enable(false)
    
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    
    inst.AnimState:SetBank("fireflies")
    inst.AnimState:SetBuild("fireflies")

    inst.AnimState:SetRayTestOnBB(true)
    
    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst:AddComponent("playerprox")

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus
    
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.NET)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(onworked)

    inst:AddComponent("fader")
    
    inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
    inst.components.stackable.forcedropsingle = true

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(ondropped)
    inst.components.inventoryitem.canbepickedup = false

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL
    inst.components.fuel.fueltype = FUELTYPE.CAVE

    inst.components.playerprox:SetDist(3,5)
    inst.components.playerprox:SetOnPlayerNear(updatelight)
    inst.components.playerprox:SetOnPlayerFar(updatelight)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:WatchWorldState("isnight", OnIsNight)

    updatelight(inst)
    
    return inst
end

return Prefab("common/objects/fireflies", fn, assets)