local assets =
{
    Asset("ANIM", "anim/statue_small_marble_build.zip"),
   	Asset("MINIMAP_IMAGE", "statue_small"),
}

local prefabs =
{
    "marble",
    "rock_break_fx",
}

SetSharedLootTable( 'statue_marble',
{
    {'marble',  1.0},
    {'marble',  1.0},
    {'marble',  0.3},
})

local function OnWorked(inst, worker, workleft)
    if workleft <= 0 then
        local pos = inst:GetPosition()
        SpawnPrefab("rock_break_fx").Transform:SetPosition(pos:Get())
        inst.components.lootdropper:DropLoot(pos)
        inst:Remove()
    else
        inst.AnimState:PlayAnimation(
            (workleft < TUNING.MARBLEPILLAR_MINE / 3 and "low") or
            (workleft < TUNING.MARBLEPILLAR_MINE * 2 / 3 and "med") or
            inst.animname
        )
    end
end

local names = {"s1", "s2", "s3"}
local function setstatuetype(inst, name)
    if inst.animname == nil or (name ~= nil and inst.animname ~= name) then
        inst.animname = name or names[math.random(#names)]
    end

    inst.AnimState:PlayAnimation(inst.animname)
end

local function onsave(inst, data)
    data.anim = inst.animname
end

local function onload(inst, data)
    setstatuetype(inst, data ~= nil and data.anim or nil)
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

    inst.AnimState:SetBank("statue")
    inst.AnimState:SetBuild("statue_small_marble_build")

    inst.MiniMapEntity:SetIcon("statue_small.png")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('statue_marble')

    inst:AddComponent("inspectable")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.MARBLEPILLAR_MINE)
    inst.components.workable:SetOnWorkCallback(OnWorked)

    MakeHauntableWork(inst)

    if not POPULATING then
        setstatuetype(inst)
    end
    --------SaveLoad
    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("statue_marble", fn, assets, prefabs)
