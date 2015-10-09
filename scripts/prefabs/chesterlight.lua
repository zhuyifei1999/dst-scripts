local assets =
{
    Asset("ANIM", "anim/cave_exit_lightsource.zip"),
}

local function TurnOn(inst)
    inst.AnimState:PlayAnimation("on")
    inst.AnimState:PushAnimation("idle_loop", false)
    inst.components.lighttweener:StartTween(inst.Light, 0, .9, .3, nil, 0)
    inst.components.lighttweener:StartTween(inst.Light, 5, nil, nil, nil, FRAMES * 6)
end

local function TurnOff(inst)
    inst.AnimState:PlayAnimation("off")
    inst.components.lighttweener:StartTween(inst.Light, 0, .9, .3, nil, FRAMES * 6)
    inst:ListenForEvent("animover", inst.Remove)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("cavelight")
    inst.AnimState:SetBuild("cave_exit_lightsource")

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.Light:SetRadius(5)
    inst.Light:SetIntensity(.9)
    inst.Light:SetFalloff(.3)
    inst.Light:SetColour(180 / 255, 195 / 255, 150 / 255)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.TurnOn = TurnOn
    inst.TurnOff = TurnOff

    inst:AddComponent("lighttweener")

    return inst
end

return Prefab("chesterlight", fn, assets)