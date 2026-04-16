local assets =
{
    Asset("ANIM", "anim/wx78_gestalttrapper.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("wx78_gestalttrapper")
    inst.AnimState:SetBuild("wx78_gestalttrapper")
    inst.AnimState:PlayAnimation("idle")

    inst.pickupsound = "metal"

    MakeInventoryFloatable(inst, "small", 0.07, 1.2)
    MakeItemSocketable_Client(inst, "socket_gestalttrapper")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakeItemSocketable_Server(inst)
    inst.components.socketable:SetSocketQuality(SOCKETQUALITY.LOW)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("wx78_gestalttrapper", fn, assets)