-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/dragonling_winter.zip"),
}

return CreatePrefabSkin("dragonling_winter",
{
	base_prefab = "critter_dragonling",
	type = "item",
	assets = assets,
	build_name = "dragonling_winter",
	rarity = "Elegant",
	init_fn = function(inst) pet_init_fn(inst, "dragonling_winter", "dragonling_build" ) end,
})
