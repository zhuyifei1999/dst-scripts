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

mod_protect_Recipe = false

Recipe = Class(function(self, name, ingredients, tab, level, placer, min_spacing, nounlock, numtogive, builder_tag, atlas, image, lockedatlas, lockedimage)
    if mod_protect_Recipe then
        print("Warning: Calling Recipe from a mod is now deprecated. Please call AddRecipe from your modmain.lua file.")
    end

    self.name          = name
    self.ingredients   = ingredients
    self.product       = name
    self.tab           = tab

    self.atlas         = (atlas and resolvefilepath(atlas)) or resolvefilepath("images/inventoryimages.xml")
    self.image         = image or (name .. ".tex")

    --self.lockedatlas   = (lockedatlas and resolvefilepath(lockedatlas)) or (atlas == nil and resolvefilepath("images/inventoryimages_inverse.xml")) or nil
    --self.lockedimage   = lockedimage or (name ..".tex")

    self.sortkey       = num
    self.rpc_id        = num --mods will set the rpc_id in SetModRPCID when called by AddRecipe()
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
    AllRecipes[name]   = self
end)

function Recipe:SetModRPCID()
    local rpc_id = smallhash(self.name)
    
    for _,v in pairs(AllRecipes) do
        if v.rpc_id == rpc_id then
            print("ERROR:hash collision between recipe names ", self.name, " and ", v.name )
        end
    end
    self.rpc_id = rpc_id
end

function GetValidRecipe(recname)
    if not IsRecipeValidInGameMode(TheNet:GetServerGameMode(), recname) then
        return
    end
    local rec = AllRecipes[recname]
    return rec ~= nil and rec.tab ~= nil and rec or nil
end

function IsRecipeValid(recname)
    return GetValidRecipe(recname) ~= nil
end
