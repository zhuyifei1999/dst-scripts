require "class"
require "util"

Ingredient = Class(function(self, type, amount, atlas)
    self.type = type
    self.amount = amount
	self.atlas = (atlas and resolvefilepath(atlas))
					or resolvefilepath("images/inventoryimages.xml")
end)

local num = 0
AllRecipes = {}

Recipe = Class(function(self, name, ingredients, tab, level, placer, min_spacing, nounlock, numtogive, builder_tag)
    self.name          = name
    self.placer        = placer
    self.ingredients   = ingredients
    self.product       = name
    self.tab           = tab

    self.atlas         = resolvefilepath("images/inventoryimages.xml")

    self.image         = name .. ".tex"
    self.sortkey       = num
    self.level         = level or 0
    self.level.ANCIENT = self.level.ANCIENT or 0
    self.level.MAGIC   = self.level.MAGIC or 0
    self.level.SCIENCE = self.level.SCIENCE or 0
    self.placer        = placer
    self.min_spacing   = min_spacing or 3.2

    self.nounlock      = nounlock or false

    self.numtogive     = numtogive or 1

    self.builder_tag   = builder_tag or nil

    num                = num + 1
    AllRecipes[name]      = self
end)

function IsRecipeValid(recname)
    return IsRecipeValidInGameMode(TheNet:GetServerGameMode(), recname)
end

function GetValidRecipe(recname)
    return IsRecipeValid(recname) and AllRecipes[recname] or nil
end