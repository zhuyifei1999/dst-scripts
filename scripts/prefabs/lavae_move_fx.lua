local assets =
{
    Asset("ANIM", "anim/lavae_move_fx.zip"),
}

local function PlayFX(proxy, variation, scale)
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.Transform:SetFromProxy(proxy.GUID)
    inst.Transform:SetScale(scale, scale, scale)

    inst.AnimState:SetBank("lava_trail_fx")
    inst.AnimState:SetBuild("lavae_move_fx")
    inst.AnimState:PlayAnimation("trail"..tostring(variation))

    inst:ListenForEvent("animover", inst.Remove)
end

local MIN_FX_SCALE = .5
local MAX_FX_SCALE = 1.3

local function OnRandDirty(inst)
    if inst._complete or inst._rand:value() <= 0 then
        return
    end

    --Delay one frame in case we are about to be removed
    inst:DoTaskInTime(0, PlayFX, inst._rand:value(), inst._scale:value() / 7 * (MAX_FX_SCALE - MIN_FX_SCALE) + MIN_FX_SCALE)
    inst._complete = true
end

local function SetVariation(inst, rand, scale)
    inst._rand:set(rand)
    --scale range from .5 -> 1.2
    inst._scale:set(math.clamp(math.floor(math.floor((scale - MIN_FX_SCALE) / (MAX_FX_SCALE - MIN_FX_SCALE) * 7 + .5)), 0, 7))
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst._rand = net_tinybyte(inst.GUID, "lavae_move_fx._rand", "randdirty")
    inst._scale = net_tinybyte(inst.GUID, "lavae_move_fx._scale")

    --Dedicated server does not need to spawn the local fx
    if not TheNet:IsDedicated() then
        inst._complete = false
        inst:ListenForEvent("randdirty", OnRandDirty)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.SetVariation = SetVariation

    inst.persists = false
    inst:DoTaskInTime(1, inst.Remove)

    return inst
end

return Prefab("lavae_move_fx", fn, assets)
