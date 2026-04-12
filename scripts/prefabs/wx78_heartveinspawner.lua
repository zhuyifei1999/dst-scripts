local prefabs = {
    "shadow_heart_vein",
}

local POSITION_CANT_TAGS = { "INLIMBO", "NOBLOCK", "FX" }
local IS_CLEAR_AREA_RADIUS = 2

local function IsValidPosition(pos)
    local x, y, z = pos:Get()

    return TheSim:CountEntities(x, 0, z, IS_CLEAR_AREA_RADIUS, nil, POSITION_CANT_TAGS) <= 0 and TheWorld.Map:IsSurroundedByLand(x, 0, z, 1)
end

local function GetSpawnPoint(inst)
    local pos = inst:GetPosition()
    for attempt = 1, 3 do
        local radius = GetRandomMinMax(2, TUNING.SKILLS.WX78.SHADOWHEART_SPAWN_DENSITY_RANGE)

        local offset = FindWalkableOffset(pos, math.random() * TWOPI, radius, 16, nil, nil, IsValidPosition)

        if offset ~= nil then
            return pos + offset
        end
    end
    return nil
end

local VEINS_MUST_TAGS = {"shadow_heart_vein"}

local function OnRemoved(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TUNING.SKILLS.WX78.SHADOWHEART_SPAWN_DENSITY_RANGE, VEINS_MUST_TAGS)
    for _, ent in ipairs(ents) do
        if ent:IsValid() then
            ent:ScheduleForDelete()
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
    periodicspawner:SetPrefab("shadow_heart_vein")
    periodicspawner:SetRandomTimes(TUNING.SKILLS.WX78.SHADOWHEART_SPAWN_PERIOD, TUNING.SKILLS.WX78.SHADOWHEART_SPAWN_VARIANCE)
    periodicspawner:SetDensityInRange(TUNING.SKILLS.WX78.SHADOWHEART_SPAWN_DENSITY_RANGE, TUNING.SKILLS.WX78.SHADOWHEART_SPAWN_DENSITY_MAX)
    periodicspawner:SetGetSpawnPointFn(GetSpawnPoint)
    periodicspawner:Start()

    inst.persists = false

    inst.OnRemoveEntity = OnRemoved

    return inst
end

return Prefab("wx78_heartveinspawner", fn, nil, prefabs)