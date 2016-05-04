local assets =
{
    Asset("ANIM", "anim/fan_wheel.zip"),
}

local function AlignToTarget(inst, target)
    inst.Transform:SetRotation(target.Transform:GetRotation())
end

local function SetFollowTarget(inst, target)
    if target ~= nil then
        inst.entity:SetParent(target.entity)
        inst.Follower:FollowSymbol(target.GUID, "swap_object", 0, -114, 0)
        if inst._followtask ~= nil then
            inst._followtask:Cancel()
        end
        inst._followtask = inst:DoPeriodicTask(0, AlignToTarget, nil, target)
        AlignToTarget(inst, target)
    elseif inst._followtask ~= nil then
        inst:Remove()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("fan_wheel")
    inst.AnimState:SetBuild("fan_wheel")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetFinalOffset(1)

    -----------------------------------------------------
    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst._followtask = nil
    inst._mounted = nil
    inst.SetFollowTarget = SetFollowTarget

    inst.persists = false

    return inst
end

return Prefab("fan_wheel", fn, assets)
