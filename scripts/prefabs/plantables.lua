require "prefabutil"

local function make_plantable(data)

	local assets =
	{
		Asset("ANIM", "anim/"..data.name..".zip"),
	}

	if data.build ~= nil then
		table.insert(assets, Asset("ANIM", "anim/"..data.build..".zip"))
	end

	local function ondeploy(inst, pt)
		local tree = SpawnPrefab(data.name) 
		if tree ~= nil then 
			tree.Transform:SetPosition(pt:Get())
			inst.components.stackable:Get():Remove()
			tree.components.pickable:OnTransplant()
		end 
	end
	
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		--inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

		MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(data.bank or data.name)
        inst.AnimState:SetBuild(data.build or data.name)
        inst.AnimState:PlayAnimation("dropped")

        if not TheWorld.ismastersim then
            return inst
        end

        inst.entity:SetPristine()

        inst:AddComponent("stackable")
		inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

		inst:AddComponent("inspectable")
		inst.components.inspectable.nameoverride = data.inspectoverride or "dug_"..data.name
		inst:AddComponent("inventoryitem")

		inst:AddComponent("fuel")
		inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

        MakeMediumBurnable(inst, TUNING.LARGE_BURNTIME)
		MakeSmallPropagator(inst)

		MakeHauntableLaunchAndIgnite(inst)

	    inst:AddComponent("deployable")
	    --inst.components.deployable:SetDeployMode(DEPLOYMODE.ANYWHERE)
	    inst.components.deployable.ondeploy = ondeploy
	    inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
        if data.mediumspacing then
            inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.MEDIUM)
        end

	    inst:AddComponent("edible")
	    inst.components.edible.foodtype = FOODTYPE.WOOD
	    inst.components.edible.woodiness = 10

		---------------------  
		return inst      
	end

	return Prefab("common/objects/dug_"..data.name, fn, assets)
end

local plantables = 
{
	{name="berrybush", anim="idle_dead"},
	{name="berrybush2", bank = "berrybush", inspectoverride = "dug_berrybush", anim = "idle_dead"},
	{name="sapling", mediumspacing=true},
	{name="grass", build="grass1", mediumspacing=true},
    {name="marsh_bush", mediumspacing=true},
	--"reeds",
}

local prefabs= {}
for k,v in pairs(plantables) do
	table.insert(prefabs, make_plantable(v))
	table.insert(prefabs, MakePlacer("common/dug_"..v.name.."_placer", v.bank or v.name, v.build or v.name, v.anim or "idle"))
end

return unpack(prefabs)