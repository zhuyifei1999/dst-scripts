require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/fossil_piece.zip"),
}

local prefabs =
{
    "fossil_stalker",
}

local NUM_FOSSIL_TYPES = 6
local function SetFossilType(inst, fossiltype)
    inst.fossiltype = fossiltype
    inst.AnimState:PlayAnimation(""..(fossiltype or "idle")) -- "idle" is the generic anim to use once its been picked up
end

local function cleanfossil(inst, data)
    SetFossilType(inst, nil) -- show the cleaned bones image instead of the random mined images
end

local function onsave(inst, data)
    data.fossiltype = inst.fossiltype
end

local function onload(inst, data)
    SetFossilType(inst, data and data.fossiltype)
end

local function ondeploy(inst, pt)
    local mound = SpawnPrefab("fossil_stalker")
    if mound then
        mound.Transform:SetPosition(pt:Get())
        mound.SoundEmitter:PlaySound("dontstarve/creatures/together/fossil/repair")

        inst.components.stackable:Get():Remove()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("fossil_piece")
    inst.AnimState:SetBuild("fossil_piece")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("quakedebris")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
    inst.components.stackable:SetOnDeStack(SetFossilType)

    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    MakeHauntableLaunch(inst)

    ------------------
    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy
    inst.components.deployable:SetDeployMode(DEPLOYMODE.ANYWHERE)

    inst:AddComponent("repairer")
    inst.components.repairer.repairmaterial = MATERIALS.FOSSIL
    inst.components.repairer.healthrepairvalue = 1
    inst.components.repairer.workrepairvalue = 1

    SetFossilType(inst, math.random(NUM_FOSSIL_TYPES))

    inst:ListenForEvent("onpickup", cleanfossil)
    inst:ListenForEvent("onputininventory", cleanfossil)

    --------SaveLoad
    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

function cleanfn()
    local inst = fn()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:SetPrefabName("fossil_piece")
    SetFossilType(inst, nil)

    return inst
end

return Prefab("fossil_piece", fn, assets, prefabs),
       MakePlacer("fossil_piece_placer", "fossil_piece", "fossil_piece", "idle"),
       Prefab("fossil_piece_clean", cleanfn, assets, prefabs)
