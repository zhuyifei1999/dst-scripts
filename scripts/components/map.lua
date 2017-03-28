require "map/terrain"

--NOTE: this is the max of all entities that have custom deploy_extra_spacing
--      see EntityScript:SetDeployExtraSpacing(spacing)
local DEPLOY_EXTRA_SPACING = 0
function Map:RegisterDeployExtraSpacing(spacing)
    DEPLOY_EXTRA_SPACING = math.max(spacing, DEPLOY_EXTRA_SPACING)
end

--NOTE: this is the max of all entities that have custom terraform_extra_spacing
--      see EntityScript:SetTerraformExtraSpacing(spacing)
local TERRAFORM_EXTRA_SPACING = 0
function Map:RegisterTerraformExtraSpacing(spacing)
    TERRAFORM_EXTRA_SPACING = math.max(spacing, TERRAFORM_EXTRA_SPACING)
end

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
    if tile == GROUND.DIRT or
        tile >= GROUND.UNDERGROUND or
        tile == GROUND.IMPASSABLE or
        tile == GROUND.INVALID then
        return false
    elseif TERRAFORM_EXTRA_SPACING > 0 then
        for i, v in ipairs(TheSim:FindEntities(x, 0, z, TERRAFORM_EXTRA_SPACING, { "terraformblocker" }, { "INLIMBO" })) do
            if v.entity:IsVisible() and
                v:GetDistanceSqToPoint(x, 0, z) < v.terraform_extra_spacing * v.terraform_extra_spacing then
                return false
            end
        end
    end
    return true
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

function Map:IsPointNearHole(pt, range)
    range = range or .5
    for i, v in ipairs(TheSim:FindEntities(pt.x, 0, pt.z, DEPLOY_EXTRA_SPACING + range, { "groundhole" })) do
        local radius = v.Physics:GetRadius() + range
        if v:GetDistanceSqToPoint(pt) < radius * radius then
            return true
        end
    end
    return false
end

function Map:IsDeployPointClear(pt, inst, min_spacing, min_spacing_sq_fn)
    local min_spacing_sq = min_spacing_sq_fn == nil and min_spacing * min_spacing or nil
    for i, v in ipairs(TheSim:FindEntities(pt.x, 0, pt.z, math.max(DEPLOY_EXTRA_SPACING, min_spacing), nil, DEPLOY_IGNORE_TAGS)) do
        if v ~= inst and
            v.entity:IsVisible() and
            v.components.placer == nil and
            v.entity:GetParent() == nil then
            --FindEntities range check is <=, but we want <
            if min_spacing_sq_fn ~= nil then
                min_spacing_sq = min_spacing_sq_fn(v)
            end
            if v:GetDistanceSqToPoint(pt.x, 0, pt.z) < (v.deploy_extra_spacing ~= nil and math.max(v.deploy_extra_spacing * v.deploy_extra_spacing, min_spacing_sq) or min_spacing_sq) then
                return false
            end
        end
    end
    return true
end

function Map:CanDeployAtPoint(pt, inst, mouseover)
    return (mouseover == nil or mouseover:HasTag("player"))
        and self:IsPassableAtPoint(pt:Get())
        and self:IsDeployPointClear(pt, inst, inst.replica.inventoryitem ~= nil and inst.replica.inventoryitem:DeploySpacingRadius() or DEPLOYSPACING_RADIUS[DEPLOYSPACING.DEFAULT])
end

function Map:CanDeployPlantAtPoint(pt, inst)
    return self:CanPlantAtPoint(pt:Get())
        and self:IsDeployPointClear(pt, inst, inst.replica.inventoryitem ~= nil and inst.replica.inventoryitem:DeploySpacingRadius() or DEPLOYSPACING_RADIUS[DEPLOYSPACING.DEFAULT])
end

local function CalculateWallSpacingSq(other)
    return other:HasTag("wall") and .1 or 1
end

function Map:CanDeployWallAtPoint(pt, inst)
    return self:IsPassableAtPoint(pt:Get())
        and self:IsDeployPointClear(pt, inst, 1, CalculateWallSpacingSq)
end

function Map:CanPlacePrefabFilteredAtPoint(x, y, z, prefab)
    local tile = self:GetTileAtPoint(x, y, z)
    if tile == GROUND.INVALID or tile == GROUND.IMPASSABLE then
        return false
    end

    if terrain.filter[prefab] ~= nil then
        for i, v in ipairs(terrain.filter[prefab]) do
            if tile == v then
                -- can't grow on this terrain
                return false
            end
        end
    end
    return true
end
    
function Map:CanDeployRecipeAtPoint(pt, recipe, rot)
    return self:IsPassableAtPoint(pt:Get())
        and (recipe.testfn == nil or recipe.testfn(pt, rot))
        and self:IsDeployPointClear(pt, nil, recipe.min_spacing or 3.2)
end
