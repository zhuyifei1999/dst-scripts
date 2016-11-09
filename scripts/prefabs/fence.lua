require "prefabutil"

local wall_prefabs =
{
    "collapse_small",
}

local fencebank = "fence"

local function FixUpFenceOrientation(inst, deployed)
	local x, y, z = inst.Transform:GetWorldPosition()
	local neighbors = TheSim:FindEntities(x,0,z, 1.5, {"wall"})

	local neighbor = neighbors[1] ~= inst and neighbors[1] or neighbors[2]
	local rot = 0
	
	if neighbor ~= nil then
		local dir = Vector3(x, 0, z) - Vector3(neighbor.Transform:GetWorldPosition())
		rot = math.atan2(dir.x, dir.z) * RADIANS

		if deployed then -- if deployed beside another wall, then mark this as isaligned. If the other wall is not aligned then align it
			inst.isaligned = true
			for i = 2, #neighbors do
				local n = neighbors[i]
				if (not n.isaligned) and n:HasTag("alignwall") then
					n.Transform:SetRotation(rot + 90)
					n.AnimState:PlayAnimation("idle")
					n.isaligned = true
				end
			end
		end
	else
		rot = -TheCamera:GetHeadingTarget()
	end
	
	inst.Transform:SetRotation(rot + 90)
	inst.AnimState:PlayAnimation("idle")
end

local function OnIsPathFindingDirty(inst)
    if inst._ispathfinding:value() then
        if inst._pfpos == nil then
            inst._pfpos = inst:GetPosition()
            TheWorld.Pathfinder:AddWall(inst._pfpos:Get())
        end
    elseif inst._pfpos ~= nil then
        TheWorld.Pathfinder:RemoveWall(inst._pfpos:Get())
        inst._pfpos = nil
    end
end

local function InitializePathFinding(inst)
    inst:ListenForEvent("onispathfindingdirty", OnIsPathFindingDirty)
    OnIsPathFindingDirty(inst)
end

local function makeobstacle(inst)
    inst.Physics:SetActive(true)
    inst._ispathfinding:set(true)
end

local function clearobstacle(inst)
    inst.Physics:SetActive(false)
    inst._ispathfinding:set(false)
end

local function onremove(inst)
    inst._ispathfinding:set_local(false)
    OnIsPathFindingDirty(inst)
end

local function keeptargetfn()
    return false
end

local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")

    inst:Remove()
end

local function onworked(inst)
	inst.AnimState:PlayAnimation((inst._isopen and inst._isopen:value()) and "hit_open" or "hit")
end

local function onhit(inst, attacker, damage)
	inst.components.workable:WorkedBy(attacker)
end

-------------------------------------------------------------------------------
local function OpenDoor(inst, skiptransition)
    inst._isopen:set(true)
	clearobstacle(inst)

	if not skiptransition then
		inst.SoundEmitter:PlaySound("dontstarve/common/together/gate/open")
	end
	
	inst.AnimState:PlayAnimation("idle_open")
end

local function CloseDoor(inst, skiptransition)
    inst._isopen:set(false)
	makeobstacle(inst)

	if not skiptransition then
		inst.SoundEmitter:PlaySound("dontstarve/common/together/gate/close")
	end
	
	inst.AnimState:PlayAnimation("idle")
end

local function ToggleDoor(inst)
	inst.components.activatable.inactive = true
	if inst._isopen:value() then
		CloseDoor(inst)
	else
		OpenDoor(inst)
	end
end

local function getdooractionstring(inst)
    return inst._isopen:value() and "CLOSE" or "OPEN"
end
-------------------------------------------------------------------------------

local function onsave(inst, data)
	if inst.isaligned then
		data.rotation = inst.Transform:GetRotation()
	end
	
	if inst._isopen and inst._isopen:value() then
		data.isopen = true
	end
end

local function onload(inst, data)
    if data ~= nil then
		if data.rotation ~= nil then
			inst.isaligned = true
	        inst.Transform:SetRotation(data.rotation)
	    end

  		if data.isopen then
	        OpenDoor(inst, true)
	    end
    end
end

