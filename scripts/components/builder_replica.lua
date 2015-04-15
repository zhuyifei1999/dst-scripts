local Builder = Class(function(self, inst)
    self.inst = inst

    if TheWorld.ismastersim then
        self.classified = inst.player_classified
    elseif self.classified == nil and inst.player_classified ~= nil then
        self:AttachClassified(inst.player_classified)
    end
end)

--------------------------------------------------------------------------

function Builder:OnRemoveFromEntity()
    if self.classified ~= nil then
        if TheWorld.ismastersim then
            self.classified = nil
        else
            self.inst:RemoveEventCallback("onremove", self.ondetachclassified, self.classified)
            self:DetachClassified()
        end
    end
end

Builder.OnRemoveEntity = Builder.OnRemoveFromEntity

function Builder:AttachClassified(classified)
    self.classified = classified
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)
end

function Builder:DetachClassified()
    self.classified = nil
    self.ondetachclassified = nil
end

--------------------------------------------------------------------------

function Builder:SetScienceBonus(sciencebonus)
    if self.classified ~= nil then
        self.classified.sciencebonus:set(sciencebonus)
    end
end

function Builder:ScienceBonus()
    if self.inst.components.builder ~= nil then
        return self.inst.components.builder.science_bonus or 0
    elseif self.classified ~= nil then
        return self.classified.sciencebonus:value()
    else
        return 0
    end
end

function Builder:SetMagicBonus(magicbonus)
    if self.classified ~= nil then
        self.classified.magicbonus:set(magicbonus)
    end
end

function Builder:MagicBonus()
    if self.inst.components.builder ~= nil then
        return self.inst.components.builder.magic_bonus or 0
    elseif self.classified ~= nil then
        return self.classified.magicbonus:value()
    else
        return 0
    end
end

function Builder:SetAncientBonus(ancientbonus)
    if self.classified ~= nil then
        self.classified.ancientbonus:set(ancientbonus)
    end
end

function Builder:AncientBonus()
    if self.inst.components.builder ~= nil then
        return self.inst.components.builder.ancient_bonus or 0
    elseif self.classified ~= nil then
        return self.classified.ancientbonus:value()
    else
        return 0
    end
end

function Builder:SetIngredientMod(ingredientmod)
    if self.classified ~= nil then
        self.classified.ingredientmod:set(ingredientmod)
    end
end

function Builder:IngredientMod()
    if self.inst.components.builder ~= nil then
        return self.inst.components.builder.ingredientmod
    elseif self.classified ~= nil then
        return self.classified.ingredientmod:value()
    else
        return 1
    end
end

function Builder:SetIsFreeBuildMode(isfreebuildmode)
    if self.classified ~= nil then
        self.classified.isfreebuildmode:set(isfreebuildmode)
    end
end

function Builder:SetTechTrees(techlevels)
    if self.classified ~= nil then
        self.classified.sciencelevel:set(techlevels.SCIENCE or 0)
        self.classified.magiclevel:set(techlevels.MAGIC or 0)
        self.classified.ancientlevel:set(techlevels.ANCIENT or 0)
    end
end

function Builder:GetTechTrees()
    if self.inst.components.builder ~= nil then
        return self.inst.components.builder.accessible_tech_trees
    elseif self.classified ~= nil then
        return self.classified.techtrees
    else
        return TECH.NONE
    end
end

function Builder:AddRecipe(recipename)
    if self.classified ~= nil and self.classified.recipes[recipename] ~= nil then
        self.classified.recipes[recipename]:set(true)
    end
end

function Builder:BufferBuild(recipename)
    if self.inst.components.builder ~= nil then
        self.inst.components.builder:BufferBuild(recipename)
    elseif self.classified ~= nil then
        self.classified:BufferBuild(recipename)
    end
end

function Builder:SetIsBuildBuffered(recipename, isbuildbuffered)
    if self.classified ~= nil then
        self.classified.bufferedbuilds[recipename]:set(isbuildbuffered)
    end
end

