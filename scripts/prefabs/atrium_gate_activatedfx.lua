
local assets =
{
    Asset("ANIM", "anim/atrium_gate_overload_fx.zip"),
}

local function SetFx(inst, anim, immediate)
	local prev_anim = inst.anim
	inst.anim = anim
	if immediate then
		inst.AnimState:PlayAnimation(inst.anim .. "_pre", false)
	else
		if prev_anim then
			inst.AnimState:PushAnimation(prev_anim .. "_pst", false)
		end
		inst.AnimState:PushAnimation(inst.anim .. "_pre", false)
	end
	inst.AnimState:PushAnimation(inst.anim .. "_loop", true)
end

local function EndFx(inst)
	inst.AnimState:PushAnimation(inst.anim .. "_pst", false)
	inst:DoTaskInTime(4, inst.Remove)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.Light:Enable(false)
	inst.Light:SetColour(200 / 255, 140 / 255, 140 / 255)
	inst.Light:SetRadius(8.0)
	inst.Light:SetFalloff(.9)
	inst.Light:SetIntensity(0.65)

    inst.AnimState:SetBank("atrium_gate_overload_fx")
    inst.AnimState:SetBuild("atrium_gate_overload_fx")

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetFinalOffset(1)

    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst.anim = "idle"

	inst.SetFx = SetFx
	inst.EndFx = EndFx

    return inst
end


return Prefab("atrium_gate_activatedfx", fn, assets)
