local assets =
{
    Asset("ANIM", "anim/atrium_key.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("atrium_key.png")

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("atrium_key")
    inst.AnimState:SetBuild("atrium_key")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("irreplaceable")
    inst:AddTag("nonpotatable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst:AddComponent("inspectable")

    inst:AddComponent("tradable")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("atrium_key", fn, assets)
