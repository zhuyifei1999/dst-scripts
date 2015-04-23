local prefabs =
{
	"dragonfly",
}

local function OnKilled(inst)
	inst.components.timer:StartTimer("regen_dragonfly", TUNING.DRAGONFLY_RESPAWN_TIME)
end

local function GenerateNewDragon(inst)
	inst.components.childspawner:AddChildrenInside(1)
	inst.components.childspawner:StartSpawning()
end

local function ontimerdone(inst, data)
    if data.name == "regen_dragonfly" then
        GenerateNewDragon(inst)
    end
end

local function onspawned(inst, child)
    local pos = child:GetPosition()
    pos.y = 20
    child.Transform:SetPosition(pos:Get())
    child.sg:GoToState("land")
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("childspawner")
    inst:AddComponent("timer")

    inst.components.childspawner.childname = "dragonfly"
    inst.components.childspawner:SetMaxChildren(1)
    inst.components.childspawner:SetSpawnPeriod(TUNING.DRAGONFLY_SPAWN_TIME, 0)
    inst.components.childspawner.onchildkilledfn = OnKilled
    inst.components.childspawner:StartSpawning()
    inst.components.childspawner:StopRegen()
    inst.components.childspawner:SetSpawnedFn(onspawned)

    inst:ListenForEvent("timerdone", ontimerdone)

	return inst
end

return Prefab("dragonfly_spawner", fn, nil, prefabs)