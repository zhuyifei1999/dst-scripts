local assets =
{
    Asset("ANIM", "anim/fan_wheel.zip"),
}

local function AlignToOwner(inst)
    if inst.followtarget ~= nil then
		local ownerrot = inst.followtarget.Transform:GetRotation()
        inst.Transform:SetRotation(ownerrot)
    end
end

local function SetFollowTarget(inst, target)
    inst.followtarget = target
	if inst.followtarget ~= nil then
		inst.Follower:FollowSymbol(target.GUID, "swap_object", 0, -114, 0.02)
		inst.savedfollowtarget = target
	elseif inst.savedfollowtarget ~= nil then
		inst:Remove()
	end
end

local function local_fn(proxy)
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

	-----------------------------------------------------
    inst:AddTag("FX")

    inst.persists = false

	--inst.followtarget = net_entity(inst.GUID, "fan_wheel.followtarget", "followtargetdirty")
	--inst:ListenForEvent("followtargetdirty", followtargetdirty, inst)

    ----Dedicated server does not need to spawn the local fx
    --if not TheNet:IsDedicated() then
    --end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.SetFollowTarget = SetFollowTarget

    inst:DoPeriodicTask(0, AlignToOwner)

    return inst
end

return Prefab("common/fx/fan_wheel", local_fn, assets)
