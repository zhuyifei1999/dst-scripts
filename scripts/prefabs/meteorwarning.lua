local assets =
{
	Asset("ANIM", "anim/meteor_shadow.zip"),
}

local function startshadow(inst, time, starttint, endtint)
    inst.components.colourtweener:StartTween({starttint,starttint,starttint,starttint}, 0)
    inst.components.colourtweener:StartTween({endtint,endtint,endtint,endtint}, time)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("warning_shadow")
    inst.AnimState:SetBuild("meteor_shadow")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetFinalOffset(-1)

    inst:AddTag("FX")
    
    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst.SoundEmitter:PlaySound("dontstarve/common/meteor_spawn")

    inst:AddComponent("colourtweener")

    inst.startfn = startshadow

    inst.persists = false

    return inst
end

return Prefab("common/fx/meteorwarning", fn, assets)