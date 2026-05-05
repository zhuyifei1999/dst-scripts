local assets =
{
    Asset("ANIM", "anim/wx78_shadowdrone_debuffer.zip"),
	Asset("ANIM", "anim/wx78_shadowdrone_harvester.zip"),
}

local prefabs =
{
	"globalmapiconunderfog",
}

local brain = require("brains/wx78_shadowdrone_debufferbrain")

local PATHCAPS = { allowocean = true, ignorecreep = true, ignorewalls = true }

local function CreateShadowFx()
	local inst = CreateEntity()

	inst:AddTag("DECOR")
	inst:AddTag("NOCLICK")
	--[[Non-networked entity]]
	--inst.entity:SetCanSleep(false) --commented out; follow parent sleep instead
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()

	inst.AnimState:SetBank("wx78_shadowdrone_harvester")
	inst.AnimState:SetBuild("wx78_shadowdrone_harvester")
	inst.AnimState:PlayAnimation("fx_shadow_loop", true)
	inst.AnimState:SetMultColour(1, 1, 1, 0.5)
	inst.AnimState:UsePointFiltering(true)

	return inst
end

local function OnBuilt(inst, data)
	local builder = data and data.builder
	if builder and builder:IsValid() and builder.components.petleash and builder.components.petleash:AttachPet(inst) then
		inst:PushEventImmediate("spawned")
	else
		inst:AddTag("CLASSIFIED")
		inst:RemoveFromScene()
		inst.persists = false
		inst:DoStaticTaskInTime(0, inst.Remove)
	end
end

local function DoCancelDebuffTarget(inst, target)
	inst.debufftargets[target] = nil
end

local function StopTrackingDebuffTarget(inst, target)
	if inst.debufftargets[target] == true then
		inst.debufftargets[target] = inst:DoTaskInTime(2, DoCancelDebuffTarget, target)
	end
end

local function StartTrackingDebuffTarget(inst, target)
	if Periodic.is_instance(inst.debufftargets[target]) then
		inst.debufftargets[target]:Cancel()
	end
	inst.debufftargets[target] = true
end

local function ClearScanTarget(inst)
	if inst.target then
		inst:RemoveEventCallback("onremove", inst._onscantargetremoved, inst.target)
		inst._onscantargetremoved = nil
		StopTrackingDebuffTarget(inst, inst.target)
		inst.target = nil
    end
end

local function SetScanTarget(inst, target)
	if inst.target == target then
        return
    end

	inst:ClearScanTarget()

    if target and target:IsValid() then
		inst.target = target
		inst._onscantargetremoved = function() inst:ClearScanTarget() end
		inst:ListenForEvent("onremove", inst._onscantargetremoved, target)
		if inst._scanning then
			StartTrackingDebuffTarget(inst, target)
		end
    end
end

local function GetScanTarget(inst)
	return inst.target
end

local function OnStartScanning(inst)
	inst._scanning = true
	if inst.target then
		StartTrackingDebuffTarget(inst, inst.target)
	end
end

local function OnStopScanning(inst)
	inst._scanning = nil
	if inst.target then
		StopTrackingDebuffTarget(inst, inst.target)
	end
end

local function IsApplyingDebuffTo(inst, target)
	return inst.debufftargets[target] ~= nil
end

local function TryToDropRecipeLoot(inst)
    local recipe = AllRecipes.wx78_shadowdrone_debuffer
    if recipe == nil or recipe.ingredients == nil then
        return
    end

    local pt = inst:GetPosition()
	pt.y = pt.y + 2

    local lootdropper = inst.components.lootdropper or inst:AddComponent("lootdropper")
	lootdropper.y_speed = 4
	lootdropper.y_speed_variance = 3
	lootdropper.spawn_loot_inside_prefab = true

    local dropeverything = inst.components.counter:GetCount("interactions") == 0
    for _, ingredient in ipairs(recipe.ingredients) do
        if ingredient.type ~= "nightmarefuel" or dropeverything then
            local amt = (ingredient.amount == 0 and 0) or math.max(1, math.ceil(ingredient.amount * (dropeverything and 1 or 0.5)))
            for _ = 1, amt do
                lootdropper:SpawnLootPrefab(ingredient.type, pt)
            end
        end
    end
end

local function ApplyUse(inst)
    inst.components.counter:Set("interactions", 1)
end

local function OnPlayedFromCat(inst, doer, isairborne)
	if doer and doer:IsValid() and inst:IsNear(doer, 2) then
		inst:PushEvent("deactivate")
	end
end

