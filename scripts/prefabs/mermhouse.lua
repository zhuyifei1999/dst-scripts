local assets =
{
	Asset("ANIM", "anim/pig_house.zip"),
}

local prefabs =
{
	"merm",
	"collapse_big",
}

local loot =
{
    "boards",
    "rocks",
    "fish",
}

local function onhammered(inst, worker)
    inst:RemoveComponent("childspawner")
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_big").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
	inst:Remove()
end

local function onhit(inst, worker)
    if inst.components.childspawner then
        inst.components.childspawner:ReleaseAllChildren(worker)
    end
	inst.AnimState:PlayAnimation("hit_rundown")
	inst.AnimState:PushAnimation("rundown")
end

local function StartSpawning(inst)
	if inst.components.childspawner and not TheWorld.state.iswinter then
		inst.components.childspawner:StartSpawning()
	end
end

local function StopSpawning(inst)
	if inst.components.childspawner then
		inst.components.childspawner:StopSpawning()
	end
end

local function OnSpawned(inst, child)
	inst.SoundEmitter:PlaySound("dontstarve/common/pighouse_door")
	if TheWorld.state.isday and inst.components.childspawner and inst.components.childspawner:CountChildrenOutside() >= 1 and not child.components.combat.target then
        StopSpawning(inst)
    end
end

local function OnGoHome(inst, child) 
	inst.SoundEmitter:PlaySound("dontstarve/common/pighouse_door")
	if inst.components.childspawner and inst.components.childspawner:CountChildrenOutside() < 1 then
        StartSpawning(inst)
    end
end

local function OnIsDay(inst, isday)
    if isday then
        StopSpawning(inst)
    else
        if not TheWorld.state.iswinter then
            inst.components.childspawner:ReleaseAllChildren()
        end
        StartSpawning(inst)
    end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.MiniMapEntity:SetIcon("mermhouse.png")

    inst.AnimState:SetBank("pig_house")
    inst.AnimState:SetBuild("pig_house")
    inst.AnimState:PlayAnimation("rundown")

    inst:AddTag("structure")

    MakeSnowCoveredPristine(inst)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot)
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(2)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)
	
	inst:AddComponent("childspawner")
	inst.components.childspawner.childname = "merm"
	inst.components.childspawner:SetSpawnedFn(OnSpawned)
	inst.components.childspawner:SetGoHomeFn(OnGoHome)
	inst.components.childspawner:SetRegenPeriod(TUNING.TOTAL_DAY_TIME*4)
	inst.components.childspawner:SetSpawnPeriod(10)
	inst.components.childspawner:SetMaxChildren(TUNING.MERMHOUSE_MERMS)

    inst.components.childspawner.emergencychildname = "merm"
    inst.components.childspawner:SetEmergencyRadius(TUNING.MERMHOUSE_EMERGENCY_RADIUS)
    inst.components.childspawner:SetMaxEmergencyChildren(TUNING.MERMHOUSE_EMERGENCY_MERMS)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        if not inst.components.childspawner or not inst.components.childspawner:CanSpawn() then 
            return false 
        end

        local target = FindEntity(inst, 25, nil,
        {"character"},
        {"merm","playerghost"}
        )

        if target and math.random() <= TUNING.HAUNT_CHANCE_HALF then
            onhit(inst, target)
            return true
        end

        return false
    end)

    inst:WatchWorldState("isday", OnIsDay)

	StartSpawning(inst)

    inst:AddComponent("inspectable")
	
	MakeSnowCovered(inst)
    return inst
end

return Prefab("common/objects/mermhouse", fn, assets, prefabs)