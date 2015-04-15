local assets =
{
    Asset("ANIM", "anim/bloodpump.zip"),
}

local function OnSave(inst, data)
    --print("chester_eyebone - OnSave")
    data.hasBeenPickedUp = inst.hasBeenPickedUp
end


local function OnLoad(inst, data)

    if data and data.hasBeenPickedUp then
        inst.hasBeenPickedUp = data.hasBeenPickedUp
    end
end

local function beat(inst)
    inst.task = nil
    inst.AnimState:PlayAnimation("idle", false)
    inst.SoundEmitter:PlaySound("dontstarve/ghost/bloodpump")
    inst.task = inst:DoTaskInTime(.75 + math.random()*.75, beat)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:SetBank("bloodpump01")
    inst.AnimState:SetBuild("bloodpump")
    inst.AnimState:PlayAnimation("idle", false)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(function(inst)
        inst.task = inst:DoTaskInTime(.75 + math.random()*.75, beat)
    end)

    inst.hasBeenPickedUp = false

    inst.components.inventoryitem:SetOnPickupFn(function(inst, pickuper)

        if not inst.hasBeenPickedUp then
            inst.hasBeenPickedUp = true
            pickuper.components.combat:GetAttacked(inst, TUNING.REVIVER_CRAFT_HEALTH_PENALTY)
            pickuper.components.sanity:DoDelta( -TUNING.REVIVER_CRAFT_SANITY_PENALTY )
        end

        if inst.task then
            inst.task:Cancel()
            inst.task = nil
        end
    end)

    inst:AddComponent("inspectable")

    inst:AddComponent("tradable")

    inst.OnLoad = OnLoad
    inst.OnSave = OnSave

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("common/reviver", fn, assets)