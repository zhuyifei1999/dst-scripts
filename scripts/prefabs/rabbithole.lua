local assets =
{
	Asset("ANIM", "anim/rabbit_hole.zip"),
}

local prefabs =
{
	"rabbit",
	"smallmeat",
}

local function dig_up(inst, chopper)
	if inst.components.spawner:IsOccupied() then
		inst.components.lootdropper:SpawnLootPrefab("rabbit")
	end
	inst:Remove()
end

local function startspawning(inst)
    if inst.components.spawner and not inst.spring then
    	if not inst.components.spawner:IsSpawnPending() then
    		inst.components.spawner:SpawnWithDelay(60 + math.random(120) )
    	end
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
    if inst.spring then
    	inst.AnimState:PlayAnimation("idle_flooded")
    	inst.wet_prefix = STRINGS.WET_PREFIX.RABBITHOLE
    	inst.always_wet = true
    end
end

local function GetChild(inst)
	return "rabbit"
end

local function SetSpringMode(inst, force)
	if not inst.spring or force then
		stopspawning(inst)
		inst.springtask = nil
		inst.spring = true
		if inst.components.spawner:IsOccupied() then
			inst.AnimState:PlayAnimation("idle_flooded")
			inst.wet_prefix = STRINGS.WET_PREFIX.RABBITHOLE
			inst.always_wet = true
		end
	end
end

local function SetNormalMode(inst, force)
	if inst.spring or force then
		inst.AnimState:PlayAnimation("idle")
		if TheWorld.state.isday and inst.components.spawner and not inst.components.spawner:IsSpawnPending() then
	        startspawning(inst)
	    end
	    inst.normaltask = nil
	    inst.spring = false
	   	inst.wet_prefix = STRINGS.WET_PREFIX.GENERIC
	   	inst.always_wet = false
	end
end

local function OnWake(inst)
	if inst.spring and inst.components.spawner and inst.components.spawner:IsOccupied() then
		if inst.components.spawner:IsSpawnPending() then
			stopspawning(inst)
		end
		inst.AnimState:PlayAnimation("idle_flooded")
		inst.wet_prefix = STRINGS.WET_PREFIX.RABBITHOLE
		inst.always_wet = true
		if inst.springtask then
			inst.springtask:Cancel()
			inst.springtask = nil
		end
	end
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

local function OnRaining(inst)
	if TheWorld.state.isspring and not inst.spring then
		inst.springtask = inst:DoTaskInTime(math.random(3,20), SetSpringMode)
	end
end

local function OnIsSpring(inst, data)
	if data == false and inst.spring then
		inst.normaltask = inst:DoTaskInTime(math.random(TUNING.MIN_RABBIT_HOLE_TRANSITION_TIME, TUNING.MAX_RABBIT_HOLE_TRANSITION_TIME), SetNormalMode)
	end
end

local function GetStatus(inst)
	if inst.spring then
		return "SPRING"
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

	inst:AddTag("cattoy")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:SetBank("rabbithole")
    inst.AnimState:SetBuild("rabbit_hole")
    inst.AnimState:PlayAnimation("idle")
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
    inst:WatchWorldState("startrain", OnRaining)
    inst:WatchWorldState("isspring", OnIsSpring)
	inst:DoTaskInTime(.1, function(inst) 
		if TheWorld.state.isspring then
			SetSpringMode(inst, true)
	    else
	    	SetNormalMode(inst, true)
	    end
	end)
	
    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        return not inst.spring and inst.components.spawner:ReleaseChild()
    end)
	
    return inst
end

return Prefab("common/objects/rabbithole", fn, assets, prefabs)