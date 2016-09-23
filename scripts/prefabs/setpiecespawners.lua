-- SET PIECE SPAWNER
-- used in set pieces where we want to control the spawning of prefab varriants 

local function makespawner(prefabname)
    local prefabs =
    {
        prefabname,
    }

    local function OnSpawn(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        if #TheSim:FindEntities(x, y, z, .5, nil, { "INLIMBO" }) > 0 then
            --Something occupying this space already
            return
        end

        local newinst = SpawnPrefab(prefabname)
        if newinst ~= nil then
            newinst.Transform:SetPosition(inst.Transform:GetWorldPosition())
            if newinst.components.diseaseable ~= nil then
                newinst.components.diseaseable:OnRebirth()
            end
        end
    end

    local function OnLoadPostPass(inst, newents, data)
        local firstload = data == nil or data.timeToSpawn == nil
        if firstload and        
            not (TheWorld.components.prefabswapmanager ~= nil and
                TheWorld.components.prefabswapmanager:IsDiseasedPrefab(prefabname)) then

            local newinst = SpawnPrefab(prefabname)
            if newinst ~= nil then
                newinst.Transform:SetPosition(inst.Transform:GetWorldPosition())
                if data ~= nil then
                    --This data is defined by worldgen setpieces
                    --originally intended for the target prefabs
                    newinst:SetPersistData(data)
                end
            end
        end
    end

    local function OnLoad(inst, data, newents)
        if data ~= nil and data.timeToSpawn ~= nil and data.timeToSpawn >= 0 then
            if inst.task ~= nil then
                inst.task:Cancel()
            end
            inst.task = inst:DoTaskInTime(math.max(0, data.timeToSpawn), OnSpawn)
        end
    end

    local function OnSave(inst, data)
        data.timeToSpawn = inst.task ~= nil and math.max(0, GetTaskRemaining(inst.task)) or -1
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        --[[Non-networked entity]]

        inst:AddTag("CLASSIFIED")

        inst.task = nil

        inst:ListenForEvent("ms_spawnsetpiece"..prefabname, function(world, data)
            if inst.task ~= nil then
                inst.task:Cancel()
                inst.task = nil
            end
            if data ~= nil and data.delay ~= nil then
                inst.task = inst:DoTaskInTime(data.delay + math.random() * (data.delayvariance or 0), OnSpawn)
            else
                OnSpawn(inst, data)
            end
        end, TheWorld)

        inst.OnLoadPostPass = OnLoadPostPass
        inst.OnLoad = OnLoad
        inst.OnSave = OnSave

        return inst
    end

    return Prefab("sps_"..prefabname, fn, nil, prefabs)
end

return makespawner("berrybush"),
    makespawner("berrybush_juicy")
