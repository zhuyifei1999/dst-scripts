local NUM_TREES = 4

local assets =
{
    Asset("ANIM", "anim/marble_trees.zip"),
}

local prefabs =
{
    "marble",
}

SetSharedLootTable( 'marble_tree',
{
    {'marble', 1.0},
    {'marble', 0.5},
})

local function onsave(inst, data)
    data.anim = inst.animnumber
end

local function onload(inst, data)
    if data and data.anim then
        inst.animnumber = data.anim
        inst.AnimState:PlayAnimation("full_"..inst.animnumber)
    end
end

local function onworked(inst, worker, workleft)
    if workleft <= 0 then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
        inst.components.lootdropper:DropLoot(Point(inst.Transform:GetWorldPosition()))
        inst:Remove()
    elseif workleft < TUNING.MARBLETREE_MINE / 3 then
        inst.AnimState:PlayAnimation("low_"..inst.animnumber)
    elseif workleft < TUNING.MARBLETREE_MINE * 2 / 3 then
        inst.AnimState:PlayAnimation("med_"..inst.animnumber)
    else
        inst.AnimState:PlayAnimation("full_"..inst.animnumber)
    end
end

local function makeMarbleTree(animnumber)
    local name = "marbletree"
    if animnumber > 0 then
        name = name.."_"..tostring(animnumber)
    end
    local prefabname = "forest/objects/"..name

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()  
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, 0.1)

        inst.MiniMapEntity:SetIcon("marbletree.png")
        inst.MiniMapEntity:SetPriority(-1)

        inst.AnimState:SetBank("marble_trees")
        inst.AnimState:SetBuild("marble_trees")
        if animnumber > 0 then
            inst.AnimState:PlayAnimation("full_"..animnumber)
        end

        MakeSnowCoveredPristine(inst)

        inst:SetPrefabName("marbletree")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetChanceLootTable('marble_tree')

        if animnumber > 0 then
            inst.animnumber = animnumber
        else
            inst.animnumber = math.random(1, NUM_TREES)
            inst.AnimState:PlayAnimation("full_"..inst.animnumber)
        end

        inst:AddComponent("inspectable")
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.MINE)
        inst.components.workable:SetWorkLeft(TUNING.MARBLETREE_MINE)
        inst.components.workable:SetOnWorkCallback(onworked)

        MakeHauntableWork(inst)

        MakeSnowCovered(inst)

        inst.OnSave = onsave
        inst.OnLoad = onload

        return inst
    end
    return Prefab(prefabname, fn, assets, prefabs)
end

local ret = {}
for k = 0, NUM_TREES do -- 0 is the "random" tree
    table.insert(ret, makeMarbleTree(k))
end

return unpack(ret)