local function CalcScanRange(inst)
	local bonus = 0
	local owner = inst.components.follower:GetLeader()
	if owner and owner.components.skilltreeupdater then
		if owner.components.skilltreeupdater:IsActivated("wx78_extradronerange") then
			bonus = bonus + TUNING.SKILLS.WX78.SHADOWDRONE_DEBUFFER_SCAN_RANGE_SKILLBOOST
		end
		if owner.components.skilltreeupdater:IsActivated("wx78_circuitry_betabuffs_1") and owner.GetModuleTypeCount then
			bonus = bonus + owner:GetModuleTypeCount("radar") * TUNING.SKILLS.WX78.RADAR_SHADOWDRONE_DEBUFFER_SCAN_RANGE
		end
	end

	return TUNING.SKILLS.WX78.SHADOWDRONE_DEBUFFER_SCAN_RANGE + bonus / 3,
		TUNING.SKILLS.WX78.SHADOWDRONE_DEBUFFER_SCAN_RANGE_MAX + bonus
end

local function OnSave(inst, data)
	data.despawn = inst.sg:HasStateTag("despawn")
end

local function OnLoad(inst, data)--, ents)
	if data and data.despawn then
		inst.sg:GoToState("despawn")
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
	inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

	MakeTinyFlyingCharacterPhysics(inst, 50, 0.1)

	inst.Transform:SetFourFaced()

	inst.MiniMapEntity:SetIcon("wx78_shadowdrone_debuffer.png")
	inst.MiniMapEntity:SetCanUseCache(false)

	inst.DynamicShadow:SetSize(1.2, 0.75)

    inst.AnimState:SetBank("wx78_shadowdrone_debuffer")
    inst.AnimState:SetBuild("wx78_shadowdrone_debuffer")
    inst.AnimState:PlayAnimation("idle_loop", true)
	inst.AnimState:SetSymbolLightOverride("fx_scan_parts", 0.15)
	inst.AnimState:OverrideSymbol("wx78_shadow_explode", "wx78_shadowdrone_harvester", "wx78_shadow_explode")

	inst:AddTag("wx78_shadowdrone")
	inst:AddTag("companion")
	inst:AddTag("scarytoprey")
	inst:AddTag("cattoyairborne")
	inst:AddTag("flying")
	inst:AddTag("NOBLOCK")
	inst:AddTag("shadow_aligned")

	if not TheNet:IsDedicated() then
		inst.fx = CreateShadowFx()
		inst.fx.entity:SetParent(inst.entity)
		inst.fx.Follower:FollowSymbol(inst.GUID, "FOLLOW_SHADOW", 0, 0, 0, true)

		inst:AddComponent("transparentondrones")
	end

    inst.scrapbook_anim = "scrapbook"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.scrapbook_animoffsety = 100

	inst:AddComponent("maprevealable")
	inst.components.maprevealable:SetIconPrefab("globalmapiconunderfog")

    inst:AddComponent("inspectable")

    local locomotor = inst:AddComponent("locomotor")
	locomotor.walkspeed = TUNING.SKILLS.WX78.SHADOWDRONE_DEBUFFER_WALKSPEED
	locomotor.runspeed = TUNING.SKILLS.WX78.SHADOWDRONE_DEBUFFER_RUNSPEED
    locomotor.directdrive = true -- using directdrive to bypass pathfinding
    locomotor:SetExternalSpeedMultiplier(inst, "run_start", 0) -- hack speed mult to prevent run_start from moving right away (see stategraph)
	locomotor:EnableGroundSpeedMultiplier(false)
	locomotor:SetTriggersCreep(false)
	locomotor.pathcaps = PATHCAPS

    local follower = inst:AddComponent("follower")
    follower.keepdeadleader = true
    follower.keepleaderduringminigame = true

    inst:AddComponent("knownlocations")

    inst:AddComponent("counter")

	inst:AddComponent("cattoy")
	inst.components.cattoy:SetOnPlay(OnPlayedFromCat)
	inst.components.cattoy:SetBypassLastAirTime(true)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGwx78_shadowdrone_debuffer")

	inst:ListenForEvent("onbuilt", OnBuilt)

	inst.target = nil
	inst.debufftargets = {}

	inst.SetScanTarget = SetScanTarget
	inst.ClearScanTarget = ClearScanTarget
	inst.GetScanTarget = GetScanTarget
	inst.OnStartScanning = OnStartScanning
	inst.OnStopScanning = OnStopScanning
	inst.IsApplyingDebuffTo = IsApplyingDebuffTo
    inst.TryToDropRecipeLoot = TryToDropRecipeLoot
    inst.ApplyUse = ApplyUse
	inst.CalcScanRange = CalcScanRange
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

    return inst
end

return Prefab("wx78_shadowdrone_debuffer", fn, assets, prefabs)
