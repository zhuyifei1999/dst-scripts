local assets =
{
    Asset("ANIM", "anim/lunar_seed.zip"),
}

local function onload(inst)
    -- If we loaded, then just turn the light on
    inst.Light:Enable(true)
end

local function seedfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst, 1, .5)

    inst.AnimState:SetBuild("lunar_seed")
    inst.AnimState:SetBank("lunar_seed")
    inst.AnimState:PlayAnimation("idle")

    inst.Light:SetColour(111/255, 111/255, 227/255)
    inst.Light:SetIntensity(0.75)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetRadius(2)
    inst.Light:Enable(false)

    inst:AddTag("lunarseed")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    --
    inst:AddComponent("inspectable")

    --
    inst:AddComponent("inventoryitem")

    --
    inst:AddComponent("tradable")

    --
    inst:AddComponent("stackable")

    --
    MakeHauntable(inst)

    --
    inst.OnLoad = onload

    return inst
end

return Prefab("lunar_seed", seedfn, assets)