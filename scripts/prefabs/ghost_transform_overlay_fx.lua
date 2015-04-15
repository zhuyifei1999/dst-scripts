local assets =
{
	Asset("ANIM", "anim/player_revive_fx.zip"),
    -- Asset("ANIM", "anim/player_revive_WithoutGhostHat.zip"),
}

local function RemoveMe(inst)
    inst:DoTaskInTime(1, inst.Remove)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")        

    inst.AnimState:SetBank("player_revive_FX")
    inst.AnimState:SetBuild("player_revive_FX")
    inst.AnimState:PlayAnimation("shudder", false)
    inst.AnimState:PushAnimation("hit", false)
    inst.AnimState:PushAnimation("transform", false)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()
    
    inst.persists = false

    inst:ListenForEvent("animqueueover", RemoveMe)

    return inst
end

return Prefab("fx/ghost_transform_overlay_fx", fn, assets)
