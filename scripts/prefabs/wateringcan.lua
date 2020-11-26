local fueltype = FUELTYPE.BURNABLE

local MOISTURE_ON_BURNT_MULTIPLIER = 0.1

local function OnDeplete(inst)
    inst.components.finiteuses:Use(1)
end

local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_"..inst.prefab, "swap_"..inst.prefab)
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function OnUnequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function OnFill(inst, from_object)
    if from_object ~= nil
        and from_object.components.watersource ~= nil
        and from_object.components.watersource.override_fill_uses ~= nil then
        
        inst.components.finiteuses:SetUses(math.min(inst.components.finiteuses.total, inst.components.finiteuses:GetUses() + from_object.components.watersource.override_fill_uses))
    else
        inst.components.finiteuses:SetPercent(1)
    end
    return true
end

local function MakeFuel(inst)
    if inst.components.fuel == nil then
        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL
        inst.components.fuel.fueltype = fueltype
    end
end

local function RemoveFuel(inst)
    if inst.components.fuel ~= nil then
        inst:RemoveComponent("fuel")
    end
end

local function onpercentusedchanged(inst, data)
    if data.percent <= 0 then
        MakeFuel(inst)
    else
        RemoveFuel(inst)
    end
end

local function onburnt(inst)
    local amount = math.ceil(inst.components.finiteuses:GetUses() * inst.components.wateringcan.water_amount * MOISTURE_ON_BURNT_MULTIPLIER)
    if amount > 0 then
        local x, y, z = inst.Transform:GetWorldPosition()
        TheWorld.components.farming_manager:AddSoilMoistureAtPoint(x, 0, z, amount)
    end
end

local function isempty(inst)
    return inst:HasTag(fueltype.."_fuel")
end

local function displaynamefn(inst)
    return isempty(inst) and STRINGS.NAMES[string.upper(inst.prefab).."_EMPTY"] or STRINGS.NAMES[string.upper(inst.prefab)]
end

local function getdesc(inst, viewer)
	return GetDescription(viewer, inst, isempty(inst) and "EMPTY" or nil)
end

local function MakeWateringCan(name, uses, water_amount)
    local assets =
    {
        Asset("ANIM", "anim/"..name..".zip"),
        Asset("ANIM", "anim/swap_"..name..".zip"),
    }

    local prefabs =
    {
        "gridplacer",
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.Transform:SetTwoFaced()

        MakeInventoryPhysics(inst)
        
        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle")

        MakeInventoryFloatable(inst, "small", 0.1, 0.8)

        inst.displaynamefn = displaynamefn

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst.components.inspectable.getspecialdescription = getdesc

        inst:AddComponent("inventoryitem")

        inst:AddComponent("wateringcan")
        inst.components.wateringcan.water_amount = water_amount
        inst.components.wateringcan.ondepletefn = OnDeplete
        
        inst:AddComponent("fillable")
        inst.components.fillable.overrideonfillfn = OnFill
        inst.components.fillable.acceptsoceanwater = false
        inst.components.fillable.showoceanaction = true
        inst.components.fillable.oceanwatererrorreason = "UNSUITABLE_FOR_PLANTS"

        inst:AddComponent("finiteuses")
        inst.components.finiteuses:SetMaxUses(uses)
        inst.components.finiteuses:SetUses(0)

        MakeFuel(inst)

        inst:AddComponent("equippable")
        inst.components.equippable:SetOnEquip(OnEquip)
        inst.components.equippable:SetOnUnequip(OnUnequip)

        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(TUNING.UNARMED_DAMAGE)

        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)
        MakeHauntableLaunch(inst)

        inst:ListenForEvent("percentusedchange", onpercentusedchanged)
        inst:ListenForEvent("onburnt", onburnt)

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return MakeWateringCan("wateringcan", TUNING.WATERINGCAN_USES, TUNING.WATERINGCAN_WATER_AMOUNT),
    MakeWateringCan("premiumwateringcan", TUNING.PREMIUMWATERINGCAN_USES, TUNING.PREMIUMWATERINGCAN_WATER_AMOUNT)