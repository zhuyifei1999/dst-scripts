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
        tile ~= GROUND.WOODFLOOR and
        tile ~= GROUND.CARPET and
        tile ~= GROUND.CHECKER and
        tile < GROUND.UNDERGROUND and
        tile ~= GROUND.IMPASSABLE and
        tile ~= GROUND.INVALID
end

local function CanDeployAtPoint(pt, inst)
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 4, nil, { "NOBLOCK", "player", "FX" })
    local min_spacing_sq = inst.replica.inventoryitem ~= nil and inst.replica.inventoryitem:DeploySpacingSq() or DEPLOYSPACING_SQ[DEPLOYSPACING.DEFAULT]
    for k, v in pairs(ents) do
        if v ~= inst and
            v.entity:IsValid() and
            v.entity:IsVisible() and
            v.components.placer == nil and
            v.entity:GetParent() == nil and
            distsq(v:GetPosition(), pt) < min_spacing_sq then
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
    if not TheWorld.Map:IsPassableAtPoint(pt:Get()) then
        return false
    end
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 2, nil, { "NOBLOCK", "player", "FX", "INLIMBO", "DECOR" })
    for k, v in pairs(ents) do
        if v ~= inst and
            v.entity:IsValid() and
            v.entity:IsVisible() and
            v.components.placer == nil and
            v.entity:GetParent() == nil then
            if v:HasTag("wall") then
                if distsq(v:GetPosition(), pt) < .1 then
                    return false
                end
            elseif distsq(v:GetPosition(), pt) < 1 then
                return false
            end
        end
    end
    return true
end