local assets =
{
	Asset("ANIM", "anim/atrium_light.zip")
}

local function OnPoweredFn(inst, ispowered)
    inst.AnimState:PlayAnimation(ispowered and "turn_on" or "turn_off", false)
    inst.AnimState:PushAnimation(ispowered and "idle_active" or "idle", false)
    inst.Light:Enable(ispowered)
end

local function getstatus(inst)
    return inst.Light:IsEnabled() and "ON" or "OFF"
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddLight()
	inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .45)

    inst.AnimState:SetBank("atrium_light")
    inst.AnimState:SetBuild("atrium_light")
    inst.AnimState:PlayAnimation("idle", true)

	inst.MiniMapEntity:SetIcon("atrium_light.png")

    inst.Light:Enable(false)
    inst.Light:SetRadius(8.0)
    inst.Light:SetFalloff(.9)
    inst.Light:SetIntensity(0.65)
    inst.Light:SetColour(200 / 255, 140 / 255, 140 / 255)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    MakeHauntableWork(inst)

	inst:ListenForEvent("atriumpowered", function(_, ispowered) OnPoweredFn(inst, ispowered) end, TheWorld)

    return inst
end

return Prefab("atrium_light", fn, assets)
