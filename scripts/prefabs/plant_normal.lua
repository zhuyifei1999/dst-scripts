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

for k, v in pairs(VEGGIES) do
    table.insert(prefabs, k)
end

local function onmatured(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/farm_harvestable")
    inst.AnimState:OverrideSymbol("swap_grown", inst.components.crop.product_prefab,inst.components.crop.product_prefab.."01")
end

local function onburnt(inst)
    if inst.components.crop.product_prefab then 
        local temp = SpawnPrefab(inst.components.crop.product_prefab)
        local product = nil
        if temp.components.cookable and temp.components.cookable.product then
            product = SpawnPrefab(temp.components.cookable.product)
        else
            product = SpawnPrefab("seeds_cooked")
        end
        temp:Remove()

        if inst.components.stackable and product.components.stackable then
            product.components.stackable.stacksize = math.min(product.components.stackable.maxsize, inst.components.stackable.stacksize)
        end

        if inst.components.crop and inst.components.crop.grower and inst.components.crop.grower.components.grower then
            inst.components.crop.grower.components.grower:RemoveCrop(inst)
        end

        product.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end

    inst:Remove()
end

local function GetStatus(inst)
    return (inst:HasTag("withered") and "WITHERED")
        or (inst.components.crop:IsReadyForHarvest() and "READY")
        or "GROWING"
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeDragonflyBait(inst, 1)

    inst.AnimState:SetBank("plant_normal")
    inst.AnimState:SetBuild("plant_normal")
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:SetFinalOffset(-1)

    --witherable (from witherable component) added to pristine state for optimization
    inst:AddTag("witherable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("crop")
    inst.components.crop:SetOnMatureFn(onmatured)

    inst:AddComponent("witherable")

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
                    inst.components.crop:Fertilize(fert, haunter)
                end
                return true
            end
        end
        return false
    end)

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    inst.components.burnable:SetOnBurntFn(onburnt)
    --Clear default handlers so we don't stomp our .persists flag
    inst.components.burnable:SetOnIgniteFn(nil)
    inst.components.burnable:SetOnExtinguishFn(nil)

    return inst
end

return Prefab("plant_normal", fn, assets, prefabs)
