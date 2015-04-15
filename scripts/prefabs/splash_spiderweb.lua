local assets =
{
	Asset("ANIM", "anim/splash_spiderweb.zip"),
}

local function PlaySplashAnim(proxy)
	local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()

    inst.Transform:SetFromProxy(proxy.GUID)
	
    inst.AnimState:SetBank("splash_spiderweb")
    inst.AnimState:SetBuild("splash_spiderweb")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetFinalOffset(-1)
    
    inst:ListenForEvent("animover", inst.Remove)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    --Dedicated server does not need to spawn the local fx
    if not TheNet:IsDedicated() then
        --Delay one frame so that we are positioned properly before starting the effect
        --or in case we are about to be removed
        inst:DoTaskInTime(0, PlaySplashAnim)
    end

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddTag("FX")
    inst.persists = false
    inst:DoTaskInTime(1, inst.Remove)

    return inst
end

return Prefab("common/fx/splash_spiderweb", fn, assets)