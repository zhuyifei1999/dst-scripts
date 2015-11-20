local TileBG = require "widgets/tilebg"
local InventorySlot = require "widgets/invslot"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local TabGroup = require "widgets/tabgroup"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local IngredientUI = require "widgets/ingredientui"

require "widgets/widgetutil"

local TEASER_SCALE_TEXT = 1
local TEASER_SCALE_BTN = 1.5

local RecipePopup = Class(Widget, function(self, horizontal)
    Widget._ctor(self, "Recipe Popup")

    local hud_atlas = resolvefilepath( "images/hud.xml" )

    self.bg = self:AddChild(Image())
    local img = horizontal and "craftingsubmenu_fullvertical.tex" or "craftingsubmenu_fullhorizontal.tex"

    if horizontal then
        self.bg:SetPosition(240,40,0)
    else
        self.bg:SetPosition(210,16,0)
    end
    self.bg:SetTexture(hud_atlas, img)

    self.bg.light_box = self.bg:AddChild(Image(hud_atlas, "craftingsubmenu_litevertical.tex"))
    self.bg.light_box:SetPosition(30, -22)

    --

    self.contents = self:AddChild(Widget(""))
    self.contents:SetPosition(-75,0,0)

    if JapaneseOnPS4() then
        self.name = self.contents:AddChild(Text(UIFONT, 40 * 0.8))
    else
        self.name = self.contents:AddChild(Text(UIFONT, 40))
    end
    self.name:SetPosition(320, 142, 0)
    self.name:SetHAlign(ANCHOR_MIDDLE)
    if JapaneseOnPS4() then
        self.name:SetRegionSize(64*3+30,90)
        self.name:EnableWordWrap(true)
    else
        self.name:SetRegionSize(64*3+30,70)
    end

    if JapaneseOnPS4() then
        self.desc = self.contents:AddChild(Text(BODYTEXTFONT, 33 * 0.8))
        self.desc:SetPosition(320, -10, 0)
        self.desc:SetRegionSize(64*3+30,90)
    else
        self.desc = self.contents:AddChild(Text(BODYTEXTFONT, 33))
        self.desc:SetPosition(320, -5, 0)
        self.desc:SetRegionSize(64*3+30,70) 
    end
    self.desc:EnableWordWrap(true)

    self.ing = {}

    self.button = self.contents:AddChild(ImageButton())
    self.button:SetScale(.7,.7,.7)
    self.button.image:SetScale(.45, .7)
    self.button:SetOnClick(function() if not DoRecipeClick(self.owner, self.recipe) then self.owner.HUD.controls.crafttabs:Close() end end)

    self.recipecost = self.contents:AddChild(Text(NUMBERFONT, 40))
    self.recipecost:SetHAlign(ANCHOR_LEFT)
    self.recipecost:SetRegionSize(80,50)
    self.recipecost:SetPosition(420,-115,0)--(375, -115, 0)
    self.recipecost:SetColour(255/255, 234/255,0/255, 1)

    self.amulet = self.contents:AddChild(Image( resolvefilepath("images/inventoryimages.xml"), "greenamulet.tex"))
    self.amulet:SetPosition(415, -105, 0)
    self.amulet:SetTooltip(STRINGS.GREENAMULET_TOOLTIP)
    
    self.teaser = self.contents:AddChild(Text(BODYTEXTFONT, 28))
    self.teaser:SetPosition(325, -100, 0)
    self.teaser:SetRegionSize(64*3+20,100)
    self.teaser:EnableWordWrap(true)
    self.teaser:Hide()
    
end)

