local assets =
{
	Asset("ANIM", "anim/marsh_tile.zip"),
	Asset("ANIM", "anim/splash.zip"),
}

local prefabs =
{
	"marsh_plant",
	"fish",
	"frog",
	"mosquito",
}

local function ReturnChildren(inst)
	for k,child in pairs(inst.components.childspawner.childrenoutside) do
		if child.components.homeseeker then
			child.components.homeseeker:GoHome()
		end
		child:PushEvent("gohome")
	end
end

local function SpawnPlants(inst, plantname)

	if inst.decor then
		for i,item in ipairs(inst.decor) do
			item:Remove()
		end
	end
	inst.decor = {}

	local plant_offsets = {}

	for i=1,math.random(2,4) do
		local a = math.random()*math.pi*2
		local x = math.sin(a)*1.9+math.random()*0.3
		local z = math.cos(a)*2.1+math.random()*0.3
		table.insert(plant_offsets, {x,0,z})
	end

	for k, offset in pairs( plant_offsets ) do
		local plant = SpawnPrefab( plantname )
		plant.entity:SetParent( inst.entity )
		plant.Transform:SetPosition( offset[1], offset[2], offset[3] )
		table.insert( inst.decor, plant )
		
		plant:ListenForEvent("onremove", function()
			for k,v in pairs(inst.decor) do
				if v == plant then
					table.remove( inst.decor, k )
					return
				end
			end
		end, plant)
	end
end

local function OnSnowLevel(inst, snowlevel, thresh)
	thresh = thresh or .02

	if snowlevel > thresh and not inst.frozen then
		inst.frozen = true
		inst.AnimState:PlayAnimation("frozen")
		inst.SoundEmitter:PlaySound("dontstarve/winter/pondfreeze")
	    inst.components.childspawner:StopSpawning()
		inst.components.fishable:Freeze()

        inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.WORLD)
        inst.Physics:CollidesWith(COLLISION.ITEMS)

		for i,item in ipairs(inst.decor) do
			if item:IsValid() then
				item:Remove()
			end
		end
		inst.decor = {}
	elseif snowlevel < thresh and inst.frozen then
		inst.frozen = false
		inst.AnimState:PlayAnimation("idle"..inst.pondtype)
	    inst.components.childspawner:StartSpawning()
		inst.components.fishable:Unfreeze()

		inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.WORLD)
        inst.Physics:CollidesWith(COLLISION.ITEMS)
        inst.Physics:CollidesWith(COLLISION.CHARACTERS)

		SpawnPlants(inst, inst.planttype)
	end
end

local function onload(inst, data, newents)
	OnSnowLevel(inst, TheWorld.state.snowlevel)
end

local function commonfn(pondtype)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1.95)

    inst.AnimState:SetBuild("marsh_tile")
    inst.AnimState:SetBank("marsh_tile")
    inst.AnimState:PlayAnimation("idle"..pondtype, true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.MiniMapEntity:SetIcon("pond"..pondtype..".png")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst.pondtype = pondtype

	inst:AddComponent( "childspawner" )
	inst.components.childspawner:SetRegenPeriod(TUNING.POND_REGEN_TIME)
	inst.components.childspawner:SetSpawnPeriod(TUNING.POND_SPAWN_TIME)
	inst.components.childspawner:SetMaxChildren(math.random(3,4))
	inst.components.childspawner:StartRegen()

	inst.frozen = false

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "pond"
    inst.no_wet_prefix = true

	inst:AddComponent("fishable")
	inst.components.fishable:SetRespawnTime(TUNING.FISH_RESPAWN_TIME)

	inst.OnLoad = onload

	return inst
end

local function OnIsDay(inst, isday)
    if isday ~= inst.dayspawn then
        inst.components.childspawner:StopSpawning()
        ReturnChildren(inst)
    elseif not TheWorld.state.iswinter then
        inst.components.childspawner:StartSpawning()
    end
end

local function pondmos()
	local inst = commonfn("_mos")

    if not TheWorld.ismastersim then
        return inst
    end

	inst.components.childspawner.childname = "mosquito"
	inst.components.fishable:AddFish("fish")
	inst.planttype = "marsh_plant"
	SpawnPlants(inst,inst.planttype )

    inst.dayspawn = false
    inst:WatchWorldState("isday", OnIsDay)
	inst:WatchWorldState("snowlevel", OnSnowLevel)

	return inst
end	

local function pondfrog()
	local inst = commonfn("")

    if not TheWorld.ismastersim then
        return inst
    end

	inst.components.childspawner.childname = "frog"
	inst.components.fishable:AddFish("fish")
    inst.planttype = "marsh_plant"
	SpawnPlants(inst, inst.planttype)

    inst.dayspawn = true
    inst:WatchWorldState("isday", OnIsDay)
	inst:WatchWorldState("snowlevel", OnSnowLevel)

	return inst
end

local function pondcave()
	local inst = commonfn("_cave")

    if not TheWorld.ismastersim then
        return inst
    end

	inst.components.fishable:AddFish("eel")
    inst.planttype = "pond_algae"
	SpawnPlants(inst, inst.planttype)

	--These spawn nothing at this time.
	return inst
end

return Prefab("marsh/objects/pond", pondfrog, assets, prefabs),
	  Prefab("marsh/objects/pond_mos", pondmos, assets, prefabs),
	  Prefab("marsh/objects/pond_cave", pondcave, assets, prefabs)