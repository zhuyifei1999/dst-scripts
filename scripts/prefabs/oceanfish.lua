local FISH_DATA = require("prefabs/oceanfishdef")

local SWIMMING_COLLISION_MASK   = COLLISION.GROUND
								+ COLLISION.LAND_OCEAN_LIMITS
								+ COLLISION.OBSTACLES
								+ COLLISION.SMALLOBSTACLES
local PROJECTILE_COLLISION_MASK = COLLISION.GROUND

local function CalcNewSize()
	local p = 2 * math.random() - 1
	return (p*p*p + 1) * 0.5
end

local brain = require "brains/oceanfishbrain"

local function Flop(inst)
	inst.AnimState:PushAnimation("flop_pre", false)
	local num = math.random(3)
	inst.AnimState:PushAnimation("flop_loop", false)
	for i = 1, num do
		inst.AnimState:PushAnimation("flop_loop", false)
	end
	inst.AnimState:PushAnimation("flop_pst", false)

	inst.flop_task = inst:DoTaskInTime(math.random() + 2 + 0.5*num, Flop)
end

local function OnInventoryLanded(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	if TheWorld.Map:IsPassableAtPoint(x, y, z) then
		if inst.flop_task ~= nil then
			inst.flop_task:Cancel()
		end
		inst.flop_task = inst:DoTaskInTime(math.random() + 2 + 0.5*math.random(3), Flop)
	else
		local fish = SpawnPrefab(inst.fish_def.prefab)
		fish.Transform:SetPosition(x, y, z)
		fish.Transform:SetRotation(inst.Transform:GetRotation())
		fish.leaving = true
		fish.persists = false

		SpawnPrefab("splash").Transform:SetPosition(x, y, z)

		inst:Remove()
	end
end

local function onpickup(inst)
	if inst.flop_task ~= nil then
		inst.flop_task:Cancel()
		inst.flop_task = nil
	end
end

local function OnProjectileLand(inst)
	local x, y, z = inst.Transform:GetWorldPosition()

	local land_in_water = not TheWorld.Map:IsPassableAtPoint(x, y, z)
	if land_in_water then
	    inst:RemoveComponent("complexprojectile")
		inst.Physics:SetCollisionMask(SWIMMING_COLLISION_MASK)
		inst.AnimState:SetSortOrder(ANIM_SORT_ORDER_BELOW_GROUND.UNDERWATER)
		inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
		if inst.components.weighable ~= nil then
			inst.components.weighable:SetPlayerAsOwner(nil)
		end
		inst.leaving = true
		inst.persists = false
		inst.sg:GoToState("idle")
		inst:RestartBrain()
	    SpawnPrefab("splash").Transform:SetPosition(x, y, z)
	else
		local fish = SpawnPrefab(inst.fish_def.prefab.."_inv")
		fish.Transform:SetPosition(x, y, z)
		fish.Transform:SetRotation(inst.Transform:GetRotation())
		fish.components.inventoryitem:SetLanded(true, false)
		if fish.flop_task then
			fish.flop_task:Cancel()
		end
		Flop(fish)
		if inst.components.oceanfishable ~= nil and fish.components.weighable ~= nil then
			fish.components.weighable:CopyWeighable(inst.components.weighable)
		end

	    inst:Remove()
	end
end

local function OnMakeProjectile(inst)
    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetOnHit(OnProjectileLand)

	inst:StopBrain()
	inst.sg:GoToState("launched_out_of_water")

	inst.Physics:SetCollisionMask(PROJECTILE_COLLISION_MASK)

    inst.AnimState:SetSortOrder(0)
    inst.AnimState:SetLayer(LAYER_WORLD)

    SpawnPrefab("splash").Transform:SetPosition(inst.Transform:GetWorldPosition())

	return inst
end

local function OnTimerDone(inst, data)
	if data ~= nil and data.name == "lifespan" then
		if inst.components.oceanfishable:GetRod() == nil then
			inst:RemoveComponent("oceanfishable")
			inst.sg:GoToState("leave")
		else
			inst.components.timer:StartTimer("lifespan", 30)
		end
	end
end

local function OnReelingIn(inst, doer)
	if inst:HasTag("partiallyhooked") then
		-- now fully hooked!
		inst:RemoveTag("partiallyhooked")
		inst.components.oceanfishable:ResetStruggling()
        if inst.components.homeseeker ~= nil
                and inst.components.homeseeker.home ~= nil
                and inst.components.homeseeker.home:IsValid()
                and inst.components.homeseeker.home.prefab == "oceanfish_shoalspawner" then
            TheWorld:PushEvent("ms_shoalfishhooked", inst.components.homeseeker.home)
        end
	end
end

local function OnSetRod(inst, rod)
	if rod ~= nil then
		inst:AddTag("partiallyhooked")
		inst:AddTag("scarytooceanprey")
	else
		inst:RemoveTag("partiallyhooked")
		inst:RemoveTag("scarytooceanprey")
	end
end

local function ondroppedasloot(inst, data)
	if data ~= nil and data.dropper ~= nil then
		inst.components.weighable.prefab_override_owner = data.dropper.prefab
	end
end

local function HandleEntitySleep(inst)
	local home = inst.components.homeseeker and inst.components.homeseeker.home or nil
	if home ~= nil and home:IsValid() and not inst.leaving and inst.persists then
		home.components.childspawner:GoHome(inst)
	else
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

local function OnSave(inst, data)
	if inst.components.herdmember.herdprefab then
    	data.herdprefab = inst.components.herdmember.herdprefab
    end
end

local function OnLoad(inst, data)
    if data ~= nil and data.herdprefab ~= nil then
        inst.components.herdmember.herdprefab = data.herdprefab
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

    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
	inst.Physics:SetCollisionMask(SWIMMING_COLLISION_MASK)
    inst.Physics:SetCapsule(0.5, 1)

    inst:AddTag("ignorewalkableplatforms")
	inst:AddTag("notarget")
	inst:AddTag("NOCLICK")
	inst:AddTag("NOBLOCK")
	inst:AddTag("oceanfishable")
	inst:AddTag("oceanfishinghookable")
	inst:AddTag("oceanfish")
	inst:AddTag("swimming")
	inst:AddTag("herd_"..data.prefab)
    inst:AddTag("ediblefish_"..data.fishtype)

    inst.AnimState:SetBank(data.bank)
    inst.AnimState:SetBuild(data.build)
    inst.AnimState:PlayAnimation("idle_loop")

    inst.AnimState:SetSortOrder(ANIM_SORT_ORDER_BELOW_GROUND.UNDERWATER)
    inst.AnimState:SetLayer(LAYER_BELOW_GROUND)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.fish_def = data

	--inst.leaving = nil

    inst:AddComponent("locomotor")
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = data and data.walkspeed or TUNING.OCEANFISH.WALKSPEED
    inst.components.locomotor.runspeed = data and data.runspeed or TUNING.OCEANFISH.RUNSPEED
	inst.components.locomotor.pathcaps = { allowocean = true, ignoreLand = true }

	inst:AddComponent("oceanfishable")
	inst.components.oceanfishable.makeprojectilefn = OnMakeProjectile
	inst.components.oceanfishable.onreelinginfn = OnReelingIn
	inst.components.oceanfishable.onsetrodfn = OnSetRod
	inst.components.oceanfishable:StrugglingSetup(inst.components.locomotor.walkspeed, inst.components.locomotor.runspeed, data.stamina or TUNING.OCEANFISH.FISHABLE_STAMINA)
	inst.components.oceanfishable.catch_distance = TUNING.OCEAN_FISHING.FISHING_CATCH_DIST
	
    inst:AddComponent("eater")
	if data and data.diet then
		inst.components.eater:SetDiet(data.diet.caneat or FOODGROUP.BERRIES_AND_SEEDS, data.diet.preferseating)
	else
		inst.components.eater:SetDiet(FOODGROUP.BERRIES_AND_SEEDS, FOODGROUP.BERRIES_AND_SEEDS)
	end

	inst:AddComponent("knownlocations")

	inst:AddComponent("timer")
	inst:ListenForEvent("timerdone", OnTimerDone)
	--inst.components.timer:StartTimer("lifespan", 30)

    inst:AddComponent("herdmember")
    inst.components.herdmember:Enable(false)

	inst:AddComponent("weighable")
	--inst.components.weighable.type = TROPHYSCALE_TYPES.FISH -- No need to set a weighable type, this is just here for data and will be copied over to the inventory item
	inst.components.weighable:SetWeight(Lerp(inst.fish_def.weight_min, inst.fish_def.weight_max, CalcNewSize()))

    inst:SetStateGraph("SGoceanfish")
    inst:SetBrain(brain)

	inst.OnEntityWake = OnEntityWake
    inst.OnEntitySleep = OnEntitySleep

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

local function inv_common(data)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()    
    MakeInventoryPhysics(inst)

	inst.Transform:SetTwoFaced()

    inst.AnimState:SetBank(data.bank)
    inst.AnimState:SetBuild(data.build)
    inst.AnimState:PlayAnimation("flop_pst")

	inst:SetPrefabNameOverride(data.prefab)

    --weighable_fish (from weighable component) added to pristine state for optimization
	inst:AddTag("weighable_fish")

	inst:AddTag("fish")
	inst:AddTag("oceanfish")
	inst:AddTag("catfood")
	inst:AddTag("smallcreature")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.fish_def = data

	inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem:SetOnPutInInventoryFn(onpickup)
    
    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_ONE_DAY)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = inst.fish_def.perish_product
	
	inst:AddComponent("murderable")

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot(inst.fish_def.loot)

    inst:AddComponent("edible")
	if data.edible_values ~= nil then
		inst.components.edible.healthvalue = data.edible_values.health or TUNING.HEALING_TINY
		inst.components.edible.hungervalue = data.edible_values.hunger or TUNING.CALORIES_SMALL
		inst.components.edible.sanityvalue = data.edible_values.sanity or 0
		inst.components.edible.foodtype = data.edible_values.foodtype or FOODTYPE.MEAT
	else
		inst.components.edible.healthvalue = 0
		inst.components.edible.hungervalue = 0
		inst.components.edible.sanityvalue = 0
		inst.components.edible.foodtype = FOODTYPE.MEAT
	end
	if inst.components.edible.foodtype == FOODTYPE.MEAT then
		--edible.ismeat doesn't appear to actually be used anywhere, might not be necessary.
		inst.components.edible.ismeat = true
	end

	inst:AddComponent("weighable")
	inst.components.weighable.type = TROPHYSCALE_TYPES.FISH
	inst.components.weighable:SetWeight(Lerp(inst.fish_def.weight_min, inst.fish_def.weight_max, CalcNewSize()))

	inst:AddComponent("cookable")
	inst.components.cookable.product = inst.fish_def.cooking_product

    inst:AddComponent("tradable")
    inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.MEAT

	inst.flop_task = inst:DoTaskInTime(math.random() * 2 + 1, Flop)

