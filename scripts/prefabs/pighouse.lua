require "prefabutil"
require "recipes"

local assets =
{
    Asset("ANIM", "anim/pig_house.zip"),
    Asset("SOUND", "sound/pig.fsb"),
}

local prefabs =
{
    "pigman",
}

local function LightsOn(inst)
    if not inst:HasTag("burnt") then 
        inst.Light:Enable(true)
        inst.AnimState:PlayAnimation("lit", true)
        inst.SoundEmitter:PlaySound("dontstarve/pig/pighut_lighton")
        inst.lightson = true
    end
end

local function LightsOff(inst)
    if not inst:HasTag("burnt") then 
        inst.Light:Enable(false)
        inst.AnimState:PlayAnimation("idle", true)
        inst.SoundEmitter:PlaySound("dontstarve/pig/pighut_lightoff")
        inst.lightson = false
    end
end

local function onfar(inst)
    if not inst:HasTag("burnt") then 
        if inst.components.spawner:IsOccupied() then
            LightsOn(inst)
        end
    end
end

local function getstatus(inst)
    if inst:HasTag("burnt") then 
        return "BURNT"
    elseif inst.components.spawner and inst.components.spawner:IsOccupied() then
        if inst.lightson then
            return "FULL"
        else
            return "LIGHTSOUT"
        end
    end
end

local function onnear(inst)
    if not inst:HasTag("burnt") then 
        if inst.components.spawner:IsOccupied() then
            LightsOff(inst)
        end
    end
end

local function onwere(child)
    if child.parent and not child.parent:HasTag("burnt") then
        child.parent.SoundEmitter:KillSound("pigsound")
        child.parent.SoundEmitter:PlaySound("dontstarve/pig/werepig_in_hut", "pigsound")
    end
end

local function onnormal(child)
    if child.parent and not child.parent:HasTag("burnt") then
        child.parent.SoundEmitter:KillSound("pigsound")
        child.parent.SoundEmitter:PlaySound("dontstarve/pig/pig_in_hut", "pigsound")
    end
end

local function onoccupieddoortask(inst)
    if not inst.components.playerprox:IsPlayerClose() then
        LightsOn(inst)
    end
end

local function onoccupied(inst, child)
    if not inst:HasTag("burnt") then 
        inst.SoundEmitter:PlaySound("dontstarve/pig/pig_in_hut", "pigsound")
        inst.SoundEmitter:PlaySound("dontstarve/common/pighouse_door")
        
        if inst.doortask then
            inst.doortask:Cancel()
            inst.doortask = nil
        end
        inst.doortask = inst:DoTaskInTime(1, onoccupieddoortask)
        if child ~= nil then
            inst:ListenForEvent("transformwere", onwere, child)
            inst:ListenForEvent("transformnormal", onnormal, child)
        end
    end
end

local function onvacate(inst, child)
    if not inst:HasTag("burnt") then 
        if inst.doortask then
            inst.doortask:Cancel()
            inst.doortask = nil
        end
        inst.SoundEmitter:PlaySound("dontstarve/common/pighouse_door")
        inst.SoundEmitter:KillSound("pigsound")
        
        if child then
            inst:RemoveEventCallback("transformwere", onwere, child)
            inst:RemoveEventCallback("transformnormal", onnormal, child)
            if child.components.werebeast then
                child.components.werebeast:ResetTriggers()
            end
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
    if inst.doortask then
        inst.doortask:Cancel()
        inst.doortask = nil
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

local function onstartdaydoortask(inst)
    inst.components.spawner:ReleaseChild()
end

local function OnStartDay(inst)
    --print(inst, "OnStartDay")
    if not inst:HasTag("burnt") then 
        if inst.components.spawner:IsOccupied() then
            LightsOff(inst)
            if inst.doortask then
                inst.doortask:Cancel()
                inst.doortask = nil
            end
            inst.doortask = inst:DoTaskInTime(1 + math.random() * 2, onstartdaydoortask)
        end
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

local function spawncheckday(inst)
    --print(inst, "spawn check day")
    if TheWorld.state.isday then
        OnStartDay(inst)
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

    inst.MiniMapEntity:SetIcon("pighouse.png")
--{anim="level1", sound="dontstarve/common/campfire", radius=2, intensity=.75, falloff=.33, colour = {197/255,197/255,170/255}},
    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(1)
    inst.Light:Enable(false)
    inst.Light:SetColour(180/255, 195/255, 50/255)

    inst.AnimState:SetBank("pig_house")
    inst.AnimState:SetBuild("pig_house")
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
    inst.components.spawner:Configure("pigman", TUNING.TOTAL_DAY_TIME*4)
    inst.components.spawner.onoccupied = onoccupied
    inst.components.spawner.onvacate = onvacate

    inst:WatchWorldState("startday", OnStartDay)

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(10,13)
    inst.components.playerprox:SetOnPlayerNear(onnear)
    inst.components.playerprox:SetOnPlayerFar(onfar)

    inst:AddComponent("inspectable")

    inst.components.inspectable.getstatus = getstatus

    MakeSnowCovered(inst)

    MakeMediumBurnable(inst, nil, nil, true)
    MakeLargePropagator(inst)
    inst:ListenForEvent("burntup", onburntup)
    inst:ListenForEvent("onignite", onignite)

    inst.OnSave = onsave 
    inst.OnLoad = onload

    MakeHauntableWork(inst)

    inst:ListenForEvent("onbuilt", onbuilt)
    inst:DoTaskInTime(math.random(), spawncheckday)

    return inst
end

return Prefab("common/objects/pighouse", fn, assets, prefabs),
    MakePlacer("common/pighouse_placer", "pig_house", "pig_house", "idle")