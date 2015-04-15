local assets =
{
	Asset("ANIM", "anim/flies.zip"),
}

local function onnear(inst)
    inst.SoundEmitter:KillSound("flies")
	inst.AnimState:PlayAnimation("swarm_pst")
end

local function onfar(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/flies", "flies")
	inst.AnimState:PlayAnimation("swarm_pre")
    inst.AnimState:PushAnimation("swarm_loop", true)
end        
        
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("flies")
    inst.AnimState:SetBuild("flies")
    
    inst.AnimState:PlayAnimation("swarm_pre")
    inst.AnimState:PushAnimation("swarm_loop", true)

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    --inst.SoundEmitter:PlaySound("dontstarve/common/flies", "flies")

    inst:AddComponent("playerprox")
    
    inst.components.playerprox:SetDist(2,3)
    inst.components.playerprox:SetOnPlayerNear(onnear)

    inst.components.playerprox:SetOnPlayerFar(onfar)
    
    return inst
end

return Prefab("common/objects/flies", fn, assets)