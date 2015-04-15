local assets =
{
	Asset("ANIM", "anim/structure_collapse_fx.zip"),
}

local function playfx(proxy, anim)
    local inst = CreateEntity()

    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst.Transform:SetFromProxy(proxy.GUID)

    inst.AnimState:SetBank("collapse")
    inst.AnimState:SetBuild("structure_collapse_fx")
    inst.AnimState:PlayAnimation(anim)

    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_smoke")

    inst:ListenForEvent("animover", inst.Remove)
end

local function makefn(anim)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddNetwork()

        --Dedicated server does not need to spawn the local fx
        if not TheNet:IsDedicated() then
            --Delay one frame so that we are positioned properly before starting the effect
            --or in case we are about to be removed
            inst:DoTaskInTime(0, playfx, anim)
        end

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddTag("NOCLICK")
        inst.persists = false
        inst:DoTaskInTime(1, inst.Remove)

        return inst
    end
end

return Prefab("fx/collapse_big", makefn("collapse_large"), assets),
        Prefab("fx/collapse_small", makefn("collapse_small"), assets)