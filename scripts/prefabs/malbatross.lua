local assets =
{
    Asset("ANIM", "anim/marbitraus_basic.zip"),
    Asset("ANIM", "anim/marbitraus_build.zip"),
}

local prefabs =
{

}

local function fn()
    
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()    
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("marbitraus")
    inst.AnimState:SetBuild("marbitraus_build")

    inst.DynamicShadow:SetSize(6, 2)
    inst.Transform:SetSixFaced()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:PlayAnimation("idle_loop", true)

    return inst
end

return Prefab("malbatross", fn, assets, prefabs)
