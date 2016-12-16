require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/spider_egg_sac.zip"),
    Asset("SOUND", "sound/spider.fsb"),
}

local function ondeploy(inst, pt)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spider_egg_sack")
    local tree = SpawnPrefab("spiderden")
    if tree ~= nil then
        tree.Transform:SetPosition(pt:Get())
        inst.components.stackable:Get():Remove()
        inst:RemoveComponent("hauntable")
    end
end

local function onpickup(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spider_egg_sack")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("spider_egg_sac")
    inst.AnimState:SetBuild("spider_egg_sac")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("cattoy")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM    
    inst:AddComponent("inspectable")

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

    MakeSmallBurnable(inst, TUNING.LARGE_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunchAndIgnite(inst)

    inst:AddComponent("inventoryitem")
    inst:AddComponent("tradable")

    inst.components.inventoryitem:SetOnPickupFn(onpickup)

    inst:AddComponent("deployable")
    --inst.components.deployable:SetDeployMode(DEPLOYMODE.ANYWHERE)
    inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.NONE)
    inst.components.deployable.ondeploy = ondeploy

    return inst
end

return Prefab("spidereggsack", fn, assets),
    MakePlacer("spidereggsack_placer", "spider_cocoon", "spider_cocoon", "cocoon_small")