function Builder:IsBuildBuffered(recipename)
    if self.inst.components.builder ~= nil then
        return self.inst.components.builder:IsBuildBuffered(recipename)
    elseif self.classified ~= nil then
        return recipename ~= nil and
            (self.classified.bufferedbuilds[recipename] ~= nil and
            self.classified.bufferedbuilds[recipename]:value()) or
            self.classified._bufferedbuildspreview[recipename] == true
    else
        return false
    end
end

function Builder:KnowsRecipe(recipename)
    if self.inst.components.builder ~= nil then
        return self.inst.components.builder:KnowsRecipe(recipename)
    elseif self.classified ~= nil then
        local recipe = GetValidRecipe(recipename)
        return recipe ~= nil
            and (   (recipe.level.SCIENCE <= self.classified.sciencebonus:value() and
                    recipe.level.MAGIC <= self.classified.magicbonus:value() and
                    recipe.level.ANCIENT <= self.classified.ancientbonus:value() and
                    (recipe.builder_tag == nil or self.inst:HasTag(recipe.builder_tag)))
                or self.classified.isfreebuildmode:value()
                or (self.classified.recipes[recipename] ~= nil and self.classified.recipes[recipename]:value()))
    else
        return false
    end
end

function Builder:CanBuild(recipename)
    if self.inst.components.builder ~= nil then
        return self.inst.components.builder:CanBuild(recipename)
    elseif self.classified ~= nil then
        local recipe = GetValidRecipe(recipename)
        if recipe == nil then
            return false
        elseif self.classified.isfreebuildmode:value() then
            return true
        end
        for i, v in ipairs(recipe.ingredients) do
            local amt = math.max(1, RoundBiasedUp(v.amount * self.classified.ingredientmod:value()))
            if not self.inst.replica.inventory:Has(v.type, amt) then
                return false
            end
        end
        return true
    else
        return false
    end
end

function Builder:CanLearn(recipename)
    if self.inst.components.builder ~= nil then
        return self.inst.components.builder:CanLearn(recipename)
    elseif self.classified ~= nil then
        local recipe = GetValidRecipe(recipename)
        return recipe ~= nil
            and (recipe.builder_tag == nil or
                self.inst:HasTag(recipe.builder_tag) or
                self.classified.isfreebuildmode:value())
    else
        return false
    end
end

function Builder:CanBuildAtPoint(pt, recipe)
    if not TheWorld.Map:IsPassableAtPoint(pt:Get()) then
        return false
    end

    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 6, nil, { "player", "FX", "NOBLOCK" }) -- or we could include a flag to the search?
    for k, v in pairs(ents) do
        if v ~= self.inst and
            v.components.placer == nil and
            v.entity:IsVisible() and
            not (v.replica.inventoryitem ~= nil and v.replica.inventoryitem:IsHeld()) then
            local min_rad = recipe.min_spacing or 2 + 1.2
            --local rad = (v.Physics and v.Physics:GetRadius() or 1) + 1.25
            
            --stupid finalling hack because it's too late to change stuff
            if recipe.name == "treasurechest" and v.prefab == "pond" then
                min_rad = min_rad + 1
            end

            if distsq(v:GetPosition(), pt) <= min_rad * min_rad then
                return false
            end
        end
    end
    return true
end

function Builder:MakeRecipeFromMenu(recipe)
    if self.inst.components.builder ~= nil then
        self.inst.components.builder:MakeRecipeFromMenu(recipe)
    elseif self.inst.components.playercontroller ~= nil then
        self.inst.components.playercontroller:RemoteMakeRecipeFromMenu(recipe)
    end
end

function Builder:MakeRecipeAtPoint(recipe, pt)
    if self.inst.components.builder ~= nil then
        self.inst.components.builder:MakeRecipeAtPoint(recipe, pt)
    elseif self.inst.components.playercontroller ~= nil then
        self.inst.components.playercontroller:RemoteMakeRecipeAtPoint(recipe, pt)
    end
end

function Builder:IsBusy()
    if self.inst.components.builder ~= nil then
        return false
    end
    local inventory = self.inst.replica.inventory
    if inventory == nil or inventory.classified == nil then
        return false
    elseif inventory.classified:IsBusy() then
        return true
    end
    local overflow = inventory.classified:GetOverflowContainer()
    return overflow ~= nil and overflow.classified ~= nil and overflow.classified:IsBusy()
end

return Builder