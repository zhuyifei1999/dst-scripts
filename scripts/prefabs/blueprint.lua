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
        inst.components.named:SetName((STRINGS.NAMES[string.upper(inst.recipetouse)] or STRINGS.NAMES.UNKNOWN).." "..STRINGS.NAMES.BLUEPRINT)
    end
end

local function onsave(inst, data)
    data.recipetouse = inst.recipetouse
end

local function OnTeach(inst, learner)
    learner:PushEvent("learnrecipe", { teacher = inst, recipe = inst.components.teacher.recipe })
end

local function CanBlueprintRecipe(recipe)
    --Exclude character specific and TECH.NONE
    if not recipe.nounlock and recipe.builder_tag == nil and type(recipe.level) == "table" then
        for k, v in pairs(recipe.level) do
            if v > 0 then
                return true
            end
        end
    end
    return false
end

local function OnHaunt(inst, haunter)
    if math.random() <= TUNING.HAUNT_CHANCE_HALF then
        local recipes = {}
        local old = inst.recipetouse ~= nil and GetValidRecipe(inst.recipetouse) or nil
        for k, v in pairs(AllRecipes) do
            if IsRecipeValid(v.name) and
                old ~= v and
                (old == nil or old.tab == v.tab) and
                CanBlueprintRecipe(v) and
                not haunter.components.builder:KnowsRecipe(v.name) and
                haunter.components.builder:CanLearn(v.name) then
                table.insert(recipes, v)
            end
        end
        if #recipes > 0 then
            inst.recipetouse = recipes[math.random(#recipes)].name or STRINGS.NAMES.UNKNOWN
            inst.components.teacher:SetRecipe(inst.recipetouse)
            inst.components.named:SetName(STRINGS.NAMES[string.upper(inst.recipetouse)].." "..STRINGS.NAMES.BLUEPRINT)
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
            return true
        end
    end
    return false
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
    AddHauntableCustomReaction(inst, OnHaunt, true, false, true)

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
        if IsRecipeValid(v.name) and CanBlueprintRecipe(v) then
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
    inst.recipetouse = #recipes > 0 and recipes[math.random(#recipes)].name or STRINGS.NAMES.UNKNOWN
    inst.components.teacher:SetRecipe(inst.recipetouse)
    inst.components.named:SetName(STRINGS.NAMES[string.upper(inst.recipetouse)].." "..STRINGS.NAMES.BLUEPRINT)
    return inst
end

local function MakeSpecificBlueprint(specific_item)
    return function()
        local inst = fn()

        if not TheWorld.ismastersim then
            return inst
        end

        local r = GetValidRecipe(specific_item)
        inst.recipetouse = r ~= nil and not r.nounlock and r.name or STRINGS.NAMES.UNKNOWN
        inst.components.teacher:SetRecipe(inst.recipetouse)
        inst.components.named:SetName(STRINGS.NAMES[string.upper(inst.recipetouse)].." "..STRINGS.NAMES.BLUEPRINT)
        return inst
    end
end

local function MakeAnyBlueprintFromTab(recipetab)
    return function()
        local inst = fn()

        if not TheWorld.ismastersim then
            return inst
        end

        local recipes = {}
        local allplayers = AllPlayers
        for k, v in pairs(AllRecipes) do
            if IsRecipeValid(v.name) and v.tab == recipetab and CanBlueprintRecipe(v) then
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
        inst.recipetouse = #recipes > 0 and recipes[math.random(#recipes)].name or STRINGS.NAMES.UNKNOWN
        inst.components.teacher:SetRecipe(inst.recipetouse)
        inst.components.named:SetName(STRINGS.NAMES[string.upper(inst.recipetouse)].." "..STRINGS.NAMES.BLUEPRINT)
        return inst
    end
end

local prefabs = {}

table.insert(prefabs, Prefab("blueprint", MakeAnyBlueprint, assets))
for k, v in pairs(RECIPETABS) do
    table.insert(prefabs, Prefab(string.lower(v.str or "NONAME").."_blueprint", MakeAnyBlueprintFromTab(v), assets))
end
for k, v in pairs(AllRecipes) do
    table.insert(prefabs, Prefab(string.lower(k or "NONAME").."_blueprint", MakeSpecificBlueprint(k), assets))
end
return unpack(prefabs)
