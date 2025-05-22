local assets = {
    Asset("ANIM", "anim/wagpunk_cagewall.zip"),
}

-- idle_off to activate to idle_on to deactivated to idle_off

local function ExtendWall(inst)
    if inst.extended then
        return
    end
    inst.extended = true
    inst:RemoveTag("NOCLICK")

    if inst:IsAsleep() then
        inst.AnimState:PlayAnimation("idle_on")
    else
        inst.AnimState:PlayAnimation("activate")
        inst.AnimState:PushAnimation("idle_on", true)
    end
end

local function RetractWall(inst)
    if not inst.extended then
        return
    end
    inst.extended = false
    inst:AddTag("NOCLICK")

    if inst:IsAsleep() then
        inst.AnimState:PlayAnimation("idle_off")
    else
        inst.AnimState:PlayAnimation("deactivated")
        inst.AnimState:PushAnimation("idle_off", true)
    end
end

local function ExtendWallWithJitter(inst, jitter)
    inst:DoTaskInTime(math.random() * jitter, inst.ExtendWall)
end

local function RetractWallWithJitter(inst, jitter)
    inst:DoTaskInTime(math.random() * jitter, inst.RetractWall)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.Transform:SetEightFaced()

    inst.AnimState:SetBank("wagpunk_fence")
    inst.AnimState:SetBuild("wagpunk_cagewall")
    inst.AnimState:PlayAnimation("idle_off")
    
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst.extended = false
    inst.ExtendWall = ExtendWall
    inst.RetractWall = RetractWall
    inst.ExtendWallWithJitter = ExtendWallWithJitter
    inst.RetractWallWithJitter = RetractWallWithJitter

    return inst
end

return Prefab("wagpunk_cagewall", fn, assets)