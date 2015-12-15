local function onsciencebonus(self, sciencebonus)
    self.inst.replica.builder:SetScienceBonus(sciencebonus)
end

local function onmagicbonus(self, magicbonus)
    self.inst.replica.builder:SetMagicBonus(magicbonus)
end

local function onancientbonus(self, ancientbonus)
    self.inst.replica.builder:SetAncientBonus(ancientbonus)
end

local function oningredientmod(self, ingredientmod)
    assert(INGREDIENT_MOD[ingredientmod] ~= nil, "Ingredient mods restricted to certain values, see constants.lua INGREDIENT_MOD")
    self.inst.replica.builder:SetIngredientMod(ingredientmod)
end

local function onfreebuildmode(self, freebuildmode)
    self.inst.replica.builder:SetIsFreeBuildMode(freebuildmode)
end

local Builder = Class(function(self, inst)
    self.inst = inst

    self.recipes = {}
    self.accessible_tech_trees = deepcopy(TECH.NONE)
    self.inst:StartUpdatingComponent(self)
    self.current_prototyper = nil
    self.buffered_builds = {}
    self.bonus_tech_level = 0
    self.science_bonus = 0
    self.magic_bonus = 0
    self.ancient_bonus = 0
    self.ingredientmod = 1

    self.freebuildmode = false

    self.inst.replica.builder:SetTechTrees(self.accessible_tech_trees)
    for k, v in pairs(AllRecipes) do
        if IsRecipeValid(v.name) then
            self.inst.replica.builder:SetIsBuildBuffered(v.name, false)
        end
    end
end,
nil,
{
    science_bonus = onsciencebonus,
    magic_bonus = onmagicbonus,
    ancient_bonus = onancientbonus,
    ingredientmod = oningredientmod,
    freebuildmode = onfreebuildmode,
})

function Builder:ActivateCurrentResearchMachine()
    if self.current_prototyper ~= nil and self.current_prototyper.components.prototyper ~= nil then
        self.current_prototyper.components.prototyper:Activate()
    end
end

function Builder:OnSave()
    return
    {
        buffered_builds = self.buffered_builds,
        recipes = self.recipes,
    }
end

function Builder:OnLoad(data)
    if data.buffered_builds ~= nil then
        for k, v in pairs(AllRecipes) do
            if data.buffered_builds[k] ~= nil and IsRecipeValid(v.name) then
                self.inst.replica.builder:SetIsBuildBuffered(v.name, true)
                self.buffered_builds[k] = type(data.buffered_builds[k]) == "number" and data.buffered_builds[k] or 0
            end
        end
    end

    if data.recipes ~= nil then
        for i, v in ipairs(data.recipes) do
            if IsRecipeValid(v) then
                self:AddRecipe(v)
            end
        end
    end
end

function Builder:IsBuildBuffered(recname)
    return self.buffered_builds[recname] ~= nil
end

function Builder:OnUpdate()
    self:EvaluateTechTrees()
end

function Builder:GiveAllRecipes()
    self.freebuildmode = not self.freebuildmode
    self.inst:PushEvent("unlockrecipe")
end

local function propertech(recipetree, buildertree)
    for k, v in pairs(recipetree) do
        if buildertree[tostring(k)] ~= nil and
            recipetree[tostring(k)] ~= nil and
            recipetree[tostring(k)] > buildertree[tostring(k)] then
            return false
        end
    end
    return true
end

function Builder:UnlockRecipesForTech(tech)
    for k, v in pairs(AllRecipes) do
        if IsRecipeValid(v.name) and propertech(v.level, tech) then
            self:UnlockRecipe(v.name)
        end
    end
end

