require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/treasure_chest.zip"),
    Asset("ANIM", "anim/ui_chest_3x2.zip"),

    Asset("ANIM", "anim/pandoras_chest.zip"),
    Asset("ANIM", "anim/skull_chest.zip"),
    Asset("ANIM", "anim/pandoras_chest_large.zip"),
}

local prefabs =
{
    "collapse_small",
}

local chests =
{
    treasure_chest =
    {
        bank = "chest",
        build = "treasure_chest",
    },
    skull_chest =
    {
        bank = "skull_chest",
        build = "skull_chest",
    },
    pandoras_chest =
    {
        bank = "pandoras_chest",
        build = "pandoras_chest",
    },
    minotaur_chest =
    {
        bank = "pandoras_chest_large",
        build = "pandoras_chest_large",
    },
}

local function onopen(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("open")
        inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
    end
end 

local function onclose(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("close")
        inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
    end
end

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("closed", false)
        if inst.components.container ~= nil then
            inst.components.container:DropEverything()
            inst.components.container:Close()
        end
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("closed", false)
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

local function chest(style)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        inst.MiniMapEntity:SetIcon(style..".png")

        inst:AddTag("structure")
        inst:AddTag("chest")
        inst.AnimState:SetBank(chests[style].bank)
        inst.AnimState:SetBuild(chests[style].build)
        inst.AnimState:PlayAnimation("closed")

        MakeSnowCoveredPristine(inst)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst:AddComponent("container")
        inst.components.container:WidgetSetup("treasurechest")
        inst.components.container.onopenfn = onopen
        inst.components.container.onclosefn = onclose

        inst:AddComponent("lootdropper")
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(2)
        inst.components.workable:SetOnFinishCallback(onhammered)
        inst.components.workable:SetOnWorkCallback(onhit) 

        AddHauntableDropItemOrWork(inst)

        inst:ListenForEvent("onbuilt", onbuilt)
        MakeSnowCovered(inst)   

        MakeSmallBurnable(inst, nil, nil, true)
        MakeMediumPropagator(inst)

        inst.OnSave = onsave 
        inst.OnLoad = onload

        return inst
    end
end

return Prefab("common/treasurechest", chest("treasure_chest"), assets, prefabs),
    MakePlacer("common/treasurechest_placer", "chest", "treasure_chest", "closed"),
    Prefab("common/pandoraschest", chest("pandoras_chest"), assets, prefabs),
    Prefab("common/skullchest", chest("skull_chest"), assets, prefabs),
    Prefab("common/minotaurchest", chest("minotaur_chest"), assets, prefabs)
