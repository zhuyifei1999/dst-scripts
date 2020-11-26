local assets =
{
    Asset("ANIM", "anim/soil_amender.zip"),
	Asset("INV_IMAGE", "soil_amender_stale"),
	Asset("INV_IMAGE", "soil_amender_spoiled"),
	Asset("SCRIPT", "scripts/prefabs/fertilizer_nutrient_defs.lua"),
}

local prefabs =
{
    "poopcloud",
	"soil_amender_fermented",
}

local FERTILIZER_DEFS = require("prefabs/fertilizer_nutrient_defs").FERTILIZER_DEFS

local function percolate(inst, anim, delay, pre_anim)
	if POPULATING or not inst.entity:IsAwake() or inst.inlimbo then
	    inst.AnimState:PlayAnimation(anim.."_idle", false)
	elseif pre_anim then
	    inst.AnimState:PlayAnimation(pre_anim)
	    inst.AnimState:PushAnimation(anim.."_loop", false)
	    inst.AnimState:PushAnimation(anim.."_idle", false)
	else
	    inst.AnimState:PlayAnimation(anim.."_loop", false)
	    inst.AnimState:PushAnimation(anim.."_idle", false)
	end

	if inst.percolate_task ~= nil then
		inst.percolate_task:Cancel()
	end
    inst.percolate_task = inst:DoTaskInTime(delay + math.random() * 2, percolate, anim, delay)
end

local function bottlereturnfn(inst, is_final_use, doer, target)
	if is_final_use then
		local x, y, z = (target ~= nil and target or inst).Transform:GetWorldPosition()
		inst:Remove()
		inst = nil
		local refund = SpawnPrefab("messagebottleempty")
		if doer ~= nil and doer.components.inventory ~= nil then
			doer.components.inventory:GiveItem(refund, nil, Vector3(x, y, z))
		else
			refund.Transform:SetPosition(x, y, z)
		end
	end
end

local function displayadjectivefn(inst)
	return nil
end

local function getdisplayname(inst)
    return inst:HasTag("fresh") and STRINGS.NAMES.SOIL_AMENDER_FRESH
			or inst:HasTag("stale") and STRINGS.NAMES.SOIL_AMENDER_STALE
			or STRINGS.NAMES.SOIL_AMENDER_SPOILED
end

local function getstatus(inst)
    return inst:HasTag("spoiled") and "SPOILED"
			or inst:HasTag("stale") and "STALE"
			or nil
end

local function onreplacedfn(inst, new_item)
	new_item.AnimState:PlayAnimation("fermented_pre")
	new_item.AnimState:PushAnimation("fermented_idle")
end

local function update_fertilizer(inst)
	local perishable = inst.components.perishable
	if perishable then
		local fertilizer = inst.components.fertilizer
		if perishable:IsFresh() then
			fertilizer:SetHealingAmount(TUNING.SOILAMENDER_FERTILIZE_HEALTH_LOW)
			fertilizer.fertilizervalue = TUNING.SOILAMENDER_FERTILIZE_LOW
			fertilizer.soil_cycles = TUNING.SOILAMENDER_SOILCYCLES_LOW
			fertilizer.withered_cycles = TUNING.SOILAMENDER_WITHEREDCYCLES_LOW
			fertilizer:SetNutrients(FERTILIZER_DEFS.soil_amender_low.nutrients)

			percolate(inst, "fresh", 6)
			inst.components.inventoryitem:ChangeImageName(nil)
			inst.fertilizer_index:set(1)
		elseif perishable:IsStale() then
			fertilizer:SetHealingAmount(TUNING.SOILAMENDER_FERTILIZE_HEALTH_MED)
			fertilizer.fertilizervalue = TUNING.SOILAMENDER_FERTILIZE_MED
			fertilizer.soil_cycles = TUNING.SOILAMENDER_SOILCYCLES_MED
			fertilizer.withered_cycles = TUNING.SOILAMENDER_WITHEREDCYCLES_MED
			fertilizer:SetNutrients(FERTILIZER_DEFS.soil_amender_med.nutrients)

			percolate(inst, "stale", 3, "stale_pre")
			inst.components.inventoryitem:ChangeImageName("soil_amender_stale")
			inst.fertilizer_index:set(2)
		else
			fertilizer:SetHealingAmount(TUNING.SOILAMENDER_FERTILIZE_HEALTH_HIGH)
			fertilizer.fertilizervalue = TUNING.SOILAMENDER_FERTILIZE_HIGH
			fertilizer.soil_cycles = TUNING.SOILAMENDER_SOILCYCLES_HIGH
			fertilizer.withered_cycles = TUNING.SOILAMENDER_WITHEREDCYCLES_HIGH
			fertilizer:SetNutrients(FERTILIZER_DEFS.soil_amender_high.nutrients)

			percolate(inst, "spoiled", 1, "spoiled_pre")
			inst.components.inventoryitem:ChangeImageName("soil_amender_spoiled")
			inst.fertilizer_index:set(3)
		end
	end 