local function MakeWall(name, animdata, isdoor)
	local assets =
	{
		Asset("ANIM", "anim/"..animdata..".zip"),
	}

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		inst.Transform:SetEightFaced()

		MakeObstaclePhysics(inst, .5)
		inst.Physics:SetDontRemoveOnSleep(true)

		inst:AddTag("wall")
		inst:AddTag("alignwall")
		inst:AddTag("noauradamage")

		inst.AnimState:SetBank(animdata)
		inst.AnimState:SetBuild(animdata)
		inst.AnimState:PlayAnimation("idle")

		if isdoor then
            inst.AnimState:Hide("mouseover")
			inst.AnimState:SetFinalOffset(1)
            inst._isopen = net_bool(inst.GUID, "fence_gate._open")
		end

		MakeSnowCoveredPristine(inst)

		if isdoor then
		    inst.GetActivateVerb = getdooractionstring
		end

		inst._pfpos = nil
		inst._ispathfinding = net_bool(inst.GUID, "_ispathfinding", "onispathfindingdirty")
		makeobstacle(inst)
		--Delay this because makeobstacle sets pathfinding on by default
		--but we don't to handle it until after our position is set
		inst:DoTaskInTime(0, InitializePathFinding)

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("inspectable")
		inst:AddComponent("lootdropper")
		if isdoor then
		    inst.components.lootdropper:SetLoot({"boards", "boards", "rope"})
		else
		    inst.components.lootdropper:SetLoot({"twigs"})
		end

		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
		inst.components.workable:SetWorkLeft(3)
		inst.components.workable:SetOnFinishCallback(onhammered)
		inst.components.workable:SetOnWorkCallback(onworked)
		

        inst:AddComponent("combat")
        inst.components.combat:SetKeepTargetFunction(keeptargetfn)
        inst.components.combat.onhitfn = onhit

        inst:AddComponent("health")
        inst.components.health:SetMaxHealth(1)
        inst.components.health:SetAbsorptionAmount(1)
        inst.components.health:SetAbsorptionAmountFromPlayer(1)
		inst.components.health.fire_damage_scale = 0
        inst.components.health.canheal = false

        MakeMediumBurnable(inst)
        MakeMediumPropagator(inst)
        inst.components.burnable.flammability = .5
        MakeDragonflyBait(inst, 3)

		MakeHauntableWork(inst)
		MakeSnowCovered(inst)
		
		if isdoor then
			inst:AddComponent("activatable")
			inst.components.activatable.OnActivate = ToggleDoor
			inst.components.activatable.standingaction = true
		end

		inst.OnRemoveEntity = onremove

		inst.OnSave = onsave
		inst.OnLoad = onload

		return inst
	end
	
	return Prefab(name, fn, assets, wall_prefabs)
end

-------------------------------------------------------------------------------
local function MakeInvItem(name, placement, animdata)
	local assets =
	{
		Asset("ANIM", "anim/"..animdata..".zip"),
	}
	local item_prefabs =
	{
		placement,
	}

	local function ondeploywall(inst, pt, deployer)
		--inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spider_egg_sack")

		local wall = SpawnPrefab(placement) 
		if wall ~= nil then 
			local x = math.floor(pt.x) + .5
			local z = math.floor(pt.z) + .5

			wall.Physics:SetCollides(false)
			wall.Physics:Teleport(x, 0, z)
			wall.Physics:SetCollides(true)
			inst.components.stackable:Get():Remove()

			FixUpFenceOrientation(wall, true)

			TheWorld.Pathfinder:AddWall(x, 0, z)
		end
	end

	local function itemfn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		MakeInventoryPhysics(inst)

		inst:AddTag("wallbuilder")

		inst.AnimState:SetBank(animdata)
		inst.AnimState:SetBuild(animdata)
		inst.AnimState:PlayAnimation("inventory")

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("stackable")
		inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

		inst:AddComponent("inspectable")
		inst:AddComponent("inventoryitem")

		inst:AddComponent("deployable")
		inst.components.deployable.ondeploy = ondeploywall
		inst.components.deployable:SetDeployMode(DEPLOYMODE.WALL)

        MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
        MakeSmallPropagator(inst)

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

        MakeDragonflyBait(inst, 3)

		MakeHauntableLaunch(inst)

		return inst
	end
    
    return Prefab(name, itemfn, assets, item_prefabs)
end


-------------------------------------------------------------------------------
local function placerupdate(inst)
	inst.AnimState:SetAddColour(.25, .75, .25, 0)
	
	FixUpFenceOrientation(inst, false)
end

return MakeWall("fence", "fence", false),
    MakeInvItem("fence_item", "fence", "fence"),
    MakePlacer("fence_item_placer", "fence", "fence", "idle", nil, nil, true, nil, nil, "eight", function(inst) inst.components.placer.oncanbuild = placerupdate end),

	MakeWall("fence_gate", "fence_gate", true),
    MakeInvItem("fence_gate_item", "fence_gate", "fence_gate"),
    MakePlacer("fence_gate_item_placer", "fence_gate", "fence_gate", "idle", nil, nil, true, nil, nil, "eight", function(inst) inst.components.placer.oncanbuild = placerupdate end)
