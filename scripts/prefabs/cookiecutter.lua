local assets =
{
	Asset("ANIM", "anim/cookiecutter_build.zip"),
	Asset("ANIM", "anim/cookiecutter.zip"),
	Asset("ANIM", "anim/cookiecutter_water.zip"),
}

local prefabs =
{
    "monstermeat",
	"cookiecuttershell",
	"wood_splinter_jump",
	"wood_splinter_drill",
	"splash",
}

local brain = require("brains/cookiecutterbrain")

local sounds =
{
    attack = "saltydog/creatures/cookiecutter/attack",
	eat = "saltydog/creatures/cookiecutter/eat_LP",
	eat_item = "saltydog/creatures/cookiecutter/bite",
	eat_finish = "saltydog/creatures/cookiecutter/attack",
	jump = "turnoftides/common/together/water/splash/jump_small",
	splash = "turnoftides/common/together/water/splash/small",
	land = "turnoftides/common/together/boat/damage_small",
	hit = "saltydog/creatures/cookiecutter/hit",
    death = "saltydog/creatures/cookiecutter/death",
}

SetSharedLootTable("cookiecutter",
{
    {"monstermeat",			1.0},
    {"cookiecuttershell",	1.0},
})

local function OnAttacked(inst, data)
	inst.target_boat = nil

	inst.attackdata.wants_to_attack = true
	inst.is_fleeing = true
	inst:AddTag("scarytocookiecutters")
	if inst.flee_task ~= nil then
		inst.flee_task:Cancel()
	end
	inst.flee_task = inst:DoTaskInTime(TUNING.COOKIECUTTER.FLEE_DURATION, function()
		inst.is_fleeing = false
		inst:RemoveTag("scarytocookiecutters")
	end)
end

local function DoReturn(inst)
	local home = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
	if home ~= nil then
		home.components.childspawner:GoHome(inst)
	else
		inst:Remove()
	end
end

local function OnEntitySleep(inst)
    DoReturn(inst)
end

local function SetSortOrderIsInWater(inst, inwater)
	if inwater then
		inst.AnimState:SetSortOrder(ANIM_SORT_ORDER_BELOW_GROUND.BOAT_LIP)
		inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
	else
		inst.AnimState:SetSortOrder(0)
		inst.AnimState:SetLayer(LAYER_WORLD)
	end
end

local function OnSave(inst, data)
	data.submerged = inst:HasTag("submerged")
end

local function OnLoad(inst, data)
	if data.submerged then
		inst:PushEvent("onsubmerge")
	end
end

local function OnSink(inst)
	inst:ClearBufferedAction()
	inst.Physics:SetActive(true)
	inst.Physics:CollidesWith(COLLISION.CHARACTERS)
	inst.should_drill = false
	if inst.SoundEmitter:PlayingSound("eat_LP") then inst.SoundEmitter:KillSound("eat_LP") end
	inst.sg:GoToState("idle")
end

local function OnTeleported(inst)
	inst.components.amphibiouscreature:OnExitOcean()
end

local function OnResurface(inst)
	local resurfacepoint = inst.components.knownlocations:GetLocation("resurfacepoint")
		or inst.components.knownlocations:GetLocation("home")
		or inst:GetPosition()
	local rand = math.random()
	local offset = FindSwimmableOffset(resurfacepoint, math.random() * PI * 2, (1 - rand * rand) * TUNING.COOKIECUTTER.MAX_RESURFACE_RADIUS + inst:GetPhysicsRadius(0), 8, false, true)

	if offset ~= nil then
		inst.is_fleeing = false

		inst.should_drill = false
		inst.should_start_drilling = false

		inst:RemoveTag("submerged")

		inst.Transform:SetPosition(resurfacepoint.x + offset.x, 0, resurfacepoint.z + offset.z)
		inst.Physics:CollidesWith(COLLISION.CHARACTERS)
		inst:ReturnToScene()

		inst:setsortorderisinwaterfn(true)
		inst.sg:GoToState("surface")
	else
		-- Try again with delay
		inst:DoTaskInTime(1, OnResurface)
	end
end

local function OnSubmerge(inst)
	inst.should_drill = false
	inst.should_start_drilling = false
	inst:AddTag("submerged")
	inst:DoTaskInTime(TUNING.COOKIECUTTER.RESURFACE_DELAY, OnResurface)
	inst.sg:GoToState("idle")
	inst:RemoveFromScene()
end

