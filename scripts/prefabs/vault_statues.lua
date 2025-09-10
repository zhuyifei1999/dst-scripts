local assets =
{
	Asset("ANIM", "anim/statue_vault.zip"),
}

--[[
king
guard
gate
ancient1
ancient2
ancient3
ancient4
bug1
bug2
bug3
]]

local function SetId(inst, id)
	if id ~= inst.id then
		inst.id = id
		inst.AnimState:PlayAnimation("idle_"..id)
	end
end

local function SetScene(inst, scene)
	inst.scene = scene
end

local function GetStatus(inst)--, viewer)
	return string.upper(inst.scene)
end

local function OnSave(inst, data)
	data.id = inst.id ~= "king" and inst.id or nil
	data.scene = inst.scene ~= "lore1" and inst.scene or nil
end

local function OnLoad(inst, data)--, ents)
	if data then
		if data.id then
			inst:SetId(data.id)
		end
		if data.scene then
			inst:SetScene(data.scene)
		end
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, 0.66)

	inst.AnimState:SetBank("statue_vault")
	inst.AnimState:SetBuild("statue_vault")
	inst.AnimState:PlayAnimation("idle_king")

	inst:AddTag("structure")
	inst:AddTag("statue")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = GetStatus

	inst.id = "king"
	inst.scene = "lore1"

	inst.SetId = SetId
	inst.SetScene = SetScene
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	return inst
end

return Prefab("vault_statue", fn, assets)
