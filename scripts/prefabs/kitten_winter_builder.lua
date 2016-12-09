-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/kitten_winter.zip"),
}

return CreatePrefabSkin("kitten_winter_builder",
{
	base_prefab = "critter_kitten_builder",
	type = "item",
	assets = assets,
	build_name = "kitten_winter",
	rarity = "Common",
	init_fn = function(inst) critter_builder_init_fn(inst, "kitten_winter" ) end,
})
