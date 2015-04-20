require "prefabutil"
require "recipes"

local assets =
{
    Asset("ANIM", "anim/rabbit_house.zip"),
}

local prefabs =
{
    "bunnyman",
}

local function getstatus(inst)
    if inst:HasTag("burnt") then 
        return "BURNT"
    elseif inst.components.spawner and inst.components.spawner:IsOccupied() then
        if inst.lightson then
            return "FULL"
        end
    end
end

local function onoccupied(inst, child)
    --inst.SoundEmitter:PlaySound("dontstarve/pig/pig_in_hut", "pigsound")
    --inst.SoundEmitter:PlaySound("dontstarve/common/pighouse_door")
end

local function onvacate(inst, child)
    --inst.SoundEmitter:PlaySound("dontstarve/common/pighouse_door")
    --inst.SoundEmitter:KillSound("pigsound")
    
    if not inst:HasTag("burnt") then 
        if child then
            if child.components.health then
                child.components.health:SetPercent(1)
            end
        end
    end
end

local function onhammered(inst, worker)

    if inst:HasTag("fire") and inst.components.burnable then 
        inst.components.burnable:Extinguish()
    end
    if inst.components.spawner then inst.components.spawner:ReleaseChild() end
    inst.components.lootdropper:DropLoot()
    SpawnPrefab("collapse_big").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then 
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle")
    end
end

local function OnStopDay(inst)
    --print(inst, "OnStopDay")
    if not inst:HasTag("burnt") then 
        if inst.components.spawner:IsOccupied() then
            if inst.doortask then
                inst.doortask:Cancel()
                inst.doortask = nil
            end
            inst.doortask = inst:DoTaskInTime(1 + math.random() * 2, function() inst.components.spawner:ReleaseChild() end)
        end
    end
end

local function SpawnCheckDay(inst)
    --print(inst, "spawn check day")
    if not TheWorld.state.isday then
        OnStopDay(inst)
    end
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or inst:HasTag("fire") then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle")
end

local function onburntup(inst)
    if inst.doortask then
        inst.doortask:Cancel()
        inst.doortask = nil
    end
end

local function onignite(inst)
    if inst.components.spawner then
        inst.components.spawner:ReleaseChild()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.MiniMapEntity:SetIcon("rabbit_house.png")
--{anim="level1", sound="dontstarve/common/campfire", radius=2, intensity=.75, falloff=.33, colour = {197/255,197/255,170/255}},
    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(1)
    inst.Light:Enable(false)
    inst.Light:SetColour(180/255, 195/255, 50/255)

    inst.AnimState:SetBank("rabbithouse")
    inst.AnimState:SetBuild("rabbit_house")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("structure")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("spawner")
    inst.components.spawner:Configure("bunnyman", TUNING.TOTAL_DAY_TIME)
    inst.components.spawner.onoccupied = onoccupied
    inst.components.spawner.onvacate = onvacate

    inst:WatchWorldState("stopday", OnStopDay)

    inst:AddComponent("inspectable")

    inst.components.inspectable.getstatus = getstatus

    MakeSnowCovered(inst)

    MakeMediumBurnable(inst, nil, nil, true)
    MakeLargePropagator(inst)
    inst:ListenForEvent("burntup", onburntup)
    inst:ListenForEvent("onignite", onignite)

    inst.OnSave = onsave 
    inst.OnLoad = onload

    inst:ListenForEvent("onbuilt", onbuilt)
    inst:DoTaskInTime(math.random(), SpawnCheckDay)

    MakeHauntableWork(inst)

    return inst
end

return Prefab("common/objects/rabbithouse", fn, assets, prefabs),
    MakePlacer("common/rabbithouse_placer", "rabbithouse", "rabbit_house", "idle")