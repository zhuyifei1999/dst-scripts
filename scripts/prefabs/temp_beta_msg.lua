local assets =
{
	Asset("ANIM", "anim/mapscroll.zip"),
	Asset("INV_IMAGE", "mapscroll"),
}

local MSG_BASIC = "Thanks for playing the beta!\nBoss final phase and rewards coming soon..."
local MSG_BASIC_NEW = "Thanks for playing the beta!"
local MSG_KILLTIME = "%s\nYou defeated %s in %ds."

local function SetKillTime(inst, killtime, prefabname)
	inst.killtime = killtime
	inst.boss = prefabname
	inst.components.inspectable:SetDescription(
		string.format(MSG_KILLTIME,
			prefabname and MSG_BASIC_NEW or MSG_BASIC,
			STRINGS.NAMES[string.upper(prefabname or "wagboss_robot_possessed")],
			killtime
		)
	)
end

local function OnSave(inst, data)
	data.killtime = inst.killtime
	data.boss = inst.boss
end

local function OnLoad(inst, data)--, ents)
	if data and data.killtime then
		SetKillTime(inst, data.killtime, data.boss)
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
	inst.components.inspectable:SetDescription(MSG_BASIC_NEW)

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
