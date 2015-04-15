local assets =
{
	Asset("ANIM", "anim/maxwell_torch.zip")
}

local prefabs =
{
    "maxwelllight_flame",
}

local function changelevels(inst, order)
    for i=1, #order do
        inst.components.burnable:SetFXLevel(order[i])
        Sleep(0.05)
    end
end

local function light(inst)    
    inst.task = inst:StartThread(function() changelevels(inst, inst.lightorder) end)    
end

local function extinguish(inst)
    if inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
end

local function fn(name)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("maxwelltorch.png")

    inst.AnimState:SetBank("maxwell_torch")
    inst.AnimState:SetBuild("maxwell_torch")
    inst.AnimState:PlayAnimation("idle", false)

    inst:AddTag("structure")

    MakeObstaclePhysics(inst, .1)

    if name ~= nil then
        --Sneak these into pristine state for optimization
        inst:AddTag("_named")
    end

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    if name ~= nil then
        --Remove these tags so that they can be added properly when replicating components below
        inst:RemoveTag("_named")

        inst:AddComponent("named")
        inst.components.named:SetName(STRINGS.NAMES[name])
    end

    -----------------------
    inst:AddComponent("burnable")
    inst.components.burnable:AddBurnFX("maxwelllight_flame", Vector3(0,0,0), "fire_marker")
    inst.components.burnable:SetOnIgniteFn(light)
    ------------------------    
    inst:AddComponent("inspectable")

    return inst
end

local function arealight()
    local inst = fn("MAXWELLLIGHT")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.lightorder = { 5, 6, 7, 8, 7 }

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(17, 27 )
    inst.components.playerprox:SetOnPlayerNear(function() if not inst.components.burnable:IsBurning() then inst.components.burnable:Ignite() end end)
    inst.components.playerprox:SetOnPlayerFar(extinguish)

    inst.components.inspectable.nameoverride = "maxwelllight"

    return inst
end

local function spotlight()
    local inst = fn()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.lightorder = { 1, 2, 3, 4, 3 }

    return inst
end

return Prefab( "common/objects/maxwelllight", spotlight, assets, prefabs),
    Prefab("common/objects/maxwelllight_area", arealight, assets, prefabs)