local assets =
{
    Asset("ANIM", "anim/cook_pot_food.zip"),
}

local prefabs =
{
    "spoiled_food",
}

local function MakePreparedFood(data)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBuild("cook_pot_food")
        inst.AnimState:SetBank("food")
        inst.AnimState:PlayAnimation(data.name, false)

        inst:AddTag("preparedfood")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("edible")
        inst.components.edible.healthvalue = data.health
        inst.components.edible.hungervalue = data.hunger
        inst.components.edible.foodtype = data.foodtype or FOODTYPE.GENERIC
        inst.components.edible.sanityvalue = data.sanity or 0
        inst.components.edible.temperaturedelta = data.temperaturedelta or 0
        inst.components.edible.temperaturediration = data.temperaturediration or 0

        inst:AddComponent("inspectable")
        inst.wet_prefix = data.wet_prefix
        
        inst:AddComponent("inventoryitem")

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("perishable")
        inst.components.perishable:SetPerishTime(data.perishtime or TUNING.PERISH_SLOW)
        inst.components.perishable:StartPerishing()
        inst.components.perishable.onperishreplacement = "spoiled_food"

        if data.tags then
            for i,v in pairs(data.tags) do
                inst:AddTag(v)
            end
        end

        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)
        MakeHauntableLaunchAndPerish(inst)
        AddHauntableCustomReaction(inst, function(inst, haunter)
            if math.random() <= TUNING.HAUNT_CHANCE_SUPERRARE then
                if inst.components.burnable and not inst.components.burnable:IsBurning() then
                    inst.components.burnable:Ignite()
                    inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
                    inst.components.hauntable.cooldown_on_successful_haunt = false
                    return true
                end
            end
            return false
        end, true, false, true)
        ---------------------        

        inst:AddComponent("bait")

        ------------------------------------------------
        inst:AddComponent("tradable")
        
        ------------------------------------------------  

        return inst
    end

    return Prefab("common/inventory/"..data.name, fn, assets, prefabs)
end

local prefs = {}

local foods = require("preparedfoods")
for k,v in pairs(foods) do
    table.insert(prefs, MakePreparedFood(v))
end

return unpack(prefs)