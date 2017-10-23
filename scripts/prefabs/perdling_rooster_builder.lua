-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/perdling_rooster.zip"),
}

return CreatePrefabSkin("perdling_rooster_builder",
{
	base_prefab = "critter_perdling_builder",
	type = "item",
	assets = assets,
	build_name = "perdling_rooster",
	rarity = "Common",
	init_fn = function(inst) critter_builder_init_fn(inst, "perdling_rooster" ) end,
	release_group = 23,
})
