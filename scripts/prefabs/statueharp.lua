local assets =
{
    Asset("ANIM", "anim/statue_small.zip"),
    Asset("ANIM", "anim/statue_small_harp_build.zip"),
}

local prefabs =
{
    "marble",
}

SetSharedLootTable( 'statue_harp',
{
    {'marble',  1.0},
    {'marble',  1.0},
    {'marble',  0.3},
})

local function OnWorked(inst, worker, workleft)
    if workleft <= 0 then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
        inst.components.lootdropper:DropLoot(inst:GetPosition())
        inst:Remove()
    else
        inst.AnimState:PlayAnimation(
            (workleft < TUNING.MARBLEPILLAR_MINE / 3 and "low") or
            (workleft < TUNING.MARBLEPILLAR_MINE * 2 / 3 and "med") or
            "full"
        )
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.66)

    inst.entity:AddTag("statue")

    inst.AnimState:SetBank("statue_small")
    inst.AnimState:SetBuild("statue_small")
    inst.AnimState:OverrideSymbol("swap_statue", "statue_small_harp_build", "swap_statue")
    inst.AnimState:PlayAnimation("full")
    inst.AnimState:SetRayTestOnBB(true) --TODO: remove this when artists adds a mouseover region

    inst.MiniMapEntity:SetIcon("statue_small.png")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('statue_harp')

    inst:AddComponent("inspectable")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.MARBLEPILLAR_MINE)
    inst.components.workable:SetOnWorkCallback(OnWorked)

    MakeHauntableWork(inst)

    return inst
end

return Prefab("forest/objects/statueharp", fn, assets, prefabs)
