local assets = {}

local prefabs =
{
	"tumbleweed",
}

local function OnSpawn(inst, child)
	if child then
		child.owner = inst
	end
end

local function OnEntitySleep(inst)

end

local function OnEntityWake(inst)

end

local function fn()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()

    -- Non-networked?

	inst.OnEntityWake = OnEntityWake
	inst.OnEntitySleep = OnEntitySleep

	inst:AddComponent( "childspawner" )
	inst.components.childspawner.childname = "tumbleweed"
	inst.components.childspawner:SetSpawnedFn(OnSpawn)
	inst.components.childspawner:SetMaxChildren(math.random(TUNING.MIN_TUMBLEWEEDS_PER_SPAWNER,TUNING.MAX_TUMBLEWEEDS_PER_SPAWNER))
	inst.components.childspawner:SetSpawnPeriod(math.random(TUNING.MIN_TUMBLEWEED_SPAWN_PERIOD, TUNING.MAX_TUMBLEWEED_SPAWN_PERIOD))
	inst.components.childspawner:SetRegenPeriod(TUNING.TUMBLEWEED_REGEN_PERIOD)
	inst.components.childspawner.spawnoffscreen = true
	inst:DoTaskInTime(0, function(inst)
		inst.components.childspawner:ReleaseAllChildren() 
		inst.components.childspawner:StartSpawning()
	end)

	inst:ListenForEvent("windchange", function(it, data)
		if data and data.angle then inst.angle = data.angle end
	end, TheWorld)

	return inst
end

return Prefab( "tumbleweedspawner", fn, assets, prefabs)
