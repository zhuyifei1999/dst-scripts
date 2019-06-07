local assets =
{
    Asset("ANIM", "anim/boat_brokenparts.zip"),
    Asset("ANIM", "anim/boat_brokenparts_build.zip"),
}

local prefabs =
{
    
}

local function fn(suffix, radius)

    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    MakeObstaclePhysics(inst, radius)

    inst.AnimState:SetBank("boat_broken")
    inst.AnimState:SetBuild("boat_brokenparts_build")
    inst.AnimState:PlayAnimation("land_" .. suffix)
    inst.AnimState:PushAnimation("idle_loop_" .. suffix, true)

    -- Boat fragments are always wet!
    inst:AddTag("wet")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakeLargeBurnable(inst)
    MakeLargePropagator(inst)

    inst:AddComponent("hauntable")
    inst:AddComponent("inspectable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    return inst
end

return Prefab("boatfragment01", function() return fn("01", 0.5) end, assets, prefabs),
       Prefab("boatfragment02", function() return fn("02", 0.5) end, assets, prefabs),
       Prefab("boatfragment03", function() return fn("03", 0.5) end, assets, prefabs),
       Prefab("boatfragment04", function() return fn("04", 0.5) end, assets, prefabs),
       Prefab("boatfragment05", function() return fn("05", 0.5) end, assets, prefabs)
       
