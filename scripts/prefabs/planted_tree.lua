require "prefabutil"
local pinecone_assets =
{
    Asset("ANIM", "anim/pinecone.zip"),
}

local pinecone_prefabs =
{
    "evergreen_short",
}

local acorn_assets =
{
    Asset("ANIM", "anim/acorn.zip"),
}

local acorn_prefabs =
{
    "deciduoustree",
}

local function growtree(inst)
    local tree = SpawnPrefab(inst.growprefab)
    if c_sel() == inst then c_select(tree) end
    if tree then
        tree.Transform:SetPosition(inst.Transform:GetWorldPosition())
        tree:growfromseed()
        inst:Remove()
    end
end

local function stopgrowing(inst)
    inst.components.timer:StopTimer("grow")
end

startgrowing = function(inst) -- this was forward declared
    if not inst.components.timer:TimerExists("grow") then
        local growtime = GetRandomWithVariance(TUNING.PINECONE_GROWTIME.base, TUNING.PINECONE_GROWTIME.random)
        inst.components.timer:StartTimer("grow", growtime)
    end
end

local function ontimerdone(inst, data)
    if data.name == "grow" then
        growtree(inst)
    end
end

local function digup(inst, digger)
    inst.components.lootdropper:SpawnLootPrefab("twigs")
    inst:Remove()
end

local function sapling_fn(build, anim, growprefab, tag)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank(build)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation(anim)

        MakeDragonflyBait(inst, 3)

        inst:AddTag(tag)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.growprefab = growprefab
        inst.StartGrowing = startgrowing

        inst:AddComponent("timer")
        inst:ListenForEvent("timerdone", ontimerdone)
        startgrowing(inst)

        inst:AddComponent("inspectable")

        inst:AddComponent("lootdropper")

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.DIG)
        inst.components.workable:SetOnFinishCallback(digup)
        inst.components.workable:SetWorkLeft(1)

        MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
        inst:ListenForEvent("onignite", stopgrowing)
        inst:ListenForEvent("onextinguish", startgrowing)
        MakeSmallPropagator(inst)

        MakeHauntableIgnite(inst)

        return inst
    end
    return fn
end

return Prefab("pinecone_sapling", sapling_fn("pinecone", "idle_planted", "evergreen_short", "evergreen"), pinecone_assets, pinecone_prefabs),
    Prefab("lumpy_sapling", sapling_fn("pinecone", "idle_planted2", "evergreen_sparse_short", "evergreen_sparse"), pinecone_assets, pinecone_prefabs),
    Prefab("acorn_sapling", sapling_fn("acorn", "idle_planted", "deciduoustree", "deciduoustree"), acorn_assets, acorn_prefabs)
