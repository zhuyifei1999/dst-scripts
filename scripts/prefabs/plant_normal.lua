local assets =
{
	Asset("ANIM", "anim/plant_normal.zip"),

	-- products for buildswap
    Asset("ANIM", "anim/durian.zip"),
    Asset("ANIM", "anim/eggplant.zip"),
    Asset("ANIM", "anim/dragonfruit.zip"),
    Asset("ANIM", "anim/pomegranate.zip"),
    Asset("ANIM", "anim/corn.zip"),
    Asset("ANIM", "anim/pumpkin.zip"),
    Asset("ANIM", "anim/carrot.zip"),

}

require "prefabs/veggies"

local prefabs = {}

for k,v in pairs(VEGGIES) do
    table.insert(prefabs, k)
end

local function onmatured(inst)
	inst.SoundEmitter:PlaySound("dontstarve/common/farm_harvestable")
	inst.AnimState:OverrideSymbol("swap_grown", inst.components.crop.product_prefab,inst.components.crop.product_prefab.."01")
end

local function GetStatus(inst)
    if inst.components.crop:IsReadyForHarvest() then
        return "READY"
    else
        return "GROWING"
    end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:SetBank("plant_normal")
    inst.AnimState:SetBuild("plant_normal")
    inst.AnimState:PlayAnimation("grow")

    inst:AddComponent("crop")
    inst.components.crop:SetOnMatureFn(onmatured)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        if math.random() <= TUNING.HAUNT_CHANCE_OFTEN then
            if inst.components.crop then
                local harvested = inst.components.crop:Harvest()
                if not harvested then
                    local fert = SpawnPrefab("spoiled_food")
                    inst.components.crop:Fertilize(fert)
                end
                return true
            end
        end
        return false
    end)

    inst.AnimState:SetFinalOffset(-1)

    return inst
end

return Prefab("common/objects/plant_normal", fn, assets, prefabs)