local assets =
{
	Asset("ANIM", "anim/hermithouse_ornament_shell.zip"),
}

local prefabs =
{
	"hermithouse_ornament_fx",
}

local function UnlinkHighlight(inst)
	if inst.highlightparent.highlightchildren then
		table.removearrayvalue(inst.highlightparent.highlightchildren, inst)
	end
end

local function LinkHighlight(inst, house)
	if house.highlightchildren == nil then
		house.highlightchildren = { inst }
	else
		table.insert(house.highlightchildren, inst)
	end
	inst.highlightparent = house
	inst.OnRemoveEntity = UnlinkHighlight
end

local function OnEntityReplicated(inst)
	local house = inst.entity:GetParent()
	if house and house:HasTag("hermithouse") then
		LinkHighlight(inst, house)
	end
end

local function dowind(inst)
	if inst.AnimState:IsCurrentAnimation("idle_loop") then
		inst.AnimState:PlayAnimation("wind")
		inst.AnimState:PushAnimation("idle_loop")
	end
end

local function fxfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()
	inst.entity:AddNetwork()

	inst:AddTag("FX")

	inst.AnimState:SetBank("hermithouse_ornament_shell")
	inst.AnimState:SetBuild("hermithouse_ornament_shell")
	inst.AnimState:PlayAnimation("idle_loop", true)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst.OnEntityReplicated = OnEntityReplicated

		return inst
	end

	inst.dowind = dowind

	inst.persists = false

	return inst
end

local function CloneAsFx(inst, house)
	local skin_build = inst:GetSkinBuild()
	local fx = SpawnPrefab("hermithouse_ornament_fx", skin_build, inst.skin_id)
	if POPULATING or house:IsAsleep() then
		fx.AnimState:PlayAnimation("idle_loop", true)
		fx.AnimState:SetFrame(math.random(fx.AnimState:GetCurrentAnimationNumFrames()) - 1)
	else
		fx.AnimState:PlayAnimation("place")
		fx.AnimState:PushAnimation("idle_loop")
	end
	if not TheNet:IsDedicated() then
		LinkHighlight(fx, house)
	end
	return fx
end

local function OnHermitHouseOrnamentSkinChanged(inst, skin_build)
	local owner = inst.components.inventoryitem.owner
	if owner and owner.RefreshDecor then
		owner:RefreshDecor(inst)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst, 0.1)

	inst:AddTag("hermithouse_ornament")
	inst:AddTag("molebait")
	inst:AddTag("cattoy")

	inst.AnimState:SetBank("hermithouse_ornament_shell")
	inst.AnimState:SetBuild("hermithouse_ornament_shell")
	inst.AnimState:PlayAnimation("grounded")

	MakeInventoryFloatable(inst, "small", 0.1, { 1.3, 1, 1 })

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("tradable")
	inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.HERMITHOUSE_ORNAMENT

	MakeHauntableLaunch(inst)

	inst.CloneAsFx = CloneAsFx
	inst.OnHermitHouseOrnamentSkinChanged = OnHermitHouseOrnamentSkinChanged

	return inst
end

return Prefab("hermithouse_ornament", fn, assets, prefabs),
	Prefab("hermithouse_ornament_fx", fxfn)
