require "recipes"

local assets =
{
    Asset("ANIM", "anim/blueprint.zip"),
    Asset("INV_IMAGE", "blueprint"),
}

local function onload(inst, data)
    if data ~= nil and data.recipetouse ~= nil then
        inst.recipetouse = data.recipetouse
        inst.components.teacher:SetRecipe(inst.recipetouse)
        inst.components.named:SetName((STRINGS.NAMES[string.upper(inst.recipetouse)] or STRINGS.NAMES.UNKNOWN).." Blueprint")
    end
end

local function onsave(inst, data)
    if inst.recipetouse then
        data.recipetouse = inst.recipetouse
    end
end

local function selectrecipe_any(recipes)
    if next(recipes) then
        return recipes[math.random(1, #recipes)]
    end
end

local function OnTeach(inst, learner)
    learner:PushEvent("learnrecipe", { teacher = inst, recipe = inst.components.teacher.recipe })
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("blueprint")
    inst.AnimState:SetBuild("blueprint")
    inst.AnimState:PlayAnimation("idle")

    --Sneak these into pristine state for optimization
    inst:AddTag("_named")

    inst:SetPrefabName("blueprint")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --Remove these tags so that they can be added properly when replicating components below
    inst:RemoveTag("_named")

    inst:AddComponent("inspectable")    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:ChangeImageName("blueprint")

    inst:AddComponent("named")
    inst:AddComponent("teacher")
    inst.components.teacher.onteach = OnTeach

    MakeHauntableLaunch(inst)
    AddHauntableCustomReaction(inst, function(inst, haunter)
        if math.random() <= TUNING.HAUNT_CHANCE_HALF then
            local recipes = {}
            for k, v in pairs(AllRecipes) do
                if IsRecipeValid(v.name) and
                    not haunter.components.builder:KnowsRecipe(v.name) and
                    haunter.components.builder:CanLearn(v.name) then
                    table.insert(recipes, v)
                end
            end
            local r = selectrecipe_any(recipes)
            if r ~= nil then
                inst.recipetouse = r.name or STRINGS.NAMES.UNKNOWN
                inst.components.teacher:SetRecipe(inst.recipetouse)
                inst.components.named:SetName(STRINGS.NAMES[string.upper(inst.recipetouse)].." Blueprint")
                inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
                return true
            end
        end
        return false
    end, true, false, true)

    inst.OnLoad = onload
    inst.OnSave = onsave

    return inst
end

local function MakeAnyBlueprint()
    local inst = fn()

    if not TheWorld.ismastersim then
        return inst
    end

    local recipes = {}
    local allplayers = AllPlayers
    for k, v in pairs(AllRecipes) do
        if IsRecipeValid(v.name) then
            local known = false
            for i, player in ipairs(allplayers) do
                if player.components.builder:KnowsRecipe(v.name) or
                    not player.components.builder:CanLearn(v.name) then
                    known = true
                    break
                end
            end
            if not known then
                table.insert(recipes, v)
            end
        end
    end
    local r = selectrecipe_any(recipes)
    if r ~= nil then
        if not inst.recipetouse then
            inst.recipetouse = r.name or STRINGS.NAMES.UNKNOWN
        end
        inst.components.teacher:SetRecipe(inst.recipetouse)
        inst.components.named:SetName(STRINGS.NAMES[string.upper(inst.recipetouse)].." Blueprint")
    end
    return inst
end

local function MakeAnySpecificBlueprint(specific_item)
    return function()
        local inst = fn()

        if not TheWorld.ismastersim then
            return inst
        end

        local recipes = {}
        local allplayers = AllPlayers
        for k, v in pairs(AllRecipes) do
            if IsRecipeValid(v.name) then
                if specific_item == nil then
                    local known = false
                    for i, player in ipairs(allplayers) do
                        if player.components.builder:KnowsRecipe(v.name) or
                            not player.components.builder:CanLearn(v.name) then
                            known = true
                            break
                        end
                    end
                    if not known then
                        table.insert(recipes, v)
                    end
                elseif v.name == specific_item then
                    table.insert(recipes, v)
                end
            end
        end
        local r = selectrecipe_any(recipes)
        if r ~= nil then
            if not inst.recipetouse then
                inst.recipetouse = r.name
            end
            inst.components.teacher:SetRecipe(inst.recipetouse)
            inst.components.named:SetName(STRINGS.NAMES[string.upper(inst.recipetouse)].." Blueprint")
        end
        return inst
    end
end

local function MakeSpecificBlueprint(recipetab)
    return function()
        local inst = fn()

        if not TheWorld.ismastersim then
            return inst
        end

        local recipes = {}
        local allplayers = AllPlayers
        for k, v in pairs(AllRecipes) do
            if IsRecipeValid(v.name) and v.tab == recipetab then
                local known = false
                for i, player in ipairs(allplayers) do
                    if player.components.builder:KnowsRecipe(v.name) or
                        not player.components.builder:CanLearn(v.name) then
                        known = true
                        break
                    end
                end
                if not known then
                    table.insert(recipes, v)
                end
            end
        end
        local r = selectrecipe_any(recipes)
        if r ~= nil then
            if not inst.recipetouse then
                inst.recipetouse = r.name
            end
            inst.components.teacher:SetRecipe(inst.recipetouse)
            inst.components.named:SetName(STRINGS.NAMES[string.upper(inst.recipetouse)].." Blueprint")
        end
        return inst
    end
end

local prefabs = {}

table.insert(prefabs, Prefab("blueprint", MakeAnyBlueprint, assets))
for k,v in pairs(RECIPETABS) do
    table.insert(prefabs, Prefab(string.lower(v.str or "NONAME").."_blueprint", MakeSpecificBlueprint(v), assets))
end
for k,v in pairs(AllRecipes) do
    table.insert(prefabs, Prefab(string.lower(k or "NONAME").."_blueprint", MakeAnySpecificBlueprint(k), assets))
end
return unpack(prefabs)