function Builder:EvaluateTechTrees()
    local pos = self.inst:GetPosition()
    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, TUNING.RESEARCH_MACHINE_DIST, {"prototyper"})

    local old_accessible_tech_trees = deepcopy(self.accessible_tech_trees or TECH.NONE)
    local old_prototyper = self.current_prototyper
    self.current_prototyper = nil

    local prototyper_active = false
    for k,v in pairs(ents) do
        if v.components.prototyper then
            if not prototyper_active then
                --activate the first machine in the list. This will be the one you're closest to.
                v.components.prototyper:TurnOn()
                self.accessible_tech_trees = v.components.prototyper:GetTechTrees()
                prototyper_active = true
                self.current_prototyper = v
            else
                --you've already activated a machine. Turn all the other machines off.
                v.components.prototyper:TurnOff()
            end
        end
    end

    --add any character specific bonuses to your current tech levels.
    if not prototyper_active  then
        self.accessible_tech_trees.SCIENCE = self.science_bonus
        self.accessible_tech_trees.MAGIC = self.magic_bonus
        self.accessible_tech_trees.ANCIENT = self.ancient_bonus
    else
        self.accessible_tech_trees.SCIENCE = self.accessible_tech_trees.SCIENCE + self.science_bonus
        self.accessible_tech_trees.MAGIC = self.accessible_tech_trees.MAGIC + self.magic_bonus
        self.accessible_tech_trees.ANCIENT = self.accessible_tech_trees.ANCIENT + self.ancient_bonus
    end

    local trees_changed = false
    
    for k,v in pairs(old_accessible_tech_trees) do
        if v ~= self.accessible_tech_trees[k] then 
            trees_changed = true
            break
        end
    end
    if not trees_changed then
        for k,v in pairs(self.accessible_tech_trees) do
            if v ~= old_accessible_tech_trees[k] then 
                trees_changed = true
                break
            end
        end
    end

    if old_prototyper and old_prototyper.components.prototyper and old_prototyper.entity:IsValid() and old_prototyper ~= self.current_prototyper then
        old_prototyper.components.prototyper:TurnOff()
    end

    if trees_changed then
        self.inst:PushEvent("techtreechange", {level = self.accessible_tech_trees})
        self.inst.replica.builder:SetTechTrees(self.accessible_tech_trees)
    end
end

function Builder:AddRecipe(recname)
    if not table.contains(self.recipes, recname) then
        table.insert(self.recipes, recname)
    end
    self.inst.replica.builder:AddRecipe(recname)
end

function Builder:UnlockRecipe(recname)
    local recipe = GetValidRecipe(recname)
    if recipe ~= nil and not recipe.nounlock then
    --print("Unlocking: ", recname)
        if self.inst.components.sanity ~= nil then
            self.inst.components.sanity:DoDelta(TUNING.SANITY_MED)
        end
        self:AddRecipe(recname)
        self.inst:PushEvent("unlockrecipe", { recipe = recname })
    end
end

function Builder:GetIngredientWetness(ingredients)
    local wetness = {}
    for item, ents in pairs(ingredients) do
        for k, v in pairs(ents) do
            table.insert(wetness,
            {
                wetness = k.components.inventoryitem ~= nil and k.components.inventoryitem:GetMoisture() or TheWorld.state.wetness,
                num = v,
            })
        end
    end

    local totalWetness = 0
    local totalItems = 0
    for k,v in pairs(wetness) do
        totalWetness = totalWetness + (v.wetness * v.num)
        totalItems = totalItems + v.num
    end

    return totalItems > 0 and totalWetness or 0
end

function Builder:GetIngredients(recname)
    local recipe = AllRecipes[recname]
    if recipe then
        local ingredients = {}
        for k,v in pairs(recipe.ingredients) do
            local amt = math.max(1, RoundBiasedUp(v.amount * self.ingredientmod))
            local items = self.inst.components.inventory:GetItemByName(v.type, amt)
            ingredients[v.type] = items
        end
        return ingredients
    end
end

function Builder:RemoveIngredients(ingredients, recname)
    for item, ents in pairs(ingredients) do
        for k,v in pairs(ents) do
            for i = 1, v do
                self.inst.components.inventory:RemoveItem(k, false):Remove()
            end
        end
    end

    local recipe = AllRecipes[recname]
    if recipe then
        for k,v in pairs(recipe.character_ingredients) do
            if v.type == CHARACTER_INGREDIENT.HEALTH then
                --Don't die from crafting!
                local delta = math.min(math.max(0, self.inst.components.health.currenthealth - 1), v.amount)
                self.inst:PushEvent("consumehealthcost")
                self.inst.components.health:DoDelta(-delta, false, "builder", true, nil, true)
            elseif v.type == CHARACTER_INGREDIENT.MAX_HEALTH then
                self.inst:PushEvent("consumehealthcost")
                self.inst.components.health:DeltaPenalty(v.amount)
            elseif v.type == CHARACTER_INGREDIENT.SANITY then
                self.inst.components.sanity:DoDelta(-v.amount)
            elseif v.type == CHARACTER_INGREDIENT.MAX_SANITY then
                --[[
                    Because we don't have any maxsanity restoring items we want to be more careful
                    with how we remove max sanity. Because of that, this is not handled here.
                    Removal of sanity is actually managed by the entity that is created.
                    See maxwell's pet leash on spawn and pet on death functions for examples.
                --]]
            end
        end
    end
    self.inst:PushEvent("consumeingredients")
