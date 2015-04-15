local assets =
{
	Asset("ANIM", "anim/rabbit_hole.zip"),
}

local prefabs =
{
	"rabbit",
}

local function dig_up(inst, chopper)
	if inst.components.spawner:IsOccupied() then
		inst.components.lootdropper:SpawnLootPrefab("rabbit")
	end
	inst:Remove()
end

local function startspawning(inst)
    if inst.components.spawner then
        inst.components.spawner:SpawnWithDelay(60 + math.random(120))
    end
end

local function resumespawning(inst)
    if inst.components.spawner then
        inst.components.spawner:SetQueueSpawning(false)
    end
end

local function stopspawning(inst)
    if inst.components.spawner then
        inst.components.spawner:SetQueueSpawning(true, 60+math.random(60))
    end
end

local function onoccupied(inst)
    if TheWorld.state.isday then
        resumespawning(inst) --make sure we're not queueing
        startspawning(inst)
    end
end

local function GetChild(inst)
	return "rabbit"
end

local function OnIsDay(inst, isday)
    if isday then
        if inst.components.spawner:IsOccupied() then
            resumespawning(inst) --make sure we're not queueing
            startspawning(inst)
        else
            resumespawning(inst)
        end
    else
        stopspawning(inst)
    end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:SetBank("rabbithole")
    inst.AnimState:SetBuild("rabbit_hole")
    inst.AnimState:PlayAnimation("anim")
	--inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)

	inst:AddComponent("spawner")
	inst.components.spawner:Configure("rabbit", TUNING.RABBIT_RESPAWN_TIME)
	inst.components.spawner.childfn = GetChild
	
	inst.components.spawner:SetOnOccupiedFn(onoccupied)
	inst.components.spawner:SetOnVacateFn(stopspawning)
    
	inst:AddComponent("lootdropper")
	inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(dig_up)
    inst.components.workable:SetWorkLeft(1)
    
    inst:WatchWorldState("isday", OnIsDay)
	
    inst:AddComponent("inspectable")

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        return inst.components.spawner:ReleaseChild()
    end)
	
    return inst
end

return Prefab("common/objects/rabbithole", fn, assets, prefabs)