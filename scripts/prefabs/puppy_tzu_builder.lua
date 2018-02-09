-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/puppy_tzu.zip"),
}

return CreatePrefabSkin("puppy_tzu_builder",
{
	base_prefab = "critter_puppy_builder",
	type = "item",
	assets = assets,
	build_name = "puppy_tzu",
	rarity = "Common",
	init_fn = function(inst) critter_builder_init_fn(inst, "puppy_tzu" ) end,
	skin_tags = { "CRAFTABLE", },
	release_group = 40,
})
