local assets =
{
    Asset("ANIM", "anim/pig_torch.zip"),
    Asset("SOUND", "sound/common.fsb"),
}

local prefabs =
{
    "pigtorch_flame",
    "pigtorch_fuel",
    "pigguard",
    "collapse_small",
}

local function onhammered(inst, worker)
    inst.components.lootdropper:DropLoot()
    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst:Remove()
end

local function onhit(inst,worker)
    if inst.components.spawner.child and inst.components.spawner.child.components.combat then
        inst.components.spawner.child.components.combat:SuggestTarget(worker)
    end
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle")
end

local function onextinguish(inst)
    if inst.components.fueled then
        inst.components.fueled:InitializeFuelLevel(0)
    end
end

local function onupdatefueledraining(inst)
    inst.components.fueled.rate = 1 + TUNING.PIGTORCH_RAIN_RATE * TheWorld.state.precipitationrate
end

local function onisraining(inst, israining)
    if inst.components.fueled ~= nil then
        if israining then
            inst.components.fueled:SetUpdateFn(onupdatefueledraining)
        else
            inst.components.fueled:SetUpdateFn()
            inst.components.fueled.rate = 1
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.33)

    inst.AnimState:SetBank("pigtorch")
    inst.AnimState:SetBuild("pig_torch")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("structure")

    --MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("burnable")
    inst.components.burnable.canlight = false
    inst.components.burnable:AddBurnFX("pigtorch_flame", Vector3(-5, 40, 0), "fire_marker")
    inst:ListenForEvent("onextinguish", onextinguish) --in case of creepy hands

    inst:AddComponent("fueled")
    inst.components.fueled.accepting = true
    inst.components.fueled.maxfuel = TUNING.PIGTORCH_FUEL_MAX
    inst.components.fueled:SetSections(3)
    inst.components.fueled.fueltype = FUELTYPE.PIGTORCH
    inst.components.fueled:SetSectionCallback( function(section)
        if section == 0 then
            inst.components.burnable:Extinguish()
        else
            if not inst.components.burnable:IsBurning() then
                inst.components.burnable:Ignite()
            end

            inst.components.burnable:SetFXLevel(section, inst.components.fueled:GetSectionPercent())
        end
    end)
    inst.components.fueled:InitializeFuelLevel(TUNING.PIGTORCH_FUEL_MAX)

    inst:WatchWorldState("israining", onisraining)
    onisraining(inst, TheWorld.state.israining)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"log", "log", "log", "poop"})
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("spawner")
    inst.components.spawner:Configure("pigguard", TUNING.TOTAL_DAY_TIME*4)
    inst.components.spawner:SetOnlySpawnOffscreen(true)
    --MakeSnowCovered(inst)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        local fuel = SpawnPrefab("pigtorch_fuel")
        if fuel then inst.components.fueled:TakeFuelItem(fuel) end
        inst.components.spawner:ReleaseChild()
        return true
    end)
    inst.components.spawner:SetOnVacateFn(function(inst, child)
        local fx = SpawnPrefab("collapse_small")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end)

    return inst
end

local function pigtorch_fuel()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.PIGTORCH_FUEL_MAX
    inst.components.fuel.fueltype = FUELTYPE.PIGTORCH
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(inst.Remove)

    return inst
end

return Prefab("forest/objects/pigtorch", fn, assets, prefabs),
    Prefab("forest/object/pigtorch_fuel", pigtorch_fuel)