end

function Builder:HasCharacterIngredient(ingredient)
    if ingredient.type == CHARACTER_INGREDIENT.HEALTH then
        if self.inst.components.health ~= nil then
            --round up health to match UI display
            local current = math.ceil(self.inst.components.health.currenthealth)
            return current >= ingredient.amount, current
        end
    elseif ingredient.type == CHARACTER_INGREDIENT.MAX_HEALTH then
        if self.inst.components.health ~= nil then
            local penalty = self.inst.components.health:GetPenaltyPercent()
            return penalty + ingredient.amount <= TUNING.MAXIMUM_HEALTH_PENALTY, 1 - penalty
        end
    elseif ingredient.type == CHARACTER_INGREDIENT.SANITY then
        if self.inst.components.sanity ~= nil then
            --round up sanity to match UI display
            local current = math.ceil(self.inst.components.sanity.current)
            return current >= ingredient.amount, current
        end
    elseif ingredient.type == CHARACTER_INGREDIENT.MAX_SANITY then
        if self.inst.components.sanity ~= nil then
            local penalty = self.inst.components.sanity:GetPenaltyPercent()
            return penalty + ingredient.amount <= TUNING.MAXIMUM_SANITY_PENALTY, 1 - penalty
        end
    end
    return false
end

function Builder:MakeRecipe(recipe, pt, rot, onsuccess)
    if recipe ~= nil then
        self.inst:PushEvent("makerecipe", { recipe = recipe })
        if self:IsBuildBuffered(recipe.name) or self:CanBuild(recipe.name) then
            self.inst.components.locomotor:Stop()
            local buffaction = BufferedAction(self.inst, nil, ACTIONS.BUILD, nil, pt or self.inst:GetPosition(), recipe.name, 1, nil, rot)
            if onsuccess ~= nil then
                buffaction:AddSuccessAction(onsuccess)
            end
            self.inst.components.locomotor:PushAction(buffaction, true)
            return true
        end
    end
    return false
end

function Builder:DoBuild(recname, pt, rotation)
    local recipe = GetValidRecipe(recname)
    if recipe ~= nil and (self:IsBuildBuffered(recname) or self:CanBuild(recname)) then
        local wetlevel = self.buffered_builds[recname]
        if wetlevel ~= nil then
            self.buffered_builds[recname] = nil
            self.inst.replica.builder:SetIsBuildBuffered(recname, false)
        else
            local materials = self:GetIngredients(recname)
            wetlevel = self:GetIngredientWetness(materials)
            self:RemoveIngredients(materials, recname)
        end
        self.inst:PushEvent("refreshcrafting")

        local prod = SpawnPrefab(recipe.product)
        if prod ~= nil then
            pt = pt or Point(self.inst.Transform:GetWorldPosition())

            if wetlevel > 0 and prod.components.inventoryitem ~= nil then
                prod.components.inventoryitem:InheritMoisture(wetlevel, self.inst:GetIsWet())
            end

            if prod.components.inventoryitem ~= nil then
                if self.inst.components.inventory ~= nil then
                    --self.inst.components.inventory:GiveItem(prod)
                    self.inst:PushEvent("builditem", { item = prod, recipe = recipe })
                    ProfileStatsAdd("build_"..prod.prefab)

                    if prod.components.equippable ~= nil and not self.inst.components.inventory:GetEquippedItem(prod.components.equippable.equipslot) then
                        --The item is equippable. Equip it.
                        self.inst.components.inventory:Equip(prod)

                        if recipe.numtogive > 1 then
                            --Looks like the recipe gave more than one item! Spawn in the rest and give them to the player.
                            for i = 2, recipe.numtogive do
                                local addt_prod = SpawnPrefab(recipe.product)
                                self.inst.components.inventory:GiveItem(addt_prod, nil, pt)
                            end
                        end
                    elseif recipe.numtogive > 1 and prod.components.stackable then
                        --The item is stackable. Just increase the stack size of the original item.
                        prod.components.stackable:SetStackSize(recipe.numtogive)
                        self.inst.components.inventory:GiveItem(prod, nil, pt)
                    elseif recipe.numtogive > 1 and not prod.components.stackable then
                        --We still need to give the player the original product that was spawned, so do that.
                        self.inst.components.inventory:GiveItem(prod, nil, pt)
                        --Now spawn in the rest of the items and give them to the player.
                        for i = 2, recipe.numtogive do
                            local addt_prod = SpawnPrefab(recipe.product)
                            self.inst.components.inventory:GiveItem(addt_prod, nil, pt)
                        end
                    else
                        --Only the original item is being received.
                        self.inst.components.inventory:GiveItem(prod, nil, pt)
                    end

                    if self.onBuild ~= nil then
                        self.onBuild(self.inst, prod)
                    end
                    prod:OnBuilt(self.inst)

                    return true
                end
            else
                prod.Transform:SetPosition(pt:Get())
                --V2C: or 0 check added for backward compatibility with mods that
                --     have not been updated to support placement rotation yet
                prod.Transform:SetRotation(rotation or 0)
                self.inst:PushEvent("buildstructure", { item = prod, recipe = recipe })
                prod:PushEvent("onbuilt", { builder = self.inst })
                ProfileStatsAdd("build_"..prod.prefab)

                if self.onBuild ~= nil then
                    self.onBuild(self.inst, prod)
                end

                prod:OnBuilt(self.inst)

                return true
            end
        end
    end
