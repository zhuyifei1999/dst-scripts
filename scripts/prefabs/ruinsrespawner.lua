local function onnewobjectfn(inst, obj)
    inst:ListenForEvent("onremove", function(obj)
        RemoveByValue(inst.components.objectspawner.objects, obj)
    end, obj)
end

local function tryspawn(inst)
    if inst.resetruins and #inst.components.objectspawner.objects <= 0 then
        local x, y, z = inst.Transform:GetWorldPosition()
        for i, v in ipairs(TheSim:FindEntities(x, y, z, 1, nil, { "INLIMBO" })) do
            if v.components.workable ~= nil and v.components.workable:GetWorkAction() ~= ACTIONS.NET then
                v.components.workable:Destroy(v)
            end
        end

        inst.components.objectspawner:SpawnObject(inst.spawnprefab).Transform:SetPosition(x, y, z)
    end

    inst.resetruins = nil
end

local function onsave(inst, data)
    data.resetruins = inst.resetruins
end

local function onload(inst, data)
    if data ~= nil then
        inst.resetruins = data.resetruins
    end
end

local function MakeRuinsRespawner(obj)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        --[[Non-networked entity]]

        inst:AddTag("CLASSIFIED")

        inst.spawnprefab = obj
        inst.resetruins = true

        inst:AddComponent("objectspawner")
        inst.components.objectspawner.onnewobjectfn = onnewobjectfn

        inst:ListenForEvent("resetruins", function()
            inst.resetruins = true
            tryspawn(inst)
        end, TheWorld)

        inst:DoTaskInTime(0, tryspawn)

        inst.OnSave = onsave
        inst.OnLoad = onload

        return inst
    end

    return Prefab(obj.."_spawner", fn, nil, { obj })
end

return MakeRuinsRespawner