end

local function GetFertilizerKey(inst)
    return inst.fertilizerkey
end

local function fertilizerresearchfn(inst)
    return inst:GetFertilizerKey()
end

local soil_amender_index_to_key =
{
	"soil_amender_low",
	"soil_amender_med",
	"soil_amender_high",
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("soil_amender")
    inst.AnimState:SetBuild("soil_amender")
    inst.AnimState:PlayAnimation("fresh_idle")

    MakeInventoryFloatable(inst, "med", 0.1, 0.73)

	inst.displaynamefn = getdisplayname
	inst.displayadjectivefn = displayadjectivefn
	inst:AddTag("show_spoilage")

	inst.fertilizerkey = soil_amender_index_to_key[1]
	inst.GetFertilizerKey = GetFertilizerKey

	inst.fertilizer_index = net_tinybyte(inst.GUID, "fertilizer_index", "onfertilizerindexdirty")

	inst:ListenForEvent("onfertilizerindexdirty", function()
		inst.fertilizerkey = soil_amender_index_to_key[inst.fertilizer_index:value()]
	end)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("inventoryitem")

    inst:AddComponent("fertilizerresearchable")
    inst.components.fertilizerresearchable:SetResearchFn(fertilizerresearchfn)

    inst:AddComponent("fertilizer")
	inst:ListenForEvent("forceperishchange", update_fertilizer)
	inst.components.fertilizer.onappliedfn = bottlereturnfn

	inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_SUPERFAST)
    inst.components.perishable:StartPerishing()
	inst.components.perishable.onreplacedfn = onreplacedfn
    inst.components.perishable.onperishreplacement = "soil_amender_fermented"

	percolate(inst, "fresh", 6, "fresh_idle")

    MakeHauntableLaunch(inst)

    return inst
end

local function fermented_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("soil_amender")
    inst.AnimState:SetBuild("soil_amender")
    inst.AnimState:PlayAnimation("fermented_idle", false)

    MakeInventoryFloatable(inst, "med", 0.1, 0.73)

	inst.fertilizerkey = "soil_amender_fermented"
    inst.GetFertilizerKey = GetFertilizerKey

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("fertilizerresearchable")
    inst.components.fertilizerresearchable:SetResearchFn(fertilizerresearchfn)

    inst:AddComponent("fertilizer")
	inst.components.fertilizer:SetHealingAmount(TUNING.SOILAMENDER_FERMENTED_TOTAL_HEALTH / TUNING.SOILAMENDER_FERMENTED_USES)
	inst.components.fertilizer.fertilizervalue = TUNING.SOILAMENDER_FERTILIZE_HIGH
	inst.components.fertilizer.soil_cycles = TUNING.SOILAMENDER_SOILCYCLES_HIGH
	inst.components.fertilizer.withered_cycles = TUNING.SOILAMENDER_WITHEREDCYCLES_HIGH
	inst.components.fertilizer:SetNutrients(FERTILIZER_DEFS.soil_amender_fermented.nutrients)
	inst.components.fertilizer.onappliedfn = bottlereturnfn

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.SOILAMENDER_FERMENTED_USES)
    inst.components.finiteuses:SetUses(TUNING.SOILAMENDER_FERMENTED_USES)
    --inst.components.finiteuses:SetOnFinished(inst.Remove) -- handled by fertilizer.onappliedfn

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("soil_amender", fn, assets, prefabs),
	Prefab("soil_amender_fermented", fermented_fn, assets)
