-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/swap_bedroll_furry_quilt_white_ivory.zip"),
}

return CreatePrefabSkin("bedroll_furry_quilt_white_ivory",
{
	base_prefab = "bedroll_furry",
	type = "item",
	assets = assets,
	build_name = "swap_bedroll_furry_quilt_white_ivory",
	rarity = "Distinguished",
	init_fn = function(inst) bedroll_furry_init_fn(inst, "swap_bedroll_furry_quilt_white_ivory") end,
	marketable = true,
	release_group = 7,
})
