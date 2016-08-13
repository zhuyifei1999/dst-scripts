local assets =
{
    Asset("ANIM", "anim/sentryward.zip"),
}

local prefabs =
{
    "collapse_small",
    "globalmapicon",
}

local function doidleanims(inst)
    inst.AnimState:PlayAnimation("idle_full_loop2")
    for i = 1, math.random(3) do
        inst.AnimState:PushAnimation("idle_full_loop2", false)
    end

    local anim_num = math.random(4)
    inst.AnimState:PushAnimation(anim_num == 1 and "idle_full_loop" or ("idle_full_loop"..tostring(anim_num)), false)
end

local function onhammered(inst)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit_full")
    end
end

local function onbuilt(inst)
    --inst.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
    inst.AnimState:PlayAnimation("place")
end

local function onburnt(inst)
    inst.components.maprevealer:Stop()
    if inst.icon ~= nil then
        inst.icon:Remove()
        inst.icon = nil
    end
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function init(inst)
    if inst.icon == nil and not inst:HasTag("burnt") then
        inst.icon = SpawnPrefab("globalmapicon")
        inst.icon:TrackEntity(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("sentryward.png")
    inst.MiniMapEntity:SetCanUseCache(false)
    inst.MiniMapEntity:SetDrawOverFogOfWar(true)

    MakeObstaclePhysics(inst, .1)

    inst.AnimState:SetBank("sentryward")
    inst.AnimState:SetBuild("sentryward")
    inst.AnimState:PlayAnimation("idle_full_loop2")

    inst:AddTag("structure")

    --maprevealer (from maprevealer component) added to pristine state for optimization
    inst:AddTag("maprevealer")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("animqueueover", doidleanims)
    inst.AnimState:SetTime(math.random() * 1.5)

    -----------------------
    MakeSmallBurnable(inst, nil, nil, true)
    inst:ListenForEvent("burntup", onburnt)

    MakeSmallPropagator(inst)
    MakeHauntableWork(inst)

    -------------------------
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    -----------------------------

    inst:AddComponent("inspectable")

    inst:AddComponent("maprevealer")

    inst:ListenForEvent("onbuilt", onbuilt)
    inst.OnSave = onsave
    inst.OnLoad = onload

    inst:DoTaskInTime(0, init)

    return inst
end

return Prefab("sentryward", fn, assets, prefabs),
    MakePlacer("sentryward_placer", "sentryward", "sentryward", "idle_full")
