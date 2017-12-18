-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/perdling_winter.zip"),
}

return CreatePrefabSkin("perdling_winter",
{
	base_prefab = "critter_perdling",
	type = "item",
	assets = assets,
	build_name = "perdling_winter",
	rarity = "Elegant",
	init_fn = function(inst) pet_init_fn(inst, "perdling_winter", "perdling_build" ) end,
	skin_tags = { "PET", "WINTER", "CRAFTABLE", },
	marketable = true,
	release_group = 35,
})
