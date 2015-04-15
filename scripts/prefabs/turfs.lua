require "prefabutil"

local function ondeploy(inst, pt, deployer)
	if deployer and deployer.SoundEmitter then
		deployer.SoundEmitter:PlaySound("dontstarve/wilson/dig")
	end

	local map = TheWorld.Map
	local original_tile_type = map:GetTileAtPoint(pt:Get())
	local x, y = map:GetTileCoordsAtPoint(pt:Get())
	if x and y then
		map:SetTile(x,y, inst.data.tile)
		map:RebuildLayer( original_tile_type, x, y )
		map:RebuildLayer( inst.data.tile, x, y )
	end

	local minimap = TheWorld.minimap.MiniMap
	minimap:RebuildLayer(original_tile_type, x, y)
	minimap:RebuildLayer(inst.data.tile, x, y)

	inst.components.stackable:Get():Remove()
end

local assets =
{
    Asset("ANIM", "anim/turf.zip"),
}

local prefabs =
{
    "gridplacer",
}

local function make_turf(data)
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
        inst.entity:AddNetwork()

		MakeInventoryPhysics(inst)

        inst:AddTag("groundtile")

        inst.AnimState:SetBank("turf")
        inst.AnimState:SetBuild("turf")
        inst.AnimState:PlayAnimation(data.anim)

        if not TheWorld.ismastersim then
            return inst
        end

        inst.entity:SetPristine()
	    
        inst:AddComponent("stackable")
		inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

		inst:AddComponent("inspectable")
		inst:AddComponent("inventoryitem")
		inst.data = data

		inst:AddComponent("fuel")
		inst.components.fuel.fuelvalue = TUNING.MED_FUEL
        MakeMediumBurnable(inst, TUNING.MED_BURNTIME)
		MakeSmallPropagator(inst)
		MakeHauntableLaunchAndIgnite(inst)

	    inst:AddComponent("deployable")
	    --inst.components.deployable:SetDeployMode(DEPLOYMODE.ANYWHERE)
	    inst.components.deployable.ondeploy = ondeploy
        if data.tile == "webbing" then
            inst.components.deployable:SetDeployMode(DEPLOYMODE.ANYWHERE)
        else
            inst.components.deployable:SetDeployMode(DEPLOYMODE.TURF)
        end
	    inst.components.deployable:SetUseGridPlacer(true)

		---------------------
		return inst      
	end

	return Prefab("common/objects/turf_"..data.name, fn, assets, prefabs)
end

local turfs =
{
	{name="road",			anim="road",		tile=GROUND.ROAD},
	{name="rocky",			anim="rocky",		tile=GROUND.ROCKY},
	{name="forest",			anim="forest",		tile=GROUND.FOREST},
	{name="marsh",			anim="marsh",		tile=GROUND.MARSH},
	{name="grass",			anim="grass",		tile=GROUND.GRASS},
	{name="savanna",		anim="savanna",		tile=GROUND.SAVANNA},
	{name="dirt",			anim="dirt",		tile=GROUND.DIRT},
	{name="woodfloor",		anim="woodfloor",	tile=GROUND.WOODFLOOR},
	{name="carpetfloor",	anim="carpet",		tile=GROUND.CARPET},
	{name="checkerfloor",	anim="checker",		tile=GROUND.CHECKER},

	{name="cave",			anim="cave",		tile=GROUND.CAVE},
	{name="fungus",			anim="fungus",		tile=GROUND.FUNGUS},
    {name="fungus_red",		anim="fungus_red",	tile=GROUND.FUNGUSRED},
	{name="fungus_green",	anim="fungus_green",tile=GROUND.FUNGUSGREEN},

	{name="sinkhole",		anim="sinkhole",	tile=GROUND.SINKHOLE},
	{name="underrock",		anim="rock",		tile=GROUND.UNDERROCK},
	{name="mud",			anim="mud",			tile=GROUND.MUD},
}

local prefabs= {}
for k,v in pairs(turfs) do
	table.insert(prefabs, make_turf(v))
end

return unpack(prefabs)