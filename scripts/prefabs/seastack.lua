local assets =
{
    Asset("ANIM", "anim/water_rock_01.zip"),
}

local prefabs =
{
    
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeWaterObstaclePhysics(inst, 1.35)

    inst.Transform:SetFourFaced()
    inst:AddTag("ignorewalkableplatforms")

    inst.AnimState:SetBank("water_rock01")
    inst.AnimState:SetBuild("water_rock_01")
    inst.AnimState:PlayAnimation("idle")   

    inst.entity:SetPristine()    

    MakeInventoryFloatable(inst, "med", nil, 0.85)

    if not TheWorld.ismastersim then
        return inst
    else
        inst:DoTaskInTime(0, function(inst)
			inst.components.floater:OnLandedServer()
        end)
    end

    inst:AddComponent("inspectable")

    inst:ListenForEvent("hit_boat", function(inst) 
        inst.AnimState:PlayAnimation("hit") 
        inst.AnimState:PushAnimation("idle", false) 
    end)

    return inst
end

return Prefab("seastack", fn, assets, prefabs)
