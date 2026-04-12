local prefabs = {
    "itemmimic_revealed",
}

local function MimicDensityFilter(inst, ent)
    return ent.components.itemmimic ~= nil
end

local function MimicSpawn(inst, ent)
    ent:SetNoLoot(true)
    if ent.components.knownlocations then
        ent.components.knownlocations:RememberLocation("leash", inst:GetPosition())
    end
    ent:PushEvent("jump")
end

local MIMIC_MUST_TAGS = {"itemmimic_revealed"}

local function OnRemoved(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TUNING.SKILLS.WX78.MIMICHEART_SPAWN_DENSITY_RANGE, MIMIC_MUST_TAGS)
    for _, ent in ipairs(ents) do
        if ent:IsValid() and ent:GetNoLoot() then
            ent.components.health:Kill()
        end
    end
end

local function fn()
	local inst = CreateEntity()

    if not TheWorld.ismastersim then
        --Not meant for client!
        inst:DoTaskInTime(0, inst.Remove)

        return inst
    end

    inst.entity:AddTransform()
    --[[Non-networked entity]]

    inst.entity:Hide()
    inst:AddTag("CLASSIFIED")

    local periodicspawner = inst:AddComponent("periodicspawner")
    periodicspawner:SetPrefab("itemmimic_revealed")
    periodicspawner:SetRandomTimes(TUNING.SKILLS.WX78.MIMICHEART_SPAWN_PERIOD, TUNING.SKILLS.WX78.MIMICHEART_SPAWN_VARIANCE)
    periodicspawner:SetDensityInRange(TUNING.SKILLS.WX78.MIMICHEART_SPAWN_DENSITY_RANGE, TUNING.SKILLS.WX78.MIMICHEART_SPAWN_DENSITY_MAX)
    periodicspawner:SetDensityFilterFn(MimicDensityFilter)
    periodicspawner:SetOnSpawnFn(MimicSpawn)
    periodicspawner:Start()

    inst.persists = false

    inst.OnRemoveEntity = OnRemoved

    return inst
end

return Prefab("wx78_mimicspawner", fn, nil, prefabs)