end

function Builder:KnowsRecipe(recname)
    local recipe = GetValidRecipe(recname)
    return recipe ~= nil
        and (   (recipe.level.SCIENCE <= self.science_bonus and
                recipe.level.MAGIC <= self.magic_bonus and
                recipe.level.ANCIENT <= self.ancient_bonus and
                (recipe.builder_tag == nil or self.inst:HasTag(recipe.builder_tag)))
            or self.freebuildmode
            or table.contains(self.recipes, recname))
end

function Builder:CanBuild(recname)
    local recipe = GetValidRecipe(recname)
    if recipe == nil then
        return false
    elseif self.freebuildmode then
        return true
    end
    for i, v in ipairs(recipe.ingredients) do
        if not self.inst.components.inventory:Has(v.type, math.max(1, RoundBiasedUp(v.amount * self.ingredientmod))) then
            return false
        end
    end
    for i, v in ipairs(recipe.character_ingredients) do
        if not self:HasCharacterIngredient(v) then
            return false
        end
    end
    return true
end

function Builder:CanLearn(recname)
    local recipe = GetValidRecipe(recname)
    return recipe ~= nil
        and (recipe.builder_tag == nil or
            self.inst:HasTag(recipe.builder_tag) or
            self.freebuildmode)
end

--------------------------------------------------------------------------
--RPC handlers
--------------------------------------------------------------------------

function Builder:MakeRecipeFromMenu(recipe)
    if recipe.placer == nil then
        if self:KnowsRecipe(recipe.name) then
            if self:IsBuildBuffered(recipe.name) or self:CanBuild(recipe.name) then
                self:MakeRecipe(recipe)
            end
        elseif CanPrototypeRecipe(recipe.level, self.accessible_tech_trees) and
            self:CanLearn(recipe.name) and
            self:CanBuild(recipe.name) then
            self:MakeRecipe(recipe, nil, nil, function()
                self:ActivateCurrentResearchMachine()
                self:UnlockRecipe(recipe.name)
            end)
        end
    end
end

function Builder:MakeRecipeAtPoint(recipe, pt, rot)
    if recipe.placer ~= nil and
        self:KnowsRecipe(recipe.name) and
        self:IsBuildBuffered(recipe.name) and
        TheWorld.Map:CanDeployRecipeAtPoint(pt, recipe) then
        self:MakeRecipe(recipe, pt, rot)
    end
end

function Builder:BufferBuild(recname)
    local recipe = GetValidRecipe(recname)
    if recipe ~= nil and recipe.placer ~= nil and not self:IsBuildBuffered(recname) and self:CanBuild(recname) then
        if not self:KnowsRecipe(recname) then
            if CanPrototypeRecipe(recipe.level, self.accessible_tech_trees) and self:CanLearn(recname) then
                self:ActivateCurrentResearchMachine()
                self:UnlockRecipe(recname)
            else
                return
            end
        end
        local materials = self:GetIngredients(recname)
        local wetlevel = self:GetIngredientWetness(materials)
        self:RemoveIngredients(materials, recname)
        self.buffered_builds[recname] = wetlevel
        self.inst.replica.builder:SetIsBuildBuffered(recname, true)
    end
end

return Builder
