require "prefabutil"

local wall_prefabs =
{
    "collapse_small",
}

local function GetAnimName(inst, basename)
	if inst.doorpairside == 2 then
		basename = basename .. "right"
	end
	if (inst._isopen and inst._isopen:value()) then
		basename = basename .. "_open"
	end
	return basename
end

local function GetAnimState(inst)
    return (inst.dooranim or inst).AnimState
end

-------------------------------------------------------------------------------
-- Fence/Gate Alignment

local function CalcRotationEnum(rot)
	return ((math.floor(rot + 0.5) / 45) % 4)
end

local function CalcFacingAngle(rot)
	return CalcRotationEnum(rot) * 45 
end

local function FindPairedDoor(inst)
	if inst.doorpairside == nil then
		return nil
	end
	
	local x, y, z = inst.Transform:GetWorldPosition()
	
	local rot = inst.Transform:GetRotation()
	local search_x = -math.sin(rot / RADIANS) * 1.2
	local search_y = math.cos(rot / RADIANS) * 1.2
    
    search_x = x + (inst.doorpairside == 2 and search_x or -search_x)
    search_y = z + (inst.doorpairside == 2 and -search_y or search_y)
    
    local other_door = TheSim:FindEntities(search_x,0,search_y, 0.25, {"wall"})[1]
	return (other_door and other_door.isdoor and other_door.doorpairside ~= inst.doorpairside) and other_door or nil
end

