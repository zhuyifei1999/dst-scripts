local prefabs =
{
    "antlion",
}

local function OnTimerDone(inst, data)
    if data.name == "spawndelay" then
        inst:RemoveEventCallback("timerdone", OnTimerDone)
        local antlion = SpawnPrefab("antlion")
        antlion.Transform:SetPosition(inst.Transform:GetWorldPosition())
        antlion.sg:GoToState("enterworld")
    end
end

local function OnSandstormChanged(inst, active)
    if active then
        if not inst.spawned then
            inst.spawned = true
            inst:ListenForEvent("timerdone", OnTimerDone)
            inst.components.timer:StopTimer("spawndelay")
            inst.components.timer:StartTimer("spawndelay", GetRandomMinMax(10, 20))
        end
    elseif inst.spawned then
        inst.spawned = nil
        inst:RemoveEventCallback("timerdone", OnTimerDone)
        inst.components.timer:StopTimer("spawndelay")
    end
end

local function OnInit(inst)
    inst:ListenForEvent("ms_sandstormchanged", function(src, data) OnSandstormChanged(inst, data) end, TheWorld)
    OnSandstormChanged(inst, TheWorld.components.sandstorms ~= nil and TheWorld.components.sandstorms:IsSandstormActive())
end

local function OnSave(inst, data)
    data.spawned = inst.spawned or nil
end

local function OnLoad(inst, data)
    if data ~= nil and data.spawned then
        if not inst.spawned then
            inst.spawned = true
            if inst.components.timer:TimerExists("spawndelay") then
                inst:ListenForEvent("timerdone", OnTimerDone)
            end
        end
    else
        if inst.spawned then
            inst.spawned = nil
            inst:RemoveEventCallback("timerdone", OnTimerDone)
        end
        inst.components.timer:StopTimer("spawndelay")
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    --[[Non-networked entity]]

    inst:AddTag("CLASSIFIED")

    inst:AddComponent("timer")

    inst:DoTaskInTime(0, OnInit)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("antlion_spawner", fn, nil, prefabs)
