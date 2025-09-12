local assets =
{
	Asset("ANIM", "anim/vault_ground_pattern.zip"),
}

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.AnimState:SetBank("vault_ground_pattern")
	inst.AnimState:SetBuild("vault_ground_pattern")
	inst.AnimState:PlayAnimation("idle1")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(-3)
	inst.AnimState:SetFinalOffset(-1)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	return inst
end

return Prefab("vault_ground_pattern_fx", fn, assets)
