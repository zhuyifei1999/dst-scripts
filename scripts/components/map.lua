require "map/terrain"

function Map:IsPassableAtPoint(x, y, z)
    local tile = self:GetTileAtPoint(x, y, z)
    return tile ~= GROUND.IMPASSABLE and
        tile ~= GROUND.INVALID
end

function Map:IsAboveGroundAtPoint(x, y, z)
    local tile = self:GetTileAtPoint(x, y, z)
    return tile < GROUND.UNDERGROUND and
        tile ~= GROUND.IMPASSABLE and
        tile ~= GROUND.INVALID
end

function Map:CanTerraformAtPoint(x, y, z)
    local tile = self:GetTileAtPoint(x, y, z)
    return tile ~= GROUND.DIRT and
        tile < GROUND.UNDERGROUND and
        tile ~= GROUND.IMPASSABLE and
        tile ~= GROUND.INVALID
end

function Map:CanPlaceTurfAtPoint(x, y, z)
    return self:GetTileAtPoint(x, y, z) == GROUND.DIRT
end

function Map:CanPlantAtPoint(x, y, z)
    local tile = self:GetTileAtPoint(x, y, z)
    return tile ~= GROUND.ROCKY and
        tile ~= GROUND.ROAD and
        tile ~= GROUND.UNDERROCK and
        tile < GROUND.UNDERGROUND and
        tile ~= GROUND.IMPASSABLE and
        tile ~= GROUND.INVALID and
        not GROUND_FLOORING[tile]
end

local DEPLOY_IGNORE_TAGS = { "NOBLOCK", "player", "FX", "INLIMBO", "DECOR" }
local DEPLOY_PORTAL_SPACING = 2
local DEPLOY_PORTAL_SPACING_SQ = DEPLOY_PORTAL_SPACING * DEPLOY_PORTAL_SPACING

local function CanDeployAtPoint(pt, inst)
    local min_spacing = inst.replica.inventoryitem ~= nil and inst.replica.inventoryitem:DeploySpacingRadius() or DEPLOYSPACING_RADIUS[DEPLOYSPACING.DEFAULT]
    local min_spacing_sq = min_spacing * min_spacing
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, math.max(DEPLOY_PORTAL_SPACING, min_spacing), nil, DEPLOY_IGNORE_TAGS)
    for k, v in pairs(ents) do
        if v ~= inst and
            v.entity:IsValid() and
            v.entity:IsVisible() and
            v.components.placer == nil and
            v.entity:GetParent() == nil and
            --FindEntities range check is <=, but we want <
            v:GetDistanceSqToPoint(pt:Get()) < (v:HasTag("portal") and math.max(DEPLOY_PORTAL_SPACING_SQ, min_spacing_sq) or min_spacing_sq) then
            return false
        end
    end
    return true
end

function Map:CanDeployAtPoint(pt, inst, mouseover)
    return (mouseover == nil or mouseover:HasTag("player")) and
        self:IsPassableAtPoint(pt:Get()) and CanDeployAtPoint(pt, inst)
end

function Map:CanDeployPlantAtPoint(pt, inst)
    return self:CanPlantAtPoint(pt:Get()) and CanDeployAtPoint(pt, inst)
end

function Map:CanDeployWallAtPoint(pt, inst)
    if not self:IsPassableAtPoint(pt:Get()) then
        return false
    end
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, math.max(DEPLOY_PORTAL_SPACING, 1), nil, DEPLOY_IGNORE_TAGS)
    for k, v in pairs(ents) do
        if v ~= inst and
            v.entity:IsValid() and
            v.entity:IsVisible() and
            v.components.placer == nil and
            v.entity:GetParent() == nil then
            --FindEntities range check is <=, but we want <
            local min_spacing_sq = v:HasTag("wall") and .1 or 1
            if v:GetDistanceSqToPoint(pt:Get()) < (v:HasTag("portal") and math.max(DEPLOY_PORTAL_SPACING_SQ, min_spacing_sq) or min_spacing_sq) then
                return false
            end
        end
    end
    return true
end

function Map:CanPlacePrefabFilteredAtPoint(x, y, z, prefab)
    local tile = self:GetTileAtPoint(x, y, z)
    if tile == GROUND.INVALID or tile == GROUND.IMPASSABLE then
        return false
    end

    if terrain.filter[prefab] ~= nil then
        for i,v in ipairs(terrain.filter[prefab]) do
            if tile == v then
                -- can't grow on this terrain
                return false
            end
        end
    end
    return true
end
    

--Ported from legacy "stupid finalling hack because it's too late to change stuff"
--V2C: is it because we rly should be using Physics radius, but
--     not everything has Physics defined? OH WELL
local RECIPE_PADDING =
{
    treasurechest =
    {
        pond = 1, --1 more spacing when building treasurchest near pond
    },
}

function Map:CanDeployRecipeAtPoint(pt, recipe, rot)
    if not self:IsPassableAtPoint(pt:Get()) or
        (recipe.testfn ~= nil and not recipe.testfn(pt, rot)) then
        return false
    end

    local min_spacing = recipe.min_spacing or 3.2

    local padding = RECIPE_PADDING[recipe.name]
    local pad_spacing = 0
    if padding ~= nil then
        for k, v in pairs(padding) do
            if v > pad_spacing then
                pad_spacing = v
            end
        end
    end

    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, math.max(DEPLOY_PORTAL_SPACING, min_spacing + pad_spacing), nil, DEPLOY_IGNORE_TAGS)
    for k, v in pairs(ents) do
        if v.entity:IsValid() and
            v.entity:IsVisible() and
            v.components.placer == nil and
            v.entity:GetParent() == nil then
            --FindEntities range check is <=, but we want <
            local v_spacing = min_spacing + (pad_spacing > 0 and padding[v.prefab] or 0)
            if v:GetDistanceSqToPoint(pt:Get()) < (v:HasTag("portal") and math.max(DEPLOY_PORTAL_SPACING_SQ, v_spacing * v_spacing) or v_spacing * v_spacing) then
                return false
            end
        end
    end
    return true
end