--    inst:AddComponent("stackable")
--    inst.components.stackable.maxsize = TUNING.STACK_SMALLITEM    

	MakeHauntableLaunchAndPerish(inst)

	inst:ListenForEvent("on_landed", OnInventoryLanded)
	inst:ListenForEvent("animover", function() 
		if inst.AnimState:IsCurrentAnimation("flop_loop") then 
			inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishland")
		end
	end)
	inst:ListenForEvent("on_loot_dropped", ondroppedasloot)

    return inst
end

local fish_prefabs = {}

local function MakeFish(data)
	local assets = { Asset("ANIM", "anim/"..data.bank..".zip"), Asset("SCRIPT", "scripts/prefabs/oceanfishdef.lua"), }
	if data.bank ~= data.build then 
		table.insert(assets, Asset("ANIM", "anim/"..data.build..".zip"))
	end

	local prefabs = {
		data.prefab.."_inv", 
		"schoolherd_"..data.prefab,
		"spoiled_fish", 
		data.cooking_product,
	}
	ConcatArrays(prefabs, data.loot)
	ConcatArrays(prefabs, data.loot)

	table.insert(fish_prefabs, Prefab(data.prefab, function() return water_common(data) end, assets, prefabs))
	table.insert(fish_prefabs, Prefab(data.prefab.."_inv", function() return inv_common(data) end))
end

for _, fish_def in pairs(FISH_DATA.fish) do
	MakeFish(fish_def)
end

return unpack(fish_prefabs)