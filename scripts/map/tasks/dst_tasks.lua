------------------------------------------------------------
-- GIANTS ROOMS
------------------------------------------------------------

AddTask("MooseBreedingTask", {
		locks={LOCKS.TREES,LOCKS.TIER2},
		keys_given={KEYS.PIGS,KEYS.WOOD,KEYS.MEAT,KEYS.TIER2},
		room_choices={
			["MooseGooseBreedingGrounds"] = 1,
		},
		room_bg=GROUND.GRASS,
		background_room="BGGrass",
		colour={r=1,g=0.7,b=1,a=1},
})