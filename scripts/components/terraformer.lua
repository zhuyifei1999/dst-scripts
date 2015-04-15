local Terraformer = Class(function(self, inst)
    self.inst = inst
end)

local GROUND_TURFS =
{
	[GROUND.ROCKY]		= "turf_rocky",
	[GROUND.ROAD]		= "turf_road",
	[GROUND.DIRT]		= "turf_dirt",
	[GROUND.SAVANNA]	= "turf_savanna",
	[GROUND.GRASS]		= "turf_grass",
	[GROUND.FOREST]		= "turf_forest",
	[GROUND.MARSH]		= "turf_marsh",
	[GROUND.WOODFLOOR]	= "turf_woodfloor",
	[GROUND.CARPET]		= "turf_carpetfloor",
	[GROUND.CHECKER]	= "turf_checkerfloor",
	
	[GROUND.CAVE]		= "turf_cave",
	[GROUND.FUNGUS]		= "turf_fungus",
	[GROUND.FUNGUSRED]	= "turf_fungus_red",
	[GROUND.FUNGUSGREEN]= "turf_fungus_green",
	
	[GROUND.SINKHOLE]	= "turf_sinkhole",
	[GROUND.UNDERROCK]	= "turf_underrock",
	[GROUND.MUD]		= "turf_mud",

	webbing				= "turf_webbing",
}

local function SpawnTurf(turf, pt)
	if turf ~= nil then
		local loot = SpawnPrefab(turf)
		loot.Transform:SetPosition(pt:Get())
		if loot.Physics ~= nil then
			local angle = math.random() * 2 * PI
			loot.Physics:SetVel(2 * math.cos(angle), 10, 2 * math.sin(angle))
		end
	end
end

function Terraformer:Terraform(pt)
    local world = TheWorld
    local map = world.Map

    if not map:CanTerraformAtPoint(pt:Get()) then
        return false
    end

	local original_tile_type = map:GetTileAtPoint(pt:Get())
	local x, y = map:GetTileCoordsAtPoint(pt:Get())

	map:SetTile(x, y, GROUND.DIRT)
	map:RebuildLayer(original_tile_type, x, y)
	map:RebuildLayer(GROUND.DIRT, x, y)
	
    local minimap = world.minimap.MiniMap
	minimap:RebuildLayer(original_tile_type, x, y)
	minimap:RebuildLayer(GROUND.DIRT, x, y)
	
	SpawnTurf(GROUND_TURFS[original_tile_type], pt)
	return true
end

return Terraformer