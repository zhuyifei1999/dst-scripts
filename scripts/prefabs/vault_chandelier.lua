--This file contains vault_chandelier_broken.
--vault_chandelier is defined in archive_chandelier.lua

local assets =
{
	Asset("ANIM", "anim/chandelier_vault.zip"),
}

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, 0.75)

	inst.AnimState:SetBank("chandelier_vault")
	inst.AnimState:SetBuild("chandelier_vault")
	inst.AnimState:PlayAnimation("fallen")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	return inst
end

--vault_chandelier is defined in archive_chandelier.lua
return Prefab("vault_chandelier_broken", fn, assets)
