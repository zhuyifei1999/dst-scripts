local stalagmite_assets =
{
    Asset("ANIM", "anim/rock_stalagmite.zip"),
}

local prefabs =
{
    "rocks",
    "nitre",
    "flint",
    "goldnugget",
    "orangegem",
}

SetSharedLootTable( 'full_rock',
{
    {'rocks',       1.00},
    {'rocks',       1.00},
    {'rocks',       1.00},
    {'goldnugget',  1.00},
    {'flint',       1.00},
    {'goldnugget',  0.25},
    {'flint',       0.60},
    {'bluegem',     0.05},
    {'redgem',      0.05},
})

SetSharedLootTable( 'med_rock',
{
    {'rocks',       1.00},
    {'rocks',       1.00},
    {'flint',       1.00},
    {'goldnugget',  0.50},
    {'flint',       0.60},
})

SetSharedLootTable( 'low_rock',
{
    {'rocks',       1.00},
    {'flint',       1.00},
    {'goldnugget',  0.25},
    {'flint',       0.30},
})

local function workcallback(inst, worker, workleft)
    if workleft <= 0 then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
        inst.components.lootdropper:DropLoot(inst:GetPosition())
        inst:Remove()
    elseif workleft <= TUNING.ROCKS_MINE / 3 then
        inst.AnimState:PlayAnimation("low")
    elseif workleft <= TUNING.ROCKS_MINE * 2 / 3 then
        inst.AnimState:PlayAnimation("med")
    else
        inst.AnimState:PlayAnimation("full")
    end
end

local function commonfn(anim)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("stalagmite.png")

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("rock_stalagmite")
    inst.AnimState:SetBuild("rock_stalagmite")
    inst.AnimState:PlayAnimation(anim)

    inst:SetPrefabNameOverride("stalagmite")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    local color = 0.5 + math.random() * 0.5
    inst.AnimState:SetMultColour(color, color, color, 1)

    inst:AddComponent("lootdropper")

    inst:AddComponent("inspectable")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE)

    inst.components.workable:SetOnWorkCallback(workcallback)

    return inst
end

local function fullrock()
    local inst = commonfn("full")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.lootdropper:SetChanceLootTable('full_rock')

    return inst
end

local function medrock()
    local inst = commonfn("med")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE_MED)
    inst.components.lootdropper:SetChanceLootTable('med_rock')

    return inst
end

local function lowrock()
    local inst = commonfn("low")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE_LOW)
    inst.components.lootdropper:SetChanceLootTable('low_rock')

    return inst
end

return Prefab("cave/objects/stalagmite_full", fullrock, stalagmite_assets, prefabs),
    Prefab("cave/objects/stalagmite_med", medrock, stalagmite_assets, prefabs),
    Prefab("cave/objects/stalagmite_low", lowrock, stalagmite_assets, prefabs),
    Prefab("cave/objects/stalagmite", fullrock, stalagmite_assets, prefabs)