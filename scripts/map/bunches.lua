

local BunchBlockers = 
{

}

local Bunches = 
{
    seastack_spawner_swell = {
        prefab = "seastack",
        range = 50,
        min = 30,
        max = 50,
        min_spacing = 8, 
        valid_tile_types = {
            GROUND.OCEAN_SWELL,
        },
    },
    seastack_spawner_rough = {
        prefab = "seastack",
        range = 30,
        min = 15,
        max = 25,
        min_spacing = 4,
        valid_tile_types = {
            GROUND.OCEAN_ROUGH,
        },
    },        
    saltstack_spawner_rough = {
        prefab = "saltstack",
        range = 12,
        min = 6,
        max = 9,
        min_spacing = 5,
        valid_tile_types = {
            GROUND.OCEAN_ROUGH,
        },
    },
}

return 
{
	Bunches = Bunches,
	BunchBlockers = BunchBlockers,
}