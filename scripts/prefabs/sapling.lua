local assets =
{
    Asset("ANIM", "anim/sapling.zip"),
    Asset("ANIM", "anim/sapling_diseased_build.zip"),
    Asset("SOUND", "sound/common.fsb"),
}

local prefabs =
{
    "twigs",
    "dug_sapling",
    "disease_fx_small",
    "disease_puff",
    "diseaseflies",
}

local function ondiseaseddeathfn(inst)
    SpawnPrefab("disease_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
end

local function ondiseasedfn(inst)
    inst.AnimState:SetBuild("sapling_diseased_build")
    SpawnPrefab("disease_fx_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.components.pickable:ChangeProduct("spoiled_food")
end

local function onrebirthedfn(inst)
    if inst.components.pickable:CanBePicked() then
        inst.components.pickable:MakeEmpty()
    end
end

local function ontransplantfn(inst)
    inst.components.pickable:MakeEmpty()
end

local function dig_up(inst, chopper)
    if inst.components.pickable and inst.components.pickable:CanBePicked() then
        inst.components.lootdropper:SpawnLootPrefab("twigs")
    end
    if not inst:HasTag("withered") then
        local bush = inst.components.lootdropper:SpawnLootPrefab("dug_sapling")
    else
        inst.components.lootdropper:SpawnLootPrefab("twigs")
    end
    inst:Remove()
end

local function onpickedfn(inst)
    inst.AnimState:PlayAnimation("rustle")
    inst.AnimState:PushAnimation("picked", false)
end

local function onregenfn(inst)
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("sway", true)
end

local function makeemptyfn(inst)
    if not POPULATING and inst:HasTag("withered") or inst.AnimState:IsCurrentAnimation("idle_dead") then
        inst.AnimState:PlayAnimation("dead_to_empty")
        inst.AnimState:PushAnimation("empty", false)
    else
        inst.AnimState:PlayAnimation("empty")
    end
end

local function makebarrenfn(inst, wasempty)
    if not POPULATING and inst:HasTag("withered") then
        inst.AnimState:PlayAnimation(wasempty and "empty_to_dead" or "full_to_dead")
        inst.AnimState:PushAnimation("idle_dead", false)
    else
        inst.AnimState:PlayAnimation("idle_dead")
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("sapling.png")

    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:SetBank("sapling")
    inst.AnimState:SetBuild("sapling")
    inst.AnimState:PlayAnimation("sway", true)

    inst:AddTag("renewable")
    MakeDragonflyBait(inst, 1)

    --witherable (from witherable component) added to pristine state for optimization
    inst:AddTag("witherable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:SetTime(math.random() * 2)

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/harvest_sticks"

    inst.components.pickable:SetUp("twigs", TUNING.SAPLING_REGROW_TIME)
    inst.components.pickable.onregenfn = onregenfn
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.makeemptyfn = makeemptyfn
    inst.components.pickable.ontransplantfn = ontransplantfn
    inst.components.pickable.makebarrenfn = makebarrenfn

    inst:AddComponent("witherable")

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(dig_up)
    inst.components.workable:SetWorkLeft(1)

    inst:AddComponent("diseaseable")
    inst.components.diseaseable:SetDiseasedFn(ondiseasedfn)
    inst.components.diseaseable:SetRebirthedFn(onrebirthedfn)
    inst.components.diseaseable:SetDiseasedDeathFn(ondiseaseddeathfn)

    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)
    MakeNoGrowInWinter(inst)
    MakeHauntableIgnite(inst)
    ---------------------   

    return inst
end

return Prefab("sapling", fn, assets, prefabs)
