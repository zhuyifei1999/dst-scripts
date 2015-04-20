require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/wilsonstatue.zip"),
}

local prefabs =
{
    "collapse_small",
    "charcoal",
}

local function onhammered(inst, worker)
    if inst:HasTag("fire") and inst.components.burnable ~= nil then
        inst.components.burnable:Extinguish()
    end
    if inst:HasTag("burnt") then
        if inst.components.lootdropper ~= nil then
            inst.components.lootdropper:SpawnLootPrefab("charcoal")
        end
        SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    else
        if inst.components.lootdropper ~= nil then
            inst.components.lootdropper:DropLoot()
        end
        SpawnPrefab("collapse_big").Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst:Remove()
end

local function onhaunt(inst, haunter)
    if not inst:HasTag("burnt") then
        return true
    end
    if inst.components.workable ~= nil then
        inst.components.workable:WorkedBy(haunter, 1)
    end
    return false
end

local function onburnt(inst)
    inst:AddTag("burnt")
    inst.components.burnable.canlight = false
    if inst.components.workable ~= nil then
        inst.components.workable:SetWorkLeft(1)
    end
    inst.AnimState:PlayAnimation("burnt", true)
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then 
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle")
    end
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or inst:HasTag("fire") then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function onbuilt(inst, data)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", false)
    --if data ~= nil and data.builder ~= nil and data.builder.components.health ~= nil then
        --TODO: Hurt the builder like the Telltale Heart does?
    --end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .3)

    inst.MiniMapEntity:SetIcon("resurrect.png")

    inst:AddTag("structure")
    inst:AddTag("resurrector")

    inst.AnimState:SetBank("wilsonstatue")
    inst.AnimState:SetBuild("wilsonstatue")
    inst.AnimState:PlayAnimation("idle")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)
    inst:ListenForEvent("onbuilt", onbuilt)

    inst:AddComponent("burnable")
    inst.components.burnable:SetFXLevel(3)
    inst.components.burnable:SetBurnTime(10)
    inst.components.burnable:AddBurnFX("fire", Vector3(0, 0, 0))
    inst.components.burnable:SetOnBurntFn(onburnt)
    MakeLargePropagator(inst)

    inst.OnSave = onsave 
    inst.OnLoad = onload

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_INSTANT_REZ)
    inst.components.hauntable:SetOnHauntFn(onhaunt)

    MakeSnowCovered(inst)

    inst:ListenForEvent("activateresurrection", inst.Remove)

    return inst
end

return Prefab("common/objects/resurrectionstatue", fn, assets, prefabs),
    MakePlacer("common/resurrectionstatue_placer", "wilsonstatue", "wilsonstatue", "idle")