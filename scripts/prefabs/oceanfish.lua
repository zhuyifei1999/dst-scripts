
local FISH_DEFS = 
{
	{ prefab = "oceanfish_medium_4", bank = "oceanfish_medium", build = "oceanfish_medium_4" },
}

local brain = require "brains/oceanfishbrain"


local function HandleEntitySleep(inst)
	local home = inst.components.homeseeker and inst.components.homeseeker.home or nil
	if home == nil or not home:IsValid() then
		inst:Remove()
	end
	inst.remove_task = nil
end

local function OnEntityWake(inst)
	if inst.remove_task ~= nil then
		inst.remove_task:Cancel()
		inst.remove_task = nil
	end
end

local function OnEntitySleep(inst)
	if not POPULATING then
		inst.remove_task = inst:DoTaskInTime(.1, HandleEntitySleep)
	end
end

local function water_common(data)
   local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
	inst.entity:AddPhysics()

	inst.Transform:SetSixFaced()

    inst.Physics:SetMass(5)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:CollidesWith(COLLISION.LAND_OCEAN_LIMITS)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
    inst.Physics:SetCapsule(0.5, 1)

    inst:AddTag("ignorewalkableplatforms")
	inst:AddTag("notarget")
	inst:AddTag("NOCLICK")
	inst:AddTag("NOBLOCK") -- its fine to build things on top of them
	inst:AddTag("oceanfishable")
	inst:AddTag("swimming")

    inst.AnimState:SetBank(data.bank)
    inst.AnimState:SetBuild(data.build)
    inst.AnimState:PlayAnimation("idle_loop")

    inst.AnimState:SetSortOrder(ANIM_SORT_ORDER_BELOW_GROUND.UNDERWATER)
    inst.AnimState:SetLayer(LAYER_BELOW_GROUND)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = 1.5
    inst.components.locomotor.runspeed = 3
	inst.components.locomotor.pathcaps = { allowocean = true, ignoreLand = true }

	inst:AddComponent("knownlocations")

    inst:SetStateGraph("SGoceanfish")
    inst:SetBrain(brain)

	inst.OnEntityWake = OnEntityWake
    inst.OnEntitySleep = OnEntitySleep

    return inst
end

local fish_prefabs = {}

local function MakeFish(data)
	local assets = { Asset("ANIM", "anim/"..data.bank..".zip") }
	if data.bank ~= data.build then 
		table.insert(assets, Asset("ANIM", "anim/"..data.build..".zip"))
	end

	table.insert(fish_prefabs, Prefab(data.prefab, function() return water_common(data) end, assets))
end

for _, fish_def in pairs(FISH_DEFS) do
	MakeFish(fish_def)
end

return unpack(fish_prefabs)