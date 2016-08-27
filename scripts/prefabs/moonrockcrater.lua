local assets =
{
    Asset("ANIM", "anim/mooneyes.zip"),
}

local prefabs =
{
    "purplemooneye",
    "bluemooneye",
    "redmooneye",
    "orangemooneye",
    "yellowmooneye",
    "greenmooneye",
}

local function ItemTradeTest(inst, item)
    return item ~= nil and string.sub(item.prefab, -3) == "gem"
end

local function OnGemGiven(inst, giver, item)
    local mooneye = SpawnPrefab(string.sub(item.prefab, 1, -4).."mooneye")
    local container = inst.components.inventoryitem:GetContainer()
    if container ~= nil then
        local slot = inst.components.inventoryitem:GetSlotNum()
        inst:Remove()
        container:GiveItem(mooneye, slot)
    else
        local x, y, z = inst.Transform:GetWorldPosition()
        inst:Remove()
        mooneye.Transform:SetPosition(x, y, z)
    end
    mooneye.SoundEmitter:PlaySound("dontstarve/common/telebase_gemplace")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:SetBank("mooneyes")
    inst.AnimState:SetBuild("mooneyes")
    inst.AnimState:PlayAnimation("crater")

    inst:AddTag("gemsocket")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("repairer")
    inst.components.repairer.repairmaterial = MATERIALS.MOONROCK
    inst.components.repairer.healthrepairvalue = TUNING.REPAIR_MOONROCK_CRATER_HEALTH

    inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(ItemTradeTest)
    inst.components.trader.onaccept = OnGemGiven

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("moonrockcrater", fn, assets, prefabs)