local function GetNeighbors(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	return TheSim:FindEntities(x,0,z, 1.5, {"wall"})
end

local function SetOffset(inst, offset)
    if inst.dooranim ~= nil then
        inst.dooranim.Transform:SetPosition(offset, 0, 0)
    end
end

local function ApplyDoorOffset(inst)
	SetOffset(inst, inst.offsetdoor and 0.45 or 0.05)
end

local function SetOrientation(inst, rotation)
	rotation = CalcFacingAngle(rotation)

	inst.Transform:SetRotation(rotation)
    if inst.dooranim ~= nil then
        inst.dooranim.Transform:SetRotation(rotation)
    end

	if inst.builds.narrow then
		local dir = math.floor(math.abs(rotation) + 0.5) / 45
		if dir % 2 == 0 then
			GetAnimState(inst):SetBuild(inst.builds.narrow)
			GetAnimState(inst):SetBank(inst.builds.narrow)
		else
			GetAnimState(inst):SetBuild(inst.builds.wide)
			GetAnimState(inst):SetBank(inst.builds.wide)
		end
		
		if inst.isdoor then
			ApplyDoorOffset(inst)
		end
	end
end


local function FixUpFenceOrientation2(inst, data) -- work in progress for a much better alignment algorithm
	local neighbors = GetNeighbors(inst)
	if #neighbors <= 1 then
		return
	end
	
	-- find the best orientation
	if inst.doorpairside == nil then
		local rots = {0,0,0,0}
		rots[CalcRotationEnum(inst.Transform:GetRotation())] = 0.1
		for _, v in ipairs(neighbors) do
			local dir = Vector3(inst.Transform:GetWorldPosition()) - Vector3(n.Transform:GetWorldPosition())
			local rot = CalcRotationEnum(math.atan2(dir.x, dir.z) * RADIANS) 
			rots[rot] = dirs[rot] + ((v.isdoor and v.doorpairside == nil) and 1.5 or 1)
		end
		local best_rot = 0
		for i,v in ipairs(rots) do
			if rots[best_rot] < rots[i] then
				best_rot = i
			end
		end
		local orientation = best_rot*45

		if CalcRotationEnum(inst.Transform:GetRotation()) ~= best_rot then
			
		end
		SetOrientation(inst, orientation)
	end
end

local function _calcdooroffset(inst, neighbors)
	if inst == nil or not inst.isdoor then
		return false
	end

	if neighbors == nil then
		neighbors = GetNeighbors(inst)
	end
	
	local has_walls = false
	for i, v in ipairs(neighbors) do
		if not v:HasTag("alignwall") then
			has_walls = true
		end
	end

	return has_walls
end

local function RefreshDoorOffset(inst, neighbors)
	if inst == nil or (not inst.isdoor) or CalcRotationEnum(inst.Transform:GetRotation()) % 2 ~= 0 then
		return
	end
	
	local do_offset = _calcdooroffset(inst, neighbors)
	
	local otherdoor = FindPairedDoor(inst)
	if otherdoor and do_offset == false then
		do_offset = _calcdooroffset(otherdoor)
	end
	
	if inst.offsetdoor ~= do_offset then
		inst.offsetdoor = do_offset
		ApplyDoorOffset(inst)
	end

	if otherdoor and otherdoor.offsetdoor ~= do_offset then
		otherdoor.offsetdoor = do_offset
		ApplyDoorOffset(otherdoor)
	end
	
end

local function FixUpFenceOrientation(inst, deployedrotation)
	local neighbors = GetNeighbors(inst)

	local neighbor = neighbors[1] ~= inst and neighbors[1] or neighbors[2]
	local rot = 0
		
	if neighbor ~= nil then
		local x, y, z = inst.Transform:GetWorldPosition()
		local dir = Vector3(x, 0, z) - Vector3(neighbor.Transform:GetWorldPosition())
		rot = math.atan2(dir.x, dir.z) * RADIANS

		if deployedrotation ~= nil then
			for i = 1, #neighbors do
				local n = neighbors[i]
				if n ~= inst then
					local ndir = Vector3(x, 0, z) - Vector3(n.Transform:GetWorldPosition())
					local nrot = math.atan2(ndir.x, ndir.z) * RADIANS
					
					local n_alignwall = n:HasTag("alignwall")
					if n.isdoor and inst.isdoor and n.doorpairside == nil and inst.doorpairside == nil then
						inst.doorpairside = (ndir.x > 0 or (ndir.x == 0 and ndir.z == 1)) and 2 or 1
						n.doorpairside = inst.doorpairside == 1 and 2 or 1
						GetAnimState(n):PlayAnimation(GetAnimName(n, "idle"))
					end
					if n_alignwall then
						if #GetNeighbors(n) <= 2 then
							SetOrientation(n, nrot)
						end
						if n.isdoor then
							RefreshDoorOffset(n)
							ApplyDoorOffset(n)
						end
					end
				end
			end
		end
	else
		rot = deployedrotation or -TheCamera:GetHeadingTarget()
	end
	
	SetOrientation(inst, rot)
	if deployedrotation ~= nil then
		RefreshDoorOffset(inst)
	end
	GetAnimState(inst):PlayAnimation(GetAnimName(inst, "idle"))
end

local function refreshalignment(inst, data)
	FixUpFenceOrientation(inst, inst.Transform:GetRotation())
end

-------------------------------------------------------------------------------

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
    
    if inst.doorpairside ~= nil then
		local otherdoor = FindPairedDoor(inst)
		if otherdoor then
			otherdoor.doorpairside = nil
			SetOrientation(otherdoor, otherdoor.Transform:GetRotation())
		end
    end
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
	GetAnimState(inst):PlayAnimation(GetAnimName(inst, "hit"))
	GetAnimState(inst):PushAnimation(GetAnimName(inst, "idle"), false)
end

local function onhit(inst, attacker, damage)
	inst.components.workable:WorkedBy(attacker)
end

-------------------------------------------------------------------------------
local function OpenDoor(inst, skiptransition)
	if inst == nil then
		return
	end

    inst._isopen:set(true)
	clearobstacle(inst)

	if not skiptransition then
		inst.SoundEmitter:PlaySound("dontstarve/common/together/gate/open")
	end
	
	GetAnimState(inst):PlayAnimation(GetAnimName(inst, "idle"))
end

local function CloseDoor(inst, skiptransition)
	if inst == nil then
		return
	end

    inst._isopen:set(false)
	makeobstacle(inst)

	if not skiptransition then
		inst.SoundEmitter:PlaySound("dontstarve/common/together/gate/close")
	end
	
	GetAnimState(inst):PlayAnimation(GetAnimName(inst, "idle"))
end

local function ToggleDoor(inst)
	inst.components.activatable.inactive = true

	if inst._isopen:value() then
		CloseDoor(inst)
		CloseDoor(FindPairedDoor(inst))
	else
		OpenDoor(inst)
		OpenDoor(FindPairedDoor(inst))
	end
end

local function getdooractionstring(inst)
    return inst._isopen:value() and "CLOSE" or "OPEN"
end
-------------------------------------------------------------------------------

local function onsave(inst, data)
	local rot = CalcRotationEnum(inst.Transform:GetRotation())
	data.rot = rot > 0 and rot or nil
	data.doorpairside = inst.doorpairside
	data.offsetdoor = inst.offsetdoor
	
	if inst._isopen and inst._isopen:value() then
		data.isopen = true
	end
end

local function onload(inst, data)
    if data ~= nil then
		inst.doorpairside = data.doorpairside
		inst.offsetdoor = data.offsetdoor
		
		local rotation = 0
		if data.rotation ~= nil then
			-- updates save data to new format, safe to remove this when we go out of the beta branch
	        rotation = data.rotation - 90
	    elseif data.rot ~= nil then
		    rotation = data.rot*45
	    end
        SetOrientation(inst, rotation)

  		if data.isopen then
	        OpenDoor(inst, true)
	    elseif inst.doorpairside == 2 then
        	GetAnimState(inst):PlayAnimation(GetAnimName(inst, "idle"))
	    end
    end
end

local function MakeWall(name, builds, isdoor)
    local assets, custom_wall_prefabs

    if isdoor then
        custom_wall_prefabs = { name.."_anim" }
        for i, v in ipairs(wall_prefabs) do
            table.insert(custom_wall_prefabs, v)
        end
    else
        assets =
        {
            Asset("ANIM", "anim/"..builds.wide..".zip"),
        }
        if builds.narrow then
            table.insert(assets, Asset("ANIM", "anim/"..builds.narrow..".zip"))
        end
    end

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
        inst.entity:AddAnimState() --V2C: need this even if we are door, for mouseover sorting
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		inst.Transform:SetEightFaced()

		MakeObstaclePhysics(inst, .5)
		inst.Physics:SetDontRemoveOnSleep(true)

		inst:AddTag("wall")
		inst:AddTag("alignwall")
		inst:AddTag("noauradamage")

		if isdoor then
            inst._isopen = net_bool(inst.GUID, "fence_gate._open")
            inst.GetActivateVerb = getdooractionstring
        else
            inst.AnimState:SetBank(builds.wide)
            inst.AnimState:SetBuild(builds.wide)
            inst.AnimState:PlayAnimation("idle")

            MakeSnowCoveredPristine(inst)
		end

		inst._pfpos = nil
		inst._ispathfinding = net_bool(inst.GUID, "_ispathfinding", "onispathfindingdirty")
		makeobstacle(inst)
		--Delay this because makeobstacle sets pathfinding on by default
		--but we don't to handle it until after our position is set
		inst:DoTaskInTime(0, InitializePathFinding)

		-----------------------------------------------------------------------
		inst.entity:SetPristine()
		if not TheWorld.ismastersim then
			return inst
		end

        if isdoor then
            inst.isdoor = true
            inst.dooranim = SpawnPrefab(name.."_anim")
            inst.dooranim.entity:SetParent(inst.entity)
            inst.highlightforward = inst.dooranim
        end

		inst.builds = builds

		inst:AddComponent("inspectable")
		inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetLoot(
            isdoor and
            { "boards", "boards", "rope" } or
            { "twigs" }
        )

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

		if isdoor then
			inst:AddComponent("activatable")
			inst.components.activatable.OnActivate = ToggleDoor
			inst.components.activatable.standingaction = true
        else
            MakeSnowCovered(inst)
		end

		inst.OnRemoveEntity = onremove

		inst:ListenForEvent("refreshalignment", refreshalignment)

		inst.OnSave = onsave
		inst.OnLoad = onload

		return inst
	end

	return Prefab(name, fn, assets, custom_wall_prefabs or wall_prefabs)
end

-------------------------------------------------------------------------------
local function OnWallAnimReplicated(inst)
    local parent = inst.entity:GetParent()
    if parent ~= nil then
        parent.highlightforward = inst
    end
end

local function MakeWallAnim(name, builds, isdoor)
    local assets =
    {
        Asset("ANIM", "anim/"..builds.wide..".zip"),
    }
    if builds.narrow then
        table.insert(assets, Asset("ANIM", "anim/"..builds.narrow..".zip"))
    end
    
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst.Transform:SetEightFaced()

        inst.AnimState:SetBank(builds.wide)
        inst.AnimState:SetBuild(builds.wide)
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("FX")

        if isdoor then
            inst.AnimState:Hide("mouseover")
        end

        MakeSnowCoveredPristine(inst)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            inst.OnEntityReplicated = OnWallAnimReplicated

            return inst
        end

        MakeSnowCovered(inst)

        inst.persists = false

        return inst
    end
    
    return Prefab(name, fn, assets)
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

	local function ondeploywall(inst, pt, deployer, rot)
		local wall = SpawnPrefab(placement) 
		if wall ~= nil then 
			local x = math.floor(pt.x) + .5
			local z = math.floor(pt.z) + .5

			wall.Physics:SetCollides(false)
			wall.Physics:Teleport(x, 0, z)
			wall.Physics:SetCollides(true)
			inst.components.stackable:Get():Remove()

			FixUpFenceOrientation(wall, rot or 0)

			wall.SoundEmitter:PlaySound("dontstarve/common/place_structure_wood")
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
	
	FixUpFenceOrientation(inst, nil)
end

local function MakeWallPlacer(placer, builds, isdoor)
	local placer = MakePlacer(placer, builds.wide, builds.wide, "idle", nil, nil, true, nil, nil, "eight", 
		function(inst)
			inst.components.placer.oncanbuild = placerupdate
			inst.builds = builds
			inst.isdoor = isdoor -- temp
		end)
	
	return placer
end

return MakeWall("fence", {wide="fence", narrow="fence_thin"}, false),
    MakeInvItem("fence_item", "fence", "fence"),
    MakeWallPlacer("fence_item_placer", {wide="fence"}, false),

	MakeWall("fence_gate", {wide="fence_gate", narrow="fence_gate_thin"}, true),
    MakeWallAnim("fence_gate_anim", {wide="fence_gate", narrow="fence_gate_thin"}, true),
    MakeInvItem("fence_gate_item", "fence_gate", "fence_gate"),
    MakeWallPlacer("fence_gate_item_placer", {wide="fence_gate"}, true)
