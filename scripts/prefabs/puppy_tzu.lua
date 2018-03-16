-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/puppy_tzu.zip"),
}

return CreatePrefabSkin("puppy_tzu",
{
	base_prefab = "critter_puppy",
	type = "item",
	assets = assets,
	build_name = "puppy_tzu",
	rarity = "Elegant",
	rarity_modifier = "Seasonal",
	init_fn = function(inst) pet_init_fn(inst, "puppy_tzu", "pupington_build" ) end,
	skin_tags = { "PET", "VARG", "CRAFTABLE", },
	release_group = 40,
})