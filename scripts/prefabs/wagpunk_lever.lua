local assets = {
    Asset("ANIM", "anim/wagpunk_lever.zip"),
}

local function OnActivate(inst, doer)
    inst:RetractLever()
    TheWorld:PushEvent("ms_wagpunk_lever_activated")
    return true
end

local function ExtendLever(inst)
    if inst.extended then
        return
    end
    inst.extended = true
    inst:RemoveTag("NOCLICK")

    inst.components.activatable.inactive = true
    ChangeToObstaclePhysics(inst)
    if inst:IsAsleep() then
        inst.AnimState:PlayAnimation("idle")
    else
        inst.AnimState:PlayAnimation("deactivated")
        inst.AnimState:PushAnimation("idle", true)
    end
end

local function RetractLever(inst)
    if not inst.extended then
        return
    end
    inst.extended = false
    inst:AddTag("NOCLICK")

    inst.components.activatable.inactive = false
    RemovePhysicsColliders(inst)
    if inst:IsAsleep() then
        inst.AnimState:PlayAnimation("idle_close")
    else
        inst.AnimState:PlayAnimation("activate")
        inst.AnimState:PushAnimation("idle_close", true)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.4)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("wagpunk_lever")
    inst.AnimState:SetBuild("wagpunk_lever")
    inst.AnimState:PlayAnimation("idle_close")

    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    local activatable = inst:AddComponent("activatable")
    activatable.OnActivate = OnActivate
    activatable.standingaction = true
    activatable.inactive = false

    inst.extended = false
    inst.ExtendLever = ExtendLever
    inst.RetractLever = RetractLever

    return inst
end

return Prefab("wagpunk_lever", fn, assets)