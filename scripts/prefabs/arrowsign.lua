local assets =
{
    Asset("ANIM", "anim/sign_arrow_post.zip"),
    Asset("ANIM", "anim/sign_arrow_panel.zip"),
}


local prefabs =
{
    "collapse_small",
    "arrowsign_panel",
}

local function onhammered(inst, worker)
    if inst:HasTag("fire") and inst.components.burnable then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle")
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

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .2)

    inst.MiniMapEntity:SetIcon("sign.png")

    inst.AnimState:SetBank("sign_arrow_post")
    inst.AnimState:SetBuild("sign_arrow_post")
    inst.AnimState:PlayAnimation("idle")

    inst.Transform:SetEightFaced()

    MakeSnowCoveredPristine(inst)

    --Sneak these into pristine state for optimization
    inst:AddTag("_writeable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --Remove these tags so that they can be added properly when replicating components below
    inst:RemoveTag("_writeable")

    inst:AddComponent("inspectable")
    inst:AddComponent("writeable")
    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    MakeSnowCovered(inst)

    inst:AddComponent("savedrotation")

    inst:AddTag("structure")
    MakeSmallBurnable(inst, nil, nil, true)
    MakeSmallPropagator(inst)
    inst.OnSave = onsave
    inst.OnLoad = onload

    MakeHauntableWork(inst)

    return inst
end

local function panelfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("sign_arrow_panel")
    inst.AnimState:SetBuild("sign_arrow_panel")
    inst.AnimState:PlayAnimation("idle")

    inst.Transform:SetEightFaced()

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("writeable")
    inst:AddComponent("lootdropper")

    inst:AddComponent("savedrotation")

    -- TODO: Make workable, but transfer the work to the sign base instead

    MakeSnowCovered(inst)

    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("common/objects/arrowsign_post", fn, assets, prefabs),
        MakePlacer("common/arrowsign_post_placer", "sign_arrow_post", "sign_arrow_post", "idle", nil, nil, nil, nil, -90, "eight"),
        Prefab("common/objects/arrowsign_panel", panelfn, assets, prefabs),
        MakePlacer("common/arrowsign_panel_placer", "sign_arrow_panel", "sign_arrow_panel", "idle", nil, nil, nil, nil, -90, "eight")