local function GetHintTextForRecipe(player, recipe)
    local validmachines = {}
    local adjusted_level = deepcopy(recipe.level)

    for k,v in pairs(TUNING.PROTOTYPER_TREES) do

        -- Adjust level for bonus so that the hint gives the right message
        if player.replica.builder ~= nil then
            if k == "SCIENCEMACHINE" or k == "ALCHEMYMACHINE" then
                adjusted_level.SCIENCE = adjusted_level.SCIENCE - player.replica.builder:ScienceBonus()
            elseif k == "PRESTIHATITATOR" or k == "SHADOWMANIPULATOR" then
                adjusted_level.MAGIC = adjusted_level.MAGIC - player.replica.builder:MagicBonus()
            elseif k == "ANCIENTALTAR_LOW" or k == "ANCIENTALTAR_HIGH" then
                adjusted_level.ANCIENT = adjusted_level.ANCIENT - player.replica.builder:AncientBonus()
            end
        end

        local canbuild = CanPrototypeRecipe(adjusted_level, v)
        if canbuild then
            table.insert(validmachines, {TREE = tostring(k), SCORE = 0})
            --return tostring(k)
        end
    end

    if #validmachines > 0 then
        if #validmachines == 1 then
            --There's only once machine is valid. Return that one.
            return validmachines[1].TREE
        end

        --There's more than one machine that gives the valid tech level! We have to find the "lowest" one (taking bonus into account).
        for k,v in pairs(validmachines) do
            for rk,rv in pairs(adjusted_level) do
                if TUNING.PROTOTYPER_TREES[v.TREE][rk] == rv then
                    v.SCORE = v.SCORE + 1
                    if player.replica.builder ~= nil then
                        if v.TREE == "SCIENCEMACHINE" or v.TREE == "ALCHEMYMACHINE" then
                            v.SCORE = v.SCORE + player.replica.builder:ScienceBonus()
                        elseif v.TREE == "PRESTIHATITATOR" or v.TREE == "SHADOWMANIPULATOR" then
                            v.SCORE = v.SCORE + player.replica.builder:MagicBonus()
                        elseif v.TREE == "ANCIENTALTAR_LOW" or v.TREE == "ANCIENTALTAR_HIGH" then
                            v.SCORE = v.SCORE + player.replica.builder:AncientBonus()
                        end
                    end
                end
            end
        end

        -- local bestmachine = nil    
        -- for each req in recipe.level do
        --     for m in validmachines do
        --         if req > 0 and m[req] >= req and m[req] < bestmachine[req] then
        --             bestmachine = m
        --         end
        --     end
        -- end

        table.sort(validmachines, function(a,b) return (a.SCORE) > (b.SCORE) end)

        return validmachines[1].TREE
    end

    return "CANTRESEARCH"
end

