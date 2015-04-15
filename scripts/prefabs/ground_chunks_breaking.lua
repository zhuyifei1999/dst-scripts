local assets =
{
    Asset("ANIM", "anim/ground_chunks_breaking.zip"),
}

local function PlayChunksAnim(proxy)
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.Transform:SetFromProxy(proxy.GUID)

    inst.AnimState:SetBank("ground_breaking")
    inst.AnimState:SetBuild("ground_chunks_breaking")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetFinalOffset(-1)

    inst:ListenForEvent("animover", inst.Remove)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    --Dedicated server does not need to spawn the local fx
    if not TheNet:IsDedicated() then
        --Delay one frame so that we are positioned properly before starting the effect
        --or in case we are about to be removed
        inst:DoTaskInTime(0, PlayChunksAnim)
    end

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst.persists = false
    inst:DoTaskInTime(1, inst.Remove)

    return inst
end

return Prefab("common/fx/ground_chunks_breaking", fn, assets)