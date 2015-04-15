local assets =
{
    Asset("ANIM", "anim/spider_mound.zip")
}

local prefabs =
{
    "spider_hider",
    "spider_spitter",
}

SetSharedLootTable( 'spider_hole',
{
    {'rocks',       1.00},
    {'rocks',       1.00},
    {'silk',        1.00},
    {'spidergland', 0.25},
    {'silk',        0.50},
})

local function ReturnChildren(inst)
    if inst.components.childspawner then
        for k,child in pairs(inst.components.childspawner.childrenoutside) do
            if child.components.homeseeker then
                child.components.homeseeker:GoHome()
            end
            child:PushEvent("gohome")
        end
    end
end

local function workcallback(inst, worker, workleft)
    if workleft <= 0 then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
        inst.components.lootdropper:DropLoot(Point(inst.Transform:GetWorldPosition()))
        inst:Remove()
    elseif workleft <= TUNING.SPILAGMITE_ROCK * 0.5 then
        inst.AnimState:PlayAnimation("low")
    else
        inst.AnimState:PlayAnimation("med")
    end
end

local function GoToBrokenState(inst)
    inst.broken = true
    
    inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")

    inst.AnimState:PushAnimation("med")
    inst:RemoveTag("spiderden")

    if inst.components.childspawner then 
        inst.components.childspawner:StopSpawning()
        inst:RemoveComponent("childspawner") 
    end

    if inst.creep then
        inst.creep:SetRadius(0)
    end

    inst.components.workable:SetOnWorkCallback(workcallback)
    inst.components.workable:SetWorkLeft(TUNING.SPILAGMITE_ROCK)
end

local function IsInvestigator(child)
    return child.components.knownlocations:GetLocation("investigate") ~= nil
end

local function SpawnInvestigators(inst, data)
    if not inst.components.health:IsDead() then
        if inst.components.childspawner then
            local num_to_release = math.min(2, inst.components.childspawner.childreninside)
            local num_investigators = inst.components.childspawner:CountChildrenOutside(IsInvestigator)
            num_to_release = num_to_release - num_investigators
            local targetpos = data ~= nil and data.target ~= nil and Vector3(data.target.Transform:GetWorldPosition()) or nil
            for k = 1, num_to_release do
                local spider = inst.components.childspawner:SpawnChild()
                if spider ~= nil and targetpos ~= nil then
                    spider.components.knownlocations:RememberLocation("investigate", targetpos)
                end
            end
        end
    end
end

local function MakeSpiderSpawner(inst)
    inst:AddComponent("childspawner")
    inst.components.childspawner:SetRegenPeriod(120)
    inst.components.childspawner:SetSpawnPeriod(240)
    inst.components.childspawner:SetMaxChildren(math.random(2, 3))
    inst.components.childspawner:StartRegen()
    inst.components.childspawner.childname = "spider_hider"
    inst.components.childspawner:SetRareChild("spider_spitter", 0.33)
    inst.components.childspawner:StartSpawning()
    inst:ListenForEvent("startquake", function() ReturnChildren(inst) end, TheWorld)

    inst.creep = inst.entity:AddGroundCreepEntity()
    inst.creep:SetRadius(5)
    inst:ListenForEvent("creepactivate", SpawnInvestigators)
end

local function onsave(inst, data)
    data.broken = inst.broken
end

local function onload(inst, data)
    if data then
        inst.broken = data.broken
        if inst.broken then 
            GoToBrokenState(inst)
        else
            MakeSpiderSpawner(inst)
        end
    else
        MakeSpiderSpawner(inst)
    end
end

local function onworked(inst, worker, workleft)
    if inst.components.childspawner ~= nil then
        inst.components.childspawner:ReleaseAllChildren(worker)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 2)

    inst.MiniMapEntity:SetIcon("cavespider_den.png")
    
    inst.AnimState:SetBank("spider_mound")
    inst.AnimState:SetBuild("spider_mound")
    inst.AnimState:PlayAnimation("full")

    inst:AddTag("spiderden")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst:AddComponent("inspectable")
    inst:AddComponent("health")

    --For the first 1/3 of work done, this functions as a child spawner.
    --After the rock has been mined down to the 2nd level the rock is no longer a child spawner
    --and the call backs are changed within the "GoToBrokenState" function
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.SPILAGMITE_SPAWNER)
    inst.components.workable:SetOnWorkCallback(onworked)
    inst.components.workable:SetOnFinishCallback(GoToBrokenState)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('spider_hole')

    inst.broken = false
    inst.OnSave = onsave
    inst.OnLoad = onload
    return inst
end

return Prefab("cave/objects/spiderhole", fn, assets, prefabs)