local assets =
{
    Asset("ANIM", "anim/bloodpump.zip"),
}

local function beat(inst)
    inst.AnimState:PlayAnimation("idle")
    inst.SoundEmitter:PlaySound("dontstarve/ghost/bloodpump")
    inst.beattask = inst:DoTaskInTime(.75 + math.random() * .75, beat)
end

local function ondropped(inst)
    if inst.beattask ~= nil then
        inst.beattask:Cancel()
    end
    inst.beattask = inst:DoTaskInTime(.75 + math.random() * .75, beat)
end

local function onpickup(inst)
    if inst.beattask ~= nil then
        inst.beattask:Cancel()
        inst.beattask = nil
    end
end

--The first pickup must be the maker
local function onfirstpickup(inst, maker)
    inst.components.inventoryitem:SetOnPickupFn(onpickup)
    onpickup(inst)

    maker.components.health:DoDelta(-TUNING.REVIVER_CRAFT_HEALTH_PENALTY, nil, nil, nil, nil, true)
    maker.components.sanity:DoDelta(-TUNING.REVIVER_CRAFT_SANITY_PENALTY)

    -- sound and anim reactions
    if maker.components.combat.hurtsound ~= nil and maker.SoundEmitter ~= nil then
        maker.SoundEmitter:PlaySound(maker.components.combat.hurtsound)
    end

    maker:PushEvent("damaged", {})
end

local function onload(inst)
    inst.components.inventoryitem:SetOnPickupFn(onpickup)
end

local function oninit(inst)
    --Most likely dynamically or debug spawned in, and not picked up
    onload(inst) --removes pickup damage
    ondropped(inst) --starts beating (should be on the ground)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("bloodpump01")
    inst.AnimState:SetBuild("bloodpump")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(ondropped)
    inst.components.inventoryitem:SetOnPickupFn(onfirstpickup)

    inst:AddComponent("inspectable")
    inst:AddComponent("tradable")

    MakeHauntableLaunch(inst)

    inst.OnLoad = onload

    inst.beattask = inst:DoTaskInTime(0, oninit)

    return inst
end

return Prefab("common/reviver", fn, assets)