local stalagmite_tall_assets =
{
    Asset("ANIM", "anim/rock_stalagmite_tall.zip"),
	Asset("MINIMAP_IMAGE", "stalagmite_tall"), --shared with other numbered prefabs
}

local prefabs =
{
    "rocks",
    "nitre",
    "flint",
    "goldnugget",
    "yellowgem",
}

SetSharedLootTable( 'stalagmite_tall_full_rock',
{
    {'rocks',       1.00},
    {'rocks',       1.00},
    {'goldnugget',  1.00},
    {'flint',       1.00},
    {'goldnugget',  0.25},
    {'flint',       0.60},
    {'redgem',      0.05},
    {'log',         0.05},
})

SetSharedLootTable( 'stalagmite_tall_med_rock',
{
    {'rocks',       1.00},
    {'rocks',       1.00},
    {'flint',       1.00},
    {'goldnugget',  0.15},
    {'flint',       0.60},
})

SetSharedLootTable( 'stalagmite_tall_low_rock',
{
    {'rocks',       1.00},
    {'flint',       1.00},
    {'goldnugget',  0.15},
    {'flint',       0.30},
})

local function workcallback(inst, worker, workleft)
    if workleft <= 0 then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
        inst.components.lootdropper:DropLoot(inst:GetPosition())
        inst:Remove()
    elseif workleft <= TUNING.ROCKS_MINE / 3 then
        inst.AnimState:PlayAnimation("low"..inst.type)
    elseif workleft <= TUNING.ROCKS_MINE * 2 / 3 then
        inst.AnimState:PlayAnimation("med"..inst.type)
    else
        inst.AnimState:PlayAnimation("full"..inst.type)
    end
end

local function commonfn(anim)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("stalagmite_tall.png")

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("rock_stalagmite_tall")
    inst.AnimState:SetBuild("rock_stalagmite_tall")

    --Sneak these into pristine state for optimization
    inst:AddTag("_named")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --Remove these tags so that they can be added properly when replicating components below
    inst:RemoveTag("_named")

    inst.type = "_"..tostring(math.random(2)) -- left or right handed rock
    inst.AnimState:PlayAnimation(anim..inst.type)

    local color = 0.5 + math.random() * 0.5
    inst.AnimState:SetMultColour(color, color, color, 1)

    inst:AddComponent("lootdropper") 

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "stalagmite_tall"

    inst:AddComponent("named")
    inst.components.named:SetName(STRINGS.NAMES["STALAGMITE"])

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

    inst.components.lootdropper:SetChanceLootTable('stalagmite_tall_full_rock')

    return inst
end

local function medrock()
    local inst = commonfn("med")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE_MED)
    inst.components.lootdropper:SetChanceLootTable('stalagmite_tall_med_rock')

    return inst
end

local function lowrock()
    local inst = commonfn("low")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE_LOW)
    inst.components.lootdropper:SetChanceLootTable('stalagmite_tall_low_rock')

    return inst
end

return Prefab("stalagmite_tall_full", fullrock, stalagmite_tall_assets, prefabs),
    Prefab("stalagmite_tall_med", medrock, stalagmite_tall_assets, prefabs),
    Prefab("stalagmite_tall_low", lowrock, stalagmite_tall_assets, prefabs),
    Prefab("stalagmite_tall", fullrock, stalagmite_tall_assets, prefabs)