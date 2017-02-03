local assets =
{
    Asset("ANIM", "anim/oasis_tile.zip"),
    Asset("ANIM", "anim/splash.zip"),
    Asset("MINIMAP_IMAGE", "oasis"),
}

local prefabs =
{
    "fish",
    "wetpouch",
}

local WATER_RADIUS = 3.8

local NUM_BUGS = 3
local BUG_OFFSET = 1.4
local BUG_RANDOM_RANGE = .5
local function SpawnOasisBugs(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, BUG_OFFSET + BUG_RANDOM_RANGE + 0.1)
	local bug_pts = {}
	for k,ent in ipairs(ents) do
		if ent.prefab == "fireflies" then
			table.insert(bug_pts, ent:GetPosition())
		end
	end

	local pos = inst:GetPosition()
	local offset = nil
	for i = #bug_pts + 1, NUM_BUGS do
		if i == 1 then
			offset = Vector3(BUG_OFFSET, 0, 0)
		elseif i == 2 then
			local dir = bug_pts[1] - pos
			local ca = math.cos(0.33*2*PI);
			local sa = math.sin(0.33*2*PI);
			offset = Vector3(ca*dir.x - sa*dir.y, 0, sa*dir.x + ca*dir.y):Normalize() * BUG_OFFSET
		elseif i == 3 then
			offset = Vector3(0,0,0)
			for _,pt in ipairs(bug_pts) do
				offset = offset + (pt - pos)
			end
			offset = offset:Normalize() * BUG_OFFSET
			offset.x = -offset.x
			offset.z = -offset.z
		end

	    local bug = SpawnPrefab("fireflies")
	    bug.Transform:SetPosition((pos + offset + Vector3(math.random()*BUG_RANDOM_RANGE, 0, math.random()*BUG_RANDOM_RANGE)):Get())
	    table.insert(bug_pts, bug:GetPosition())
	end	
end

local MAX_SUCCULENTS = 18
local SUCCULENT_RANGE = 15
local SUCCULENT_RANGE_MIN = WATER_RADIUS + 0.5

local function SpawnSucculents(inst)
	local pt = inst:GetPosition()

	local function noentcheckfn(offset)
		return #(TheSim:FindEntities(pt.x + offset.x, pt.y + offset.y, pt.z + offset.z, 2)) == 0
	end

	local succulents_to_spawn = MAX_SUCCULENTS - #(TheSim:FindEntities(pt.x, pt.y, pt.z, SUCCULENT_RANGE, {"succulent"})) 
	for i = 1, succulents_to_spawn do
		local offset = FindWalkableOffset(pt, math.random()*2*PI, GetRandomMinMax(SUCCULENT_RANGE_MIN, SUCCULENT_RANGE), 10, false, true)
		if offset ~= nil then
			local plant = SpawnPrefab("succulent_plant")
			plant.Transform:SetPosition((pt + offset):Get())
			plant.AnimState:PlayAnimation("place")
			plant.AnimState:PushAnimation("idle", false)
		end
	end
end

local function HasPhysics(obj)
    return obj.Physics ~= nil
end

local function DisableLake(inst)
    inst.components.fishable:Freeze()

	inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(COLLISION.WORLD)
	inst.Physics:CollidesWith(COLLISION.ITEMS)

	inst:RemoveTag("watersource")
    inst:AddTag("NOCLICK")
end

local function UpdateLakeState(inst, skipanim)
    if TheWorld.state.issummer then
        if inst.driedup ~= false then
            if FindEntity(inst, WATER_RADIUS, HasPhysics, nil, { "FX", "NOCLICK", "DECOR", "INLIMBO", "playerghost", "ghost", "flying", "structure" }) ~= nil then
				--Something is on top of us, reschedule filling up...
				inst:DoTaskInTime(5, UpdateLakeState)
				return
			end

            if skipanim then
				inst.AnimState:PlayAnimation("idle", true)
			else
				if inst.isdamp then
					inst.AnimState:PlayAnimation("dry_pst")
				else
					inst.AnimState:PlayAnimation("dry_pst")
				end
				inst.AnimState:PushAnimation("idle")
			end

			inst.isdamp = false
            inst.driedup = false

			inst.components.fishable:Unfreeze()
            SpawnOasisBugs(inst)
            SpawnSucculents(inst)

			inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
			inst.Physics:ClearCollisionMask()
			inst.Physics:CollidesWith(COLLISION.WORLD)
			inst.Physics:CollidesWith(COLLISION.ITEMS)
			inst.Physics:CollidesWith(COLLISION.CHARACTERS)

			inst:AddTag("watersource")
            inst:RemoveTag("NOCLICK")
		end
--[[
	elseif TheWorld.state.iswet ~= inst.isdamp then
        inst.isdamp = true
		if not inst.driedup then
	        inst.driedup = true
			DisableLake(inst)

			if skipanim then
				inst.AnimState:PlayAnimation("wet", true)
			else
				inst.AnimState:PlayAnimation("dry_pre")
				inst.AnimState:PushAnimation("wet")
			end
	    else
			inst.AnimState:PlayAnimation("wet", true)
	    end
]]
    elseif not inst.driedup then
        inst.driedup = true
        inst.isdamp = false

		DisableLake(inst)
		
		if skipanim then
			inst.AnimState:PlayAnimation("dry_idle", true)
		else
			inst.AnimState:PlayAnimation("dry_pre")
			inst.AnimState:PushAnimation("dry_idle")
		end
    end
end

local function OnWorldStateChanged(inst)
	UpdateLakeState(inst, false)
end

local function GetFish(inst)
	return math.random() < 0.6 and "wetpouch" or "fish"
end

local function OnInit(inst)
    inst.task = nil
    inst:WatchWorldState("issummer", OnWorldStateChanged)
    inst:WatchWorldState("iswet", OnWorldStateChanged)
    UpdateLakeState(inst, true)
end

local function GetStatus(inst)
    return inst.driedup and "EMPTY" or nil
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

	inst.Transform:SetRotation(45)

    MakeObstaclePhysics(inst, 6)

    inst.AnimState:SetBuild("oasis_tile")
    inst.AnimState:SetBank("oasis_tile")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(2)

    inst.MiniMapEntity:SetIcon("oasis.png")

    inst:AddTag("watersource")
    inst:AddTag("birdblocker")
    inst:AddTag("antlion_sinkhole_blocker")

    inst.no_wet_prefix = true

    inst.deploy_spacing = 6

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("fishable")
    inst.components.fishable.maxfish = TUNING.OASISLAKE_MAX_FISH
    inst.components.fishable:SetRespawnTime(TUNING.OASISLAKE_FISH_RESPAWN_TIME)
    inst.components.fishable:SetGetFishFn(GetFish)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:AddComponent("oasis")
    inst.components.oasis.radius = TUNING.SANDSTORM_OASIS_RADIUS

	inst.isdamp = false

    TheWorld:PushEvent("ms_registeroasis", inst)
    inst.task = inst:DoTaskInTime(0, OnInit)

    return inst
end

return Prefab("oasislake", fn, assets, prefabs)
