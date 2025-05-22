local assets =
{
	Asset("ANIM", "anim/mapscroll.zip"),
	Asset("INV_IMAGE", "mapscroll"),
}

local MSG_BASIC = "Thanks for playing the beta!\nBoss final phase and rewards coming soon..."
local MSG_KILLTIME = "\nYou defeated %s in %ds."

local function SetKillTime(inst, killtime)
	inst.killtime = killtime
	inst.components.inspectable:SetDescription(MSG_BASIC..string.format(MSG_KILLTIME, STRINGS.NAMES.WAGBOSS_ROBOT_POSSESSED, killtime))
end

local function OnSave(inst, data)
	data.killtime = inst.killtime
end

local function OnLoad(inst, data)--, ents)
	if data and data.killtime then
		SetKillTime(inst, data.killtime)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("mapscroll")
	inst.AnimState:SetBuild("mapscroll")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem:ChangeImageName("mapscroll")

	inst:AddComponent("inspectable")
	inst.components.inspectable:SetDescription(MSG_BASIC)

	inst:AddComponent("erasablepaper")

	inst:AddComponent("fuel")
	inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

	MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
	MakeSmallPropagator(inst)

	MakeHauntableLaunch(inst)

	inst.SetKillTime = SetKillTime
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	return inst
end

return Prefab("temp_beta_msg", fn, assets)
