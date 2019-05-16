local assets =
{
    Asset("ANIM", "anim/frog.zip")
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
    --MakeObstaclePhysics(inst, .2)

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("frog")
    inst.AnimState:SetBuild("frog")
    inst.AnimState:PlayAnimation("idle", true)  
    inst.AnimState:SetSortOrder(5) 

    inst.entity:SetPristine()    

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:AddFollower()

    inst:AddComponent("livinghat")
    inst.components.livinghat:SetHead(ThePlayer)

    return inst
end

return Prefab("animalhat", fn, assets, prefabs)
