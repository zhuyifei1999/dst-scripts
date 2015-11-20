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
    local x, y, z = child.Transform:GetWorldPosition()
    child.Transform:SetPosition(x, 20, z)
    child.sg:GoToState("land")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    --[[Non-networked entity]]

    inst:AddTag("CLASSIFIED")

    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "dragonfly"
    inst.components.childspawner:SetMaxChildren(1)
    inst.components.childspawner:SetSpawnPeriod(TUNING.DRAGONFLY_SPAWN_TIME, 0)
    inst.components.childspawner.onchildkilledfn = OnKilled
    inst.components.childspawner:StartSpawning()
    inst.components.childspawner:StopRegen()
    inst.components.childspawner:SetSpawnedFn(onspawned)

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", ontimerdone)

    return inst
end

return Prefab("dragonfly_spawner", fn, nil, prefabs)
