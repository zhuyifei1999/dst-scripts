local assets =
{
    Asset("ANIM", "anim/marble_pillar.zip"),
}

local prefabs =
{
    "marble",
}

SetSharedLootTable( 'marble_pillar',
{
    {'marble', 1.00},
    {'marble', 1.00},
    {'marble', 0.33},
})

local function onworked(inst, worker, workleft)
    if workleft <= 0 then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
        inst.components.lootdropper:DropLoot(Point(inst.Transform:GetWorldPosition()))
        inst:Remove()
    elseif workleft < TUNING.MARBLEPILLAR_MINE / 3 then
        inst.AnimState:PlayAnimation("low")
    elseif workleft < TUNING.MARBLEPILLAR_MINE * 2 / 3 then
        inst.AnimState:PlayAnimation("med")
    else
        inst.AnimState:PlayAnimation("full")
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("marble_pillar")
    inst.AnimState:SetBuild("marble_pillar")
    inst.AnimState:PlayAnimation("full")

    inst.MiniMapEntity:SetIcon("marblepillar.png")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('marble_pillar')

    inst:AddComponent("inspectable")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.MARBLEPILLAR_MINE)
    inst.components.workable:SetOnWorkCallback(onworked)

    MakeHauntableWork(inst)
    MakeSnowCovered(inst)

    return inst
end

return Prefab("forest/objects/marblepillar", fn, assets, prefabs)