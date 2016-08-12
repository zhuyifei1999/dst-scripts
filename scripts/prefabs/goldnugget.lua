local assets =
{
    Asset("ANIM", "anim/gold_nugget.zip"),
}

local function shine(inst)
    if not inst.AnimState:IsCurrentAnimation("sparkle") then
        inst.AnimState:PlayAnimation("sparkle")
        inst.AnimState:PushAnimation("idle", true)
    end
    inst:DoTaskInTime(4 + math.random() * 5, shine)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetBank("goldnugget")
    inst.AnimState:SetBuild("gold_nugget")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("molebait")
    inst:AddTag("quakedebris")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.ELEMENTAL
    inst.components.edible.hungervalue = 2
    inst:AddComponent("tradable")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst:AddComponent("stackable")
    inst:AddComponent("bait")

    MakeHauntableLaunchAndSmash(inst)

    shine(inst)

    return inst
end

return Prefab("goldnugget", fn, assets)