function RecipePopup:Refresh()
    local owner = self.owner
    if owner == nil then
        return false
    end

    local recipe = self.recipe
    local builder = owner.replica.builder
    local inventory = owner.replica.inventory

    local knows = builder:KnowsRecipe(recipe.name)
    local buffered = builder:IsBuildBuffered(recipe.name)
    local can_build = buffered or builder:CanBuild(recipe.name)
    local tech_level = builder:GetTechTrees()
    local should_hint = not knows and ShouldHintRecipe(recipe.level, tech_level) and not CanPrototypeRecipe(recipe.level, tech_level)

    local equippedBody = inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    local showamulet = equippedBody and equippedBody.prefab == "greenamulet"

    local controller_id = TheInput:GetControllerID()

    if should_hint then
        self.recipecost:Hide()
        self.button:Hide()

        local hint_text =
        {
            ["SCIENCEMACHINE"] = STRINGS.UI.CRAFTING.NEEDSCIENCEMACHINE,
            ["ALCHEMYMACHINE"] = STRINGS.UI.CRAFTING.NEEDALCHEMYENGINE,
            ["SHADOWMANIPULATOR"] = STRINGS.UI.CRAFTING.NEEDSHADOWMANIPULATOR,
            ["PRESTIHATITATOR"] = STRINGS.UI.CRAFTING.NEEDPRESTIHATITATOR,
            ["CANTRESEARCH"] = STRINGS.UI.CRAFTING.CANTRESEARCH,
            ["ANCIENTALTAR_HIGH"] = STRINGS.UI.CRAFTING.NEEDSANCIENT_FOUR,
        }
        local str = hint_text[GetHintTextForRecipe(owner, recipe)] or "Text not found."
        self.teaser:SetScale(TEASER_SCALE_TEXT)
        self.teaser:SetString(str)
        self.teaser:Show()
        showamulet = false
    elseif knows then
        self.teaser:Hide()
        self.recipecost:Hide()

        if TheInput:ControllerAttached() then
            self.button:Hide()
            self.teaser:Show()

            if can_build then
                self.teaser:SetScale(TEASER_SCALE_BTN)
                self.teaser:SetString(TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. (buffered and STRINGS.UI.CRAFTING.PLACE or STRINGS.UI.CRAFTING.BUILD))
            else
                self.teaser:SetScale(TEASER_SCALE_TEXT)
                self.teaser:SetString(STRINGS.UI.CRAFTING.NEEDSTUFF)
            end
        else
            self.button:Show()
            self.button:SetPosition(320, -105, 0)
            self.button:SetScale(1,1,1)

            self.button:SetText(buffered and STRINGS.UI.CRAFTING.PLACE or STRINGS.UI.CRAFTING.BUILD)
            if can_build then
                self.button:Enable()
            else
                self.button:Disable()
            end
        end
    else
        self.teaser:Hide()
        self.recipecost:Hide()

        if TheInput:ControllerAttached() then
            self.button:Hide()
            self.teaser:Show()

            self.teaser:SetColour(1,1,1,1) 

            if can_build then
                self.teaser:SetScale(TEASER_SCALE_BTN)
                self.teaser:SetString(TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. STRINGS.UI.CRAFTING.PROTOTYPE)
            else
                self.teaser:SetScale(TEASER_SCALE_TEXT)
                self.teaser:SetString(STRINGS.UI.CRAFTING.NEEDSTUFF)
            end
        else
            self.button:Show()
            self.button:SetPosition(315, -105, 0)
            self.button:SetScale(1,1,1)

            self.button:SetText(STRINGS.UI.CRAFTING.PROTOTYPE)
            if can_build then
                self.button:Enable()
            else
                self.button:Disable()
            end
        end
    end

    if not showamulet then
        self.amulet:Hide()
    else
        self.amulet:Show()
    end

    self.name:SetString(STRINGS.NAMES[string.upper(self.recipe.name)])
    self.desc:SetString(STRINGS.RECIPE_DESC[string.upper(self.recipe.name)])

    for i, v in ipairs(self.ing) do
        v:Kill()
    end

    self.ing = {}

    local num = (recipe.ingredients ~= nil and #recipe.ingredients or 0) + (recipe.character_ingredients ~= nil and #recipe.character_ingredients or 0)
    local w = 64
    local div = 10
    local half_div = div * .5
    local offset = 315 --center
    if num > 1 then 
        offset = offset - (w *.5 + half_div) * (num - 1)
    end

    for i, v in ipairs(recipe.ingredients) do
        local has, num_found = inventory:Has(v.type, RoundBiasedUp(v.amount * builder:IngredientMod()))
        local ing = self.contents:AddChild(IngredientUI(v.atlas, v.type..".tex", v.amount, num_found, has, STRINGS.NAMES[string.upper(v.type)], owner))
        if num > 1 and #self.ing > 0 then
            offset = offset + half_div
        end
        ing:SetPosition(Vector3(offset, 80, 0))
        offset = offset + w + half_div
        table.insert(self.ing, ing)
    end

    for i, v in ipairs(recipe.character_ingredients) do
        --#BDOIG - does this need to listen for deltas and change while menu is open?
        --V2C: yes, but the entire craft tabs does. (will be added there)
        local has, amount = builder:HasCharacterIngredient(v)
        local ing = self.contents:AddChild(IngredientUI(v.atlas, v.type..".tex", v.amount, amount, has, STRINGS.NAMES[string.upper(v.type)], owner, v.type))
        if num > 1 and #self.ing > 0 then
            offset = offset + half_div
        end
        ing:SetPosition(Vector3(offset, 80, 0))
        offset = offset + w + half_div
        table.insert(self.ing, ing)
    end
end

function RecipePopup:SetRecipe(recipe, owner)
    self.recipe = recipe
    self.owner = owner
    self:Refresh()
end

return RecipePopup