local function CheckForBoats(inst)
	if inst.is_fleeing or (inst.components.eater ~= nil and not inst.components.eater:HasBeen(TUNING.COOKIECUTTER.EAT_DELAY)) then
		inst.target_boat = nil

		return
	end

	local dist = TUNING.COOKIECUTTER.BOAT_DETECTION_DIST

	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, dist, { "boat" })

	if #ents > 0 then
		local smallest_sqdist = dist * dist + 1
		local bx, by, bz, delta_sqdist
		local target_boat = nil
		for _,v in pairs(ents) do
			bx, by, bz = v.Transform:GetWorldPosition()
			delta_sqdist = (x - bx) * (x - bx) + (z - bz) * (z - bz)

			if delta_sqdist < smallest_sqdist then
				smallest_sqdist = delta_sqdist
				target_boat = v
			end
		end

		inst.target_boat = target_boat
	else
		inst.target_boat = nil
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 10, .5)
	inst:SetPhysicsRadiusOverride(.5)

    inst.Transform:SetSixFaced()

    inst:AddTag("monster")
	inst:AddTag("smallcreature")
    inst:AddTag("hostile")
	inst:AddTag("cookiecutter")

	local bank_land = "cookiecutter"
	local bank_water = "cookiecutter_water"
    inst.AnimState:SetBank(bank_water)
    inst.AnimState:SetBuild("cookiecutter_build")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.sounds = sounds

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.runspeed = TUNING.COOKIECUTTER.RUN_SPEED
	inst.components.locomotor.walkspeed = TUNING.COOKIECUTTER.WANDER_SPEED
	inst.components.locomotor.hop_distance = 2

	inst:SetStateGraph("SGcookiecutter")

	inst:AddComponent("embarker")
	inst.components.embarker.embark_speed = 5.8
	inst.components.embarker.antic = true
	inst.components.embarker.embarker_min_dist = TUNING.COOKIECUTTER.BOARDING_DISTANCE + math.random() * TUNING.COOKIECUTTER.BOARDING_DISTANCE_VARIANCE

	inst.components.locomotor:SetAllowPlatformHopping(false)

	inst:AddComponent("amphibiouscreature")
	inst.components.amphibiouscreature:SetBanks(bank_land, bank_water)
    inst.components.amphibiouscreature:SetEnterWaterFn(
        function(inst)
			inst.components.locomotor.runspeed = TUNING.COOKIECUTTER.RUN_SPEED
			inst.should_drill = false
			inst.components.embarker.embarker_min_dist = TUNING.COOKIECUTTER.BOARDING_DISTANCE + math.random() * TUNING.COOKIECUTTER.BOARDING_DISTANCE_VARIANCE
        end)
    inst.components.amphibiouscreature:SetExitWaterFn(
        function(inst)
			local x, y, z = inst.Transform:GetWorldPosition()
			if TheWorld.Map:GetPlatformAtPoint(x, z) ~= nil then
				inst.should_drill = true
				inst.should_start_drilling = true
			else
				if inst.components.health then
					inst.components.health:Kill()
				end
			end
        end)

	inst.components.locomotor.pathcaps = { allowocean = true, ignoreLand = true }

	inst.setsortorderisinwaterfn = SetSortOrderIsInWater
	inst:setsortorderisinwaterfn(true)

	inst.doreturnfn = DoReturn

	inst:AddComponent("knownlocations")

    inst:SetBrain(brain)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.COOKIECUTTER.HEALTH)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:AddComponent("combat")
    inst.components.combat:SetHurtSound(inst.sounds.hit)
	inst.components.combat.defaultdamage = TUNING.COOKIECUTTER.DAMAGE
	
	inst.attackdata = {
		wants_to_attack = false,
		on_cooldown = false,

		cooldown_duration = TUNING.COOKIECUTTER.ATTACK_PERIOD,
	}


    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("cookiecutter")

    inst:AddComponent("inspectable")

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.WOOD }, { FOODTYPE.WOOD })
    
	inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)
	inst.components.sleeper.sleeptestfn = nil -- they don't sleep at night or day

	inst:AddComponent("cookiecutterdrill")

	inst:DoTaskInTime(0, function()
		local x, y, z = inst.Transform:GetWorldPosition()
		if TheWorld.Map:GetPlatformAtPoint(x, z) ~= nil then
			inst.components.amphibiouscreature:OnExitOcean(inst)
			inst.Physics:SetActive(false)-- Physics normally turn off in the jump_pst animation on the frame of landing.
			inst.sg:GoToState("idle")
		elseif TheWorld.Map:IsVisualGroundAtPoint(inst.Transform:GetWorldPosition()) then
			if inst.components.health then
				inst.components.health:Kill()
			end
		else
			inst.components.amphibiouscreature:OnEnterOcean(inst)
		end
	end)

	inst:DoPeriodicTask(.25, CheckForBoats)

	inst.no_wet_prefix = true

	inst.OnEntitySleep = OnEntitySleep

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("onsink", OnSink)
	inst:ListenForEvent("teleported", OnTeleported)
	inst:ListenForEvent("onsubmerge", OnSubmerge)
	inst:ListenForEvent("onresurface", OnResurface)

    return inst
end

return Prefab("cookiecutter", fn, assets, prefabs)
